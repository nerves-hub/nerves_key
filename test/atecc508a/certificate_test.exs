defmodule ATECC508A.CertificateTest do
  use ExUnit.Case
  doctest ATECC508A.Certificate

  setup_all do
    generate_ca()
  end

  test "new", %{ca: signer, ca_key: signer_key} do
    private_key =
      ATECC508A.Certificate.curve()
      |> X509.PrivateKey.new_ec()

    public_key = X509.PublicKey.derive(private_key)

    serial = ATECC508A.SerialNumber.random()

    otp_cert = ATECC508A.Certificate.new(public_key, serial, "/O=MyOrg", signer, signer_key)
    assert X509.Certificate.serial(otp_cert) == serial
  end

  test "compress", %{ca: signer, ca_key: signer_key} do
    private_key =
      ATECC508A.Certificate.curve() |> X509.PrivateKey.new_ec()

    public_key = X509.PublicKey.derive(private_key)

    serial = ATECC508A.SerialNumber.random()

    otp_cert = ATECC508A.Certificate.new(public_key, serial, "/O=MyOrg", signer, signer_key)

    compressed = ATECC508A.Certificate.compress(otp_cert)
    assert byte_size(compressed) == 72
  end

  test "decompress", %{ca: signer, ca_key: signer_key} do
    private_key =
      ATECC508A.Certificate.curve() |> X509.PrivateKey.new_ec()

    public_key = X509.PublicKey.derive(private_key)

    serial = ATECC508A.SerialNumber.random()

    otp_cert = ATECC508A.Certificate.new(public_key, serial, "/O=MyOrg", signer, signer_key)

    compressed = ATECC508A.Certificate.compress(otp_cert)
    decompressed = ATECC508A.Certificate.decompress(compressed, public_key, "/O=MyOrg", fn(_) -> serial end, fn(_) -> signer end)
    assert otp_cert == decompressed
  end

  test "compress and decompress signature", %{ca: signer, ca_key: signer_key} do
    private_key =
      ATECC508A.Certificate.curve() |> X509.PrivateKey.new_ec()

    public_key = X509.PublicKey.derive(private_key)

    serial = ATECC508A.SerialNumber.random()

    otp_cert = ATECC508A.Certificate.new(public_key, serial, "/O=MyOrg", signer, signer_key)

    signature = ATECC508A.Certificate.signature(otp_cert)

    compressed_signature = ATECC508A.Certificate.compress_signature(signature)
    assert ATECC508A.Certificate.decompress_signature(compressed_signature) == signature
  end

  test "compress and decompress validity", %{ca: signer, ca_key: signer_key} do
    private_key =
      ATECC508A.Certificate.curve() |> X509.PrivateKey.new_ec()

    public_key = X509.PublicKey.derive(private_key)

    serial = ATECC508A.SerialNumber.random()

    otp_cert = ATECC508A.Certificate.new(public_key, serial, "/O=MyOrg", signer, signer_key)

    validity = X509.Certificate.validity(otp_cert)

    compressed_validity = ATECC508A.Certificate.compress_validity(validity)

    assert ATECC508A.Certificate.decompress_validity(compressed_validity) == validity
  end

  defp generate_ca() do
    opts = [
      serial: ATECC508A.SerialNumber.random(),
      hash: ATECC508A.Certificate.hash(),
      extensions: [
        key_usage: X509.Certificate.Extension.key_usage([:keyCertSign, :cRLSign]),
        basic_constraints: X509.Certificate.Extension.basic_constraints(true),
        subject_key_identifier: true,
        authority_key_identifier: false
      ]
    ]

    template = X509.Certificate.Template.new(:root_ca, opts)
    ca_key = X509.PrivateKey.new_ec(ATECC508A.Certificate.curve())
    subject_rdn = "/O=MyOrg Root"
    ca = X509.Certificate.self_signed(ca_key, subject_rdn, template: template)
    %{ca: ca, ca_key: ca_key}
  end

end
