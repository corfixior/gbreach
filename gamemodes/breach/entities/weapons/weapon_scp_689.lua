AddCSLuaFile()

SWEP.Base 			= "weapon_scp_base"
SWEP.PrintName		= "SCP-689"

SWEP.Primary.Delay 	=  15
SWEP.Sound			= "scp/689/689Attack.ogg"

SWEP.DrawCrosshair	= true
SWEP.HoldType 		= "normal"

SWEP.Targets = {}
SWEP.TargetTimers = {} -- Przechowuje czasy dodania celów

function SWEP:SetupDataTables()
	self:NetworkVar( "Entity", 0, "NCurTarget" )
	self:NetworkVar( "Float", 0, "NextRewind" )
	self:SetNCurTarget( nil )
	self:SetNextRewind( 0 )
end

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_689" )

	self:SetHoldType( self.HoldType )
	
	-- Inicjalizacja dla umiejętności rewind (jak ult Ekko)
	self.RewindPositions = {}
	self.RewindDelay = 60 -- Cooldown na rewind
	self.RewindTime = 4 -- Cofanie do pozycji sprzed 4 sekund
	self.LastPositionSave = 0
	
	-- Ghost model dla rewind (jak Ekko)
	if CLIENT then
		timer.Simple(0.1, function()
			if IsValid(self) and IsValid(self.Owner) then
				self.GhostModel = ClientsideModel(self.Owner:GetModel())
				self.GhostModel:SetNoDraw(true)
				self.GhostModel:SetMaterial("models/wireframe")
				self.GhostModel:SetRenderMode(RENDERMODE_TRANSALPHA)
				self.GhostModel:SetColor(Color(128, 0, 255, 100)) -- Fioletowy przezroczysty
			end
		end)
	end
end

function SWEP:OnRemove()
	if CLIENT and IsValid(self.GhostModel) then
		self.GhostModel:Remove()
	end
end

SWEP.ntabupdate = 0
SWEP.NextGlassBreak = 0
function SWEP:Think()
	if postround or preparing then return end
	
	-- Wybijanie szyb - używamy KeyPressed hook zamiast KeyDown
	
	if self.ntabupdate < CurTime() then
		self.ntabupdate = CurTime() + 3 --delay for performance

		if SERVER then
			net.Start( "689" )
				net.WriteTable( self.Targets )
			net.Send( self.Owner )
		end
	end

	if CLIENT then
		-- Zapisywanie pozycji dla ghost modelu także po stronie klienta
		if self.LastPositionSave < CurTime() then
			self.LastPositionSave = CurTime() + 0.5
			table.insert(self.RewindPositions, {
				pos = self.Owner:GetPos(),
				ang = self.Owner:EyeAngles(),
				time = CurTime(),
				health = self.Owner:Health()
			})
			
			-- Usuń stare pozycje
			for i = #self.RewindPositions, 1, -1 do
				if self.RewindPositions[i].time < CurTime() - self.RewindTime then
					table.remove(self.RewindPositions, i)
				end
			end
		end
		
		-- Aktualizuj pozycję ghost modelu
		if IsValid(self.GhostModel) and #self.RewindPositions > 0 then
			local oldestPos = self.RewindPositions[1]
			self.GhostModel:SetPos(oldestPos.pos)
			self.GhostModel:SetAngles(oldestPos.ang)
			
			-- Ustaw sekwencję animacji aby uniknąć T-pose
			local seq = self.Owner:GetSequence()
			if seq and seq >= 0 then
				self.GhostModel:SetSequence(seq)
				self.GhostModel:SetCycle(self.Owner:GetCycle())
				self.GhostModel:SetPlaybackRate(0) -- Zatrzymaj animację
			end
			
			self.GhostModel:SetupBones()
			
			-- Pokaż ghost tylko gdy rewind jest gotowy
			local nextRewind = self:GetNextRewind()
			if nextRewind <= CurTime() and self.Owner == LocalPlayer() then
				self.GhostModel:SetNoDraw(false)
			else
				self.GhostModel:SetNoDraw(true)
			end
		end
		return
	end
	
	-- Zapisywanie pozycji dla rewind co 0.5 sekundy
	if self.LastPositionSave < CurTime() then
		self.LastPositionSave = CurTime() + 0.5
		table.insert(self.RewindPositions, {
			pos = self.Owner:GetPos(),
			ang = self.Owner:EyeAngles(),
			time = CurTime(),
			health = self.Owner:Health()
		})
		
		-- Usuń stare pozycje (starsze niż RewindTime)
		for i = #self.RewindPositions, 1, -1 do
			if self.RewindPositions[i].time < CurTime() - self.RewindTime then
				table.remove(self.RewindPositions, i)
			end
		end
	end

	local ownerpos = self.Owner:GetPos()
	local currentTime = CurTime()
	
	-- Usuń cele które są za długo na liście (15 sekund)
	for k = #self.Targets, 1, -1 do
		local v = self.Targets[k]
		if !IsValid( v ) or !v:Alive() or v:GTeam() == TEAM_SPEC or (v:GTeam() == TEAM_SCP and v:GetNClass() != ROLES.ROLE_SCP035) or v.Using714 or v:GetPos():DistToSqr(ownerpos) > 9000000 then
			table.remove(self.Targets, k)
			self.TargetTimers[v] = nil
		elseif self.TargetTimers[v] and currentTime - self.TargetTimers[v] > 15 then
			-- Usuń cel po 15 sekundach
			table.remove(self.Targets, k)
			self.TargetTimers[v] = nil
		end
	end

	for k, v in pairs( player.GetAll() ) do
		if v != self.Owner and !table.HasValue( self.Targets, v ) and !v.Using714 then
			if v:IsPlayer() and v:GTeam() != TEAM_SPEC and (v:GTeam() != TEAM_SCP or v:GetNClass() == ROLES.ROLE_SCP035) then
				local treyes = util.TraceLine( {
					start = v:EyePos(),
					endpos = self.Owner:EyePos(),
					mask = MASK_SHOT_HULL,
					filter = { v, self.Owner }
				} )

				local trpos = util.TraceLine( {
					start = v:EyePos(),
					endpos = self.Owner:GetPos(),
					mask = MASK_SHOT_HULL,
					filter = { v, self.Owner }
				} )

				if !treyes.Hit or !trpos.Hit then
					local trnormal = !treyes.Hit and treyes.Normal or !trpos.Hit and trpos.Normal
					local eyenormal = v:EyeAngles():Forward()

					if eyenormal:Dot( trnormal ) > 0.70 then
						table.insert( self.Targets, v )
						self.TargetTimers[v] = currentTime -- Zapisz czas dodania celu
					end
				end
			end
		end
	end
end

SWEP.NextPrimary = 0

function SWEP:PrimaryAttack()
	if preparing or postround then return end
	//if not IsFirstTimePredicted() then return end
	if #self.Targets < 1 then return end
	if self.NextPrimary > CurTime() then return end
	self.NextPrimary = CurTime() + self.Primary.Delay
	self:SetNWFloat("NextPrimary", self.NextPrimary) -- Synchronizuj z klientem

	if SERVER then
		local at = self:GetNCurTarget()
		if !table.HasValue( self.Targets, at ) then at = nil print( "689 tried to attack invalid entity!" ) end

		if !IsValid( at ) then
			at = table.Random(self.Targets)
			self:SetNCurTarget( at )
		end

		-- Odtwórz dźwięk tylko na ofierze
		at:EmitSound(self.Sound)
		
		-- Zablokuj skakanie i zmień broń na holster
		if IsValid(at) and at:IsPlayer() then
			at:SetJumpPower(0) -- Zablokuj skakanie
			at:StripWeapons() -- Usuń wszystkie bronie
			at:Give("br_holster") -- Daj holster
			at:SelectWeapon("br_holster") -- Wybierz holster
		end

		timer.Create("CheckTimer"..self.Owner:SteamID64(), 0.5, math.floor(self.Primary.Delay), function()
			if !( IsValid( self ) and IsValid( self.Owner ) and self.Owner:Alive() and IsValid( at ) and at:Alive() and at:GTeam() != TEAM_SPEC ) or at.Using714 then
				timer.Destroy("CheckTimer")
				timer.Destroy( "KillTimer"..self.Owner:SteamID64() )
				-- Przywróć skakanie jeśli atak został przerwany
				if IsValid(at) and at:IsPlayer() and at:Alive() then
					at:SetJumpPower(200) -- Domyślna wartość
				end
			end
		end )

		timer.Create("KillTimer"..self.Owner:SteamID64(), math.floor(self.Primary.Delay / 2), 1, function()
			if IsValid( self ) and IsValid( self.Owner ) and self.Owner:Alive() and IsValid( at ) and at:Alive() and at:GTeam() != TEAM_SPEC then
				local pos = at:GetPos()
				
				-- Użyj TakeDamageInfo zamiast Kill() aby system punktów działał prawidłowo
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(at:Health() + 100) -- Zapewnij zabicie
				dmginfo:SetAttacker(self.Owner)
				dmginfo:SetInflictor(self)
				dmginfo:SetDamageType(DMG_DIRECT)
				at:TakeDamageInfo(dmginfo)
				
				self.Owner:SetPos(pos)
				self.Owner:AddExp(125, true)
				table.RemoveByValue(self.Targets, at)
				self:SetNCurTarget( nil )

				local toremove = math.ceil( #self.Targets / 2 )

				for i = 1, toremove do
					print( "rem!", table.remove( self.Targets, math.random( 0, #self.Targets ) ) )
					
				end
			end
		end )
	end
end

SWEP.NextSecondary = 0
function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextSecondary > CurTime() then return end
	
	if SERVER then
		-- Umiejętność Rewind (jak ult Ekko)
		if #self.RewindPositions > 0 then
			local oldestPos = self.RewindPositions[1]
			

			
			-- Efekt wizualny przed teleportacją usunięty
			
			-- Teleportuj do starej pozycji
			self.Owner:SetPos(oldestPos.pos)
			self.Owner:SetEyeAngles(oldestPos.ang)
			
			-- Przywróć HP jeśli było wyższe
			if oldestPos.health > self.Owner:Health() then
				self.Owner:SetHealth(oldestPos.health)
			end
			

			
			-- Efekt po teleportacji usunięty
			
			-- Wyczyść historię pozycji
			self.RewindPositions = {}
			
			-- Ustaw cooldown
			self.NextSecondary = CurTime() + self.RewindDelay
			self:SetNextRewind(self.NextSecondary)
		end
	end
end

SWEP.LastReload = 0

function SWEP:Reload()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end

	if !SERVER then return end
	if self.NextPrimary > CurTime() then return end
	if self.LastReload > CurTime() then return end

	self.LastReload = CurTime() + 0.25

	local CurTarget = self:GetNCurTarget()
	if !IsValid( CurTarget ) then
		self:SetNCurTarget( self.Targets[1] )
		return
	end

	for i, v in ipairs( self.Targets ) do
		if v == CurTarget then
			if i == #self.Targets then self:SetNCurTarget( self.Targets[1] ) return end
			self:SetNCurTarget( self.Targets[i + 1] )
			return
		end
	end
end


function SWEP:DrawHUD()
	if disablehud == true then return end
	if self.Owner:Team() == TEAM_SPEC then return end
	
	self:DrawSCPHUD()
	
	-- Lista celów po prawej stronie
	if #self.Targets > 0 then
		draw.Text( {
			text = self.Lang.HUD.targets..":",
			pos = { ScrW() * 0.97, ScrH() / 3 - 35 },
			font = "173font",
			color = Color(200, 200, 200, 255),
			xalign = TEXT_ALIGN_RIGHT,
			yalign = TEXT_ALIGN_CENTER,
		})
	end
	for i, v in ipairs( self.Targets ) do
		local add = v == self:GetNCurTarget() and "> " or ""
		local col = v == self:GetNCurTarget() and Color(255, 100, 100, 255) or Color(150, 150, 150, 255)
		draw.Text( {
			text = add..v:GetName(),
			pos = { ScrW() * 0.99, ScrH() / 3 + i * 25 },
			font = "173font",
			color = col,
			xalign = TEXT_ALIGN_RIGHT,
			yalign = TEXT_ALIGN_CENTER,
		})
	end
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
	local titleW, titleH = surface.GetTextSize("SCP-689")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-689")
	
	-- Status ataku
	local nextPrimary = self:GetNWFloat("NextPrimary", 0)
	local isAttacking = nextPrimary > CurTime()
	local currentTarget = self:GetNCurTarget()
	
	if isAttacking and IsValid(currentTarget) then
		-- Usunięto czerwony napis "ATTACKING" na życzenie użytkownika
		-- surface.SetFont("DermaDefaultBold")
		-- surface.SetTextColor(255, 0, 0, 255)
		-- local attackText = "ATTACKING: " .. currentTarget:GetName()
		-- local attackW, attackH = surface.GetTextSize(attackText)
		-- surface.SetTextPos(centerX - attackW / 2, hudY + 35)
		-- surface.DrawText(attackText)
	elseif #self.Targets > 0 then
		-- Usunięto zielony napis "TARGETS" na życzenie użytkownika
		-- surface.SetFont("DermaDefaultBold")
		-- surface.SetTextColor(100, 255, 100, 255)
		-- local targetsText = "TARGETS: " .. #self.Targets
		-- local targetsW, targetsH = surface.GetTextSize(targetsText)
		-- surface.SetTextPos(centerX - targetsW / 2, hudY + 35)
		-- surface.DrawText(targetsText)
	else
		-- Usunięto żółty napis "NO TARGETS" na życzenie użytkownika
		-- surface.SetFont("DermaDefaultBold")
		-- surface.SetTextColor(255, 255, 100, 255)
		-- local noTargetsText = "NO TARGETS"
		-- local noTargetsW, noTargetsH = surface.GetTextSize(noTargetsText)
		-- surface.SetTextPos(centerX - noTargetsW / 2, hudY + 35)
		-- surface.DrawText(noTargetsText)
	end
	
	-- Cooldowny
	local cooldownY = hudY + 60
	local barWidth = 150
	local barHeight = 8
	local spacing = 20
	local totalWidth = barWidth * 3 + spacing * 2
	local startX = centerX - totalWidth / 2
	
	-- LMB Cooldown (Attack)
	local lmbBarX = startX
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(lmbBarX, cooldownY - 15)
	surface.DrawText("LMB - Attack")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
	
	local attackCooldown = 0
	if nextPrimary > CurTime() then
		attackCooldown = nextPrimary - CurTime()
	end
	
	if attackCooldown > 0 then
		local progress = 1 - (attackCooldown / self.Primary.Delay)
		surface.SetDrawColor(255, 100, 100, 255)
		surface.DrawRect(lmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 150, 150, 255)
		surface.SetTextPos(lmbBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", attackCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(lmbBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- R Cooldown (Switch Target)
	local rBarX = startX + barWidth + spacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rBarX, cooldownY - 15)
	surface.DrawText("R - Switch")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rBarX, cooldownY, barWidth, barHeight)
	
	if #self.Targets > 0 then
		surface.SetDrawColor(100, 100, 255, 255) -- Niebieski dla switch target
		surface.DrawRect(rBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 150, 255, 255)
		surface.SetTextPos(rBarX, cooldownY + 10)
		surface.DrawText("AVAILABLE")
	else
		surface.SetFont("DermaDefault")
		surface.SetTextColor(100, 100, 100, 255)
		surface.SetTextPos(rBarX, cooldownY + 10)
		surface.DrawText("NO TARGETS")
	end
	
	-- RMB (Rewind)
	local rmbBarX = startX + (barWidth + spacing) * 2
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rmbBarX, cooldownY - 15)
	surface.DrawText("RMB - Rewind")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
	
	local rewindCooldown = 0
	local nextRewind = self:GetNextRewind()
	if nextRewind > CurTime() then
		rewindCooldown = nextRewind - CurTime()
	end
	
	if rewindCooldown > 0 then
		local progress = 1 - (rewindCooldown / self.RewindDelay)
		surface.SetDrawColor(128, 0, 255, 255) -- Fioletowy dla rewind
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(200, 150, 255, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", rewindCooldown))
	else
		surface.SetDrawColor(200, 100, 255, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(220, 180, 255, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- Celownik
	local x = ScrW() / 2.0
	local y = ScrH() / 2.0
	
	local scale = 0.3
	-- Czerwony celownik gdy atakuje
	if isAttacking then
		surface.SetDrawColor(255, 0, 0, 255)
	else
		surface.SetDrawColor(0, 255, 0, 255)
	end
	
	local gap = 5
	local length = gap + 20 * scale
	surface.DrawLine( x - length, y, x - gap, y )
	surface.DrawLine( x + length, y, x + gap, y )
	surface.DrawLine( x, y - length, x, y - gap )
	surface.DrawLine( x, y + length, x, y + gap )
	
	-- Info o rozbijaniu szyb
	surface.SetFont("DermaDefault")
	surface.SetTextColor(150, 150, 150, 255)
	local glassText = "[E] - Break Glass"
	local glassW, glassH = surface.GetTextSize(glassText)
	surface.SetTextPos(centerX - glassW / 2, hudY + hudHeight - 25)
	surface.DrawText(glassText)
end

-- Renderowanie ghost modelu - tylko dla właściciela broni
hook.Add("PostDrawTranslucentRenderables", "SCP689_GhostModel", function(bDepth, bSkybox, b3DSkybox)
	if bSkybox or b3DSkybox then return end
	
	local ply = LocalPlayer()
	if !IsValid(ply) or !ply:Alive() then return end
	
	local wep = ply:GetActiveWeapon()
	if !IsValid(wep) or wep:GetClass() != "weapon_scp_689" then return end
	
	-- WAŻNE: Renderuj ghost tylko dla właściciela broni
	if wep.Owner != ply then return end
	
	if !IsValid(wep.GhostModel) or wep.GhostModel:GetNoDraw() then return end
	
	-- Ustaw model gracza
	local mdl = ply:GetModel()
	if wep.GhostModel:GetModel() != mdl then
		wep.GhostModel:SetModel(mdl)
	end
	
	-- Renderuj ghost z efektem
	render.SetBlend(0.5)
	render.SetColorModulation(0.5, 0, 1) -- Fioletowy
	wep.GhostModel:DrawModel()
	render.SetColorModulation(1, 1, 1)
	render.SetBlend(1)
	
	-- Dodaj efekt świecenia
	local pos = wep.GhostModel:GetPos()
	render.SetMaterial(Material("sprites/light_glow02_add"))
	render.DrawSprite(pos + Vector(0, 0, 40), 128, 128, Color(128, 0, 255, 100))
end)

-- Rozbijanie szyb na środkowy przycisk myszy lub E
if SERVER then
	hook.Add("KeyPress", "SCP689_GlassBreak", function(ply, key)
		if !IsValid(ply) or !ply:Alive() then return end
		local wep = ply:GetActiveWeapon()
		if !IsValid(wep) or wep:GetClass() != "weapon_scp_689" then return end
		
		-- Sprawdź czy to środkowy przycisk myszy (107) lub E (32)
		if key != 107 and key != 32 then return end
		
		if wep.NextGlassBreak and wep.NextGlassBreak > CurTime() then return end
		wep.NextGlassBreak = CurTime() + 0.5
		
		-- Znajdź szybę przed graczem
		local tr = util.TraceLine({
			start = ply:GetShootPos(),
			endpos = ply:GetShootPos() + ply:GetAimVector() * 100,
			filter = ply
		})
		
		local ent = tr.Entity
		if IsValid(ent) then
			if ent:GetClass() == "func_breakable" or ent:GetClass() == "func_breakable_surf" then
				ent:Fire("Break")
				-- Usunięto dźwięk rozbijania szyby
				
				-- Efekt wizualny usunięty na życzenie użytkownika
				-- local effectdata = EffectData()
				-- effectdata:SetOrigin(tr.HitPos)
				-- effectdata:SetNormal(tr.HitNormal)
				-- util.Effect("GlassImpact", effectdata)
			elseif string.find(ent:GetClass(), "door") then
				-- Możliwość rozbicia drzwi ze szkłem
				wep:SCPDamageEvent(ent, 100)
			end
		end
	end)
end