defmodule Dlex.Lang do
  use Dlex.Changeset
  def __schema__(:field, :language),
    do: {:language, :string}

  def __schema__(:field, :value),
    do: {:value, :string}

  @type t :: %__MODULE__{
          value: String.t(),
          language: String.t()
        }

  defstruct [:value, :language]

  def changeset(lang, params \\ %{}) do
    lang
    |> cast(params, [
      :language,
      :value
    ])
    |> validate_required([:language, :value])
  end

  def __changeset__ do
    %{
      value: :string,
      language: :string
    }
  end

  def __schema__(:primary_key), do: [:language]
  def __schema__(:type, :value), do: :string
  def __schema__(:type, :language), do: :string
end
