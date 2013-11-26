defmodule Vinz.Access.LoadTest do
  use Vinz.Access.TestCase

  import Vinz.Access.Load

  alias Vinz.Access.Test.Repo

  setup do
    begin
    group_name = "test group"
    group(Vinz.Access.Test.Repo, group_name, "group for testing the load module")
    { :ok, [ group_name: group_name ]}
  end
  teardown do: rollback

  test :load_existing_group, ctx do
    assert_raise Postgrex.Error, fn ->
      group(Vinz.Access.Test.Repo, group_name(ctx), "this should raise an error")
    end
  end

  test :load_existing_right, ctx do
    name = "test right"
    right(Repo, name, "resource", group_name(ctx), [:read, :update])
    assert_raise Postgrex.Error, fn ->
      right(Repo, name, "resource", group_name(ctx), [:create, :delete])
    end
  end

  defp group_name(ctx), do: ctx[:group_name]
end