defmodule ATECC508A.RequestTest do
  use ExUnit.Case
  import Mox

  alias ATECC508A.Request

  @mock_transport {ATECC508A.Transport.Mock, nil}

  @test_data_64 :crypto.strong_rand_bytes(64)
  @test_data_32 :crypto.strong_rand_bytes(32)
  @test_data_4 :crypto.strong_rand_bytes(4)

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

  test "random" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<0x1B, 0, 0, 0>>, 23, 32 -> {:ok, @test_data_32} end)

    assert Request.random(@mock_transport) == {:ok, @test_data_32}
  end

  test "write config zone" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<18, 128, 0, 0, @test_data_32::binary()>>, 45, 1 ->
      {:ok, <<0>>}
    end)

    assert Request.write_zone(@mock_transport, :config, 0, @test_data_32) == :ok

    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<18, 0, 0, 0, @test_data_4::binary()>>, 45, 1 -> {:ok, <<0>>} end)

    assert Request.write_zone(@mock_transport, :config, 0, @test_data_4) == :ok
  end

  test "write otp zone" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<18, 129, 0, 0, @test_data_32::binary()>>, 45, 1 ->
      {:ok, <<0>>}
    end)

    assert Request.write_zone(@mock_transport, :otp, 0, @test_data_32) == :ok

    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<18, 1, 0, 0, @test_data_4::binary()>>, 45, 1 -> {:ok, <<0>>} end)

    assert Request.write_zone(@mock_transport, :otp, 0, @test_data_4) == :ok
  end

  test "read data zone" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<2, 130, 0, 0>>, 5, 32 -> {:ok, @test_data_32} end)

    assert Request.read_zone(@mock_transport, :data, 0, 32) == {:ok, @test_data_32}

    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<2, 130, 8, 0>>, 5, 32 -> {:ok, @test_data_32} end)

    assert Request.read_zone(@mock_transport, :data, 8, 32) == {:ok, @test_data_32}

    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<2, 2, 8, 0>>, 5, 4 -> {:ok, @test_data_4} end)

    assert Request.read_zone(@mock_transport, :data, 8, 4) == {:ok, @test_data_4}
  end

  test "write data zone" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<18, 130, 0, 0, @test_data_32::binary()>>, 45, 1 ->
      {:ok, <<0>>}
    end)

    assert Request.write_zone(@mock_transport, :data, 0, @test_data_32) == :ok
  end

  test "handles write data zone error" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<18, 130, 0, 0, @test_data_32::binary()>>, 45, 1 ->
      {:ok, <<1>>}
    end)

    assert Request.write_zone(@mock_transport, :data, 0, @test_data_32) ==
             {:error, :checkmac_or_verify_miscompare}
  end

  test "lock config zone" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<0x17, 0, 0xAA, 0x55>>, 35, 1 -> {:ok, <<0>>} end)

    assert Request.lock_zone(@mock_transport, :config, <<0xAA, 0x55>>) == :ok
  end

  test "lock data/otp zone" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<0x17, 1, 0xAA, 0x55>>, 35, 1 -> {:ok, <<0>>} end)

    assert Request.lock_zone(@mock_transport, :data, <<0xAA, 0x55>>) == :ok
  end

  test "genkey slot 0" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<0x40, 4, 0, 0>>, 653, 64 -> {:ok, @test_data_64} end)

    assert Request.genkey(@mock_transport, 0, true) == {:ok, @test_data_64}
  end

  test "genkey slot 0, no create" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<0x40, 0, 0, 0>>, 653, 64 -> {:ok, @test_data_64} end)

    assert Request.genkey(@mock_transport, 0, false) == {:ok, @test_data_64}
  end

  test "genkey slot 5" do
    ATECC508A.Transport.Mock
    |> expect(:request, fn _, <<0x40, 4, 5, 0>>, 653, 64 -> {:ok, @test_data_64} end)

    assert Request.genkey(@mock_transport, 5, true) == {:ok, @test_data_64}
  end
end
