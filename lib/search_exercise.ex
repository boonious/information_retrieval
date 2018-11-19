defmodule IR do
  @moduledoc """
  Documentation for IR.
  """

  @doc """
  Parsing CSV dataset or subset specifed by number of lines into a list of (hash) maps.
  """
  @spec parse(integer) :: list(map)
  def parse(num_of_docs) when is_number(num_of_docs) do
    File.stream!("data.csv")
      |> CSV.decode!(headers: true)
      |> Enum.take(num_of_docs)
  end

end
