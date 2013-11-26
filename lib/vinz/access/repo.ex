defmodule Vinz.Access.Repo.Query.Api do
  use Ecto.Query.Typespec

  ## Types
  deft boolean

  @doc """
  Aggregate function, returns true if atleast one input value is true.
  See http://www.postgresql.org/docs/9.2/static/functions-aggregate.html
  """
  @aggregate true
  def bool_or(booleans)
  defs bool_or(boolean) :: boolean
end
