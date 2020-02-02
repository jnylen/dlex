defmodule Dlex.RepoTest do
  use ExUnit.Case

  alias Dlex.{TestHelper, TestRepo, User, Team, Ball, Social}

  setup_all do
    {:ok, pid} = TestRepo.start_link(TestHelper.opts())
    %{pid: pid}
  end

  describe "schema operations" do
    setup do
      TestRepo.register(Ball)
      TestRepo.register(User)
      TestRepo.register(Team)
      TestRepo.register(Social)
      TestRepo.alter_schema()
      :ok
    end

    test "basic crud operations" do
      user = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: uid}} = TestRepo.set(user)
      assert uid != nil
      assert {:ok, %User{uid: ^uid, name: "Alice", age: 25}} = TestRepo.get(uid)
      assert %User{uid: ^uid, name: "Alice", age: 25} = TestRepo.get!(uid)

      assert {:ok, %{"uid_get" => [%User{uid: ^uid, name: "Alice", age: 25}]}} =
               TestRepo.all("{uid_get(func: uid(#{uid})) {uid dgraph.type expand(_all_)}}")

      assert {:ok, %{"uid_get" => [%{"uid" => _, "user.age" => 25, "user.name" => "Alice"}]}} =
               TestRepo.all("{uid_get(func: uid(#{uid})) {uid expand(_all_)}}")
    end

    test "basic crud operations with many relations" do
      user = %User{name: "Mark", age: 23}
      assert {:ok, %User{uid: user_uid} = inserted_user} = TestRepo.set(user)

      team = %Team{name: "Mark", members: [inserted_user]}

      assert {:ok, %Team{uid: team_uid}} = TestRepo.set(team)
      assert team_uid != nil

      assert {:ok, %Team{uid: ^team_uid, name: "Mark", members: [^inserted_user]}} =
               TestRepo.get(team_uid)
    end

    test "basic crud operations with one relation" do
      owner = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: _} = owner} = TestRepo.set(owner)

      ball = %Ball{color: "Red", owner: owner}
      assert {:ok, %Ball{uid: ball_uid}} = TestRepo.set(ball)

      assert {:ok, %Ball{color: "Red", owner: ^owner, uid: ^ball_uid}} = TestRepo.get(ball_uid)
    end
  end

  describe "in a struct" do
    setup do
      Dlex.TestHelper.drop_all(Dlex.TestRepo)

      TestRepo.register(Ball)
      TestRepo.register(User)
      TestRepo.register(Team)

      TestRepo.alter_schema()

      :ok
    end

    test "does a changeset return valid with a relation?" do
      owner = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: _} = owner} = TestRepo.set(owner)

      assert [] == Ball.changeset(%Ball{}, %{color: "Red", owner: owner}).errors
    end

    test "does a changeset return invalid with a relation?" do
      team = %Team{name: "Mark"}
      assert {:ok, %Team{uid: team_uid}} = TestRepo.set(team)

      assert [owner: {"not in one of the allowed models", []}] ==
               Ball.changeset(%Ball{}, %{color: "Red", owner: team}).errors
    end

    test "does a changeset return invalid with a relation in a many one?" do
      owner = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: _} = owner} = TestRepo.set(owner)

      assert [members: {"is invalid", [type: {:array, :map}, validation: :cast]}] ==
               Team.changeset(%Team{}, %{name: "Louise", members: owner}).errors
    end

    test "does a changeset return valid with multiple relations?" do
      owner = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: _} = owner} = TestRepo.set(owner)

      assert [] ==
               Team.changeset(%Team{}, %{name: "Louise", members: [owner, owner, owner, owner]}).errors
    end

    test "does a changeset return invalid with multiple relations and one single invalid one?" do
      owner = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: _} = owner} = TestRepo.set(owner)

      team = %Team{name: "Mark"}
      assert {:ok, %Team{uid: team_uid} = team2} = TestRepo.set(team)

      assert [members: {"not in one of the allowed models", []}] ==
               Team.changeset(%Team{}, %{name: "Louise", members: [owner, owner, team2, owner]}).errors
    end

    test "does a reverse relation on team match the added relations?" do
      owner = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: user_uid} = owner} = TestRepo.set(owner)

      team = %Team{name: "Mark", members: [owner]}
      assert {:ok, %Team{uid: team_uid} = team2} = TestRepo.set(team)

      assert team = TestRepo.get(team_uid)

      assert owner = TestRepo.get(user_uid)
    end

    test "does a changeset convert lang-tagged fields?" do
      team = %Team{name: "hello there", text: [%Dlex.Lang{value: "text here", language: "en"}]}
      assert {:ok, %Team{uid: team_uid} = team2} = TestRepo.set(team)

      assert team_uid != nil
      assert {:ok, %Team{uid: ^team_uid} = team3} = TestRepo.get(team_uid)

      assert team2 == team3
    end
  end
end
