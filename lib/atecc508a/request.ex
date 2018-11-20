defmodule ATECC508A.Request do
  @moduledoc """
  This module knows how to encode the various messages that get sent to
  the ATECC508A.
  """

  @type zone :: :config | :otp | :data
  @type slot :: 0..15
  @type block :: 0..3
  @type offset :: 0..7
  @type access_size :: 4 | 32
  @type access_data :: <<_::32>> | <<_::1024>>

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

  def interpret_result({:ok, data}) when byte_size(data) > 1 do
    {:ok, data}
  end

  def interpret_result({:error, reason}), do: {:error, reason}
  def interpret_result({:ok, <<0x00>>}), do: :ok
  def interpret_result({:ok, <<0x01>>}), do: {:error, :checkmac_or_verify_miscompare}
  def interpret_result({:ok, <<0x03>>}), do: {:error, :parse_error}
  def interpret_result({:ok, <<0x05>>}), do: {:error, :ecc_fault}
  def interpret_result({:ok, <<0x0F>>}), do: {:error, :execution_error}
  def interpret_result({:ok, <<0x11>>}), do: {:error, :no_wake}
  def interpret_result({:ok, <<0xEE>>}), do: {:error, :watchdog_about_to_expire}
  def interpret_result({:ok, <<0xFF>>}), do: {:error, :crc_error}
  def interpret_result({:ok, <<unknown>>}), do: {:error, {:unexpected_status, unknown}}

  @doc """
  Create a read message
  """
  # @spec read_zone(f(), zone(), slot(), block(), offset(), access_size()) :: {:ok, binary()} | {:error, atom()}
  def read_zone(transport, id, zone, slot, block, offset, length) do
    addr = get_addr(zone, slot, block, offset)

    payload =
      <<@atecc508a_op_read, length_flag(length)::1, 0::5, zone_index(zone)::2, addr::binary>>

    transport.request(id, payload, 5, length)
    |> interpret_result()
  end

  @doc """
  Create a write message
  """
  # @spec write_zone(zone(), slot(), block(), offset(), access_data()) :: transaction()
  def write_zone(transport, id, zone, slot, block, offset, data) do
    addr = get_addr(zone, slot, block, offset)
    len = byte_size(data)

    payload =
      <<@atecc508a_op_write, length_flag(len)::1, 0::5, zone_index(zone)::2, addr::binary,
        data::binary>>

    transport.request(id, payload, 5, 1)
    |> interpret_result()
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

    transport.request(id, payload, 115, 64)
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

    transport.request(id, payload, 32, 1)
    |> interpret_result()
  end

  defp zone_index(:config), do: 0
  defp zone_index(:otp), do: 1
  defp zone_index(:data), do: 2

  defp get_addr(zone, _slot, block, offset) when zone in [:config, :otp] do
    <<block::5, offset::3, 0>>
  end

  defp get_addr(:data, slot, block, offset) do
    <<slot::5, offset::3, block>>
  end

  defp length_flag(32), do: 1
  defp length_flag(4), do: 0
end
