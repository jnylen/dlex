defmodule Dlex.Lang do
  def __schema__(:field, :language),
    do: {:language, :string}

  def __schema__(:field, :value),
    do: {:value, :string}

  @type t :: %__MODULE__{
          value: String.t(),
          language: String.t()
        }

  defstruct [:value, :language]
end
