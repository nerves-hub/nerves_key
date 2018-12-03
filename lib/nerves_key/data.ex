defmodule NervesKey.Data do
  @moduledoc """
  This module handles Data Zone data stored in the Nerves Key.
  """

  alias ATECC508A.{DataZone, Request, Transport, Util}

  # @doc """
  # Read the device certificate
  # """
  # @spec read_device_certificate(Transport.t()) :: {:ok, X509.Certificate.t()} | {:error, atom()}
  # def read_device_certificate(transport) do
  #   with {:ok, compressed_cert} <- DataZone.read(transport, 10),
  #        {:ok, public_key} <- Request.genkey(transport, 0, false),

  #   do
  #     cert = ATECC508A.Certificate.decompress(compressed_cert, public_key)
  #   end
  # end
end
