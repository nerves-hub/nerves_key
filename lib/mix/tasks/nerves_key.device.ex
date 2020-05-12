defmodule Mix.Tasks.NervesKey.Device do
  use Mix.Task

  @shortdoc "Simulate NervesKey device key creation"

  @moduledoc """
  Create a device certificate without a NervesKey

  ## create

  This simulates certification creation if you don't have a NervesKey.

  While this doesn't make any sense if you're using NervesKeys, it can
  be handy in testing device certs that look like they're from NervesKeys.

    mix nerves_key.device create NAME --signing-cert <CERT> --signing-key <KEY>

  If --years-valid is unspecified, the new certificate will be valid for
  one year.
  """

  @switches [signing_cert: :string, signing_key: :string]

  def run(args) do
    {opts, args} = OptionParser.parse!(args, strict: @switches)

    case args do
      ["create", name] ->
        create(name, opts)

      _ ->
        usage()
    end
  end

  @spec usage() :: no_return()
  def usage() do
    Mix.raise("""
    Invalid arguments to `mix nerves_key.device`.

    Usage:
      mix nerves_key.device create NAME --signing-cert <CERT> --signing-key <KEY>

    Run `mix help nerves_key.device` for more information.
    """)
  end

  @spec create(String.t(), keyword()) :: :ok
  def create(name, opts) do
    cert_path = name <> ".cert"
    key_path = name <> ".key"

    if File.exists?(cert_path) do
      Mix.raise("Refusing to overwrite #{cert_path}. Please remove or change the name")
    end

    if File.exists?(key_path) do
      Mix.raise("Refusing to overwrite #{key_path}. Please remove or change the name")
    end

    signer_cert_path = Keyword.fetch!(opts, :signing_cert)
    signer_key_path = Keyword.fetch!(opts, :signing_key)

    signer_cert = File.read!(signer_cert_path) |> X509.Certificate.from_pem!()
    signer_key = File.read!(signer_key_path) |> X509.PrivateKey.from_pem!()

    device_key = X509.PrivateKey.new_ec(ATECC508A.Certificate.curve())
    device_public_key = X509.PublicKey.derive(device_key)
    atecc508a_serial_number = :crypto.strong_rand_bytes(9)

    cert =
      ATECC508A.Certificate.new_device(
        device_public_key,
        atecc508a_serial_number,
        name,
        signer_cert,
        signer_key
      )

    pem_cert = X509.Certificate.to_pem(cert)
    pem_key = X509.PrivateKey.to_pem(device_key)

    File.write!(cert_path, pem_cert)
    File.write!(key_path, pem_key)

    Mix.shell().info("""
    Created device cert, #{cert_path} and private key, #{key_path}.

    Please store #{key_path} in a safe place.

    IMPORTANT: These are for debug purposes only. NervesKey or other ATECC508A/608A devices
    should be used to create real certs since they protect the private keys.
    """)
  end
end
