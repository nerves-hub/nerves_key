defmodule ATECC508A.Util do
  @moduledoc """
  Various utility functions
  """

  @doc """
  Pad the given binary out to the specified length.
  """
  @spec pad_zeros(binary(), pos_integer()) :: binary()
  def pad_zeros(bin, len) when byte_size(bin) == len, do: bin

  def pad_zeros(bin, len) when byte_size(bin) < len do
    pad = len - byte_size(bin)
    <<bin::binary, 0::unit(8)-size(pad)>>
  end

  def pad_zeros(bin, len) do
    <<bin::bytes-size(len)>>
  end

  @doc """
  Trim trailing zeros from a binary.
  """
  @spec trim_zeros(binary()) :: binary()
  def trim_zeros(bin) do
    String.trim_trailing(bin, <<0>>)
  end
end
