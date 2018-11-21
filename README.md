# IR [![Build Status](https://travis-ci.org/boonious/information_retrieval.svg?branch=master)](https://travis-ci.org/boonious/information_retrieval) [![Coverage Status](https://coveralls.io/repos/github/boonious/information_retrieval/badge.svg?branch=master)](https://coveralls.io/github/boonious/information_retrieval?branch=master)

IR is an [Elixir-based](https://elixir-lang.org) exercise in information retrieval, in-memory indexing and full-text searching of CSV dataset.

### Usage - Interactive Elixir (IEx)

The application can be invoked interactively through
[IEx](https://elixir-lang.org/getting-started/introduction.html#interactive-mode).


```bash
  # from application home directory,
  # start IEx with the application running
  # this will also compile the application if it hasn't been compiled
  ...$ iex -S mix
    
  # or start IEx with shell history
  ..$ iex --erl "-kernel shell_history enabled" -S mix

```

Dataset parsing and indexing:

```elixir
  # build an in-memory corpus for the entire dataset
  iex> {:ok, corpus} = IR.parse(:all)

  # corpus of specific number of documents
  iex> {:ok, corpus} = IR.parse(2)

  # build an in-memory index for the entire dataset
  iex> {:ok, index} = IR.indexing(:all)
  
  # index specific number of documents
  iex> {:ok, index} = IR.indexing(500)
  ... # %{ "term" => "postings"..}

  # indexing and build text corpus
  iex> {:ok, index, corpus} = IR.indexing(5000, corpus: true)
  ...


```

The generated corpus and index can be used in search queries.

For quick tests, the application's search function - `IR.q`
will automatically generate
a corpus and index of 1000 (max) docs from the
CSV dataset if pre-created index / corpus are not supplied.
The query will be issued on this small index.

Doc ids and scores are currently being returned as results.

```elixir
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
  # ( > 1000 docs), it'll take awhile for a large dataset
  iex> {:ok, index, corpus} = IR.indexing(:all, corpus: true)

  # use the index / corpus in search
  iex> IR.q "renaissance", index: index, corpus: corpus

  # re-use the corpus / index for another search
  # without waiting for indexing
  iex> IR.q "van eyck", index: index, corpus: corpus, op: :and


```

Ranking and sorting of results can be toggled with the `:sort` option.

```elixir
  iex> IR.q "christopher columbus carlo eyck galileo galilei", sort: false
  Indexing..
  Found 5 results.
  [{1, 1.25276}, {4, 0.55962}, {5, 0.55962}, {6, 0.55962}, {7, 5.01105}]

  # ranking with relevancy
  iex(6)> IR.q "christopher columbus carlo eyck galileo galilei", sort: true
  Indexing..
  Found 5 results.
  [{7, 5.01105}, {1, 1.25276}, {4, 0.55962}, {5, 0.55962}, {6, 0.55962}]


```

## CSV data

A dataset can be supplied in a CSV file named `data.csv`, in the application
home directory. It currently imports `title` and `description` columns
which should be specified with such headers in the file.
Existing data from other columns will not be parsed.

The default dataset filename and path can be configured in
`config/config.exs`:

```elixir
  config :ir,
    data_filepath: "another_path/another_filename.csv"
```

## Requirement
This application is based on [Erlang](http://erlang.org/doc/installation_guide/INSTALL.html).
To compile and build the application, [Elixir](https://elixir-lang.org) is required.
You can install Elixir on OS X via Homebrew with:

```bash
  brew install elixir
```

The above installs both Elixr and Erlang.
For other OSes, check the [installation instructions](http://elixir-lang.org/install.html) on elixir-lang.org.

To compile the application, run the following from the application home directory:

```elixir
  ...$ mix deps.get; mix compile
```

## Documentation

API documentation can be generated with the following command:

```bash
  ...$ mix docs
  Docs successfully generated.
  View them at "doc/index.html".
```



