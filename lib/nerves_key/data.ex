defmodule NervesKey.Data do
  @moduledoc """
  This module handles Data Zone data stored in the Nerves Key.
  """

  # @doc """
  # Read the device certificate
  # """
  # @spec read_device_certificate(Transport.t()) :: {:ok, X509.Certificate.t()} | {:error, atom()}
  # def read_device_certificate(transport) do
  #   with {:ok, compressed_cert} <- DataZone.read(transport, 10),
  #        {:ok, public_key} <- Request.genkey(transport, 0, false),

  #   do
  #     cert = ATECC508A.Certificate.decompress(compressed_cert, public_key)
  #   end
  # end

  @doc """
  Create a public/private key pair

  The public key is returned on success. This can only be called on devices that
  have their configuration locked, but not their data.
  """
  @spec genkey(ATECC508A.Transport.t()) :: {:ok, X509.PublicKey.t()} | {:error, atom()}
  def genkey(transport) do
    with {:ok, raw_key} = ATECC508A.Request.genkey(transport, 0, true) do
      {:ok, ATECC508A.Certificate.raw_to_public_key(raw_key)}
    end
  end

  @doc """
  Determine what's in all of the data slots
  """
  @spec slot_data(ATECC508A.serial_number(), X509.Certificate.t(), X509.Certificate.t()) :: [
          {ATECC508A.Request.slot(), binary()}
        ]
  def slot_data(device_sn, device_cert, signer_cert) do
    device_template = ATECC508A.Certificate.Template.device(device_sn)
    device_compressed = ATECC508A.Certificate.compress(device_cert, device_template)

    signer_template = ATECC508A.Certificate.Template.signer()
    signer_compressed = ATECC508A.Certificate.compress(signer_cert, signer_template)

    # See README.md for slot contents. We still need to program unused slots in order
    # to lock the device so specify nothing so they'll get padded with zeros to the
    # appropriate size.
    [
      {1, <<>>},
      {2, <<>>},
      {3, <<>>},
      {4, <<>>},
      {5, <<>>},
      {6, <<>>},
      {7, <<>>},
      {8, <<>>},
      {9, <<>>},
      {10, device_compressed.data},
      {11, signer_compressed.public_key},
      {12, signer_compressed.data},
      {13, <<>>},
      {14, <<>>},
      {15, <<>>}
    ]
    |> Enum.map(fn {slot, data} -> {slot, ATECC508A.DataZone.pad_to_slot_size(slot, data)} end)
  end

  @doc """
  Write all of the slots
  """
  def write_slots(transport, slot_data) do
    Enum.each(slot_data, fn {slot, data} ->
      :ok = ATECC508A.DataZone.write_padded(transport, slot, data)
    end)
  end

  # @doc """
  # Lock the OTP and data zones.

  # There's no going back!
  # """
  @spec lock(ATECC508A.Transport.t(), binary(), [{Request.slot(), binary()}]) ::
          :ok | {:error, atom()}
  def lock(transport, otp_data, slot_data) do
    sorted_slot_data =
      Enum.sort(slot_data, fn {slot1, _data1}, {slot2, _data2} -> slot1 < slot2 end)

    all_data =
      [Enum.map(sorted_slot_data, fn {_slot, data} -> data end), otp_data]
      |> IO.iodata_to_binary()

    ATECC508A.DataZone.lock(transport, all_data)
  end
end
