defmodule ATECC508A do
  @moduledoc """
  The ATECC508A is an authentication device used for storing private keys
  and other data securely.
  """

  @typedoc """
  This represents the ATECC508A 9-byte device serial number
  """
  @type serial_number() :: <<_::72>>

  @typedoc """
  ATECC508A compressed certificates have 16-byte serial numbers
  """
  @type cert_serial_number() :: <<_::128>>

  @typedoc """
  ATECC508A compressed certificates use a 3-byte encoding for the validity date range.
  """
  @type encoded_dates() :: <<_::24>>

  @typedoc """
  An ECC P256 public key
  """
  @type ecc_public_key() :: <<_::512>>

  @typedoc """
  Microchip P256 compressed certificate

  See Atmel-8974A app note
  """
  @type compressed_cert() :: <<_::576>>

  @typedoc """
  A SHA256 hash
  """
  @type sha256() :: <<_::256>>

  @typedoc """
  A CRC16 as computed by the ATECC508A
  """
  @type crc16() :: <<_::16>>
end
