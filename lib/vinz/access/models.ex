defmodule Vinz.Access.Models do

defmodule Principal do
  use Ecto.Model

  queryable "vinz_access_principal" do
    field :name, :string
  end

  def hash_password(plaintext) do
    { :ok, hash } = :scrypt.hash(plaintext)
    hash
  end
end


defmodule Group do
  use Ecto.Model
  import Ecto.Query

  queryable "vinz_access_group" do
    field :name, :string
    field :comment, :string
  end

  def by_name(name) do
     from g in __MODULE__,
    where: g.name == ^name
  end
end


defmodule GroupMember do
  use Ecto.Model

  queryable "vinz_access_group_member" do
    field :vinz_access_group_id, :integer
    field :vinz_access_principal_id, :integer
  end
end


defmodule Right do
  use Ecto.Model

  queryable "vinz_access_right" do
    field :name, :string
    field :resource, :string
    field :global, :boolean
    field :domain, :string
    field :vinz_access_group_id, :integer
    field :can_create, :boolean
    field :can_read, :boolean
    field :can_update, :boolean
    field :can_delete, :boolean
  end
end

end