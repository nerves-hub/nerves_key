defmodule ATECC508A.Device do
  use GenServer

  alias ATECC508A.{Configuration, Transport, Request, Util}

  @otp_magic <<0x4E, 0x72, 0x76, 0x73>>

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
    {:ok, i2c} = Transport.I2C.init([])

    {:ok, %State{i2c: i2c}, {:continue, :init}}
  end

  def handle_continue(:init, state) do
    {:noreply, state}
  end

  def handle_call(:read_info, _from, state) do
    {:reply, :unimplemented, state}
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

  defp read_otp_zone(state) do
    with {:ok, lo} <- Request.read_zone(Transport.I2C, state.i2c, :otp, 0, 0, 0, 32),
         {:ok, hi} <- Request.read_zone(Transport.I2C, state.i2c, :otp, 0, 1, 0, 32) do
      {:ok, lo <> hi}
    end
  end

  defp write_otp_zone(state, contents) do
  end

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
