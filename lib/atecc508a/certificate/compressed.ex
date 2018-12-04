defmodule ATECC508A.Certificate.Compressed do
  @moduledoc """
  An ATECC508A compressed certificate and accompanying information needed to decompress it.

  The fields are:

  * `:data` - the compressed certificate data
  * `:device_sn` - if a device serial number is needed to decompress the cert, then this is set
  * `:public_key` - the certificate's public key
  * `:serial_number` - if the compressed certificate uses an arbitrary serial number, then this is it
  * `:subject_rdn` - the subject RDN that should be re-added to the cert when uncompressed
  * `:issuer_rdn` - the issuer's RDN that should be re-added to the cert when uncompressed
  * `:extensions` - the X.509 extensions that should be re-added to the cert when uncompressed
  * `:template` - the template that was use to compress the certificate

  """

  defstruct [
    :data,
    :device_sn,
    :public_key,
    :serial_number,
    :subject_rdn,
    :issuer_rdn,
    :extensions,
    :template
  ]

  @type t :: %__MODULE__{
          data: ATECC508A.compressed_cert(),
          device_sn: ATECC508A.serial_number() | nil,
          public_key: ATECC508A.ecc_public_key(),
          serial_number: binary() | nil,
          subject_rdn: String.t() | X509.RDNSequence.t(),
          issuer_rdn: String.t() | X509.RDNSequence.t(),
          extensions: [X509.Certificate.Extension.t()],
          template: ATECC508A.Certificate.Template
        }
end
