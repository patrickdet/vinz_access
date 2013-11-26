defmodule Vinz.Access do
  require Ecto.Query

  alias Ecto.Query, as: Q

  alias Vinz.Access.Domains
  alias Vinz.Access.Models.GroupMember
  alias Vinz.Access.Models.Right

  @modes [ :create, :read, :update, :delete ]

  def check!(repo, principal_id, resource, mode) when mode in @modes do
    unless can_access?(repo, principal_id, resource, mode), do: throw :unauthorized
    true
  end

  def check(repo, principal_id, resource, mode) when mode in @modes do
    can_access?(repo, principal_id, resource, mode)
  end

  def permit(repo, principal_id, resource, mode, action) when mode in @modes and is_function(action, 0) do
    if check(repo, principal_id, resource, mode) do
      action.()
    else
      { :error, :unauthorized }
    end
  end

  def permit(repo, principal_id, resource, mode, action) when mode in @modes and is_function(action, 1) do
    domain = Domains.get(repo, principal_id, resource, mode)
    if check(repo, principal_id, resource, mode) || domain do
      action.(domain)
    else
      { :error, :unauthorized }
    end
  end

  def can_create?(repo, principal_id, resource), do: can_access?(repo, principal_id, resource, :create)
  def can_read?(repo, principal_id, resource), do: can_access?(repo, principal_id, resource, :read)
  def can_update?(repo, principal_id, resource), do: can_access?(repo, principal_id, resource, :update)
  def can_delete?(repo, principal_id, resource), do: can_access?(repo, principal_id, resource, :delete)

  def can_access?(repo, principal_id, resource, mode) when mode in @modes do
    user_group_ids = Q.from(m in GroupMember, select: m.vinz_access_group_id)
      |> Q.where([m], m.vinz_access_principal_id == ^principal_id)
      |> repo.all

    if Enum.count(user_group_ids) > 0 do
      access = Q.from(r in Right)
        |> Q.where([r], r.global or (r.vinz_access_group_id in ^user_group_ids))
        |> Q.where([r], r.resource == ^resource)
        |> Q.where([r], r.domain == nil)
        |> select(mode)
        |> repo.all
        |> Enum.first

      !!access
    else
      false
    end
  end

  defp select(query, :create), do: Q.select(query, [r], bool_or(r.can_create))
  defp select(query, :read),   do: Q.select(query, [r], bool_or(r.can_read))
  defp select(query, :update), do: Q.select(query, [r], bool_or(r.can_update))
  defp select(query, :delete), do: Q.select(query, [r], bool_or(r.can_delete))
end
