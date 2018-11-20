defmodule IR do
  @moduledoc """
  Documentation for IR.
  """

  @doc """
  Parsing CSV dataset or subset.

  ### Example

  ```
    # entire dataset (stream)
    parse(:all)
    
    # first 5 documents returns in a list of maps
    parse(5)
  ```
  """
  @spec parse(integer | :all) :: list(map) | Stream
  def parse(num_of_docs) when is_number(num_of_docs) do
    File.stream!("data.csv")
      |> CSV.decode!(headers: true)
      |> Enum.take(num_of_docs)
  end

  def parse(:all), do: File.stream!("data.csv") |> CSV.decode!(headers: true)

end
