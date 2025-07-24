AddCSLuaFile()

SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-1316"

SWEP.HoldType = "normal"

-- SCP-1316 Configuration
SWEP.AttackDelay = 1.0
SWEP.DefensiveAbilityCooldown = 60
SWEP.DefensiveAbilityDuration = 10
SWEP.HitDistance = 80

-- Ride System
SWEP.RidingTarget = nil
SWEP.IsRiding = false
SWEP.NextDefensiveUse = 0

-- No viewmodel needed for cat

if SERVER then
	util.AddNetworkString("scp1316_start_riding")
	util.AddNetworkString("scp1316_stop_riding")
	util.AddNetworkString("scp1316_defensive_ability")
	util.AddNetworkString("scp1316_sync_rider")
	
	-- Hook to handle when riding target dies or disconnects
	hook.Add("PlayerDeath", "SCP1316_StopRiding", function(victim, inflictor, attacker)
		if victim.SCP1316_Rider then
			local scp1316 = victim.SCP1316_Rider
			if IsValid(scp1316) then
				local weapon = scp1316:GetActiveWeapon()
				if IsValid(weapon) and weapon:GetClass() == "weapon_scp_1316" then
					weapon:StopRiding()
				end
			end
		end
	end)
	
	hook.Add("PlayerDisconnected", "SCP1316_StopRiding", function(ply)
		if ply.SCP1316_Rider then
			local scp1316 = ply.SCP1316_Rider
			if IsValid(scp1316) then
				local weapon = scp1316:GetActiveWeapon()
				if IsValid(weapon) and weapon:GetClass() == "weapon_scp_1316" then
					weapon:StopRiding()
				end
			end
		end
	end)
	
	-- Hook to reset riding when SCP-1316 dies
	hook.Add("PlayerDeath", "SCP1316_ResetRiding", function(victim, inflictor, attacker)
		if IsValid(victim) and victim:GTeam() == TEAM_SCP then
			local weapon = victim:GetActiveWeapon()
			if IsValid(weapon) and weapon:GetClass() == "weapon_scp_1316" then
				weapon:StopRiding()
			end
		end
	end)
	
	-- Hook to make SCP-1316 immortal and transparent when riding
	hook.Add("EntityTakeDamage", "SCP1316_RidingProtection", function(target, dmginfo)
		if IsValid(target) and target:IsPlayer() and target:GTeam() == TEAM_SCP then
			local weapon = target:GetActiveWeapon()
			if IsValid(weapon) and weapon:GetClass() == "weapon_scp_1316" and weapon.IsRiding then
				-- Immortal when riding
				return true
			end
		end
	end)
	
	-- Hook for defensive ability damage reduction
	hook.Add("EntityTakeDamage", "SCP1316_DefensiveAbility", function(target, dmginfo)
		if IsValid(target) and target:IsPlayer() and target.SCP1316_DefensiveActive then
			-- 99% damage reduction
			dmginfo:ScaleDamage(0.01)
		end
	end)
end

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID("breach/wep_1316")
	
	-- Third person camera when riding
	local thirdPersonActive = false
	local originalCalcView = nil
	
	net.Receive("scp1316_start_riding", function()
		thirdPersonActive = true
		
		-- Store original CalcView if not already stored
		if not originalCalcView then
			originalCalcView = GAMEMODE.CalcView
		end
		
		-- Override CalcView for third person
		GAMEMODE.CalcView = function(self, ply, pos, angles, fov)
			if ply == LocalPlayer() and thirdPersonActive then
				local view = {}
				view.origin = pos - angles:Forward() * 100 + angles:Up() * 20
				view.angles = angles
				view.fov = fov
				view.drawviewer = true
				return view
			end
			
			-- Call original CalcView for other cases
			if originalCalcView then
				return originalCalcView(self, ply, pos, angles, fov)
			end
		end
	end)
	
	net.Receive("scp1316_stop_riding", function()
		thirdPersonActive = false
		
		-- Restore original CalcView
		if originalCalcView then
			GAMEMODE.CalcView = originalCalcView
		end
	end)
	
	-- Receive rider sync for cat icon
	net.Receive("scp1316_sync_rider", function()
		local target = net.ReadEntity()
		local hasRider = net.ReadBool()
		
		if IsValid(target) then
			target.SCP1316_HasRider = hasRider and true or nil
		end
	end)
	
	-- Draw custom cat icon above riding target's head
	hook.Add("PostPlayerDraw", "SCP1316_DrawCatIcon", function(ply)
		if ply.SCP1316_HasRider then
			local pos = ply:GetPos() + Vector(0, 0, 85)
			local ang = LocalPlayer():EyeAngles()
			ang:RotateAroundAxis(ang:Forward(), 90)
			ang:RotateAroundAxis(ang:Right(), 90)
			
			cam.Start3D2D(pos, ang, 0.15)
				-- Draw circle background
				surface.SetDrawColor(50, 50, 50, 200)
				draw.NoTexture()
				surface.DrawPoly({
					{x = 0, y = -30},
					{x = 21, y = -21},
					{x = 30, y = 0},
					{x = 21, y = 21},
					{x = 0, y = 30},
					{x = -21, y = 21},
					{x = -30, y = 0},
					{x = -21, y = -21}
				})
				
				-- Draw circle border
				surface.SetDrawColor(255, 200, 100, 255)
				for i = 0, 360, 10 do
					local x1 = math.cos(math.rad(i)) * 27
					local y1 = math.sin(math.rad(i)) * 27
					local x2 = math.cos(math.rad(i + 10)) * 27
					local y2 = math.sin(math.rad(i + 10)) * 27
					surface.DrawLine(x1, y1, x2, y2)
				end
				
				-- Draw cat whiskers
				surface.SetDrawColor(255, 255, 255, 255)
				-- Left whiskers
				surface.DrawLine(-22, -4, -12, -3)
				surface.DrawLine(-22, 0, -12, 0)
				surface.DrawLine(-22, 4, -12, 3)
				-- Right whiskers  
				surface.DrawLine(22, -4, 12, -3)
				surface.DrawLine(22, 0, 12, 0)
				surface.DrawLine(22, 4, 12, 3)
				
				-- Draw cat ears (triangles)
				surface.SetDrawColor(255, 200, 100, 255)
				draw.NoTexture()
				-- Left ear
				surface.DrawPoly({
					{x = -12, y = -18},
					{x = -4, y = -27},
					{x = 3, y = -18}
				})
				-- Right ear
				surface.DrawPoly({
					{x = -3, y = -18},
					{x = 4, y = -27},
					{x = 12, y = -18}
				})
				
				-- Draw cat eyes
				surface.SetDrawColor(100, 255, 100, 255)
				draw.NoTexture()
				-- Left eye
				surface.DrawPoly({
					{x = -9, y = -6},
					{x = -4, y = -9},
					{x = -4, y = -3}
				})
				-- Right eye
				surface.DrawPoly({
					{x = 4, y = -6},
					{x = 9, y = -9},
					{x = 9, y = -3}
				})
				
				-- Draw cat nose (small triangle)
				surface.SetDrawColor(255, 150, 150, 255)
				surface.DrawPoly({
					{x = -1, y = 3},
					{x = 1, y = 3},
					{x = 0, y = 6}
				})
				
			cam.End3D2D()
		end
	end)
end

function SWEP:Initialize()
	self:InitializeLanguage("SCP_1316")
	self:SetHoldType(self.HoldType)
	
	self.NextAttack = 0
	self.IsRiding = false
	self.RidingTarget = nil
	self.NextDefensiveUse = 0
end

function SWEP:StartRiding(target)
	if not SERVER then return end
	if not IsValid(target) or not target:IsPlayer() then return end
				if target:GTeam() == TEAM_SCP and target:GetNClass() != ROLES.ROLE_SCP035 then return end
	if self.IsRiding then return end
	
	self.IsRiding = true
	self.RidingTarget = target
	
	-- Set up riding relationship
	target.SCP1316_Rider = self.Owner
	target.SCP1316_HasRider = true
	target.SCP1316_OriginalSpeed = target:GetWalkSpeed()
	target.SCP1316_OriginalRunSpeed = target:GetRunSpeed()
	
	-- Apply speed boost to target (+20%)
	target:SetWalkSpeed(target:GetWalkSpeed() * 1.2)
	target:SetRunSpeed(target:GetRunSpeed() * 1.2)
	
	-- Make SCP-1316 invisible and non-solid
	self.Owner:SetNoDraw(true)
	self.Owner:SetSolid(SOLID_NONE)
	self.Owner:SetMoveType(MOVETYPE_NOCLIP)
	
	-- Start regeneration for target
	target.SCP1316_RegenTimer = timer.Create("SCP1316_Regen_" .. target:EntIndex(), 1, 0, function()
		if IsValid(target) and target:Alive() and target.SCP1316_HasRider then
			local newHealth = math.min(target:GetMaxHealth(), target:Health() + 1)
			target:SetHealth(newHealth)
		else
			timer.Remove("SCP1316_Regen_" .. target:EntIndex())
		end
	end)
	
	-- Network to client for third person camera
	net.Start("scp1316_start_riding")
	net.Send(self.Owner)
	
	-- Network to all clients to show cat icon
	net.Start("scp1316_sync_rider")
	net.WriteEntity(target)
	net.WriteBool(true)
	net.Broadcast()
	
	-- Sync riding target position
	self.Owner:SetPos(target:GetPos())
end

function SWEP:StopRiding()
	if not SERVER then return end
	if not self.IsRiding then return end
	
	local target = self.RidingTarget
	
	self.IsRiding = false
	self.RidingTarget = nil
	
	-- Restore SCP-1316 visibility and physics
	if IsValid(self.Owner) then
		self.Owner:SetNoDraw(false)
		self.Owner:SetSolid(SOLID_BBOX)
		self.Owner:SetMoveType(MOVETYPE_WALK)
	end
	
	-- Clean up target
	if IsValid(target) then
		target.SCP1316_Rider = nil
		target.SCP1316_HasRider = nil
		
		-- Restore original speed
		if target.SCP1316_OriginalSpeed then
			target:SetWalkSpeed(target.SCP1316_OriginalSpeed)
			target:SetRunSpeed(target.SCP1316_OriginalRunSpeed)
		end
		
		-- Stop regeneration
		timer.Remove("SCP1316_Regen_" .. target:EntIndex())
	end
	
	-- Network to client to stop third person camera
	if IsValid(self.Owner) then
		net.Start("scp1316_stop_riding")
		net.Send(self.Owner)
	end
	
	-- Network to all clients to hide cat icon
	if IsValid(target) then
		net.Start("scp1316_sync_rider")
		net.WriteEntity(target)
		net.WriteBool(false)
		net.Broadcast()
	end
end

function SWEP:DefensiveAbility()
	if not SERVER then return end
	if self.IsRiding then return end -- Can't use when riding
	if self.NextDefensiveUse > CurTime() then return end
	
	self.NextDefensiveUse = CurTime() + self.DefensiveAbilityCooldown
	
	-- Apply defensive buffs
	self.Owner.SCP1316_DefensiveActive = true
	
	-- 2x speed boost
	local originalWalk = self.Owner:GetWalkSpeed()
	local originalRun = self.Owner:GetRunSpeed()
	self.Owner:SetWalkSpeed(originalWalk * 2)
	self.Owner:SetRunSpeed(originalRun * 2)
	
	-- Remove buffs after duration
	timer.Simple(self.DefensiveAbilityDuration, function()
		if IsValid(self.Owner) then
			self.Owner.SCP1316_DefensiveActive = false
			self.Owner:SetWalkSpeed(originalWalk)
			self.Owner:SetRunSpeed(originalRun)
		end
	end)
	
	-- Network to client
	net.Start("scp1316_defensive_ability")
	net.Send(self.Owner)
end

function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextAttack > CurTime() then return end
	
	if self.IsRiding then
		-- Stop riding
		self:StopRiding()
	else
		-- Try to start riding
		local tr = util.TraceHull({
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.HitDistance,
			filter = self.Owner,
			mins = Vector(-16, -16, -16),
			maxs = Vector(16, 16, 16),
			mask = MASK_SHOT_HULL
		})
		
		if tr.Hit and IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity:GTeam() != TEAM_SCP then
			self:StartRiding(tr.Entity)
		end
	end
	
	self.NextAttack = CurTime() + self.AttackDelay
end

function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.IsRiding then return end -- Can't use when riding
	
	self:DefensiveAbility()
end

function SWEP:Reload()
	-- Manual stop riding
	if self.IsRiding then
		self:StopRiding()
	end
end

function SWEP:Think()
	-- Sync cooldown with client
	if SERVER then
		self:SetNWFloat("NextAttack", self.NextAttack)
		self:SetNWFloat("NextDefensiveUse", self.NextDefensiveUse)
		self:SetNWBool("IsRiding", self.IsRiding)
		
		-- Follow riding target
		if self.IsRiding and IsValid(self.RidingTarget) then
			self.Owner:SetPos(self.RidingTarget:GetPos())
		end
	end
end

function SWEP:Holster()
	if SERVER and self.IsRiding then
		self:StopRiding()
	end
	return true
end

function SWEP:OnRemove()
	if SERVER and self.IsRiding then
		self:StopRiding()
	end
end

if CLIENT then
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
		local titleW, titleH = surface.GetTextSize("SCP-1316")
		surface.SetTextPos(centerX - titleW / 2, hudY + 10)
		surface.DrawText("SCP-1316")
		
		local isRiding = self:GetNWBool("IsRiding", false)
		
		-- Cooldowny
		local cooldownY = hudY + 60
		local barWidth = 120
		local barHeight = 8
		local spacing = 20
		local totalWidth = barWidth * 2 + spacing
		local startX = centerX - totalWidth / 2
		
		-- LMB - Ride/Stop
		local lmbBarX = startX
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		if isRiding then
			surface.SetTextPos(lmbBarX, cooldownY - 15)
			surface.DrawText("LMB - Stop Riding")
		else
			surface.SetTextPos(lmbBarX, cooldownY - 15)
			surface.DrawText("LMB - Start Riding")
		end
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
		
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
		
		local attackCooldown = math.max(0, self:GetNWFloat("NextAttack", 0) - CurTime())
		
		if attackCooldown > 0 then
			local progress = 1 - (attackCooldown / self.AttackDelay)
			surface.SetDrawColor(255, 200, 100, 255)
			surface.DrawRect(lmbBarX, cooldownY, barWidth * progress, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(255, 220, 150, 255)
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
		
		-- RMB - Defensive Ability (only when not riding)
		if not isRiding then
			local rmbBarX = startX + barWidth + spacing
			surface.SetTextColor(200, 200, 200, 255)
			surface.SetFont("DermaDefaultBold")
			surface.SetTextPos(rmbBarX, cooldownY - 15)
			surface.DrawText("RMB - Defensive")
			
			surface.SetDrawColor(150, 150, 150, 255)
			surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
			
			surface.SetDrawColor(40, 40, 40, 200)
			surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
			
			local defensiveCooldown = math.max(0, self:GetNWFloat("NextDefensiveUse", 0) - CurTime())
			
			if defensiveCooldown > 0 then
				local progress = 1 - (defensiveCooldown / self.DefensiveAbilityCooldown)
				surface.SetDrawColor(255, 100, 100, 255)
				surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
				
				surface.SetFont("DermaDefault")
				surface.SetTextColor(255, 150, 150, 255)
				surface.SetTextPos(rmbBarX, cooldownY + 10)
				surface.DrawText(string.format("%.0fs", defensiveCooldown))
			else
				surface.SetDrawColor(100, 255, 100, 255)
				surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
				
				surface.SetFont("DermaDefault")
				surface.SetTextColor(150, 255, 150, 255)
				surface.SetTextPos(rmbBarX, cooldownY + 10)
				surface.DrawText("READY")
			end
		end
		
		-- Celownik (tylko gdy nie jedzie)
		if not isRiding then
			local x = ScrW() / 2.0
			local y = ScrH() / 2.0
			local scale = 0.3
			local color = Color(255, 200, 100, 255)
			surface.SetDrawColor(color)
			
			local gap = 5
			local length = gap + 20 * scale
			surface.DrawLine(x - length, y, x - gap, y)
			surface.DrawLine(x + length, y, x + gap, y)
			surface.DrawLine(x, y - length, x, y - gap)
			surface.DrawLine(x, y + length, x, y + gap)
		end
	end
end 