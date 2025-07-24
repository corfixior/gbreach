-- Server-side death card system
util.AddNetworkString("BR_ShowDeathCard")

-- Table to track damage between players
local damageTracker = {}

-- Reset damage tracking for a player
local function ResetDamageTracking(ply)
    local steamid = ply:SteamID()
    damageTracker[steamid] = {}
end

-- Track damage dealt
hook.Add("PlayerHurt", "BR_TrackDamage", function(victim, attacker, healthRemaining, damageTaken)
    if not IsValid(victim) or not IsValid(attacker) then return end
    if not victim:IsPlayer() or not attacker:IsPlayer() then return end
    if victim == attacker then return end
    
    local victimID = victim:SteamID()
    local attackerID = attacker:SteamID()
    
    -- Initialize tables if needed
    damageTracker[victimID] = damageTracker[victimID] or {}
    damageTracker[attackerID] = damageTracker[attackerID] or {}
    
    -- Track damage dealt by attacker to victim
    damageTracker[attackerID][victimID] = (damageTracker[attackerID][victimID] or 0) + damageTaken
end)

-- Send death card info when player dies
hook.Add("PlayerDeath", "BR_SendDeathCard", function(victim, inflictor, attacker)
    if not IsValid(victim) then return end
    
    -- Don't show death card for invalid attackers or self-kills
    if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then
        return
    end
    
    local victimID = victim:SteamID()
    local attackerID = attacker:SteamID()
    
    -- Get damage statistics
    local damageDealt = 0
    local damageReceived = 0
    
    if damageTracker[victimID] and damageTracker[victimID][attackerID] then
        damageDealt = damageTracker[victimID][attackerID]
    end
    
    if damageTracker[attackerID] and damageTracker[attackerID][victimID] then
        damageReceived = damageTracker[attackerID][victimID]
    end
    
    -- Get weapon info
    local weaponClass = "Unknown"
    local weaponName = "Unknown"
    
    if IsValid(inflictor) then
        if inflictor:IsWeapon() then
            weaponClass = inflictor:GetClass()
            weaponName = inflictor:GetPrintName() or weaponClass
        elseif inflictor:IsPlayer() then
            local wep = inflictor:GetActiveWeapon()
            if IsValid(wep) then
                weaponClass = wep:GetClass()
                weaponName = wep:GetPrintName() or weaponClass
            end
        else
            weaponClass = inflictor:GetClass()
            weaponName = inflictor:GetClass()
        end
    end
    
    -- Send death card info to victim
    net.Start("BR_ShowDeathCard")
        net.WriteEntity(attacker)
        net.WriteString(weaponClass)
        net.WriteString(weaponName)
        net.WriteUInt(math.Round(damageDealt), 16)
        net.WriteUInt(math.Round(damageReceived), 16)
    net.Send(victim)
    
    -- Reset damage tracking for the victim
    ResetDamageTracking(victim)
end)

-- Reset tracking on spawn
hook.Add("PlayerSpawn", "BR_ResetDamageTracking", function(ply)
    ResetDamageTracking(ply)
end)

-- Clean up on disconnect
hook.Add("PlayerDisconnected", "BR_CleanupDamageTracking", function(ply)
    local steamid = ply:SteamID()
    damageTracker[steamid] = nil
    
    -- Also clean up references to this player in other tables
    for id, damages in pairs(damageTracker) do
        damages[steamid] = nil
    end
end)