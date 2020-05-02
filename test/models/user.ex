defmodule DlexTest.User do
  use Dlex.Node
  use Dlex.Changeset

  schema "user" do
    field :name, :string, index: ["term"]
    field :age, :integer
    field :friends, :uid
    field :cache, :any, virtual: true
    field :facebook_id, :string, depends_on: DlexTest.Social
    relation(:member_of, :reverse, model: DlexTest.Team, name: :members)
  end
end
