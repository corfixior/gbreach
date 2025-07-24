# SCP: Breach Gamemode Documentation

## Overview
SCP: Breach is a Garry's Mod gamemode based on the SCP Foundation universe, featuring multiple teams, classes, and SCP entities. The gamemode emphasizes role-based gameplay with balanced teams and special abilities.

## Game Structure

### Core Files
- `init.lua`: Main initialization file
- `shared.lua`: Shared code between client and server
- `cl_init.lua`: Client-side initialization
- `gamemode/modules/`: Directory containing all modular components

### Game Flow
1. **Initialization**: Game loads and registers all modules
2. **Preparation Phase**: Players spawn and are assigned roles
3. **Active Round**: Main gameplay phase with objectives
4. **Post-Round**: Round cleanup and statistics display
5. **Round Restart**: Map cleanup and new round setup

## Player Classes and Teams

### Team Structure
The gamemode features 7 main teams with distinct roles and objectives:

| Team | Color | Description |
|------|-------|-----------|
| SCP | Red | SCP entities with unique abilities |
| MTF Guards | Blue | Mobile Task Force security personnel |
| Class D | Orange | Test subjects with various roles |
| Scientists | Light Blue | Research staff |
| Chaos Insurgency | Blue | Rebel faction with military equipment |
| GOC | Yellow | Global Occult Coalition |
| Spectators | Green | Dead players and observers |

### Class System
Classes are defined in `sh_classes.lua` with a hierarchical structure:

```lua
ALLCLASSES = {
    classds = { -- Class D Personnel
        roles = {
            {name = ROLES.ROLE_CLASSD, weapons = {"br_holster", "br_id"}, health = 100, walkspeed = 1, runspeed = 1, armor = 0, max = 0},
            {name = ROLES.ROLE_VETERAN, weapons = {"br_holster", "br_id", "weapon_piss"}, health = 120, walkspeed = 1.1, runspeed = 1.1, armor = 0, max = 2},
            -- Additional Class D roles...
        }
    },
    researchers = { -- Scientists
        roles = {
            {name = ROLES.ROLE_RES, weapons = {"br_holster", "br_id"}, health = 100, walkspeed = 1, runspeed = 1, armor = 0, max = 0},
            {name = ROLES.ROLE_MEDIC, weapons = {"br_holster", "br_id", "item_ultramedkit"}, health = 100, walkspeed = 1, runspeed = 1, armor = 0, max = 2},
            -- Additional researcher roles...
        }
    },
    security = { -- MTF Guards
        roles = {
            {name = ROLES.ROLE_SECURITY, weapons = {"br_holster", "br_id", "item_radio", "weapon_stunstick", "cw_mp5"}, health = 100, walkspeed = 0.9, runspeed = 0.95, armor = 0, vest = "armor_security", max = 0},
            {name = ROLES.ROLE_MTFGUARD, weapons = {"br_holster", "br_id", "item_radio", "weapon_stunstick", "cw_mp5"}, health = 100, walkspeed = 0.85, runspeed = 0.92, armor = 0, vest = "armor_mtfguard", max = 10},
            -- Additional security roles...
        }
    },
    support = { -- Armed Site Support
        roles = {
            {name = ROLES.ROLE_MTFNTF, weapons = {"br_holster", "br_id", "item_radio", "item_nvg", "weapon_stunstick", "cw_ar15"}, health = 100, walkspeed = 0.86, runspeed = 0.93, armor = 0, vest = "armor_ntf", max = 5},
            {name = ROLES.ROLE_CHAOS, weapons = {"br_holster", "br_id", "item_radio", "weapon_stunstick", "cw_ak74"}, health = 100, walkspeed = 0.86, runspeed = 0.93, armor = 0, vest = "armor_chaosins", max = 5},
            -- Additional support roles...
        }
    },
    goc = { -- Global Occult Coalition
        roles = {
            {name = ROLES.ROLE_GOC_SOLDIER, weapons = {"br_holster", "br_id", "item_radio", "item_medkit", "weapon_stunstick", "cw_g36c"}, health = 120, walkspeed = 0.9, runspeed = 0.95, armor = 0, vest = "armor_goc", max = 8},
            {name = ROLES.ROLE_GOC_OPERATIVE, weapons = {"br_holster", "br_id", "item_radio", "item_nvg", "item_medkit", "weapon_stunstick", "cw_ar15"}, health = 130, walkspeed = 0.92, runspeed = 0.97, armor = 0, vest = "armor_goc", max = 3},
            -- Additional GOC roles...
        }
    }
}
```

## Key Systems

### Player Management
Player functionality is handled in `sv_player.lua` with extensive meta-table extensions:

```lua
local mply = FindMetaTable("Player")

-- Role assignment based on level and availability
function mply:SetRoleBestFrom(role)
    local thebestone = nil
    for k,v in pairs(ALLCLASSES[role]["roles"]) do
        local can = true
        if v.customcheck != nil then
            if v.customcheck(self) == false then
                can = false
            end
        end
        local using = 0
        for _,pl in pairs(player.GetAll()) do
            if pl:GetNClass() == v.name then
                using = using + 1
            end
        end
        if using >= v.max then can = false end
        if can == true then
            if self:GetLevel() >= v.level then
                if thebestone != nil then
                    if thebestone.level < v.level then
                        thebestone = v
                    end
                else
                    thebestone = v
                end
            end
        end
    end
    if thebestone == nil then
        thebestone = ALLCLASSES[role]["roles"][1]
    end
    self:SetupNormal()
    self:ApplyRoleStats(thebestone)
end
```

### Special Abilities
Several classes have unique passive abilities:

#### D-Class Infected
- **Viral Aura**: Damages players who stay within 50 units for 10+ seconds
- Deals 2 damage per second after exposure threshold
- Visual poison effect

```lua
-- D-CLASS INFECTED PASSIVE ABILITY
-- Viral Aura - damages players who stay too close for too long
local InfectedProximity = {}

timer.Create("DClassInfected_ViralAura", 1, 0, function()
    for _, infected in pairs(player.GetAll()) do
        if IsValid(infected) and infected:Alive() and infected:GetNClass() == ROLES.ROLE_DCLASS_INFECTED then
            local nearbyPlayers = ents.FindInSphere(infected:GetPos(), 50)
            
            for _, ply in pairs(nearbyPlayers) do
                if IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply != infected and ply:GetNClass() != ROLES.ROLE_DCLASS_INFECTED then
                    local steamID = ply:SteamID()
                    
                    if not InfectedProximity[steamID] then
                        InfectedProximity[steamID] = 0
                    end
                    
                    InfectedProximity[steamID] = InfectedProximity[steamID] + 1
                    
                    if InfectedProximity[steamID] >= 10 then
                        ply:SetHealth(ply:Health() - 2)
                        ply:ScreenFade(SCREENFADE.IN, Color(50, 200, 50, 20), 0.5, 0)
                    end
                end
            end
            
            -- Reset timer for players who moved away
            for steamID, time in pairs(InfectedProximity) do
                local ply = player.GetBySteamID(steamID)
                if not IsValid(ply) or not ply:Alive() or ply:GetPos():Distance(infected:GetPos()) > 50 then
                    InfectedProximity[steamID] = 0
                end
            end
        end
    end
end)
```

#### Psychologist
- **Therapeutic Presence**: Healing aura for nearby injured players
- Heals 1 HP per second to players below 50 HP
- Range: 125 units

```lua
-- PSYCHOLOGIST PASSIVE ABILITIES
-- Passive 1: Therapeutic Presence - Healing Aura
timer.Create("Psychologist_TherapeuticPresence", 1, 0, function()
    for _, psychologist in pairs(player.GetAll()) do
        if IsValid(psychologist) and psychologist:Alive() and psychologist:GetNClass() == ROLES.ROLE_PSYCHOLOGIST then
            local nearbyPlayers = ents.FindInSphere(psychologist:GetPos(), 125)
            
            for _, ply in pairs(nearbyPlayers) do
                if IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply != psychologist then
                    local team = ply:GTeam()
                    local class = ply:GetNClass()
                    
                    if team == TEAM_SCI or team == TEAM_GUARD or (team == TEAM_CHAOS and class == ROLES.ROLE_CHAOSSPY) then
                        local currentHP = ply:Health()
                        if currentHP < 50 and currentHP > 0 then
                            ply:SetHealth(math.min(currentHP + 1, 50))
                        end
                    end
                end
            end
        end
    end
end)
```

#### Thief D
- **Weapon Theft**: Steal active weapon from other players
- 60-second cooldown
- Cannot steal from SCPs or self

```lua
-- THIEF D PASSIVE ABILITY
-- Weapon Theft - steal active weapon from other players
hook.Add("PlayerUse", "ThiefD_WeaponTheft", function(ply, ent)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(ent) or not ent:IsPlayer() then return end
    if preparing or postround then return end
    
    if ply:GetNClass() != ROLES.ROLE_THIEF_D then return end
    
    if ply.ThiefNextSteal and ply.ThiefNextSteal > CurTime() then
        local timeLeft = math.ceil(ply.ThiefNextSteal - CurTime())
        ply:PrintMessage(HUD_PRINTCENTER, "Theft on cooldown: " .. timeLeft .. "s")
        return false
    end
    
    if ent:GTeam() == TEAM_SCP then 
        return false
    end
    
    if ply == ent then return end
    
    local distance = ply:GetPos():Distance(ent:GetPos())
    if distance > 50 then
        return false
    end
    
    local targetWeapon = ent:GetActiveWeapon()
    if not IsValid(targetWeapon) then 
        return false
    end
    
    local weaponClass = targetWeapon:GetClass()
    
    if weaponClass == "br_holster" or weaponClass == "br_tag" then
        return false
    end
    
    if ply:HasWeapon(weaponClass) then
        return false
    end
    
    local weaponAmmo = 0
    local ammoType = targetWeapon:GetPrimaryAmmoType()
    if ammoType and ammoType != -1 then
        weaponAmmo = ent:GetAmmoCount(ammoType)
    end
    
    local keycardType = nil
    if weaponClass == "br_keycard" then
        keycardType = targetWeapon:GetNWString("K_TYPE", "safe")
    end
    
    ent:StripWeapon(weaponClass)
    
    local newWeapon = ply:Give(weaponClass)
    if IsValid(newWeapon) then
        if weaponClass == "br_keycard" and keycardType then
            newWeapon:SetKeycardType(keycardType)
        end
        
        if ammoType and ammoType != -1 and weaponAmmo > 0 then
            ply:GiveAmmo(weaponAmmo, ammoType)
        end
    end
    
    ply:SelectWeapon(weaponClass)
    ply.ThiefNextSteal = CurTime() + 60
    
    ply:ScreenFade(SCREENFADE.IN, Color(255, 255, 0, 20), 0.3, 0)
    ent:ScreenFade(SCREENFADE.IN, Color(255, 0, 0, 30), 0.5, 0)
    
    ply:EmitSound("buttons/button14.wav", 50, 120)
    ent:EmitSound("buttons/button10.wav", 50, 80)
    
    return false
end)
```

#### Dr. House
- **Death Harvest**: Gains 10 HP when someone dies within 300 units
- Healing is capped at maximum health

```lua
-- DR. HOUSE PASSIVE ABILITY
-- Death Harvest - gains 10 HP when someone nearby dies
hook.Add("PostPlayerDeath", "DrHouse_DeathHarvest", function(victim, inflictor, attacker)
    if not IsValid(victim) or not victim:IsPlayer() then return end
    if preparing or postround then return end
    
    for _, drhouse in pairs(player.GetAll()) do
        if IsValid(drhouse) and drhouse:Alive() and drhouse:GetNClass() == ROLES.ROLE_DRHOUSE then
            local distance = drhouse:GetPos():Distance(victim:GetPos())
            
            if distance <= 300 then
                local currentHP = drhouse:Health()
                local maxHP = drhouse:GetMaxHealth()
                local newHP = math.min(currentHP + 10, maxHP)
                
                drhouse:SetHealth(newHP)
                drhouse:PrintMessage(HUD_PRINTTALK, "[DR. HOUSE] Death nearby healed you for " .. (newHP - currentHP) .. " HP!")
                drhouse:ScreenFade(SCREENFADE.IN, Color(0, 255, 0, 30), 0.5, 0)
            end
        end
    end
end)
```

## SCP System

### SCP Registration
SCPs are registered using the `RegisterSCP` function in `sv_base_scps.lua`:

```lua
RegisterSCP( "SCP023", "models/Novux/023/Novux_SCP-023.mdl", "weapon_scp_023", {
    jump_power = 200,
    prep_freeze = true,
}, {
    base_health = 2000,
    max_health = 2000,
    base_speed = 150,
    run_speed = 250,
    max_speed = 250,
} )
```

### SCP Properties
Each SCP has configurable properties:

| Property | Description |
|----------|-------------|
| `jump_power` | Jump height multiplier |
| `prep_freeze` | Prevents movement during preparation phase |
| `no_ragdoll` | Prevents ragdoll on death |
| `model_scale` | Player model scale |
| `hands_model` | Custom hands model |
| `no_spawn` | Prevents position change on spawn |
| `no_model` | Prevents model change |
| `no_swep` | Prevents weapon assignment |
| `no_strip` | Prevents weapon stripping |
| `no_select` | Hides from player selection |

## Round Management

### Round Phases
The round system in `sv_round.lua` manages three main phases:

1. **Preparation Phase**: 
   - Duration controlled by `br_time_preparing` convar
   - Players are frozen and assigned roles
   - Teams are balanced based on player count

2. **Active Round**:
   - Duration controlled by `br_time_round` convar
   - Main gameplay with objectives
   - Win conditions checked periodically

3. **Post-Round**:
   - Duration controlled by `br_time_post` convar
   - Statistics displayed
   - Round restarts after timer completion

### Team Balancing
The team balancing algorithm in `sv_round_setup.lua` distributes players based on total count:

```lua
function GetRoleTable( all )
    local scp = 0
    local mtf = 0
    local res = 0

    if all < 9 then
        scp = 1
    elseif all < 15 then
        scp = 2
    else
        scp = math.floor( ( all - 14 ) / 7 ) + 3
    end
    
    all = all - scp
    
    mtf = math.Round( all * 0.3 )
    
    all = all - mtf
    
    res = math.floor( all * 0.3 )
    all = all - res
    
    return {scp, mtf, res, all}
end
```

## Special Items

### SCP-207
- **Function**: Speed and jump boost
- **Effect**: +25% speed and jump per bottle consumed
- **Stacking**: Effects are cumulative
- **Implementation**: Server-side tracking in `sv_scp207.lua`

### SCP-330
- **Function**: Candy dispenser with consequences
- **Mechanics**:
  - Players can take up to 2 candies
  - Taking more than 2 results in hands being cut off
  - Cut hands prevent weapon use and interactions
- **Implementation**: Server-side tracking in `sv_scp330.lua`

### SCP-1123
- **Function**: Skull of Memories
- **Effect**: Allows player to see through another player's eyes
- **Implementation**: Server-side tracking in `sv_scp1123.lua`

## Networking

### Key Network Strings
- `BR_UpdateVest`: Updates client vest display
- `NVG_Toggle`: Controls NVG state
- `TranslatedMessage`: Sends localized messages
- `DropWeapon`: Client request to drop weapon
- `RolesSelected`: Notifies clients that roles are assigned
- `UpdateRoundType`: Updates client with current round type
- `PrepStart`: Notifies clients that preparation phase starts
- `RoundStart`: Notifies clients that round starts
- `PostStart`: Notifies clients that post-round starts

## Configuration

### ConVars
Key configuration variables include:

| ConVar | Default | Description |
|--------|---------|-----------|
| `br_min_players` | 2 | Minimum players to start round |
| `br_time_preparing` | 30 | Preparation phase duration |
| `br_time_round` | 600 | Main round duration |
| `br_time_post` | 15 | Post-round duration |
| `br_scp_penalty` | 2 | SCP penalty duration |
| `br_premium_penalty` | 1 | Premium player SCP penalty |
| `br_specialround_pct` | 15 | Chance of special round |
| `br_expscale` | 1 | Experience scaling factor |
| `br_premium_mult` | 1.5 | Premium experience multiplier |

## Player Progression

### Level System
Players gain experience and level up:

```lua
function mply:AddExp(amount, msg)
    amount = amount * GetConVar("br_expscale"):GetInt()
    if self.Premium == true then
        amount = amount * GetConVar("br_premium_mult"):GetFloat()
    end
    amount = math.Round(amount)
    
    if not self.GetNEXP then
        player_manager.RunClass( self, "SetupDataTables" )
    end
    
    if self.GetNEXP and self.SetNEXP then
        self:SetNEXP( self:GetNEXP() + amount )
        local xp = self:GetNEXP()
        local lvl = self:GetNLevel()
        
        if lvl == 0 then
            if xp >= 3000 then
                self:AddLevel(1)
                self:SetNEXP(xp - 3000)
                self:SaveLevel()
                PrintMessage(HUD_PRINTTALK, self:Nick() .. " reached level 1! Congratulations!")
            end
        elseif lvl == 1 then
            if xp >= 5000 then
                self:AddLevel(1)
                self:SetNEXP(xp - 5000)
                self:SaveLevel()
                PrintMessage(HUD_PRINTTALK, self:Nick() .. " reached level 2! Congratulations!")
            end
        -- Additional level thresholds...
        end
    end
end
```

## Conclusion
SCP: Breach is a well-structured gamemode with a comprehensive class system, balanced team mechanics, and unique special abilities. The codebase shows good organization with proper separation of concerns between client and server code, effective use of hooks, and robust networking for multiplayer synchronization.