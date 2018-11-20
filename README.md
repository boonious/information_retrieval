# IR [![Build Status](https://travis-ci.org/boonious/information_retrieval.svg?branch=master)](https://travis-ci.org/boonious/information_retrieval) [![Coverage Status](https://coveralls.io/repos/github/boonious/information_retrieval/badge.svg?branch=master)](https://coveralls.io/github/boonious/information_retrieval?branch=master)

IR is an exercise in information retrieval, in-memory indexing and full-text searching.

The [Elixir-based](https://elixir-lang.org) application can be invoked 
in the following ways:

### Interactive Elixir

```elixir
  instructions forthcoming
```

### Command line interface

```elixir
  instructions forthcoming
```

## Requirement
This application requires [Erlang](http://erlang.org/doc/installation_guide/INSTALL.html).
To compile and build the application, [Elixir](https://elixir-lang.org) is required.
You can install Elixir on OS X via Homebrew with:

```bash
  brew install elixir
```

The above install both Elixr and Erlang.
For other OSes, check the [installation instructions](http://elixir-lang.org/install.html) on elixir-lang.org.

## CSV data

The application assumes test data to be supplied in a CSV file - `data.csv`, in the root directory.
It currently uses the `title` and `description` values which are specified with headers in the file.

The default filename and path can be customised in the application configuration:

```elixir
  config :ir,
    data_filepath: "another_path/another_filename.csv"
```

## Documentation

API documentation can be generated with the following command:

```bash
  ...$ mix docs
  Docs successfully generated.
  View them at "doc/index.html".
```



