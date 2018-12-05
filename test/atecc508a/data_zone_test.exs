defmodule ATECC508A.DataZoneTest do
  use ExUnit.Case

  alias ATECC508A.DataZone

  test "pad to slot size" do
    assert DataZone.pad_to_slot_size(0, <<>>) == <<0::size(36)-unit(8)>>
    assert DataZone.pad_to_slot_size(1, <<1>>) == <<1, 0::size(35)-unit(8)>>
    assert DataZone.pad_to_slot_size(2, <<2>>) == <<2, 0::size(35)-unit(8)>>
    assert DataZone.pad_to_slot_size(3, <<3>>) == <<3, 0::size(35)-unit(8)>>
    assert DataZone.pad_to_slot_size(4, <<4>>) == <<4, 0::size(35)-unit(8)>>
    assert DataZone.pad_to_slot_size(5, <<5>>) == <<5, 0::size(35)-unit(8)>>
    assert DataZone.pad_to_slot_size(6, <<6>>) == <<6, 0::size(35)-unit(8)>>
    assert DataZone.pad_to_slot_size(7, <<7>>) == <<7, 0::size(35)-unit(8)>>
    assert DataZone.pad_to_slot_size(8, <<8>>) == <<8, 0::size(415)-unit(8)>>
    assert DataZone.pad_to_slot_size(9, <<9>>) == <<9, 0::size(71)-unit(8)>>
    assert DataZone.pad_to_slot_size(10, <<10>>) == <<10, 0::size(71)-unit(8)>>
    assert DataZone.pad_to_slot_size(11, <<11>>) == <<11, 0::size(71)-unit(8)>>
    assert DataZone.pad_to_slot_size(12, <<12>>) == <<12, 0::size(71)-unit(8)>>
    assert DataZone.pad_to_slot_size(13, <<13>>) == <<13, 0::size(71)-unit(8)>>
    assert DataZone.pad_to_slot_size(14, <<14>>) == <<14, 0::size(71)-unit(8)>>
    assert DataZone.pad_to_slot_size(15, <<15>>) == <<15, 0::size(71)-unit(8)>>
  end

  test "no padding when the exact slot size" do
    data = :crypto.strong_rand_bytes(36)
    assert DataZone.pad_to_slot_size(1, data) == data
  end

  test "pad to 32-bytes" do
    assert DataZone.pad_to_32(<<>>) == <<>>
    assert DataZone.pad_to_32(<<1>>) == <<1, 0::size(31)-unit(8)>>
    assert DataZone.pad_to_32(<<0::size(32)-unit(8)>>) == <<0::size(32)-unit(8)>>
  end
end
