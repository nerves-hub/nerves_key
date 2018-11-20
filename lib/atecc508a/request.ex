defmodule ATECC508A.Request do
  @moduledoc """
  This module knows how to send requests to the ATECC508A.
  """

  alias ATECC508A.Transport

  @type zone :: :config | :otp | :data
  @type slot :: 0..15
  @type block :: 0..3
  @type offset :: 0..7
  @type access_size :: 4 | 32
  @type access_data :: <<_::32>> | <<_::1024>>
  @type addr :: 0..65535

  @typedoc """
  A transaction is a tuple with the binary to send, how long to
  wait in milliseconds for the response and the size of payload to
  expect to read for the response.
  """
  @type transaction :: {binary(), non_neg_integer(), non_neg_integer()}

  @atecc508a_op_read 0x02
  @atecc508a_op_write 0x12
  @atecc508a_op_genkey 0x40
  @atecc508a_op_lock 0x17

  # See https://github.com/MicrochipTech/cryptoauthlib/blob/master/lib/atca_execution.c
  # for command max execution times. I'm not sure why they are different from the
  # datasheet. Since this library is compatible with the ECC608A, the longer time is
  # used.

  @spec to_config_addr(0..127) :: addr()
  def to_config_addr(byte_offset)
      when byte_offset >= 0 and byte_offset < 128 and rem(byte_offset, 4) == 0 do
    div(byte_offset, 4)
  end

  @spec to_config_addr(block(), offset()) :: addr()
  def to_config_addr(block, offset)
      when block >= 0 and block < 4 and offset >= 0 and offset < 8 do
    block * 8 + offset
  end

  @spec to_otp_addr(0..127) :: addr()
  def to_otp_addr(byte_offset), do: to_config_addr(byte_offset)

  @spec to_otp_addr(block(), offset()) :: addr()
  def to_otp_addr(block, offset), do: to_config_addr(block, offset)

  @spec to_data_addr(slot(), 0..416) :: addr()
  def to_data_addr(slot, byte_offset)
      when slot >= 0 and slot < 16 and byte_offset >= 0 and byte_offset < 128 and
             rem(byte_offset, 4) == 0 do
    word_offset = div(byte_offset, 4)
    offset = rem(word_offset, 8)
    block = div(word_offset, 8)
    to_data_addr(slot, block, offset)
  end

  @spec to_data_addr(slot(), block(), offset()) :: addr()
  def to_data_addr(slot, block, offset)
      when slot >= 0 and slot < 16 and block >= 0 and block < 13 and offset >= 0 and offset < 8 do
    block * 256 + slot * 8 + offset
  end

  @doc """
  Create a read message
  """
  @spec read_zone(Transport.t(), zone(), addr(), access_size()) ::
          {:ok, binary()} | {:error, atom()}
  def read_zone(transport, zone, addr, length) do
    payload =
      <<@atecc508a_op_read, length_flag(length)::1, 0::5, zone_index(zone)::2, addr::little-16>>

    Transport.request(transport, payload, 5, length)
    |> interpret_result()
  end

  @doc """
  Create a write message
  """
  @spec write_zone(Transport.t(), zone(), addr(), access_data()) :: :ok | {:error, atom()}
  def write_zone(transport, zone, addr, data) do
    len = byte_size(data)

    payload =
      <<@atecc508a_op_write, length_flag(len)::1, 0::5, zone_index(zone)::2, addr::little-16,
        data::binary>>

    Transport.request(transport, payload, 45, 1)
    |> interpret_result()
    |> return_status()
  end

  @doc """
  Create a genkey request message.
  """
  # @spec genkey(slot(), boolean()) :: transaction()
  def genkey(transport, id, key_id, create_key?) do
    mode2 = if create_key?, do: 1, else: 0
    mode3 = 0
    mode4 = 0

    payload = <<@atecc508a_op_genkey, 0::3, mode4::1, mode3::1, mode2::1, 0::2, key_id>>

    transport.request(id, payload, 653, 64)
    |> interpret_result()
  end

  @doc """
  Create a message to lock a zone.
  """
  # @spec lock_zone(zone(), ATECC508A.crc16()) :: transaction()
  def lock_zone(transport, id, zone, zone_crc) do
    # Need to calculate the CRC of everything written in the zone to be
    # locked for this to work.

    # See Table 9-31 - Mode Encoding
    mode = if zone == :config, do: 0, else: 1
    payload = <<@atecc508a_op_lock, mode, zone_crc::binary>>

    transport.request(id, payload, 35, 1)
    |> interpret_result()
  end

  defp zone_index(:config), do: 0
  defp zone_index(:otp), do: 1
  defp zone_index(:data), do: 2

  defp length_flag(32), do: 1
  defp length_flag(4), do: 0

  defp interpret_result({:ok, data}) when byte_size(data) > 1 do
    {:ok, data}
  end

  defp interpret_result({:error, reason}), do: {:error, reason}
  defp interpret_result({:ok, <<0x00>>}), do: {:ok, <<0x00>>}
  defp interpret_result({:ok, <<0x01>>}), do: {:error, :checkmac_or_verify_miscompare}
  defp interpret_result({:ok, <<0x03>>}), do: {:error, :parse_error}
  defp interpret_result({:ok, <<0x05>>}), do: {:error, :ecc_fault}
  defp interpret_result({:ok, <<0x0F>>}), do: {:error, :execution_error}
  defp interpret_result({:ok, <<0x11>>}), do: {:error, :no_wake}
  defp interpret_result({:ok, <<0xEE>>}), do: {:error, :watchdog_about_to_expire}
  defp interpret_result({:ok, <<0xFF>>}), do: {:error, :crc_error}
  defp interpret_result({:ok, <<unknown>>}), do: {:error, {:unexpected_status, unknown}}

  defp return_status({:ok, _}), do: :ok
  defp return_status(other), do: other
end
