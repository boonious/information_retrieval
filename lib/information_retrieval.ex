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
  @type term_document_matrix :: %{required(binary) => list(number)}
  @type term_idfs :: %{required(binary) => number}

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

  Includes a `corpus` boolean option (default to `false`)
  for building an in-memory corpus while indexing.

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
  def indexing(num_of_docs, opts \\ [corpus: false]) when is_number(num_of_docs) or is_atom(num_of_docs) do
    IO.puts "Indexing.."
    data_filepath = Application.get_env :ir, :data_filepath
    build_corpus? = Keyword.fetch! opts, :corpus

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
    |> analyse
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

  # simple tokenisation, could clean/stem/remove stopwords later
  @doc """
    Process text: tokenisation, downcase etc.
  """
  def analyse(text) do
    text
    |> String.downcase
    |> String.replace(~r/[\p{P}\p{S}]/, " ") # strip punctuation
    |> String.split(" ", trim: true)
    |> Enum.uniq
  end

  @doc """
  Issue a search query on a given index and corpus.

  For quick tests, the function will generate a corpus and index of 1000 (max) docs from the
  CSV dataset if pre-created index / corpus are not supplied.
  The query will be issued on this small index.

  Options:

  - `:op` - default `:or`, match ALL (`:and`) or ANY (`:or`) terms in the query
  - `:corpus`, parsed data required for results display and ranking purposes
  - `:index`, pre-created search data for querying and ranking purposes
  - `:sort` default `true`, rank results by relevancy

  ### Example

  ```
    # quick search test with up to 1000 max docs
    iex> IR.q "northern renaissance van eyck"
    Indexing..
    Found 4 results.
    [4, 5, 6, 7] # currenty return unranked doc IDs

    # stricter AND boolean search
    iex(9)> IR.q "northern renaissance van eyck", op: :and
    Indexing..
    Found 2 results.
    [5, 6]

    # create in-memory index and corpus for the entire CSV dataset
    # ( > 1000 docs)
    iex> {:ok, index, corpus} = IR.indexing(:all, corpus: true)
    ..

    # use the index / corpus in search
    iex> IR.q "renaissance", index: index, corpus: corpus
    ..

    # re-use the corpus / index for another search
    iex> IR.q "van eyck", index: index, corpus: corpus, op: :and
    ..

  ```
  """
  @spec q(binary, keyword) :: list[binary]
  def q(query, opts \\ [index: nil, corpus: nil, op: :or, sort: true])
  def q(query, opts) do
    op = if opts[:op], do: opts[:op], else: :or

    # index and build a corpus for 1000 documents from the dataset
    # if no index / corpus are provided
    if is_nil(opts[:index]) or is_nil(opts[:corpus]) do
      {:ok, index, corpus} = indexing(1000, corpus: true)
      q(query, index, corpus, op, opts[:sort])
    else
      q(query, opts[:index], opts[:corpus], op, opts[:sort])
    end
  end

  @doc false
  def q(query, index, corpus, op, sort) do
    terms = query |> analyse
    posting_sets = terms |> Enum.map(&(index[&1]))

    unranked_docs_ids = cond do
      # any nil postings indicates a missing term, 0 result (AND boolean)
      op == :and and Enum.member?(posting_sets, nil) -> []
      op == :and ->
        posting_sets
        |> ids_from_postings(:and)
        |> MapSet.to_list

      # remove nil postings of missing terms, get ids for the rest of the terms (OR boolean)
      op == :or ->
        posting_sets
        |> Enum.reject(&is_nil(&1))
        |> ids_from_postings(:or)
        |> MapSet.to_list
    end

    num_of_results = length unranked_docs_ids
    IO.puts "Found #{num_of_results} results."

    idfs = idf(terms, index, corpus)
    term_doc_matrix = tdm(unranked_docs_ids, idfs, terms, corpus)

    # ranked documents based on the sum td-idf vector for now
    #
    # next: could derive scores by computing cosine similarity 
    # between doc vectors and search term vector
    unranked_ids_with_scores = term_doc_matrix
    |> Enum.map(fn {doc_id, vector} -> {doc_id, Enum.sum(vector) |> Float.round(5)} end)

    ids_scores = case sort do
      true ->
        unranked_ids_with_scores |> Enum.sort_by(&(elem(&1,1)),  &>=/2)
      false -> unranked_ids_with_scores
      _ -> unranked_ids_with_scores 
    end

    for {id, score} <- ids_scores do
      title = corpus[id].title |> String.slice(0,100)
      description = corpus[id].description |> String.slice(0,100)
      IO.puts "\ndoc no: #{id}, score: #{score}"
      IO.puts title
      IO.puts description <> " ..."
      IO.puts "========================"
    end

    IO.puts ""
    ids_scores

  end

  # single keyword postings
  defp ids_from_postings([set], _) when is_map(set), do: set
  defp ids_from_postings([], _), do: MapSet.new([])

  # find docs containing all terms: AND boolean query
  # posting sets intersection
  defp ids_from_postings([set1, set2], :and) when is_map(set1) and is_map(set2) do
    MapSet.intersection(set1, set2)
  end

  # > 3 terms, AND boolean
  defp ids_from_postings([set1 | set2], :and) when is_map(set1) and is_list(set2) do
    set1 |> MapSet.intersection(ids_from_postings(set2, :and))
  end

  # find docs containing any of the terms: OR boolean query
  # sets union
  defp ids_from_postings([set1, set2], :or) when is_map(set1) and is_map(set2) do
    MapSet.union(set1, set2)
  end

  # > 3 terms, OR boolean
  defp ids_from_postings([set1 | set2], :or) when is_map(set1) and is_list(set2) do
    set1 |> MapSet.union(ids_from_postings(set2, :or))
  end

  @doc """
  Construct Term-Document-Matrix (TDM) for a given list of documents and terms.
  """
  @spec tdm(list(binary), term_idfs, list(binary), corpus) :: term_document_matrix
  def tdm(doc_ids, idfs, terms, corpus) do
    for doc_id <- doc_ids, into: %{} do
      {doc_id, tfidf_vector(terms, doc_id, idfs, corpus, [])}
    end
  end

  @doc """
  Calculate inverse document frequency (IDF) for a given list of terms, index and corpus.

  Returns IDF value per term in a map.

  ```
    %{
      "eyck" => 0.5596157879354227,
      "northern" => 0.3364722366212129,
      "renaissance" => 0.3364722366212129,
      "van" => 0.5596157879354227
    }
  ```
  """
  @spec idf(list(binary), index, corpus) :: term_idfs
  def idf(terms, index, corpus) do
    total_docs = Map.size corpus

    for term <- terms, index[term] != nil, into: %{} do
      df = index[term] |> MapSet.size
      idf = :math.log(total_docs / (1 + df))
      {term, idf}
    end

  end

  @doc """
  Construct term frequency inverse document frequency (tf-idf) terms vector (List) for a given document and terms.
  """
  @spec tfidf_vector(list(binary), binary, term_idfs, corpus, list(number)) :: list(number)
  def tfidf_vector(terms, doc_id, idfs, corpus, vector)
  def tfidf_vector([], _doc_id, _idfs, _corpus, vector), do: vector
  def tfidf_vector([term|terms], doc_id, idfs, corpus, vector) do
    doc = corpus[doc_id]
    tokens = analyse(doc.title <> " " <> doc.description)

    tf = Enum.count(tokens, fn x -> x == term end)
    idf = idfs[term]

    td_idf = if tf == 0, do: 0, else: tf * idf
    updated_vector = vector ++ [td_idf]

    tfidf_vector(terms, doc_id, idfs, corpus, updated_vector)
  end

end
