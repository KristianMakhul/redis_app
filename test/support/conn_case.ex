defmodule Redis.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint RedisWeb.Endpoint

      use RedisWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Redis.ConnCase
    end
  end

  setup _tags do
    clean_redis(:redix)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  defp clean_redis(conn) do
    # Sends the FLUSHALL command to clear all keys in Redis
    Redix.command!(conn, ["FLUSHALL"])
  end
end
