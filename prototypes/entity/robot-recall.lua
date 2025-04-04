-- local entity = table.deepcopy(data.raw["logistic-container"]["logistic-chest-requester"])

local entity = {}
local baseEnt = data.raw["logistic-container"]["passive-provider-chest"]

entity.name = "robot-recall-chest"
entity.order = "logistic-container"
entity.minable = { mining_time = 0.1, result = "robot-recall-chest" } 
entity.logistic_mode = "passive-provider"
entity.inventory_size = settings.startup["recall-chest-size"].value
entity.icon_size = 64
entity.health = 350
entity.icon_mipmaps = 4
entity.icon = "__robot-recall-v2__/graphics/icons/robot-recall-chest.png"
entity.open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume=0.5 }
entity.close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.5 }
entity.animation_sound = baseEnt.animation_sound
entity.vehicle_impact_sound = baseEnt.vehicle_impact_sound
entity.opened_duration = baseEnt.opened_duration 
entity.collision_box = {{-0.35, -0.35}, {0.35, 0.35}}
entity.selection_box = {{-0.5, -0.5}, {0.5, 0.5}}
entity.damaged_trigger_effect = baseEnt.damaged_trigger_effect
entity.type = "logistic-container"
entity.animation = {
  layers =
  {
    {
      filename = "__robot-recall-v2__/graphics/entity/robot-recall-chest.png",
      priority = "extra-high",
      width = 66,
      height = 74,
      frame_count = 7,
      shift = util.by_pixel(0, -2),
      scale = 0.5
    },{
      filename = "__base__/graphics/entity/logistic-chest/logistic-chest-shadow.png",
      priority = "extra-high",
      width = 96,
      height = 44,
      repeat_count = 7,
      shift = util.by_pixel(8.5, 5),
      draw_as_shadow = true,
      scale = 0.5
    }
  }
}

entity.picture = entity.animation
entity.circuit_wire_connection_point = circuit_connector_definitions["chest"].points
entity.circuit_connector_sprites = circuit_connector_definitions["chest"].sprites
entity.circuit_wire_max_distance = default_circuit_wire_max_distance
entity.flags = {"placeable-player", "player-creation"}

data:extend{entity}
