local item = table.deepcopy(data.raw.item["requester-chest"])

item.name = "robot-redistribute-chest"
-- item.entity = "robot-redistribute-chest"
item.place_result = item.name
item.icons = {
    {
        icon = "__robot-recall-v2__/graphics/icons/robot-redistribute-chest.png"
        -- tint = { r = 0.5, g = 0.5, b = 0.5, a = 1}
    },
}

data:extend{item}
