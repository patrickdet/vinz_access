defmodule Vinz.Access do
  require Ecto.Query

  alias Ecto.Query, as: Q

  alias Vinz.Access.Repo
  alias Vinz.Access.Domains
  alias Vinz.Access.Models.GroupMember
  alias Vinz.Access.Models.Right

  @modes [ :create, :read, :update, :delete ]

  def check!(repo, user_id, resource, mode) when mode in @modes do
    unless can_access?(repo, user_id, resource, mode), do: throw :unauthorized
    true
  end

  def check(repo, user_id, resource, mode) when mode in @modes do
    can_access?(repo, user_id, resource, mode)
  end

  def permit(repo, user_id, resource, mode, action) when mode in @modes and is_function(action, 0) do
    if check(repo, user_id, resource, mode) do
      action.()
    else
      { :error, :unauthorized }
    end
  end

  def permit(repo, user_id, resource, mode, action) when mode in @modes and is_function(action, 1) do
    domain = Domains.get(repo, user_id, resource, mode)
    if check(repo, user_id, resource, mode) || domain do
      action.(domain)
    else
      { :error, :unauthorized }
    end
  end

  def can_create?(repo, user_id, resource), do: can_access?(repo, user_id, resource, :create)
  def can_read?(repo, user_id, resource), do: can_access?(repo, user_id, resource, :read)
  def can_update?(repo, user_id, resource), do: can_access?(repo, user_id, resource, :update)
  def can_delete?(repo, user_id, resource), do: can_access?(repo, user_id, resource, :delete)

  def can_access?(repo, user_id, resource, mode) when mode in @modes do
    user_group_ids = Q.from(m in GroupMember, select: m.vinz_access_group_id)
      |> Q.where([m], m.vinz_access_user_id == ^user_id)
      |> repo.all

    if Enum.count(user_group_ids) > 0 do
      access = Q.from(r in Right)
        |> Q.where([r], r.global or (r.vinz_access_group_id in ^user_group_ids))
        |> Q.where([r], r.resource == ^resource)
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
