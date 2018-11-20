defmodule ATECC508A.Transport do
  @moduledoc """
  ATECC508A transport behaviour
  """

  @type t :: {module(), any()}

  @callback init(args :: any()) :: {:ok, t()} | {:error, atom()}

  @callback request(
              id :: any(),
              payload :: binary(),
              timeout :: non_neg_integer(),
              response_payload_len :: non_neg_integer()
            ) :: {:ok, binary()} | {:error, atom()}

  @spec request(t(), binary(), non_neg_integer(), non_neg_integer()) ::
          {:ok, binary()} | {:error, atom()}
  def request({mod, arg}, payload, timeout, response_payload_len) do
    mod.request(arg, payload, timeout, response_payload_len)
  end
end
