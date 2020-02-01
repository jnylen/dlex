{:ok, _} = Application.ensure_all_started(:grpc)
ExUnit.start()

defmodule Dlex.User do
  use Dlex.Node
  use Dlex.Changeset

  schema "user" do
    field :name, :string, index: ["term"]
    field :age, :integer
    field :friends, :uid
    field :cache, :any, virtual: true
  end
end

defmodule Dlex.Team do
  use Dlex.Node
  use Dlex.Changeset

  schema "team" do
    field :name, :string, index: ["term"]
    field :text, :string, lang: true
    relation(:members, :many, models: [Dlex.User])
  end

  def changeset(team, params \\ %{}) do
    team
    |> cast(params, [:name, :members, :text])
    |> validate_relation(:members)
  end
end

defmodule Dlex.Ball do
  use Dlex.Node
  use Dlex.Changeset

  schema "ball" do
    field :color, :string, index: ["term"]
    relation(:owner, :one, models: [Dlex.User], reverse: true)
  end

  def changeset(ball, params \\ %{}) do
    ball
    |> cast(params, [:color, :owner])
    |> validate_relation(:owner)
  end
end

defmodule Dlex.TestRepo do
  use Dlex.Repo, otp_app: :dlex, modules: [Dlex.User, Dlex.Team, Dlex.Ball]
end

defmodule Dlex.TestHelper do
  @dlex_adapter :"#{System.get_env("DLEX_ADAPTER", "grpc")}"

  def opts() do
    case @dlex_adapter do
      :http -> [transport: :http, port: 8080]
      :grpc -> [transport: :grpc, port: 9080]
    end
  end

  def drop_all(pid) do
    Dlex.alter(pid, %{drop_all: true})
  end
end
