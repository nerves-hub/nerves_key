defmodule ATECC508A.Sim508A do
  @moduledoc """
  This is a simulated ATECC508A for creating things normally created
  on the ATECC508A
  """

  @slot0_private_key ATECC508A.Certificate.curve() |> X509.PrivateKey.new_ec()
  @slot0_public_key X509.PublicKey.derive(@slot0_private_key)

  @doc """
  Our simulated ECC508A has an easy-to-remember serial number
  """
  def serial_number() do
    <<1, 2, 3, 4, 5, 6, 7, 8, 9>>
  end

  @doc """
  "Create" a public/private key pair; return the public key in
  OTP record format.
  """
  @spec otp_genkey() :: :public_key.ec_public_key()
  def otp_genkey() do
    @slot0_public_key
  end

  @doc """
  "Create" a public/private key pair, but return the public key as bytes
  """
  def genkey() do
    nil
  end
end
