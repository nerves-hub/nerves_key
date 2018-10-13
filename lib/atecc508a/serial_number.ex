defmodule ATECC508A.SerialNumber do
  @moduledoc """
  Compute X.509 certificate serial numbers
  """

  @doc """
  Compute a certificate serial number based on the devices 9
  byte serial number and the encoded issue/expire date.

  Returns the serial number
  """
  @spec from_device_sn(<<_::72>>, ATECC508A.encoded_dates()) :: <<_::128>>
  def from_device_sn(device_sn, encoded_dates) do
    hash = :crypto.hash(:sha256, [device_sn, encoded_dates])
    <<0b01::2, hash::126>>
  end

  @spec from_public_key(<<_::512, ATECC508A.encoded_dates())
  def from_public_key(public_key, encoded_dates) do
    hash = :crypto.hash(:sha256, [public_key, encoded_dates])
    <<0b01::2, hash::126>>
  end
end
