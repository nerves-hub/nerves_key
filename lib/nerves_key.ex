defmodule NervesKey do
  @moduledoc """
  This is a high level interface to provisioning and using the Nerves Key
  or any ATECC508A/608A that can be configured similarly.
  """

  @doc """
  Configure an ATECC508A or ATECC608A as a Nerves Key.

  This can only be called once. Subsequent calls will fail.
  """
  defdelegate configure(transport), to: NervesKey.Config

  @doc """
  Check whether the ATECC508A has been configured or not.

  If this returns {:ok, false}, then `configure/1` can be called.
  """
  @spec configured?(ATECC508A.Transport.t()) :: {:error, atom()} | {:ok, boolean()}
  defdelegate configured?(transport), to: NervesKey.Config

  @doc """
  Check if the chip's configuration is compatible with the Nerves Key. This only checks
  what's important for the Nerves Key.
  """
  @spec config_compatible?(ATECC508A.Transport.t()) :: {:error, atom()} | {:ok, boolean()}
  defdelegate config_compatible?(transport), to: NervesKey.Config
end
