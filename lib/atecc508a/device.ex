defmodule ATECC508A.Device do
  use GenServer

  alias Circuits.I2C

  @default_unprovisioned_address 0x60
  @default_provisioned_address 0x58

  @atecc508a_wake_delay_us 1500
  @atecc508a_signature <<0x04, 0x11, 0x33, 0x43>>

  @atecc508a_zone_config 0
  @atecc508a_zone_otp 1
  @atecc508a_zone_data 2

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
  @spec device_certificate() :: X509.Certificate.t()
  def device_certificate() do
    true
  end

  @doc """
  Return the signer's X.509 certificate

  The device must be provisioned for this to succeed.
  """
  @spec signer_certificate() :: X509.Certificate.t()
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
    rc = %ATECC508A.Info{}
    {:reply, rc, state}
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
    # I2C.write_read(i2c, @unprovisioned_address)
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

    {:ok, @atecc508a_signature} = I2C.read(state.i2c, state.address, 4)
  end

  defp sleep(state) do
    # See ATECC508A 6.2 for the sleep sequence.
    I2C.write(state.i2c, state.address, <<0x01>>)
  end

  defp microsleep(usec) do
    Process.sleep(round((usec + 999) / 1000))
  end
end
