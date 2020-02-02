defmodule DlexTest.Ball do
  use Dlex.Node
  use Dlex.Changeset

  schema "ball" do
    field :color, :string, index: ["term"]
    relation(:owner, :one, models: [DlexTest.User], reverse: true)
  end

  def changeset(ball, params \\ %{}) do
    ball
    |> cast(params, [:color, :owner])
    |> validate_relation(:owner)
  end
end
