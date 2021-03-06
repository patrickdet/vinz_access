defmodule Vinz.Access.Load do
  alias Vinz.Access.Models.Group
  alias Vinz.Access.Models.Right

  def load_string(string) when is_binary(string) do
    Code.eval_string(string, [], [ delegate_locals_to: __MODULE__ ])
  end

  def group(repo, name, comment) do
    Group.Entity[name: name, comment: comment] |> repo.insert
  end

  def right(repo, name, resource, modes) do
    create? = :create in modes
    read?   = :read in modes
    update? = :update in modes
    delete? = :delete in modes
    Right.Entity[name: name, resource: resource, domain: nil, global: true,
      can_create: create?, can_read: read?, can_update: update?, can_delete: delete? ]
    |> repo.insert
  end

  def right(repo, name, resource, group_name, modes) do
    group_id = group_id!(repo, group_name)
    create? = :create in modes
    read?   = :read in modes
    update? = :update in modes
    delete? = :delete in modes
    Right.Entity[name: name, resource: resource, domain: nil, global: false, vinz_access_group_id: group_id,
      can_create: create?, can_read: read?, can_update: update?, can_delete: delete? ]
    |> repo.insert
  end

  def filter(repo, name, resource, domain, modes) do
    create? = :create in modes
    read?   = :read in modes
    update? = :update in modes
    delete? = :delete in modes
    Right.Entity[name: name, resource: resource, global: true, domain: domain,
      can_create: create?, can_read: read?, can_update: update?, can_delete: delete? ]
    |> repo.insert
  end

  def filter(repo, name, resource, group_name, domain, modes) do
    group_id = group_id!(repo, group_name)
    create? = :create in modes
    read?   = :read in modes
    update? = :update in modes
    delete? = :delete in modes
    Right.Entity[name: name, resource: resource, global: false, vinz_access_group_id: group_id, domain: domain,
      can_create: create?, can_read: read?, can_update: update?, can_delete: delete? ]
    |> repo.insert
  end

  defp group_id!(repo, name) do
    group = Process.get({ :group, name })
    unless group do
      group = repo.all(Group.by_name(name)) |> List.first
      unless group, do: raise "Group #{name} was not found"
      Process.put({ :group, name }, group)
    end
    group.id
  end
end
