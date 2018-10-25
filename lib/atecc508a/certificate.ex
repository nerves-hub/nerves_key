defmodule ATECC508A.Certificate do
  @moduledoc """
  Convert between X.509 certificates and ATECC508A compressed certificates
  """

  import X509.Certificate.Extension, except: [authority_key_identifier: 1]
  import X509.ASN1, except: [extension: 2, basic_constraints: 1]
  alias X509.{PublicKey, RDNSequence, SignatureAlgorithm}
  alias X509.Certificate.{Template, Validity}

  @hash :sha256
  @curve :secp256r1
  @validity_years 31
  @era 2000
  @version :v3

  def new(public_key, serial, subject_rdn, signer, signer_key) do
    template = template(serial)
    X509.Certificate.new(public_key, subject_rdn, signer, signer_key, template: template)
  end

  def curve(), do: @curve
  def hash(), do: @hash

  # Serial number source needs to be passed in for the first time so we
  # can know what to set the source to when compressing
  def compress(cert, opts \\ []) do
    signature =
      signature(cert)
      |> compress_signature()

    encoded_dates =
      X509.Certificate.validity(cert)
      |> compress_validity()

    signer_id = opts[:signer_id] || 0x00
    signer_id = <<signer_id :: size(16)>>

    serial_number_source = opts[:serial_number_source] || :device_sn

    # Template ID
    #  0:   Use the device template
    #  1:   Use the signer template
    #  (n): issuer template or higher
    template_id = 1
    chain_id = 0
    serial_number_source = serial_number_source(serial_number_source)
    format_version= 0x00
    reserved = <<0x00>>

    signature <>
    encoded_dates <>
    signer_id <>
    <<template_id :: size(4), chain_id :: size(4)>> <>
    <<serial_number_source :: size(4), format_version :: size(4)>> <>
    reserved
  end

  def decompress(compressed_cert, public_key, subject_rdn, serial_fun, signer_fun) do
    <<
      compressed_signature :: binary-size(64),
      encoded_dates :: binary-size(3),
      signer_id :: size(16),
      _template_id :: size(4),
      _chain_id :: size(4),
      serial_number_source :: size(4),
      _format_version :: size(4),
      _reserved :: size(8)
    >> = compressed_cert


    serial_number = serial_fun.(serial_number_source)
    signer = signer_fun.(signer_id)

    template =
      template(serial_number)
      |> Template.update_ski(public_key)
      |> Template.update_aki(signer)

    signer_rdn =
      case signer do
        certificate(tbsCertificate: tbs) ->
          # FIXME: avoid calls to undocumented functions in :public_key app
          tbs
          |> otp_tbs_certificate(:subject)
          |> :pubkey_cert_records.transform(:decode)

        otp_certificate(tbsCertificate: tbs) ->
          otp_tbs_certificate(tbs, :subject)
      end

    signature_alg = SignatureAlgorithm.new(@hash, :ecdsa)

    otp_tbs_certificate =
      otp_tbs_certificate(
        version: @version,
        serialNumber: serial_number,
        signature: signature_alg,
        issuer:
          case signer_rdn do
            {:rdnSequence, _} -> signer_rdn
            name when is_binary(name) -> RDNSequence.new(name, :otp)
          end,
        validity: decompress_validity(encoded_dates),
        subject:
          case subject_rdn do
            {:rdnSequence, _} -> subject_rdn
            name when is_binary(name) -> RDNSequence.new(name, :otp)
          end,
        subjectPublicKeyInfo: PublicKey.wrap(public_key, :OTPSubjectPublicKeyInfo),
        extensions:
          template.extensions
          |> Keyword.values()
          |> Enum.reject(&(&1 == false))
      )
    otp_certificate(
      tbsCertificate: otp_tbs_certificate,
      signatureAlgorithm: signature_alg,
      signature: decompress_signature(compressed_signature)
    )
  end

  def compress_signature(signature) do
    <<0x30, _len, 0x02, r_len, r :: signed-unit(8)-size(r_len), 0x02, s_len, s :: signed-unit(8)-size(s_len)>> = signature
    r = :binary.encode_unsigned(r)
    s = :binary.encode_unsigned(s)
    r <> s
  end

  def decompress_signature(<<r :: binary-size(32), s :: binary-size(32)>>) do
    r = unsigned_to_signed_bin(r)
    s = unsigned_to_signed_bin(s)

    r_len = byte_size(r)
    s_len = byte_size(s)

    r = <<0x02, r_len>> <> r
    s = <<0x02, s_len>> <> s

    value = r <> s
    len = byte_size(value)

    <<0x30, len>> <> value
  end

  def compress_validity(validity() = validity) do
    [notBefore: {_, not_before}, notAfter: {_, not_after}] = validity(validity)
    not_before = decode_generalized_time(to_string(not_before))
    not_after = decode_generalized_time(to_string(not_after))
    expire_years = not_after.year - not_before.year
    year = not_before.year - @era
    month = not_before.month
    day = not_before.day
    hour = not_before.hour

    <<year :: size(5), month :: size(4), day :: size(5), hour :: size(5), expire_years :: size(5)>>
  end

  def decompress_validity(compressed_validity) do
    <<
      year :: size(5),
      month :: size(4),
      day :: size(5),
      hour :: size(5),
      expire_years :: size(5)
    >> = compressed_validity

    not_before = %DateTime{
      year: year + @era,
      month: month,
      day: day,
      hour: hour,
      minute: 0,
      second: 0,
      std_offset: 0,
      utc_offset: 0,
      zone_abbr: "UTC",
      time_zone: "Etc/UTC"
    }

    not_after = %{not_before |
      year: not_before.year + expire_years
    }

    Validity.new(not_before, not_after)
  end

  def signature(otp_cert) do
    otp_certificate(otp_cert, :signature)
  end

  def get_authority_key_identifier(otp_certificate) do
    otp_certificate
    |> X509.Certificate.extensions()
    |> X509.Certificate.Extension.find(:authority_key_identifier)
    |> extension()
    |> Keyword.get(:extnValue)
    |> authority_key_identifier()
    |> Keyword.get(:keyIdentifier)
  end

  # Helpers

  defp unsigned_to_signed_bin(<<1 :: size(1), _ :: size(7), _:: binary>> = bin), do: <<0x00>> <> bin
  defp unsigned_to_signed_bin(bin), do: bin

  defp serial_number_source(:random), do: 0x00
  defp serial_number_source(:public_key), do: 0xA
  defp serial_number_source(:device_sn), do: 0xB
  defp serial_number_source(invalid) do
    raise """
    Invalid serial number source : #{inspect invalid}
    Must be one of:
      :random - randomly generated
      :public_key - Use the Public Key and encoded dates to generate the certificate serial number.
      :device_sn - Use the unique device serial number and encoded dates to generate the certificate serial number.
    """
  end

  defp template(serial) do
    %Template{
      serial: serial,
      validity: years(@validity_years),
      hash: @hash,
      extensions: [
        basic_constraints: basic_constraints(false),
        key_usage: key_usage([:digitalSignature, :keyEncipherment]),
        ext_key_usage: ext_key_usage([:clientAuth]),
        subject_key_identifier: false,
        authority_key_identifier: true
      ]
    }
    |> Template.new()
  end

  defp years(years) do
    now =
      DateTime.utc_now()
      |> trim()

    not_before = now
    not_after = Map.put(now, :year, now.year + years)
    Validity.new(not_before, not_after)
  end

  defp trim(datetime) do
    datetime
    |> Map.put(:minute, 0)
    |> Map.put(:second, 0)
    |> Map.put(:microsecond, {0, 0})
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
