defmodule DlexTest.NodeTest do
  use ExUnit.Case

  alias DlexTest.{Ball, User, Team}

  describe "schema generation" do
    test "basic" do
      assert "user" == User.__schema__(:source)
      assert :string == User.__schema__(:type, :name)
      assert :integer == User.__schema__(:type, :age)
      assert [:name, :age, :friends, :facebook_id, :member_of] == User.__schema__(:fields)
    end

    test "alter" do
      assert %{
               "schema" => [
                 %{
                   "index" => true,
                   "predicate" => "user.name",
                   "tokenizer" => ["term"],
                   "type" => "string"
                 },
                 %{"predicate" => "user.age", "type" => "int"},
                 %{"predicate" => "user.friends", "type" => "uid"}
               ],
               "types" => [
                 %{
                   "fields" => [
                     %{"name" => "~team.members", "type" => "reverse_relation"},
                     %{"name" => "social.facebook_id", "type" => "string"},
                     %{"name" => "user.friends", "type" => "uid"},
                     %{"name" => "user.age", "type" => "integer"},
                     %{"name" => "user.name", "type" => "string"}
                   ],
                   "name" => "user"
                 }
               ]
             } == User.__schema__(:alter)
    end

    test "transformation callbacks" do
      assert "user.name" == User.__schema__(:field, :name)
      assert {:name, :string} == User.__schema__(:field, "user.name")
    end
  end

  describe "does a changeset work" do
    test "and is a simple changeset valid?" do
      assert [] == Ball.changeset(%Ball{}, %{color: "Red"}).errors
    end

    test "and is the type changeset checked?" do
      assert [{:color, {"is invalid", [type: :string, validation: :cast]}}] ==
               Ball.changeset(%Ball{}, %{color: 12}).errors
    end

    test "with lang-tagged field?" do
      assert [] ==
               Team.changeset(%Team{}, %{
                 text: [%Dlex.Lang{value: "text here", language: "en"}]
               }).errors
    end
  end
end
