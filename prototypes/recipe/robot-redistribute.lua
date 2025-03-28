local recipe = table.deepcopy(data.raw.recipe["passive-provider-chest"])
recipe.enabled = false;
recipe.ingredients = {
    {type="item", name="passive-prodiver-chest", amount=1},
    {type="item", name="processing-unit", amount=1}
}
recipe.name = "robot-redistribute-chest"
recipe.results = {
  {type="item", name=recipe.name, amount=1}
}

table.insert(data.raw["technology"]["construction-robotics"].effects, {type="unlock-recipe", recipe=recipe.name})
table.insert(data.raw["technology"]["logistic-robotics"].effects, {type="unlock-recipe", recipe=recipe.name})

data:extend{recipe}
