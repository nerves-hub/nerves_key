defmodule ATECC508A.Certificate do
  @moduledoc """
  Convert between X.509 certificates and ATECC508A compressed certificates

  This is an implementation of the compressed certificate definition described in
  Atmel-8974A-CryptoAuth-ATECC-Compressed-Certificate-Definition-ApplicationNote_112015.
  """

  import X509.ASN1, except: [extension: 2, basic_constraints: 1]
  alias X509.{PublicKey, RDNSequence, SignatureAlgorithm}
  alias X509.Certificate.Template

  @hash :sha256
  @curve :secp256r1
  @validity_years 31
  @version :v3
  @era 2000

  @doc """
  Create a new device certificate.

  The created certificate is compatible with ATECC508A certificate compression.

  Parameters:

  * `atecc508a_public_key` - the public key to be signed (from ATECC508A)
  * `atecc508a_sn` - the ATECC508a's serial number - used to compute the certificate's serial number
  * `manufacturer_sn` - the manufacturer's desired serial number - used as the common name
  * `signer` - the signer's certificate
  * `signer_key` - the signer's private key
  """
  @spec new_device(
          :public_key.ec_public_key(),
          ATECC508A.serial_number(),
          String.t(),
          X509.Certificate.t(),
          :public_key.ec_private_key()
        ) :: X509.Certificate.t()
  def new_device(atecc508a_public_key, atecc508a_sn, manufacturer_sn, signer, signer_key) do
    byte_size(manufacturer_sn) <= 16 || raise "Manufacturer serial number too long"
    subject_rdn = "/CN=" <> manufacturer_sn

    {not_before_dt, not_after_dt} = ATECC508A.Validity.create_compatible_validity(@validity_years)
    compressed_validity = ATECC508A.Validity.compress(not_before_dt, not_after_dt)
    x509_validity = X509.Certificate.Validity.new(not_before_dt, not_after_dt)

    x509_cert_sn = ATECC508A.SerialNumber.from_device_sn(atecc508a_sn, compressed_validity)
    template = device_template(x509_cert_sn, x509_validity)

    X509.Certificate.new(atecc508a_public_key, subject_rdn, signer, signer_key, template: template)
  end

  @doc """
  Create a new signer certificate.

  The signer certificate is a root certificate. I.e. it's not signed by
  anyone else. Signer certificates and their associated private keys
  should be stored safely, though. Their overall use is limited to automating
  the registration of devices to cloud servers like Nerves Hub and
  Amazon IoT. Once a device has registered, the cloud server will
  ignore the signer certificate. It is therefore possible to time limit
  signer certificates, uninstall them from the cloud server, or limit
  the number of devices they can auto-register.

  The created signer certificate is compatible with ATECC508A certificate
  compression.

  Parameters:

  * `validity_years` - how many years is this signer certificate valid
  """
  @spec new_signer(pos_integer()) :: X509.Certificate.t()
  def new_signer(validity_years) do
    # Create a new private key -> consider making this a separate step
    signer_key = X509.PrivateKey.new_ec(@curve)
    signer_public_key = X509.PublicKey.derive(signer_key)

    {not_before_dt, not_after_dt} = ATECC508A.Validity.create_compatible_validity(validity_years)
    compressed_validity = ATECC508A.Validity.compress(not_before_dt, not_after_dt)
    x509_validity = X509.Certificate.Validity.new(not_before_dt, not_after_dt)

    raw_public_key = public_key_to_raw(signer_public_key)
    x509_cert_sn = ATECC508A.SerialNumber.from_public_key(raw_public_key, compressed_validity)

    subject_rdn = X509.RDNSequence.new("/CN=Signer", :otp)

    tbs_cert =
      otp_tbs_certificate(
        version: @version,
        serialNumber: x509_cert_sn,
        signature: SignatureAlgorithm.new(@hash, signer_key),
        issuer: subject_rdn,
        validity: x509_validity,
        subject: subject_rdn,
        subjectPublicKeyInfo: PublicKey.wrap(signer_public_key, :OTPSubjectPublicKeyInfo),
        extensions: [
          X509.Certificate.Extension.basic_constraints(true, 0),
          X509.Certificate.Extension.key_usage([:digitalSignature, :keyCertSign, :cRLSign]),
          X509.Certificate.Extension.ext_key_usage([:serverAuth, :clientAuth]),
          X509.Certificate.Extension.subject_key_identifier(signer_public_key),
          X509.Certificate.Extension.authority_key_identifier(signer_public_key)
        ]
      )

    signer_cert =
      tbs_cert
      |> :public_key.pkix_sign(signer_key)
      |> X509.Certificate.from_der!()

    {signer_cert, signer_key}
  end

  @spec curve() :: :secp256r1
  def curve(), do: @curve

  @spec hash() :: :sha256
  def hash(), do: @hash

  @doc """
  Compress an X.509 certificate for storage in an ATECC508A slot.

  Not all X.509 certificates are compressible. Most aren't. It's probably
  only practical to go through `new_device` and `new_signer`.

  Parameters:

  * `cert` - the certificate to compress
  * `template` - the template that will be used on the decompression side
  """
  # @spec compress(X509.Certificate.t(), ATECC508A.Certificate.Template.t()) ::
  #         ATECC508A.Certificate.Compressed.t()
  def compress(cert, template) do
    compressed_signature =
      signature(cert)
      |> compress_signature()

    compressed_validity =
      X509.Certificate.validity(cert)
      |> compress_validity()

    serial_number_source = serial_number_source(template.sn_source)

    format_version = 0x00
    reserved = 0x00

    data =
      <<compressed_signature::binary-size(64), compressed_validity::binary-size(3),
        template.signer_id::size(16), template.template_id::size(4), template.chain_id::size(4),
        serial_number_source::size(4), format_version::size(4), reserved>>

    %ATECC508A.Certificate.Compressed{
      data: data,
      device_sn: template.device_sn,
      public_key: X509.Certificate.public_key(cert) |> public_key_to_raw(),
      serial_number: X509.Certificate.serial(cert),
      subject_rdn: X509.Certificate.subject(cert),
      issuer_rdn: X509.Certificate.issuer(cert),
      template: template
    }
  end

  @doc """
  Decompress an ECC508A certificate back to it's X.509 form.
  """
  @spec decompress(ATECC508A.Certificate.Compressed.t()) :: X509.Certificate.t()
  def decompress(compressed) do
    <<
      compressed_signature::binary-size(64),
      compressed_validity::binary-size(3),
      signer_id::size(16),
      template_id::size(4),
      chain_id::size(4),
      serial_number_source::size(4),
      format_version::size(4),
      0::size(8)
    >> = compressed.data

    template = compressed.template

    format_version == 0 || raise "Format version mismatch"
    template_id == template.template_id || raise "Template ID mismatch"
    signer_id == template.signer_id || raise "Signer ID mismatch"
    chain_id == template.chain_id || raise "Chain ID mismatch"

    x509_serial_number = decompress_sn(serial_number_source, compressed, compressed_validity)

    subject_public_key = raw_to_public_key(compressed.public_key)

    signature_alg = SignatureAlgorithm.new(@hash, :ecdsa)

    otp_tbs_certificate =
      otp_tbs_certificate(
        version: @version,
        serialNumber: x509_serial_number,
        signature: signature_alg,
        issuer:
          case compressed.issuer_rdn do
            {:rdnSequence, _} -> compressed.issuer_rdn
            name when is_binary(name) -> RDNSequence.new(name, :otp)
          end,
        validity: decompress_validity(compressed_validity),
        subject:
          case compressed.subject_rdn do
            {:rdnSequence, _} -> compressed.subject_rdn
            name when is_binary(name) -> RDNSequence.new(name, :otp)
          end,
        subjectPublicKeyInfo: PublicKey.wrap(subject_public_key, :OTPSubjectPublicKeyInfo),
        extensions: template.extensions
      )

    otp_certificate(
      tbsCertificate: otp_tbs_certificate,
      signatureAlgorithm: signature_alg,
      signature: decompress_signature(compressed_signature)
    )
  end

  @doc """
  Compress an X.509 signature into the raw format expected on the ECC508A
  """
  @spec compress_signature(binary()) :: <<_::512>>
  def compress_signature(signature) do
    <<0x30, _len, 0x02, r_len, r::signed-unit(8)-size(r_len), 0x02, s_len,
      s::signed-unit(8)-size(s_len)>> = signature

    <<r::unsigned-size(256), s::unsigned-size(256)>>
  end

  @doc """
  Decompress an ECC508A signature into X.509 form.
  """
  @spec decompress_signature(<<_::512>>) :: binary()
  def decompress_signature(<<r::binary-size(32), s::binary-size(32)>>) do
    r = unsigned_to_signed_bin(r)
    s = unsigned_to_signed_bin(s)

    r_len = byte_size(r)
    s_len = byte_size(s)

    r = <<0x02, r_len, r::binary>>
    s = <<0x02, s_len, s::binary>>

    len = byte_size(r) + byte_size(s)

    <<0x30, len, r::binary, s::binary>>
  end

  @spec compress_validity(X509.Certificate.Validity.t()) :: ATECC508A.encoded_dates()
  def compress_validity(valid_dates) do
    X509.ASN1.validity(notBefore: {_, not_before_s}, notAfter: {_, not_after_s}) = valid_dates

    not_before = decode_generalized_time(to_string(not_before_s))
    not_after = decode_generalized_time(to_string(not_after_s))
    ATECC508A.Validity.compress(not_before, not_after)
  end

  @spec decompress_validity(ATECC508A.encoded_dates()) :: X509.Certificate.Validity.t()
  def decompress_validity(compressed_validity) do
    {not_before, not_after} = ATECC508A.Validity.decompress(compressed_validity)

    X509.Certificate.Validity.new(not_before, not_after)
  end

  def decompress_sn(0x00, compressed, _compressed_validity) do
    # Stored serial number
    compressed.serial_number
  end

  def decompress_sn(0x0A, compressed, compressed_validity) do
    # Calculated from public key
    ATECC508A.SerialNumber.from_public_key(compressed.public_key, compressed_validity)
  end

  def decompress_sn(0x0B, compressed, compressed_validity) do
    # Calculated from device serial number
    ATECC508A.SerialNumber.from_device_sn(compressed.device_sn, compressed_validity)
  end

  @spec signature(X509.Certificate.t()) :: any()
  def signature(otp_cert) do
    otp_certificate(otp_cert, :signature)
  end

  @spec get_authority_key_identifier(X509.Certificate.t()) :: any()
  def get_authority_key_identifier(otp_certificate) do
    otp_certificate
    |> X509.Certificate.extensions()
    |> X509.Certificate.Extension.find(:authority_key_identifier)
    |> X509.ASN1.extension()
    |> Keyword.get(:extnValue)
    |> X509.ASN1.authority_key_identifier()
    |> Keyword.get(:keyIdentifier)
  end

  @doc """
  Return the raw public key bits from one in X509 form.
  """
  @spec public_key_to_raw(X509.PublicKey.t()) :: ATECC508A.ecc_public_key()
  def public_key_to_raw(public_key) do
    {{:ECPoint, <<4, raw_key::64-bytes>>}, {:namedCurve, {1, 2, 840, 10045, 3, 1, 7}}} =
      public_key

    raw_key
  end

  @doc """
  Convert a raw public key bits to an X509 public key.
  """
  @spec raw_to_public_key(ATECC508A.ecc_public_key()) :: X509.PublicKey.t()
  def raw_to_public_key(raw_key) do
    {{:ECPoint, <<4, raw_key::64-bytes>>}, {:namedCurve, {1, 2, 840, 10045, 3, 1, 7}}}
  end

  # Helpers

  defp unsigned_to_signed_bin(<<1::size(1), _::size(7), _::binary>> = bin),
    do: <<0x00, bin::binary>>

  defp unsigned_to_signed_bin(bin), do: bin

  defp serial_number_source(:random), do: 0x00
  defp serial_number_source(:public_key), do: 0xA
  defp serial_number_source(:device_sn), do: 0xB

  defp serial_number_source(invalid) do
    raise """
    Invalid serial number source : #{inspect(invalid)}
    Must be one of:
      :random - randomly generated
      :public_key - Use the Public Key and encoded dates to generate the certificate serial number.
      :device_sn - Use the unique device serial number and encoded dates to generate the certificate serial number.
    """
  end

  defp device_template(serial, validity) do
    %Template{
      serial: serial,
      validity: validity,
      hash: @hash,
      extensions: [
        basic_constraints: X509.Certificate.Extension.basic_constraints(false),
        key_usage: X509.Certificate.Extension.key_usage([:digitalSignature, :keyEncipherment]),
        ext_key_usage: X509.Certificate.Extension.ext_key_usage([:clientAuth]),
        subject_key_identifier: false,
        authority_key_identifier: true
      ]
    }
    |> Template.new()
  end

  defp decode_generalized_time(timestamp) do
    <<year::binary-unit(8)-size(2), month::binary-unit(8)-size(2), day::binary-unit(8)-size(2),
      hour::binary-unit(8)-size(2), minute::binary-unit(8)-size(2),
      second::binary-unit(8)-size(2), "Z">> = timestamp

    NaiveDateTime.new(
      String.to_integer(year) + @era,
      String.to_integer(month),
      String.to_integer(day),
      String.to_integer(hour),
      String.to_integer(minute),
      String.to_integer(second)
    )
    |> case do
      {:ok, naive_date_time} ->
        DateTime.from_naive!(naive_date_time, "Etc/UTC")

      error ->
        error
    end
  end
end
