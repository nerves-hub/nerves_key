defmodule ATECC508A.Transport do
  @moduledoc """
  ATECC508A transport behaviour
  """

  @callback init(args :: any()) :: {:ok, any()} | {:error, atom()}

  @callback request(
              instance :: any(),
              payload :: binary(),
              timeout :: non_neg_integer(),
              response_payload_len :: non_neg_integer()
            ) :: {:ok, binary()} | {:error, atom()}
end
