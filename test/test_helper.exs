{:ok, _} = Application.ensure_all_started(:grpc)
ExUnit.start()

defmodule DlexTest.Helper do
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
