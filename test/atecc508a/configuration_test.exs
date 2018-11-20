defmodule ATECC508A.ConfigurationTest do
  use ExUnit.Case
  import Mox

  alias ATECC508A.Configuration

  @mock_transport {ATECC508A.Transport.Mock, nil}

  @test_data0_4 :crypto.strong_rand_bytes(4)
  @test_data1_4 :crypto.strong_rand_bytes(4)
  @test_data2_4 :crypto.strong_rand_bytes(4)
  @test_data3_4 :crypto.strong_rand_bytes(4)
  @test_data4_4 :crypto.strong_rand_bytes(4)
  @test_data5_4 :crypto.strong_rand_bytes(4)
  @test_data6_4 :crypto.strong_rand_bytes(4)
  @test_data7_4 :crypto.strong_rand_bytes(4)

  @test_data0_32 @test_data0_4 <>
                   @test_data1_4 <>
                   @test_data2_4 <>
                   @test_data3_4 <>
                   @test_data4_4 <> @test_data5_4 <> @test_data6_4 <> @test_data7_4
  @test_data1_32 :crypto.strong_rand_bytes(32)
  @test_data2_32 :crypto.strong_rand_bytes(32)
  @test_data3_32 :crypto.strong_rand_bytes(32)

  setup :verify_on_exit!

  test "read the entire config zone" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<2, 128, 0, 0>>, _, 32 -> {:ok, @test_data0_32} end)
    |> expect(:request, fn _, <<2, 128, 8, 0>>, _, 32 -> {:ok, @test_data1_32} end)
    |> expect(:request, fn _, <<2, 128, 16, 0>>, _, 32 -> {:ok, @test_data2_32} end)
    |> expect(:request, fn _, <<2, 128, 24, 0>>, _, 32 -> {:ok, @test_data3_32} end)

    assert Configuration.read_all(@mock_transport) ==
             {:ok, @test_data0_32 <> @test_data1_32 <> @test_data2_32 <> @test_data3_32}
  end

  test "write the slot config" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<18, 0, 5, 0, @test_data0_4>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 6, 0, @test_data1_4>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 7, 0, @test_data2_4>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 8, 0, @test_data3_4>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 9, 0, @test_data4_4>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 10, 0, @test_data5_4>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 11, 0, @test_data6_4>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 12, 0, @test_data7_4>>, _, 1 -> {:ok, <<0>>} end)

    assert Configuration.write_slot_config(@mock_transport, @test_data0_32)
  end

  test "write the key config" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<18, 0, 24, 0, @test_data0_4>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 25, 0, @test_data1_4>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 26, 0, @test_data2_4>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 27, 0, @test_data3_4>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 28, 0, @test_data4_4>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 29, 0, @test_data5_4>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 30, 0, @test_data6_4>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 31, 0, @test_data7_4>>, _, 1 -> {:ok, <<0>>} end)

    assert Configuration.write_key_config(@mock_transport, @test_data0_32)
  end

end
