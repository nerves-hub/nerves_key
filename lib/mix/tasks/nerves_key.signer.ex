defmodule Mix.Tasks.NervesKey.Signer do
  use Mix.Task

  @shortdoc "Manages NervesKey signing keys"

  @moduledoc """
  Manages NervesKey signing keys

  ## create

  Create a new NervesKey signing key pair with the specified name

    mix nerves_key.signer create NAME

  """

  @switches []

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
    Mix.shell().raise("""
    Invalid arguments to `mix nerves_key.signer`.

    Usage:
      mix nerves_key.key create NAME

    Run `mix help nerves_key.signer` for more information.
    """)
  end

  @spec create(String.t(), keyword()) :: :ok
  def create(name, _opts) do
    {cert, priv_key} = NervesKey.create_signing_key_pair()
    pem_cert = X509.Certificate.to_pem(cert)
    pem_key = X509.PrivateKey.to_pem(priv_key)

    File.write!(name <> ".cert", pem_cert)
    File.write!(name <> ".key", pem_key)

    Mix.shell().info("Created signing cert and private key.")
  end
end
