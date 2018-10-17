defmodule ATECC508A.CRC do
  import Bitwise

  @atecc508a_polynomial 0x8005

  @doc """
  Compute the CRC of a message using the ATECC508A's algorithm.
  """
  @spec crc(binary()) :: ATECC508A.crc16()
  def crc(message) do
    # See Atmel CryptoAuthentication Data Zone CRC Calculation application note
    crc = do_crc(0, message)

    # ATECC508A expects little endian
    <<crc::little-16>>
  end

  defp shift(crc, 0) when crc >= 0x8000, do: (crc <<< 1) ^^^ (@atecc508a_polynomial + 0x10000)
  defp shift(crc, 1) when crc < 0x8000, do: (crc <<< 1) ^^^ @atecc508a_polynomial
  defp shift(crc, 1) when crc >= 0x8000, do: (crc <<< 1) ^^^ 0x10000
  defp shift(crc, 0) when crc < 0x8000, do: crc <<< 1

  defp do_crc(crc, <<>>), do: crc

  defp do_crc(crc, <<a::1, b::1, c::1, d::1, e::1, f::1, g::1, h::1, rest::binary>>) do
    crc
    |> shift(h)
    |> shift(g)
    |> shift(f)
    |> shift(e)
    |> shift(d)
    |> shift(c)
    |> shift(b)
    |> shift(a)
    |> do_crc(rest)
  end
end
