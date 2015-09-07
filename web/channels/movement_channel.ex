defmodule Entice.Web.MovementChannel do
  use Entice.Web.Web, :channel
  use Entice.Logic.Area
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Logic.Area
  alias Entice.Logic.Movement, as: Move
  alias Entice.Web.Token
  alias Entice.Web.Observer
  import Phoenix.Naming


  def join("movement:" <> map, %{"client_id" => client_id, "entity_token" => token}, socket) do
    {:ok, ^token, :entity, %{map: map_mod, entity_id: entity_id, char: char}} = Token.get_token(client_id)
    {:ok, ^map_mod} = Area.get_map(camelize(map))


    Observer.register(entity_id)
    Observer.notify_active(entity_id, "movement:" <> map, [])

    :ok = Move.register(entity_id)

    socket = socket
      |> set_map(map_mod)
      |> set_entity_id(entity_id)
      |> set_client_id(client_id)
      |> set_character(char)

    socket |> push("join:ok", %{})
    {:ok, socket}
  end


  def handle_in("update:pos", %{"pos" => %{"x" => x, "y" => y} = pos}, socket) do
    Entity.put_attribute(socket |> entity_id, %Position{pos: %Coord{x: x, y: y}})
    broadcast!(socket, "update:pos", %{entity: socket |> entity_id, pos: pos})

    {:ok, socket}
  end


  def handle_in("update:goal", %{"goal" => %{"x" => x, "y" => y} = goal, "plane" => plane}, socket) do
    Move.change_goal(socket |> entity_id, %Coord{x: x, y: y}, plane)
    broadcast!(socket, "update:goal", %{entity: socket |> entity_id, goal: goal, plane: plane})

    {:ok, socket}
  end


   def handle_in("update:movetype", %{"movetype" => mtype, "velocity" => velo}, socket)
   when mtype in 0..10 and velo in -1..2 do
    Move.change_move_type(socket |> entity_id, mtype, velo)
    broadcast!(socket, "update:movetype", %{entity: socket |> entity_id, movetype: mtype, velocity: velo})

    {:ok, socket}
  end


  def handle_out("update:" <> value, %{} = msg, socket)
  when value in ["pos", "goal", "movetype"] do
    socket |> push("update:" <> value, msg)
    {:ok, socket}
  end


  def handle_out("terminated", %{entity_id: entity_id}, socket) do
    case (entity_id == socket |> entity_id) do
      true  -> {:leave, socket}
      false -> {:ok, socket}
    end
  end


  def handle_out(_event, _message, socket), do: {:ok, socket}


  def leave(_msg, socket) do
    Observer.notify_inactive(socket |> entity_id, socket.topic)
    Move.unregister(socket |> entity_id)
    {:ok, socket}
  end
end

