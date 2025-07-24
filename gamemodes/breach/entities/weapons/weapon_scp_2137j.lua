AddCSLuaFile()

SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-2137-J"

SWEP.HoldType = "normal"

-- SCP-2137-J Configuration
SWEP.AttackDelay = 2.0
SWEP.SecondaryDelay = 60.0 -- RMB cooldown (longer for big kremowka)
SWEP.HitDistance = 500
SWEP.ThrowForce = 800

-- No viewmodel needed for Papaj

if SERVER then
	util.AddNetworkString("scp2137j_throw_kremowka")
	util.AddNetworkString("scp2137j_throw_big_kremowka")
	util.AddNetworkString("scp2137j_resurrection")
	
	-- Hook to prevent kremowka from dealing collision damage
	hook.Add("EntityTakeDamage", "SCP2137J_PreventKremowkaDamage", function(target, dmginfo)
		local inflictor = dmginfo:GetInflictor()
		if IsValid(inflictor) and inflictor.IsSCP2137JKremowka then
			-- Only allow explosion damage, block physics damage
			if dmginfo:GetDamageType() != DMG_BLAST then
				return true -- Block the damage
			end
		end
	end)
	
	-- Resurrection system for SCP-2137-J
	hook.Add("EntityTakeDamage", "SCP2137J_Resurrection", function(target, dmginfo)
		if not IsValid(target) then return end
		if not target:IsPlayer() then return end
		if target:GTeam() != TEAM_SCP then return end
		
		local weapon = target:GetActiveWeapon()
		if not IsValid(weapon) then return end
		if weapon:GetClass() != "weapon_scp_2137j" then return end
		
		-- Check if already resurrected
		if target:GetNWBool("SCP2137J_HasResurrected", false) then return end
		
		-- Check if damage would bring HP below 1
		local newHP = target:Health() - dmginfo:GetDamage()
		if newHP >= 1 then return end
		
		-- Block the damage
		dmginfo:SetDamage(0)
		
		-- Mark as resurrected (one time only)
		target:SetNWBool("SCP2137J_HasResurrected", true)
		
		-- Get spawn position
		local spawnPos = nil
		if game.GetMap() == "gm_site19" then
			spawnPos = Vector(4902.546875, -194.649277, 25.906204)
		elseif game.GetMap() == "br_site15" then
			spawnPos = Vector(1400.00, 2000.00, -7157.00)
		else
			-- Fallback to current position if unknown map
			spawnPos = target:GetPos()
		end
		
		-- Instant teleport and heal
		target:SetPos(spawnPos)
		target:SetHealth(1200) -- Full HP
	end)
end

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID("breach/wep_2137j")
end

function SWEP:Initialize()
	self:InitializeLanguage("SCP_2137J")
	self:SetHoldType(self.HoldType)
	
	self.NextAttack = 0
	self.NextSecondaryAttack = 0
end

function SWEP:PrimaryAttack()
	if not IsFirstTimePredicted() then return end
	if CurTime() < self.NextAttack then return end
	
	self:ThrowKremowka()
	self.NextAttack = CurTime() + self.AttackDelay
end

function SWEP:ThrowKremowka()
	if not SERVER then return end
	if not IsValid(self.Owner) then return end
	
	local ply = self.Owner
	local eyePos = ply:EyePos()
	local eyeAng = ply:EyeAngles()
	local forward = eyeAng:Forward()
	
	-- Create kremowka entity
	local kremowka = ents.Create("prop_physics")
	if not IsValid(kremowka) then return end
	
	kremowka:SetModel("models/kremowka/kremowka.mdl")
	kremowka:SetPos(eyePos + forward * 50)
	kremowka:SetAngles(eyeAng)
	kremowka:Spawn()
	kremowka:Activate()
	
	-- Disable collision damage (kremowka shouldn't hurt on impact, only on explosion)
	kremowka:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	
	-- Set physics properties
	local phys = kremowka:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetVelocity(forward * self.ThrowForce + Vector(0, 0, 100))
		phys:AddAngleVelocity(VectorRand() * 10)
		-- Make kremowka lighter so it doesn't deal physics damage
		phys:SetMass(1)
	end
	
	-- Mark as SCP-2137-J kremowka
	kremowka.IsSCP2137JKremowka = true
	kremowka.SCP2137JOwner = ply
	
	-- Set explosion timer (3 seconds)
	timer.Simple(3, function()
		if IsValid(kremowka) then
			self:ExplodeKremowka(kremowka)
		end
	end)
	
	-- Network to client for effects
	net.Start("scp2137j_throw_kremowka")
	net.WriteVector(eyePos)
	net.WriteAngle(eyeAng)
	net.Broadcast()
end

function SWEP:ThrowBigKremowka()
	if not SERVER then return end
	if not IsValid(self.Owner) then return end
	
	local ply = self.Owner
	local eyePos = ply:EyePos()
	local eyeAng = ply:EyeAngles()
	local forward = eyeAng:Forward()
	
	-- Create big kremowka entity
	local kremowka = ents.Create("prop_physics")
	if not IsValid(kremowka) then return end
	
	kremowka:SetModel("models/kremowka/kremowka.mdl")
	kremowka:SetPos(eyePos + forward * 50)
	kremowka:SetAngles(eyeAng)
	kremowka:Spawn()
	kremowka:Activate()
	
	-- Make it bigger (1.5x scale)
	kremowka:SetModelScale(5, 0)
	
	-- Disable collision damage
	kremowka:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	
	-- Set physics properties
	local phys = kremowka:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetVelocity(forward * self.ThrowForce + Vector(0, 0, 100))
		phys:AddAngleVelocity(VectorRand() * 10)
		phys:SetMass(1)
	end
	
	-- Mark as SCP-2137-J big kremowka
	kremowka.IsSCP2137JKremowka = true
	kremowka.IsSCP2137JBigKremowka = true
	kremowka.SCP2137JOwner = ply
	
	-- Set explosion timer (3 seconds)
	timer.Simple(3, function()
		if IsValid(kremowka) then
			self:ExplodeBigKremowka(kremowka)
		end
	end)
	
	-- Network to client for effects
	net.Start("scp2137j_throw_big_kremowka")
	net.WriteVector(eyePos)
	net.WriteAngle(eyeAng)
	net.Broadcast()
end

function SWEP:ExplodeKremowka(kremowka)
	if not SERVER then return end
	if not IsValid(kremowka) then return end
	
	local pos = kremowka:GetPos()
	local owner = kremowka.SCP2137JOwner
	
	-- Create explosion effect
	local effectdata = EffectData()
	effectdata:SetOrigin(pos)
	effectdata:SetMagnitude(150)
	effectdata:SetScale(1)
	util.Effect("Explosion", effectdata)
	
	-- Damage nearby entities
	for _, ent in pairs(ents.FindInSphere(pos, 150)) do
		local shouldDamage = false
		local damage = 0
		
		-- Check line of sight
		local targetPos = ent:GetPos()
		if ent:IsPlayer() then
			targetPos = ent:GetPos() + Vector(0, 0, 36) -- Eye level for players
		else
			targetPos = ent:GetPos() + ent:OBBCenter() -- Center of entity
		end
		
		local trace = util.TraceLine({
			start = pos,
			endpos = targetPos,
			filter = {kremowka, ent}
		})
		
		-- Only damage if line of sight is clear
		if not trace.Hit then
			-- Damage players (non-SCP and SCP-035)
			if ent:IsPlayer() and ent:Alive() and (ent:GTeam() != TEAM_SCP or ent:GetNClass() == ROLES.ROLE_SCP035) then
				shouldDamage = true
				local distance = ent:GetPos():Distance(pos)
				damage = math.max(15, 100 - (distance / 3))
			end
			
			-- Damage breakable entities (func_breakable, prop_physics, etc.)
			if ent:GetClass() == "func_breakable" or 
			   ent:GetClass() == "func_breakable_surf" or
			   ent:GetClass() == "prop_physics" or
			   ent:GetClass() == "prop_dynamic" then
				shouldDamage = true
				damage = 100 -- Fixed damage for breakables
			end
		end
		
		if shouldDamage then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage(damage)
			dmginfo:SetDamageType(DMG_BLAST)
			dmginfo:SetAttacker(IsValid(owner) and owner or kremowka)
			dmginfo:SetInflictor(kremowka)
			dmginfo:SetDamagePosition(pos)
			
			ent:TakeDamageInfo(dmginfo)
		end
	end
	
	-- Remove kremowka
	kremowka:Remove()
end

function SWEP:ExplodeBigKremowka(kremowka)
	if not SERVER then return end
	if not IsValid(kremowka) then return end
	
	local pos = kremowka:GetPos()
	local owner = kremowka.SCP2137JOwner
	
	-- Create bigger explosion effect
	local effectdata = EffectData()
	effectdata:SetOrigin(pos)
	effectdata:SetMagnitude(250) -- Bigger explosion
	effectdata:SetScale(1.5)
	util.Effect("Explosion", effectdata)
	
	-- Damage nearby entities (bigger radius and more damage)
	for _, ent in pairs(ents.FindInSphere(pos, 200)) do -- Increased radius from 150 to 200
		local shouldDamage = false
		local damage = 0
		
		-- Check line of sight
		local targetPos = ent:GetPos()
		if ent:IsPlayer() then
			targetPos = ent:GetPos() + Vector(0, 0, 36) -- Eye level for players
		else
			targetPos = ent:GetPos() + ent:OBBCenter() -- Center of entity
		end
		
		local trace = util.TraceLine({
			start = pos,
			endpos = targetPos,
			filter = {kremowka, ent}
		})
		
		-- Only damage if line of sight is clear
		if not trace.Hit then
			-- Damage players (non-SCP and SCP-035) - increased damage
			if ent:IsPlayer() and ent:Alive() and (ent:GTeam() != TEAM_SCP or ent:GetNClass() == ROLES.ROLE_SCP035) then
				shouldDamage = true
				local distance = ent:GetPos():Distance(pos)
				damage = math.max(30, 180 - (distance / 2.5)) -- Increased from 15/100 to 30/180
			end
			
			-- Damage breakable entities - increased damage
			if ent:GetClass() == "func_breakable" or 
			   ent:GetClass() == "func_breakable_surf" or
			   ent:GetClass() == "prop_physics" or
			   ent:GetClass() == "prop_dynamic" then
				shouldDamage = true
				damage = 200 -- Increased from 100 to 200
			end
		end
		
		if shouldDamage then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage(damage)
			dmginfo:SetDamageType(DMG_BLAST)
			dmginfo:SetAttacker(IsValid(owner) and owner or kremowka)
			dmginfo:SetInflictor(kremowka)
			dmginfo:SetDamagePosition(pos)
			
			ent:TakeDamageInfo(dmginfo)
		end
	end
	
	-- Remove kremowka
	kremowka:Remove()
end

function SWEP:SecondaryAttack()
	if not IsFirstTimePredicted() then return end
	if CurTime() < self.NextSecondaryAttack then return end
	
	self:ThrowBigKremowka()
	self.NextSecondaryAttack = CurTime() + self.SecondaryDelay
end

function SWEP:Reload()
	-- No reload
end

function SWEP:Think()
	-- No special think behavior needed
end

if CLIENT then
	function SWEP:DrawHUD()
		if disablehud == true then return end
		
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		
		-- Draw standard SCP HUD
		self:DrawSCPHUD()
		
		-- Draw crosshair
		local centerX, centerY = ScrW() / 2, ScrH() / 2
		surface.SetDrawColor(255, 255, 255, 200)
		surface.DrawLine(centerX - 10, centerY, centerX + 10, centerY)
		surface.DrawLine(centerX, centerY - 10, centerX, centerY + 10)
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
		local titleW, titleH = surface.GetTextSize("SCP-2137-J")
		surface.SetTextPos(centerX - titleW / 2, hudY + 10)
		surface.DrawText("SCP-2137-J")
		
		-- Cooldowny kremówek
		local cooldownY = hudY + 60
		local barWidth = 120
		local barHeight = 8
		local spacing = 20
		local totalWidth = barWidth * 2 + spacing
		local startX = centerX - totalWidth / 2
		
		-- LMB Cooldown (Kremówka)
		local lmbBarX = startX
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		surface.SetTextPos(lmbBarX, cooldownY - 15)
		surface.DrawText("LMB - Kremówka")
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
		
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
		
		local kremowkaCooldown = 0
		local timeSinceAttack = CurTime() - (self.NextAttack - self.AttackDelay)
		local cooldownProgress = math.Clamp(timeSinceAttack / self.AttackDelay, 0, 1)
		
		if cooldownProgress < 1 then
			kremowkaCooldown = self.NextAttack - CurTime()
		end
		
		if kremowkaCooldown > 0 then
			local progress = 1 - (kremowkaCooldown / self.AttackDelay)
			surface.SetDrawColor(255, 200, 0, 200)
			surface.DrawRect(lmbBarX, cooldownY, barWidth * progress, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(255, 255, 150, 255)
			surface.SetTextPos(lmbBarX, cooldownY + 10)
			surface.DrawText(string.format("%.1fs", kremowkaCooldown))
		else
			surface.SetDrawColor(100, 255, 100, 255)
			surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(150, 255, 150, 255)
			surface.SetTextPos(lmbBarX, cooldownY + 10)
			surface.DrawText("READY")
		end
		
		-- RMB Cooldown (Big Kremówka)
		local rmbBarX = startX + barWidth + spacing
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		surface.SetTextPos(rmbBarX, cooldownY - 15)
		surface.DrawText("RMB - Big Kremówka")
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
		
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
		
		local bigKremowkaCooldown = 0
		local timeSinceSecondary = CurTime() - (self.NextSecondaryAttack - self.SecondaryDelay)
		local secondaryCooldownProgress = math.Clamp(timeSinceSecondary / self.SecondaryDelay, 0, 1)
		
		if secondaryCooldownProgress < 1 then
			bigKremowkaCooldown = self.NextSecondaryAttack - CurTime()
		end
		
		if bigKremowkaCooldown > 0 then
			local progress = 1 - (bigKremowkaCooldown / self.SecondaryDelay)
			surface.SetDrawColor(255, 200, 0, 200)
			surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(255, 255, 150, 255)
			surface.SetTextPos(rmbBarX, cooldownY + 10)
			surface.DrawText(string.format("%.1fs", bigKremowkaCooldown))
		else
			surface.SetDrawColor(100, 255, 100, 255)
			surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(150, 255, 150, 255)
			surface.SetTextPos(rmbBarX, cooldownY + 10)
			surface.DrawText("READY")
		end
		

	end
	
	-- Receive throw effect
	net.Receive("scp2137j_throw_kremowka", function()
		local pos = net.ReadVector()
		local ang = net.ReadAngle()
		
		-- Play throw sound
		sound.Play("physics/body/body_medium_impact_soft_" .. math.random(1, 7) .. ".wav", pos, 75, math.random(90, 110))
	end)
	
	-- Receive big throw effect
	net.Receive("scp2137j_throw_big_kremowka", function()
		local pos = net.ReadVector()
		local ang = net.ReadAngle()
		
		-- Play deeper throw sound for big kremowka
		sound.Play("physics/body/body_medium_impact_soft_" .. math.random(1, 7) .. ".wav", pos, 75, math.random(70, 90))
	end)
	
	-- Receive resurrection effect
	net.Receive("scp2137j_resurrection", function()
		local pos = net.ReadVector()
		
		-- Play resurrection sound
		sound.Play("ambient/explosions/explode_4.wav", pos, 100, 80)
		
		-- Play holy/divine sound
		timer.Simple(0.5, function()
			sound.Play("ambient/atmosphere/cave_hit" .. math.random(1, 6) .. ".wav", pos, 90, 120)
		end)
	end)
end 