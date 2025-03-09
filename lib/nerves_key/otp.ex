# SPDX-FileCopyrightText: 2018 Frank Hunleth
# SPDX-FileCopyrightText: 2018 Justin Schneck
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesKey.OTP do
  @moduledoc """
  This module handles OTP data stored in the NervesKey.
  """

  alias ATECC508A.{OTPZone, Transport, Util}

  @magic <<0x4E, 0x72, 0x76, 0x73>>

  defstruct [
    :flags,
    :board_name,
    :manufacturer_sn,
    :user
  ]

  @type t :: %__MODULE__{
          flags: 0..65535,
          manufacturer_sn: binary(),
          board_name: binary(),
          user: <<_::256>>
        }

  @type raw() :: <<_::512>>

  @doc """
  Create a NervesKey OTP data struct
  """
  @spec new(String.t(), String.t(), binary() | nil) :: t()
  def new(board_name, manufacturer_sn, user \\ nil)

  def new(board_name, manufacturer_sn, nil)
      when byte_size(manufacturer_sn) > 16 and byte_size(manufacturer_sn) <= 32 do
    %__MODULE__{flags: 1, board_name: board_name, manufacturer_sn: manufacturer_sn, user: <<>>}
  end

  def new(board_name, manufacturer_sn, user)
      when byte_size(manufacturer_sn) <= 16 do
    %__MODULE__{
      flags: 0,
      board_name: board_name,
      manufacturer_sn: manufacturer_sn,
      user: check_user(user)
    }
  end

  defp check_user(nil), do: <<0::256>>
  defp check_user(user) when byte_size(user) <= 32, do: user

  @doc """
  Read NervesKey information from the OTP data.
  """
  @spec read(Transport.t()) :: {:ok, t()} | {:error, atom()}
  def read(transport) do
    with {:ok, data} <- OTPZone.read(transport) do
      from_raw(data)
    end
  end

  @doc """
  Write NervesKey information to the OTP zone.
  """
  @spec write(Transport.t(), raw()) :: :ok | {:error, atom()}
  defdelegate write(transport, data), to: OTPZone

  @doc """
  Convert a raw configuration to a nice map.
  """
  @spec from_raw(raw()) :: {:ok, t()} | {:error, atom()}
  def from_raw(<<@magic::binary, flags::16, board_name::10-bytes, manufacturer_sn::48-bytes>>)
      when flags == 1 do
    # Long serial number flag
    {:ok,
     %__MODULE__{
       flags: flags,
       board_name: Util.trim_zeros(board_name),
       manufacturer_sn: Util.trim_zeros(manufacturer_sn),
       user: <<>>
     }}
  end

  def from_raw(
        <<@magic::binary, flags::16, board_name::10-bytes, manufacturer_sn::16-bytes,
          user::32-bytes>>
      ) do
    {:ok,
     %__MODULE__{
       flags: flags,
       board_name: Util.trim_zeros(board_name),
       manufacturer_sn: Util.trim_zeros(manufacturer_sn),
       user: user
     }}
  end

  def from_raw(_other), do: {:error, :not_nerves_key}

  @doc """
  Convert a raw configuration to a nice map. Raise if there is an error.
  """
  @spec from_raw!(raw()) :: t()
  def from_raw!(raw) do
    {:ok, raw} = from_raw(raw)
    raw
  end

  @doc """
  Convert a nice config map back to a raw configuration
  """
  @spec to_raw(t()) :: raw()
  def to_raw(%__MODULE__{flags: 1} = info) do
    board_name = Util.pad_zeros(info.board_name, 10)
    manufacturer_sn = Util.pad_zeros(info.manufacturer_sn, 48)

    <<@magic::binary, info.flags::size(16), board_name::binary, manufacturer_sn::binary>>
  end

  def to_raw(%__MODULE__{} = info) do
    board_name = Util.pad_zeros(info.board_name, 10)
    manufacturer_sn = Util.pad_zeros(info.manufacturer_sn, 16)
    user = Util.pad_zeros(info.user, 32)

    <<@magic::binary, info.flags::size(16), board_name::binary, manufacturer_sn::binary,
      user::binary>>
  end
end
