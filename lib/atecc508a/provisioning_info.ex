defmodule ATECC508A.ProvisioningInfo do
  @moduledoc """
  This struct contains all of the data needed to provision a device.
  """

  defstruct otp_flags: 0,
            board_name: "",
            mfg_serial_number: "",
            otp_user: <<>>,
            device_compressed_cert: <<0::576>>,
            signer_public_key: <<0::512>>,
            signer_compressed_cert: <<0::576>>,
            signer_serial_number: <<>>,
            root_cert_sha256: <<0::256>>

  @type t :: %__MODULE__{
          otp_flags: integer(),
          board_name: String.t(),
          mfg_serial_number: String.t(),
          otp_user: binary(),
          device_compressed_cert: ATECC508A.compressed_cert(),
          signer_public_key: ATECC508A.ecc_public_key(),
          signer_compressed_cert: ATECC508A.compressed_cert(),
          signer_serial_number: binary(),
          root_cert_sha256: ATECC508A.sha256()
        }
end
