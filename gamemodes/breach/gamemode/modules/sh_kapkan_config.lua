KAPKAN_CONFIG = KAPKAN_CONFIG or {
    MaxPlaceDistance = 150,
    MaxUses = 4,
    ExplosionDamage = 95,
    ExplosionDelay = 0.5,
    AllowUndo = true,
    LaserLength = 80,
    MineHealth = 10,
    PlacementDelay = 0.9,
    PlayerCollisions = false
}

local DEFAULT_CONFIG = table.Copy(KAPKAN_CONFIG)

if SERVER then
    AddCSLuaFile()
    
    util.AddNetworkString("UpdateKapkanConfig")
    function UpdateKapkanConfig(ply)
        net.Start("UpdateKapkanConfig")
            net.WriteTable(KAPKAN_CONFIG)
        if ply then net.Send(ply) else net.Broadcast() end
    end
    
    net.Receive("UpdateKapkanConfig", function(len, ply)
        if ply:IsAdmin() then
            KAPKAN_CONFIG = net.ReadTable()
            UpdateKapkanConfig()
            print("[Kapkan] Config updated by "..ply:Name())
        end
    end)
else
    net.Receive("UpdateKapkanConfig", function()
        KAPKAN_CONFIG = net.ReadTable()
    end)
end

hook.Add("PlayerInitialSpawn", "SendKapkanConfig", function(ply)
    if SERVER then
        timer.Simple(5, function()
            if IsValid(ply) then
                UpdateKapkanConfig(ply)
            end
        end)
    end
end) 