defmodule NervesKey do
  @moduledoc """
  This is a high level interface to provisioning and using the Nerves Key
  or any ATECC508A/608A that can be configured similarly.
  """

  alias NervesKey.{Config, OTP, Data}

  @build_year DateTime.utc_now().year

  @doc """
  Configure an ATECC508A or ATECC608A as a Nerves Key.
  """
  def configure(transport) do
    cond do
      Config.config_compatible?(transport) == {:ok, true} -> :ok
      Config.configured?(transport) == {:ok, true} -> {:error, :config_locked}
      true -> Config.configure(transport)
    end
  end

  @doc """
  Create a signing key pair

  This returns a tuple that contains the certificate and the private key.
  """
  def create_signing_key_pair() do
    ATECC508A.Certificate.new_signer(1)
  end

  @doc """
  Read the device certificate from the slot
  """
  @spec device_cert(ATECC508A.Transport.t()) :: X509.Certificate.t()
  def device_cert(transport) do
    {:ok, device_sn} = Config.device_sn(transport)
    {:ok, device_data} = ATECC508A.DataZone.read(transport, 10)
    {:ok, signer_public_key} = ATECC508A.DataZone.read(transport, 11)
    {:ok, %OTP{manufacturer_sn: serial_number}} = OTP.read(transport)
    {:ok, raw_public_key} = ATECC508A.Request.genkey(transport, 0, false)
    template = ATECC508A.Certificate.Template.device(device_sn, signer_public_key)

    compressed = %ATECC508A.Certificate.Compressed{
      data: device_data,
      device_sn: device_sn,
      serial_number: serial_number,
      public_key: raw_public_key,
      template: template,
      issuer_rdn: "/CN=Signer",
      subject_rdn: "/CN=" <> device_sn
    }

    ATECC508A.Certificate.decompress(compressed)
  end

  @doc """
  Read the signer certificate from the slot
  """
  @spec signer_cert(ATECC508A.Transport.t()) :: X509.Certificate.t()
  def signer_cert(transport) do
    {:ok, signer_data} = ATECC508A.DataZone.read(transport, 12)
    {:ok, signer_public_key} = ATECC508A.DataZone.read(transport, 11)
    template = ATECC508A.Certificate.Template.signer(signer_public_key)

    compressed = %ATECC508A.Certificate.Compressed{
      data: signer_data,
      public_key: signer_public_key,
      template: template,
      issuer_rdn: "/CN=Signer",
      subject_rdn: "/CN=Signer"
    }

    ATECC508A.Certificate.decompress(compressed)
  end

  @doc """
  Provision a NervesKey in one step

  This function does it all, but it requires the signer's private key.
  """
  @spec provision(
          ATECC508A.Transport.t(),
          NervesKey.ProvisioningInfo.t(),
          X509.Certificate.t(),
          X509.PrivateKey.t()
        ) :: :ok
  def provision(transport, info, signer_cert, signer_key) do
    check_time()

    :ok = configure(transport)
    otp_info = OTP.new(info.board_name, info.manufacturer_sn)
    otp_data = OTP.to_raw(otp_info)
    :ok = OTP.write(transport, otp_data)

    {:ok, device_public_key} = Data.genkey(transport)
    {:ok, device_sn} = Config.device_sn(transport)

    device_cert =
      ATECC508A.Certificate.new_device(
        device_public_key,
        device_sn,
        info.manufacturer_sn,
        signer_cert,
        signer_key
      )

    slot_data = Data.slot_data(device_sn, device_cert, signer_cert)

    :ok = Data.write_slots(transport, slot_data)

    # No turning back!!

    :ok = Data.lock(transport, otp_data, slot_data)
  end

  defp check_time() do
    unless DateTime.utc_now().year >= @build_year do
      raise """
      It doesn't look like the clock has been set. Check that `nerves_time` is running
      or something else is providing time.
      """
    end
  end
end
