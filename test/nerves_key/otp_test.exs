defmodule NervesKey.OTPTest do
  use ExUnit.Case

  alias NervesKey.OTP

  defp assert_raw_and_back(otp) do
    raw_and_back = otp |> OTP.to_raw() |> OTP.from_raw!()

    assert otp == raw_and_back
  end

  test "magic is right" do
    <<magic::4-bytes, _rest::binary()>> = OTP.to_raw(OTP.new("", ""))
    assert magic == <<0x4E, 0x72, 0x76, 0x73>>
  end

  test "encode normal length serial numbers" do
    otp =
      OTP.new(
        "my_board",
        "1234578",
        <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
          24, 25, 26, 27, 28, 29, 30, 31>>
      )

    assert OTP.to_raw(otp) ==
             <<0x4E, 0x72, 0x76, 0x73, 0x00, 0x00, "my_board", 0, 0, "1234578", 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
               21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31>>

    assert_raw_and_back(otp)
  end

  test "encode 16 byte serial" do
    otp = OTP.new("my_board", "1234567890123456")

    assert OTP.to_raw(otp) ==
             <<0x4E, 0x72, 0x76, 0x73, 0x00, 0x00, "my_board", 0, 0, "1234567890123456", 0::256>>

    assert_raw_and_back(otp)
  end

  test "encode 17 byte serial" do
    otp = OTP.new("my_board", "12345678901234567")

    assert OTP.to_raw(otp) ==
             <<0x4E, 0x72, 0x76, 0x73, 0x00, 0x01, "my_board", 0, 0, "12345678901234567", 0::248>>

    assert_raw_and_back(otp)
  end

  test "encode 32 byte serial" do
    otp = OTP.new("my_board", "12345678901234567890123456789012")

    assert OTP.to_raw(otp) ==
             <<0x4E, 0x72, 0x76, 0x73, 0x00, 0x01, "my_board", 0, 0,
               "12345678901234567890123456789012", 0::128>>

    assert_raw_and_back(otp)
  end
end
