-- Weapon Damage Modifiers System
-- Server-side handling

-- Default modifiers table
WEAPON_DAMAGE_MODIFIERS = WEAPON_DAMAGE_MODIFIERS or {}

-- Load saved modifiers from file
local function LoadModifiers()
    if file.Exists("breach/weapon_modifiers.txt", "DATA") then
        local data = file.Read("breach/weapon_modifiers.txt", "DATA")
        if data then
            local tbl = util.JSONToTable(data)
            if tbl then
                WEAPON_DAMAGE_MODIFIERS = tbl
                print("[WEAPON MODIFIERS] Loaded " .. table.Count(WEAPON_DAMAGE_MODIFIERS) .. " weapon modifiers")
            end
        end
    else
        -- Create default modifiers for common CW2.0 weapons
        WEAPON_DAMAGE_MODIFIERS = {
            -- Assault Rifles
            ["cw_ak74"] = { vs_scp = 1.0, vs_human = 1.0 },
            ["cw_ar15"] = { vs_scp = 1.0, vs_human = 1.0 },
            ["cw_m4a1"] = { vs_scp = 1.0, vs_human = 1.0 },
            ["cw_g36c"] = { vs_scp = 1.0, vs_human = 1.0 },
            ["cw_scarh"] = { vs_scp = 1.0, vs_human = 1.0 },
            
            -- SMGs
            ["cw_mp5"] = { vs_scp = 1.0, vs_human = 1.0 },
            ["cw_ump45"] = { vs_scp = 1.0, vs_human = 1.0 },
            ["cw_mac11"] = { vs_scp = 1.0, vs_human = 1.0 },
            
            -- Pistols
            ["cw_deagle"] = { vs_scp = 1.0, vs_human = 1.0 },
            ["cw_fiveseven"] = { vs_scp = 1.0, vs_human = 1.0 },
            ["cw_m1911"] = { vs_scp = 1.0, vs_human = 1.0 },
            ["cw_p99"] = { vs_scp = 1.0, vs_human = 1.0 },
            
            -- Shotguns
            ["cw_m3super90"] = { vs_scp = 1.0, vs_human = 1.0 },
            ["cw_shorty"] = { vs_scp = 1.0, vs_human = 1.0 },
            
            -- Sniper Rifles
            ["cw_l115"] = { vs_scp = 1.0, vs_human = 1.0 },
            ["cw_m14"] = { vs_scp = 1.0, vs_human = 1.0 },
            
            -- Other
            ["cw_m249_official"] = { vs_scp = 1.0, vs_human = 1.0 },
            ["cw_flash_grenade"] = { vs_scp = 1.0, vs_human = 1.0 },
            ["cw_smoke_grenade"] = { vs_scp = 1.0, vs_human = 1.0 },
            ["cw_frag_grenade"] = { vs_scp = 1.0, vs_human = 1.0 }
        }
        SaveModifiers()
    end
end

-- Save modifiers to file
local function SaveModifiers()
    if not file.Exists("breach", "DATA") then
        file.CreateDir("breach")
    end
    
    local data = util.TableToJSON(WEAPON_DAMAGE_MODIFIERS, true)
    file.Write("breach/weapon_modifiers.txt", data)
    print("[WEAPON MODIFIERS] Saved modifiers to file")
end

-- Sync modifiers with clients
util.AddNetworkString("BR_SyncWeaponModifiers")
util.AddNetworkString("BR_RequestWeaponModifiers")
util.AddNetworkString("BR_UpdateWeaponModifier")

local function SyncModifiersToPlayer(ply)
    net.Start("BR_SyncWeaponModifiers")
    net.WriteTable(WEAPON_DAMAGE_MODIFIERS)
    net.Send(ply)
end

-- Send modifiers when player requests them
net.Receive("BR_RequestWeaponModifiers", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    SyncModifiersToPlayer(ply)
end)

-- Update modifier from client
net.Receive("BR_UpdateWeaponModifier", function(len, ply)
    if not ply:IsSuperAdmin() then 
        ply:PrintMessage(HUD_PRINTTALK, "Only super admins can modify weapon damage!")
        return 
    end
    
    local weapon = net.ReadString()
    local vs_scp = net.ReadFloat()
    local vs_human = net.ReadFloat()
    
    -- Validate values
    vs_scp = math.Clamp(vs_scp, 0, 5)
    vs_human = math.Clamp(vs_human, 0, 5)
    
    -- Create entry if it doesn't exist
    if not WEAPON_DAMAGE_MODIFIERS[weapon] then
        WEAPON_DAMAGE_MODIFIERS[weapon] = {}
    end
    
    WEAPON_DAMAGE_MODIFIERS[weapon].vs_scp = vs_scp
    WEAPON_DAMAGE_MODIFIERS[weapon].vs_human = vs_human
    
    SaveModifiers()
    
    -- Sync to all players
    net.Start("BR_SyncWeaponModifiers")
    net.WriteTable(WEAPON_DAMAGE_MODIFIERS)
    net.Broadcast()
    
    ply:PrintMessage(HUD_PRINTTALK, "Updated damage modifiers for " .. weapon)
    print("[WEAPON MODIFIERS] " .. ply:Nick() .. " updated " .. weapon .. " - vs_scp: " .. vs_scp .. ", vs_human: " .. vs_human)
end)

-- Hook into damage system
hook.Add("EntityTakeDamage", "BR_WeaponDamageModifiers", function(target, dmginfo)
    if not target:IsPlayer() or not target:Alive() then return end
    
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    
    local weapon = attacker:GetActiveWeapon()
    if not IsValid(weapon) then return end
    
    local weaponClass = weapon:GetClass()
    local modifiers = WEAPON_DAMAGE_MODIFIERS[weaponClass]
    
    if modifiers then
        local multiplier = 1.0
        
        -- Check if target is SCP or human
        if target:GTeam() == TEAM_SCP then
            multiplier = modifiers.vs_scp or 1.0
        else
            multiplier = modifiers.vs_human or 1.0
        end
        
        if multiplier != 1.0 then
            local originalDmg = dmginfo:GetDamage()
            dmginfo:ScaleDamage(multiplier)
            
            if GetConVar("developer"):GetInt() > 0 then
                print("[WEAPON MODIFIERS] " .. weaponClass .. " damage: " .. originalDmg .. " -> " .. dmginfo:GetDamage() .. " (x" .. multiplier .. ")")
            end
        end
    end
end, HOOK_NORMAL) -- Normal priority to apply before other modifiers

-- Load modifiers on server start
hook.Add("Initialize", "BR_LoadWeaponModifiers", function()
    LoadModifiers()
end)

-- Console commands
concommand.Add("br_reload_weapon_modifiers", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then 
        ply:PrintMessage(HUD_PRINTTALK, "Only super admins can reload weapon modifiers!")
        return 
    end
    
    LoadModifiers()
    
    -- Sync to all players
    net.Start("BR_SyncWeaponModifiers")
    net.WriteTable(WEAPON_DAMAGE_MODIFIERS)
    net.Broadcast()
    
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTTALK, "Reloaded weapon damage modifiers")
    else
        print("[WEAPON MODIFIERS] Reloaded from console")
    end
end)

concommand.Add("br_reset_weapon_modifiers", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then 
        ply:PrintMessage(HUD_PRINTTALK, "Only super admins can reset weapon modifiers!")
        return 
    end
    
    -- Reset all to 1.0
    for weapon, _ in pairs(WEAPON_DAMAGE_MODIFIERS) do
        WEAPON_DAMAGE_MODIFIERS[weapon].vs_scp = 1.0
        WEAPON_DAMAGE_MODIFIERS[weapon].vs_human = 1.0
    end
    
    SaveModifiers()
    
    -- Sync to all players
    net.Start("BR_SyncWeaponModifiers")
    net.WriteTable(WEAPON_DAMAGE_MODIFIERS)
    net.Broadcast()
    
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTTALK, "Reset all weapon damage modifiers to default")
    else
        print("[WEAPON MODIFIERS] Reset all modifiers to default")
    end
end)

-- Initialize on first player join
hook.Add("PlayerInitialSpawn", "BR_SendWeaponModifiers", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then
            SyncModifiersToPlayer(ply)
        end
    end)
end)