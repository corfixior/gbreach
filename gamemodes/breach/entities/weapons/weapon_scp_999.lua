AddCSLuaFile()

SWEP.Base 				= "weapon_scp_base"
SWEP.PrintName			= "SCP999"			

SWEP.Primary.Delay 		= 2
SWEP.Secondary.Delay 	= 5

SWEP.DrawCrosshair		= true
SWEP.HoldType 			= ""

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 0, "NextPrimary")
	self:NetworkVar("Float", 1, "NextSecondary")
end

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_999" )

	self:SetHoldType(self.HoldType)
	
	-- Initialize cooldowns
	self:SetNextPrimary(0)
	self:SetNextSecondary(0)
end

function SWEP:DrawWorldModel()
	-- Nie rysuj modelu broni
end

function SWEP:DrawWorldModelTranslucent()
	-- Nie rysuj modelu broni
end

function SWEP:DrawViewModel()
	-- Nie rysuj viewmodelu
end

function SWEP:PreDrawViewModel()
	return true -- Zapobiega rysowaniu
end

function SWEP:ViewModelDrawn()
	-- Nic nie rób
end

function SWEP:GetViewModelPosition(pos, ang)
	return pos, ang
end

SWEP.ShowViewModel = false
SWEP.ShowWorldModel = false

function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if CurTime() < self:GetNextPrimary() then return end
	self:SetNextPrimary(CurTime() + self.Primary.Delay)
	if SERVER then
		local tr = util.TraceHull({
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 150,
			maxs = Vector(10, 10, 10),
			mins = Vector(-10, -10, -10),
			filter = self.Owner,
			mask = MASK_SHOT
		})
		local ent = tr.Entity
		if !IsValid(ent) then return end
		if ent:IsPlayer() then
			if ent:GTeam() != TEAM_SPEC then
				if ent:Health() == ent:GetMaxHealth() then return end
				local hp = ent:Health() + math.random(5, 10)
				if hp > ent:GetMaxHealth() then hp = ent:GetMaxHealth() end
				self.Owner:AddExp(20, false)
				ent:SetHealth(hp)
			end
		else
			self:SCPDamageEvent( ent, 10 )
		end
	end
end

function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if CurTime() < self:GetNextSecondary() then return end
	self:SetNextSecondary(CurTime() + self.Secondary.Delay)
	if SERVER then
		local fent = ents.FindInSphere(self.Owner:GetPos(), 300)
		local hp = 0
		local totalheal = 0
		for k, v in pairs(fent) do
			if v:IsPlayer() then
				if v:GTeam() != TEAM_SPEC and v != self.Owner then
					hp = v:Health() + math.random(5, 15)
					if hp > v:GetMaxHealth() then hp = v:GetMaxHealth() end
					totalheal = totalheal + (hp - v:Health())
					v:SetHealth(hp)
					hp = 0
				end
			end
		end
		if totalheal > 0 then self.Owner:AddExp(totalheal, false) end
	end
end

function SWEP:Deploy()
	if IsValid( self.Owner ) then
		self.Owner:SetCustomCollisionCheck( true )
		self.Owner:DrawViewModel( false )
		-- Dodaj flagę identyfikującą SCP-999
		self.Owner.SCP999Active = true
	end
	return true
end

function SWEP:OnRemove()
	if IsValid( self.Owner ) then
		self.Owner:SetCustomCollisionCheck( false )
		-- Usuń flagę
		self.Owner.SCP999Active = false
	end
end

function SWEP:Holster()
	if IsValid( self.Owner ) then
		self.Owner:SetCustomCollisionCheck( false )
		-- Usuń flagę
		self.Owner.SCP999Active = false
	end
	return true
end

function SWEP:DrawHUD()
	if disablehud == true then return end
	if self.Owner:Team() == TEAM_SPEC then return end
	
	self:DrawSCPHUD()
end

function SWEP:DrawSCPHUD()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	local centerX = ScrW() / 2
	local centerY = ScrH() / 2
	local hudY = ScrH() - 150
	
	local hudWidth = 500
	local hudHeight = 120
	local hudX = centerX - hudWidth / 2
	
	-- Funkcja pomocnicza do generowania koloru tęczy
	local function getRainbowColor(speed)
		speed = speed or 1
		local time = CurTime() * speed
		local r = math.sin(time) * 127 + 128
		local g = math.sin(time + 2) * 127 + 128
		local b = math.sin(time + 4) * 127 + 128
		return Color(r, g, b, 255)
	end
	
	-- Tło HUD
	surface.SetDrawColor(20, 20, 20, 180)
	surface.DrawRect(hudX, hudY, hudWidth, hudHeight)
	
	-- Tęczowe obramowanie
	local rainbowColor = getRainbowColor(2)
	surface.SetDrawColor(rainbowColor.r, rainbowColor.g, rainbowColor.b, 200)
	surface.DrawOutlinedRect(hudX, hudY, hudWidth, hudHeight)
	
	-- Tęczowa linia dekoracyjna
	surface.SetDrawColor(rainbowColor.r, rainbowColor.g, rainbowColor.b, 255)
	surface.DrawRect(hudX + 10, hudY + 5, hudWidth - 20, 2)
	
	-- Tytuł SCP z efektem tęczy
	surface.SetFont("DermaLarge")
	surface.SetTextColor(rainbowColor.r, rainbowColor.g, rainbowColor.b, 255)
	local titleW, titleH = surface.GetTextSize("SCP-999")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-999")
	
	-- Cooldowny
	local cooldownY = hudY + 60
	local barWidth = 230
	local barHeight = 8
	local spacing = 20
	local totalWidth = barWidth * 2 + spacing
	local startX = centerX - totalWidth / 2
	
	-- LMB Cooldown (Heal)
	local lmbBarX = startX
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(lmbBarX, cooldownY - 15)
	surface.DrawText("LMB - Heal")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
	
	local healCooldown = 0
	local nextHeal = self:GetNextPrimary()
	if nextHeal > CurTime() then
		healCooldown = nextHeal - CurTime()
	end
	
	if healCooldown > 0 then
		local progress = 1 - (healCooldown / self.Primary.Delay)
		local barRainbow = getRainbowColor(3)
		surface.SetDrawColor(barRainbow.r, barRainbow.g, barRainbow.b, 255)
		surface.DrawRect(lmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 200, 220, 255)
		surface.SetTextPos(lmbBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", healCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(lmbBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- RMB Cooldown (Group Heal)
	local rmbBarX = startX + barWidth + spacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rmbBarX, cooldownY - 15)
	surface.DrawText("RMB - Group Heal")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
	
	local groupHealCooldown = 0
	local nextGroupHeal = self:GetNextSecondary()
	if nextGroupHeal > CurTime() then
		groupHealCooldown = nextGroupHeal - CurTime()
	end
	
	if groupHealCooldown > 0 then
		local progress = 1 - (groupHealCooldown / self.Secondary.Delay)
		local barRainbow2 = getRainbowColor(3.5)
		surface.SetDrawColor(barRainbow2.r, barRainbow2.g, barRainbow2.b, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 200, 220, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", groupHealCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- Tęczowy celownik
	local x = ScrW() / 2.0
	local y = ScrH() / 2.0
	
	local crosshairRainbow = getRainbowColor(4)
	surface.SetDrawColor(crosshairRainbow.r, crosshairRainbow.g, crosshairRainbow.b, 255)
	
	local gap = 5
	local length = gap + 15
	surface.DrawLine( x - length, y, x - gap, y )
	surface.DrawLine( x + length, y, x + gap, y )
	surface.DrawLine( x, y - length, x, y - gap )
	surface.DrawLine( x, y + length, x, y + gap )
end
