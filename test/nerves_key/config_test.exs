# SPDX-FileCopyrightText: 2025 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesKey.ConfigTest do
  use ExUnit.Case

  alias ATECC508A.Configuration.Config608
  alias NervesKey.Config

  # A locked chip as Configuration.read/2 returns it after configure_volatile/2,
  # built with the same steps configure_volatile/2 uses.
  defp provisioned_volatile() do
    {key_config, slot_config} = Config.config()

    %Config608{lock_config: 0, chip_mode: 0, key_config: key_config, slot_config: slot_config}
    |> Config.set_volatile_key(1)
    |> Config.set_encryption_key(2)
    |> Config.set_persistent_disable(0)
    |> Config.set_persistent_disable(2)
  end

  defp put_slot_config(%Config608{slot_config: zone} = info, slot, <<_, _>> = bytes) do
    %{info | slot_config: put_slot(zone, slot, bytes)}
  end

  defp put_key_config(%Config608{key_config: zone} = info, slot, <<_, _>> = bytes) do
    %{info | key_config: put_slot(zone, slot, bytes)}
  end

  defp put_slot(zone, slot, bytes) do
    <<before::binary-size(slot * 2), _::binary-size(2), rest::binary>> = zone
    before <> bytes <> rest
  end

  test "the volatile provisioning steps write the slot 1 and slot 2 bytes the README documents" do
    info = provisioned_volatile()

    assert <<0x87, 0x20, 0x81, 0x90, 0x81, 0x90, _::binary>> = info.slot_config
    assert <<0x33, 0x10, 0x78, 0x00, 0x38, 0x10, _::binary>> = info.key_config
    assert info.volatile_key_permission == %{enabled?: true, key: 1}
  end

  test "the configuration configure_volatile/2 writes is volatile-compatible" do
    assert Config.volatile_config_compatible?(provisioned_volatile())
  end

  test "slot 1 with NoMac set is still accepted" do
    info = provisioned_volatile() |> put_slot_config(1, <<0x91, 0x90>>)
    assert Config.volatile_config_compatible?(info)
  end

  # Both accepted slot 1 variants must still reject a bad slot 2.
  for slot1 <- [<<0x81, 0x90>>, <<0x91, 0x90>>] do
    @slot1 slot1

    test "an encryption key slot that is readable, writable or usable without the latch is rejected (slot 1 #{inspect(slot1, base: :hex)})" do
      info = provisioned_volatile() |> put_slot_config(1, @slot1)
      assert Config.volatile_config_compatible?(info)

      # Readable, writable
      refute info |> put_slot_config(2, <<0x0F, 0x0F>>) |> Config.volatile_config_compatible?()
      # Secret, but writable with any key
      refute info |> put_slot_config(2, <<0x81, 0x00>>) |> Config.volatile_config_compatible?()
      # Not an AES key
      refute info |> put_key_config(2, <<0x1C, 0x10>>) |> Config.volatile_config_compatible?()
      # AES key but usable without the persistent latch
      refute info |> put_key_config(2, <<0x38, 0x00>>) |> Config.volatile_config_compatible?()
    end

    test "an encryption key slot that cannot be used with MAC is rejected (slot 1 #{inspect(slot1, base: :hex)})" do
      info =
        provisioned_volatile() |> put_slot_config(1, @slot1) |> put_slot_config(2, <<0x91, 0x90>>)

      refute Config.volatile_config_compatible?(info)
    end
  end

  test "a regular NervesKey configuration is not volatile-compatible" do
    {key_config, slot_config} = Config.config()

    info = %{
      provisioned_volatile()
      | slot_config: slot_config,
        key_config: key_config,
        volatile_key_permission: %{enabled?: false, key: 0}
    }

    refute Config.volatile_config_compatible?(info)
  end

  test "an unlocked chip, the wrong chip mode or no volatile key permission is rejected" do
    info = provisioned_volatile()

    refute Config.volatile_config_compatible?(%{info | lock_config: 0x55})
    refute Config.volatile_config_compatible?(%{info | chip_mode: 1})

    refute Config.volatile_config_compatible?(%{
             info
             | volatile_key_permission: %{enabled?: false, key: 1}
           })
  end
end
