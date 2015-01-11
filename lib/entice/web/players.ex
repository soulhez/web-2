defmodule Entice.Web.Players do
  use Entice.Area
  use Entice.Area.Attributes
  alias Entice.Web.Groups
  alias Entice.Area.Entity
  import Entice.Web.Utils

  def prepare_player(map, char) do
    {:ok, id} = Entity.start(map, UUID.uuid4(), %{
      Name => %Name{name: char.name},
      Position => %Position{pos: map.spawn},
      Appearance => copy_into(%Appearance{}, char)})
    Groups.create_for(map, id)
    {:ok, id}
  end

  def start_transfer(map, id) do
    Groups.delete_for(map, id)
    :ok = Entity.change_area(map, Transfer, id)
    reset_pos(Transfer, id)
    :ok
  end

  def continue_transfer(map, id) do
    :ok = Entity.change_area(Transfer, map, id)
    reset_pos(map, id)
    Groups.create_for(map, id)
    :ok
  end

  defp reset_pos(map, id) do
    Entity.put_attribute(map, id, map.spawn)
  end
end
