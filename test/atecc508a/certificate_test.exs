defmodule ATECC508A.CertificateTest do
  use ExUnit.Case
  doctest ATECC508A.Certificate
  alias ATECC508A.Sim508A

  setup_all do
    generate_ca()
  end

  test "new signer cert" do
    {signer_cert, _signer_key} = ATECC508A.Certificate.new_signer(2)

    rdn = signer_cert |> X509.Certificate.subject() |> X509.RDNSequence.to_string()

    assert rdn == "/CN=Signer"

    # TODO - test self-signed?
  end

  test "signer certs can be compressed" do
    {signer_cert, _signer_key} = ATECC508A.Certificate.new_signer(1)

    compressed_cert = ATECC508A.Certificate.compress(signer_cert)
    decompressed_cert = ATECC508A.Certificate.decompress(compressed_cert, public_key, subject_rdn, serial_fun, signer_fun)
    assert decompressed_cert == signer_cert
  end

  test "new device cert", %{ca: signer, ca_key: signer_key} do
    public_key = Sim508A.otp_genkey()
    ecc508a_sn = Sim508A.serial_number()
    manufacturing_sn = "1234"

    ecc508a_validity =
      ATECC508A.Validity.create_compatible_validity(31)
      |> ATECC508A.Validity.compress()

    cert_sn = ATECC508A.SerialNumber.from_device_sn(ecc508a_sn, ecc508a_validity)

    otp_cert =
      ATECC508A.Certificate.new_device(
        public_key,
        ecc508a_sn,
        manufacturing_sn,
        signer,
        signer_key
      )

    assert X509.Certificate.serial(otp_cert) == cert_sn
  end

  test "compress", %{ca: signer, ca_key: signer_key} do
    public_key = Sim508A.otp_genkey()
    ecc508a_sn = Sim508A.serial_number()
    manufacturing_sn = "1234"

    otp_cert =
      ATECC508A.Certificate.new_device(
        public_key,
        ecc508a_sn,
        manufacturing_sn,
        signer,
        signer_key
      )

    compressed = ATECC508A.Certificate.compress(otp_cert)
    assert byte_size(compressed.data) == 72
    assert compressed.device_sn == ecc508a_sn
  end

  test "decompress", %{ca: signer, ca_key: signer_key} do
    public_key = Sim508A.otp_genkey()
    ecc508a_sn = Sim508A.serial_number()
    manufacturing_sn = "1234"

    ecc508a_validity =
      ATECC508A.Validity.create_compatible_validity(31)
      |> ATECC508A.Validity.compress()

    cert_sn = ATECC508A.SerialNumber.from_device_sn(ecc508a_sn, ecc508a_validity)

    otp_cert =
      ATECC508A.Certificate.new_device(
        public_key,
        ecc508a_sn,
        manufacturing_sn,
        signer,
        signer_key
      )

    compressed = ATECC508A.Certificate.compress(otp_cert)

    decompressed =
      ATECC508A.Certificate.decompress(
        compressed,
        public_key,
        "/CN=#{manufacturing_sn}",
        fn _ -> cert_sn end,
        fn _ -> signer end
      )

    assert otp_cert == decompressed
  end

  test "compress and decompress signature", %{ca: signer, ca_key: signer_key} do
    public_key = Sim508A.otp_genkey()
    ecc508a_sn = Sim508A.serial_number()
    manufacturing_sn = "1234"

    otp_cert =
      ATECC508A.Certificate.new_device(
        public_key,
        ecc508a_sn,
        manufacturing_sn,
        signer,
        signer_key
      )

    signature = ATECC508A.Certificate.signature(otp_cert)

    compressed_signature = ATECC508A.Certificate.compress_signature(signature)
    assert ATECC508A.Certificate.decompress_signature(compressed_signature) == signature
  end

  test "compress and decompress validity", %{ca: signer, ca_key: signer_key} do
    public_key = Sim508A.otp_genkey()
    ecc508a_sn = Sim508A.serial_number()
    manufacturing_sn = "1234"

    otp_cert =
      ATECC508A.Certificate.new_device(
        public_key,
        ecc508a_sn,
        manufacturing_sn,
        signer,
        signer_key
      )

    validity = X509.Certificate.validity(otp_cert)

    compressed_validity = ATECC508A.Certificate.compress_validity(validity)

    assert ATECC508A.Certificate.decompress_validity(compressed_validity) == validity
  end

  defp generate_ca() do
    {ca, ca_key} = ATECC508A.Certificate.new_signer(1)
    %{ca: ca, ca_key: ca_key}
  end
end
