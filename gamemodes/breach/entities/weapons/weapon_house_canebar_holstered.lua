AddCSLuaFile()

-- weapon_house_canebar_holstered.lua
SWEP.Category			= "Other"
SWEP.IconOverride 		= "vgui/hud/killicon/greg_icon"
SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true
SWEP.PrintName			= "House Canebar (Holstered)"	
SWEP.Base				= "weapon_base"
SWEP.Author				= "Opal, Bunny"
SWEP.Instructions		= "Holstered version of the House canebar."

SWEP.ViewModel			= "models/canebar/v_house_canebar.mdl"
SWEP.WorldModel			= "models/canebar/w_house_canebar.mdl"
SWEP.ViewModelFOV 		= 65
SWEP.HoldType 			= "normal"
SWEP.UseHands 			= true
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair		= false

SWEP.Slot					= 0
SWEP.SlotPos				= 1
SWEP.FiresUnderwater 		= false

SWEP.Primary.Ammo			= -1
SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Delay 			= 0.4
SWEP.Primary.Damage 		= 0

SWEP.Secondary.Ammo			= "none"
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
	
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false
SWEP.droppable			= false

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
	if IsValid(self.Owner) and IsValid(self.Owner:GetViewModel()) then
		self.Owner:GetViewModel():SetNoDraw(true) -- Hide viewmodel when holstered
	end
	self:SetHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()
	-- Holstered weapon doesn't attack
	return false
end

function SWEP:SecondaryAttack()
	-- Holstered weapon doesn't have secondary attack
	return false
end

function SWEP:Think()
	-- Add any holstered-specific thinking here if needed
end

if CLIENT then
    killicon.Add("weapon_house_canebar_holstered", "vgui/hud/killicon/greg_icon", Color(255, 255, 255, 255))
end 