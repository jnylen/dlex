defmodule Dlex.Changeset do
  @moduledoc """
  This is basically just a proxy to Ecto.Changeset, except it has some dgraph-specific validators.
  """

  defmacro __using__(_) do
    quote do
      import Ecto.Changeset
      import Dlex.Changeset
    end
  end

  def apply_changes(%{changes: changes, data: data}) when changes == %{} do
    data
  end

  def apply_changes(%{changes: _changes, data: _data} = changeset) do
    Ecto.Changeset.apply_changes(changeset)
  end

  def validate_relation(%Ecto.Changeset{data: %{__struct__: struct}} = changeset, field)
      when is_atom(field),
      do: Ecto.Changeset.validate_change(changeset, field, &relation_valid?(&1, &2, struct))

  defp relation_valid?(current_field, list, struct) when is_list(list) do
    models = struct.__schema__(:models, current_field)

    Enum.reduce_while(list, [], fn item, _ ->
      models
      |> relation_valid_value(current_field, item)
      |> case do
        [] -> {:cont, []}
        res -> {:halt, res}
      end
    end)
  end

  defp relation_valid?(current_field, value, struct) when is_map(value) do
    struct.__schema__(:models, current_field)
    |> relation_valid_value(current_field, value)
  end

  defp relation_valid_value(models, current_field, value) when is_map(value) do
    if Enum.member?(models, value |> Map.get(:__struct__)),
      do: [],
      else: [{current_field, "not in one of the allowed models"}]
  end

  defp relation_valid_value(models, current_field, value) when is_binary(value) do
    {:ok, item} = Application.get_env(:dlex, :repo).get(value)

    if Enum.member?(models, item |> Map.get(:__struct__)),
      do: [],
      else: [{current_field, "not in one of the allowed models"}]
  end

  defp relation_valid?(current_field, _, _),
    do: [{current_field, "value needs to be a list of structs or a single struct"}]
end
