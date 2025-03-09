# SPDX-FileCopyrightText: 2018 Frank Hunleth
# SPDX-FileCopyrightText: 2019 Justin Schneck
# SPDX-FileCopyrightText: 2019 Peter C. Marks
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

  @doc """
  Configure an ATECC508A or ATECC608A as a NervesKey.

  This can only be called once. Subsequent calls will fail.
  """
  @spec configure(ATECC508A.Transport.t()) :: {:error, atom()} | :ok
  def configure(transport) do
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
      Configuration.lock(transport, provision_info)
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

  # See the README.md for an easier-to-view version of what bytes matter
  defp slot_config_compatible(
         <<0x87, 0x20, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 0x0F, 0x2F, 0x0F,
           0x2F, 0x0F, 0x2F, 0x0F, 0x2F, _, _, _, _>>
       ),
       do: true

  defp slot_config_compatible(_), do: false

  defp key_config_compatible(
         <<0x33, 0x00, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 0x3C, 0x00, 0x30,
           0x00, 0x3C, 0x00, 0x3C, 0x00, _, _, _, _>>
       ),
       do: true

  defp key_config_compatible(_), do: false
end
