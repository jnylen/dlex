defmodule DlexTest.RepoTest do
  use ExUnit.Case

  alias DlexTest.{Helper, Repo, User, Team, Ball, Social}

  setup_all do
    {:ok, pid} = Repo.start_link(Helper.opts())
    %{pid: pid}
  end

  describe "schema operations" do
    setup do
      Repo.register(Ball)
      Repo.register(User)
      Repo.register(Team)
      Repo.register(Social)
      Repo.alter_schema()
      :ok
    end

    test "basic crud operations" do
      user = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: uid}} = Repo.set(user)
      assert uid != nil
      assert {:ok, %User{uid: ^uid, name: "Alice", age: 25}} = Repo.get(uid)
      assert %User{uid: ^uid, name: "Alice", age: 25} = Repo.get!(uid)

      assert {:ok, %{"uid_get" => [%User{uid: ^uid, name: "Alice", age: 25}]}} =
               Repo.all("{uid_get(func: uid(#{uid})) {uid dgraph.type expand(_all_)}}")

      assert {:ok, %{"uid_get" => [%{"uid" => _, "user.age" => 25, "user.name" => "Alice"}]}} =
               Repo.all("{uid_get(func: uid(#{uid})) {uid expand(_all_)}}")
    end

    test "basic crud operations with many relations" do
      user = %User{name: "Mark", age: 23}
      assert {:ok, %User{uid: user_uid} = inserted_user} = Repo.set(user)

      team = %Team{name: "Mark", members: [inserted_user]}

      assert {:ok, %Team{uid: team_uid}} = Repo.set(team)
      assert team_uid != nil

      assert {:ok, %Team{uid: ^team_uid, name: "Mark", members: [^inserted_user]}} =
               Repo.get(team_uid)
    end

    test "basic crud operations with one relation" do
      owner = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: _} = owner} = Repo.set(owner)

      ball = %Ball{color: "Red", owner: owner}
      assert {:ok, %Ball{uid: ball_uid}} = Repo.set(ball)

      assert {:ok, %Ball{color: "Red", owner: ^owner, uid: ^ball_uid}} = Repo.get(ball_uid)
    end

    test "basic crud operations with one shared predicate" do
      user = %User{name: "Alice", age: 25, facebook_id: "facebookerino"}
      assert {:ok, %User{uid: uid} = user} = Repo.set(user)

      assert {:ok,
              %DlexTest.User{
                age: 25,
                facebook_id: "facebookerino",
                name: "Alice",
                uid: uid
              }} == Repo.get(uid)
    end
  end

  describe "in a struct" do
    setup do
      Helper.drop_all(Repo)

      Repo.register(Ball)
      Repo.register(User)
      Repo.register(Team)

      Repo.alter_schema()

      :ok
    end

    test "does a changeset return valid with a relation?" do
      owner = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: _} = owner} = Repo.set(owner)

      assert [] == Ball.changeset(%Ball{}, %{color: "Red", owner: owner}).errors
    end

    test "does a changeset return invalid with a relation?" do
      team = %Team{name: "Mark"}
      assert {:ok, %Team{uid: team_uid}} = Repo.set(team)

      assert [owner: {"not in one of the allowed models", []}] ==
               Ball.changeset(%Ball{}, %{color: "Red", owner: team}).errors
    end

    test "does a changeset return invalid with a relation in a many one?" do
      owner = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: _} = owner} = Repo.set(owner)

      assert [members: {"is invalid", [type: {:array, :map}, validation: :cast]}] ==
               Team.changeset(%Team{}, %{name: "Louise", members: owner}).errors
    end

    test "does a changeset return valid with multiple relations?" do
      owner = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: _} = owner} = Repo.set(owner)

      assert [] ==
               Team.changeset(%Team{}, %{name: "Louise", members: [owner, owner, owner, owner]}).errors
    end

    test "does a changeset return invalid with multiple relations and one single invalid one?" do
      owner = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: _} = owner} = Repo.set(owner)

      team = %Team{name: "Mark"}
      assert {:ok, %Team{uid: team_uid} = team2} = Repo.set(team)

      assert [members: {"not in one of the allowed models", []}] ==
               Team.changeset(%Team{}, %{name: "Louise", members: [owner, owner, team2, owner]}).errors
    end

    test "does a reverse relation on team match the added relations?" do
      owner = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: user_uid} = owner} = Repo.set(owner)

      team = %Team{name: "Mark", members: [owner]}
      assert {:ok, %Team{uid: team_uid} = team2} = Repo.set(team)

      assert team = Repo.get(team_uid)

      assert owner = Repo.get(user_uid)
    end

    test "does a changeset convert lang-tagged fields?" do
      team = %Team{name: "hello there", text: [%Dlex.Lang{value: "text here", language: "en"}]}
      assert {:ok, %Team{uid: team_uid} = team2} = Repo.set(team)

      assert team_uid != nil
      assert {:ok, %Team{uid: ^team_uid} = team3} = Repo.get(team_uid)

      assert team2 == team3
    end
  end
end
