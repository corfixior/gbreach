AddCSLuaFile()

SWEP.Base 			= "weapon_scp_base"
SWEP.PrintName		= "SCP-023"
SWEP.DrawCrosshair	= true
SWEP.HoldType 		= "normal"

SWEP.Primary.Sound			= "scp/023/attack.mp3"
SWEP.Primary.Delay			= 1.0
SWEP.Secondary.Automatic 	= false

-- Cooldowny
SWEP.MarkCooldown = 180 -- 3 minuty cooldown na oznaczenie
SWEP.DashCooldown = 15 -- 15 sekund cooldown na dash

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_023" )
	self:SetHoldType( self.HoldType )
	
	-- Inicjalizacja zmiennych
	self.NextMark = 0
	self.NextDash = 0
	self.MarkedPlayer = nil
	self.MarkedDeathTime = 0
	self.CurrentMarkedName = ""
	
	if SERVER then
		local hookID = "SCP023_" .. self:EntIndex()
		
		-- Hook na śmierć gracza
		hook.Add("PlayerDeath", "Death_" .. hookID, function(victim, inflictor, attacker)
			-- Sprawdź czy oznaczony gracz zabił kogoś - może się uratować
			if IsValid(self) and IsValid(self.MarkedPlayer) and IsValid(attacker) and attacker == self.MarkedPlayer and victim != self.MarkedPlayer then
				-- Oznaczony gracz zabił kogoś innego - ratuje się!
				net.Start("SCP023_MarkRemoved")
				net.Send(self.MarkedPlayer)
				
				-- Usuń oznaczenie
				self.MarkedPlayer = nil
				self.MarkedDeathTime = 0
				self.CurrentMarkedName = ""
				-- NIE resetuj cooldownu - SCP-023 musi czekać
				self:UpdateMarkedList()
				
				-- Efekt dźwiękowy ratowania
				attacker:EmitSound("buttons/button14.wav", 75, 150)
				return
			end
			
			-- Standardowa śmierć oznaczonego gracza
			if IsValid(self) and IsValid(self.MarkedPlayer) and victim == self.MarkedPlayer then
				-- Konkretnie oznaczony gracz umarł, zresetuj cooldown
				self.MarkedPlayer = nil
				self.MarkedDeathTime = 0
				self.CurrentMarkedName = ""
				self.NextMark = 0
				self:UpdateMarkedList()
			end
		end)
		
		-- Hook na disconnect gracza
		hook.Add("PlayerDisconnected", "Disconnect_" .. hookID, function(ply)
			if IsValid(self) and IsValid(self.MarkedPlayer) and ply == self.MarkedPlayer then
				-- Gracz oznaczony się rozłączył, zresetuj cooldown
				self.MarkedPlayer = nil
				self.MarkedDeathTime = 0
				self.CurrentMarkedName = ""
				self.NextMark = 0
				self:UpdateMarkedList()
			end
		end)
	end
end

function SWEP:OnRemove()
	if SERVER then
		local hookID = "SCP023_" .. self:EntIndex()
		hook.Remove("PlayerDeath", "Death_" .. hookID)
		hook.Remove("PlayerDisconnected", "Disconnect_" .. hookID)
	end
end

function SWEP:Deploy()
	self:HideModels()

	if SERVER then
		-- Ustaw prędkość na 200
		self.Owner:SetWalkSpeed(200)
		self.Owner:SetRunSpeed(200)
	end
end

SWEP.NextSpec = 0
function SWEP:Think()
	self:PlayerFreeze()
	if !SERVER then return end
	
	-- Sprawdzanie oznaczonego gracza
	if self.NextSpec > CurTime() then return end
	self.NextSpec = CurTime() + 0.1
	
	-- Sprawdź oznaczonego gracza
	if IsValid(self.MarkedPlayer) then
		-- Sprawdź czy gracz nadal jest valid i żywy
		if !self.MarkedPlayer:Alive() or self.MarkedPlayer:GTeam() == TEAM_SCP or self.MarkedPlayer:GTeam() == TEAM_SPEC then
			-- Gracz nie żyje lub zmienił team - usuń z listy i zresetuj cooldown
			self.MarkedPlayer = nil
			self.MarkedDeathTime = 0
			self.CurrentMarkedName = ""
			self.NextMark = 0 -- Reset cooldown
			self:UpdateMarkedList()
		elseif self.MarkedDeathTime > 0 and self.MarkedDeathTime <= CurTime() then
			-- Czas minął, zabij konkretnego gracza
			-- Najpierw efekt dźwiękowy (przed zabiciem)
			if IsValid(self.MarkedPlayer) then
				self.MarkedPlayer:EmitSound("ambient/fire/ignite.wav", 75, 50)
			end
			
			-- Teraz zabij gracza
			local dmginfo = DamageInfo()
			dmginfo:SetDamage(9999)
			dmginfo:SetAttacker(self.Owner)
			dmginfo:SetInflictor(self)
			dmginfo:SetDamageType(DMG_DIRECT)
			self.MarkedPlayer:TakeDamageInfo(dmginfo)
			
			-- Daj exp właścicielowi
			if IsValid(self.Owner) then
				self.Owner:AddExp(250, true)
			end
			
			-- Usuń z listy (bez resetu cooldownu)
			self.MarkedPlayer = nil
			self.MarkedDeathTime = 0
			self.CurrentMarkedName = ""
			
			-- Wyślij aktualizację do klienta
			self:UpdateMarkedList()
		end
	end
end

SWEP.NextPrimary = 0
function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextPrimary > CurTime() then return end
	self.NextPrimary = CurTime() + self.Primary.Delay
	
	self:EmitSound( self.Primary.Sound )
	
	if !SERVER then return end
	
	local trace = util.TraceHull( {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 45,
		filter = self.Owner,
		mask = MASK_SHOT,
		maxs = Vector( 6, 6, 6 ),
		mins = Vector( -6, -6, -6 ),
	} )
	
	local ent = trace.Entity
	if IsValid( ent ) then
		if ent:IsPlayer() then
			if ent:GTeam() == TEAM_SPEC then return end
			if ent:GTeam() == TEAM_SCP and ent:GetNClass() != ROLES.ROLE_SCP035 then return end
			ent:TakeDamage( math.random( 10, 20 ), self.Owner, self.Owner )
		else
			self:SCPDamageEvent( ent, 10 )
		end
	end
end

-- PPM - Oznaczenie gracza do śmierci
function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextMark > CurTime() then return end
	
	if !SERVER then return end
	
	local trace = util.TraceLine( {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 2000,
		filter = self.Owner,
		mask = MASK_SHOT
	} )
	
	local ent = trace.Entity
	if IsValid( ent ) and ent:IsPlayer() then
		if ent:GTeam() == TEAM_SPEC then return end
						if ent:GTeam() == TEAM_SCP and ent:GetNClass() != ROLES.ROLE_SCP035 then return end
		
		-- Oznacz gracza
		self.NextMark = CurTime() + self.MarkCooldown
		
		-- Zapisz gracza
		self.MarkedPlayer = ent
		self.MarkedDeathTime = CurTime() + 120 -- 2 minuty
		self.CurrentMarkedName = ent:Nick()
		
		-- Efekty
		ent:EmitSound("ambient/atmosphere/cave_hit5.wav", 75, 100)
		self.Owner:EmitSound("npc/scanner/scanner_photo1.wav", 75, 100)
		
		-- Powiadom gracza że został oznaczony
		net.Start("SCP023_MarkedForDeath")
			net.WriteFloat(self.MarkedDeathTime) -- Wyślij czas śmierci
		net.Send(ent)
		
		-- Aktualizuj listę oznaczonych dla HUD
		self:UpdateMarkedList()
	end
end

-- Klawisz R - Dash
function SWEP:Reload()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextDash > CurTime() then return end
	
	self.NextDash = CurTime() + self.DashCooldown
	
	if SERVER then
		-- Dash do przodu z większą siłą
		local forward = self.Owner:GetAimVector()
		forward.z = 0
		forward:Normalize()
		
		-- Dodaj siłę poziomą i pionową
		local vel = forward * 1500 + Vector(0, 0, 400)
		
		self.Owner:SetVelocity(vel)
		
		-- Efekt cząsteczkowy
		local effectdata = EffectData()
		effectdata:SetOrigin(self.Owner:GetPos())
		effectdata:SetNormal(self.Owner:GetAimVector())
		effectdata:SetScale(1)
		util.Effect("ManhackSparks", effectdata)
	end
	
	return false -- Zapobiega przeładowaniu
end

-- Aktualizacja listy oznaczonych graczy
function SWEP:UpdateMarkedList()
	if !SERVER then return end
	
	net.Start("SCP023_UpdateMarked")
		net.WriteEntity(self)
		net.WriteFloat(self.NextMark)
		net.WriteString(self.CurrentMarkedName)
		net.WriteFloat(self.MarkedDeathTime)
	net.Send(self.Owner)
end

-- Client-side
if CLIENT then
	-- Hook na śmierć gracza - usuń timer
	hook.Add("PlayerDeath", "SCP023_RemoveTimerOnDeath", function(victim, inflictor, attacker)
		if victim == LocalPlayer() and LocalPlayer().SCP023_DeathTime then
			-- Usuń timer i oznaczenie
			LocalPlayer().SCP023_DeathTime = nil
			hook.Remove("HUDPaint", "SCP023_DeathWarning")
		end
	end)
	
	-- Odbieranie informacji o oznaczeniu
	net.Receive("SCP023_MarkedForDeath", function()
		local deathTime = net.ReadFloat()
		
		LocalPlayer():PrintMessage(HUD_PRINTTALK, "You have been marked for death by SCP-023! Kill someone within 2 minutes to save yourself!")
		surface.PlaySound("ambient/alarms/warningbell1.wav")
		
		-- Zapisz czas śmierci globalnie dla gracza
		LocalPlayer().SCP023_DeathTime = deathTime
		
		-- Pokaż większe ostrzeżenie z licznikiem
		hook.Add("HUDPaint", "SCP023_DeathWarning", function()
			-- Sprawdź czy gracz nadal jest oznaczony i żywy
			if not LocalPlayer().SCP023_DeathTime or not LocalPlayer():Alive() then
				hook.Remove("HUDPaint", "SCP023_DeathWarning")
				LocalPlayer().SCP023_DeathTime = nil
				return
			end
			
			local timeLeft = LocalPlayer().SCP023_DeathTime - CurTime()
			if timeLeft <= 0 then
				hook.Remove("HUDPaint", "SCP023_DeathWarning")
				LocalPlayer().SCP023_DeathTime = nil
				return
			end
			
			-- Główny tekst
			local text = "MARKED FOR DEATH - KILL TO SURVIVE!"
			surface.SetFont("DermaLarge")
			local tw, th = surface.GetTextSize(text)
			local x, y = ScrW()/2 - tw/2, ScrH()/2 - 100
			
			-- Pulsujący efekt
			local pulse = math.sin(CurTime() * 4) * 0.5 + 0.5
			local alpha = 150 + pulse * 105
			
			-- Tło dla głównego tekstu
			surface.SetDrawColor(0, 0, 0, alpha * 0.8)
			surface.DrawRect(x - 10, y - 5, tw + 20, th + 10)
			
			-- Główny tekst
			surface.SetTextColor(255, 50 + pulse * 205, 50, alpha)
			surface.SetTextPos(x, y)
			surface.DrawText(text)
			
			-- LICZNIK CZASU
			local timerText = string.format("TIME LEFT: %d:%02d", math.floor(timeLeft / 60), math.floor(timeLeft % 60))
			surface.SetFont("DermaLarge")
			local timerW, timerH = surface.GetTextSize(timerText)
			local timerX, timerY = ScrW()/2 - timerW/2, y + th + 20
			
			-- Kolor zależny od czasu
			local timerColor = Color(255, 255, 255, 255)
			if timeLeft < 30 then
				-- Czerwony gdy mało czasu
				timerColor = Color(255, 50, 50, 255)
			elseif timeLeft < 60 then
				-- Żółty gdy średnio czasu
				timerColor = Color(255, 255, 50, 255)
			end
			
			-- Tło dla licznika
			surface.SetDrawColor(0, 0, 0, 200)
			surface.DrawRect(timerX - 10, timerY - 5, timerW + 20, timerH + 10)
			
			-- Obramowanie licznika
			surface.SetDrawColor(timerColor.r, timerColor.g, timerColor.b, 255)
			surface.DrawOutlinedRect(timerX - 10, timerY - 5, timerW + 20, timerH + 10)
			
			-- Tekst licznika
			surface.SetTextColor(timerColor.r, timerColor.g, timerColor.b, 255)
			surface.SetTextPos(timerX, timerY)
			surface.DrawText(timerText)
			
			-- Dodatkowy pasek postępu
			local barY = timerY + timerH + 15
			local barWidth = 300
			local barHeight = 10
			local barX = ScrW()/2 - barWidth/2
			
			-- Tło paska
			surface.SetDrawColor(50, 50, 50, 200)
			surface.DrawRect(barX, barY, barWidth, barHeight)
			
			-- Pasek postępu
			local progress = timeLeft / 120 -- 120 sekund = 2 minuty
			surface.SetDrawColor(timerColor.r, timerColor.g, timerColor.b, 255)
			surface.DrawRect(barX, barY, barWidth * progress, barHeight)
			
			-- Obramowanie paska
			surface.SetDrawColor(100, 100, 100, 255)
			surface.DrawOutlinedRect(barX, barY, barWidth, barHeight)
		end)
		
		-- Nie usuwaj automatycznie - hook sam się usunie gdy czas się skończy
	end)
	
	-- Odbieranie informacji o usunięciu oznaczenia
	net.Receive("SCP023_MarkRemoved", function()
		LocalPlayer():PrintMessage(HUD_PRINTTALK, "You have been saved! The mark of death has been lifted!")
		surface.PlaySound("buttons/button9.wav")
		
		-- Usuń oznaczenie i ostrzeżenie
		LocalPlayer().SCP023_DeathTime = nil
		hook.Remove("HUDPaint", "SCP023_DeathWarning")
		
		-- Pokaż komunikat o ocaleniu
		hook.Add("HUDPaint", "SCP023_SavedNotice", function()
			local text = "YOU HAVE BEEN SAVED!"
			surface.SetFont("DermaLarge")
			local tw, th = surface.GetTextSize(text)
			local x, y = ScrW()/2 - tw/2, ScrH()/2 - 100
			
			-- Zielony tekst
			surface.SetTextColor(50, 255, 50, 255)
			surface.SetTextPos(x, y)
			surface.DrawText(text)
		end)
		
		timer.Simple(3, function()
			hook.Remove("HUDPaint", "SCP023_SavedNotice")
		end)
	end)
	
	-- Odbieranie listy oznaczonych graczy
	net.Receive("SCP023_UpdateMarked", function()
		local wep = net.ReadEntity()
		if !IsValid(wep) then return end
		
		wep.NextMark = net.ReadFloat()
		wep.CurrentMarkedName = net.ReadString()
		wep.MarkedDeathTime = net.ReadFloat()
	end)
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
	
	-- Tło HUD (tak jak w SCP-069)
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
	local titleW, titleH = surface.GetTextSize("SCP-023")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-023")
	
	-- Cooldowny (wszystkie w jednej linii: LMB, R, PPM)
	local cooldownY = hudY + 60
	local barWidth = 120
	local barHeight = 8
	local totalWidth = barWidth * 3 + 60 -- 3 paski + odstępy
	local startX = centerX - totalWidth / 2
	
	-- LMB (Bite) Cooldown - pierwszy
	local lpmBarX = startX
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(lpmBarX, cooldownY - 15)
	surface.DrawText("LMB - Bite")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(lpmBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(lpmBarX, cooldownY, barWidth, barHeight)
	
	local lpmCooldown = 0
	if self.NextPrimary and self.NextPrimary > CurTime() then
		lpmCooldown = self.NextPrimary - CurTime()
	end
	
	if lpmCooldown > 0 then
		local progress = 1 - (lpmCooldown / self.Primary.Delay)
		surface.SetDrawColor(255, 100, 100, 255)
		surface.DrawRect(lpmBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 150, 150, 255)
		surface.SetTextPos(lpmBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", lpmCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(lpmBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(lpmBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- R (Dash) - środkowy
	local dashBarX = startX + barWidth + 30
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(dashBarX, cooldownY - 15)
	surface.DrawText("R - Dash")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(dashBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(dashBarX, cooldownY, barWidth, barHeight)
	
	local dashCooldown = 0
	if self.NextDash and self.NextDash > CurTime() then
		dashCooldown = self.NextDash - CurTime()
	end
	
	if dashCooldown > 0 then
		local progress = 1 - (dashCooldown / self.DashCooldown)
		surface.SetDrawColor(100, 200, 255, 255)
		surface.DrawRect(dashBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 200, 255, 255)
		surface.SetTextPos(dashBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", dashCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(dashBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(dashBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- RMB (Mark) Cooldown - trzeci
	local ppmBarX = startX + (barWidth + 30) * 2
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(ppmBarX, cooldownY - 15)
	surface.DrawText("RMB - Mark")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(ppmBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(ppmBarX, cooldownY, barWidth, barHeight)
	
	local markCooldown = 0
	if self.NextMark and self.NextMark > CurTime() then
		markCooldown = self.NextMark - CurTime()
	end
	
	if markCooldown > 0 then
		local progress = 1 - (markCooldown / self.MarkCooldown)
		surface.SetDrawColor(255, 215, 0, 255)
		surface.DrawRect(ppmBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 255, 150, 255)
		surface.SetTextPos(ppmBarX, cooldownY + 10)
		surface.DrawText(string.format("%.0fs", markCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(ppmBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(ppmBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- Informacja o oznaczonym graczu z timerem (na dole HUD-u po środku)
	if self.CurrentMarkedName and self.CurrentMarkedName != "" then
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 215, 0, 255)
		
		local timeLeft = 0
		if self.MarkedDeathTime and self.MarkedDeathTime > CurTime() then
			timeLeft = self.MarkedDeathTime - CurTime()
		end
		
		local markedText = string.format("Marked: %s - %ds", self.CurrentMarkedName, math.ceil(timeLeft))
		local tw, th = surface.GetTextSize(markedText)
		surface.SetTextPos(centerX - tw/2, hudY + hudHeight - 20)
		surface.DrawText(markedText)
	end
	
	-- Celownik
	local x = ScrW() / 2.0
	local y = ScrH() / 2.0
	
	local scale = 0.3
	surface.SetDrawColor( 255, 0, 0, 255 )
	
	local gap = 5
	local length = gap + 20 * scale
	surface.DrawLine( x - length, y, x - gap, y )
	surface.DrawLine( x + length, y, x + gap, y )
	surface.DrawLine( x, y - length, x, y - gap )
	surface.DrawLine( x, y + length, x, y + gap )
end

if SERVER then
	util.AddNetworkString("SCP023_UpdateMarked")
	util.AddNetworkString("SCP023_MarkedForDeath")
	util.AddNetworkString("SCP023_MarkRemoved")
end