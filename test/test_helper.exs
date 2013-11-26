ExUnit.start

defmodule Vinz.Access.Test.Repo do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres
  def url do 
    { :ok, url } = :application.get_env(:vinz_access, :repo_url)
    url
  end
  def query_apis do
    super() ++ [Vinz.Access.Repo.Query.Api]
  end
end

Vinz.Access.Test.Repo.start_link

defmodule Vinz.Access.TestCase do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case
      alias Ecto.Adapters.Postgres
      alias Vinz.Access.Test.Repo

      def begin do
        Postgres.begin_test_transaction(Repo)
        :ok
      end

      def rollback do
        Postgres.rollback_test_transaction(Repo)
        :ok
      end
    end
  end
end
