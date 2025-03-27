local recipe = table.deepcopy(data.raw.recipe["passive-provider-chest"])
recipe.enabled = false;
recipe.ingredients = {
    {type="item", name="passive-prodiver-chest", value=1},
    {type="item", name="processing-unit", value=1}
}
recipe.name = "robot-redistribute-chest"
recipe.results = {
  {type="item", name=recipe.name, amount=1}
}

table.insert(data.raw["technology"]["construction-robotics"].effects, {type="unlock-recipe", recipe="robot-redistribute-chest"})
table.insert(data.raw["technology"]["logistic-robotics"].effects, {type="unlock-recipe", recipe="robot-redistribute-chest"})

data:extend{item, entity, recipe}
