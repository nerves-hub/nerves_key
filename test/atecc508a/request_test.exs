defmodule ATECC508A.RequestTest do
  use ExUnit.Case

  alias ATECC508A.Request

  @test_write_data_32 <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
                        22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32>>
  @test_write_data_4 <<1, 2, 3, 4>>

  test "read config zone" do
    {message, timeout, resp_len} = Request.read_zone(:config, 0, 0, 0, 32)
    assert message == <<7, 2, 128, 0, 0>>
    assert timeout >= 1
    assert resp_len == 32

    {message, _timeout, _resp_len} = Request.read_zone(:config, 0, 1, 0, 32)
    assert message == <<7, 2, 128, 8, 0>>
  end

  test "read otp zone" do
    {message, timeout, resp_len} = Request.read_zone(:otp, 0, 0, 0, 32)
    assert message == <<7, 2, 129, 0, 0>>
    assert timeout >= 1
    assert resp_len == 32

    {message, _timeout, _resp_len} = Request.read_zone(:otp, 0, 1, 0, 32)
    assert message == <<7, 2, 129, 8, 0>>
  end

  test "read data zone" do
    {message, timeout, resp_len} = Request.read_zone(:data, 0, 0, 0, 32)
    assert message == <<7, 2, 130, 0, 0>>
    assert timeout >= 1
    assert resp_len == 32

    {message, _timeout, _resp_len} = Request.read_zone(:data, 0, 1, 0, 32)
    assert message == <<7, 2, 130, 0, 1>>
  end

  test "write config zone" do
    {message, timeout, resp_len} = Request.write_zone(:config, 0, 0, 0, @test_write_data_32)
    assert message == <<39, 18, 128, 0, 0, @test_write_data_32::binary>>
    assert timeout >= 26
    assert resp_len == 1

    {message, _timeout, _resp_len} = Request.write_zone(:config, 0, 1, 0, @test_write_data_32)
    assert message == <<39, 18, 128, 8, 0, @test_write_data_32::binary>>

    {message, _timeout, _resp_len} = Request.write_zone(:config, 0, 1, 0, @test_write_data_4)
    assert message == <<11, 18, 0, 8, 0, @test_write_data_4::binary>>

  end

  test "write otp zone" do
    {message, timeout, resp_len} = Request.write_zone(:otp, 0, 0, 0, @test_write_data_32)
    assert message == <<39, 18, 129, 0, 0, @test_write_data_32::binary>>
    assert timeout >= 26
    assert resp_len == 1

    {message, _timeout, _resp_len} = Request.write_zone(:otp, 0, 1, 0, @test_write_data_32)
    assert message == <<39, 18, 129, 8, 0, @test_write_data_32::binary>>

    {message, _timeout, _resp_len} = Request.write_zone(:otp, 0, 1, 0, @test_write_data_4)
    assert message == <<11, 18, 1, 8, 0, @test_write_data_4::binary>>
  end

  test "write data zone" do
    {message, timeout, resp_len} = Request.write_zone(:data, 0, 0, 0, @test_write_data_32)
    assert message == <<39, 18, 130, 0, 0, @test_write_data_32::binary>>
    assert timeout >= 26
    assert resp_len == 1

    {message, _timeout, _resp_len} = Request.write_zone(:data, 0, 1, 0, @test_write_data_32)
    assert message == <<39, 18, 130, 0, 1, @test_write_data_32::binary>>

    {message, _timeout, _resp_len} = Request.write_zone(:data, 0, 1, 0, @test_write_data_4)
    assert message == <<11, 18, 2, 0, 1, @test_write_data_4::binary>>
  end
end
