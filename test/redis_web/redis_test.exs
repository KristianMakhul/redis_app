defmodule Redis.RedisTest do
  use Redis.DataCase, async: true
  use Redis.ConnCase

  import Phoenix.LiveViewTest

  describe "Backend Tests" do
    test "set and get a value in Redis" do
      assert {:ok, "OK"} = Redix.command(:redix, ["SET", "test_key", "test_value"])
      assert {:ok, "test_value"} = Redix.command(:redix, ["GET", "test_key"])
    end

    test "delete a key in Redis" do
      Redix.command(:redix, ["SET", "key_to_delete", "value"])
      assert {:ok, 1} = Redix.command(:redix, ["DEL", "key_to_delete"])
      assert {:ok, nil} = Redix.command(:redix, ["GET", "key_to_delete"])
    end

    test "increment a value in Redis" do
      Redix.command(:redix, ["SET", "counter", "10"])
      assert {:ok, 11} = Redix.command(:redix, ["INCR", "counter"])
      assert {:ok, "11"} = Redix.command(:redix, ["GET", "counter"])
    end

    test "push and pop from a list in Redis" do
      Redix.command(:redix, ["LPUSH", "my_list", "value1"])
      Redix.command(:redix, ["LPUSH", "my_list", "value2"])
      assert {:ok, "value2"} = Redix.command(:redix, ["LPOP", "my_list"])
      assert {:ok, "value1"} = Redix.command(:redix, ["LPOP", "my_list"])
      assert {:ok, nil} = Redix.command(:redix, ["LPOP", "my_list"])
    end

    test "set a key with expiration and check expiration" do
      Redix.command(:redix, ["SET", "temp_key", "temp_value", "EX", "1"])
      assert {:ok, "temp_value"} = Redix.command(:redix, ["GET", "temp_key"])
      Process.sleep(1100)
      assert {:ok, nil} = Redix.command(:redix, ["GET", "temp_key"])
    end

    test "Redis interaction with cleanup" do
      assert {:ok, "OK"} = Redix.command(:redix, ["SET", "my_key", "my_value"])
      assert {:ok, "my_value"} = Redix.command(:redix, ["GET", "my_key"])

      clean_redis(:redix)

      assert {:ok, 0} = Redix.command(:redix, ["EXISTS", "my_key"])
    end
  end

  describe "Frontend Tests" do
    test "renders Redis page with correct content", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Redis keys and values storage"
      assert html =~ "Add key and value"
      assert html =~ "Key"
      assert html =~ "Value"
    end

    test "clicking 'Discard' closes the create modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("button", "Add key and value")
      |> render_click()

      assert render(view) =~ "Create new key and value"
    end

    test "clicking 'Update value' opens update modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("button[value=key]", "Update value")
      |> render_click()

      assert render(view) =~ "Update Key"
    end

    test "creating a new key-value pair displays it on the page", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#create_modal form", %{key: "new_key", value: "new_value"})
      |> render_submit()

      assert render(view) =~ "new_key"
      assert render(view) =~ "new_value"
    end

    test "creating and deleting a key-value pair updates the page", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> form("#create_modal form", %{key: "new_key", value: "new_value"})
      |> render_submit()

      assert render(view) =~ "new_key"
      assert render(view) =~ "new_value"

      view
      |> element("button[phx-click=confirm_delete_modal]", "Confirm")
      |> render_click(%{value: "new_key"})
      
      refute render(view) =~ "new_value"
    end
  end
end
