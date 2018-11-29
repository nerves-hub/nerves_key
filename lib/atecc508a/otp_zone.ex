defmodule ATECC508A.OTPZone do
  @moduledoc """
  This module handles operations on the OTP zone.
  """

  alias ATECC508A.{Request, Transport}

  @doc """
  Read the OTP
  """
  @spec read(Transport.t()) :: {:ok, <<_::512>>} | {:error, atom()}
  def read(transport) do
    with {:ok, lo} <- Request.read_zone(transport, :otp, Request.to_otp_addr(0), 32),
         {:ok, hi} <- Request.read_zone(transport, :otp, Request.to_otp_addr(32), 32) do
      {:ok, lo <> hi}
    end
  end

  @doc """
  Write the configuration.

  This only works when the ATECC508A is unlocked and only bytes not all bytes can
  be changed. This only writes the ones that can.
  """
  @spec write(Transport.t(), <<_::512>>) :: :ok | {:error, atom()}
  def write(transport, data) do
    <<lo::32-bytes, hi::32-bytes>> = data

    with :ok <- Request.write_zone(transport, :otp, Request.to_otp_addr(0), lo),
         :ok <- Request.write_zone(transport, :otp, Request.to_otp_addr(32), hi) do
      :ok
    end
  end

  # @doc """
  # Lock the OTP zone.

  # The expected contents need to be passed for a CRC calculation. They are not
  # written by design. The logic is that this is a final chance before it's too
  # late to check that the device is programmed correctly.
  # """
  # @spec lock(Transport.t(), ATECC508A.crc16()) :: :ok | {:error, atom()}
  # def lock(transport, expected_contents) do
  #   crc = ATECC508A.CRC.crc(expected_contents)

  #   Request.lock_zone(transport, :otp, crc)
  # end
end
