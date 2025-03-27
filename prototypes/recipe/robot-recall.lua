local recipe = table.deepcopy(data.raw.recipe["requester-chest"])
recipe.enabled = false;
recipe.ingredients = {
    {type="item", name="requester-chest", amount=1},
    {type="item", name="processing-unit", amount=1}
}
recipe.name = "robot-recall-chest"
recipe.results = {
  {type="item", name=recipe.name, amount=1}
}

table.insert(data.raw["technology"]["construction-robotics"].effects, {type="unlock-recipe", recipe="robot-recall-chest"})
table.insert(data.raw["technology"]["logistic-robotics"].effects, {type="unlock-recipe", recipe="robot-recall-chest"})

data:extend{item, entity, recipe}
