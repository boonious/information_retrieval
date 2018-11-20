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

  @doc """
  Build a corpus by parsing CSV dataset or subset.

  The function automatically assigns ids (starting from 1).

  ### Example

  ```
    # parse the entire dataset (stream)
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
  @spec parse(integer | :all) :: {:ok, list(map)}
  def parse(num_of_docs) when is_number(num_of_docs) do
    data_filepath = Application.get_env :ir, :data_filepath

    corpus = File.stream!(data_filepath)
      |> CSV.decode!(headers: true)
      |> Enum.take(num_of_docs)
      |> Enum.with_index(1)
      |> Enum.into(%{}, fn {doc, i} -> parse(doc, i) end)
    {:ok, corpus}
  end

  def parse(:all) do
    data_filepath = Application.get_env :ir, :data_filepath

    corpus = File.stream!(data_filepath)
      |> CSV.decode!(headers: true)
      |> Stream.with_index(1)
      |> Enum.into(%{}, fn {doc, i} -> parse(doc, i) end)
    {:ok, corpus}
  end

  @doc false
  def parse(doc, id) do
    {id, %IR.Doc{ :title => doc["title"], :description => doc["description"]}}
  end
end
