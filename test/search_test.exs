defmodule IRSearchTest do
  use ExUnit.Case

  setup do
    Application.put_env :ir, :data_filepath, "test/data/data.csv"
 
    {:ok, index, corpus} = IR.indexing(:all, corpus: true)
    {:ok, index: index, corpus: corpus} 
  end

  test "single keyword search - without supplying index/corpus" do
    doc_ids = IR.q "art"
    assert doc_ids == [4, 5]
  end

  test "keywords search - OR boolean", %{index: index, corpus: corpus} do    
    doc_ids = IR.q "van sdfsdfd eyck", index: index, corpus: corpus
    assert doc_ids == [4, 5, 6]

    doc_ids = IR.q "christopher columbus carlo rovelli", index: index, corpus: corpus
    assert doc_ids == [1, 7]
  end

  test "keywords search - AND boolean", %{index: index, corpus: corpus} do
    doc_ids = IR.q "northern renaissance van eyck", index: index, corpus: corpus, op: :and
    assert doc_ids == [5, 6]
  end

  test "keywords search - 0 results" do
    doc_ids = IR.q "sdfdsfsdfsdfsd"
    assert doc_ids == []

    doc_ids = IR.q "sdfsdfd sdfssd sdsdf"
    assert doc_ids == []

    doc_ids = IR.q "van sdfsdfd eyck", op: :and
    assert doc_ids == []

    doc_ids = IR.q "sdfsdfd eyck", op: :and
    assert doc_ids == []

    doc_ids = IR.q "christopher columbus carlo rovelli", op: :and
    assert doc_ids == []
  end

end
