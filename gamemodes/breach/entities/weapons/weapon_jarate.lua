AddCSLuaFile()

SWEP.DrawWeaponInfoBox = false
SWEP.BounceWeaponIcon = true

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID( "models/orange_blossom/piss/piss_icon" )
	SWEP.BounceWeaponIcon = false
end

SWEP.Slot = 4
SWEP.SlotPos = 8

SWEP.Category = "Breach SCP"
SWEP.PrintName = "Jarate"
SWEP.Spawnable = true

SWEP.ViewModel = Model( "models/orange_blossom/piss/piss.mdl" )
SWEP.WorldModel = Model( "models/orange_blossom/piss/piss_world.mdl" )
SWEP.ViewModelFOV = 50
SWEP.BobScale = 2
SWEP.UseHands = true

-- Breach gamemode compatibility
SWEP.droppable = true
SWEP.teams = {2,3,5,6,7} -- MTF, Scientists, Guards, etc.

SWEP.Primary.Ammo = "jarate"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = GetConVar and GetConVar("blossomJarateCount") and GetConVar("blossomJarateCount"):GetInt() or 1
SWEP.Primary.Automatic = false

SWEP.Secondary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false

SWEP.DrawAmmo = true

SWEP.soundAttack = "orange_blossom/piss/swoosh.wav"
SWEP.soundDeploy = "orange_blossom/piss/bottle.wav"
SWEP.speed = GetConVar and GetConVar("sv_defaultdeployspeed") and GetConVar("sv_defaultdeployspeed"):GetFloat() or 1

SWEP.timers = { --these are reset at OnRemove()
	["hitTime"] = 999999,
	["idleTime"] = 999999,
	["cool"] = 999999,
}

SWEP.time = 0
SWEP.isIdle = false
SWEP.myPos = Vector( 0, 0, 0 )
SWEP.hold = false
SWEP.throwForce = GetConVar and GetConVar("blossomJarateThrow") and GetConVar("blossomJarateThrow"):GetInt() or 650

function SWEP:Initialize()
	self.time = CurTime()
	self:SetHoldType( "grenade" )
	self.throwForce = GetConVar and GetConVar("blossomJarateThrow") and GetConVar("blossomJarateThrow"):GetInt() or 650
	self.Primary.DefaultClip = GetConVar and GetConVar("blossomJarateCount") and GetConVar("blossomJarateCount"):GetInt() or 1
end

function SWEP:Deploy()
	self.time = CurTime()

	local vm = self.Owner:GetViewModel()
	vm:SendViewModelMatchingSequence( vm:LookupSequence( "draw" ) )
	vm:SetPlaybackRate( self.speed )

	self.timers["idleTime"] = self.time + vm:SequenceDuration() / self.speed
	self.timers["cool"] = self.time

	self:CallOnClient( "DeployClientside" )

	return true
end

function SWEP:DeployClientside()
	self.time = CurTime()

	local vm = self.Owner:GetViewModel()
	vm:SendViewModelMatchingSequence( vm:LookupSequence( "draw" ) )
	vm:SetPlaybackRate( self.speed )

	self.timers["idleTime"] = self.time + vm:SequenceDuration() / self.speed
	self.timers["cool"] = self.time

	sound.Play( self.soundDeploy, LocalPlayer():GetPos(), 75, 100, 1 )
end

function SWEP:CanPrimaryAttack()
	if SERVER and self.Owner:GetAmmoCount( self.Primary.Ammo ) > 0 and self.timers["cool"] < self.time and !self.hold then
		return true
	else
		return false
	end
end

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() or !IsFirstTimePredicted() then return end

	local vm = self.Owner:GetViewModel()
	vm:SendViewModelMatchingSequence( vm:LookupSequence( "drawbackhigh" ) )
	self.hold = true
end

function SWEP:ClientThrow()
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
end

function SWEP:SecondaryAttack()
	return
end

function SWEP:Holster()
	self:ResetTimers()
	return true
end

function SWEP:OnDrop()
	self:ResetTimers()
end

function SWEP:OnRemove()
	self:ResetTimers()
end

function SWEP:Think()
	if CLIENT then return end

	local vm = self.Owner:GetViewModel()
	self.time = CurTime()
	self.myPos = self.Owner:GetPos()

	if self.hold then
		local down = self.Owner:KeyDown( IN_ATTACK )

		if down then
			self.timers["cool"] = self.time + 0.7
			return
		else
			self.Owner:SetAnimation( PLAYER_ATTACK1 )
			vm:SendViewModelMatchingSequence( vm:LookupSequence( "throw" ) )
			self.timers["hitTime"] = self.time + 0.2
			self.hold = false
			self:CallOnClient( "ClientThrow" )
		end
	end

	if self.timers["hitTime"] < self.time then --primary attack
		local ange = self.Owner:LocalEyeAngles()

		local side = Vector( 8, -8, 0 )
		side:Rotate(ange)
		local offsetFix = Vector( 0, 0.02, 0 )
		offsetFix:Rotate( ange )

		local proj = ents.Create( "breach_jarate_projectile" )
		local dir = self.Owner:GetAimVector() + Vector( 0, 0, 0.2 ) + offsetFix
		local parent = self.Owner
		local force = self.throwForce

		proj:MyInfo( dir, parent, force )
		proj:SetPos( self.Owner:GetPos() + side + Vector( 0, 0, 60 ) )
		proj:Spawn()

		sound.Play( self.soundAttack, self.myPos, 75, math.random( 90, 110 ), 1 )

		self.Owner:RemoveAmmo( 1, self.Primary.Ammo )
		self.timers["hitTime"] = 999999
		self.timers["idleTime"] = self.time + 0.5

		if self.Owner:GetAmmoCount( self.Primary.Ammo ) <= 0 then
			self.Owner:StripWeapon( "weapon_jarate" )
			return
		end

		return
	end

	if !self.hold and self.timers["idleTime"] < self.time then --loop idle
		vm:SendViewModelMatchingSequence( vm:LookupSequence( "idle01" ) )
		self.timers["idleTime"] = self.time + vm:SequenceDuration()
		return
	end
end

function SWEP:ResetTimers()
	for k,v in pairs( self.timers ) do --timers won't progress when wep is not active
		self.timers[k] = 999999
	end
end 