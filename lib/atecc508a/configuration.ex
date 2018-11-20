defmodule ATECC508A.Configuration do
  @moduledoc """
  This module handles operations on the configuration zone.
  """

  alias ATECC508A.{Request, Transport}

  @doc """
  Read the entire contents of the configuration zone
  """
  @spec read_all(Transport.t()) :: {:ok, <<_::1024>>} | {:error, atom()}
  def read_all(transport) do
    with {:ok, lo} <- Request.read_zone(transport, :config, 0, 32),
         {:ok, mid} <- Request.read_zone(transport, :config, 8, 32),
         {:ok, hi} <- Request.read_zone(transport, :config, 16, 32),
         {:ok, hi2} <- Request.read_zone(transport, :config, 24, 32) do
      {:ok, lo <> mid <> hi <> hi2}
    end
  end

  @doc """
  Read the current slot configuration
  """
  @spec read_slot_config(Transport.t()) :: {:ok, <<_::256>>} | {:error, atom()}
  def read_slot_config(transport) do
    case read_all(transport) do
      {:ok, data} ->
        <<_::20-bytes, slot_config::32-bytes, _::binary>> = data
        {:ok, slot_config}

      error ->
        error
    end
  end

  @doc """
  Write a slot configuration.
  """
  @spec write_slot_config(Transport.t(), <<_::256>>) :: :ok | {:error, atom()}
  def write_slot_config(transport, data) when byte_size(data) == 32 do
    multi_write(transport, 20, data)
  end

  @doc """
  Read the current slot configuration
  """
  @spec read_key_config(Transport.t()) :: {:ok, <<_::256>>} | {:error, atom()}
  def read_key_config(transport) do
    case read_all(transport) do
      {:ok, data} ->
        <<_::96-bytes, key_config::32-bytes>> = data
        {:ok, key_config}

      error ->
        error
    end
  end

  @doc """
  Write the key configuration.
  """
  @spec write_key_config(Transport.t(), <<_::256>>) :: :ok | {:error, atom()}
  def write_key_config(transport, data) when byte_size(data) == 32 do
    multi_write(transport, 96, data)
  end

  defp multi_write(_transport, _addr, <<>>), do: :ok

  defp multi_write(transport, offset, <<four_bytes::4-bytes, rest::binary>>) do
    addr = Request.to_config_addr(offset)

    case Request.write_zone(transport, :config, addr, four_bytes) do
      :ok -> multi_write(transport, offset + 4, rest)
      error -> error
    end
  end
end
