defmodule ATECC508A.Device do
  use GenServer

  alias Circuits.I2C
  alias ATECC508A.Util

  @default_provisioned_address 0x60

  @otp_magic <<0x4E, 0x72, 0x76, 0x73>>

  @atecc508a_wake_delay_us 1500
  @atecc508a_signature <<0x04, 0x11, 0x33, 0x43>>

  @type provisioning_state :: :unconfigured | :configured | :provisioned | :errored

  defmodule State do
    @moduledoc false

    defstruct i2c: nil,
              address: nil,
              state: :unconfigured
  end

  @spec start_link(Keyword.t()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Return the state of the device

  * :unconfigured - this is a fresh ATECC508A that hasn't been configured yet
  * :configured - the configuration has been programmed and locked, but required data hasn't been written
  * :provisioned - the device has been provisioned and is locked
  * :errored - the device has an unexpected configuration or it's locked with unexpected data
  """
  @spec device_state() :: provisioning_state()
  def device_state() do
    GenServer.call(__MODULE__, :device_state)
  end

  @doc """
  Write and lock the configuration of the ATECC508A

  This is the first step in the provisioning process.
  """
  @spec configure() :: :ok | {:error, String.t()}
  def configure() do
    GenServer.call(__MODULE__, :configure)
  end

  @doc """
  Once the configuration is locked, call this function to create the device key

  The public key part is returned on success so that it may be signed.
  """
  @spec create_device_key_pair() :: {:ok, ATECC508A.ecc_public_key()} | {:error, String.t()}
  def create_device_key_pair() do
    GenServer.call(__MODULE__, :create_device_key_pair)
  end

  @doc """
  Finalize the provisioning of the device

  See ATECC508A for all of the information that's needed. This function will
  write that data to the appropriate locations and lock the device. After this
  call, none of this data can change. If you made a mistake, cry a little and
  then replace the ATECC508 with a new one.
  """
  @spec provision(ATECC508A.ProvisioningInfo.t()) :: :ok | {:error, String.t()}
  def provision(provisioning_info) do
    GenServer.call(__MODULE__, {:provision, provisioning_info})
  end

  @doc """
  Return the device's X.509 certificate

  The device must be provisioned for this to succeed.
  """
  # @spec device_certificate() :: X509.Certificate.t()
  def device_certificate() do
    true
  end

  @doc """
  Return the signer's X.509 certificate

  The device must be provisioned for this to succeed.
  """
  # @spec signer_certificate() :: X509.Certificate.t()
  def signer_certificate() do
    true
  end

  @doc """
  Query and return all of the information that's stored in the clear
  """
  @spec read_info() :: ATECC508A.Info.t()
  def read_info() do
    GenServer.call(__MODULE__, :read_info)
  end

  def init(_args) do
    device = Application.get_env(:atecc508a, :i2c_device, "i2c-1")
    address = Application.get_env(:atecc508a, :i2c_address, @default_provisioned_address)

    {:ok, i2c} = I2C.open(device)

    {:ok, %State{i2c: i2c, address: address}, {:continue, :init}}
  end

  def handle_continue(:init, state) do
    {:noreply, state}
  end

  def handle_call(:read_info, _from, state) do
    with :ok <- wakeup(state),
         {:ok, raw_bytes} <- read_configuration_zone(state),
         {:ok, rc} <- parse_config_zone(raw_bytes),
         :ok <- sleep(state) do
      {:reply, rc, state}
    else
      error -> {:reply, error, state}
    end
  end

  def handle_call(:configure, _from, state) do
    rc = %ATECC508A.Info{}
    {:reply, rc, state}
  end

  def handle_call(:create_device_key_pair, _from, state) do
    rc = %ATECC508A.Info{}
    {:reply, rc, state}
  end

  def handle_call({:provision, provisioning_info}, _from, state) do
    rc = %ATECC508A.Info{}
    {:reply, rc, state}
  end

  defp device_configured?(i2c) do
    # I2C.write_read(i2c, @provisioned_address)
  end

  defp wakeup(state) do
    # See ATECC508A 6.1 for the wakeup sequence.
    #
    # Write to address 0 to pull SDA down for the wakeup interval (60 uS).
    # Since only 8-bits get through, the I2C speed needs to be < 133 KHz for
    # this to work. This "fails" since nobody will ACK the write and that's
    # expected.
    I2C.write(state.i2c, 0, <<0>>)

    # Wait for the device to wake up for real
    microsleep(@atecc508a_wake_delay_us)

    # Check that it's awake by reading its signature
    case I2C.read(state.i2c, state.address, 4) do
      {:ok, @atecc508a_signature} -> :ok
      {:ok, _something_else} -> {:error, :unexpected_wakeup_response}
      error -> error
    end
  end

  defp sleep(state) do
    # See ATECC508A 6.2 for the sleep sequence.
    I2C.write(state.i2c, state.address, <<0x01>>)
  end

  defp microsleep(usec) do
    msec = round(:math.ceil(usec / 1000))
    Process.sleep(msec)
  end

  defp get_addr(:config, 0, block, offset), do: block * 8 + offset
  defp get_addr(:otp, 0, block, offset), do: block * 8 + offset
  # defp get_addr(:data, slot, block, offset), do: block * 256 + slot * 8 + offset

  # defp length_flag(4), do: 0
  defp length_flag(32), do: 1

  defp zone_value(:config), do: 0
  defp zone_value(:otp), do: 1
  # defp zone_value(:data), do: 02

  @atecc508a_op_read 0x02
  @atecc508a_op_write 0x12
  @atecc508a_op_genkey 0x40
  @atecc508a_op_lock 0x17

  defp read_zone(state, zone, slot, block, offset, len) when len == 4 or len == 32 do
    addr = get_addr(zone, slot, block, offset)

    msg = <<7, @atecc508a_op_read, length_flag(len)::1, zone_value(zone)::7, addr::little-16>>
    crc = ATECC508A.CRC.crc(msg)
    to_send = [3, msg, crc]
    response_len = len + 3

    with :ok <- I2C.write(state.i2c, state.address, to_send),
         microsleep(5000),
         {:ok, <<^response_len, message::binary-size(len), message_crc::binary-size(2)>>} <-
           I2C.read(state.i2c, state.address, len + 3),
         ^message_crc <- ATECC508A.CRC.crc(<<response_len, message::binary>>) do
      {:ok, message}
    else
      {:error, _} = error -> error
      {:ok, bin} when is_binary(bin) -> {:error, {:unexpected_length, bin, response_len}}
      _bad_crc -> {:error, :crc_mismatch}
    end
  end

  defp write_zone(state, zone, slot, block, offset, data)
       when byte_size(data) == 4 or byte_size(data) == 32 do
    addr = get_addr(zone, slot, block, offset)
    len = byte_size(data)

    msg =
      <<len + 7, @atecc508a_op_write, length_flag(len)::1, 0::5, zone_value(zone)::2,
        addr::little-16, data>>

    crc = ATECC508A.CRC.crc(msg)
    to_send = [3, msg, crc]

    with :ok <- I2C.write(state.i2c, state.address, to_send),
         microsleep(5000),
         {:ok, <<3, 0, message_crc::binary-size(2)>>} <- I2C.read(state.i2c, state.address, 4),
         ^message_crc <- ATECC508A.CRC.crc(<<3, 0>>) do
      :ok
    else
      {:error, _} = error -> error
      {:ok, bin} when is_binary(bin) -> {:error, {:failed, bin}}
      _bad_crc -> {:error, :crc_mismatch}
    end
  end

  defp genkey(state, mode, key_id) do
  end

  defp lock_zone(state, zone, crc) do
    # Need to calculate the CRC of everything written in the zone to be
    # locked for this to work.

    # See Table 9-31 - Mode Encoding
    mode = if zone == :config, do: 0, else: 1
    msg = <<7, @atecc508a_op_lock, mode, crc>>
    msg_crc = ATECC508A.CRC.crc(msg)
    to_send = [3, msg, msg_crc]

    with :ok <- I2C.write(state.i2c, state.address, to_send),
         microsleep(5000),
         {:ok, <<3, 0, message_crc::binary-size(2)>>} <- I2C.read(state.i2c, state.address, 4),
         ^message_crc <- ATECC508A.CRC.crc(<<3, 0>>) do
      :ok
    else
      {:error, _} = error -> error
      {:ok, bin} when is_binary(bin) -> {:error, {:failed, bin}}
      _bad_crc -> {:error, :crc_mismatch}
    end
  end

  defp read_otp_zone(state) do
    with {:ok, lo} <- read_zone(state, :otp, 0, 0, 0, 32),
         {:ok, hi} <- read_zone(state, :otp, 0, 1, 0, 32) do
      {:ok, lo <> hi}
    end
  end

  defp write_otp_zone(state, contents) do
  end

  defp read_configuration_zone(state) do
    with {:ok, lo} <- read_zone(state, :config, 0, 0, 0, 32),
         {:ok, mid} <- read_zone(state, :config, 0, 1, 0, 32),
         {:ok, hi} <- read_zone(state, :config, 0, 2, 0, 32),
         {:ok, hi2} <- read_zone(state, :config, 0, 3, 0, 32) do
      {:ok, lo <> mid <> hi <> hi2}
    end
  end

  defp parse_config_zone(
         <<sn0_3::4-bytes, rev_num::4-bytes, sn4_8::5-bytes, _reserved0, _i2c_enable, _reserved1,
           _i2c_address, _reserved2, otp_mode, chip_mode, slot_config::32-bytes,
           counter0::little-64, counter1::little-64, last_key_use::16-bytes, user_extra, selector,
           lock_value, lock_config, slot_locked::little-16, _rfu::2-bytes, x509_format::4-bytes,
           key_config::32-bytes>>
       ) do
    {:ok,
     %{
       serial_number: sn0_3 <> sn4_8,
       rev_num: rev_num,
       otp_mode: otp_mode,
       chip_mode: chip_mode,
       slot_config: slot_config,
       counter0: counter0,
       counter1: counter1,
       last_key_use: last_key_use,
       user_extra: user_extra,
       selector: selector,
       lock_value: lock_value,
       lock_config: lock_config,
       slot_locked: slot_locked,
       x509_format: x509_format,
       key_config: key_config
     }}
  end

  defp parse_config_zone(_other), do: {:error, :config_parse_error}

  defp parse_otp_zone(
         <<@otp_magic, flags::2-bytes, board_name::10-bytes, mfg_serial_number::16-bytes,
           user_data::32-bytes>>
       ) do
    {:ok,
     %{
       flags: flags,
       board_name: Util.trim_zeros(board_name),
       mfg_serial_number: Util.trim_zeros(mfg_serial_number),
       user_data: user_data
     }}
  end

  defp encode_otp_zone(info) do
    board_name = Util.pad_zeros(info.board_name, 10)
    mfg_serial_number = Util.pad_zeros(info.mfg_serial_number, 16)

    [<<@otp_magic, 0::16>>, board_name, mfg_serial_number, info.user_data]
  end
end
