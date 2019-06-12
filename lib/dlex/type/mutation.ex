defmodule Dlex.Type.Mutation do
  @moduledoc false

  alias Dlex.{Query, Utils}
  alias Dlex.Api.{Assigned, Mutation}
  alias Dlex.Api.Dgraph.Stub, as: ApiStub

  @behaviour Dlex.Type

  @impl true
  def execute(channel, request, opts), do: ApiStub.mutate(channel, request, opts)

  @impl true
  def describe(%Query{statement: statement} = query, opts) do
    statement = if opts[:return_json], do: Utils.add_blank_ids(statement), else: statement
    %Query{query | statement: statement}
  end

  @impl true
  def encode(%{json: json} = query, _parameters, _opts) do
    %Query{sub_type: sub_type, statement: statement, txn_context: txn} = query
    {commit, start_ts} = transaction_opts(txn)
    mutation_type = infer_type(statement)
    statement = format(mutation_type, statement, json)
    mutation_key = mutation_key(mutation_type, sub_type)
    mutation = [{mutation_key, statement} | [start_ts: start_ts, commit_now: commit]]
    Mutation.new(mutation)
  end

  defp transaction_opts(%{start_ts: start_ts}), do: {false, start_ts}
  defp transaction_opts(nil), do: {true, 0}

  defp infer_type(%{}), do: :json
  defp infer_type([%{} | _]), do: :json
  defp infer_type(_), do: :nquads

  defp format(:nquads, statement, _), do: statement
  defp format(:json, statement, json_lib), do: json_lib.encode!(statement)

  defp mutation_key(:json, nil), do: :set_json
  defp mutation_key(:nquads, nil), do: :set_nquads
  defp mutation_key(:json, :deletion), do: :delete_json
  defp mutation_key(:nquads, :deletion), do: :del_nquads

  @impl true
  def decode(%Query{statement: statement} = _query, %Assigned{uids: uids} = _result, opts) do
    if opts[:return_json], do: Utils.replace_ids(statement, uids), else: uids
  end
end