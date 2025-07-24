AddCSLuaFile()

SWEP.Base 					= "weapon_scp_base"
SWEP.PrintName				= "SCP-076-2 Rework"

SWEP.ViewModel				= "models/weapons/scp076/v_katana.mdl"
SWEP.WorldModel				= "models/weapons/scp076/w_katana.mdl"

SWEP.HoldType 				= "melee"

SWEP.NextPrimary = 0
SWEP.NextIdle = 0

-- Berserk parametry
SWEP.BerserkChargeTime = 5 -- Czas ładowania berserka
SWEP.BerserkDuration = 10 -- Czas trwania berserka
SWEP.ExhaustionDuration = 15 -- Czas zmęczenia po berserku
SWEP.BerserkCooldown = 60 -- Całkowity cooldown berserka

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_076" )

	self:SetHoldType( self.HoldType )

	self.NextIdle = CurTime() + self:SequenceDuration( ACT_VM_DRAW)
	self:SendWeaponAnim( ACT_VM_DRAW )
	self.NextPrimary = CurTime() + 1
	self:EmitSound( "weapons/knife/knife_deploy1.wav" )
	
	-- Inicjalizacja zmiennych berserka
	self.IsBerserk = false
	self.IsCharging = false
	self.IsExhausted = false
	self.BerserkEnd = 0
	self.ChargeEnd = 0
	self.ExhaustEnd = 0
	self.NextBerserk = 0
	self.OriginalSpeed = 0
	self.OriginalWalkSpeed = 0
	
	-- Networking
	if SERVER then
		util.AddNetworkString("SCP076_BerserkUpdate")
	end
	
	if CLIENT then
		self.WepSelectIcon = surface.GetTextureID("breach/wep_076")
	end
end

-- Synchronizacja stanów przy spawnie broni
function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "BerserkActive")
	self:NetworkVar("Bool", 1, "ChargingActive")
	self:NetworkVar("Bool", 2, "ExhaustedActive")
end

function SWEP:Deploy()
end

function SWEP:Think()
	self:PlayerFreeze()

	if self.NextIdle > CurTime() then return end
	self.NextIdle = CurTime() + self:SequenceDuration( ACT_VM_IDLE )
	self:SendWeaponAnim( ACT_VM_IDLE )
	
	if SERVER then
		-- Sprawdź ładowanie berserka
		if self.IsCharging and CurTime() >= self.ChargeEnd then
			self:ActivateBerserk()
		end
		
		-- Sprawdź koniec berserka
		if self.IsBerserk and CurTime() >= self.BerserkEnd then
			self:EndBerserk()
		end
		
		-- Sprawdź koniec zmęczenia
		if self.IsExhausted and CurTime() >= self.ExhaustEnd then
			self:EndExhaustion()
		end
	end
end

function SWEP:PrimaryAttack()
	if postround then return end
	if self.NextPrimary > CurTime() then return end
	if self.IsCharging then return end -- Nie można atakować podczas ładowania
	
	self.NextPrimary = CurTime() + 1
	self.NextIdle = CurTime() + self:SequenceDuration( ACT_VM_MISSCENTER )
	self:EmitSound( "Weapon_Knife.Slash" )
	self.Owner:LagCompensation( true )
	
	local pos = self.Owner:GetShootPos()
	local aim = self.Owner:GetAimVector()
	local baseDmg = math.random( 25, 35 )
	
	-- Podwójne obrażenia w trybie berserk
	if self.IsBerserk then
		baseDmg = baseDmg * 2
	end
	
	local dist = 75

	local damage = DamageInfo()
	damage:SetDamage( baseDmg )
	damage:SetDamageType( DMG_SLASH )
	damage:SetAttacker( self.Owner )
	damage:SetInflictor( self )
	damage:SetDamageForce( aim * 300 )

	local tr = util.TraceHull( {
		start = pos,
		endpos = pos + aim * dist,
		filter = self.Owner,
		mask = MASK_SHOT_HULL,
		mins = Vector( -10, -5, -5 ),
		maxs = Vector( 10, 5, 5 )
	} )
	if tr.Hit then
		local ent = tr.Entity
		if ent:IsPlayer() then
			if ent:GTeam() != TEAM_SPEC and (ent:GTeam() != TEAM_SCP or ent:GetNClass() == ROLES.ROLE_SCP035) then
				self:EmitSound( "Weapon_Knife.Hit" )
				if SERVER and ent:GTeam() != TEAM_SCP then
					ent:TakeDamageInfo( damage )
				end
			end
		elseif !self:SCPDamageEvent( ent, self.IsBerserk and 20 or 10 ) then
			local look = self.Owner:GetEyeTrace()
			self:EmitSound( "weapons/rpg/shotdown.wav" )
			util.Decal("ManhackCut", look.HitPos + look.HitNormal, look.HitPos - look.HitNormal )
		end
	end
	
	self.Owner:LagCompensation( false )
	self:SendWeaponAnim( ACT_VM_MISSCENTER )
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
end

-- RMB - Aktywacja trybu Berserk
function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextBerserk > CurTime() then return end
	if self.IsBerserk or self.IsCharging or self.IsExhausted then return end
	
	if SERVER then
		-- Rozpocznij ładowanie
		self.IsCharging = true
		self.ChargeEnd = CurTime() + self.BerserkChargeTime
		
		-- Ustaw networked variable
		self:SetChargingActive(true)
		
		-- Zamroź gracza
		self.Owner:Freeze(true)
		
		-- Dźwięk ładowania
		self.Owner:EmitSound("ambient/energy/weld1.wav", 75, 50)
		
		-- Timer dla efektu ładowania
		timer.Create("SCP076_ChargeEffect_" .. self:EntIndex(), 0.1, 50, function()
			if not IsValid(self) or not IsValid(self.Owner) or not self.IsCharging then
				timer.Remove("SCP076_ChargeEffect_" .. self:EntIndex())
				return
			end
			
			-- Efekt czerwonego dymu zbierającego się
			local effectdata = EffectData()
			effectdata:SetOrigin(self.Owner:GetPos() + Vector(0, 0, 40))
			effectdata:SetScale(2)
			-- Zmieniony efekt zamiast GlassImpact
			util.Effect("BloodImpact", effectdata)
		end)
		
		-- Update klienta
		self:UpdateBerserkState()
	end
end

-- Aktywacja berserka
function SWEP:ActivateBerserk()
	if not SERVER then return end
	
	self.IsCharging = false
	self.IsBerserk = true
	self.BerserkEnd = CurTime() + self.BerserkDuration
	
	-- Ustaw networked variable
	self:SetBerserkActive(true)
	self:SetChargingActive(false)
	
	-- Odmroź gracza
	self.Owner:Freeze(false)
	
	-- Zatrzymaj timer efektu ładowania
	timer.Remove("SCP076_ChargeEffect_" .. self:EntIndex())
	
	-- Zapisz oryginalne prędkości
	self.OriginalSpeed = self.Owner:GetRunSpeed()
	self.OriginalWalkSpeed = self.Owner:GetWalkSpeed()
	
	-- Podwój prędkość
	self.Owner:SetRunSpeed(self.OriginalSpeed * 2)
	self.Owner:SetWalkSpeed(self.OriginalWalkSpeed * 2)
	
	-- Dźwięk aktywacji
	self.Owner:EmitSound("npc/antlion_guard/angry1.wav", 100, 80)
	
	-- Efekt czerwonej aury
	local effectdata = EffectData()
	effectdata:SetOrigin(self.Owner:GetPos())
	effectdata:SetEntity(self.Owner)
	util.Effect("BloodImpact", effectdata)
	
	-- Update klienta
	self:UpdateBerserkState()
end

-- Zakończenie berserka
function SWEP:EndBerserk()
	if not SERVER then return end
	
	self.IsBerserk = false
	self.IsExhausted = true
	self.ExhaustEnd = CurTime() + self.ExhaustionDuration
	self.NextBerserk = CurTime() + self.BerserkCooldown
	
	-- Ustaw networked variables
	self:SetBerserkActive(false)
	self:SetExhaustedActive(true)
	
	-- Ustaw spowolnienie (50% normalnej prędkości)
	self.Owner:SetRunSpeed(self.OriginalSpeed * 0.5)
	self.Owner:SetWalkSpeed(self.OriginalWalkSpeed * 0.5)
	
	-- Dźwięk zmęczenia
	self.Owner:EmitSound("player/pl_drown1.wav", 75, 100)
	
	-- Update klienta
	self:UpdateBerserkState()
end

-- Zakończenie zmęczenia
function SWEP:EndExhaustion()
	if not SERVER then return end
	
	self.IsExhausted = false
	
	-- Ustaw networked variable
	self:SetExhaustedActive(false)
	
	-- Przywróć normalną prędkość
	self.Owner:SetRunSpeed(self.OriginalSpeed)
	self.Owner:SetWalkSpeed(self.OriginalWalkSpeed)
	
	-- Update klienta
	self:UpdateBerserkState()
end

-- Aktualizacja stanu dla klienta
function SWEP:UpdateBerserkState()
	if not SERVER then return end
	
	net.Start("SCP076_BerserkUpdate")
		net.WriteEntity(self)
		net.WriteBool(self.IsBerserk)
		net.WriteBool(self.IsCharging)
		net.WriteBool(self.IsExhausted)
		net.WriteFloat(self.BerserkEnd)
		net.WriteFloat(self.ChargeEnd)
		net.WriteFloat(self.ExhaustEnd)
		net.WriteFloat(self.NextBerserk)
	net.Broadcast() -- Zmienione z net.Send(self.Owner) na net.Broadcast()
end

-- Odbieranie aktualizacji po stronie klienta
if CLIENT then
	net.Receive("SCP076_BerserkUpdate", function()
		local wep = net.ReadEntity()
		if IsValid(wep) and wep:GetClass() == "weapon_scp_076" then
			wep.IsBerserk = net.ReadBool()
			wep.IsCharging = net.ReadBool()
			wep.IsExhausted = net.ReadBool()
			wep.BerserkEnd = net.ReadFloat()
			wep.ChargeEnd = net.ReadFloat()
			wep.ExhaustEnd = net.ReadFloat()
			wep.NextBerserk = net.ReadFloat()
		end
	end)
	
	-- Hook do rysowania aury berserka na modelu
	hook.Add("PostDrawTranslucentRenderables", "SCP076_BerserkAura", function()
		-- Sprawdź wszystkich graczy
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply:Alive() then
				local wep = ply:GetActiveWeapon()
				-- Używaj networked variable zamiast lokalnej zmiennej
				if IsValid(wep) and wep:GetClass() == "weapon_scp_076" then
					-- Efekt ładowania
					if wep:GetChargingActive() or wep.IsCharging then
						local pos = ply:GetPos()
						local time = CurTime()
						local progress = 0
						if wep.ChargeEnd then
							progress = 1 - ((wep.ChargeEnd - time) / wep.BerserkChargeTime)
						end
						
						-- Czerwony okrąg zbierający się do środka
						render.SetColorMaterial()
						render.StartBeam(32)
						for i = 0, 31 do
							local angle = (i / 31) * math.pi * 2
							local radius = 100 * (1 - progress) + 20
							local x = pos.x + math.cos(angle) * radius
							local y = pos.y + math.sin(angle) * radius
							local z = pos.z + 40 + math.sin(time * 10 + i) * 5
							
							render.AddBeam(Vector(x, y, z), 10, i / 31, Color(255, 0, 0, 150 * progress))
						end
						render.EndBeam()
						
						-- Cząsteczki zbiegające się do gracza
						if math.random() > 0.5 then
							local emitter = ParticleEmitter(pos)
							if emitter then
								for p = 1, 2 do
									local angle = math.random() * math.pi * 2
									local dist = 80 + math.random() * 40
									local startPos = pos + Vector(math.cos(angle) * dist, math.sin(angle) * dist, math.random(20, 80))
									
									local part = emitter:Add("sprites/light_glow02_add", startPos)
									if part then
										part:SetDieTime(0.5)
										part:SetStartAlpha(100)
										part:SetEndAlpha(0)
										part:SetStartSize(8)
										part:SetEndSize(2)
										part:SetGravity(Vector(0, 0, 0))
										local vel = (pos + Vector(0, 0, 40) - startPos):GetNormalized() * 200
										part:SetVelocity(vel)
										part:SetColor(255, 0, 0)
										part:SetRoll(math.random(0, 360))
									end
								end
								emitter:Finish()
							end
						end
						
						-- Czerwona poświata podczas ładowania
						local pulse = math.sin(time * 8) * 0.3 + 0.7
						cam.Start3D()
						render.SetMaterial(Material("sprites/light_glow02_add"))
						render.DrawSprite(pos + Vector(0, 0, 40), 150 * progress * pulse, 150 * progress * pulse, Color(255, 0, 0, 100))
						cam.End3D()
					
					-- Efekt berserka
					elseif wep:GetBerserkActive() or wep.IsBerserk then
					-- Rysuj aurę na modelu gracza
					local pos = ply:GetPos()
					local time = CurTime()
					
					-- Czerwona poświata wokół modelu
					local mins, maxs = ply:GetModelBounds()
					local center = ply:GetPos() + Vector(0, 0, (maxs.z - mins.z) / 2)
					local pulse = math.sin(time * 4) * 0.2 + 0.8
					
					cam.Start3D()
					render.SetMaterial(Material("sprites/light_glow02_add"))
					render.DrawSprite(center, 120 * pulse, 120 * pulse, Color(255, 0, 0, 60))
					cam.End3D()
					
					-- Efekt czerwonych cząsteczek
					if math.random() > 0.7 then
						local emitter = ParticleEmitter(pos)
						if emitter then
							for p = 1, 3 do
								-- Losowa pozycja wokół gracza
								local offset = Vector(math.random(-40, 40), math.random(-40, 40), math.random(0, 70))
								local part = emitter:Add("particles/flamelet" .. math.random(1, 5), pos + offset)
								if part then
									part:SetDieTime(1.5)
									part:SetStartAlpha(200)
									part:SetEndAlpha(0)
									part:SetStartSize(15)
									part:SetEndSize(5)
									part:SetGravity(Vector(0, 0, 80))
									part:SetVelocity(Vector(math.random(-30, 30), math.random(-30, 30), math.random(40, 80)))
									part:SetColor(255, 50, 50)
									part:SetRoll(math.random(0, 360))
									part:SetRollDelta(math.random(-3, 3))
									part:SetAirResistance(50)
								end
							end
							emitter:Finish()
						end
					end
					end
				end
			end
		end
	end)
end

-- HUD w stylu innych SCP
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
	local titleW, titleH = surface.GetTextSize("SCP-076-2")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-076-2")
	
	-- Cooldowny (LMB i RMB)
	local cooldownY = hudY + 60
	local barWidth = 180
	local barHeight = 8
	local spacing = 60
	local totalWidth = barWidth * 2 + spacing
	local startX = centerX - totalWidth / 2
	
	-- LMB Cooldown (Atak)
	local lmbBarX = startX
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(lmbBarX, cooldownY - 15)
	surface.DrawText("LMB - Sword Attack")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
	
	local attackCooldown = 0
	if self.NextPrimary and self.NextPrimary > CurTime() then
		attackCooldown = self.NextPrimary - CurTime()
	end
	
	if attackCooldown > 0 then
		local progress = 1 - attackCooldown
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
	
	-- RMB Status (Berserk)
	local rmbBarX = startX + barWidth + spacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rmbBarX, cooldownY - 15)
	surface.DrawText("RMB - Berserk Mode")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
	
	-- Różne stany berserka
	if self.IsCharging then
		-- Ładowanie
		local progress = 0
		if self.ChargeEnd then
			progress = 1 - ((self.ChargeEnd - CurTime()) / self.BerserkChargeTime)
		end
		surface.SetDrawColor(255, 255, 0, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 255, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText("CHARGING...")
	elseif self.IsBerserk then
		-- Aktywny berserk
		local progress = 0
		if self.BerserkEnd then
			progress = (self.BerserkEnd - CurTime()) / self.BerserkDuration
		end
		surface.SetDrawColor(255, 0, 0, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 150, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText(string.format("BERSERK %.1fs", self.BerserkEnd - CurTime()))
	elseif self.IsExhausted then
		-- Zmęczenie
		local progress = 0
		if self.ExhaustEnd then
			progress = (self.ExhaustEnd - CurTime()) / self.ExhaustionDuration
		end
		surface.SetDrawColor(100, 100, 100, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 150, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText(string.format("EXHAUSTED %.1fs", self.ExhaustEnd - CurTime()))
	elseif self.NextBerserk and self.NextBerserk > CurTime() then
		-- Cooldown
		local cooldown = self.NextBerserk - CurTime()
		local progress = 1 - (cooldown / self.BerserkCooldown)
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText(string.format("%.0fs", cooldown))
	else
		-- Gotowy
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- Status na dole
	local statusText = ""
	local statusColor = Color(200, 200, 200)
	
	if self.IsBerserk then
		statusText = "BERSERK MODE ACTIVE - 2x Damage & Speed"
		statusColor = Color(255, 100, 100)
	elseif self.IsExhausted then
		statusText = "EXHAUSTED - Movement Slowed"
		statusColor = Color(150, 150, 150)
	elseif self.IsCharging then
		statusText = "CHARGING BERSERK MODE..."
		statusColor = Color(255, 255, 100)
	else
		statusText = ""
		statusColor = Color(100, 255, 100)
	end
	
	surface.SetFont("DermaDefault")
	surface.SetTextColor(statusColor.r, statusColor.g, statusColor.b, 255)
	local tw, th = surface.GetTextSize(statusText)
	surface.SetTextPos(centerX - tw/2, hudY + hudHeight - 20)
	surface.DrawText(statusText)
	
	-- Celownik
	local x = ScrW() / 2.0
	local y = ScrH() / 2.0
	
	local scale = 0.3
	local color = self.IsBerserk and Color(255, 0, 0) or Color(200, 200, 200)
	surface.SetDrawColor(color.r, color.g, color.b, 255)
	
	local gap = 5
	local length = gap + 20 * scale
	surface.DrawLine( x - length, y, x - gap, y )
	surface.DrawLine( x + length, y, x + gap, y )
	surface.DrawLine( x, y - length, x, y - gap )
	surface.DrawLine( x, y + length, x, y + gap )
end

-- Czyszczenie przy usunięciu broni
function SWEP:OnRemove()
	if SERVER and IsValid(self.Owner) then
		-- Przywróć normalne prędkości jeśli broń jest usuwana
		if self.OriginalSpeed and self.OriginalSpeed > 0 then
			self.Owner:SetRunSpeed(self.OriginalSpeed)
			self.Owner:SetWalkSpeed(self.OriginalWalkSpeed)
		end
		
		-- Odmroź gracza jeśli był zamrożony
		if self.IsCharging then
			self.Owner:Freeze(false)
		end
		
		-- Usuń timer efektu ładowania
		timer.Remove("SCP076_ChargeEffect_" .. self:EntIndex())
	end
end