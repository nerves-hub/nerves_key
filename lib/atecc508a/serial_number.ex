defmodule ATECC508A.SerialNumber do
  @moduledoc """
  Compute X.509 certificate serial numbers
  """

  @doc """
  Compute a certificate serial number based on the device's
  9-byte serial number and the encoded issue/expire date.
  This is used for device certificates.

  Returns the serial number
  """
  @spec from_device_sn(ATECC508A.serial_number(), ATECC508A.encoded_dates()) :: non_neg_integer()
  def from_device_sn(device_sn, encoded_dates) do
    <<_::2, hash126::126, _::128>> = :crypto.hash(:sha256, [device_sn, encoded_dates])
    <<sn::128>> = <<0b01::2, hash126::126>>
    sn
  end

  @doc """
  Compute a certificate serial number based on the certificate's
  public key. This can be used for signer certificates.
  """
  @spec from_public_key(ATECC508A.ecc_public_key(), ATECC508A.encoded_dates()) ::
          non_neg_integer()
  def from_public_key(public_key, encoded_dates) do
    <<_::2, hash126::126, _::128>> = :crypto.hash(:sha256, [public_key, encoded_dates])
    <<sn::128>> = <<0b01::2, hash126::126>>
    sn
  end
end
