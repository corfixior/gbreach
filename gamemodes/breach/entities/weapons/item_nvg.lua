AddCSLuaFile()

if CLIENT then
	SWEP.WepSelectIcon 	= surface.GetTextureID("breach/wep_nvg")
	SWEP.BounceWeaponIcon = false
end

SWEP.ViewModelFOV	= 62
SWEP.ViewModelFlip	= false
SWEP.ViewModel		= "models/mishka/models/nvg.mdl"
SWEP.WorldModel		= "models/mishka/models/nvg.mdl"
SWEP.PrintName		= "NVG"
SWEP.Slot			= 1
SWEP.SlotPos		= 1
SWEP.DrawAmmo		= false
SWEP.DrawCrosshair	= false
SWEP.HoldType		= "normal"
SWEP.Spawnable		= false
SWEP.AdminSpawnable	= false

SWEP.droppable				= true
SWEP.teams					= {2,3,5,6,7}

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Ammo			=  "none"
SWEP.Primary.Automatic		= false

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Ammo			=  "none"
SWEP.Secondary.Automatic	=  false

-- Network string for NVG toggle
if SERVER then
	util.AddNetworkString("NVG_Toggle")
end

function SWEP:Deploy()
	self.Owner:DrawViewModel( false )
end

function SWEP:DrawWorldModel()
	if !IsValid(self.Owner) then
		self:DrawModel()
	end
end

SWEP.Lang = nil

function SWEP:Initialize()
	if CLIENT then
		self.Lang = GetWeaponLang().NVG
		self.Author		= self.Lang.author
		self.Contact		= self.Lang.contact
		self.Purpose		= self.Lang.purpose
		self.Instructions	= self.Lang.instructions
	end
	self:SetHoldType(self.HoldType)
	self:SetSkin( 2 )
end

function SWEP:Think()
end

function SWEP:Reload()
end

function SWEP:PrimaryAttack()
	if CLIENT then return end
	
	-- Toggle NVG state
	local owner = self.Owner
	if IsValid(owner) then
		-- Initialize NVG state if not exists
		if owner.NVGActive == nil then
			owner.NVGActive = false
		end
		
		-- Toggle state
		owner.NVGActive = !owner.NVGActive
		
		-- Send to client
		net.Start("NVG_Toggle")
			net.WriteBool(owner.NVGActive)
		net.Send(owner)
		
		-- Feedback message
		if owner.NVGActive then
			owner:ChatPrint("NVG activated")
		else
			owner:ChatPrint("NVG deactivated")
		end
		
		self:SetNextPrimaryFire(CurTime() + 0.5)
	end
end

function SWEP:OnRemove()
	-- Clear NVG state when weapon is removed/dropped
	if SERVER and IsValid(self.Owner) then
		self.Owner.NVGActive = false
		net.Start("NVG_Toggle")
			net.WriteBool(false)
		net.Send(self.Owner)
	end
end

function SWEP:OnDrop()
	-- Clear NVG state when weapon is dropped
	if SERVER and IsValid(self.Owner) then
		self.Owner.NVGActive = false
		net.Start("NVG_Toggle")
			net.WriteBool(false)
		net.Send(self.Owner)
	end
end

function SWEP:Holster()
	return true
end

function SWEP:SecondaryAttack()
end

function SWEP:CanPrimaryAttack()
	return true
end


