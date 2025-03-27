-- @todo Find proper mod name
if __DebugAdapter then
  local variables = require("__debugadapter__/variables.lua")
end

-- Load all data
for _, prototype in pairs({"entity", "item", "recipe"}) do
    require("prototypes." .. prototype ..".robot-recall")
end
