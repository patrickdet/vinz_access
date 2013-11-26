defmodule Vinz.Access.Users do
  @resource "vinz.users"

  alias Vinz.Access
  alias Vinz.Access.Models.User

  def create(repo, creator_id, vals) do
    Access.permit repo, creator_id, @resource, :create, fn ->
      user = User.new(vals)
      case User.validate(user) do
        { :ok, user } -> repo.create(user)
        { :error, errors } -> { :error, errors }
      end
    end
  end

  def delete(repo, deletor_id, user_id) do
    Access.permit repo, deletor_id, @resource, :delete, fn ->
      if user = repo.find(User, user_id) do
        repo.delete(user)
      else
        { :error, :not_found }
      end
    end
  end
end
