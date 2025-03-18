# SPDX-FileCopyrightText: 2018 Frank Hunleth
# SPDX-FileCopyrightText: 2019 Justin Schneck
# SPDX-FileCopyrightText: 2019 Peter C. Marks
# SPDX-FileCopyrightText: 2025 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesKey.Config do
  @moduledoc """
  This is a high level interface to provisioning and using the NervesKey
  or any ATECC508A/608A that can be configured similarly.
  """

  alias ATECC508A.Configuration

  # See README.md for the SlotConfig and KeyConfig values. These are copied verbatim.
  @key_config <<0x33, 0x00, 0x1C, 0x00, 0x1C, 0x00, 0x1C, 0x00, 0x1C, 0x00, 0x1C, 0x00, 0x1C,
                0x00, 0x1C, 0x00, 0x3C, 0x00, 0x3C, 0x00, 0x3C, 0x00, 0x30, 0x00, 0x3C, 0x00,
                0x3C, 0x00, 0x3C, 0x00, 0x3C, 0x00>>

  @slot_config <<0x87, 0x20, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F,
                 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x2F, 0x0F, 0x2F, 0x0F, 0x2F,
                 0x0F, 0x2F, 0x0F, 0x0F, 0x0F, 0x0F>>

  # The structure of key configs and slot configs which let's us print the current config on
  # a device. Mostly useful during development of new configs. But an absolute pain to not
  # have.
  # Also provides the necessary offsets and lengths to be able to edit specific fields without
  # touching the rest of the config.
  @key [
    [
      private: 1,
      pub_info: 1,
      key_type: 3,
      lockable: 1,
      req_random: 1,
      req_auth: 1
    ],
    [auth_key: 4, persistent_disable: 1, unused: 1, x509_id: 2]
  ]

  @slot [
    [
      read_key: 4,
      no_mac: 1,
      limited_use: 1,
      encrypt_read: 1,
      is_secret: 1
    ],
    [write_key: 4, write_config: 4]
  ]

  def set_volatile_key(
        %Configuration.Config608{
          key_config: key_config,
          slot_config: slot_config
        } = info,
        key_id
      ) do
    volatile = %{enabled?: true, key: key_id}

    key_config =
      key_config
      # Don't disable they key we rely on, would be bad
      |> set_key_config(key_id, :persistent_disable, 0)
      # Set ReqRandom on the volatile key
      |> set_key_config(key_id, :req_random, 1)
      # Set ReqAuth to not require auth on the volatile key
      |> set_key_config(key_id, :req_auth, 0)
      |> set_key_config(key_id, :auth_key, 0)
      # Set KeyType to be AES
      |> set_key_config(key_id, :key_type, 6)
      # Allow locking the slot
      |> set_key_config(key_id, :lockable, 1)

    slot_config =
      slot_config
      # Disable CheckMac Copy operation
      |> set_slot_config(key_id, :read_key, 1)
      # Should be usable with the MAC command
      |> set_slot_config(key_id, :no_mac, 0)
      # Ensure no use limit
      |> set_slot_config(key_id, :limited_use, 0)
      # Not requiring encrypted read because reads will not be allowed
      |> set_slot_config(key_id, :encrypt_read, 0)
      # Is secret
      |> set_slot_config(key_id, :is_secret, 1)
      # Disable WriteKey
      |> set_slot_config(key_id, :write_key, 0)
      # Never allow changing the key
      |> set_slot_config(key_id, :write_config, 0b1001)

    %{info | key_config: key_config, slot_config: slot_config, volatile_key_permission: volatile}
  end

  def set_encryption_key(
        %Configuration.Config608{
          key_config: key_config,
          slot_config: slot_config
        } = info,
        key_id
      ) do
    key_config =
      key_config
      # Disable if persistent latch not set
      |> set_key_config(key_id, :persistent_disable, 1)
      # Don't require random
      |> set_key_config(key_id, :req_random, 0)
      # Don't require auth
      |> set_key_config(key_id, :req_auth, 0)
      |> set_key_config(key_id, :auth_key, 0)
      # Set KeyType to be AES
      |> set_key_config(key_id, :key_type, 6)
      # Allow locking the slot
      |> set_key_config(key_id, :lockable, 1)

    slot_config =
      slot_config
      # Disable CheckMac Copy operation
      |> set_slot_config(key_id, :read_key, 1)
      # Should be usable with the MAC command
      |> set_slot_config(key_id, :no_mac, 0)
      # Ensure no use limit
      |> set_slot_config(key_id, :limited_use, 0)
      # Not requiring encrypted read because reads will not be allowed
      |> set_slot_config(key_id, :encrypt_read, 0)
      # Is secret
      |> set_slot_config(key_id, :is_secret, 1)
      # Disable WriteKey
      |> set_slot_config(key_id, :write_key, 0)
      # Never allow changing the key
      |> set_slot_config(key_id, :write_config, 0b1001)

    %{info | key_config: key_config, slot_config: slot_config}
  end

  def set_persistent_disable(
        %ATECC508A.Configuration.Config608{
          key_config: key_config
        } = info,
        key_id
      ) do
    key_config =
      key_config
      |> set_key_config(key_id, :persistent_disable, 1)

    %{info | key_config: key_config}
  end

  def config do
    {@key_config, @slot_config}
  end

  @doc """
  Prints configuration of device slots.
  """
  def print_slots(transport, slots) do
    {:ok, %{slot_config: slot_config, key_config: key_config}} = Configuration.read(transport)

    key_config =
      key_config
      |> twobyte()

    slot_config =
      slot_config
      |> twobyte()

    Enum.zip(key_config, slot_config)
    |> Enum.with_index()
    |> Enum.each(fn {{key, slot}, index} ->
      if is_nil(slots) || index in slots do
        IO.puts("\n\n--- Slot #{index} -----------------------------")

        IO.puts(
          "slot: #{inspect(slot, as: :binary, base: :hex)} :: #{inspect(slot, as: :binary, base: :binary)}"
        )

        IO.puts(
          "key: #{inspect(key, as: :binary, base: :hex)} :: #{inspect(key, as: :binary, base: :binary)}"
        )

        IO.puts("\n")

        unpack_slot(slot)
        unpack_key(key)
      end
    end)
  end

  defp twobyte(binary) do
    case binary do
      <<part::binary-size(2)>> ->
        [part]

      <<part::binary-size(2), rest::binary>> ->
        [part, twobyte(rest)]
    end
    |> List.flatten()
  end

  defp unpack_key(key) do
    IO.puts("\nKey config:")
    # key config, 16 bit (2 byte), 16 slots, 32 bytes from 96 to 127
    <<
      # Private - Contains an ECC private key otherwise may contain something else
      private::size(1),
      # PubInfo - Can this public key be generated?
      pub_info::size(1),
      # KeyType - 0-3 unused, 4 - ECC Key, 5 - unused, 6 - AES key, 7 - SHA or other data
      key_type::size(3),
      # Lockable - Can be individually locked by Lock command
      lockable::size(1),
      # ReqRandom - Require a random Nonce for various commands
      req_random::size(1),
      # ReqAuth - Require authentication using AuthKey to make this key usable
      req_auth::size(1),
      # AuthKey - KeyID of key used to authenticate this key
      auth_key::size(4),
      # PersistentDisable - Key is only usable if persistent latch is set.
      persistent_disable::size(1),
      # Unused
      _unused::size(1),
      # X509id - id of x509format array in configuration zone corresponding to this slot
      x509_id::size(2)
    >> = key

    bindings = binding()

    max_k = bindings |> Enum.map(&String.length(to_string(elem(&1, 0)))) |> Enum.max()
    max_v = bindings |> Enum.map(&String.length(to_string(elem(&1, 1)))) |> Enum.max()

    key
    |> format(@key)
    |> Enum.map(fn {k, v, s, o} ->
      binary =
        v
        |> b2()
        |> String.pad_leading(s, ["0"])
        |> String.pad_leading(16 - o)

      "#{String.pad_trailing(to_string(k), max_k, ["."])}..#{String.pad_leading(to_string(v), max_v, ["."])} :: #{binary}"
    end)
    |> Enum.join("\n")
    |> IO.puts()
  end

  defp get_key_bit_offset(sizes, key) do
    sizes
    |> Enum.reduce_while(0, fn {k, size}, offset ->
      if key == k do
        {:halt, {offset, size}}
      else
        {:cont, offset + size}
      end
    end)
  end

  defp get_key_offsets(format, key) do
    format
    |> Enum.with_index()
    |> Enum.reduce_while(0, fn {keys, index}, _ ->
      if Keyword.has_key?(keys, key) do
        {:halt, {index, get_key_bit_offset(keys, key)}}
      else
        {:cont, 0}
      end
    end)
  end

  def set_key_config(key_config, slot_id, key, value) do
    set_key_in_config(key_config, @key, slot_id, key, value)
  end

  def set_slot_config(slot_config, slot_id, key, value) do
    set_key_in_config(slot_config, @slot, slot_id, key, value)
  end

  defp set_key_in_config(key_config, format, slot_id, key, value) do
    slot_offset = slot_id * 16
    slot_rem = 16 * 16 - (slot_offset + 16)
    <<pre_slot::size(slot_offset), slot::2-bytes, post_slot::size(slot_rem)>> = key_config

    {byte_offset, {bit_offset, bit_size}} = get_key_offsets(format, key)
    byte_rem = 1 - byte_offset

    <<pre_byte::binary-size(byte_offset), byte::binary-size(1), post_byte::binary-size(byte_rem)>> =
      slot

    bit_rem = 8 - (bit_offset + bit_size)
    <<post_bits::size(bit_rem), _old_value::size(bit_size), pre_bits::size(bit_offset)>> = byte

    <<pre_slot::size(slot_offset), pre_byte::binary-size(byte_offset), post_bits::size(bit_rem),
      value::size(bit_size), pre_bits::size(bit_offset), post_byte::binary-size(byte_rem),
      post_slot::size(slot_rem)>>
  end

  defp format(binary, [format1, format2]) do
    <<byte1::binary-size(1), byte2::binary-size(1)>> = binary

    [format(byte1, format1, 0, 0), format(byte2, format2, 0, 8)]
    |> List.flatten()
  end

  defp format(binary, format, offset, base_offset) do
    case format do
      [] ->
        []

      [{name, bits} | format] ->
        rem = 8 - (offset + bits)
        <<_skip::size(rem), part::size(bits), _::size(offset)>> = binary

        [
          {name, part, bits, offset + base_offset},
          format(binary, format, offset + bits, base_offset)
        ]
    end
  end

  defp unpack_slot(slot) do
    IO.puts("\nSlot config:")
    # slot config, 16 bit (2 byte), 16 slots, 32 bytes from 20 to 51
    <<
      # read_key, 4 bits
      # different meaning if private key
      # for non-private: KeyID for key to use to encrypt data being Read from this slot
      read_key::size(4),
      # NoMac - Disallow using slot for MAC command
      no_mac::size(1),
      # LimitedUse - Limited usages based on counter0
      limited_use::size(1),
      # EncryptRead
      encrypt_read::size(1),
      # IsSecret - Should it contain keys? Should it be protected? If so: 1
      is_secret::size(1),
      # WriteKey - KeyID for which key is used to validate writes to this slot
      write_key::size(4),
      # WriteConfig - Control details of how
      write_config::size(4)
    >> = slot

    bindings = binding()

    max_k = bindings |> Enum.map(&String.length(to_string(elem(&1, 0)))) |> Enum.max()
    max_v = bindings |> Enum.map(&String.length(to_string(elem(&1, 1)))) |> Enum.max()

    slot
    |> format(@slot)
    |> Enum.map(fn {k, v, s, o} ->
      binary =
        v
        |> b2()
        |> String.pad_leading(s, ["0"])
        |> String.pad_leading(16 - o)

      "#{String.pad_trailing(to_string(k), max_k, ["."])}..#{String.pad_leading(to_string(v), max_v, ["."])} :: #{binary}"

      # "#{String.pad_trailing(to_string(k), max_k, ["."])}..#{String.pad_leading(to_string(v), max_v, ["."])} :: #{inspect(v, base: :binary)}"
      # "#{String.pad_trailing(to_string(k), max_k, ["."])}..#{String.pad_leading(to_string(v), max_v, ["."])} :: #{bin(v)}"
    end)
    |> Enum.join("\n")
    |> IO.puts()
  end

  @doc """
  Configure an ATECC508A or ATECC608A as a NervesKey.

  This can only be called once. Subsequent calls will fail.
  """
  @spec configure(ATECC508A.Transport.t()) :: {:error, atom()} | :ok
  def configure(transport, lock? \\ true) do
    with {:ok, info} <- Configuration.read(transport),
         provision_info = %Configuration{
           info
           | key_config: @key_config,
             slot_config: @slot_config,
             otp_mode: 0xAA,
             chip_mode: 0,
             x509_format: <<0, 0, 0, 0>>
         },
         :ok <- Configuration.write(transport, provision_info) do
      if lock? do
        Configuration.lock(transport, provision_info)
      else
        :ok
      end
    end
  end

  @doc """
  Configure an ATECC508A or ATECC608A as a NervesKey with a volatile setup.

  This can only be called once. Subsequent calls will fail.
  """
  @spec configure_volatile(ATECC508A.Transport.t()) :: {:error, atom()} | :ok
  def configure_volatile(transport, lock? \\ true) do
    with {:ok, info} <- Configuration.read(transport, :atecc608),
         provision_info =
           %Configuration.Config608{
             info
             | key_config: @key_config,
               slot_config: @slot_config,
               count_match: 0xAA,
               chip_mode: 0,
               x509_format: <<0, 0, 0, 0>>
           }
           # Require activation key to set auth the volatile key config
           # and enable setting the persistent latch
           |> set_volatile_key(1)
           # configure encryption key slot
           |> set_encryption_key(2)
           # Disable device private key unless latch set
           |> set_persistent_disable(0)
           # Disable encryption key unless latch set
           |> set_persistent_disable(2),
         :ok <- Configuration.write(transport, provision_info) do
      if lock? do
        Configuration.lock(transport, provision_info)
      else
        :ok
      end
    end
  end

  @doc """
  Helper for getting information about the ATECC module.
  """
  @spec device_info(ATECC508A.Transport.t()) :: {:error, atom()} | {:ok, map()}
  def device_info(transport) do
    with {:ok, info} <- Configuration.read(transport) do
      {:ok, Map.take(info, [:rev_num])}
    end
  end

  @doc """
  Helper for getting the ATECC508A's serial number.
  """
  @spec device_sn(ATECC508A.Transport.t()) :: {:error, atom()} | {:ok, String.t()}
  def device_sn(transport) do
    with {:ok, info} <- Configuration.read(transport) do
      {:ok, info.serial_number}
    end
  end

  @doc """
  Check whether the ATECC508A has been configured or not.

  If this returns {:ok, false}, then `configure/1` can be called.
  """
  @spec configured?(ATECC508A.Transport.t()) :: {:error, atom()} | {:ok, boolean()}
  def configured?(transport) do
    with {:ok, info} <- Configuration.read(transport) do
      {:ok, info.lock_config == 0}
    end
  end

  @doc """
  Check if the chip's configuration is compatible with the NervesKey. This only checks
  what's important for the NervesKey.
  """
  @spec config_compatible?(ATECC508A.Transport.t()) :: {:error, atom()} | {:ok, boolean()}
  def config_compatible?(transport) do
    with {:ok, info} <- Configuration.read(transport) do
      answer =
        info.lock_config == 0 && info.chip_mode == 0 && slot_config_compatible(info.slot_config) &&
          key_config_compatible(info.key_config)

      {:ok, answer}
    end
  end

  def volatile_config_compatible?(transport) do
    with {:ok, %Configuration.Config608{} = info} <- Configuration.read(transport, :atecc608) do
      answer =
        info.lock_config == 0 and
          info.chip_mode == 0 and
          slot_config_volatile(info.slot_config) and
          key_config_volatile(info.key_config) and
          info.volatile_key_permission.enabled?

      {:ok, answer}
    end
  end

  # See the README.md for an easier-to-view version of what bytes matter
  defp slot_config_compatible(
         <<0x87, 0x20, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 0x0F, 0x2F, 0x0F,
           0x2F, 0x0F, 0x2F, 0x0F, 0x2F, _, _, _, _>>
       ),
       do: true

  defp slot_config_compatible(_), do: false

  defp slot_config_volatile(
         <<0x87, 0x20, 0x91, 0x90, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 0x0F, 0x2F,
           0x0F, 0x2F, 0x0F, 0x2F, 0x0F, 0x2F, _, _, _, _>>
       ),
       do: true

  defp slot_config_volatile(_) do
    false
  end

  defp key_config_compatible(
         <<0x33, 0x00, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 0x3C, 0x00, 0x30,
           0x00, 0x3C, 0x00, 0x3C, 0x00, _, _, _, _>>
       ),
       do: true

  defp key_config_compatible(_), do: false

  defp key_config_volatile(
         <<0x33, 0x10, 0x78, 0x0, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 0x3C, 0x00,
           0x30, 0x00, 0x3C, 0x00, 0x3C, 0x00, _, _, _, _>>
       ),
       do: true

  defp key_config_volatile(_), do: false

  defp b2(val) do
    :io_lib.format("~.02B", [val]) |> to_string()
  end
end
