{:ok, _} = Application.ensure_all_started(:grpc)
ExUnit.start()

defmodule DlexTest.Helper do
  @dlex_adapter :"#{System.get_env("DLEX_ADAPTER", "grpc")}"
  @offset String.to_integer(System.get_env("DLEX_PORT_OFFSET", "0"))

  def opts() do
    case @dlex_adapter do
      :http -> [transport: :http, port: 8080 + @offset]
      :grpc -> [transport: :grpc, port: 9080 + @offset]
    end
  end

  def drop_all(pid) do
    Dlex.alter(pid, %{drop_all: true})
  end
end
