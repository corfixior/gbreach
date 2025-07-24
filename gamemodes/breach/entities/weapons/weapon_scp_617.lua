AddCSLuaFile()

SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-617"

SWEP.HoldType = "normal"

-- SCP-617 Configuration
SWEP.TouchRange = 20
SWEP.StoneDuration = 4 -- Seconds before crumbling
SWEP.CheckDelay = 0.1 -- How often to check for nearby players

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID("breach/wep_617")
end

-- Clean up stone effects when player dies
if SERVER then
	hook.Add("PlayerDeath", "SCP617_CleanupStone", function(victim, inflictor, attacker)
		if IsValid(victim) and victim.IsBeingStoned then
			victim:Freeze(false)
			if victim.OriginalMaterial then
				victim:SetMaterial(victim.OriginalMaterial)
			else
				victim:SetMaterial("")
			end
			victim.IsBeingStoned = false
			victim.StoneEndTime = nil
			victim.OriginalMaterial = nil
			timer.Remove("SCP617_Stone_" .. victim:SteamID64())
		end
	end)
end

function SWEP:Initialize()
	self:InitializeLanguage("SCP_617")
	self:SetHoldType(self.HoldType)
	
	self.NextCheck = 0
end

function SWEP:PrimaryAttack()
	-- No primary attack
end

function SWEP:SecondaryAttack()
	-- No secondary attack
end

function SWEP:Reload()
	-- No reload
end

function SWEP:Think()
	if SERVER then
		-- Check for players touching SCP-617
		if self.NextCheck <= CurTime() then
			self.NextCheck = CurTime() + self.CheckDelay
			self:CheckForTouch()
		end
		
		-- Clean up any expired stone effects
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply.IsBeingStoned and ply.StoneEndTime then
				if ply.StoneEndTime <= CurTime() then
					self:CrumblePlayer(ply)
				end
			end
		end
	end
end

function SWEP:CheckForTouch()
	if not SERVER then return end
	if not IsValid(self.Owner) then return end
	
	-- Find all players near SCP-617
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and ply != self.Owner and ply:Alive() then
			if (ply:GTeam() != TEAM_SCP or ply:GetNClass() == ROLES.ROLE_SCP035) and ply:GTeam() != TEAM_SPEC then
				local dist = ply:GetPos():Distance(self.Owner:GetPos())
				if dist <= self.TouchRange then
					-- Don't affect already stoned players
					if not ply.IsBeingStoned then
						self:StonePlayer(ply)
					end
				end
			end
		end
	end
end

function SWEP:StonePlayer(target)
	if not SERVER then return end
	if not IsValid(target) then return end
	
	-- Mark as being stoned
	target.IsBeingStoned = true
	target.StoneEndTime = CurTime() + self.StoneDuration
	
	-- Store original material
	target.OriginalMaterial = target:GetMaterial()
	
	-- Apply stone material
	target:SetMaterial("models/props_wasteland/rockcliff02b")
	
	-- Freeze the player
	target:Freeze(true)
	
	-- Create timer for crumbling
	timer.Create("SCP617_Stone_" .. target:SteamID64(), self.StoneDuration, 1, function()
		if IsValid(target) and target.IsBeingStoned then
			self:CrumblePlayer(target)
		end
	end)
	
	-- Sound effect
	target:EmitSound("physics/concrete/concrete_break" .. math.random(2,3) .. ".wav", 75, 100)
	
	-- Message to player
	target:PrintMessage(HUD_PRINTCENTER, "You are turning to stone!")
	
	-- Give EXP to SCP
	if IsValid(self.Owner) then
		self.Owner:AddExp(150, true)
	end
end

function SWEP:CrumblePlayer(target)
	if not SERVER then return end
	if not IsValid(target) then return end
	
	local pos = target:GetPos()
	local ang = target:GetAngles()
	
	-- No visual effects - just stone crumbling sounds
	
	-- Crumbling sound
	target:EmitSound("physics/concrete/concrete_break" .. math.random(2,3) .. ".wav", 85, 80)
	target:EmitSound("ambient/materials/rock" .. math.random(1,5) .. ".wav", 80, 90)
	
	-- Clean up BEFORE killing player
	target.IsBeingStoned = false
	target.StoneEndTime = nil
	target:Freeze(false)
	if target.OriginalMaterial then
		target:SetMaterial(target.OriginalMaterial)
	else
		target:SetMaterial("")
	end
	target.OriginalMaterial = nil
	
	-- Kill the player
	local dmginfo = DamageInfo()
	dmginfo:SetDamage(target:Health() + 100)
	dmginfo:SetAttacker(self.Owner)
	dmginfo:SetInflictor(self)
	dmginfo:SetDamageType(DMG_CRUSH)
	target:TakeDamageInfo(dmginfo)
	
	-- Give bonus EXP for successful kill
	if IsValid(self.Owner) then
		self.Owner:AddExp(200, true)
	end
end

function SWEP:Holster()
	return true
end

function SWEP:OnRemove()
	-- Clean up any ongoing stone effects
	if SERVER then
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply.IsBeingStoned then
				ply:Freeze(false)
				if ply.OriginalMaterial then
					ply:SetMaterial(ply.OriginalMaterial)
				else
					ply:SetMaterial("")
				end
				ply.IsBeingStoned = false
				ply.StoneEndTime = nil
				ply.OriginalMaterial = nil
				timer.Remove("SCP617_Stone_" .. ply:SteamID64())
			end
		end
	end
	return true
end

if CLIENT then
	function SWEP:DrawHUD()
		-- No HUD needed - SCP-617 is fully passive
		return
	end
end 