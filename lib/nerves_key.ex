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
    # :ok = OTP.write(transport, otp)
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

    # :ok = Data.lock(transport, otp_data, slot_data)
    IO.puts(
      "Skipping the call to Data.lock(transport, #{inspect(otp_data, limit: :infinity)}, #{
        inspect(slot_data, limit: :infinity)
      })"
    )

    IO.puts("The device certificate is #{inspect(device_cert, limit: :infinity)}")
    :ok
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
