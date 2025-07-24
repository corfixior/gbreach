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

SWEP.InUse = false
SWEP.Durability = 100
SWEP.IsActive = false

function SWEP:Deploy()
	if not IsFirstTimePredicted() then return end
	-- Security Droid nie może używać SCP-714 (pierścień biologiczny, android go nie potrzebuje)
	if self.Owner:GetNClass() == ROLES.ROLE_SECURITY_DROID then
		if SERVER then
			self.Owner:PrintMessage(HUD_PRINTTALK, "[SYSTEM] ERROR: Anomalous biological enhancement item incompatible with android systems")
			-- Automatycznie usuń przedmiot
			timer.Simple(0.1, function()
				if IsValid(self.Owner) then
					self.Owner:StripWeapon("item_scp_714")
				end
			end)
		end
		return
	end
	self.Owner:DrawViewModel( false )
	if SERVER then
		self.Owner:SetNWBool("SCP714_Active", self.IsActive)
		self.Owner:SetNWFloat("SCP714_Durability", self.Durability)
	end
end

function SWEP:Holster()
	if not IsFirstTimePredicted() then return end
	return true
end

function SWEP:Equip()
	if not IsFirstTimePredicted() then return end
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

SWEP.LastTime = 0

function SWEP:Think()
	if not IsFirstTimePredicted() then return end
	
	-- Sync z serwerem (tylko synchronizacja, bez logiki działania)
	if SERVER then
		self.Owner:SetNWBool("SCP714_Active", self.IsActive)
		self.Owner:SetNWFloat("SCP714_Durability", self.Durability)
	else
		self.IsActive = self.Owner:GetNWBool("SCP714_Active", false)
		self.Durability = self.Owner:GetNWFloat("SCP714_Durability", 100)
	end
end

function SWEP:OnRemove() 
	if SERVER and IsValid(self.Owner) then
		self.Owner:SetNWBool("SCP714_Active", false)
		self.Owner.Using714 = false
		-- Usuń timer jeśli istnieje
		timer.Remove("SCP714_Background_" .. self.Owner:SteamID64())
	end
end

function SWEP:Reload()
end

function SWEP:OwnerChanged()
	-- Nie resetuj stanu przy zmianie właściciela
end

-- Hook dla działania w tle
if SERVER then
	hook.Add("Think", "SCP714_Background", function()
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply:HasWeapon("item_scp_714") then
				local wep = ply:GetWeapon("item_scp_714")
				if IsValid(wep) and wep.IsActive then
					-- Działaj w tle nawet gdy nie trzyma broni
					if not ply.SCP714_LastBgTime then ply.SCP714_LastBgTime = 0 end
					
					if ply.SCP714_LastBgTime <= CurTime() then
						ply.SCP714_LastBgTime = CurTime() + 0.9
						wep.Durability = wep.Durability - 0.5
						
						if wep.Durability > 0 then
							if ply:GetMaxHealth() > ply:Health() then
								ply:SetHealth(ply:Health() + 1)
							end
							ply.Using714 = true
						else
							wep.IsActive = false
							ply.Using714 = false
							if wep.Durability < 0 then
								ply:StripWeapon("item_scp_714")
							end
						end
						
						-- Natychmiastowa synchronizacja po zmianie
						ply:SetNWFloat("SCP714_Durability", wep.Durability)
					end
				end
			else
				ply.SCP714_LastBgTime = nil
			end
		end
	end)
end

-- Globalny HUD hook dla pokazywania statusu gdy nie trzyma SCP-714
if CLIENT then
	hook.Add("HUDPaint", "SCP714_GlobalStatus", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		
		-- Sprawdź czy ma SCP-714 ale nie trzyma go aktualnie
		if ply:HasWeapon("item_scp_714") then
			local currentWep = ply:GetActiveWeapon()
			if not IsValid(currentWep) or currentWep:GetClass() ~= "item_scp_714" then
				-- Ma SCP-714 ale nie trzyma go - pokaż status
				local isActive = ply:GetNWBool("SCP714_Active", false)
				local durability = ply:GetNWFloat("SCP714_Durability", 100)
				
				if isActive and durability > 0 then
					-- Pozycja na samej górze ekranu
					local x = ScrW() / 2
					local y = 30
					
					-- Prosty tekst bez tła
					local text = "SCP-714: " .. math.floor(durability) .. "% [ACTIVE]"
					draw.SimpleText(text, "SCP714_Small", x, y, Color(100, 255, 100), TEXT_ALIGN_CENTER)
					
					-- Pasek postępu
					local barWidth = 100
					local barHeight = 4
					local progress = durability / 100
					
					-- Tło paska
					surface.SetDrawColor(0, 0, 0, 150)
					surface.DrawRect(x - barWidth/2, y + 20, barWidth, barHeight)
					
					-- Wypełnienie paska
					surface.SetDrawColor(100, 255, 100, 255)
					surface.DrawRect(x - barWidth/2, y + 20, barWidth * progress, barHeight)
				end
			end
		end
	end)
end

function SWEP:PrimaryAttack()
	if not IsFirstTimePredicted() then return end
	if preparing or postround then return end
	
	self.IsActive = not self.IsActive
	
	if SERVER then
		if self.IsActive then
			self.Owner:PrintMessage(HUD_PRINTTALK, "SCP-714 ENABLED")
			self.Owner.Using714 = true
		else
			self.Owner:PrintMessage(HUD_PRINTTALK, "SCP-714 DISABLED")
			self.Owner.Using714 = false
		end
	end
end

function SWEP:SecondaryAttack()
end

function SWEP:CanPrimaryAttack()
end

if CLIENT then
	surface.CreateFont("SCP714_Small", {
		font = "Trebuchet24", 
		size = 18,
		weight = 500,
		antialias = true,
		shadow = true
	})
end

function SWEP:DrawHUD()
	if disablehud == true then return end
	
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	local x = ScrW() / 2
	local y = ScrH() / 2 - 50
	
	local barWidth = 100
	local barHeight = 4
	
	local isActive = ply:GetNWBool("SCP714_Active", false)
	local durability = ply:GetNWFloat("SCP714_Durability", 100)
	
	local color
	if isActive then
		color = Color(100, 255, 100) -- Jasny zielony gdy aktywny
	else
		color = Color(150, 150, 150) -- Szary gdy nieaktywny
	end
	
	local text = durability .. "%" .. (isActive and " [ON]" or " [OFF]")
	draw.SimpleText(text, "SCP714_Small", x, y - 20, color, TEXT_ALIGN_CENTER)
	
	if not isActive then
		draw.SimpleText("LMB: Enable", "SCP714_Small", x, y - 35, Color(100, 100, 100), TEXT_ALIGN_CENTER)
	end
	
	local progress = durability / 100
	
	surface.SetDrawColor(0, 0, 0, 150)
	surface.DrawRect(x - barWidth/2, y, barWidth, barHeight)
	
	if isActive then
		surface.SetDrawColor(100, 255, 100, 255) -- Jasny zielony gdy aktywny
	else
		surface.SetDrawColor(150, 150, 150, 255) -- Szary gdy nieaktywny
	end
	surface.DrawRect(x - barWidth/2, y, barWidth * progress, barHeight)
end