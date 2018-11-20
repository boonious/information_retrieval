defmodule IR.MixProject do
  use Mix.Project

  @description """
  An exercise in information retrieval, in-memory indexing and full-text searching.
  """

  def project do
    [
      app: :ir,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],

      # Docs
      name: "information_retrieval",
      description: @description,
      source_url: "https://github.com/boonious/information_retrieval",
      homepage_url: "https://github.com/boonious/information_retrieval",
      docs: [
        main: "IR",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:csv, "~> 2.0.0"},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
