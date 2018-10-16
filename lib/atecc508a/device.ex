defmodule ATECC508A.Device do
  use GenServer

  alias ElixirCircuits.I2C

  @unprovisioned_address 0xC0

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
  Return the state of the module

  * :unconfigured - this is a fresh ATECC508A that hasn't been configured yet
  * :configured - the configuration has been programmed and locked, but required data hasn't been written
  * :provisioned - the device has been provisioned and is locked
  * :errored - the device has an unexpected configuration or it's locked with unexpected data
  """
  @spec state() :: provisioning_state()
  def state() do
    :unconfigured
  end

  @doc """
  Write and lock the configuration of the ATECC508A

  This is the first step in the provisioning process.
  """
  @spec configure() :: :ok | {:error, String.t()}
  def configure() do
    {:error, "unimplemented"}
  end

  @doc """
  Once the configuration is locked, call this function to create the device key

  The public key part is returned on success so that it may be signed.
  """
  @spec create_device_key_pair() :: {:ok, ATECC508A.ecc_public_key()} | {:error, String.t}
  def create_device_key_pair() do
    {:error, "unimplemented"}
  end

  @doc """
  Finalize the provisioning of the device

  See ATECC508A for all of the information that's needed. This function will
  write that data to the appropriate locations and lock the device. After this
  call, none of this data can change. If you made a mistake, cry a little and
  then replace the ATECC508 with a new one.
  """
  @spec provision(ATECC508A.ProvisioningInfo.t()) :: :ok | {:error, String.t}
  def provision(provisioning_info) do

    {:error, "unimplemented"}
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
    %ATECC508A.Info{}
  end

  def init(_args) do

    device = Application.get_env(:atecc508a, :i2c_device, "/dev/i2c-1")
    address = Application.get_env(:atecc508a, :address, 0xB0)

    {:ok, i2c} = I2C.open(device, address)

    {:ok, %State{i2c: i2c, address: address}, {:continue, :init}}
  end

  def handle_continue(:init, state) do

    {:noreply, state}
  end
end
