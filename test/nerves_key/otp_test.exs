defmodule NervesKey.OTPTest do
  use ExUnit.Case

  alias NervesKey.OTP

  @test_data %OTP{
    flags: 1234,
    manufacturer_sn: "1234578",
    board_name: "my_board",
    user:
      <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
        25, 26, 27, 28, 29, 30, 31>>
  }

  test "to raw and back" do
    raw_and_back = @test_data |> OTP.to_raw() |> OTP.from_raw()
    assert raw_and_back == @test_data
  end

  test "magic is right" do
    <<magic::4-bytes, _rest::binary()>> = OTP.to_raw(@test_data)
    assert magic == <<0x4E, 0x72, 0x76, 0x73>>
  end
end
