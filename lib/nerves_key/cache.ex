defmodule NervesKey.Cache do
  @moduledoc false
  use GenServer

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec cache_device_cert(ATECC508A.Transport.t(), X509.Certificate.t()) :: :ok
  def cache_device_cert(transport, cert) do
    transport_info = ATECC508A.Transport.info(transport)

    GenServer.cast(
      __MODULE__,
      {:cache_device_cert, {transport_info.bus_name, transport_info.address}, cert}
    )
  end

  @spec cache_signer_cert(ATECC508A.Transport.t(), X509.Certificate.t()) :: :ok
  def cache_signer_cert(transport, cert) do
    transport_info = ATECC508A.Transport.info(transport)

    GenServer.cast(
      __MODULE__,
      {:cache_signer_cert, {transport_info.bus_name, transport_info.address}, cert}
    )
  end

  @spec device_cert(ATECC508A.Transport.t()) :: {:ok, X509.Certificate.t()} | nil
  def device_cert(transport) do
    transport_info = ATECC508A.Transport.info(transport)
    GenServer.call(__MODULE__, {:device_cert, {transport_info.bus_name, transport_info.address}})
  end

  @spec signer_cert(ATECC508A.Transport.t()) :: {:ok, X509.Certificate.t()} | nil
  def signer_cert(transport) do
    transport_info = ATECC508A.Transport.info(transport)
    GenServer.call(__MODULE__, {:signer_cert, {transport_info.bus_name, transport_info.address}})
  end

  @impl GenServer
  def init(_) do
    {:ok, %{device_certs: %{}, signer_certs: %{}}}
  end

  @impl GenServer
  def handle_cast({:cache_device_cert, info, cert}, state) do
    {:noreply, %{state | device_certs: Map.put(state.device_certs, info, cert)}}
  end

  def handle_cast({:cache_signer_cert, info, cert}, state) do
    {:noreply, %{state | signer_certs: Map.put(state.signer_certs, info, cert)}}
  end

  @impl GenServer
  def handle_call({:device_cert, info}, _from, state) do
    case Map.get(state.device_certs, info) do
      nil -> {:reply, nil, state}
      cert -> {:reply, {:ok, cert}, state}
    end
  end

  def handle_call({:signer_cert, info}, _from, state) do
    case Map.get(state.signer_certs, info) do
      nil -> {:reply, nil, state}
      cert -> {:reply, {:ok, cert}, state}
    end
  end
end
