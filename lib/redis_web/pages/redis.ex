defmodule RedisWeb.Redis do
  use RedisWeb, :surface_live_view

  alias Moon.Design.Table.Column
  alias Moon.Design.{Table, Button, Modal}

  def mount(_params, _session, socket) do
    {:ok, conn} = Redix.start_link("redis://127.0.0.1:6380")

    values = fetch_keys(conn)

    {:ok, assign(socket, variables: values, create_modal_open: false, redis_conn: conn, key: nil)}
  end

  def render(assigns) do
    ~F"""
    <div class="flex flex-col items-center justify-center mx-4 md:mx-0 font-oswald bg-gohan">
      <h1 class="text-2xl mb-4">Redis keys and values storage</h1>
      <Button on_click="open_create_modal" class="mb-4 mr-4 bg-popo hover:bg-neutral-700">
        Add key and value
      </Button>
      <Table items={item <- @variables}>
        <Column name="key" label="Key">
          {item.key}
        </Column>
        <Column name="value" label="Value">
          {item.value}
        </Column>
        <Column label="">
          <Button
            full_width="true"
            on_click="open_delete_modal"
            value={item.key}
            class="bg-popo hover:bg-zeno"
          >Delete key</Button>
        </Column>
        <Column label="">
          <Button
            full_width="true"
            on_click="open_update_modal"
            value={item.key}
            class="bg-popo hover:bg-zeno"
          >Update value</Button>
        </Column>
      </Table>
    </div>

    <Modal id="create_modal" is_open={@create_modal_open}>
      <Modal.Backdrop />
      <Modal.Panel>
        <div class="p-4 border-beerus">
          <h3 class="text-moon-18 text-center text-bulma font-medium border-b-2 pb-4">
            Create new key and value
          </h3>
          <br>
            <.form phx-submit="save">
              <div class="mt-2 flex justify-between items-center">
                <label for="key">Key</label>
                <input type="text" name="key" id="key" class="input" required>
              </div>

              <div class="mt-8 flex justify-between items-center">
                <label for="value">Value</label>
                <input type="text" name="value" id="value" class="input" required>
              </div>

              <div class="flex justify-between mt-8">
                <Button on_click="close_create_modal" variant="outline">Discard</Button>
                <Button type="submit" class="bg-popo hover:bg-zeno ml-4">Create</Button>
              </div>
            </.form>
        </div>
      </Modal.Panel>
    </Modal>

    <Modal id="delete_modal">
      <Modal.Backdrop />
      <Modal.Panel>
        <div class="p-4 border-beerus">
          <h3 class="text-moon-18 text-center font-medium pb-4">
            Are you sure you want to delete key: {@key} ?
          </h3>
        </div>
        <div class="p-4 flex justify-between">
          <Button on_click="close_delete_modal" variant="outline">Discard</Button>
          <Button on_click="confirm_delete_modal" value={@key} class="bg-popo hover:bg-zeno ml-4">Confirm</Button>
        </div>
      </Modal.Panel>
    </Modal>

    <Modal id="update_modal">
      <Modal.Backdrop />
      <Modal.Panel>
        <div class="p-4 border-beerus">
          <h3 class="text-moon-18 text-center font-medium pb-4">
            Update Key: <strong>{@key}</strong>
          </h3>
          <br>
            <.form phx-submit="confirm_update_modal">
              <input type="hidden" name="key" value={@key} />
              <div class="mt-2 flex justify-between items-center">
                <label for="value">New Value</label>
                <input type="text" name="value" id="value" class="input" required>
              </div>

              <div class="flex justify-between mt-8">
                <Button on_click="close_update_modal" variant="outline">Discard</Button>
                <Button type="submit" class="bg-popo hover:bg-zeno ml-4">Update</Button>
              </div>
            </.form>
        </div>
      </Modal.Panel>
    </Modal>
    """
  end

  def handle_event("open_delete_modal", %{"value" => key}, socket) do
    Modal.open("delete_modal")

    {:noreply, assign(socket, key: key)}
  end

  def handle_event("close_delete_modal", _, socket) do
    Modal.close("delete_modal")

    {:noreply, assign(socket, key: nil)}
  end

  def handle_event("confirm_delete_modal", %{"value" => key}, socket) do
    conn = socket.assigns.redis_conn

    Redix.command(conn, ["DEL", key])
    updated_keys = fetch_keys(conn)

    Modal.close("delete_modal")

    {:noreply, assign(socket, key: nil, variables: updated_keys)}
  end

  def handle_event("open_update_modal", %{"value" => key}, socket) do
    Modal.open("update_modal")

    {:noreply, assign(socket, key: key)}
  end

  def handle_event("close_update_modal", _, socket) do
    Modal.close("update_modal")

    {:noreply, assign(socket, key: nil)}
  end

  def handle_event("open_create_modal", _, socket) do
    Modal.open("create_modal")

    {:noreply, assign(socket, create_modal_open: true)}
  end

  def handle_event("close_create_modal", _, socket) do
    Modal.close("create_modal")

    {:noreply, assign(socket, create_modal_open: false)}
  end

  def handle_event("save", %{"key" => key, "value" => value}, socket) do
    conn = socket.assigns.redis_conn

    case Redix.command(conn, ["EXISTS", key]) do
      {:ok, 1} ->
        error_message = "Key '#{key}' already exists. Please choose a different key."

        {:noreply,
        socket
        |> put_flash(:error, error_message)
        |> assign(create_modal_open: false)}

      {:ok, 0} ->
        case Redix.command(conn, ["SET", key, value]) do
          {:ok, "OK"} ->
            new_variable = %{key: key, value: value}
            updated_variables = [new_variable | socket.assigns.variables]

            {:noreply,
            socket
            |> assign(variables: updated_variables)
            |> assign(create_modal_open: false)}

          {:error, _reason} ->
            {:noreply, socket}
        end

      {:error, _reason} ->

        error_message = "Error checking if key '#{key}' exists."

        {:noreply, socket
        |> put_flash(:error, error_message)}
    end
  end


  def handle_event("confirm_update_modal", %{"key" => key, "value" => value}, socket) do
    conn = socket.assigns.redis_conn

    Modal.close("update_modal")

    case Redix.command(conn, ["SET", key, value]) do
      {:ok, "OK"} ->
        updated_variables =
          Enum.map(socket.assigns.variables, fn
            %{key: ^key} = variable -> %{variable | value: value}
            variable -> variable
          end)

        {:noreply,
        socket
        |> assign(variables: updated_variables) }

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  defp fetch_keys(conn) do
    {:ok, keys} = Redix.command(conn, ["KEYS", "*"])

    values =
      Enum.flat_map(keys, fn key ->
        case Redix.command(conn, ["TYPE", key]) do
          {:ok, "string"} ->
            case Redix.command(conn, ["GET", key]) do
              {:ok, value} -> [%{key: key, value: value}]
              _ -> []
            end

          _ ->
            []
        end
      end)

    values
  end
end
