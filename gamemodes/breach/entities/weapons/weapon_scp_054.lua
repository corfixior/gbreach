AddCSLuaFile()

SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-054"

SWEP.HoldType = "none"
SWEP.DrawCrosshair = true

-- Cooldowns
SWEP.Primary.Delay = 5 -- Water laser cooldown
SWEP.Secondary.Delay = 80 -- Steam explosion cooldown

-- Timers
SWEP.NextPrimary = 0
SWEP.NextSecondary = 0

function SWEP:OnRemove()
	if IsValid(self.Owner) then
		self.Owner:SetCustomCollisionCheck(false)
	end
end

function SWEP:Deploy()
	if IsValid(self.Owner) then
		self.Owner:SetCustomCollisionCheck(true)
	end
	self:HideModels()
end

function SWEP:Initialize()
	self:InitializeLanguage("SCP_054")
	self:SetHoldType("none")
	
	self.NextPrimary = 0
	self.NextSecondary = 0

	if SERVER then
			util.AddNetworkString("SCP054_CreateSteam")
			util.AddNetworkString("SCP054_PuddleState")
		end

	if CLIENT then
		net.Receive("SCP054_CreateSteam", function()
			local pos = net.ReadVector()
			local emitter = ParticleEmitter(pos)
			for i = 1, 50 do
				local particle = emitter:Add("particle/smokesprites_0001", pos + Vector(math.random(-50, 50), math.random(-50, 50), math.random(0, 80)))
				if particle then
					particle:SetVelocity(Vector(math.random(-30, 30), math.random(-30, 30), math.random(20, 40)))
					particle:SetDieTime(2)
					particle:SetStartAlpha(150)
					particle:SetEndAlpha(0)
					particle:SetStartSize(30)
					particle:SetEndSize(60)
					particle:SetRoll(math.random(0, 360))
					particle:SetRollDelta(math.random(-0.5, 0.5))
					particle:SetColor(255, 255, 255)
					particle:SetAirResistance(100)
					particle:SetGravity(Vector(0, 0, -10))
				end
			end
			emitter:Finish()
		end)
	end
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

SWEP.ShowViewModel = false
SWEP.ShowWorldModel = false

-- LMB - Water Laser
function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if self.NextPrimary > CurTime() then return end
	self.NextPrimary = CurTime() + self.Primary.Delay
	
	local owner = self.Owner
	local tr = util.TraceLine({
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos() + owner:GetAimVector() * 1200,
		filter = owner,
		mask = MASK_SHOT
	})
	
	-- Tworzenie efektów wizualnych (działa po stronie klienta i serwera)
	-- Water laser beam effect - widoczny niebieski promień
	-- Główny efekt promienia (standardowy efekt GMod)
	local tracerEffect = EffectData()
	tracerEffect:SetStart(owner:GetShootPos())
	tracerEffect:SetOrigin(tr.HitPos)
	tracerEffect:SetEntity(owner)
	util.Effect("ToolTracer", tracerEffect)
	
	-- Dodatkowe efekty wodne wzdłuż promienia
	local distance = owner:GetShootPos():Distance(tr.HitPos)
	local direction = (tr.HitPos - owner:GetShootPos()):GetNormalized()
	
	-- Dodaj kilka małych efektów wody wzdłuż promienia
	for i = 1, 5 do
		local pos = owner:GetShootPos() + direction * (distance * (i / 6))
		local waterEffect = EffectData()
		waterEffect:SetOrigin(pos)
		waterEffect:SetScale(0.5)
		util.Effect("watersplash", waterEffect)
	end
	
	-- Dodatkowy efekt świecenia
	local gloweffect = EffectData()
	gloweffect:SetOrigin(tr.HitPos)
	gloweffect:SetScale(2)
	gloweffect:SetRadius(2)
	gloweffect:SetMagnitude(2)
	util.Effect("WaterSplash", gloweffect)
	
	-- Dodatkowy efekt na końcu promienia
	local effectdata = EffectData()
	effectdata:SetStart(owner:GetShootPos())
	effectdata:SetOrigin(tr.HitPos)
	effectdata:SetEntity(owner)
	effectdata:SetScale(2)
	util.Effect("watersplash", effectdata)
	
	-- Kontynuuj tylko po stronie serwera dla logiki obrażeń
	if !SERVER then return end
	
	-- Laser sound effect - krótki dźwięk zamiast zapętlonego
	owner:EmitSound("ambient/water/water_splash2.wav", 80, 120)
	
	local ent = tr.Entity
	if IsValid(ent) and ent:IsPlayer() then
		if ent:GTeam() == TEAM_SPEC or (ent:GTeam() == TEAM_SCP and ent:GetNClass() != ROLES.ROLE_SCP035) then return end
		
		-- Damage
		ent:TakeDamage(35, owner, self)
		
		-- Strong knockback
		local knockback = owner:GetAimVector() * 900
		knockback.z = knockback.z + 100 -- Add upward force
		ent:SetVelocity(knockback)
		
		-- Apply water effects (blur + slow)
		self:ApplyWaterEffects(ent)
		
		self:SCPDamageEvent(ent, 35)
	end
end

-- RMB - Steam Explosion
function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if self.NextSecondary > CurTime() then return end
	self.NextSecondary = CurTime() + self.Secondary.Delay
	
	local owner = self.Owner
	
	-- Początkowy dźwięk pary
	owner:EmitSound("ambient/gas/steam2.wav", 100, 100)
	
	-- Zatrzymaj dźwięk po 2 sekundach
	timer.Simple(2, function()
		if IsValid(owner) then
			owner:StopSound("ambient/gas/steam2.wav")
		end
	end)
	
	-- Zatrzymaj poprzedni timer jeśli istnieje
	timer.Remove("SCP054_SteamEffect_" .. self:EntIndex())
	
	-- Utwórz timer dla efektu pary (podobny do berserka SCP-076, ale w białym)
	timer.Create("SCP054_SteamEffect_" .. self:EntIndex(), 0.1, 20, function()
		if not IsValid(self) or not IsValid(owner) then
			timer.Remove("SCP054_SteamEffect_" .. self:EntIndex())
			return
		end
		
		local currentPos = owner:GetPos()
		
		-- Efekty pary widoczne dla wszystkich graczy (używamy util.Effect)
		local headPos = currentPos + Vector(0, 0, 70)
		
		-- Wyślij efekt do wszystkich klientów
		if SERVER then
			net.Start("SCP054_CreateSteam")
				net.WriteVector(owner:GetPos())
			net.Broadcast()
		end
	end)
	
	-- Po 2 sekundach następuje wybuch
	timer.Simple(2, function()
		if !IsValid(owner) then return end
		
		local currentPos = owner:GetPos() -- Aktualna pozycja gracza
		
		if SERVER then
			-- Dźwięk eksplozji
			owner:EmitSound("ambient/explosions/explode_4.wav", 90, 120)
			
			-- Find all players in explosion radius
			for _, ent in pairs(ents.FindInSphere(currentPos, 350)) do
				if IsValid(ent) and ent:IsPlayer() and ent != owner then
					-- Only damage non-SCP players (except SCP-035 can be damaged)
					if not (ent:GTeam() == TEAM_SPEC or (ent:GTeam() == TEAM_SCP and ent:GetNClass() != ROLES.ROLE_SCP035)) then
						-- Check line of sight (prevent damage through walls)
						local trace = util.TraceLine({
							start = currentPos + Vector(0, 0, 36),
							endpos = ent:GetPos() + Vector(0, 0, 36),
							filter = {owner, ent}
						})
						
						-- Only damage if no wall blocking
						if not trace.Hit then
							-- Calculate damage based on distance
							local distance = currentPos:Distance(ent:GetPos())
							local damage = math.max(30, 120 - (distance / 2.5))
							
							-- Damage
							ent:TakeDamage(damage, owner, self)
							
							-- Strong knockback
							local dir = (ent:GetPos() - currentPos):GetNormalized()
							dir.z = 0.6
							ent:SetVelocity(dir * 500)
							
							self:SCPDamageEvent(ent, damage)
						end
					end
				end
			end
		end
		
		-- Steam explosion effect (widoczny dla wszystkich)
		local effectdata = EffectData()
		effectdata:SetOrigin(currentPos)
		effectdata:SetMagnitude(350)
		effectdata:SetScale(3)
		util.Effect("Explosion", effectdata)
		
		-- Additional steam effects
		for i = 1, 8 do
			timer.Simple(i * 0.1, function()
				if IsValid(owner) then
					local currentEffectPos = owner:GetPos() -- Aktualna pozycja dla efektów
					local steamEffect = EffectData()
					steamEffect:SetOrigin(currentEffectPos + Vector(math.random(-50, 50), math.random(-50, 50), math.random(0, 100)))
					steamEffect:SetScale(1.5)
					util.Effect("watersplash", steamEffect)
				end
			end)
		end
	end)
end

-- Apply water effects to target
function SWEP:ApplyWaterEffects(target)
	if !SERVER then return end
	if !IsValid(target) then return end
	
	-- Apply 50% slow effect for 2 seconds
	local oldWalkSpeed = target:GetWalkSpeed()
	local oldRunSpeed = target:GetRunSpeed()
	
	target:SetWalkSpeed(oldWalkSpeed * 0.5)
	target:SetRunSpeed(oldRunSpeed * 0.5)
	
	-- Send water screen effect to client (blur + water overlay)
	net.Start("SCP054_WaterEffect")
	net.Send(target)
	
	-- Remove slow effect after 2 seconds
	timer.Simple(2, function()
		if IsValid(target) then
			target:SetWalkSpeed(oldWalkSpeed)
			target:SetRunSpeed(oldRunSpeed)
		end
	end)
end

-- Passive: 50% damage reduction from CW2 weapons
function SWEP:Think()
	self:PlayerFreeze()
	
	if SERVER then
		local owner = self.Owner
		if IsValid(owner) and !owner.SCP054_PassiveApplied then
			owner.SCP054_PassiveApplied = true
			
			-- Hook for damage reduction
			hook.Add("EntityTakeDamage", "SCP054_DamageReduction_" .. owner:SteamID64(), function(target, dmginfo)
				if target == owner then
					local attacker = dmginfo:GetAttacker()
					local weapon = nil
					
					if IsValid(attacker) and attacker:IsPlayer() then
						weapon = attacker:GetActiveWeapon()
					end
					
					-- Check if damage is from CW2 weapon
					if IsValid(weapon) and weapon.CW20_Weapon then
						dmginfo:ScaleDamage(0.5) -- 50% damage reduction
					end
				end
			end)
		end
	end
end

-- Network string for water effect
if SERVER then
	util.AddNetworkString("SCP054_WaterEffect")
end

-- Client-side water screen effect
if CLIENT then
	local waterEffectEnd = 0
	
	net.Receive("SCP054_WaterEffect", function()
		waterEffectEnd = CurTime() + 2 -- 2 seconds of water effect
	end)
	
	hook.Add("RenderScreenspaceEffects", "SCP054_WaterScreen", function()
		if waterEffectEnd > CurTime() then
			local timeLeft = waterEffectEnd - CurTime()
			local intensity = timeLeft / 2 -- Fade out over time
			
			-- Strong water overlay effect
			local tab = {
				["$pp_colour_addr"] = 0,
				["$pp_colour_addg"] = 0.15 * intensity,
				["$pp_colour_addb"] = 0.4 * intensity,
				["$pp_colour_brightness"] = -0.2 * intensity,
				["$pp_colour_contrast"] = 1 + (0.3 * intensity),
				["$pp_colour_colour"] = 1 - (0.3 * intensity),
				["$pp_colour_mulr"] = 1 - (0.4 * intensity),
				["$pp_colour_mulg"] = 1 - (0.2 * intensity),
				["$pp_colour_mulb"] = 1 + (0.3 * intensity)
			}
			
			DrawColorModify(tab)
			
			-- Strong blur effect
			DrawMotionBlur(0.6 * intensity, 1.0 * intensity, 0.02)
		end
	end)
end

-- Clear water effects on player death
if CLIENT then
	hook.Add("PlayerDeath", "SCP054_ClearWaterEffects", function(victim, inflictor, attacker)
		local ply = LocalPlayer()
		if victim == ply then
			-- Clear water effect
			waterEffectEnd = 0
		end
	end)
end

-- HUD Display (dokładnie jak SCP-069)
if CLIENT then
	function SWEP:DrawHUD()
		if disablehud == true then return end
		
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		
		local scrW, scrH = ScrW(), ScrH()
		local centerX = scrW / 2
		local hudY = scrH - 150
		
		-- HUD Background (identyczny jak SCP-069)
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
		local titleW, titleH = surface.GetTextSize("SCP-054")
		surface.SetTextPos(centerX - titleW / 2, hudY + 10)
		surface.DrawText("SCP-054")
		
		-- Cooldowny
		local lmbCooldown = 0
		local rmbCooldown = 0
		
		if self.NextPrimary and self.NextPrimary > CurTime() then
			lmbCooldown = self.NextPrimary - CurTime()
		end
		
		if self.NextSecondary and self.NextSecondary > CurTime() then
			rmbCooldown = self.NextSecondary - CurTime()
		end
		
		local cooldownY = hudY + 60
		local barWidth = 120
		local barHeight = 8
		local barSpacing = 20
		
		-- LMB (Water Laser) Cooldown
		local lmbBarX = centerX - barWidth - barSpacing
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		surface.SetTextPos(lmbBarX, cooldownY - 15)
		surface.DrawText("LMB - Water Laser")
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
		
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
		
		if lmbCooldown > 0 then
			local progress = 1 - (lmbCooldown / self.Primary.Delay)
			surface.SetDrawColor(255, 100, 100, 255)
			surface.DrawRect(lmbBarX, cooldownY, barWidth * progress, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(255, 150, 150, 255)
			surface.SetTextPos(lmbBarX, cooldownY + 10)
			surface.DrawText(string.format("%.1fs", lmbCooldown))
		else
			surface.SetDrawColor(100, 255, 100, 255)
			surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(150, 255, 150, 255)
			surface.SetTextPos(lmbBarX, cooldownY + 10)
			surface.DrawText("READY")
		end
		
		-- RMB (Steam Explosion) Cooldown
		local rmbBarX = centerX + barSpacing
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		surface.SetTextPos(rmbBarX, cooldownY - 15)
		surface.DrawText("RMB - Steam Explosion")
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
		
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
		
		if rmbCooldown > 0 then
			local progress = 1 - (rmbCooldown / self.Secondary.Delay)
			surface.SetDrawColor(255, 100, 100, 255)
			surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(255, 150, 150, 255)
			surface.SetTextPos(rmbBarX, cooldownY + 10)
			surface.DrawText(string.format("%.1fs", rmbCooldown))
		else
			surface.SetDrawColor(100, 255, 100, 255)
			surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(150, 255, 150, 255)
			surface.SetTextPos(rmbBarX, cooldownY + 10)
			surface.DrawText("READY")
		end
		

	end
end

function SWEP:Holster()
	if SERVER then
		local owner = self.Owner
		if IsValid(owner) and owner.SCP054_PassiveApplied then
			hook.Remove("EntityTakeDamage", "SCP054_DamageReduction_" .. owner:SteamID64())
			owner.SCP054_PassiveApplied = nil
		end
	end
	return true
end

function SWEP:OnRemove()
	if SERVER then
		local owner = self.Owner
		if IsValid(owner) and owner.SCP054_PassiveApplied then
			hook.Remove("EntityTakeDamage", "SCP054_DamageReduction_" .. owner:SteamID64())
			owner.SCP054_PassiveApplied = nil
		end
	end
end