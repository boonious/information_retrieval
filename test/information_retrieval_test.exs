defmodule IRTest do
  use ExUnit.Case
  doctest IR

  setup do
    data_filepath = Application.get_env :ir, :data_filepath
    on_exit fn ->
      Application.put_env :ir, :data_filepath, data_filepath
    end
  end

  test "parse a single doc" do
    Application.put_env :ir, :data_filepath, "test/data/data.csv"
    assert length(IR.parse(1)) == 1
  end
end
