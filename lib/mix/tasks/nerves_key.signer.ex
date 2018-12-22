defmodule Mix.Tasks.NervesKey.Signer do
  use Mix.Task

  @shortdoc "Manages NervesKey signing keys"

  @moduledoc """
  Manages NervesKey signing keys

  ## create

  Create a new NervesKey signing certificate and private key pair.  This
  creates a compressible X.509 certificate that can be stored in the
  ATECC508A's limited memory.

    mix nerves_key.signer create NAME --years-valid <YEARS>

  If --years-valid is unspecified, the new certificate will be valid for
  one year.
  """

  @switches [years_valid: :integer]

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
    Invalid arguments to `mix nerves_key.signer`.

    Usage:
      mix nerves_key.key create NAME --years-valid <YEARS>

    Run `mix help nerves_key.signer` for more information.
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

    {cert, priv_key} = NervesKey.create_signing_key_pair(opts)
    pem_cert = X509.Certificate.to_pem(cert)
    pem_key = X509.PrivateKey.to_pem(priv_key)

    File.write!(cert_path, pem_cert)
    File.write!(key_path, pem_key)

    Mix.shell().info("""
    Created signing cert, #{cert_path} and private key, #{key_path}.

    Please store #{key_path} in a safe place.

    #{cert_path} is ready to be uploaded to the servers that need
    to authenticate devices signed by the private key.
    """)
  end
end
