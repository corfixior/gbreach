-- SCP-207 Module for SCP: Breach
-- Based on original SCP-207 addon by MrMarrant
-- Adapted for Breach gamemode

-- Global SCP-207 system
scp_207 = scp_207 or {}
SCP_207_CONFIG = SCP_207_CONFIG or {}
SCP_207_LANG = SCP_207_LANG or {}

-- Configuration
SCP_207_CONFIG.TimeDecay = CreateConVar( "breach_scp207_time_decay", 60, {FCVAR_PROTECTED, FCVAR_ARCHIVE}, "Time in seconds for each cycle", 1, 300 )
SCP_207_CONFIG.MaxLoop = 48 -- Max loop of the effect from SCP207
SCP_207_CONFIG.IncrementStat = CreateConVar( "breach_scp207_increment_stat", 0.1, {FCVAR_PROTECTED, FCVAR_ARCHIVE}, "The increment stat for walking/running speed", 0.01, 1 )
SCP_207_CONFIG.IncrementStatJump = 0.05
SCP_207_CONFIG.IncrementChanceDeath = 2
SCP_207_CONFIG.InitialChanceInstantDeath = 0
SCP_207_CONFIG.RadiusCollisionDoor = 30
SCP_207_CONFIG.VelocityMinDestroyDoor = 300
SCP_207_CONFIG.DamageTakeBreakingDoor = 20
SCP_207_CONFIG.DisabledInstantKill = CreateConVar( "breach_scp207_disabled_instant_kill", 0, {FCVAR_PROTECTED, FCVAR_ARCHIVE}, "If enable, disabled the instant death", 0, 1 )
SCP_207_CONFIG.PlayersCanBreakDoors = {}

-- Network strings
SCP_207_CONFIG.TextToSendToServer = "SCP207_TextToServer"
SCP_207_CONFIG.StartOverlayEffect = "SCP207_StartOverlay"
SCP_207_CONFIG.RemoveOverlayEffect = "SCP207_RemoveOverlay"

-- Add network strings
util.AddNetworkString(SCP_207_CONFIG.TextToSendToServer)
util.AddNetworkString(SCP_207_CONFIG.StartOverlayEffect)
util.AddNetworkString(SCP_207_CONFIG.RemoveOverlayEffect)

-- Door classes for breaking
SCP_207_CONFIG.DoorClass = {
    prop_door_rotating = true,
    func_door = true,
    func_door_rotating = true
}

-- Job restrictions (can be configured per team)
SCP_207_CONFIG.JobNotAllowed = {
    ["SCP"] = true, -- Block SCPs from using SCP-207
}

-- Effect states configuration
SCP_207_CONFIG.TableStateEffect = {
    [5] = { PrintMessageInfo = "You feel more energetic..." },
    [10] = { PrintMessageInfo = "Your heart rate increases..." },
    [15] = { PrintMessageInfo = "You feel extremely energized!", StartOverlayEffect = true },
    [20] = { PrintMessageInfo = "You can break doors!", EventDoorsDestroyable = true },
    [25] = { PrintMessageInfo = "Your vision becomes blurry..." },
    [30] = { PrintMessageInfo = "Warning: Heart palpitations detected!" },
    [35] = { PrintMessageInfo = "DANGER: Cardiac stress critical!" },
    [40] = { PrintMessageInfo = "CRITICAL: Imminent cardiac failure!" },
    [45] = { PrintMessageInfo = "FINAL WARNING: Death imminent!" }
}

-- Drop SCP-207 function
function scp_207.DropSCP207(ply, ent)
	if (!IsValid(ply) or !IsValid(ent)) then return end
	local LookForward = ply:EyeAngles():Forward()
	local LookUp = ply:EyeAngles():Up()
	local SCP207 = ents.Create( "scp_207" )
	local DistanceToPos = 50
	local PosObject = ply:GetShootPos() + LookForward * DistanceToPos + LookUp
    PosObject.z = ply:GetPos().z

	SCP207:SetPos( PosObject )
	SCP207:SetAngles( ply:EyeAngles() )
	SCP207:Spawn()
	SCP207:Activate()
	ent:Remove()
end

-- Consume SCP-207 function
function scp_207.ConsumeSCP207(ply)
	if (!IsValid(ply)) then return end

	-- Initialize SCP-207 data if first time
	if not ply.HasDrinkSCP207 then
		ply.HasDrinkSCP207 = true
		ply.scp207_Stack = 0
		scp_207.GetPreviousStatPlayer(ply)
	end
	
	-- Increase stack count
	ply.scp207_Stack = ply.scp207_Stack + 1
	
	-- Calculate new multiplier (each bottle adds 25%)
	local multiplier = 1 + (ply.scp207_Stack * 0.25)
	
	-- Apply cumulative boost based on original stats
	local walkSpeed = ply.scp207_PreviousInfoData.WalkSpeed
	local runSpeed = ply.scp207_PreviousInfoData.RunSpeed
	local jumpPower = ply.scp207_PreviousInfoData.JumpPower
	
	ply:SetWalkSpeed(walkSpeed * multiplier)
	ply:SetRunSpeed(runSpeed * multiplier)
	ply:SetJumpPower(jumpPower * multiplier)
    
    local boostPercent = (multiplier - 1) * 100
    print("[BREACH SCP-207] " .. ply:Nick() .. " consumed SCP-207 x" .. ply.scp207_Stack .. " (+" .. boostPercent .. "% speed/jump boost)")
end

-- Apply state effects (simplified - no effects needed)
function scp_207.ApplyStateEffect(ply, index)
    -- No effects needed for simple speed boost
    return
end

-- Get previous player stats
function scp_207.GetPreviousStatPlayer(ply)
    if (!IsValid(ply)) then return end

    ply.scp207_PreviousInfoData = {
        WalkSpeed = ply:GetWalkSpeed(),
        RunSpeed = ply:GetRunSpeed(),
        JumpPower = ply:GetJumpPower(),
    }
end

-- Increment player stats (not needed for simple boost)
function scp_207.IncrementStat(ply)
    -- No incremental stats needed for simple 25% boost
    return
end

-- Instant death function
function scp_207.InstanDeath(ply, percent)
    if (percent >= math.Rand(1, 100)) then 
        ply:Kill() 
        print("[BREACH SCP-207] " .. ply:Nick() .. " died from SCP-207 cardiac failure")
    end
end

-- Print message to player (not needed)
function scp_207.PrintMessageInfo(ply, text)
	-- No messages needed for simple boost
	return
end

-- Start overlay effect (not needed)
function scp_207.StartOverlayEffect(ply, index)
	-- No overlay needed for simple boost
	return
end

-- Remove overlay effect (not needed)
function scp_207.RemoveOverlayEffect(ply)
	-- No overlay to remove
	return
end

-- Event: Door destructible
function scp_207.EventDoorsDestroyable(ply)
	if (!IsValid(ply)) then return end

	if (table.IsEmpty( SCP_207_CONFIG.PlayersCanBreakDoors)) then
		scp_207.AddHookCheckDoor()
	end

	SCP_207_CONFIG.PlayersCanBreakDoors[ply:EntIndex()] = true
	ply.scp207_CanDestroyDoors = true
end

-- Add hook to check doors
function scp_207.AddHookCheckDoor()
	hook.Add( "Think", "Think.CheckDoorsBreakable_SCP207", function()
		for key, value in pairs(SCP_207_CONFIG.PlayersCanBreakDoors) do
			local ent = Entity(key)
			scp_207.CheckDoor(ent)
		end
	end )
end

-- Check for doors to break
function scp_207.CheckDoor(ply)
	if (not IsValid(ply)) then return end
	local doorsFound = ents.FindInSphere( ply:GetPos(), SCP_207_CONFIG.RadiusCollisionDoor )
	for key, door in ipairs(doorsFound) do
		if (SCP_207_CONFIG.DoorClass[door:GetClass()]) then
			scp_207.DestroyDoor(door, ply)
			break
		end
	end
end

-- Remove door breaking hook
function scp_207.RemoveEventDoorsDestroyable()
	if (!table.IsEmpty( SCP_207_CONFIG.PlayersCanBreakDoors)) then return end
	hook.Remove( "Think", "Think.CheckDoorsBreakable_SCP207" )
end

-- Destroy door function
function scp_207.DestroyDoor(door, ply)
	local PhysPly = ply:GetPhysicsObject()
	if (PhysPly:GetVelocity():Length() < SCP_207_CONFIG.VelocityMinDestroyDoor) then return end

	if (door:GetClass() == "prop_door_rotating") then
		local BrokenDoor = ents.Create("prop_physics")
		BrokenDoor:SetPos(door:GetPos())
		BrokenDoor:SetAngles(door:GetAngles())
		BrokenDoor:SetModel(door:GetModel())
		BrokenDoor:SetBodyGroups(door:GetBodyGroups())
		BrokenDoor:SetSkin(door:GetSkin())
		BrokenDoor:SetCustomCollisionCheck(true)
	
		door:Remove()
	
		BrokenDoor:Spawn()
	
		local PhysBrokenDoor = BrokenDoor:GetPhysicsObject()
		if IsValid(PhysBrokenDoor) then
			PhysBrokenDoor:ApplyForceOffset(ply:GetForward() * 500, PhysBrokenDoor:GetMassCenter())
		end
		door:EmitSound("doors/heavy_metal_stop1.wav",350,120)
		ply:TakeDamage(SCP_207_CONFIG.DamageTakeBreakingDoor, ply, ply)

	elseif(!scp_207.DoorIsOpen( door )) then
		door:Fire("open")
		door.IsBreak = true
		timer.Simple(2, function()
			if (!door:IsValid()) then return end
			door.IsBreak = nil
		end)
		door:EmitSound("doors/heavy_metal_stop1.wav",350,120)
		ply:TakeDamage(SCP_207_CONFIG.DamageTakeBreakingDoor, ply, ply)
	end
end

-- Cure SCP-207 effects (simplified)
function scp_207.CureEffect(ply)
	if (!ply.HasDrinkSCP207) then return end

	-- Restore original stats
	if (ply.scp207_PreviousInfoData and ply:Alive()) then
		ply:SetWalkSpeed( ply.scp207_PreviousInfoData.WalkSpeed )
		ply:SetRunSpeed( ply.scp207_PreviousInfoData.RunSpeed )
		ply:SetJumpPower( ply.scp207_PreviousInfoData.JumpPower )

		ply.scp207_PreviousInfoData = nil
	end

	-- Clean up all SCP-207 data
	ply.HasDrinkSCP207 = nil
	ply.scp207_Stack = nil
	print("[BREACH SCP-207] Cured effects for " .. ply:Nick())
end

-- Check if door is open
function scp_207.DoorIsOpen( door )
	if (door.IsBreak) then return true end
	local doorClass = door:GetClass()

	if ( doorClass == "func_door" or doorClass == "func_door_rotating" ) then
		return door:GetInternalVariable( "m_toggle_state" ) == 0
	elseif ( doorClass == "prop_door_rotating" ) then
		return door:GetInternalVariable( "m_eDoorState" ) ~= 0
	else
		return false
	end
end

-- Hooks for Breach integration
hook.Add("PlayerDeath", "SCP207_PlayerDeath", function(victim, inflictor, attacker)
    if IsValid(victim) then
        scp_207.CureEffect(victim)
    end
end)

hook.Add("PlayerDisconnected", "SCP207_PlayerDisconnect", function(ply)
    if IsValid(ply) then
        scp_207.CureEffect(ply)
    end
end)

-- Clean up on round restart
hook.Add("RoundRestart", "SCP207_RoundRestart", function()
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) then
            scp_207.CureEffect(ply)
        end
    end
end)

print("[BREACH] SCP-207 Module Loaded") 