defmodule ATECC508A.CompressedCertificate do

  @moduledoc """
  An ATECC508A compressed certificate and accompanying information needed to decompress it.

  The fields are:

  * `:data` - the compressed certificate data
  * `:device_sn` - if a device serial number is needed to decompress the cert, then this is set
  * `:public_key` - the certificate's public key
  * `:serial_number` - if the compressed certificate uses an arbitrary serial number, then this is it

  """

  defstruct [
    :data,
    :device_sn,
    :public_key,
    :serial_number
  ]

  @type t :: %__MODULE__{
        data: ATECC508A.compressed_cert(),
        device_sn: ATECC508A.serial_number() | nil,
          public_key: ATECC508A.ecc_public_key() | nil,
          serial_number: binary() | nil
        }


end
