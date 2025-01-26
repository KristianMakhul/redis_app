defmodule Redis.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Redis.DataCase
    end
  end

  setup _tags do
    # Ensure Redis is clean before each test
    clean_redis(:redix)
    :ok
  end

  @doc """
  A helper function to clear all Redis data between tests.
  """
  def clean_redis(conn) do
    Redix.command!(conn, ["FLUSHALL"])
  end
end
