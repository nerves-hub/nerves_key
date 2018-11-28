defmodule ATECC508A.Transport.I2C do
  alias ATECC508A.Transport

  @behaviour Transport

  # 1.5 ms in the datasheet
  @atecc508a_wake_delay_ms 2
  @atecc508a_signature <<0x04, 0x11, 0x33, 0x43>>

  @default_atecc508a_address 0x60

  @type instance :: {Circuits.I2C.bus(), Circuits.I2C.address()}

  @impl Transport
  @spec init(keyword()) :: {:ok, Transport.t()} | {:error, atom()}
  def init(args) do
    bus_name = Keyword.get(args, :bus_name, "i2c-1")
    address = Keyword.get(args, :address, @default_atecc508a_address)

    case Circuits.I2C.open(bus_name) do
      {:ok, i2c} -> {:ok, {__MODULE__, {i2c, address}}}
      error -> error
    end
  end

  @impl Transport
  @spec request(instance(), binary(), non_neg_integer(), non_neg_integer()) ::
          {:error, atom()} | {:ok, binary()}
  def request({i2c, address}, payload, timeout, response_payload_len) do
    to_send = package(payload)
    response_len = response_payload_len + 3

    with :ok <- wakeup(i2c, address),
         :ok <- Circuits.I2C.write(i2c, address, to_send),
         Process.sleep(timeout),
         {:ok, response} <- Circuits.I2C.read(i2c, address, response_len),
         sleep(i2c, address) do
      unpackage(response)
    end
  end

  @doc """
  Package up a request for transmission over I2C
  """
  @spec package(binary()) :: iodata()
  def package(request) do
    len = byte_size(request) + 3
    crc = ATECC508A.CRC.crc(<<len, request::binary>>)
    [3, len, request, crc]
  end

  @doc """
  Extract the response from the data returned from an I2C read
  """
  @spec unpackage(binary()) :: {:ok, binary()} | {:error, atom()}
  def unpackage(<<length, payload_and_crc::binary>>) do
    with {:ok, payload, crc} <- extract_payload(length - 3, payload_and_crc),
         ^crc <- ATECC508A.CRC.crc(<<length, payload::binary>>) do
      {:ok, payload}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :bad_crc}
    end
  end

  defp extract_payload(payload_length, payload_and_crc) do
    try do
      <<payload::binary-size(payload_length), crc::binary-size(2), _extra::binary>> =
        payload_and_crc

      {:ok, payload, crc}
    catch
      _, _ ->
        {:error, :short_packet}
    end
  end

  defp wakeup(i2c, address) do
    # See ATECC508A 6.1 for the wakeup sequence.
    #
    # Write to address 0 to pull SDA down for the wakeup interval (60 uS).
    # Since only 8-bits get through, the I2C speed needs to be < 133 KHz for
    # this to work. This "fails" since nobody will ACK the write and that's
    # expected.
    Circuits.I2C.write(i2c, 0, <<0>>)

    # Wait for the device to wake up for real
    Process.sleep(@atecc508a_wake_delay_ms)

    # Check that it's awake by reading its signature
    case Circuits.I2C.read(i2c, address, 4) do
      {:ok, @atecc508a_signature} -> :ok
      {:ok, _something_else} -> {:error, :unexpected_wakeup_response}
      error -> error
    end
  end

  defp sleep(i2c, address) do
    # See ATECC508A 6.2 for the sleep sequence.
    Circuits.I2C.write(i2c, address, <<0x01>>)
  end
end
