defmodule Vinz.Domain.Test do
  use Vinz.Access.TestCase

  alias Vinz.Access.Test.Repo

  alias Vinz.Access.Domains
  alias Vinz.Access.Models.Right
  alias Vinz.Access.Models.Principal
  alias Vinz.Access.Models.Group
  alias Vinz.Access.Models.GroupMember

  setup_all do
    begin
    resource = "domain-test-resource"
    p = Principal.new(name: "domain-test") |> Repo.insert
    g = Group.new(name: "domain-test", description: "a group to test user domains") |> Repo.insert
    m = GroupMember.new(vinz_access_group_id: g.id, vinz_access_principal_id: p.id) |> Repo.insert
    [
      Right.new(name: "global-test-filter", resource: resource, global: true, domain: "G", can_read: true),
      Right.new(name: "group-specific-filter-read", resource: resource, global: false, vinz_access_group_id: g.id, domain: "GSR", can_read: true),
      Right.new(name: "group-specific-filter-write-u", resource: resource, global: false, vinz_access_group_id: g.id, domain: "U", can_update: true),
      Right.new(name: "group-specific-filter-write-c", resource: resource, global: false, vinz_access_group_id: g.id, domain: "C", can_create: true),
      Right.new(name: "group-specific-filter-write-d", resource: resource, global: false, vinz_access_group_id: g.id, domain: "D", can_delete: true)
    ] |> Enum.each &Repo.insert/1

    { :ok, [ principal: p, group: g, group_member: m, resource: resource ] }
  end

  teardown_all do: rollback

  test :join_domains do
    import Domains, only: [ join: 1, join: 2 ]

    assert "" == join([])
    assert "a" == join(~w(a))
    assert "(a) and (b)" == join(~w(a b))
    assert "(a) and ((b) or (c))" == join([join(~w(a)), join(~w(b c), "or")])
  end

  test :getting_user_domains, context do
    principal = Keyword.get(context, :principal)
    resource = Keyword.get(context, :resource)
    assert "(G) and (GSR)" == Domains.get(Repo, principal.id, resource)
    assert "U" == Domains.get(Repo, principal.id, resource, :update)
    assert "C" == Domains.get(Repo, principal.id, resource, :create)
    assert "D" == Domains.get(Repo, principal.id, resource, :delete)
    # user with no groups...
    assert "G" == Domains.get(Repo, 0, resource, :read)
  end
end
