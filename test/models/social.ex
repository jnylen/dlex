defmodule DlexTest.Social do
  use Dlex.Node
  use Dlex.Changeset

  shared "social" do
    field :facebook_id, :string, index: ["term"]
  end
end
