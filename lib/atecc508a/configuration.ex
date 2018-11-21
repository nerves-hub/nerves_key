defmodule ATECC508A.Configuration do
  @moduledoc """
  This module handles operations on the configuration zone.
  """

  alias ATECC508A.{Request, Transport}

  defstruct [
    :serial_number,
    :rev_num,
    :i2c_address,
    :otp_mode,
    :chip_mode,
    :slot_config,
    :counter0,
    :counter1,
    :last_key_use,
    :user_extra,
    :selector,
    :lock_value,
    :lock_config,
    :slot_locked,
    :x509_format,
    :key_config,
    :reserved0,
    :reserved1,
    :reserved2,
    :i2c_enable,
    :rfu
  ]

  @type t :: %__MODULE__{
          serial_number: binary(),
          rev_num: atom() | binary(),
          i2c_address: non_neg_integer(),
          otp_mode: non_neg_integer(),
          chip_mode: non_neg_integer(),
          slot_config: <<_::256>>,
          counter0: non_neg_integer(),
          counter1: non_neg_integer(),
          last_key_use: binary(),
          user_extra: non_neg_integer(),
          selector: non_neg_integer(),
          lock_value: non_neg_integer(),
          lock_config: non_neg_integer(),
          slot_locked: non_neg_integer(),
          x509_format: <<_::32>>,
          key_config: <<_::256>>,
          reserved0: byte(),
          reserved1: byte(),
          reserved2: byte(),
          i2c_enable: byte(),
          rfu: <<_::16>>
        }

  @doc """
  Read the configuration
  """
  @spec read(Transport.t()) :: {:ok, t()} | {:error, atom()}
  def read(transport) do
    case read_all_raw(transport) do
      {:ok, contents} -> {:ok, from_raw(contents)}
      error -> error
    end
  end

  @doc """
  Write the configuration.

  This only works when the ATECC508A is unlocked and only bytes not all bytes can
  be changed. This only writes the ones that can.
  """
  @spec write(Transport.t(), t()) :: :ok | {:error, atom()}
  def write(transport, info = %__MODULE__{}) do
    data = to_raw(info)

    <<_read_only::16-bytes, writable0::16-bytes, writable1::32-bytes, writable2::20-bytes,
      _special::8-bytes, x509::4-bytes, key_config::32-bytes>> = data

    # Use 4-byte writes for everything except for writable1 and key_config which both
    # land on 32-byte boundaries

    with :ok <- multi_write(transport, 16, writable0),
         :ok <- Request.write_zone(transport, :config, Request.to_config_addr(32), writable1),
         :ok <- multi_write(transport, 64, writable2),
         :ok <- multi_write(transport, 92, x509),
         :ok <- Request.write_zone(transport, :config, Request.to_config_addr(96), key_config) do
      :ok
    end
  end

  @doc """
  Read the entire contents of the configuration zone and don't interpret them
  """
  @spec read_all_raw(Transport.t()) :: {:ok, <<_::1024>>} | {:error, atom()}
  def read_all_raw(transport) do
    with {:ok, lo} <- Request.read_zone(transport, :config, 0, 32),
         {:ok, mid} <- Request.read_zone(transport, :config, 8, 32),
         {:ok, hi} <- Request.read_zone(transport, :config, 16, 32),
         {:ok, hi2} <- Request.read_zone(transport, :config, 24, 32) do
      {:ok, lo <> mid <> hi <> hi2}
    end
  end

  @doc """
  Read the current slot configuration
  """
  @spec read_slot_config(Transport.t()) :: {:ok, <<_::256>>} | {:error, atom()}
  def read_slot_config(transport) do
    case read_all_raw(transport) do
      {:ok, data} ->
        <<_::20-bytes, slot_config::32-bytes, _::binary>> = data
        {:ok, slot_config}

      error ->
        error
    end
  end

  @doc """
  Write a slot configuration.
  """
  @spec write_slot_config(Transport.t(), <<_::256>>) :: :ok | {:error, atom()}
  def write_slot_config(transport, data) when byte_size(data) == 32 do
    multi_write(transport, 20, data)
  end

  @doc """
  Read the current slot configuration
  """
  @spec read_key_config(Transport.t()) :: {:ok, <<_::256>>} | {:error, atom()}
  def read_key_config(transport) do
    case read_all_raw(transport) do
      {:ok, data} ->
        <<_::96-bytes, key_config::32-bytes>> = data
        {:ok, key_config}

      error ->
        error
    end
  end

  @doc """
  Write the key configuration.
  """
  @spec write_key_config(Transport.t(), <<_::256>>) :: :ok | {:error, atom()}
  def write_key_config(transport, data) when byte_size(data) == 32 do
    multi_write(transport, 96, data)
  end

  @doc """
  Lock the configuration zone.

  The expected contents need to be passed for a CRC calculation. They are not
  written by design. The logic is that this is a final chance before it's too
  late to check that the device is programmed correctly.
  """
  @spec lock(Transport.t(), ATECC508A.crc16()) :: :ok | {:error, atom()}
  def lock(transport, expected_contents) do
    crc = ATECC508A.CRC.crc(expected_contents)

    Request.lock_zone(transport, :config, crc)
  end

  @doc """
  Convert a raw configuration to a nice map.
  """
  @spec from_raw(<<_::1024>>) :: t()
  def from_raw(
        <<sn0_3::4-bytes, rev_num::4-bytes, sn4_8::5-bytes, reserved0, i2c_enable, reserved1,
          i2c_address, reserved2, otp_mode, chip_mode, slot_config::32-bytes, counter0::little-64,
          counter1::little-64, last_key_use::16-bytes, user_extra, selector, lock_value,
          lock_config, slot_locked::little-16, rfu::2-bytes, x509_format::4-bytes,
          key_config::32-bytes>>
      ) do
    %__MODULE__{
      serial_number: sn0_3 <> sn4_8,
      rev_num: decode_rev_num(rev_num),
      i2c_address: i2c_address,
      otp_mode: otp_mode,
      chip_mode: chip_mode,
      slot_config: slot_config,
      counter0: counter0,
      counter1: counter1,
      last_key_use: last_key_use,
      user_extra: user_extra,
      selector: selector,
      lock_value: lock_value,
      lock_config: lock_config,
      slot_locked: slot_locked,
      x509_format: x509_format,
      key_config: key_config,
      reserved0: reserved0,
      reserved1: reserved1,
      reserved2: reserved2,
      i2c_enable: i2c_enable,
      rfu: rfu
    }
  end

  @doc """
  Convert a nice config map back to a raw configuration
  """
  @spec to_raw(t()) :: <<_::1024>>
  def to_raw(info) do
    <<sn0_3::4-bytes, sn4_8::5-bytes>> = info.serial_number
    rev_num = encode_rev_num(info.rev_num)

    <<sn0_3::4-bytes, rev_num::4-bytes, sn4_8::5-bytes, info.reserved0, info.i2c_enable,
      info.reserved1, info.i2c_address, info.reserved2, info.otp_mode, info.chip_mode,
      info.slot_config::32-bytes, info.counter0::little-64, info.counter1::little-64,
      info.last_key_use::16-bytes, info.user_extra, info.selector, info.lock_value,
      info.lock_config, info.slot_locked::little-16, info.rfu::2-bytes, info.x509_format::4-bytes,
      info.key_config::32-bytes>>
  end

  # These were found by grep'ing Crytoauthlib
  defp decode_rev_num(<<0x00, 0x00, 0x60, 0x01>>), do: :ecc608a_1
  defp decode_rev_num(<<0x00, 0x00, 0x60, 0x02>>), do: :ecc608a_2
  defp decode_rev_num(<<0x00, 0x00, 0x50, 0x00>>), do: :ecc508a
  defp decode_rev_num(<<0x80, 0x00, 0x10, 0x01>>), do: :ecc108
  defp decode_rev_num(<<0x00, 0x02, 0x00, 0x08>>), do: :ecc204_8
  defp decode_rev_num(<<0x00, 0x02, 0x00, 0x09>>), do: :ecc204_9
  defp decode_rev_num(<<0x00, 0x04, 0x05, 0x08>>), do: :ecc204_0
  defp decode_rev_num(unknown), do: unknown

  defp encode_rev_num(:ecc608a_1), do: <<0x00, 0x00, 0x60, 0x01>>
  defp encode_rev_num(:ecc608a_2), do: <<0x00, 0x00, 0x60, 0x02>>
  defp encode_rev_num(:ecc508a), do: <<0x00, 0x00, 0x50, 0x00>>
  defp encode_rev_num(:ecc108), do: <<0x80, 0x00, 0x10, 0x01>>
  defp encode_rev_num(:ecc204_8), do: <<0x00, 0x02, 0x00, 0x08>>
  defp encode_rev_num(:ecc204_9), do: <<0x00, 0x02, 0x00, 0x09>>
  defp encode_rev_num(:ecc204_0), do: <<0x00, 0x04, 0x05, 0x08>>
  defp encode_rev_num(unknown) when byte_size(unknown) == 4, do: unknown

  defp multi_write(_transport, _addr, <<>>), do: :ok

  defp multi_write(transport, offset, <<four_bytes::4-bytes, rest::binary>>) do
    addr = Request.to_config_addr(offset)

    case Request.write_zone(transport, :config, addr, four_bytes) do
      :ok -> multi_write(transport, offset + 4, rest)
      error -> error
    end
  end
end
