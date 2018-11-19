defmodule IRTest do
  use ExUnit.Case
  doctest IR

  test "parse a single doc" do
    assert length(IR.parse(1)) == 1
  end
end
