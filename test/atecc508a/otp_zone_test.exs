defmodule ATECC508A.OTPZoneTest do
  use ExUnit.Case
  import Mox

  alias ATECC508A.OTPZone

  @mock_transport {ATECC508A.Transport.Mock, nil}

  @test_data0_32 :crypto.strong_rand_bytes(32)
  @test_data1_32 :crypto.strong_rand_bytes(32)

  @test_data_64 @test_data0_32 <> @test_data1_32

  setup :verify_on_exit!

  test "read OTP zone" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<2, 129, 0, 0>>, _, 32 -> {:ok, @test_data0_32} end)
    |> expect(:request, fn _, <<2, 129, 8, 0>>, _, 32 -> {:ok, @test_data1_32} end)

    assert OTPZone.read(@mock_transport) == {:ok, @test_data_64}
  end

  test "write OTP zone" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<18, 129, 0, 0, @test_data0_32>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 129, 8, 0, @test_data1_32>>, _, 1 -> {:ok, <<0>>} end)

    OTPZone.write(@mock_transport, @test_data_64)
  end
end
