defmodule NervesKey.OTP do
  @moduledoc """
  This module handles OTP data stored in the Nerves Key.
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
          flags: non_neg_integer(),
          manufacturer_sn: binary(),
          board_name: binary(),
          user: <<_::256>>
        }

  @doc """
  Create a Nerves Key OTP data struct
  """
  @spec new(String.t(), String.t(), binary()) :: t()
  def new(board_name, manufacturer_sn, user \\ <<0::size(256)>>) do
    %__MODULE__{flags: 0, board_name: board_name, manufacturer_sn: manufacturer_sn, user: user}
  end

  @doc """
  Read Nerves Key information from the OTP data.
  """
  @spec read(Transport.t()) :: {:ok, t()} | {:error, atom()}
  def read(transport) do
    with {:ok, data} <- OTPZone.read(transport) do
      from_raw(data)
    end
  end

  @doc """
  Write Nerves Key information to the OTP zone.
  """
  @spec write(Transport.t(), binary()) :: :ok | {:error, atom()}
  defdelegate write(transport, data), to: OTPZone

  @doc """
  Convert a raw configuration to a nice map.
  """
  @spec from_raw(<<_::512>>) :: {:ok, t()} | {:error, atom()}
  def from_raw(
        <<@magic::binary(), flags::size(16), board_name::10-bytes, manufacturer_sn::16-bytes,
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
  @spec from_raw!(<<_::512>>) :: t() | no_return()
  def from_raw!(raw) do
    {:ok, raw} = from_raw(raw)
    raw
  end

  @doc """
  Convert a nice config map back to a raw configuration
  """
  @spec to_raw(t()) :: <<_::512>>
  def to_raw(info) do
    board_name = Util.pad_zeros(info.board_name, 10)
    manufacturer_sn = Util.pad_zeros(info.manufacturer_sn, 16)
    user = Util.pad_zeros(info.user, 32)

    <<@magic::binary(), info.flags::size(16), board_name::binary(), manufacturer_sn::binary(),
      user::binary()>>
  end
end
