defmodule DlexTest.Team do
  use Dlex.Node
  use Dlex.Changeset

  schema "team" do
    field :name, :string, index: ["term"]
    field :text, :string, lang: true
    relation(:members, :many, models: [DlexTest.User], reverse: true)
  end

  def changeset(team, params \\ %{}) do
    team
    |> cast(params, [:name, :members, :text])
    |> validate_relation(:members)
  end
end
