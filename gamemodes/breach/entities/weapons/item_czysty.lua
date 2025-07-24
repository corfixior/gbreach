AddCSLuaFile()

SWEP.ViewModelFOV	= 60
SWEP.ViewModelFlip	= false
SWEP.ViewModel		= "models/mishka/models/scp714.mdl"
SWEP.WorldModel		= "models/mishka/models/scp714.mdl"
SWEP.PrintName		= "SCP-714"
SWEP.Slot			= 3
SWEP.SlotPos			= 1
SWEP.DrawAmmo		= false
SWEP.DrawCrosshair	= true
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

function SWEP:Deploy()
	-- Security Droid nie może używać SCP-714 (pierścień biologiczny, android go nie potrzebuje)
	if self.Owner:GetNClass() == ROLES.ROLE_SECURITY_DROID then
		if SERVER then
			self.Owner:PrintMessage(HUD_PRINTTALK, "[SYSTEM] ERROR: Anomalous biological enhancement item incompatible with android systems")
			-- Automatycznie usuń przedmiot
			timer.Simple(0.1, function()
				if IsValid(self.Owner) then
					self.Owner:StripWeapon("item_czysty")
				end
			end)
		end
		return
	end
	self.Owner:DrawViewModel( false )
end

function SWEP:Holster()
end

function SWEP:DrawWorldModel()
	if !IsValid(self.Owner) then
		self:DrawModel()
	end
end

SWEP.Lang = nil

function SWEP:Initialize()
	if CLIENT then
		self.Lang = GetWeaponLang().SCP_714
		self.Author		= self.Lang.author
		self.Contact		= self.Lang.contact
		self.Purpose		= self.Lang.purpose
		self.Instructions	= self.Lang.instructions
	end
	self:SetHoldType(self.HoldType)
end

function SWEP:Think()
end

function SWEP:Reload()
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end

function SWEP:CanPrimaryAttack()
end

function SWEP:DrawHUD()
	if disablehud == true then return end
end