defmodule Vinz.Access.Domains do
  require Ecto.Query

  alias Ecto.Query, as: Q
  alias Vinz.Access.Models.Right
  alias Vinz.Access.Models.GroupMember

  def get(repo, principal_id, resource, mode \\ :read) do
    base_domain_query = Q.from(r in Right, select: r.domain)
      |> Q.where([r], r.resource == ^resource)
      |> Q.where([r], r.domain != nil)
      |> filter_on_mode(mode)

    global_domains = Q.where(base_domain_query, [r], r.global)
      |> repo.all
      |> join

    user_group_ids = Q.from(m in GroupMember, select: m.vinz_access_group_id)
      |> Q.where([m], m.vinz_access_principal_id == ^principal_id)
      |> repo.all

    group_domains =
      if Enum.count(user_group_ids) > 0 do
        Q.where(base_domain_query, [r], r.vinz_access_group_id in ^user_group_ids)
          |> repo.all
          |> join("or")
      else
        ""
      end

    join([global_domains, group_domains])
  end

  def filter_on_mode(query, :create) do
    Q.where(query, [rule], rule.can_create)
  end
  def filter_on_mode(query, :read) do
    Q.where(query, [rule], rule.can_read)
  end
  def filter_on_mode(query, :update) do
    Q.where(query, [rule], rule.can_update)
  end
  def filter_on_mode(query, :delete) do
    Q.where(query, [rule], rule.can_delete)
  end


  def join(domains, op \\ "and") do
    domains |> Enum.filter(&(String.length(&1) > 0)) |> wrap |> Enum.join(" #{op} ")
  end

  def wrap(domains) do
    case domains do
      [domain] -> [domain]
      domains  -> Enum.map(domains, &("(" <> &1 <> ")"))
    end
  end
end
