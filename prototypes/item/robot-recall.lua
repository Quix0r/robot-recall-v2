local item = table.deepcopy(data.raw.item["requester-chest"])

item.name = "robot-recall-chest"
-- item.entity = "robot-recall-chest"
item.place_result = "robot-recall-chest"
item.icons = {
    {
        icon = "__robot-recall-v2__/graphics/icons/robot-recall-chest.png"
        -- tint = { r = 0.5, g = 0.5, b = 0.5, a = 1}
    },
}

data:extend{item}
