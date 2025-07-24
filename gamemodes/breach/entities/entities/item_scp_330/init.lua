-- SCP-330 server logic dla gamemode Breach
-- Bazowany na oryginalnym kodzie SCP-330 z kompatybilnością Breach

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Sounds that will be used
local CANDY_SOUNDS = {
    pick = "scp_330/pick_candy.mp3",
    consume = "scp_330/consume_candy.mp3",
    cut_hands = "scp_330/cut_hands.mp3",
    deserve = "scp_330/you_got_what_you_deserve.mp3",
    first_contact = "scp_330/on_first_contact.mp3",
    breathing = {
        "scp_330/heavy_breath_1.mp3",
        "scp_330/heavy_breath_2.mp3",
        "scp_330/heavy_breath_3.mp3"
    }
}

-- Candy flavors
local CANDY_FLAVORS = {
    "Strawberry", "Apple", "Cherry", "Orange", "Lemon", "Banana",
    "Raspberry", "Blueberry", "Pineapple", "Melon", "Watermelon",
    "Peach", "Pear", "Apricot", "Plum", "Mango", "Kiwi", "Fig", "Grape", "Hazelnut"
}

function ENT:Initialize()
    self:SetModel("models/scp_330/scp_330.mdl")
    self:RebuildPhysics()
    
    -- Breach compatibility
    self:SetMaxHealth(100)
    self:SetHealth(100)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    -- Entity is now managed by global SCP330 system
end

function ENT:RebuildPhysics()
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:PhysWake()
end

function ENT:PhysicsCollide(data, physobj)
    if data.DeltaTime > 0.2 then
        if data.Speed > 250 then
            self:EmitSound("physics/glass/glass_bottle_impact_hard" .. math.random(1, 3) .. ".wav", 75, math.random(100, 110))
        else
            self:EmitSound("physics/glass/glass_impact_soft" .. math.random(1, 3) .. ".wav", 75, math.random(100, 110))
        end
    end
end

function ENT:Use(ply)
    if not IsValid(ply) then return end
    if not ply:Alive() then return end
    
    -- Block SCP players from taking candy
    local gteam = ply.GTeam and ply:GTeam() or ply:Team()
    if gteam == TEAM_SCP then
        ply:PrintMessage(HUD_PRINTTALK, "[SCP-330] SCPs cannot take candy.")
        return
    end
    
    -- Initialize player data in global system
    SCP330:InitPlayer(ply)
    
    -- Check if player can take candy
    if not SCP330:CanTakeCandy(ply) then
        SCP330:Log("Player " .. ply:Nick() .. " tried to use SCP-330 with cut hands")
        return
    end
    
    -- Check if player has inventory space before giving candy
    local canCarry = true
    if ply.CanCarryWeapon then
        canCarry = ply:CanCarryWeapon("weapon_scp330_candy")
    else
        -- Fallback: allow up to 16 weapons in inventory
        canCarry = (#ply:GetWeapons() < 16)
    end

    if not canCarry then
        ply:PrintMessage(HUD_PRINTTALK, "[SCP-330] You need free inventory space to take candy!")
        return
    end
    
    -- Increment candy count
    local steamID = ply:SteamID64()
    SCP330.PlayerData[steamID].candyTaken = SCP330.PlayerData[steamID].candyTaken + 1
    SCP330.PlayerData[steamID].lastInteraction = CurTime()
    
    local candyCount = SCP330.PlayerData[steamID].candyTaken
    SCP330:Log("Player " .. ply:Nick() .. " is taking candy #" .. candyCount .. " (limit: " .. SCP330.Config.MaxCandies .. ")")
    
    if candyCount > SCP330.Config.MaxCandies then
        -- Cut hands punishment
        SCP330:Log("PUNISHMENT: Player " .. ply:Nick() .. " exceeded limit, cutting hands!")
        self:CutPlayerHands(ply)
    else
        -- Give candy
        SCP330:Log("SAFE: Player " .. ply:Nick() .. " receives candy safely")
        self:GiveCandy(ply)
    end
end

function ENT:CutPlayerHands(ply)
    local steamID = ply:SteamID64()
    SCP330.PlayerData[steamID].handsCut = true
    SCP330.PlayerData[steamID].bleeding = true
    
    -- Sound effects
    ply:EmitSound(CANDY_SOUNDS.cut_hands)
    
    -- Create hand props
    local rightHand = ents.Create("prop_physics")
    local leftHand = ents.Create("prop_physics")
    
    if IsValid(leftHand) then
        leftHand:SetModel("models/scp_330/scp_330_hand.mdl")
        leftHand:SetPos(ply:GetPos() + (-40 * ply:GetRight()))
        leftHand:Spawn()
        
        -- Auto-remove after configured time
        timer.Simple(SCP330.Config.HandRemovalTime, function()
            if IsValid(leftHand) then 
                leftHand:Remove() 
            end
        end)
    end
    
    if IsValid(rightHand) then
        rightHand:SetModel("models/scp_330/scp_330_hand.mdl")
        rightHand:SetPos(ply:GetPos() + (40 * ply:GetRight()))
        rightHand:Spawn()
        
        -- Auto-remove after configured time
        timer.Simple(SCP330.Config.HandRemovalTime, function()
            if IsValid(rightHand) then 
                rightHand:Remove() 
            end
        end)
    end
    
    -- Send message to player
    net.Start("SCP330_PlaySound")
        net.WriteString(CANDY_SOUNDS.deserve)
    net.Send(ply)
    
    -- Apply bleeding effect
    self:StartBleeding(ply)
    
    -- Strip weapons (hands are cut off)
    ply:StripWeapons()
    
    -- Blood decal
    util.Decal("Blood", ply:GetPos() - Vector(0, 0, 1), ply:GetPos() + Vector(0, 0, 1), ply)
    
    -- Log the event
    SCP330:Log("Player " .. ply:Nick() .. " had their hands cut by SCP-330")
end

function ENT:GiveCandy(ply)
    -- Get or create candy weapon
    local candyWeapon = ply:HasWeapon("weapon_scp330_candy") and ply:GetWeapon("weapon_scp330_candy") or ply:Give("weapon_scp330_candy")
    
    if IsValid(candyWeapon) then
        -- Add random candy flavor using global system
        local flavor = SCP330:GetRandomFlavor()
        
        if not candyWeapon.CandyPossessed then
            candyWeapon.CandyPossessed = {}
        end
        
        table.insert(candyWeapon.CandyPossessed, flavor)
        
        -- Send notification
        ply:PrintMessage(HUD_PRINTTALK, "You took a SCP-330 candy with the scent of " .. flavor .. "!")
        
        -- Play sound
        ply:EmitSound(CANDY_SOUNDS.pick, 75, math.random(90, 110))
        
        -- Log the event
        local candyCount = SCP330:GetCandyCount(ply)
        SCP330:Log("Player " .. ply:Nick() .. " took candy #" .. candyCount .. " from SCP-330")
    end
end

function ENT:StartBleeding(ply)
    if not IsValid(ply) then return end
    
    -- Use global configuration
    local bleedInterval = SCP330.Config.BleedInterval
    local bleedDuration = SCP330.Config.BleedDuration
    local bleedDamage = SCP330.Config.BleedDamage
    
    -- Start bleeding timer
    local timerName = "SCP330_Bleeding_" .. ply:EntIndex()
    local tickCount = 0
    local maxTicks = bleedDuration / bleedInterval
    
    timer.Create(timerName, bleedInterval, maxTicks, function()
        if not IsValid(ply) or not ply:Alive() then
            timer.Remove(timerName)
            return
        end
        
        ply:TakeDamage(bleedDamage)
        
        -- Blood effects
        util.Decal("Blood", ply:GetPos() - Vector(0, 0, 1), ply:GetPos() + Vector(0, 0, 1), ply)
        
        -- Send visual effects to client
        net.Start("SCP330_BloodEffect")
        net.Send(ply)
        
        tickCount = tickCount + 1
        if tickCount >= maxTicks then
            timer.Remove(timerName)
            -- Clear hand cut status after bleeding ends using global system
            local steamID = ply:SteamID64()
            if SCP330.PlayerData[steamID] then
                SCP330.PlayerData[steamID].handsCut = false
                SCP330.PlayerData[steamID].bleeding = false
            end
        end
    end)
end

-- Network messages
util.AddNetworkString("SCP330_PlaySound")
util.AddNetworkString("SCP330_BloodEffect")
util.AddNetworkString("SCP330_ProximityWarning")

-- Clean up on player disconnect
hook.Add("PlayerDisconnected", "SCP330_Entity_PlayerCleanup", function(ply)
    -- Remove any bleeding timers
    timer.Remove("SCP330_Bleeding_" .. ply:EntIndex())
end)

-- Clean up on player death/respawn
hook.Add("PlayerDeath", "SCP330_Entity_PlayerDeath", function(ply)
    timer.Remove("SCP330_Bleeding_" .. ply:EntIndex())
end)

hook.Add("PlayerSpawn", "SCP330_Entity_PlayerSpawn", function(ply)
    timer.Remove("SCP330_Bleeding_" .. ply:EntIndex())
end)

-- Note: Weapon pickup prevention is now handled by the global SCP330 module 