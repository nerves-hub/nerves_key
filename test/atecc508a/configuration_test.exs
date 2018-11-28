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

  @test_data_128 @test_data0_32 <> @test_data1_32 <> @test_data2_32 <> @test_data3_32

  @test_config %ATECC508A.Configuration{
    chip_mode: 0,
    counter0: 4_294_967_295,
    counter1: 4_294_967_295,
    i2c_address: 192,
    i2c_enable: 21,
    key_config:
      <<51, 0, 51, 0, 51, 0, 28, 0, 28, 0, 28, 0, 28, 0, 28, 0, 60, 0, 60, 0, 60, 0, 60, 0, 60, 0,
        60, 0, 60, 0, 28, 0>>,
    last_key_use:
      <<255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255>>,
    lock_config: 85,
    lock_value: 85,
    otp_mode: 85,
    reserved0: 192,
    reserved1: 0,
    reserved2: 0,
    rev_num: :ecc508a,
    rfu: <<0, 0>>,
    selector: 0,
    serial_number: <<1, 35, 11, 195, 244, 133, 240, 153, 238>>,
    slot_config:
      <<143, 32, 15, 15, 15, 15, 15, 15, 143, 143, 143, 143, 159, 143, 175, 143, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 175, 143>>,
    slot_locked: 65535,
    user_extra: 0,
    x509_format: <<0, 0, 0, 0>>
  }

  setup :verify_on_exit!

  test "read the entire config zone" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<2, 128, 0, 0>>, _, 32 -> {:ok, @test_data0_32} end)
    |> expect(:request, fn _, <<2, 128, 8, 0>>, _, 32 -> {:ok, @test_data1_32} end)
    |> expect(:request, fn _, <<2, 128, 16, 0>>, _, 32 -> {:ok, @test_data2_32} end)
    |> expect(:request, fn _, <<2, 128, 24, 0>>, _, 32 -> {:ok, @test_data3_32} end)

    assert Configuration.read_all_raw(@mock_transport) == {:ok, @test_data_128}
  end

  test "convert to and from raw" do
    assert Configuration.to_raw(Configuration.from_raw(@test_data_128)) == @test_data_128
  end

  test "read and decode the config zone" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<2, 128, 0, 0>>, _, 32 ->
      {:ok,
       <<1, 35, 11, 195, 0, 0, 80, 0, 244, 133, 240, 153, 238, 192, 21, 0, 192, 0, 85, 0, 143, 32,
         15, 15, 15, 15, 15, 15, 143, 143, 143, 143>>}
    end)
    |> expect(:request, fn _, <<2, 128, 8, 0>>, _, 32 ->
      {:ok,
       <<159, 143, 175, 143, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 175, 143, 255, 255, 255,
         255, 0, 0, 0, 0, 255, 255, 255, 255>>}
    end)
    |> expect(:request, fn _, <<2, 128, 16, 0>>, _, 32 ->
      {:ok,
       <<0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
         255, 0, 0, 85, 85, 255, 255, 0, 0, 0, 0, 0, 0>>}
    end)
    |> expect(:request, fn _, <<2, 128, 24, 0>>, _, 32 ->
      {:ok,
       <<51, 0, 51, 0, 51, 0, 28, 0, 28, 0, 28, 0, 28, 0, 28, 0, 60, 0, 60, 0, 60, 0, 60, 0, 60,
         0, 60, 0, 60, 0, 28, 0>>}
    end)

    {:ok, info} = Configuration.read(@mock_transport)

    assert info.i2c_address == 0xC0
    assert info.counter0 == 4_294_967_295
    assert info.counter1 == 4_294_967_295
    assert info.x509_format == <<0, 0, 0, 0>>
    assert info.user_extra == 0
    assert info.slot_locked == 0xFFFF
    assert info.serial_number == <<1, 35, 11, 195, 244, 133, 240, 153, 238>>
    assert info.rev_num == :ecc508a
    assert info.otp_mode == 0x55
    assert info.lock_value == 0x55
    assert info.lock_config == 0x55
    assert info.chip_mode == 0

    assert info.key_config ==
             <<51, 0, 51, 0, 51, 0, 28, 0, 28, 0, 28, 0, 28, 0, 28, 0, 60, 0, 60, 0, 60, 0, 60, 0,
               60, 0, 60, 0, 60, 0, 28, 0>>

    assert info.slot_config ==
             <<143, 32, 15, 15, 15, 15, 15, 15, 143, 143, 143, 143, 159, 143, 175, 143, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 175, 143>>
  end

  test "write everything" do
    info = @test_config

    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<18, 0, 4, 0, 192, 0, 85, 0>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 5, 0, 143, 32, 15, 15>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 6, 0, 15, 15, 15, 15>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 7, 0, 143, 143, 143, 143>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _,
                           <<18, 128, 8, 0, 159, 143, 175, 143, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                             0, 0, 0, 175, 143, 255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255,
                             255>>,
                           _,
                           1 ->
      {:ok, <<0>>}
    end)
    |> expect(:request, fn _, <<18, 0, 16, 0, 0, 0, 0, 0>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 17, 0, 255, 255, 255, 255>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 18, 0, 255, 255, 255, 255>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 19, 0, 255, 255, 255, 255>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 20, 0, 255, 255, 255, 255>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _, <<18, 0, 23, 0, 0, 0, 0, 0>>, _, 1 -> {:ok, <<0>>} end)
    |> expect(:request, fn _,
                           <<18, 128, 24, 0, 51, 0, 51, 0, 51, 0, 28, 0, 28, 0, 28, 0, 28, 0, 28,
                             0, 60, 0, 60, 0, 60, 0, 60, 0, 60, 0, 60, 0, 60, 0, 28, 0>>,
                           _,
                           1 ->
      {:ok, <<0>>}
    end)

    Configuration.write(@mock_transport, info)
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

  test "lock config" do
    expected_crc = @test_config |> Configuration.to_raw() |> ATECC508A.CRC.crc()

    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<0x17, 0, ^expected_crc::binary>>, _, 1 -> {:ok, <<0>>} end)

    assert Configuration.lock(@mock_transport, @test_config)
  end
end
