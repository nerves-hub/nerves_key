defmodule NervesKey.Data do
  @moduledoc """
  This module handles Data Zone data stored in the Nerves Key.
  """

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

  @doc """
  Create a public/private key pair

  The public key is returned on success. This can only be called on devices that
  have their configuration locked, but not their data.
  """
  @spec genkey(ATECC508A.Transport.t()) :: {:ok, X509.PublicKey.t()} | {:error, atom()}
  def genkey(transport) do
    with {:ok, raw_key} = ATECC508A.Request.genkey(transport, 0, true) do
      {:ok, ATECC508A.Certificate.raw_to_public_key(raw_key)}
    end
  end

  @spec write_certificates(ATECC508A.Transport.t(), X509.Certificate.t(), X509.Certificate.t()) ::
          :ok | {:error, atom()}
  def write_certificates(transport, device_cert, signer_cert) do
    {:ok, device_sn} = NervesKey.Config.device_sn(transport)
    device_template = ATECC508A.Certificate.Template.device(device_sn)
    device_compressed = ATECC508A.Certificate.compress(device_cert, device_template)
    :ok = ATECC508A.DataZone.write_padded(transport, 10, device_compressed.data)

    signer_template = ATECC508A.Certificate.Template.signer()
    signer_compressed = ATECC508A.Certificate.compress(signer_cert, signer_template)
    :ok = ATECC508A.DataZone.write_padded(transport, 11, signer_compressed.public_key)
    :ok = ATECC508A.DataZone.write_padded(transport, 12, signer_compressed.data)
  end
end
