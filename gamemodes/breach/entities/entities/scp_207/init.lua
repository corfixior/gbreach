-- SCP-207, A representation of a paranormal object on a fictional series on the game Garry's Mod.
-- Copyright (C) 2023  MrMarrant aka BIBI.
-- Adapted for SCP: Breach gamemode

AddCSLuaFile("shared.lua")
include("shared.lua")

local PhysicSoundLow = Sound( "physics/glass/glass_bottle_impact_hard"..math.random(1, 3)..".wav" )
local BreakSound = Sound( "physics/glass/glass_bottle_break"..math.random(1, 2)..".wav" )
local PickUpSound = Sound( "scp_207/pickup.mp3" )

function ENT:BreakEntity()
	local effectdata = EffectData()

	effectdata:SetOrigin( self:GetPos() )
	sound.Play( BreakSound, self:GetPos(), 75, math.random( 50, 160 ) )
	util.Effect( "GlassImpact", effectdata )
	self:Remove()
end

function ENT:Initialize()
	self:SetModel( "models/scp_207/scp_207.mdl" )
	self:RebuildPhysics()
end

function ENT:RebuildPhysics( value )
	self:PhysicsInit( SOLID_VPHYSICS ) 
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid( SOLID_VPHYSICS ) 
	self:SetUseType(SIMPLE_USE)
	self:PhysWake()
end

function ENT:PhysicsCollide( data, physobj )
	if ( data.Speed > 250 and data.DeltaTime > 0.01) then
		self:BreakEntity(pos)
	elseif (data.Speed > 20 and data.DeltaTime > 0.01) then
		sound.Play( PhysicSoundLow, self:GetPos(), 75, math.random( 50, 160 ) )	
	end
end

function ENT:OnTakeDamage( dmginfo )
	local DmgReceive = dmginfo:GetDamage()
	if (DmgReceive >= 5) then
		self:BreakEntity(pos)
	else
		return 0
	end
end

function ENT:Use( ply)
	-- Basic Breach checks
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if not ply:Alive() then return end
	if ply:GTeam() == TEAM_SPEC then return end
	
	-- Check if SCP-207 system allows this team/job
	if SCP_207_CONFIG and SCP_207_CONFIG.JobNotAllowed then
		local teamName = team.GetName(ply:Team())
		if SCP_207_CONFIG.JobNotAllowed[teamName] then return end
	end
	
	-- Check if player already has SCP-207
	if ply:HasWeapon("weapon_scp_207") then
		return
	end
	
	-- Check if player has free slot for weapon
	local weapons = ply:GetWeapons()
	if #weapons >= 8 then -- GMod weapon limit is usually 8
		return
	end

	-- Try to give weapon
	local weapon = ply:Give("weapon_scp_207")
	if IsValid(weapon) then
		sound.Play( PickUpSound, ply:GetPos(), 75, math.random( 50, 160 ) )	
		self:Remove()
		ply:SelectWeapon("weapon_scp_207")
	end
end 