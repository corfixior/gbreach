AddCSLuaFile()

SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-3166"

SWEP.HoldType = "knife"

-- SCP-3166 Configuration
SWEP.AttackDelay = 2.0
SWEP.HitDistance = 80
SWEP.LasagnaTarget = nil
SWEP.SpeedBoost = false
SWEP.NextTargetSelect = 0

-- Models
SWEP.ViewModel = "models/weapons/cstrike/c_knife_t.mdl"
SWEP.WorldModel = "models/weapons/w_knife_t.mdl"
SWEP.ShowWorldModel = false
SWEP.ViewModelFOV = 54
SWEP.UseHands = true

if SERVER then
	util.AddNetworkString("scp3166_target_selected")
	util.AddNetworkString("scp3166_target_killed")
	
	-- Hook to reset model when lasagna target dies or disconnects
	hook.Add("PlayerDeath", "SCP3166_ResetLasagnaModel", function(victim, inflictor, attacker)
		if victim.IsLasagnaTarget then
			victim.IsLasagnaTarget = false
			if victim.OriginalModel then
				victim:SetModel(victim.OriginalModel)
			end
			
			-- If lasagna target died but not by SCP-3166, select new target
			local killedBySCP3166 = false
			if IsValid(attacker) and attacker:IsPlayer() and attacker:GTeam() == TEAM_SCP then
				local weapon = attacker:GetActiveWeapon()
				if IsValid(weapon) and weapon:GetClass() == "weapon_scp_3166" then
					killedBySCP3166 = true
				end
			end
			
			-- If not killed by SCP-3166, find SCP-3166 and select new target
			if not killedBySCP3166 then
				for _, ply in pairs(player.GetAll()) do
					if IsValid(ply) and ply:GTeam() == TEAM_SCP then
						local weapon = ply:GetActiveWeapon()
						if IsValid(weapon) and weapon:GetClass() == "weapon_scp_3166" then
							timer.Simple(1, function()
								if IsValid(weapon) then
									weapon:SelectLasagnaTarget()
								end
							end)
							break
						end
					end
				end
			end
		end
	end)
	
	hook.Add("PlayerDisconnected", "SCP3166_ResetLasagnaModel", function(ply)
		if ply.IsLasagnaTarget then
			ply.IsLasagnaTarget = false
		end
	end)
	
	-- Hook to reset all lasagna targets when SCP-3166 dies
	hook.Add("PlayerDeath", "SCP3166_ResetAllLasagna", function(victim, inflictor, attacker)
		if IsValid(victim) and victim:GTeam() == TEAM_SCP then
			local weapon = victim:GetActiveWeapon()
			if IsValid(weapon) and weapon:GetClass() == "weapon_scp_3166" then
				-- SCP-3166 died, reset all lasagna targets
				for _, ply in pairs(player.GetAll()) do
					if IsValid(ply) and ply.IsLasagnaTarget then
						ply.IsLasagnaTarget = false
						if ply.OriginalModel then
							ply:SetModel(ply.OriginalModel)
						end
					end
				end
			end
		end
	end)
	
	-- Hook to reset lasagna targets when SCP-3166 changes team
	hook.Add("PlayerChangeTeam", "SCP3166_ResetOnTeamChange", function(ply, oldteam, newteam)
		if IsValid(ply) and oldteam == TEAM_SCP and newteam != TEAM_SCP then
			local weapon = ply:GetActiveWeapon()
			if IsValid(weapon) and weapon:GetClass() == "weapon_scp_3166" then
				-- SCP-3166 left SCP team, reset all lasagna targets
				for _, target in pairs(player.GetAll()) do
					if IsValid(target) and target.IsLasagnaTarget then
						target.IsLasagnaTarget = false
						if target.OriginalModel then
							target:SetModel(target.OriginalModel)
						end
					end
				end
			end
		end
	end)
end

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID("breach/wep_3166")
	
	-- Receive target notifications
	net.Receive("scp3166_target_selected", function()
		local target = net.ReadEntity()
		-- Notification removed
	end)
	
	net.Receive("scp3166_target_killed", function()
		local killer = net.ReadEntity()
		if IsValid(killer) then
			chat.AddText(Color(255, 100, 0), "[SCP-3166] ", Color(255, 255, 255), "Lasagna target eliminated! SCP-3166 grows stronger!")
		end
	end)
end

-- Custom model elements for Garfield
-- No custom view model elements needed for claw attacks

function SWEP:Initialize()
	self:InitializeLanguage("SCP_3166")
	self:SetHoldType(self.HoldType)
	
	self.NextAttack = 0
	
	-- Select initial lasagna target
	if SERVER then
		timer.Simple(1, function()
			if IsValid(self) and IsValid(self.Owner) then
				self:SelectLasagnaTarget()
			end
		end)
	end
end

function SWEP:SelectLasagnaTarget()
	if not SERVER then return end
	
	-- Reset previous target's model
	if IsValid(self.LasagnaTarget) and self.LasagnaTarget.IsLasagnaTarget then
		self.LasagnaTarget.IsLasagnaTarget = false
		self.LasagnaTarget.OriginalModel = self.LasagnaTarget.OriginalModel or "models/player/Group01/male_02.mdl"
		self.LasagnaTarget:SetModel(self.LasagnaTarget.OriginalModel)
	end
	
	local possibleTargets = {}
	for _, ply in pairs(player.GetAll()) do
					if IsValid(ply) and ply:Alive() and (ply:GTeam() != TEAM_SCP or ply:GetNClass() == ROLES.ROLE_SCP035) and ply:GTeam() != TEAM_SPEC then
			table.insert(possibleTargets, ply)
		end
	end
	
	if #possibleTargets > 0 then
		local target = possibleTargets[math.random(#possibleTargets)]
		
		-- Store original model before changing
		target.OriginalModel = target:GetModel()
		
		self.LasagnaTarget = target
		
		-- Change target's model
		target:SetModel("models/cktheamazingfrog/player/lasagna/lasagna.mdl")
		target.IsLasagnaTarget = true
	end
end

function SWEP:ClawAttack()
	if not SERVER then return end
	
	-- Simple trace for claw attack
	local tr = util.TraceHull({
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.HitDistance,
		filter = self.Owner,
		mins = Vector(-16, -16, -16),
		maxs = Vector(16, 16, 16),
		mask = MASK_SHOT_HULL
	})
	

	
	-- Deal damage if we hit something
	if tr.Hit and IsValid(tr.Entity) and (tr.Entity:IsPlayer() or tr.Entity:IsNPC() or tr.Entity:Health() > 0) then
		-- Don't attack other SCPs
		if tr.Entity:IsPlayer() and tr.Entity:GTeam() == TEAM_SCP then
			return
		end
		local damage = 50
		local isLasagnaTarget = tr.Entity:IsPlayer() and tr.Entity == self.LasagnaTarget and tr.Entity.IsLasagnaTarget
		
		-- Double damage to lasagna target
		if isLasagnaTarget then
			damage = 100
		end
		
		-- Check if this will kill the lasagna target
		if isLasagnaTarget and tr.Entity:Health() <= damage then
			-- Grant bonuses to SCP-3166: +500 HP and +25% speed
			self.Owner:SetHealth(math.min(self.Owner:GetMaxHealth(), self.Owner:Health() + 500))
			
			-- Speed boost +25%
			local currentWalk = self.Owner:GetWalkSpeed()
			local currentRun = self.Owner:GetRunSpeed()
			self.Owner:SetWalkSpeed(currentWalk * 1.25)
			self.Owner:SetRunSpeed(currentRun * 1.25)
			
			-- Reset target model and flag
			tr.Entity.IsLasagnaTarget = false
			if tr.Entity.OriginalModel then
				tr.Entity:SetModel(tr.Entity.OriginalModel)
			end
			self.LasagnaTarget = nil
			

			
			-- Give bonus EXP
			self.Owner:AddExp(500, true)
			
			-- Select new lasagna target after killing current one
			timer.Simple(1, function()
				if IsValid(self) and IsValid(self.Owner) then
					self:SelectLasagnaTarget()
				end
			end)
		end
		
		-- Create damage
		local dmginfo = DamageInfo()
		dmginfo:SetDamage(damage)
		dmginfo:SetAttacker(self.Owner)
		dmginfo:SetInflictor(self)
		dmginfo:SetDamageType(DMG_SLASH)
		dmginfo:SetDamageForce(self.Owner:GetAimVector() * 1000)
		tr.Entity:TakeDamageInfo(dmginfo)
		
		-- Give normal EXP
		if tr.Entity:IsPlayer() then
			self.Owner:AddExp(100, true)
		end
	end
end

function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextAttack > CurTime() then return end
	
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self:SetNextPrimaryFire(CurTime() + self.AttackDelay)
	self:SetNextSecondaryFire(CurTime() + self.AttackDelay)
	
	self:ClawAttack()
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	
	self.NextAttack = CurTime() + self.AttackDelay
end

function SWEP:SecondaryAttack()
	-- Manual target selection (only if no current target)
	if SERVER and not IsValid(self.LasagnaTarget) then
		self:SelectLasagnaTarget()
	end
end

function SWEP:Reload()
	-- Garfield taunt
	if CurTime() < (self.TauntCooldown or 0) then return end
	

	
	self.TauntCooldown = CurTime() + 10
end

function SWEP:Think()
	-- Sync cooldown with client
	if SERVER then
		self:SetNWFloat("NextAttack", self.NextAttack)
		
		-- Force lasagna model on target (check every 0.5 seconds)
		self.NextModelCheck = self.NextModelCheck or 0
		if self.NextModelCheck <= CurTime() then
			self.NextModelCheck = CurTime() + 0.5
			
			if IsValid(self.LasagnaTarget) and self.LasagnaTarget:Alive() and self.LasagnaTarget.IsLasagnaTarget then
				local correctModel = "models/cktheamazingfrog/player/lasagna/lasagna.mdl"
				if self.LasagnaTarget:GetModel() != correctModel then
					self.LasagnaTarget:SetModel(correctModel)
				end
			end
		end
	end
end

function SWEP:Holster()
	return true
end

function SWEP:OnRemove()
	return true
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
		local titleW, titleH = surface.GetTextSize("SCP-3166")
		surface.SetTextPos(centerX - titleW / 2, hudY + 10)
		surface.DrawText("SCP-3166")
		

		
		-- Cooldowny
		local cooldownY = hudY + 60
		local barWidth = 140
		local barHeight = 8
		local spacing = 20
		local totalWidth = barWidth -- Tylko 1 pasek
		local startX = centerX - totalWidth / 2
		
		-- LMB - Claw Attack
		local lmbBarX = startX
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		surface.SetTextPos(lmbBarX, cooldownY - 15)
		surface.DrawText("LMB - Claw Attack")
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
		
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
		
		local attackCooldown = math.max(0, self:GetNWFloat("NextAttack", 0) - CurTime())
		
		if attackCooldown > 0 then
			local progress = 1 - (attackCooldown / self.AttackDelay)
			surface.SetDrawColor(255, 165, 0, 255) -- Orange dla Garfielda
			surface.DrawRect(lmbBarX, cooldownY, barWidth * progress, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(255, 200, 150, 255)
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
		

		
		-- Celownik
		local x = ScrW() / 2.0
		local y = ScrH() / 2.0
		
		local scale = 0.3
		local color = Color(255, 165, 0, 255) -- Orange dla Garfielda
		surface.SetDrawColor(color)
		
		local gap = 5
		local length = gap + 20 * scale
		surface.DrawLine(x - length, y, x - gap, y)
		surface.DrawLine(x + length, y, x + gap, y)
		surface.DrawLine(x, y - length, x, y - gap)
		surface.DrawLine(x, y + length, x, y + gap)
	end

end 