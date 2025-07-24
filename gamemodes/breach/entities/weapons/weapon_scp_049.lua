AddCSLuaFile()

SWEP.Base 		= "weapon_scp_base"
SWEP.PrintName	= "SCP-049 Rework"
SWEP.HoldType	= "normal"

SWEP.AttackDelay			= 3
SWEP.NextAttackW			= 0
SWEP.GasCooldown			= 60 -- Cooldown dla gazu w sekundach (1 minuta)
SWEP.GasDuration			= 10 -- Czas trwania gazu
SWEP.GasRadius				= 300 -- Promień gazu

-- Typy zombie
SWEP.ZombieTypes = {
	{
		name = "Normal Zombie",
		model = "models/player/zombie_classic.mdl",
		health = 750,
		speed = 180,
		color = Color(100, 255, 100)
	},
	{
		name = "Fast Zombie", 
		model = "models/player/zombie_fast.mdl",
		health = 500,
		speed = 280,
		color = Color(255, 100, 100)
	},
	{
		name = "Heavy Zombie",
		model = "models/player/zombie_soldier.mdl", 
		health = 1000,
		speed = 120,
		color = Color(100, 100, 255)
	}
}

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_049" )
	self:SetHoldType( self.HoldType )
	
	self.CurrentZombieType = 1
	self.NextGas = 0
	self.NextModeSwitch = 0
	self.ActiveGases = {}
	
	-- Networking
	if SERVER then
		util.AddNetworkString("SCP049_UpdateZombieType")
		util.AddNetworkString("SCP049_UpdateGas")
		util.AddNetworkString("SCP049_CreateGas")
	end
	
	if CLIENT then
		self.WepSelectIcon = surface.GetTextureID("breach/wep_049")
		self.GasParticles = {}
	end
	
	-- Dźwięki
	for i=0, 4 do
		sound.Add({
			name = "attack"..i,
			channel = CHAN_STATIC,
			volume = 1.0,
			level = 130,
			pitch = 100,
			sound = "scp/049/attack"..i..".ogg"
		})
	end
end

-- LMB - Zarażenie żywych graczy
function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextAttackW > CurTime() then return end
	
	self.NextAttackW = CurTime() + self.AttackDelay
	
	if SERVER then
		self.Owner:EmitSound("attack"..math.random(0, 4))
		
		local tr = util.TraceHull({
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + (self.Owner:GetAimVector() * 100),
			filter = self.Owner,
			mins = Vector(-10, -10, -10),
			maxs = Vector(10, 10, 10),
			mask = MASK_SHOT_HULL
		})
		
		local ent = tr.Entity
		
		-- Zarażenie żywego gracza
		if IsValid(ent) and ent:IsPlayer() then
			if (ent:GTeam() == TEAM_SCP and ent:GetNClass() != ROLES.ROLE_SCP035) or ent:GTeam() == TEAM_SPEC then return end
			if ent.Using714 then return end
			
			-- Zamień w wybrany typ zombie
			local zombieType = self.ZombieTypes[self.CurrentZombieType]
			local scp = GetSCP("SCP0492")
			
			if scp then
				scp:SetupPlayer(ent)
				
				-- Ustaw parametry zombie
				timer.Simple(0.1, function()
					if IsValid(ent) and ent:Alive() then
						-- Ustaw model
						ent:SetModel(zombieType.model)
						
						-- Ustaw HP
						ent:SetHealth(zombieType.health)
						ent:SetMaxHealth(zombieType.health)
						
						-- Ustaw prędkość (walk speed = run speed)
						ent:SetRunSpeed(zombieType.speed)
						ent:SetWalkSpeed(zombieType.speed)
						
						-- Dodaj identyfikator typu
						ent.ZombieType = self.CurrentZombieType
						
						-- Upewnij się, że gracz jest aktywny (naprawia widoczność nicku)
						ent:SetNActive(true)
						ent.ActivePlayer = true
					end
				end)
			end
			
			self.Owner:AddExp(200, true)
			roundstats.zombies = roundstats.zombies + 1
		elseif IsValid(ent) then
			-- Większe obrażenia dla szyb
			if ent:GetClass() == "func_breakable" then
				self:SCPDamageEvent(ent, 100)
			else
				self:SCPDamageEvent(ent, 10)
			end
		end
	end
end

-- PPM - Gaz trujący
function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextGas > CurTime() then return end
	
	if SERVER then
		self.NextGas = CurTime() + self.GasCooldown
		
		-- Stwórz chmurę gazu
		local gasPos = self.Owner:GetPos()
		local gasData = {
			pos = gasPos,
			endtime = CurTime() + self.GasDuration,
			owner = self.Owner
		}
		
		table.insert(self.ActiveGases, gasData)
		
		-- Wyślij do klientów
		net.Start("SCP049_CreateGas")
			net.WriteEntity(self)
			net.WriteVector(gasPos)
			net.WriteFloat(self.GasDuration)
		net.Broadcast()
		
		-- Stwórz entity dla dźwięku gazu
		local soundEnt = ents.Create("info_target")
		soundEnt:SetPos(gasPos)
		soundEnt:Spawn()
		soundEnt:EmitSound("ambient/gas/steam2.wav", 75, 80)
		gasData.soundEnt = soundEnt
		
		-- Usuń dźwięk po zakończeniu gazu
		timer.Simple(self.GasDuration, function()
			if IsValid(soundEnt) then
				soundEnt:StopSound("ambient/gas/steam2.wav")
				soundEnt:Remove()
			end
		end)
		
		-- Timer do sprawdzania graczy w gazie
		local timerID = "SCP049_Gas_" .. self:EntIndex() .. "_" .. #self.ActiveGases
		timer.Create(timerID, 0.5, self.GasDuration * 2, function()
			if not IsValid(self) or not IsValid(self.Owner) then
				timer.Remove(timerID)
				return
			end
			
			-- Sprawdź czy gaz nadal aktywny
			if CurTime() > gasData.endtime then
				timer.Remove(timerID)
				return
			end
			
			-- Znajdź graczy w zasięgu
			for _, ply in pairs(player.GetAll()) do
				if IsValid(ply) and ply:Alive() and ply:GTeam() != TEAM_SCP and ply:GTeam() != TEAM_SPEC then
					local dist = ply:GetPos():Distance(gasPos)
					if dist <= self.GasRadius then
						-- Zadaj obrażenia
						local dmg = DamageInfo()
						dmg:SetDamage(5)
						dmg:SetAttacker(self.Owner)
						dmg:SetInflictor(self)
						dmg:SetDamageType(DMG_POISON)
						ply:TakeDamageInfo(dmg)
						
						-- Spowolnij gracza
						if not ply.GasSlowed then
							ply.GasSlowed = true
							ply.OriginalSpeed = ply:GetRunSpeed()
							ply:SetRunSpeed(ply.OriginalSpeed * 0.5)
							ply:SetWalkSpeed(ply:GetWalkSpeed() * 0.5)
							
							-- Przywróć prędkość po wyjściu z gazu
							timer.Create("GasRestore_" .. ply:SteamID(), 2, 1, function()
								if IsValid(ply) then
									ply:SetRunSpeed(ply.OriginalSpeed or 240)
									ply:SetWalkSpeed((ply.OriginalSpeed or 240) * 0.5)
									ply.GasSlowed = false
								end
							end)
						else
							-- Odśwież timer
							timer.Adjust("GasRestore_" .. ply:SteamID(), 2)
						end
					end
				end
			end
		end)
		
		-- Wyślij update cooldownu
		self:UpdateGas()
	end
end

-- R - Zmiana trybu zombie
function SWEP:Reload()
	if not IsFirstTimePredicted() then return end
	if self.NextModeSwitch > CurTime() then return end
	
	self.NextModeSwitch = CurTime() + 0.5
	
	if SERVER then
		-- Przełącz na następny typ
		self.CurrentZombieType = self.CurrentZombieType + 1
		if self.CurrentZombieType > #self.ZombieTypes then
			self.CurrentZombieType = 1
		end
		
		-- Dźwięk przełączenia - wyłączony
		-- self.Owner:EmitSound("buttons/button14.wav", 65, 100)
		
		-- Wyślij update do klienta
		net.Start("SCP049_UpdateZombieType")
			net.WriteEntity(self)
			net.WriteUInt(self.CurrentZombieType, 8)
		net.Send(self.Owner)
	end
end

-- Server: Aktualizacje
if SERVER then
	function SWEP:UpdateGas()
		net.Start("SCP049_UpdateGas")
			net.WriteEntity(self)
			net.WriteFloat(self.NextGas)
		net.Send(self.Owner)
	end
	
	function SWEP:Think()
		-- Czyszczenie nieaktywnych gazów
		for i = #self.ActiveGases, 1, -1 do
			if CurTime() > self.ActiveGases[i].endtime then
				table.remove(self.ActiveGases, i)
			end
		end
	end
end

-- Client: Odbieranie aktualizacji
if CLIENT then
	net.Receive("SCP049_UpdateZombieType", function()
		local wep = net.ReadEntity()
		local zombieType = net.ReadUInt(8)
		
		if IsValid(wep) then
			wep.CurrentZombieType = zombieType
		end
	end)
	
	net.Receive("SCP049_UpdateGas", function()
		local wep = net.ReadEntity()
		local nextGas = net.ReadFloat()
		
		if IsValid(wep) then
			wep.NextGas = nextGas
		end
	end)
	
	net.Receive("SCP049_CreateGas", function()
		local wep = net.ReadEntity()
		local pos = net.ReadVector()
		local duration = net.ReadFloat()
		
		-- Stwórz globalny efekt gazu widoczny dla wszystkich
		local gas = {
			pos = pos,
			endtime = CurTime() + duration,
			emitter = ParticleEmitter(pos),
			radius = 300 -- Promień gazu
		}
		
		-- Dodaj do globalnej tablicy gazów
		SCP049_ActiveGases = SCP049_ActiveGases or {}
		table.insert(SCP049_ActiveGases, gas)
	end)
	
	-- Hook do rysowania gazu dla wszystkich graczy
	hook.Add("PostDrawTranslucentRenderables", "SCP049_DrawGas", function()
		if not SCP049_ActiveGases then return end
		
		-- Rysuj wszystkie aktywne gazy
		for i = #SCP049_ActiveGases, 1, -1 do
			local gas = SCP049_ActiveGases[i]
			
			if CurTime() > gas.endtime then
				if gas.emitter then
					gas.emitter:Finish()
				end
				table.remove(SCP049_ActiveGases, i)
			else
				-- Rysuj cząsteczki gazu
				if gas.emitter then
					local particle = gas.emitter:Add("particle/smokesprites_0001", gas.pos + Vector(math.random(-gas.radius, gas.radius), math.random(-gas.radius, gas.radius), math.random(0, 50)))
					if particle then
						particle:SetVelocity(Vector(math.random(-20, 20), math.random(-20, 20), math.random(10, 30)))
						particle:SetDieTime(3)
						particle:SetStartAlpha(100)
						particle:SetEndAlpha(0)
						particle:SetStartSize(50)
						particle:SetEndSize(100)
						particle:SetRoll(math.random(0, 360))
						particle:SetRollDelta(math.random(-0.5, 0.5))
						particle:SetColor(100, 200, 100)
						particle:SetAirResistance(50)
						particle:SetGravity(Vector(0, 0, -20))
					end
				end
			end
		end
	end)
end

-- HUD
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
	
	-- Tło HUD (tak jak w SCP-023)
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
	local titleW, titleH = surface.GetTextSize("SCP-049")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-049")
	
	-- Pobierz typ zombie dla późniejszego użycia
	local zombieType = self.ZombieTypes[self.CurrentZombieType]
	
	-- Cooldowny (wszystkie w jednej linii: LMB, R, RMB)
	local cooldownY = hudY + 60
	local barWidth = 120
	local barHeight = 8
	local totalWidth = barWidth * 3 + 60 -- 3 paski + odstępy
	local startX = centerX - totalWidth / 2
	
	-- LMB (Infect) Cooldown - pierwszy
	local lmbBarX = startX
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(lmbBarX, cooldownY - 15)
	surface.DrawText("LMB - Infect")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
	
	local attackCooldown = 0
	if self.NextAttackW and self.NextAttackW > CurTime() then
		attackCooldown = self.NextAttackW - CurTime()
	end
	
	if attackCooldown > 0 then
		local progress = 1 - (attackCooldown / self.AttackDelay)
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
	
	-- R (Mode) - środkowy
	local modeBarX = startX + barWidth + 30
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(modeBarX, cooldownY - 15)
	surface.DrawText("R - Mode")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(modeBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(modeBarX, cooldownY, barWidth, barHeight)
	
	-- Mode zawsze gotowy
	surface.SetDrawColor(zombieType.color.r, zombieType.color.g, zombieType.color.b, 255)
	surface.DrawRect(modeBarX, cooldownY, barWidth, barHeight)
	
	surface.SetFont("DermaDefault")
	surface.SetTextColor(255, 255, 255, 255)
	surface.SetTextPos(modeBarX, cooldownY + 10)
	surface.DrawText("SWITCH")
	
	-- RMB (Gas) Cooldown - trzeci
	local gasBarX = startX + (barWidth + 30) * 2
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(gasBarX, cooldownY - 15)
	surface.DrawText("RMB - Gas")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(gasBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(gasBarX, cooldownY, barWidth, barHeight)
	
	local gasCooldown = 0
	if self.NextGas and self.NextGas > CurTime() then
		gasCooldown = self.NextGas - CurTime()
	end
	
	if gasCooldown > 0 then
		local progress = 1 - (gasCooldown / self.GasCooldown)
		surface.SetDrawColor(255, 255, 0, 255) -- Żółty kolor podczas cooldownu
		surface.DrawRect(gasBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 255, 150, 255)
		surface.SetTextPos(gasBarX, cooldownY + 10)
		surface.DrawText(string.format("%.0fs", gasCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(gasBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(gasBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- Celownik
	local x = ScrW() / 2.0
	local y = ScrH() / 2.0
	
	local scale = 0.3
	surface.SetDrawColor(zombieType.color.r, zombieType.color.g, zombieType.color.b, 255)
	
	local gap = 5
	local length = gap + 20 * scale
	surface.DrawLine( x - length, y, x - gap, y )
	surface.DrawLine( x + length, y, x + gap, y )
	surface.DrawLine( x, y - length, x, y - gap )
	surface.DrawLine( x, y + length, x, y + gap )
	
	-- Informacja o aktualnym trybie zombie (na dole HUD-u po środku)
	surface.SetFont("DermaDefault")
	surface.SetTextColor(zombieType.color.r, zombieType.color.g, zombieType.color.b, 255)
	local modeText = "Zombie Mode: " .. zombieType.name
	local tw, th = surface.GetTextSize(modeText)
	surface.SetTextPos(centerX - tw/2, hudY + hudHeight - 20)
	surface.DrawText(modeText)
	
	-- Efekty gazu przeniesione do hooka PostDrawTranslucentRenderables
end