defmodule IRTest do
  use ExUnit.Case

  setup do
    data_filepath = Application.get_env :ir, :data_filepath
    on_exit fn ->
      Application.put_env :ir, :data_filepath, data_filepath
    end
  end

  test "parse a single doc" do
    Application.put_env :ir, :data_filepath, "test/data/data.csv"

    {:ok, corpus} = IR.parse(1)
    assert Map.size(corpus) == 1
  end

  test "parse all docs" do
    Application.put_env :ir, :data_filepath, "test/data/data.csv"

    {:ok, corpus} = IR.parse(:all)
    assert Map.size(corpus) > 1
  end

  test "index a single doc" do
    Application.put_env :ir, :data_filepath, "test/data/data.csv"

    {:ok, index} = IR.indexing(1)

    assert Map.size(index) > 1
    assert index["black"] |> MapSet.to_list == [1]
  end

  test "index all docs" do
    Application.put_env :ir, :data_filepath, "test/data/data.csv"

    {:ok, index} = IR.indexing(:all)

    assert Map.size(index) > 1
    assert index["explains"] |> MapSet.to_list == [1,5]
  end

  test "index all docs, build corpus" do
    Application.put_env :ir, :data_filepath, "test/data/data.csv"

    {:ok, index, corpus} = IR.indexing(:all, corpus: true)

    assert Map.size(index) > 1
    assert Map.size(corpus) > 1
    assert index["explains"] |> MapSet.to_list == [1,5]
  end

end
