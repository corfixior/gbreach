AddCSLuaFile()

SWEP.Base 				= "weapon_scp_base"
SWEP.PrintName			= "SCP-1471-A"

SWEP.Primary.Automatic  = true
SWEP.Primary.Delay 		= 0 -- Brak cooldownu na LMB

SWEP.Secondary.Delay 	= 7

SWEP.DrawCrosshair		= true
SWEP.HoldType 			= "normal"

--if (CLIENT) then
	--SWEP.WepSelectIcon	= surface.GetTextureID( "vgui/entities/weapon_scp096" )
	--SWEP.BounceWeaponIcon = false
	--killicon.Add( "kill_icon_scp096", "vgui/icons/kill_icon_scp096", Color( 255, 255, 255, 255 ) )
--end

SWEP.Lang = nil

-- Parametry niewidoczności
SWEP.InvisibilitySpeed = 50 -- Prędkość poniżej której SCP staje się niewidoczny
SWEP.InvisibilityDistance = 1000 -- Odległość od której niewidoczność zaczyna działać
SWEP.InvisibilityAlpha = 0 -- Wartość alpha gdy niewidoczny (55 = prawie niewidoczny)

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 0, "InvisibilityLevel") -- 0 = w pełni widoczny, 1 = niewidoczny
	self:NetworkVar("Bool", 0, "IsMoving")
end

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_1471" )

	self:SetHoldType( self.HoldType )
	
	-- Inicjalizacja niewidoczności
	self:SetInvisibilityLevel(0)
	self:SetIsMoving(true)
	self.LastVelocityCheck = 0
	self.CurrentAlpha = 255
	
	if SERVER then
		-- Timer do sprawdzania ruchu
		timer.Create("SCP1471_Movement_" .. self:EntIndex(), 0.1, 0, function()
			if not IsValid(self) or not IsValid(self.Owner) then
				timer.Remove("SCP1471_Movement_" .. self:EntIndex())
				return
			end
			
			self:UpdateMovementState()
		end)
	end
end

function SWEP:OnRemove()
	if SERVER then
		timer.Remove("SCP1471_Movement_" .. self:EntIndex())
	end
	
	-- Przywróć pełną widoczność
	if IsValid(self.Owner) then
		self.Owner:SetRenderMode(RENDERMODE_NORMAL)
		self.Owner:SetColor(Color(255, 255, 255, 255))
	end
end

function SWEP:Deploy()
	self:HideModels()

	if SERVER and !self.walkspeed and !self.runspeed then
		self.walkspeed = self.Owner:GetWalkSpeed()
		self.runspeed = self.Owner:GetRunSpeed()

		self.Owner:SetRunSpeed( self.walkspeed )
	end
end

SWEP.NextPrimary = 0
function SWEP:PrimaryAttack()
	if preparing or postround then return end
	-- Brak sprawdzania cooldownu dla LMB
	if !SERVER then return end
	local fents = ents.FindInSphere( self.Owner:GetPos(), 50 ) -- Zmniejszony zasięg o połowę
	for k, ent in pairs( fents ) do
		if IsValid( ent ) then
			if ent:IsPlayer() then
				if ent:GTeam() != TEAM_SPEC and (ent:GTeam() != TEAM_SCP or ent:GetNClass() == ROLES.ROLE_SCP035) then
					//print( ent.scp1471stacks )
					ent:TakeDamage( ent.scp1471stacks or 1, self.Owner, self.Owner )
				end
			else
				self:SCPDamageEvent( ent, 5 )
			end	
		end
	end
end

SWEP.NextSecondary = 0
function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if self.NextSecondary > CurTime() then return end
	local trace = self.Owner:GetEyeTrace()
	if !trace.Hit then return end
	local ent = trace.Entity
	if IsValid( ent ) then
		if ent:IsPlayer() and (ent:GTeam() != TEAM_SCP or ent:GetNClass() == ROLES.ROLE_SCP035) and ent:GTeam() != TEAM_SPEC then
			if ent:GetAimVector():Dot( (ent:EyePos() - self.Owner:EyePos() ):GetNormalized() ) > -0.5 then
				self.NextSecondary = CurTime() + self.Secondary.Delay
				if !SERVER then return end

				self.Owner:SetWalkSpeed( self.runspeed )
				self.Owner:SetRunSpeed( self.runspeed )
				timer.Simple( 3, function()
					if IsValid( self ) and IsValid( self.Owner ) then
						self.Owner:SetWalkSpeed( self.walkspeed )
						self.Owner:SetRunSpeed( self.walkspeed )
					end
				end )

				local vec = self.Owner:GetPos() - ent:GetPos()
				local dir = vec:GetNormalized()

				ent:SendLua( "CamEnable = true" )
				ent:SendLua( "dir = Vector( "..dir.x..", "..dir.y..", "..dir.z.." )" )

				ent.scp1471stacks = ( ent.scp1471stacks or 1 ) + 1
				--self.Owner:SendLua( "CamEnable = true" )
				--self.Owner:SendLua( "dir = Vector( "..dir.x..", "..dir.y..", "..dir.z.." )" )
			end
		end
	end
end

function SWEP:DrawHUD()
	if disablehud == true then return end
	
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	local centerX = ScrW() / 2
	local centerY = ScrH() / 2
	local hudY = ScrH() - 150
	
	local hudWidth = 500
	local hudHeight = 120
	local hudX = centerX - hudWidth / 2
	
	-- Tło HUD
	surface.SetDrawColor(20, 20, 20, 180)
	surface.DrawRect(hudX, hudY, hudWidth, hudHeight)
	
	-- Obramowanie
	surface.SetDrawColor(100, 100, 100, 200)
	surface.DrawOutlinedRect(hudX, hudY, hudWidth, hudHeight)
	
	-- Linia dekoracyjna
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawRect(hudX + 10, hudY + 5, hudWidth - 20, 2)
	
	-- Tytuł SCP
	surface.SetFont("DermaLarge")
	surface.SetTextColor(200, 200, 200, 255)
	local titleW, titleH = surface.GetTextSize("SCP-1471-A")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-1471-A")
	
	-- Cooldowny
	local lpmCooldown = 0
	local ppmCooldown = 0
	
	if self.NextPrimary and self.NextPrimary > CurTime() then
		lpmCooldown = self.NextPrimary - CurTime()
	end
	
	if self.NextSecondary and self.NextSecondary > CurTime() then
		ppmCooldown = self.NextSecondary - CurTime()
	end
	
	local cooldownY = hudY + 60
	local barWidth = 120
	local barHeight = 8
	local barSpacing = 20
	
	-- LMB Cooldown (AOE Attack)
	local lpmBarX = centerX - barWidth - barSpacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(lpmBarX, cooldownY - 15)
	surface.DrawText("LMB - AOE")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(lpmBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(lpmBarX, cooldownY, barWidth, barHeight)
	
	-- Zawsze pokazuj jako gotowe (brak cooldownu)
	surface.SetDrawColor(100, 255, 100, 255)
	surface.DrawRect(lpmBarX, cooldownY, barWidth, barHeight)
	
	surface.SetFont("DermaDefault")
	surface.SetTextColor(150, 255, 150, 255)
	surface.SetTextPos(lpmBarX, cooldownY + 10)
	surface.DrawText("READY")
	
	-- RMB Cooldown (Stalk)
	local ppmBarX = centerX + barSpacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(ppmBarX, cooldownY - 15)
	surface.DrawText("RMB - Stalk")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(ppmBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(ppmBarX, cooldownY, barWidth, barHeight)
	
	if ppmCooldown > 0 then
		local progress = 1 - (ppmCooldown / self.Secondary.Delay)
		surface.SetDrawColor(100, 150, 255, 255)
		surface.DrawRect(ppmBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 200, 255, 255)
		surface.SetTextPos(ppmBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", ppmCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(ppmBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(ppmBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- Wskaźnik niewidoczności
	local invisY = hudY + hudHeight - 20
	surface.SetFont("DermaDefault")
	
	local invisLevel = self:GetInvisibilityLevel()
	if invisLevel > 0 then
		surface.SetTextColor(150, 150, 255, 255)
		local invisText = "INVISIBLE"
		local invisW, invisH = surface.GetTextSize(invisText)
		surface.SetTextPos(centerX - invisW / 2, invisY)
		surface.DrawText(invisText)
	else
		surface.SetTextColor(255, 150, 150, 255)
		local invisText = "VISIBLE"
		local invisW, invisH = surface.GetTextSize(invisText)
		surface.SetTextPos(centerX - invisW / 2, invisY)
		surface.DrawText(invisText)
	end
	
	-- Celownik
	local x = ScrW() / 2.0
	local y = ScrH() / 2.0
	
	local scale = 0.3
	surface.SetDrawColor(150, 150, 255, 255)
	
	local gap = 5
	local length = gap + 20 * scale
	surface.DrawLine(x - length, y, x - gap, y)
	surface.DrawLine(x + length, y, x + gap, y)
	surface.DrawLine(x, y - length, x, y - gap)
	surface.DrawLine(x, y + length, x, y + gap)
end

-- Aktualizacja stanu ruchu (SERVER)
function SWEP:UpdateMovementState()
	if not SERVER then return end
	
	local velocity = self.Owner:GetVelocity():Length()
	local isMoving = velocity > self.InvisibilitySpeed
	
	if isMoving != self:GetIsMoving() then
		self:SetIsMoving(isMoving)
		-- Natychmiastowe przełączanie niewidoczności
		if isMoving then
			self:SetInvisibilityLevel(0) -- W pełni widoczny
		else
			self:SetInvisibilityLevel(1) -- Niewidoczny
		end
	end
end

-- Globalny hook do renderowania SCP-1471 (CLIENT)
if CLIENT then
	hook.Add("PrePlayerDraw", "SCP1471_Invisibility", function(ply)
		if not IsValid(ply) or not ply:Alive() then return end
		
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() != "weapon_scp_1471" then return end
		
		local localPly = LocalPlayer()
		if not IsValid(localPly) then return end
		
		-- Nie stosuj efektu dla samego siebie
		if ply == localPly then return end
		
		-- Prosty przełącznik - niewidoczny gdy się nie rusza
		local invisLevel = wep:GetInvisibilityLevel()
		
		if invisLevel > 0 then
			-- Jest niewidoczny - całkowicie ukryj model
			return true -- Return true blokuje rysowanie modelu
		end
		
		-- Normalnie widoczny
		ply:SetRenderMode(RENDERMODE_NORMAL)
		ply:SetColor(Color(255, 255, 255, 255))
	end)
end