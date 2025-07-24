-- SCP-330 Server Module dla gamemode Breach
-- Zarządza funkcjonalnością SCP-330

-- SCP-330 Global functions
SCP330 = SCP330 or {}

-- Configuration
SCP330.Config = {
    MaxCandies = 2,
    BleedDamage = 5,
    BleedInterval = 10,
    BleedDuration = 900, -- 15 minutes
    ProximityRadius = 150,
    HandRemovalTime = 300, -- 5 minutes
    CandyHealAmount = 10 -- HP healed per candy
}

-- Candy flavors
SCP330.CandyFlavors = {
    "Strawberry", "Apple", "Cherry", "Orange", "Lemon", "Banana",
    "Raspberry", "Blueberry", "Pineapple", "Melon", "Watermelon", 
    "Peach", "Pear", "Apricot", "Plum", "Mango", "Kiwi", "Fig", "Grape", "Hazelnut"
}

-- Global tracking
SCP330.PlayerData = {}

-- Initialize player data
function SCP330:InitPlayer(ply)
    if not IsValid(ply) then return end
    local steamID = ply:SteamID64()
    if not self.PlayerData[steamID] then
        self.PlayerData[steamID] = {
            candyTaken = 0,
            handsCut = false,
            bleeding = false,
            lastInteraction = 0
        }
    end
end

-- Get random candy flavor
function SCP330:GetRandomFlavor()
    return self.CandyFlavors[math.random(#self.CandyFlavors)]
end

-- Reset player data
function SCP330:ResetPlayer(ply)
    local steamID = ply:SteamID64()
    if self.PlayerData[steamID] then
        self.PlayerData[steamID] = {
            candyTaken = 0,
            handsCut = false,
            bleeding = false,
            lastInteraction = 0
        }
    end
    
    -- Remove bleeding timer
    timer.Remove("SCP330_Bleeding_" .. ply:EntIndex())
    
    -- Remove all SCP-330 candy weapons from player's inventory
    if IsValid(ply) then
        for _, weapon in pairs(ply:GetWeapons()) do
            if IsValid(weapon) and weapon:GetClass() == "weapon_scp330_candy" then
                ply:StripWeapon("weapon_scp330_candy")
            end
        end
    end
end

-- Check if player can take candy (only blocks if hands are cut)
function SCP330:CanTakeCandy(ply)
    local steamID = ply:SteamID64()
    local data = self.PlayerData[steamID]
    
    if not data then return true end
    if data.handsCut then return false end
    
    -- Allow taking candy even if over limit (punishment will be applied)
    return true
end

-- Get player candy count
function SCP330:GetCandyCount(ply)
    local steamID = ply:SteamID64()
    local data = self.PlayerData[steamID]
    return data and data.candyTaken or 0
end

-- Player hooks
hook.Add("PlayerInitialSpawn", "SCP330_PlayerInit", function(ply)
    SCP330:InitPlayer(ply)
end)

hook.Add("PlayerDeath", "SCP330_Module_PlayerDeath", function(ply)
    SCP330:ResetPlayer(ply)
end)

hook.Add("PlayerSpawn", "SCP330_Module_PlayerSpawn", function(ply)
    SCP330:ResetPlayer(ply)
end)

hook.Add("PlayerDisconnected", "SCP330_Module_PlayerDisconnect", function(ply)
    timer.Remove("SCP330_Bleeding_" .. ply:EntIndex())
end)

-- Prevent weapon pickup with cut hands
hook.Add("PlayerCanPickupWeapon", "SCP330_PreventPickup", function(ply, weapon)
    SCP330:InitPlayer(ply)
    local steamID = ply:SteamID64()
    local data = SCP330.PlayerData[steamID]
    
    if data and data.handsCut then
        return false
    end
end)

-- Prevent all USE interactions with cut hands (doors, props, buttons, etc.)
hook.Add("PlayerUse", "SCP330_PreventUse", function(ply, entity)
    SCP330:InitPlayer(ply)
    local steamID = ply:SteamID64()
    local data = SCP330.PlayerData[steamID]
    
    if data and data.handsCut then
        -- Allow using SCP-330 itself so players can see the "can't use" message
        if entity:GetClass() == "item_scp_330" then
            return true
        end
        
        -- Block all other interactions (silent)
        return false
    end
end)

-- Prevent picking up any entities/items with cut hands
hook.Add("AllowPlayerPickup", "SCP330_PreventEntityPickup", function(ply, entity)
    SCP330:InitPlayer(ply)
    local steamID = ply:SteamID64()
    local data = SCP330.PlayerData[steamID]
    
    if data and data.handsCut then
        -- Block pickup silently
        return false
    end
end)

-- Prevent dropping weapons/items with cut hands (since they can't hold anything)
hook.Add("PlayerDropWeapon", "SCP330_PreventDrop", function(ply, weapon)
    SCP330:InitPlayer(ply)
    local steamID = ply:SteamID64()
    local data = SCP330.PlayerData[steamID]
    
    if data and data.handsCut then
        -- This shouldn't happen since they can't have weapons, but just in case
        return false
    end
end)

-- Admin commands
if SERVER then
    concommand.Add("scp330_spawn", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local trace = ply:GetEyeTrace()
        local pos = trace.HitPos + trace.HitNormal * 5
        
        local scp330 = ents.Create("item_scp_330")
        if IsValid(scp330) then
            scp330:SetPos(pos)
            scp330:Spawn()
            
            print("[ADMIN] " .. ply:Nick() .. " spawned SCP-330 at " .. tostring(pos))
            ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] SCP-330 spawned successfully!")
        end
    end)
    
    concommand.Add("scp330_reset_player", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local target = args[1]
        if not target then
            ply:PrintMessage(HUD_PRINTTALK, "Usage: scp330_reset_player <player_name>")
            return
        end
        
        local targetPly = nil
        for _, p in pairs(player.GetAll()) do
            if string.find(string.lower(p:Nick()), string.lower(target)) then
                targetPly = p
                break
            end
        end
        
        if not targetPly then
            ply:PrintMessage(HUD_PRINTTALK, "Player not found!")
            return
        end
        
        SCP330:ResetPlayer(targetPly)
        print("[ADMIN] " .. ply:Nick() .. " reset SCP-330 data for " .. targetPly:Nick())
        ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] Reset SCP-330 data for " .. targetPly:Nick())
    end)
    
    concommand.Add("scp330_info", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        ply:PrintMessage(HUD_PRINTTALK, "=== SCP-330 Information ===")
        ply:PrintMessage(HUD_PRINTTALK, "Active SCP-330 entities: " .. #ents.FindByClass("item_scp_330"))
        ply:PrintMessage(HUD_PRINTTALK, "Candy healing amount: " .. SCP330.Config.CandyHealAmount .. " HP")
        ply:PrintMessage(HUD_PRINTTALK, "Max candies allowed: " .. SCP330.Config.MaxCandies)
        
        local activeBleeders = 0
        local cutHands = 0
        
        for steamID, data in pairs(SCP330.PlayerData) do
            if data.bleeding then activeBleeders = activeBleeders + 1 end
            if data.handsCut then cutHands = cutHands + 1 end
        end
        
        ply:PrintMessage(HUD_PRINTTALK, "Players with cut hands: " .. cutHands)
        ply:PrintMessage(HUD_PRINTTALK, "Players currently bleeding: " .. activeBleeders)
    end)
    
    concommand.Add("scp330_check_player", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local target = args[1] or ply:Nick()
        local targetPly = nil
        
        for _, p in pairs(player.GetAll()) do
            if string.find(string.lower(p:Nick()), string.lower(target)) then
                targetPly = p
                break
            end
        end
        
        if not targetPly then
            ply:PrintMessage(HUD_PRINTTALK, "Player not found!")
            return
        end
        
        SCP330:InitPlayer(targetPly)
        local steamID = targetPly:SteamID64()
        local data = SCP330.PlayerData[steamID]
        
        ply:PrintMessage(HUD_PRINTTALK, "=== " .. targetPly:Nick() .. " SCP-330 Status ===")
        ply:PrintMessage(HUD_PRINTTALK, "Candies taken: " .. data.candyTaken)
        ply:PrintMessage(HUD_PRINTTALK, "Hands cut: " .. tostring(data.handsCut))
        ply:PrintMessage(HUD_PRINTTALK, "Bleeding: " .. tostring(data.bleeding))
        ply:PrintMessage(HUD_PRINTTALK, "Can take candy: " .. tostring(SCP330:CanTakeCandy(targetPly)))
    end)
    
    concommand.Add("scp330_spawn_table", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local success = SCP330:SpawnAtTable()
        if success then
            ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] SCP-330 spawned on table at cafeteria")
        else
            ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] SCP-330 table spawn failed")
        end
    end)
    
    concommand.Add("scp330_force_spawn_table", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local tablePos = Vector(2110.566406, -1492.138428, 15.031254)
        local scp330Pos = Vector(2111.600830, -1491.158447, 33.602257)
        local spawnAngles = Angle(0, 0, 0)
        
        -- Remove existing
        for _, ent in pairs(ents.FindByClass("item_scp_330")) do
            ent:Remove()
        end
        
        -- Force spawn table (100% chance)
        local table = ents.Create("prop_physics")
        if IsValid(table) then
            table:SetModel("models/props_c17/FurnitureTable001a.mdl")
            table:SetPos(tablePos)
            table:SetAngles(spawnAngles)
            table:Spawn()
            
            -- Make it indestructible and immovable
            if IsValid(table:GetPhysicsObject()) then
                table:GetPhysicsObject():EnableMotion(false)
            end
            table:SetHealth(999999) -- High health
            table:SetMaxHealth(999999)
            table.TakeDamage = function() end -- Override damage function
            table:SetName("SCP330_Table") -- Give it a name for identification
        end
        
        -- Force spawn SCP-330 at separate location
        local scp330 = ents.Create("item_scp_330")
        if IsValid(scp330) then
            scp330:SetPos(scp330Pos)
            scp330:SetAngles(spawnAngles)
            scp330:Spawn()
            
            -- Make SCP-330 immovable and indestructible
            if IsValid(scp330:GetPhysicsObject()) then
                scp330:GetPhysicsObject():EnableMotion(false) -- Make it static
            end
            scp330:SetHealth(999999) -- High health
            scp330:SetMaxHealth(999999)
            scp330.TakeDamage = function() end -- Override damage function
            scp330:SetName("SCP330_Bowl") -- Give it a name for identification
            
            ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] SCP-330 and table force spawned at separate locations")
            print("[ADMIN] " .. ply:Nick() .. " force spawned SCP-330 and table")
            print("[ADMIN] Table at: " .. tostring(tablePos))
            print("[ADMIN] SCP-330 at: " .. tostring(scp330Pos))
        end
    end)
    
    concommand.Add("scp330_reset_all", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local resetCount = 0
        for _, p in pairs(player.GetAll()) do
            if IsValid(p) then
                SCP330:ResetPlayer(p)
                resetCount = resetCount + 1
            end
        end
        
        ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] Reset SCP-330 data for " .. resetCount .. " players")
        print("[ADMIN] " .. ply:Nick() .. " reset SCP-330 data for all " .. resetCount .. " players")
    end)
    
    concommand.Add("scp330_debug_hooks", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        ply:PrintMessage(HUD_PRINTTALK, "=== SCP-330 Hook Debug ===")
        ply:PrintMessage(HUD_PRINTTALK, "Available hooks:")
        ply:PrintMessage(HUD_PRINTTALK, "- SCP330_Module_PlayerInit (PlayerInitialSpawn)")
        ply:PrintMessage(HUD_PRINTTALK, "- SCP330_Module_PlayerDeath (PlayerDeath)")
        ply:PrintMessage(HUD_PRINTTALK, "- SCP330_Module_PlayerSpawn (PlayerSpawn)")
        ply:PrintMessage(HUD_PRINTTALK, "- SCP330_ResetAllPlayers (BreachPreround)")
        ply:PrintMessage(HUD_PRINTTALK, "- SCP330_CleanupReset (OnCleanup)")
        
        -- Test manual reset
        SCP330:ResetPlayer(ply)
        ply:PrintMessage(HUD_PRINTTALK, "Manual reset executed on you")
    end)
    
    concommand.Add("scp330_set_heal", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local amount = tonumber(args[1])
        if not amount or amount < 0 or amount > 100 then
            ply:PrintMessage(HUD_PRINTTALK, "Usage: scp330_set_heal <amount> (0-100)")
            ply:PrintMessage(HUD_PRINTTALK, "Current healing amount: " .. SCP330.Config.CandyHealAmount .. " HP")
            return
        end
        
        SCP330.Config.CandyHealAmount = amount
        ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] SCP-330 candy healing set to " .. amount .. " HP")
        print("[ADMIN] " .. ply:Nick() .. " set SCP-330 candy healing to " .. amount .. " HP")
    end)
end

-- Network strings
util.AddNetworkString("SCP330_PlaySound")
util.AddNetworkString("SCP330_BloodEffect")
util.AddNetworkString("SCP330_ProximityWarning")

-- Helper function for logging
function SCP330:Log(message, category)
    -- Use simple print logging like other Breach modules
    print("[SCP-330] " .. message)
end

-- Spawn SCP-330 and table at separate locations
function SCP330:SpawnAtTable()
    local tablePos = Vector(2110.566406, -1492.138428, 15.031254)
    local scp330Pos = Vector(2111.600830, -1491.158447, 33.602257)
    local spawnAngles = Angle(0, 0, 0)
    
    -- Remove any existing SCP-330 entities first
    for _, ent in pairs(ents.FindByClass("item_scp_330")) do
        ent:Remove()
    end
    
    -- 25% chance to spawn
    if math.random(100) <= 25 then
        -- Spawn table prop at its location
        local table = ents.Create("prop_physics")
        if IsValid(table) then
            table:SetModel("models/props_c17/FurnitureTable001a.mdl")
            table:SetPos(tablePos)
            table:SetAngles(spawnAngles)
            table:Spawn()
            
            -- Make it indestructible and immovable
            if IsValid(table:GetPhysicsObject()) then
                table:GetPhysicsObject():EnableMotion(false) -- Make it static
            end
            table:SetHealth(999999) -- High health
            table:SetMaxHealth(999999)
            table.TakeDamage = function() end -- Override damage function
            table:SetName("SCP330_Table") -- Give it a name for identification
        end
        
        -- Spawn SCP-330 at its separate location
        local scp330 = ents.Create("item_scp_330")
        if IsValid(scp330) then
            scp330:SetPos(scp330Pos)
            scp330:SetAngles(spawnAngles)
            scp330:Spawn()
            
            -- Make SCP-330 immovable and indestructible
            if IsValid(scp330:GetPhysicsObject()) then
                scp330:GetPhysicsObject():EnableMotion(false) -- Make it static
            end
            scp330:SetHealth(999999) -- High health
            scp330:SetMaxHealth(999999)
            scp330.TakeDamage = function() end -- Override damage function
            scp330:SetName("SCP330_Bowl") -- Give it a name for identification
            
            SCP330:Log("SCP-330 and table spawned at separate locations (25% chance triggered)")
            SCP330:Log("Table at: " .. tostring(tablePos))
            SCP330:Log("SCP-330 at: " .. tostring(scp330Pos))
            return true
        end
    else
        SCP330:Log("SCP-330 and table spawn skipped (75% chance)")
        return false
    end
end

-- Auto-spawn on round start
hook.Add("PostCleanupMap", "SCP330_AutoSpawn", function()
    timer.Simple(2, function() -- Small delay to ensure map is fully loaded
        SCP330:SpawnAtTable()
    end)
end)

-- Alternative hook for round restarts
hook.Add("RoundRestart", "SCP330_RoundRestart", function()
    timer.Simple(2, function()
        SCP330:SpawnAtTable()
    end)
end)

-- Reset all players at round start (Breach-specific hook)
hook.Add("BreachPreround", "SCP330_ResetAllPlayers", function()
    print("[SCP-330] Resetting all players for new round...")
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) then
            SCP330:ResetPlayer(ply)
        end
    end
    SCP330:Log("All players reset for new round")
end)

-- Additional cleanup hook
hook.Add("OnCleanup", "SCP330_CleanupReset", function()
    print("[SCP-330] Map cleanup - resetting all players...")
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) then
            SCP330:ResetPlayer(ply)
        end
    end
    SCP330:Log("All players reset on map cleanup")
end)

-- Protect SCP-330 table and bowl from damage and removal
hook.Add("EntityTakeDamage", "SCP330_ProtectEntities", function(ent, dmg)
    if IsValid(ent) and (ent:GetName() == "SCP330_Table" or ent:GetName() == "SCP330_Bowl") then
        dmg:SetDamage(0) -- No damage
        return true -- Block damage
    end
end)

-- Prevent table and bowl removal
hook.Add("CanProperty", "SCP330_PreventProperty", function(ply, property, ent)
    if IsValid(ent) and (ent:GetName() == "SCP330_Table" or ent:GetName() == "SCP330_Bowl") then
        return false -- Block all property interactions (remove, etc.)
    end
end)

-- Additional protection against physgun
hook.Add("PhysgunPickup", "SCP330_PreventPhysgun", function(ply, ent)
    if IsValid(ent) and (ent:GetName() == "SCP330_Table" or ent:GetName() == "SCP330_Bowl") then
        return false -- Can't pick up with physgun
    end
end)

-- Prevent gravgun interactions
hook.Add("GravGunPunt", "SCP330_PreventGravGun", function(ply, ent)
    if IsValid(ent) and (ent:GetName() == "SCP330_Table" or ent:GetName() == "SCP330_Bowl") then
        return false -- Can't punt with gravgun
    end
end)

hook.Add("GravGunPickupAllowed", "SCP330_PreventGravGunPickup", function(ply, ent)
    if IsValid(ent) and (ent:GetName() == "SCP330_Table" or ent:GetName() == "SCP330_Bowl") then
        return false -- Can't pick up with gravgun
    end
end)

print("[SCP-330] Server module loaded successfully!") 