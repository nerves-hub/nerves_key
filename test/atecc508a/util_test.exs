defmodule ATECC508A.UtilTest do
  use ExUnit.Case

  alias ATECC508A.Util

  test "zero pads properly" do
    assert Util.pad_zeros(<<1, 2, 3, 4>>, 8) == <<1, 2, 3, 4, 0, 0, 0, 0>>
    assert Util.pad_zeros(<<1, 2, 3, 4>>, 4) == <<1, 2, 3, 4>>
    assert Util.pad_zeros(<<1, 2, 3, 4>>, 2) == <<1, 2>>
    assert Util.pad_zeros(<<>>, 2) == <<0, 0>>
  end

  test "zero trims properly" do
    assert Util.trim_zeros(<<1, 2, 3, 4, 0, 0, 0, 0>>) == <<1, 2, 3, 4>>
    assert Util.trim_zeros(<<1, 2, 3, 4>>) == <<1, 2, 3, 4>>
    assert Util.trim_zeros(<<0>>) == <<>>
    assert Util.trim_zeros(<<>>) == <<>>
  end
end
