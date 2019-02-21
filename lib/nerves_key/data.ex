defmodule NervesKey.Data do
  @moduledoc """
  This module handles Data Zone data stored in the NervesKey.
  """

  @doc """
  Create a public/private key pair

  The public key is returned on success. This can only be called on devices that
  have their configuration locked, but not their data.
  """
  @spec genkey(ATECC508A.Transport.t(), boolean()) :: {:ok, X509.PublicKey.t()} | {:error, atom()}
  def genkey(transport, create? \\ true) do
    with {:ok, raw_key} <- genkey_raw(transport, create?) do
      {:ok, ATECC508A.Certificate.raw_to_public_key(raw_key)}
    end
  end

  @doc """
  Run the genkey operation on the NervesKey private key slot
  """
  @spec genkey_raw(ATECC508A.Transport.t(), boolean()) ::
          {:ok, ATECC508A.ecc_public_key()} | {:error, atom()}
  def genkey_raw(transport, create?) do
    ATECC508A.Request.genkey(transport, 0, create?)
  end

  @doc """
  Determine what's in all of the data slots
  """
  @spec slot_data(ATECC508A.serial_number(), X509.Certificate.t(), X509.Certificate.t()) :: [
          {ATECC508A.Request.slot(), binary()}
        ]
  def slot_data(device_sn, device_cert, signer_cert) do
    signer_template =
      signer_cert
      |> X509.Certificate.public_key()
      |> ATECC508A.Certificate.Template.signer()

    signer_compressed = ATECC508A.Certificate.compress(signer_cert, signer_template)

    device_template =
      ATECC508A.Certificate.Template.device(device_sn, signer_compressed.public_key)

    device_compressed = ATECC508A.Certificate.compress(device_cert, device_template)

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
  @spec write_slots(ATECC508A.Transport.t(), [{ATECC508A.Request.slot(), binary()}]) :: :ok
  def write_slots(transport, slot_data) do
    Enum.each(slot_data, fn {slot, data} ->
      :ok = ATECC508A.DataZone.write_padded(transport, slot, data)
    end)
  end

  @doc """
  Write new device and signer certificates to the auxillary slots
  """
  @spec write_aux_certs(
          ATECC508A.Transport.t(),
          ATECC508A.serial_number(),
          X509.Certificate.t(),
          X509.Certificate.t()
        ) :: :ok
  def write_aux_certs(transport, device_sn, device_cert, signer_cert) do
    signer_template =
      signer_cert
      |> X509.Certificate.public_key()
      |> ATECC508A.Certificate.Template.signer()

    signer_compressed = ATECC508A.Certificate.compress(signer_cert, signer_template)

    device_template =
      ATECC508A.Certificate.Template.device(device_sn, signer_compressed.public_key)

    device_compressed = ATECC508A.Certificate.compress(device_cert, device_template)

    :ok =
      ATECC508A.DataZone.write_padded(transport, device_cert_slot(:aux), device_compressed.data)

    :ok =
      ATECC508A.DataZone.write_padded(
        transport,
        signer_pubkey_slot(:aux),
        signer_compressed.public_key
      )

    :ok =
      ATECC508A.DataZone.write_padded(transport, signer_cert_slot(:aux), signer_compressed.data)
  end

  @doc """
  Clear out the auxillary slots
  """
  @spec clear_aux_certs(ATECC508A.Transport.t()) :: :ok
  def clear_aux_certs(transport) do
    :ok = clear_slot(transport, device_cert_slot(:aux))
    :ok = clear_slot(transport, signer_pubkey_slot(:aux))
    :ok = clear_slot(transport, signer_cert_slot(:aux))
  end

  defp clear_slot(transport, slot) do
    blank = ATECC508A.DataZone.pad_to_slot_size(slot, <<>>)
    ATECC508A.DataZone.write_padded(transport, slot, blank)
  end

  # @doc """
  # Lock the OTP and data zones.

  # There's no going back!
  # """
  @spec lock(ATECC508A.Transport.t(), binary(), [{ATECC508A.Request.slot(), binary()}]) ::
          :ok | {:error, atom()}
  def lock(transport, otp_data, slot_data) do
    sorted_slot_data =
      Enum.sort(slot_data, fn {slot1, _data1}, {slot2, _data2} -> slot1 < slot2 end)

    all_data =
      [Enum.map(sorted_slot_data, fn {_slot, data} -> data end), otp_data]
      |> IO.iodata_to_binary()

    ATECC508A.DataZone.lock(transport, all_data)
  end

  # See README.md for slot assignments

  @doc """
  Return the slot that stores the compressed device certificate.
  """
  @spec device_cert_slot(NervesKey.certificate_pair()) :: ATECC508A.Request.slot()
  def device_cert_slot(:primary), do: 10
  def device_cert_slot(:aux), do: 9

  @doc """
  Return the slot that stores the compressed signer certificate.
  """
  @spec signer_cert_slot(NervesKey.certificate_pair()) :: ATECC508A.Request.slot()
  def signer_cert_slot(:primary), do: 12
  def signer_cert_slot(:aux), do: 15

  @doc """
  Return the slot that stores the signer's public key.
  """
  @spec signer_pubkey_slot(NervesKey.certificate_pair()) :: ATECC508A.Request.slot()
  def signer_pubkey_slot(:primary), do: 11
  def signer_pubkey_slot(:aux), do: 14
end
