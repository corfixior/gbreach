AddCSLuaFile()

SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-2521"

SWEP.HoldType = "normal"

-- Attack delays and cooldowns
SWEP.MeleeDelay = 6 -- 6 second cooldown
SWEP.SilenceDelay = 60 -- 60 second cooldown 
SWEP.TeleportDelay = 60 -- 60 second cooldown
SWEP.NextMelee = 0
SWEP.NextSilence = 0
SWEP.NextTeleport = 0

-- Attack properties
SWEP.MeleeDamage = 99
SWEP.MeleeRange = 100
SWEP.SilenceRadius = 400
SWEP.SilenceDuration = 4
SWEP.TeleportRange = 1000
SWEP.PassiveDamageRadius = 300
SWEP.PassiveDamage = 5
SWEP.PassiveDamageDelay = 1

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID("breach/wep_2521")
	
	-- Teleport preview
	SWEP.TeleportPreview = false
	SWEP.TeleportPos = Vector()
	SWEP.PreviewModel = nil
	SWEP.NextPreviewToggle = 0
	
	-- Black smoke effect (like SCP-054 but black)
	net.Receive("SCP2521_CreateSmoke", function()
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
				particle:SetColor(0, 0, 0) -- Black smoke instead of white
				particle:SetAirResistance(100)
				particle:SetGravity(Vector(0, 0, -10))
			end
		end
		emitter:Finish()
	end)
	
	-- Black smoke effect for hit player (3 seconds)
	net.Receive("SCP2521_CreateHitSmoke", function()
		local target = net.ReadEntity()
		if !IsValid(target) then return end
		
		-- Create timer for 3 second smoke effect
		local timerName = "SCP2521_HitSmoke_" .. target:EntIndex()
		timer.Remove(timerName) -- Remove existing timer if any
		
		timer.Create(timerName, 0.2, 15, function() -- 0.2s * 15 = 3 seconds
			if !IsValid(target) or !target:Alive() then
				timer.Remove(timerName)
				return
			end
			
			local pos = target:GetPos()
			local emitter = ParticleEmitter(pos)
			for i = 1, 8 do -- Less particles per interval but more frequent
				local particle = emitter:Add("particle/smokesprites_0001", pos + Vector(math.random(-30, 30), math.random(-30, 30), math.random(20, 70)))
				if particle then
					particle:SetVelocity(Vector(math.random(-20, 20), math.random(-20, 20), math.random(10, 30)))
					particle:SetDieTime(1.5)
					particle:SetStartAlpha(120)
					particle:SetEndAlpha(0)
					particle:SetStartSize(25)
					particle:SetEndSize(50)
					particle:SetRoll(math.random(0, 360))
					particle:SetRollDelta(math.random(-0.3, 0.3))
					particle:SetColor(0, 0, 0) -- Black smoke
					particle:SetAirResistance(80)
					particle:SetGravity(Vector(0, 0, -5))
				end
			end
			emitter:Finish()
		end)
	end)
	
	function SWEP:UpdateTeleportPreview()
		if !self.TeleportPreview then return end
		
		local owner = self.Owner
		if !IsValid(owner) then return end
		
		-- Calculate teleport position
		local tr = util.TraceLine({
			start = owner:EyePos(),
			endpos = owner:EyePos() + owner:EyeAngles():Forward() * self.TeleportRange,
			filter = owner,
			mask = MASK_PLAYERSOLID
		})
		
		self.TeleportPos = tr.HitPos
		
		-- Create or update preview model
		if !IsValid(self.PreviewModel) then
			self.PreviewModel = ClientsideModel(owner:GetModel(), RENDERGROUP_TRANSLUCENT)
			self.PreviewModel:SetNoDraw(true)
		end
		
		if IsValid(self.PreviewModel) then
			self.PreviewModel:SetPos(self.TeleportPos)
			self.PreviewModel:SetAngles(owner:EyeAngles())
			
			-- Make it transparent and colored
			self.PreviewModel:SetColor(Color(255, 255, 255, 100))
			self.PreviewModel:SetRenderMode(RENDERMODE_TRANSALPHA)
		end
	end
	

	
	hook.Add("PostDrawOpaqueRenderables", "SCP2521_DrawPreview", function()
		for _, ply in pairs(player.GetAll()) do
			local wep = ply:GetActiveWeapon()
			if IsValid(wep) and wep:GetClass() == "weapon_scp_2521" and wep.TeleportPreview and IsValid(wep.PreviewModel) then
				wep.PreviewModel:DrawModel()
			end
		end
	end)
	
	function SWEP:OnRemove()
		if IsValid(self.PreviewModel) then
			self.PreviewModel:Remove()
			self.PreviewModel = nil
		end
		self.TeleportPreview = false
		self.NextPreviewToggle = 0
	end
	
	-- Also clean up when holstering
	function SWEP:Holster()
		if IsValid(self.PreviewModel) then
			self.PreviewModel:Remove()
			self.PreviewModel = nil
		end
		self.TeleportPreview = false
		self.NextPreviewToggle = 0
		return true
	end
	
	-- Clean up hooks when gamemode changes
	hook.Add("OnGamemodeLoaded", "SCP2521_CleanupHooks", function()
		hook.Remove("PostDrawOpaqueRenderables", "SCP2521_DrawPreview")
		hook.Remove("PlayerSay", "SCP2521_ChatDetection")
		hook.Remove("PlayerSwitchWeapon", "SCP2521_ForceHolster")
		hook.Remove("PlayerDeath", "SCP2521_CleanupHitSmoke")
	end)
	
	-- Clean up hit smoke timers when player dies
	hook.Add("PlayerDeath", "SCP2521_CleanupHitSmoke", function(victim, inflictor, attacker)
		if IsValid(victim) then
			timer.Remove("SCP2521_HitSmoke_" .. victim:EntIndex())
		end
	end)
end

function SWEP:Initialize()
	self:InitializeLanguage("SCP_2521")
	self:SetHoldType(self.HoldType)
	
	if SERVER then
		-- Initialize network variables
		self:SetNWFloat("NextMelee", 0)
		self:SetNWFloat("NextSilence", 0) 
		self:SetNWFloat("NextTeleport", 0)
		
		-- Table to track silenced players
		self.SilencedPlayers = {}
		
		-- Passive damage tracking
		self.NextPassiveDamage = 0
		
		-- Ensure owner has correct team
		timer.Simple(0.1, function()
			if IsValid(self) and IsValid(self.Owner) then
				if self.Owner:GTeam() != TEAM_SCP then
					self.Owner:StripWeapon("weapon_scp_2521")
				end
			end
		end)
	end
end

function SWEP:Think()
	self:PlayerFreeze()
	
	if SERVER then
		self:PassiveDamageThink()
		self:UpdateSilencedPlayers()
	elseif CLIENT then
		if self.TeleportPreview then
			self:UpdateTeleportPreview()
		end
	end
end

-- SERVER FUNCTIONS
if SERVER then
	-- Passive damage for nearby players using chat/voice
	function SWEP:PassiveDamageThink()
		if self.NextPassiveDamage > CurTime() then return end
		self.NextPassiveDamage = CurTime() + self.PassiveDamageDelay
		
		local owner = self.Owner
		if !IsValid(owner) then return end
		
		local nearbyPlayers = ents.FindInSphere(owner:GetPos(), self.PassiveDamageRadius)
		
		for _, ply in pairs(nearbyPlayers) do
			if IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply != owner then
				if ply:GTeam() != TEAM_SCP and ply:GTeam() != TEAM_SPEC then
					-- Check if player is using voice chat or has recent chat activity
					local damage = 0
					
					-- Chat activity with character-based damage
					if ply.LastChatTime and CurTime() - ply.LastChatTime < 3 and ply.LastChatLength then
						damage = ply.LastChatLength -- Damage = character count
					end
					
					if damage > 0 then
						local dmginfo = DamageInfo()
						dmginfo:SetDamage(damage)
						dmginfo:SetAttacker(owner)
						dmginfo:SetInflictor(self)
						dmginfo:SetDamageType(DMG_DIRECT)
						ply:TakeDamageInfo(dmginfo)
					end
				end
			end
		end
	end
	
	-- Update force holstered players
	function SWEP:UpdateSilencedPlayers()
		for ply, endTime in pairs(self.SilencedPlayers) do
			if CurTime() > endTime then
				self.SilencedPlayers[ply] = nil
				if IsValid(ply) then
					ply:SetNWBool("IsForceHolstered", false)
				end
			end
		end
	end
	
	-- Hook for chat detection with character counting
	hook.Add("PlayerSay", "SCP2521_ChatDetection", function(ply, text, public)
		ply.LastChatTime = CurTime()
		ply.LastChatLength = string.len(text) -- Count all characters including spaces
	end)
	

	
	-- Hook for preventing weapon switching during force holster
	hook.Add("PlayerSwitchWeapon", "SCP2521_ForceHolster", function(ply, oldwep, newwep)
		if IsValid(ply) and ply:GetNWBool("IsForceHolstered", false) then
			if IsValid(newwep) and newwep:GetClass() != "br_holster" and newwep:GetClass() != "br_id" then
				ply:PrintMessage(HUD_PRINTCENTER, "You are forced to holster your weapons!")
				return true -- Prevent switching from holster
			end
		end
	end)
end

-- Helper function to check if weapon can be used
function SWEP:CanUseWeapon()
	local owner = self.Owner
	if !IsValid(owner) or !owner:Alive() then return false end
	if owner:GTeam() != TEAM_SCP and owner:GetNClass() != ROLES.ROLE_SCP035 then return false end
	return true
end

-- PRIMARY ATTACK - Melee Attack (99 damage, 6s cooldown, black smoke)
function SWEP:PrimaryAttack()
	if !self:CanUseWeapon() then return end
	if self.NextMelee > CurTime() then return end
	
	local owner = self.Owner
	
	-- Attack animation
	owner:SetAnimation(PLAYER_ATTACK1)
	
	if SERVER then
		-- Trace for target
		local tr = util.TraceLine({
			start = owner:EyePos(),
			endpos = owner:EyePos() + owner:EyeAngles():Forward() * self.MeleeRange,
			filter = owner,
			mask = MASK_SHOT_HULL
		})
		
		if IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity:Alive() then
			local target = tr.Entity
			
			if target:GTeam() != TEAM_SCP and target:GTeam() != TEAM_SPEC then
				-- Set cooldown only when we hit a valid target
				self.NextMelee = CurTime() + self.MeleeDelay
				self:SetNWFloat("NextMelee", self.NextMelee)
				
				-- Deal damage
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(self.MeleeDamage)
				dmginfo:SetAttacker(owner)
				dmginfo:SetInflictor(self)
				dmginfo:SetDamageType(DMG_SLASH)
				dmginfo:SetDamagePosition(tr.HitPos)
				target:TakeDamageInfo(dmginfo)
				
				-- Create smoke effect on hit target (3 seconds)
				net.Start("SCP2521_CreateHitSmoke")
					net.WriteEntity(target)
				net.Broadcast()
				
				-- Experience gain
				if owner.AddExp then
					owner:AddExp(50, true)
				end
			end
		end
	end
end

-- SECONDARY ATTACK - Force Holster (4s duration, 60s cooldown)  
function SWEP:SecondaryAttack()
	if !self:CanUseWeapon() then return end
	if self.NextSilence > CurTime() then return end
	
	local owner = self.Owner
	
	self.NextSilence = CurTime() + self.SilenceDelay
	self:SetNWFloat("NextSilence", self.NextSilence)
	
	if SERVER then
		-- Find nearby enemies
		local nearbyPlayers = ents.FindInSphere(owner:GetPos(), self.SilenceRadius)
		local forcedCount = 0
		
		for _, ply in pairs(nearbyPlayers) do
			if IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply != owner then
				if (ply:GTeam() != TEAM_SCP or ply:GetNClass() == ROLES.ROLE_SCP035) and ply:GTeam() != TEAM_SPEC then
					-- Force holster for 4 seconds
					self.SilencedPlayers[ply] = CurTime() + self.SilenceDuration
					ply:SetNWBool("IsForceHolstered", true)
					
					-- Force holster weapon
					ply:SelectWeapon("br_holster")
					
					forcedCount = forcedCount + 1
				end
			end
		end
		
		if forcedCount > 0 then
			-- Experience gain
			if owner.AddExp then
				owner:AddExp(25 * forcedCount, true)
			end
		end
	end
end

-- RELOAD - Teleport (60s cooldown with preview)
function SWEP:Reload()
	if !self:CanUseWeapon() then return end
	local teleportCooldown = math.max(0, self:GetNWFloat("NextTeleport", 0) - CurTime())
	if teleportCooldown > 0 then return end
	
	local owner = self.Owner
	
	if CLIENT then
		-- Check if we can toggle preview (1 second cooldown)
		if CurTime() < self.NextPreviewToggle then return end
		
		if !self.TeleportPreview then
			-- Start preview mode
			self.TeleportPreview = true
			self.NextPreviewToggle = CurTime() + 1 -- 1 second cooldown
			self:UpdateTeleportPreview()
		else
			-- Execute teleport
			self.TeleportPreview = false
			self.NextPreviewToggle = CurTime() + 1 -- 1 second cooldown
			
			-- Clean up preview model
			if IsValid(self.PreviewModel) then
				self.PreviewModel:Remove()
				self.PreviewModel = nil
			end
			
			-- Send teleport request to server
			net.Start("SCP2521_Teleport")
				net.WriteVector(self.TeleportPos)
			net.SendToServer()
		end
		return
	end
end

if SERVER then
	util.AddNetworkString("SCP2521_Teleport")
	util.AddNetworkString("SCP2521_CreateSmoke")
	util.AddNetworkString("SCP2521_CreateHitSmoke")
	
	net.Receive("SCP2521_Teleport", function(len, ply)
		local wep = ply:GetActiveWeapon()
		if !IsValid(wep) or wep:GetClass() != "weapon_scp_2521" then return end
		
		local teleportCooldown = math.max(0, wep:GetNWFloat("NextTeleport", 0) - CurTime())
		if teleportCooldown > 0 then return end
		
		local teleportPos = net.ReadVector()
		
		-- Validate position
		local tr = util.TraceLine({
			start = ply:EyePos(),
			endpos = ply:EyePos() + ply:EyeAngles():Forward() * wep.TeleportRange,
			filter = ply,
			mask = MASK_PLAYERSOLID
		})
		
		-- Check if position is close to calculated position (anti-cheat)
		if teleportPos:Distance(tr.HitPos) > 100 then
			ply:PrintMessage(HUD_PRINTCENTER, "Invalid teleport position!")
			return
		end
		
		-- Check if position is valid (not inside wall)
		local hullTrace = util.TraceHull({
			start = teleportPos,
			endpos = teleportPos,
			mins = Vector(-16, -16, 0),
			maxs = Vector(16, 16, 72),
			filter = ply,
			mask = MASK_PLAYERSOLID
		})
		
		if hullTrace.Hit then
			ply:PrintMessage(HUD_PRINTCENTER, "Cannot teleport into solid objects!")
			return
		end
		
		wep.NextTeleport = CurTime() + wep.TeleportDelay
		wep:SetNWFloat("NextTeleport", wep.NextTeleport)
		
		-- Create black smoke effect at old position (like SCP-054)
		local oldPos = ply:GetPos()
		net.Start("SCP2521_CreateSmoke")
			net.WriteVector(oldPos)
		net.Broadcast()
		

		
		-- Teleport
		ply:SetPos(teleportPos)
		
		-- Create black smoke effect at new position (like SCP-054)
		net.Start("SCP2521_CreateSmoke")
			net.WriteVector(teleportPos)
		net.Broadcast()
		
		-- Creepy teleport sound at new position (~1 second)
		sound.Play("ambient/atmosphere/cave_hit1.wav", teleportPos, 70, 70)
		sound.Play("ambient/wind/wind_hit1.wav", teleportPos, 60, 50)
		sound.Play("ambient/atmosphere/underground_explosion_distant1.wav", teleportPos, 50, 40)
		
		-- Experience gain
		if ply.AddExp then
			ply:AddExp(10, true)
		end
	end)
end

-- CLIENT FUNCTIONS
if CLIENT then

	
	-- HUD elements
	function SWEP:DrawHUD()
		if disablehud == true then return end
		
		local ply = LocalPlayer()
		if !IsValid(ply) then return end
		
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
		local titleW, titleH = surface.GetTextSize("SCP-2521")
		surface.SetTextPos(centerX - titleW / 2, hudY + 10)
		surface.DrawText("SCP-2521")
		

		
		-- Cooldowny
		local cooldownY = hudY + 60
		local barWidth = 140
		local barHeight = 8
		local spacing = 20
		local totalWidth = barWidth * 3 + spacing * 2
		local startX = centerX - totalWidth / 2
		
		-- LMB - Dark Strike
		local lmbBarX = startX
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		surface.SetTextPos(lmbBarX, cooldownY - 15)
		surface.DrawText("LMB - Dark Strike")
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
		
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
		
		local meleeCooldown = math.max(0, self:GetNWFloat("NextMelee", 0) - CurTime())
		
		if meleeCooldown > 0 then
			local progress = 1 - (meleeCooldown / self.MeleeDelay)
			surface.SetDrawColor(150, 50, 150, 255)
			surface.DrawRect(lmbBarX, cooldownY, barWidth * progress, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(200, 150, 200, 255)
			surface.SetTextPos(lmbBarX, cooldownY + 10)
			surface.DrawText(string.format("%.1fs", meleeCooldown))
		else
			surface.SetDrawColor(100, 255, 100, 255)
			surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(150, 255, 150, 255)
			surface.SetTextPos(lmbBarX, cooldownY + 10)
			surface.DrawText("READY")
		end
		
		-- RMB - Silence Field
		local rmbBarX = startX + barWidth + spacing
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		surface.SetTextPos(rmbBarX, cooldownY - 15)
		surface.DrawText("RMB - Force Holster")
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
		
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
		
		local silenceCooldown = math.max(0, self:GetNWFloat("NextSilence", 0) - CurTime())
		
		if silenceCooldown > 0 then
			local progress = 1 - (silenceCooldown / self.SilenceDelay)
			surface.SetDrawColor(255, 200, 0, 255)
			surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(255, 255, 150, 255)
			surface.SetTextPos(rmbBarX, cooldownY + 10)
			surface.DrawText(string.format("%.0fs", silenceCooldown))
		else
			surface.SetDrawColor(100, 255, 100, 255)
			surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(150, 255, 150, 255)
			surface.SetTextPos(rmbBarX, cooldownY + 10)
			surface.DrawText("READY")
		end
		
		-- R - Teleport
		local rBarX = startX + (barWidth + spacing) * 2
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		surface.SetTextPos(rBarX, cooldownY - 15)
		surface.DrawText("R - Teleport")
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(rBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
		
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(rBarX, cooldownY, barWidth, barHeight)
		
		local teleportCooldown = math.max(0, self:GetNWFloat("NextTeleport", 0) - CurTime())
		
		if self.TeleportPreview then
			-- Preview mode - show different color and text
			surface.SetDrawColor(255, 255, 0, 255)
			surface.DrawRect(rBarX, cooldownY, barWidth, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(255, 255, 100, 255)
			surface.SetTextPos(rBarX, cooldownY + 10)
			surface.DrawText("PREVIEW")
		elseif teleportCooldown > 0 then
			local progress = 1 - (teleportCooldown / self.TeleportDelay)
			surface.SetDrawColor(100, 150, 255, 255)
			surface.DrawRect(rBarX, cooldownY, barWidth * progress, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(150, 200, 255, 255)
			surface.SetTextPos(rBarX, cooldownY + 10)
			surface.DrawText(string.format("%.0fs", teleportCooldown))
		else
			surface.SetDrawColor(100, 255, 100, 255)
			surface.DrawRect(rBarX, cooldownY, barWidth, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(150, 255, 150, 255)
			surface.SetTextPos(rBarX, cooldownY + 10)
			surface.DrawText("READY")
		end
		
		-- Celownik
		local x = ScrW() / 2.0
		local y = ScrH() / 2.0
		
		local scale = 0.3
		surface.SetDrawColor(150, 50, 150, 255)
		
		local gap = 5
		local length = gap + 20 * scale
		surface.DrawLine( x - length, y, x - gap, y )
		surface.DrawLine( x + length, y, x + gap, y )
		surface.DrawLine( x, y - length, x, y - gap )
		surface.DrawLine( x, y + length, x, y + gap )
		

		

	end
end
