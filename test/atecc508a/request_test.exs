defmodule ATECC508A.RequestTest do
  use ExUnit.Case
  import Mox

  alias ATECC508A.Request

  @mock_transport {ATECC508A.Transport.Mock, nil}

  @test_data_32 <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
                  23, 24, 25, 26, 27, 28, 29, 30, 31, 32>>
  @test_data_4 <<1, 2, 3, 4>>

  setup :verify_on_exit!

  test "read 32-bytes in config zone" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<2, 128, 0, 0>>, 5, 32 -> {:ok, @test_data_32} end)

    assert Request.read_zone(@mock_transport, :config, 0, 32) == {:ok, @test_data_32}

    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<2, 128, 8, 0>>, 5, 32 -> {:ok, @test_data_32} end)

    assert Request.read_zone(@mock_transport, :config, 8, 32) == {:ok, @test_data_32}
  end

  test "read otp zone" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<2, 129, 0, 0>>, 5, 32 -> {:ok, @test_data_32} end)

    assert Request.read_zone(@mock_transport, :otp, 0, 32) == {:ok, @test_data_32}

    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<2, 129, 8, 0>>, 5, 32 -> {:ok, @test_data_32} end)

    assert Request.read_zone(@mock_transport, :otp, 8, 32) == {:ok, @test_data_32}
  end

  # test "read data zone" do
  #   {message, timeout, resp_len} = Request.read_zone(:data, 0, 0, 0, 32)
  #   assert message == <<2, 130, 0, 0>>
  #   assert timeout >= 1
  #   assert resp_len == 32

  #   {message, _timeout, _resp_len} = Request.read_zone(:data, 0, 1, 0, 32)
  #   assert message == <<2, 130, 0, 1>>
  # end

  # test "write config zone" do
  #   {message, timeout, resp_len} = Request.write_zone(:config, 0, 0, 0, @test_data_32)
  #   assert message == <<18, 128, 0, 0, @test_data_32::binary>>
  #   assert timeout >= 26
  #   assert resp_len == 1

  #   {message, _timeout, _resp_len} = Request.write_zone(:config, 0, 1, 0, @test_data_32)
  #   assert message == <<18, 128, 8, 0, @test_data_32::binary>>

  #   {message, _timeout, _resp_len} = Request.write_zone(:config, 0, 1, 0, @test_data_4)
  #   assert message == <<18, 0, 8, 0, @test_data_4::binary>>
  # end

  # test "write otp zone" do
  #   {message, timeout, resp_len} = Request.write_zone(:otp, 0, 0, 0, @test_data_32)
  #   assert message == <<18, 129, 0, 0, @test_data_32::binary>>
  #   assert timeout >= 26
  #   assert resp_len == 1

  #   {message, _timeout, _resp_len} = Request.write_zone(:otp, 0, 1, 0, @test_data_32)
  #   assert message == <<18, 129, 8, 0, @test_data_32::binary>>

  #   {message, _timeout, _resp_len} = Request.write_zone(:otp, 0, 1, 0, @test_data_4)
  #   assert message == <<18, 1, 8, 0, @test_data_4::binary>>
  # end

  # test "write data zone" do
  #   {message, timeout, resp_len} = Request.write_zone(:data, 0, 0, 0, @test_data_32)
  #   assert message == <<18, 130, 0, 0, @test_data_32::binary>>
  #   assert timeout >= 26
  #   assert resp_len == 1

  #   {message, _timeout, _resp_len} = Request.write_zone(:data, 0, 1, 0, @test_data_32)
  #   assert message == <<18, 130, 0, 1, @test_data_32::binary>>

  #   {message, _timeout, _resp_len} = Request.write_zone(:data, 0, 1, 0, @test_data_4)
  #   assert message == <<18, 2, 0, 1, @test_data_4::binary>>
  # end

  # test "lock zones" do
  #   {message, timeout, resp_len} = Request.lock_zone(:config, <<0xAA, 0x55>>)
  #   assert message == <<0x17, 0, 0xAA, 0x55>>
  #   assert timeout >= 32
  #   assert resp_len == 1

  #   {message, _timeout, _resp_len} = Request.lock_zone(:data, <<0xAA, 0x55>>)
  #   assert message == <<0x17, 1, 0xAA, 0x55>>
  # end

  # test "genkey" do
  #   {message, timeout, resp_len} = Request.genkey(0, true)
  #   assert message == <<0x40, 4, 0>>
  #   assert timeout >= 115
  #   assert resp_len == 64

  #   {message, _timeout, _resp_len} = Request.genkey(0, false)
  #   assert message == <<0x40, 0, 0>>

  #   {message, _timeout, _resp_len} = Request.genkey(5, false)
  #   assert message == <<0x40, 0, 5>>
  # end
end
