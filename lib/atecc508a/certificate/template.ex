defmodule ATECC508A.Certificate.Template do
  defstruct [
    :signer_id,
    :template_id,
    :chain_id,
    :sn_source,
    :device_sn,
    :certificate_sn,
    extensions: []
  ]

  alias X509.Certificate.Extension

  @type t :: %__MODULE__{
          signer_id: 0..65535,
          template_id: 0..15,
          chain_id: 0..15,
          sn_source: ATECC508A.sn_source(),
          device_sn: ATECC508A.serial_number() | nil,
          certificate_sn: binary() | nil,
          extensions: [Extension.t()]
        }

  @spec signer(X509.PublicKey.t()) :: t()
  def signer(public_key) do
    %__MODULE__{
      signer_id: 0,
      template_id: 1,
      chain_id: 0,
      sn_source: :public_key,
      device_sn: nil,
      extensions: [
        Extension.basic_constraints(true, 0),
        Extension.key_usage([:digitalSignature, :keyCertSign, :cRLSign]),
        Extension.ext_key_usage([:serverAuth, :clientAuth]),
        Extension.subject_key_identifier(public_key),
        Extension.authority_key_identifier(public_key)
      ]
    }
  end

  @spec device(ATECC508A.serial_number(), X509.PublicKey.t()) :: t()
  def device(device_sn, signer_public_key) do
    %__MODULE__{
      signer_id: 0,
      template_id: 0,
      chain_id: 0,
      sn_source: :device_sn,
      device_sn: device_sn,
      extensions: [
        Extension.basic_constraints(false),
        Extension.key_usage([:digitalSignature, :keyEncipherment]),
        Extension.ext_key_usage([:clientAuth]),
        Extension.authority_key_identifier(signer_public_key)
      ]
    }
  end
end
