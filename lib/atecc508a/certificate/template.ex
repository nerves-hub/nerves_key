defmodule ATECC508A.Certificate.Template do

  defstruct [:signer_id, :template_id, :sn_source, :device_sn, :certificate_sn]

  @type t :: %__MODULE__{
    signer_id: 0..65535,
    template_id: 0..15,
    sn_source: ATECC508A.sn_source(),
    device_sn: ATECC508A.serial_number() | nil,
    certificate_sn: binary() | nil

    }

  @spec signer() :: t()
  def signer() do
    %__MODULE__{
      signer_id: 0,
      template_id: 1,
      sn_source: :public_key,
      device_sn: nil,

    }
  end

  @spec device(ATECC508A.serial_number()) :: t()
  def device(device_sn) do
    %__MODULE__{
      signer_id: 0,
      template_id: 0,
      sn_source: :device_sn,
      device_sn: device_sn
    }
  end
end
