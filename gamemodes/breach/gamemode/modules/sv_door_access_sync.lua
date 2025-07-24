-- Server-side door access synchronization
util.AddNetworkString("BR_SyncDoorAccess")
util.AddNetworkString("BR_RequestDoorAccess")

-- Send door access data to clients when they spawn or when round starts
local function SendDoorAccessData(ply)
    if not MAPBUTTONS then return end
    
    -- Filter only doors with access requirements
    local accessDoors = {}
    for k, v in pairs(MAPBUTTONS) do
        if v.access and v.pos then
            table.insert(accessDoors, {
                pos = v.pos,
                access = v.access,
                name = v.name or "Door"
            })
        end
    end
    
    print("[DOOR ACCESS] Sending " .. #accessDoors .. " doors with access requirements")
    
    net.Start("BR_SyncDoorAccess")
        net.WriteTable(accessDoors)
    if ply then
        net.Send(ply)
        print("[DOOR ACCESS] Sent to player: " .. ply:Nick())
    else
        net.Broadcast()
        print("[DOOR ACCESS] Broadcasted to all players")
    end
end

-- Hook to send data when player spawns
hook.Add("PlayerInitialSpawn", "BR_SendDoorAccess", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            SendDoorAccessData(ply)
        end
    end)
end)

-- Send data when player fully spawns into the game
hook.Add("PlayerSpawn", "BR_SendDoorAccessPlayerSpawn", function(ply)
    -- Wait longer to ensure MAPBUTTONS is loaded
    timer.Simple(2, function()
        if IsValid(ply) and MAPBUTTONS then
            SendDoorAccessData(ply)
        end
    end)
end)

-- Send data when player spawns for the first time after joining
hook.Add("PlayerFullyConnected", "BR_SendDoorAccessConnected", function(ply)
    timer.Simple(3, function()
        if IsValid(ply) and MAPBUTTONS then
            SendDoorAccessData(ply)
        end
    end)
end)

-- Hook to send data when round starts/restarts
hook.Add("BreachStartRound", "BR_SendDoorAccessRound", function()
    timer.Simple(0.5, function()
        SendDoorAccessData()
    end)
end)

-- Also send when preparing phase starts
hook.Add("BreachStartPrep", "BR_SendDoorAccessPrep", function()
    timer.Simple(0.5, function()
        SendDoorAccessData()
    end)
end)

-- Console command to manually sync door access data
concommand.Add("br_sync_doors", function(ply, cmd, args)
    if IsValid(ply) and ply:IsAdmin() then
        print("[DOOR ACCESS] Manual sync requested by " .. ply:Nick())
        SendDoorAccessData()
    end
end)

-- Also try to send data on a timer after map load
timer.Simple(5, function()
    print("[DOOR ACCESS] Initial sync after map load")
    if MAPBUTTONS then
        SendDoorAccessData()
    else
        print("[DOOR ACCESS] MAPBUTTONS not loaded yet, retrying...")
        timer.Simple(5, function()
            if MAPBUTTONS then
                print("[DOOR ACCESS] Delayed sync after map load")
                SendDoorAccessData()
            end
        end)
    end
end)

-- Hook for when the map is initialized
hook.Add("InitPostEntity", "BR_SendDoorAccessInit", function()
    timer.Simple(10, function()
        if MAPBUTTONS then
            print("[DOOR ACCESS] Sync after InitPostEntity")
            SendDoorAccessData()
        end
    end)
end)

-- Allow clients to request door data
net.Receive("BR_RequestDoorAccess", function(len, ply)
    if IsValid(ply) then
        print("[DOOR ACCESS] Client request from " .. ply:Nick())
        timer.Simple(0.1, function()
            if IsValid(ply) and MAPBUTTONS then
                SendDoorAccessData(ply)
            end
        end)
    end
end)