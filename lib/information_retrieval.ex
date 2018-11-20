defmodule IR.Doc do
  @moduledoc """
  Data struct for a document
  """

  # `title` and `description` for the time being
  defstruct [:title, :description]
  @type t :: %__MODULE__{title: binary, description: binary}

end

defmodule IR do
  @moduledoc """
  Documentation for IR.
  """

  @type corpus :: %{required(integer) => IR.Doc.t}
  @type index :: %{required(binary) => MapSet.t}

  @doc """
  Build an in-memory corpus by parsing CSV dataset or subset.

  The function automatically assigns ids (starting from 1).

  ### Example

  ```
    # parse the entire dataset
    iex> {:ok, corpus} = IR.parse(:all)
    ...

    # few documents
    iex> {:ok, corpus} = IR.parse(2)
    {:ok,
     %{
       1 => %IR.Doc{
         description: "In this mind-bending introduction to modern physics, Carlo Rovelli explains Einstein's theory of general relativity, quantum mechanics, black holes, the complex architecture of the universe, elementary particles, gravity, and the nature of the mind.Everything you need to know about modern physics, the universe and our place in the world in seven enlightening lessons. 'Here, on the edge of what we know, in contact with the ocean of the unknown, shines the mystery and the beauty of the world. And it's breathtaking' These seven short lessons guide us, with simplicity and clarity, through the scientific revolution that shook physics in the twentieth century and still continues to shake us today. In this mind-bending introduction to modern physics, Carlo Rovelli explains Einstein's theory of general relativity, quantum mechanics, black holes, the complex architecture of the universe, elementary particles, gravity, and the nature of the mind. Not since Richard Feynman's celebrated Six Easy Pieceshas physics been so vividly, intelligently and entertainingly revealed.",
         title: "Seven Brief Lessons on Physics"
       },
       2 => %IR.Doc{
         description: "A blade runner must pursue and terminate four replicants who stole a ship in space, and have returned to Earth to find their creator.",
         title: "Blade Runner"
       }
     }}
  ```
  """
  @spec parse(integer | :all) :: {:ok, corpus}
  def parse(num_of_docs) when is_number(num_of_docs) or is_atom(num_of_docs) do
    data_filepath = Application.get_env :ir, :data_filepath

    csv_data = cond do
      is_number(num_of_docs) ->
        File.stream!(data_filepath) |> CSV.decode!(headers: true) |> Enum.take(num_of_docs)
      num_of_docs == :all ->
        File.stream!(data_filepath) |> CSV.decode!(headers: true)
    end

    corpus = csv_data
      |> Enum.with_index(1)
      |> Enum.into(%{}, fn {doc, i} -> parse(doc, i) end)
 
    {:ok, corpus}
  end

  @doc false
  def parse(doc, id) do
    {id, %IR.Doc{ :title => doc["title"], :description => doc["description"]}}
  end

  @doc """
  Create an in-memory inverted index from the CSV dataset or subset.

  Includes a `corpus` boolean option for building an in-memory corpus while indexing.

  ### Example

  ```
    # index the entire dataset
    iex> {:ok, index} = IR.indexing(:all)
    ...

    # index specific number of documents
    iex> {:ok, index} = IR.indexing(500)
    ... # %{ "term" => "postings"..}

    # indexing and build text corpus
    iex> {:ok, index, corpus} = IR.indexing(5000, corpus: true)
    ...

  ```
  """
  @spec indexing(integer, keyword) :: {:ok, index} | {:ok, index, corpus}
  def indexing(num_of_docs, options \\ [corpus: false]) when is_number(num_of_docs) or is_atom(num_of_docs) do
    IO.puts "Indexing.."
    data_filepath = Application.get_env :ir, :data_filepath
    build_corpus? = Keyword.fetch! options, :corpus

    csv_data = cond do
      is_number(num_of_docs) ->
        File.stream!(data_filepath) |> CSV.decode!(headers: true) |> Enum.take(num_of_docs)
      num_of_docs == :all ->
        File.stream!(data_filepath) |> CSV.decode!(headers: true) |> Enum.to_list
    end

    id = 1
    index = %{}
    corpus = if build_corpus?, do: %{}, else: nil

    {index, corpus} = csv_data |> _indexing(id, index, corpus)

    if build_corpus?, do: {:ok, index, corpus}, else: {:ok, index}
  end

  # recursively indexing the documents, storing the results in `index`
  defp _indexing([], _id,  index, corpus), do: {index, corpus}
  defp _indexing([doc | docs], id, index, corpus) do
    updated_index = (doc["title"] <> " " <> doc["description"])
    |> String.downcase
    |> String.split(" ") # simple tokenisation, could stem/remove stopwords later
    |> Enum.uniq
    |> build(id, index)

    # optionally create a corpus
    updated_corpus = unless is_nil(corpus) do
      {_, doc_struct} = parse(doc, id)
      Map.put corpus, id, doc_struct
    else
      nil
    end

    _indexing(docs, id + 1, updated_index, updated_corpus)
  end

  # recursively create a set of doc IDs postings per term
  defp build([], _id, index), do: index
  defp build([term|terms], id, index) do
    postings = if is_nil(index[term]), do: MapSet.new(), else: index[term]

    updated_postings = MapSet.put(postings, id)
    updated_index = Map.put index, term, updated_postings

    build(terms, id, updated_index)
  end

end
