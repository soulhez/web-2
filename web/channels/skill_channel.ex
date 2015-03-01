defmodule Entice.Web.SkillChannel do
  use Phoenix.Channel
  use Entice.Logic.Area
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Skills
  alias Entice.Logic.Area
  alias Entice.Web.Token
  import Phoenix.Naming
  import Entice.Web.ChannelHelper


  def join("skill:" <> map, %{"client_id" => client_id, "entity_token" => token}, socket) do
    {:ok, ^token, :entity, %{map: map_mod, entity_id: entity_id, char: char}} = Token.get_token(client_id)
    {:ok, ^map_mod} = Area.get_map(camelize(map))

    socket = socket
      |> set_map(map_mod)
      |> set_entity_id(entity_id)
      |> set_client_id(client_id)
      |> set_character(char)

    # retrieve skill bar here
    {:ok, skill} = Skills.get_skill(1)
    skillbar = %SkillBar{slots: %{"1" => skill}} # set first slot to be HealingSignet
    Entity.put_attribute(entity_id, skillbar)

    socket |> reply("join:ok", %{unlocked_skills: char.available_skills, skillbar: format_slots(skillbar.slots)})
    {:ok, socket}
  end


  def handle_in("skillbar:set", %{"slot" => slot, "id" => 0}, socket) when slot in 0..10 do
    new_slots = case Entity.fetch_attribute(socket |> entity_id, SkillBar) do
      {:ok, skillbar} -> Map.delete(skillbar.slots, to_string(slot))
      _               -> %{}
    end
    Entity.put_attribute(socket |> entity_id, %SkillBar{slots: new_slots})
    socket |> reply("skillbar:ok", %{skillbar: format_slots(new_slots)})
    {:ok, socket}
  end


  def handle_in("skillbar:set", %{"slot" => slot, "id" => id}, socket) when slot in 0..10 and id > 0 do
    # replace with a sophisticated check of the client's skills
    {:ok, skill} = Skills.get_skill(id)

    new_slots = case Entity.fetch_attribute(socket |> entity_id, SkillBar) do
      {:ok, skillbar} -> Map.put(skillbar.slots, to_string(slot), skill)
      _               -> %{}
    end

    Entity.put_attribute(socket |> entity_id, %SkillBar{slots: new_slots})
    socket |> reply("skillbar:ok", %{skillbar: format_slots(new_slots)})
    {:ok, socket}
  end


  def leave(_msg, socket) do
    Entity.remove_attribute(socket |> entity_id, SkillBar)
    {:ok, socket}
  end


  # Internal


  defp format_slots(slots) when is_map(slots) do
    slots
    |> Map.keys
    |> Enum.reduce(%{}, fn (slot, acc) ->
        Map.put(acc, to_string(slot), slots[slot].id)
      end)
  end
end
