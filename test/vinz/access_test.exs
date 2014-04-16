defmodule Vinz.Access.Test do
  use Vinz.Access.TestCase

  import Vinz.Access, only: [ can_create?: 3, can_read?: 3, can_update?: 3, can_delete?: 3, check!: 4, permit: 5 ]

  alias Vinz.Access.Test.Repo

  alias Vinz.Access
  alias Vinz.Access.Domains
  alias Vinz.Access.Models.Principal
  alias Vinz.Access.Models.Group
  alias Vinz.Access.Models.GroupMember
  alias Vinz.Access.Models.Right


  setup_all do
    begin
    resource = "access-test-resource"
    principal = Principal.new(name: "test-access") |> Repo.insert
    group = Group.new(name: "access-test", comment: "a group for testing access controll") |> Repo.insert

    [
      GroupMember.new(vinz_access_group_id: group.id, vinz_access_principal_id: principal.id),
      Right.new(name: "test-access-create", resource: resource, global: true, can_create: true),
      Right.new(name: "test-access-read", resource: resource, global: false, vinz_access_group_id: group.id, can_read: true),
      Right.new(name: "test-access-update", resource: resource, global: false, vinz_access_group_id: group.id, can_update: true),
      Right.new(name: "test-access-delete", resource: resource, global: true, can_delete: true),
      Right.new(name: "test-access-group-delete", resource: resource, global: false, vinz_access_group_id: group.id, can_delete: false),
      Right.new(name: "test-access-read-rilter-a", resource: resource, global: false, domain: "a", vinz_access_group_id: group.id, can_read: true),
      Right.new(name: "test-access-read-rilter-b", resource: resource, global: false, domain: "b", vinz_access_group_id: group.id, can_read: true)
    ] |> Enum.each &Repo.insert/1

    { :ok, [ principal: principal, resource: resource ] }
  end

  teardown_all do: rollback

  test :user_access, ctx do
    id = ctx[:principal].id
    resource = ctx[:resource]
    assert can_create? Repo, id, resource
    assert can_read? Repo, id, resource
    assert can_update? Repo, id, resource
    assert can_delete? Repo, id, resource

    refute can_create? Repo, id, "foo"
    refute can_read? Repo, id, "foo"
    refute can_update? Repo, id, "foo"
    refute can_delete? Repo, id, "foo"

    refute can_delete? Repo, 0, resource
  end

  test :check!, ctx do
    id = ctx[:principal].id
    resource = ctx[:resource]

    assert check!(Repo, id, resource, :create)

    try do
      check!(Repo, id, "foo", :create)
      assert false
    catch
      :throw, :unauthorized ->
        assert true
    end
  end

  test :permit, ctx do
    id = ctx[:principal].id
    resource = ctx[:resource]

    assert permit(Repo, id, resource, :delete, fn -> true end)
    { :error, :unauthorized } = permit(Repo, id, "no-resource", :read, fn -> true end)
    domain = Domains.get(Repo, id, resource, :read)
    ^domain = permit(Repo, id, resource, :read, fn(d) -> d end)
  end

  test :load do
    { resp, [] } = Access.Load.load_string(~S([
      group(Vinz.Access.Test.Repo, "test load group", "just a group to test loading"),
      right(Vinz.Access.Test.Repo, "global rights to load resource", "load", [ :read, :create ]),
      right(Vinz.Access.Test.Repo, "test load group rights to load resource", "load", "test load group", [ :create, :read, :update, :delete ]),
      filter(Vinz.Access.Test.Repo, "global filter to load resource", "load", "a == b", [ :create, :read ]),
      filter(Vinz.Access.Test.Repo, "test load group filter to load resource", "load", "test load group", "a == b", [ :delete, :update ])
    ]))
    group = List.first(resp)
    group_id = group.id
    [
      Group.Entity[],
      Right.Entity[id: _, name: "global rights to load resource", resource: "load", global: true, can_read: true, can_create: true, can_delete: false, can_update: false ],
      Right.Entity[id: _, name: "test load group rights to load resource", resource: "load", global: false, vinz_access_group_id: ^group_id, can_read: true, can_create: true, can_delete: true, can_update: true ],
      Right.Entity[id: _, name: "global filter to load resource", resource: "load", global: true, domain: "a == b", can_create: true, can_read: true, can_update: false, can_delete: false ],
      Right.Entity[id: _, name: "test load group filter to load resource", resource: "load", global: false, vinz_access_group_id: ^group_id, domain: "a == b", can_create: false, can_read: false, can_delete: true, can_update: true ]
    ] = resp
  end
end
