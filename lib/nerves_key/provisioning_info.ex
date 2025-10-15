# SPDX-FileCopyrightText: 2018 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesKey.ProvisioningInfo do
  defstruct manufacturer_sn: "", board_name: "NervesKey", mode: :unprovisioned

  @type t :: %__MODULE__{
          manufacturer_sn: binary(),
          board_name: binary(),
          mode: :unprovisioned | :regular | :volatile | :unrecognized
        }

  def default do
    %__MODULE__{}
  end
end
