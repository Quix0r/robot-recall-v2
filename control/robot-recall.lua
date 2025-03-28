function getAverage(items)
    local count = 0
    local sum = 0
    for k, v in pairs(items) do
        count = count + 1
        sum = sum + v
    end

    return sum / count
end

function getItemProtoFromName(n)
    local temp = prototypes.item[n]
    return temp
end

function setGUISize(element, w, h)
    if (not element.style) then return end
    if (w) then element.style.width = w end
    if (h) then element.style.height = h end
end

function getAllIdleRobotsInNetwork(logistic_network)
    local robots = {}
    if (logistic_network == nil) then return robots end
    for k, cell in pairs(logistic_network.cells) do
        local inv = cell.owner.get_inventory(defines.inventory.roboport_robot)
        for i = 1, #inv do
            local itemstack = inv[i]
            if (itemstack.valid_for_read) then
                if robots[itemstack.name] then
                    robots[itemstack.name].count =
                        robots[itemstack.name].count + itemstack.count
                else
                    robots[itemstack.name] =
                        {
                            count = itemstack.count,
                            item = itemstack.prototype,
                            ent = itemstack.prototype.place_result
                        }
                end
            end
        end
    end

    return robots

end

function getDistanceBetweenVectors(a, b)
    local x = a.x - b.x
    local y = a.y - b.y

    return math.abs(math.sqrt((x * x) + (y * y)))
end

function getBotsBeingRecalled(recall_chest)
    local tbl = {}
    for k, v in pairs(storage.teleportQueue) do
        if (tbl.destination == recall_chest) then
            tbl[v.itemname] =
                tbl[v.itemname] and tbl[v.itemname] + v.count or v.count
        end
    end
    return tbl
end

function addToTeleportQueue(source, destination, itemstack)

    local currentTick = game.tick
    local destinationInv = destination.get_inventory(defines.inventory.chest)
    local dist =
        getDistanceBetweenVectors(source.position, destination.position)

    local robotEnt = itemstack.prototype.place_result
    local unitsPerTick = (source["force"]["worker_robots_speed_modifier"] + 1) * robotEnt.speed * settings.global["recall-speed-modifier"].value
    local can_insert = destinationInv.can_insert(itemstack)

    -- game.print("" .. itemstack.count .. " " .. itemstack.name ..
    --                "to teleport queue")

    if (not can_insert) then return end
    -- game.print("Can't recall, no space!") 
    local item_name = itemstack.prototype.name
    local queueEntry = {
        source = source,
        srcPos = source.position,
        destination = destination,
        destPos = destination.position,
        startTick = currentTick,
        endTick = math.abs(currentTick + (dist / unitsPerTick)),
        -- itemstack = itemstack,
        itemname = item_name,
        surface = destination.surface,
        count = itemstack.count
    }
    table.insert(storage.teleportQueue, queueEntry)
    itemstack.clear()
    storage.teleportQueueEntryCount = storage.teleportQueueEntryCount + 1
    -- local timeTo

end

function buildRecallGui(baseGUI, entity)
    if (not entity) then return end
    if (entity.name ~= 'robot-recall-chest') then return end
    local logistic_network = entity.logistic_network
    if (baseGUI['robot-recall-chest'] ~= nil) then
        baseGUI['robot-recall-chest'].destroy()
    end
    
    local recallFrame = baseGUI.add({
        type = "frame",
        name = "robot-recall-chest",
        direction = "vertical",
        -- style="standalone_inner_frame_in_outer_frame"
    })
    recallFrame.caption = {'robot-recall.chest-title'}
    -- ply.opened = recallFrame
    -- this is for vanilla at 1x scale
    local INV_DIMENSIONS = {width = 874, height = 436, verticalOffset = -88}
    local WIDTH = 300
    local HEIGHT = INV_DIMENSIONS.height
    local recallScrollFlowFrame = recallFrame.add(
                                      {
            type = "frame",
            name = "frame",
            style = "inside_shallow_frame",
            direction = "vertical"
        })
    local recallScrollFlow = recallScrollFlowFrame.add {
        type = "scroll-pane",
        name = "scrollpane"
    }

    setGUISize(recallFrame, WIDTH, HEIGHT)
    setGUISize(recallScrollFlow, WIDTH - 20, HEIGHT - 50)
    -- game.print(ply.gui)
    local ply = game.players[baseGUI.player_index]
    local res = ply.display_resolution
    local scl = ply.display_scale
    storage.openedGUIPlayers[baseGUI.player_index] =
        {ply = game.players[baseGUI.player_index], ent = entity}
    recallFrame.location = {
        (res.width / 2) - (INV_DIMENSIONS.width * scl * 0.5) - WIDTH * scl,
        (res.height / 2) - (INV_DIMENSIONS.height / 2 * scl) +
            (INV_DIMENSIONS.verticalOffset * scl)
    }

    local robots = getAllIdleRobotsInNetwork(logistic_network)
    updateRecallGuiList(baseGUI, robots, logistic_network)
end

function updateRecallGuiListEntry(itemname, count, baseGui)
    local scrollPane = baseGui['robot-recall-chest']['frame']['scrollpane']
    local ply = game.players[baseGui.player_index]
    local flow =
        baseGui['robot-recall-chest']['frame']['scrollpane'][itemname] or
            scrollPane.add({type = "flow", name = itemname})
    local spritebutton = flow['spritebutton'] or flow.add(
                             {
            type = "sprite-button",
            tooltip = {
                "robot-recall.recall-button-tooltip", getItemProtoFromName(itemname).localised_name
            },
            name = "spritebutton"
        })

    if (spritebutton.sprite == "") then
        spritebutton.sprite = "item/" .. itemname
    end

    local progressbar =
        baseGui['robot-recall-chest']['frame']['scrollpane'][itemname .. '-progressbar'] or
            scrollPane.add({
                type = "progressbar",
                name = itemname .. '-progressbar',
                visible = false,
                value = 0
            })

    if (ply.opened and ply.opened.name == "robot-recall-chest") then
        if (ply.opened.get_inventory(defines.inventory.chest).can_insert(
            {name = itemname})) then
            spritebutton.enabled = true
        else
            spritebutton.enabled = false
        end
    end

    local label = flow['label'] or flow.add({type = "label", name = "label"})
    label.caption = {"robot-recall.recall-count", getItemProtoFromName(itemname).localised_name, count}
    label.style.single_line = false

end

function updateRecallGuiList(baseGui, robots, logistic_network)
    local scrollPane = baseGui['robot-recall-chest']['frame']['scrollpane']
    local ply = game.players[baseGui.player_index]
    if (logistic_network == nil or not logistic_network.valid) then
        local label = scrollPane['no-network'] or scrollPane.add(
                          {
                type = "label",
                caption = {"robot-recall.chest-no-network", ":("},
                name = "no-network"
            })
        label.style.horizontal_align = "center"
        label.style.width = scrollPane.style.maximal_width - 10
        return
    end
    if (scrollPane['no-network'] and scrollPane['no-network'].valid) then
        scrollPane['no-network'].destroy()
    end
    local count = 0
    local recalled = getBotsBeingRecalled()
    for k, v in pairs(recalled) do
        if (robots[k]) then
            robots[k].count = robots[k].count + v
        else
            robots[k] = {
                count = v,
                item = getItemProtoFromName(k),
                ent = getItemProtoFromName(k).place_result
            }
        end
    end
    for k, v in pairs(robots) do updateRecallGuiListEntry(k, v.count, baseGui) end

    local count = table_size(robots)
    -- TODO swelter: figure out if table_size can be something other than 1
    -- leaving this commented out for now, as i couldn't find a situation where it wasn't true in factorio 1.1.110
    -- this is not to say there isn't an issue here, and this should be better understood what's supposed to happen here.
    -- if (count * 2 ~= table_size(scrollPane)) then
    if (true) then
        for k, v in pairs(baseGui['robot-recall-chest']['frame']['scrollpane']
                              .children) do
            if (v.valid and v.type == "flow" and not robots[v.name]) then
                local progress =
                    baseGui['robot-recall-chest']['frame']['scrollpane'][v.name ..
                        '-progressbar']
                v.destroy()
                progress.destroy()
                -- baseGui['robot-recall-chest']['frame']['scrollpane'][k..'-progressbar'].destroy()
            end
        end
    end

    if (count == 0 and not scrollPane['no-robots-label']) then
        local label = scrollPane.add({
            type = "label",
            caption = {'robot-recall.chest-no-robot-in-roboport', ":("},
            name = "no-robots-label"
        })
        -- baseGUI.style.height
        label.style.single_line = false
        label.style.horizontal_align = 'center'
        label.style.width = scrollPane.style.maximal_width - 10
        return
    elseif (count > 0 and scrollPane['no-robots-label'] and
    scrollPane['no-robots-label'].valid) then
        scrollPane['no-robots-label'].destroy()
    end
    -- if (scrollPane['no-robots-label']) then 
    --     game.print(scrollPane['no-robots-label'].valid) 
    -- end
end

function updateRecallGuiListProgress(baseGui, robots, logistic_network)
    if (not baseGui or not baseGui['robot-recall-chest']) then return end

    local scrollPane = baseGui['robot-recall-chest']['frame']['scrollpane']
    local ply = game.players[baseGui.player_index]
    for _, element in pairs(scrollPane.children) do
        if (element.type == "progressbar") then
            local progressbar = element
            local itemname = string.sub(element.name, 0,
                                        -1 - string.len("-progressbar"))
            local totalProgress = {}
            for k, v in pairs(storage.teleportQueue) do
                -- if (storage.teleportQueue.destination) then
                -- end

                if (v.destination and v.destination.valid and ply.opened and
                    ply.opened.valid and v.destination.unit_number ==
                    ply.opened.unit_number and v.itemname == itemname) then
                    local currentTick = game.tick - v.startTick
                    local finishTick = v.endTick - v.startTick
                    -- game.print("TELEPORT QUEUE LOl")
                    table.insert(totalProgress, currentTick / finishTick)
                end
            end
            if (table_size(totalProgress) ~= 0) then
                progressbar.visible = true
                local newprog = getAverage(totalProgress)
                progressbar.value = math.max(newprog, progressbar.value)
            else
                progressbar.visible = false
                progressbar.value = 0
                -- local robots = getAllIdleRobotsInNetwork(ply.opened.ent)
                -- updateRecallGuiList(v.ply.gui.screen, robots, v.ent.logistic_network)
            end

        end
    end

end

function createRobotRecallGUI(ent, ply, gui)
    -- if (not (ent and ent.name == "robot-recall-chest")) then return end
    if (gui['robot-recall-chest'] ~= nil) then
        gui['robot-recall-chest'].destroy()
    end
    local recallFrame = gui.add({
        type = "frame",
        name = "robot-recall-chest",
        direction = "vertical"
    })
    recallFrame.caption = {'robot-recall.chest-title'}
    -- ply.opened = recallFrame
    -- this is for vanilla at 1x scale
    local INV_DIMENSIONS = {width = 874, height = 436, verticalOffset = -88}
    local WIDTH = 300
    local HEIGHT = INV_DIMENSIONS.height
    local recallScrollFlowFrame = recallFrame.add(
                                      {
            type = "frame",
            name = "frame",
            style = "inside_shallow_frame_with_padding",
            direction = "vertical"
        })
    local recallScrollFlow = recallScrollFlowFrame.add {
        type = "scroll-pane",
        name = "scrollpane"
    }

    setGUISize(recallFrame, WIDTH, HEIGHT)
    setGUISize(recallScrollFlow, WIDTH - 20, HEIGHT - 50)
    -- game.print(ply.gui)
    local res = ply.display_resolution
    local scl = ply.display_scale

    recallFrame.location = {
        (res.width / 2) - (INV_DIMENSIONS.width * scl * 0.5) - WIDTH * scl,
        (res.height / 2) - (INV_DIMENSIONS.height / 2 * scl) +
            (INV_DIMENSIONS.verticalOffset * scl)
    }

    -- if (ent and ent.logistic_network) then
    --     -- game.print(ent.logistic_network.robots)
    --     -- recallFrame.direction = "vertical"
    --     -- drawRobotRecallGui(recallScrollFlow, ent.logistic_network)
    -- end
end

function callRobotsToEntity(location_ent, logisticNetwork, robotItem)

    for k, cell in pairs(logisticNetwork.cells) do
        local roboport = cell.owner
        local inv = roboport.get_inventory(defines.inventory.roboport_robot)
        for i = 1, #inv do
            local itemstack = inv[i]
            if (itemstack.valid_for_read) then
                if (itemstack.prototype == robotItem) then
                    addToTeleportQueue(roboport, location_ent, itemstack)
                end
            end
        end
    end
end

function updateTeleportJobs(event)
    local warning = false
    for k, e in ipairs(storage.teleportQueue) do
        -- if (not itemstack.valid)
        if ((not e.destination or not e.destination.valid)) then
            -- game.print("Source or destination not valid! Removing queue item!")
            
            local count
            if (not warning) then
                -- if (__DebugAdapter) then __DebugAdapter.print("Hello!") end
                game.print("Robot Recall Chest cannot be found! Robots have been returned to their source position.")
                warning = true
            end
            if (e.source.valid) then count = e.source.insert({name=e.itemname, count=e.count}) end
            if (not count or count ~= e.count) then
                count = count and (e.count - count) or e.count
                e.surface.spill_item_stack({position=e.srcPos, stack={name=e.itemname, count=count}, allow_belts=false})
                game.print(count .. " robots have been dropped at their source position, there is no room in the source.")
            end


            storage.teleportQueue[k] = nil
            storage.teleportQueueEntryCount = storage.teleportQueueEntryCount - 1

        end
        if (event.tick >= e.endTick) then
            -- game.print("Teleport job finished!")

            -- if () then return end
            local destinationInv = e.destination.get_inventory(
                                       defines.inventory.roboport_robot) or
                                       e.destination.get_inventory(
                                           defines.inventory.chest)
            local sourceInv = e.source.get_inventory(
                                  defines.inventory.roboport_robot) or
                                  e.source
                                      .get_inventory(defines.inventory.chest)

            -- if (destinationInv.can_insert({name = e.itemname, count = e.count})) then
                local amnt = destinationInv.insert({name = e.itemname, count = e.count})
                if (amnt ~= e.count) then
                    local initialRemainder = e.count - amnt
                    local remainder = e.count - amnt
                    remainder = remainder - sourceInv.insert({name = e.itemname, count = remainder})
                    if (remainder ~= 0) then
                        game.print("Recall of " .. e.count .. " '" .. e.itemname ..
                                "' robots has (partially) failed. " .. remainder .. ' could not be recalled.')
                        if (e.destination.logistic_network and
                            e.destination.logistic_network.valid) then
                            for _, cell in
                                pairs(e.destination.logistic_network.cells) do
                                if (remainder ~= 0) then
                                    local inv =
                                        cell.owner.get_inventory(
                                            defines.inventory.roboport_robot)
                                    remainder =
                                        remainder -
                                            inv.insert({name = e.itemname, count = remainder})
                                end
                            end
                            if (remainder ~= initialRemainder) then
                                -- game.print("Recall of " .. e.count .. " " .. e.itemname .. " has failed.")
                                game.print(
                                    (initialRemainder - remainder) ..
                                        " robots have been redeployed to roboports")
                            end
                        end

                        if (remainder ~= 0) then
                            game.print(remainder .. " robots have been dropped in front of the recall station.")
                            local ent = 
                                e.destination.surface.spill_item_stack({position=e.destination.position, stack={
                            name = e.itemname, count = remainder}, allow_belts=false})
                            -- game.print(ent.position)
                            
                        end

                    end

                end
            -- end

            -- for _, v in pairs(storage.openedGUIPlayers) do
            --     -- getAllIdleRobotsInNetwork(p.ply.opened)
            --     -- local robots = getAllIdleRobotsInNetwork(v.ent.logistic_network)
            --     -- updateRecallGuiList(v.ply.gui.screen, robots, v.ent.logistic_network)
            -- end
            table.remove(storage.teleportQueue, k)
            storage.teleportQueueEntryCount = storage.teleportQueueEntryCount - 1
        end
    end
end

function initRecallChest(event) end

script.on_event({defines.events.on_built_entity}, function(event)
    -- game.print("Hello!")
    if (event.entity and event.entity.name ==
        "robot-recall-chest") then initRecallChest(event) end
end)

script.on_event({defines.events.on_robot_built_entity}, function(event)
    if (event.entity and event.entity.name ==
        "robot-recall-chest") then initRecallChest(event) end
end)

script.on_event({defines.events.on_gui_opened}, function(event)
    local ent = event.entity
    local ply = game.players[event.player_index]
    local gui = ply.gui.screen
    buildRecallGui(gui, ent)
    -- recallFrame.add({})

    -- local closeButton = recallFrame.add({type="button",name="robot-recall-chest.close", caption="Close!"})

end)

script.on_event({defines.events.on_gui_closed}, function(event)
    local ent = event.entity
    local ply = game.players[event.player_index]
    local gui = ply.gui.screen
    if (gui['robot-recall-chest'] ~= nil) then
        if (storage.openedGUIPlayers[event.player_index]) then
            table.remove(storage.openedGUIPlayers, event.player_index)
        end
        gui['robot-recall-chest'].destroy()
    end
    -- game.print('on_gui_close')
end)

script.on_event({defines.events.on_gui_click}, function(event)
    -- game.print(event)
    local ply = game.players[event.player_index]

    if (event.element.type == "sprite-button" and ply.opened and ply.opened.name ==
        "robot-recall-chest") then
        local itemname = event.element.parent.name
        local item = prototypes.item[itemname]
        -- game.print('recalling "' .. itemname .. '"')
        callRobotsToEntity(ply.opened, ply.opened.logistic_network, item,
                           event.tick)

    end

    if (event.element.name == "robot-recall-chest.close") then
        event.element.parent.destroy()
    end
end)

-- script.on_nth_tick(10, function(event)
-- if (event.tick % 5 == 0) then
--     for k, v in pairs(game.players) do
--         -- local  = v.gui.screen
--         local gui = v.gui.screen
--         updateRecallGui(event, gui, v)
--     end
-- end
-- end)
-- script.on_event({defines.events.on_tick}, function(event)
--     if (storage.teleportQueueEntryCount > 0) then
--         for k, v in pairs(storage.openedGUIPlayers) do
--             -- local  = v.gui.screen
--             local gui = v.ply.gui.screen
--             -- __DebugAdapter.print("Updating every tick!")
--             if (v.ent.logistic_network and v.ent.logistic_network.valid) then
--                 local robots = getAllIdleRobotsInNetwork(v.ent.logistic_network)
--                 updateRecallGuiList(v.ply.gui.screen, robots,
--                                     v.ent.logistic_network)
--             end
--         end
--     end
-- end)

script.on_nth_tick(2, function(event)
    if (not storage.teleportQueueEntryCount or not storage.teleportQueue) then return end
    if (storage.teleportQueueEntryCount == 0 and storage.hasChanged) then
        storage.hasChanged = false
        for k, v in pairs(storage.openedGUIPlayers) do
            updateRecallGuiListProgress(v.ply.gui.screen)
        end
    elseif (storage.teleportQueueEntryCount > 0) then
        storage.hasChanged = true
        for k, v in pairs(storage.openedGUIPlayers) do
            updateRecallGuiListProgress(v.ply.gui.screen)
        end
    end

end)

script.on_nth_tick(10, function(event)
    -- if (not storage.teleportQueueEntryCount
    if (storage.teleportQueueEntryCount and storage.teleportQueueEntryCount > 0) then updateTeleportJobs(event) end
end)

script.on_nth_tick(180, function(event)
    for k, v in pairs(storage.openedGUIPlayers) do
        -- __DebugAdapter.print("Updating every 10 ticks!")

        -- local  = v.gui.screen
        local gui = v.ply.gui.screen
        if (v.ent.logistic_network and v.ent.logistic_network.valid) then
            local robots = getAllIdleRobotsInNetwork(v.ent.logistic_network)
            updateRecallGuiList(v.ply.gui.screen, robots, v.ent.logistic_network)
        end
    end
    -- end
end)


