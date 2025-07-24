AddCSLuaFile()

SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.ViewModel = ""
SWEP.WorldModel = "models/maxpayne/weapons/shades.mdl"
SWEP.PrintName = "SCP-215"
SWEP.Slot = 3
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.HoldType = "normal"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.droppable = true
SWEP.teams = {TEAM_GUARD, TEAM_CLASSD, TEAM_SCI, TEAM_CHAOS, TEAM_GOC} -- Wszystkie zespoły poza SCPs i Spectators

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

-- Wyłącz dźwięki przełączania
function SWEP:PrimaryAttack()
	-- Pusta funkcja - wyłącza domyślne dźwięki
end

function SWEP:SecondaryAttack()
	-- Pusta funkcja - wyłącza domyślne dźwięki
end

-- Zmienne SCP-215
SWEP.IsActive = false
SWEP.DetectionRange = 2000 -- Zasięg wykrywania w jednostkach Source
SWEP.CooldownTime = 0
SWEP.CooldownDuration = 5 -- 5 sekund cooldown między użyciami

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end