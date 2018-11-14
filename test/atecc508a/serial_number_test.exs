defmodule ATECC508A.SerialNumberTest do
  use ExUnit.Case

  alias ATECC508A.SerialNumber

  test "verify test vectors" do
    # These were manually checked.
    assert SerialNumber.from_device_sn(<<0::72>>, <<0::24>>) ==
             114_212_275_507_497_809_804_692_595_957_010_019_923

    assert SerialNumber.from_public_key(<<0::512>>, <<0::24>>) ==
             122_136_849_383_167_108_807_819_891_765_977_662_465
  end
end
