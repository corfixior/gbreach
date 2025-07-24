AddCSLuaFile()

SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-939"

-- Primary attack settings
SWEP.Primary.Delay = 1.0
SWEP.BiteDamage = 30
SWEP.BiteRange = 100

-- Secondary attack settings  
SWEP.TrackingCooldown = 30
SWEP.TrackingDuration = 1.0
SWEP.TrackingRange = 4000
SWEP.DamageBonus = 0.2
SWEP.BonusDuration = 5

-- Bleed settings
SWEP.BleedDamage = 5
SWEP.BleedDuration = 3
SWEP.BleedTickRate = 1

-- Motion vision settings
SWEP.MotionThreshold = 8
SWEP.FadeSpeed = 0.08

SWEP.DrawCrosshair = true
SWEP.HoldType = ""

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 0, "NextPrimary")
	self:NetworkVar("Float", 1, "NextTracking")
	self:NetworkVar("Float", 2, "DamageBonusEndTime")
	self:NetworkVar("Float", 3, "NextVoiceToggle") -- Cooldown dla R
	self:NetworkVar("Bool", 0, "IsTracking")
	self:NetworkVar("Bool", 1, "VoiceChatAll") -- false = SCP only, true = all
end

function SWEP:Initialize()
	self:InitializeLanguage("SCP_939")
	self:SetHoldType(self.HoldType)
	
	-- Initialize cooldowns
	self:SetNextPrimary(0)
	self:SetNextTracking(0)
	self:SetDamageBonusEndTime(0)
	self:SetNextVoiceToggle(0)
	self:SetIsTracking(false)
	self:SetVoiceChatAll(false) -- Start with SCP only
	
	if SERVER then
		self.BiteCounter = {}
		self.BleedingPlayers = {}
		self.PlayerOutlines = {}
		self.LastPlayerPositions = {}
		self.PlayerVisibility = {}
		
		-- Set up network strings
		util.AddNetworkString("SCP939_UpdateVision")
		util.AddNetworkString("SCP939_ClearVision")
		util.AddNetworkString("SCP939_ShowOutline")
		util.AddNetworkString("SCP939_ClearOutlines")
		util.AddNetworkString("SCP939_BloodSpot")
		util.AddNetworkString("SCP939_ActionSpot")
	end
	
	if CLIENT then
		self.PlayerVisibilityData = {}
		self.LastBleedApplication = 0
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

function SWEP:ViewModelDrawn()
	-- Nic nie rób
end

function SWEP:GetViewModelPosition(pos, ang)
	return pos, ang
end

SWEP.ShowViewModel = false
SWEP.ShowWorldModel = false

function SWEP:Deploy()
	if SERVER then
		self:StartMotionVision()
		self:StartHealthRegeneration()
		-- self:StartVoiceLines() -- Wyłączone dźwięki ludzkie
		self:StartMaxHPCheck()
		
		local owner = self:GetOwner()
		if IsValid(owner) then
			local currentMaxHP = owner:GetNWInt("SCP939_MaxHP", 0)
			if currentMaxHP == 0 or currentMaxHP < owner:Health() then
				owner:SetNWInt("SCP939_MaxHP", owner:Health())
			end
		end
	end
	return true
end

function SWEP:Holster()
	if SERVER then
		self:StopMotionVision()
		self:ClearPlayerOutlines()
		self:StopHealthRegeneration()
		-- self:StopVoiceLines() -- Wyłączone dźwięki ludzkie
		self:StopMaxHPCheck()
	end
	return true
end

function SWEP:OnRemove()
	if SERVER then
		self:StopMotionVision()
		self:ClearPlayerOutlines()
		self:StopHealthRegeneration()
		-- self:StopVoiceLines() -- Wyłączone dźwięki ludzkie
		self:StopMaxHPCheck()
		
		-- Clean up bleed timers
		if self.BleedingPlayers then
			for steamid, _ in pairs(self.BleedingPlayers) do
				timer.Remove("SCP939_Bleed_" .. steamid)
			end
		end
		
		-- Remove hooks
		local entIndex = self:EntIndex()
		hook.Remove("EntityFireBullets", "SCP939_DetectShooting_" .. entIndex)
		hook.Remove("PlayerStartVoice", "SCP939_DetectVoice_" .. entIndex)
	end
end

-- LMB - Bite attack
function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self:GetNextPrimary() > CurTime() then return end
	
	self:SetNextPrimary(CurTime() + self.Primary.Delay)
	
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
	self:EmitSound("939lmb.wav", 75, 100)
	owner:SetAnimation(PLAYER_ATTACK1)
	
	if SERVER then
		local trace = util.TraceLine({
			start = owner:GetShootPos(),
			endpos = owner:GetShootPos() + owner:GetAimVector() * self.BiteRange,
			filter = owner
		})
		
		if trace.Hit and IsValid(trace.Entity) then
			if trace.Entity:IsPlayer() then
				local target = trace.Entity
				if target:GTeam() == TEAM_SPEC or (target:GTeam() == TEAM_SCP and target:GetNClass() != ROLES.ROLE_SCP035) then return end
				
				local damage = self.BiteDamage
				
				-- Apply damage bonus if active
				if CurTime() < self:GetDamageBonusEndTime() then
					damage = damage * (1 + self.DamageBonus)
					
					local effectdata = EffectData()
					effectdata:SetOrigin(trace.HitPos)
					effectdata:SetNormal(trace.HitNormal)
					effectdata:SetScale(1.5)
					util.Effect("cball_explode", effectdata)
				end
				
				target:TakeDamage(damage, owner, self)
				
				-- Blood effect
				local effectdata = EffectData()
				effectdata:SetOrigin(trace.HitPos)
				effectdata:SetNormal(trace.HitNormal)
				effectdata:SetEntity(target)
				util.Effect("BloodImpact", effectdata)
				
				-- Track bite counter for bleeding
				local steamid = target:SteamID()
				self.BiteCounter[steamid] = (self.BiteCounter[steamid] or 0) + 1
				
				if self.BiteCounter[steamid] >= 3 then
					self:ApplyBleeding(target)
					self.BiteCounter[steamid] = 0
					-- Set flag for crosshair highlight
					self.LastBleedApplication = CurTime()
				end
			elseif trace.Entity:GetClass():find("func_breakable") then
				-- Możliwość wybijania szyb
				trace.Entity:TakeDamage(100, owner, self)
				-- Usunięto dźwięk rozbijania szyby
			end
		end
	end
end

-- RMB - Tracking ability
function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self:GetNextTracking() > CurTime() then return end
	
	self:SetNextTracking(CurTime() + self.TrackingCooldown)
	self:SetIsTracking(true)
	
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
	self:EmitSound("939rmb.wav", 75, 100)
	
	if SERVER then
		owner:Freeze(true)
		
		local foundPlayers = self:ShowPlayerOutlines(owner)
		
		-- Visual effect
		local effectdata = EffectData()
		effectdata:SetOrigin(owner:GetPos() + Vector(0, 0, 50))
		effectdata:SetRadius(300)
		effectdata:SetMagnitude(2)
		util.Effect("ThumperDust", effectdata)
		
		timer.Simple(self.TrackingDuration, function()
			if IsValid(self) and IsValid(owner) then
				owner:Freeze(false)
				self:SetIsTracking(false)
				
				if foundPlayers > 0 then
					self:SetDamageBonusEndTime(CurTime() + self.BonusDuration)
				end
			end
		end)
	end
end

-- R - Toggle voice chat mode
function SWEP:Reload()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
	-- Sprawdź cooldown
	if self:GetNextVoiceToggle() > CurTime() then return end
	
	-- Ustaw cooldown 1 sekunda
	self:SetNextVoiceToggle(CurTime() + 1)
	
	-- Toggle voice chat mode
	self:SetVoiceChatAll(not self:GetVoiceChatAll())
	
	-- Sound feedback - usunieto dzwiek
	-- owner:EmitSound("buttons/button14.wav", 65, 100)
end

function SWEP:ApplyBleeding(target)
	if not SERVER or not IsValid(target) then return end
	
	local steamid = target:SteamID()
	
	if self.BleedingPlayers[steamid] then return end
	
	self.BleedingPlayers[steamid] = true
	
	local bleedCount = 0
	timer.Create("SCP939_Bleed_" .. steamid, self.BleedTickRate, self.BleedDuration, function()
		if IsValid(target) and IsValid(self) and target:Alive() then
			target:TakeDamage(self.BleedDamage, self:GetOwner(), self)
			
			-- Blood effect
			local effectdata = EffectData()
			effectdata:SetOrigin(target:GetPos() + Vector(math.random(-20, 20), math.random(-20, 20), 40))
			effectdata:SetNormal(Vector(0, 0, -1))
			util.Effect("bloodspray", effectdata)
			
			target:EmitSound("player/pl_pain" .. math.random(5, 7) .. ".wav", 60, math.random(90, 110))
			
			bleedCount = bleedCount + 1
			if bleedCount >= self.BleedDuration then
				self.BleedingPlayers[steamid] = nil
			end
		else
			timer.Remove("SCP939_Bleed_" .. steamid)
			if self.BleedingPlayers then
				self.BleedingPlayers[steamid] = nil
			end
		end
	end)
end

function SWEP:ShowPlayerOutlines(owner)
	if not SERVER or not IsValid(owner) then return 0 end
	
	self:ClearPlayerOutlines()
	
	local foundPlayers = 0
	
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and ply != owner and ply:Alive() then
			if ply:GTeam() != TEAM_SPEC and ply:GTeam() != TEAM_SCP then
				local distance = owner:GetPos():Distance(ply:GetPos())
				if distance <= self.TrackingRange then
					foundPlayers = foundPlayers + 1
					
					self.PlayerOutlines[ply:EntIndex()] = {
						pos = ply:GetPos(),
						endTime = CurTime() + 6
					}
					
					net.Start("SCP939_ShowOutline")
					net.WriteEntity(ply)
					net.WriteVector(ply:GetPos())
					net.WriteFloat(6)
					net.Send(owner)
				end
			end
		end
	end
	
	return foundPlayers
end

function SWEP:ClearPlayerOutlines()
	if not SERVER then return end
	
	local owner = self:GetOwner()
	if IsValid(owner) then
		net.Start("SCP939_ClearOutlines")
		net.Send(owner)
	end
	
	self.PlayerOutlines = {}
end

function SWEP:StartMotionVision()
	if not SERVER then return end
	
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
	-- Initialize player positions
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and ply != owner then
			self.LastPlayerPositions[ply] = ply:GetPos()
			self.PlayerVisibility[ply] = 1
		end
	end
	
	-- Set up detection hooks
	local entIndex = self:EntIndex()
	
	hook.Add("EntityFireBullets", "SCP939_DetectShooting_" .. entIndex, function(entity, data)
		if IsValid(entity) and entity:IsPlayer() and IsValid(self) and IsValid(self:GetOwner()) then
			-- Nie pokazuj wykrzykników dla SCP i SPEC
			if entity:GTeam() != TEAM_SCP and entity:GTeam() != TEAM_SPEC then
				self:CreateActionSpot(entity, "shooting")
			end
		end
	end)
	
	hook.Add("PlayerStartVoice", "SCP939_DetectVoice_" .. entIndex, function(ply)
		if IsValid(ply) and IsValid(self) and IsValid(self:GetOwner()) then
			-- Nie pokazuj wykrzykników dla SCP i SPEC
			if ply:GTeam() != TEAM_SCP and ply:GTeam() != TEAM_SPEC then
				self:CreateActionSpot(ply, "voice")
			end
		end
	end)
	
	-- Start vision update timer
	local steamID = owner:SteamID()
	timer.Create("SCP939_MotionVision_" .. steamID, 0.1, 0, function()
		if IsValid(self) and IsValid(owner) then
			self:UpdateMotionVision()
		else
			timer.Remove("SCP939_MotionVision_" .. steamID)
		end
	end)
end

function SWEP:StopMotionVision()
	if not SERVER then return end
	
	local owner = self:GetOwner()
	if IsValid(owner) then
		timer.Remove("SCP939_MotionVision_" .. owner:SteamID())
		
		net.Start("SCP939_ClearVision")
		net.Send(owner)
	end
	
	self.LastPlayerPositions = {}
	self.PlayerVisibility = {}
end

function SWEP:UpdateMotionVision()
	if not SERVER then return end
	
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
	local visibilityData = {}
	
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and ply != owner and ply:Alive() then
			if ply:GTeam() != TEAM_SPEC and ply:GTeam() != TEAM_SCP then
				local currentPos = ply:GetPos()
				local lastPos = self.LastPlayerPositions[ply] or currentPos
				local movement = currentPos:Distance(lastPos)
				
				if movement > self.MotionThreshold then
					-- Player is moving - fully visible
					self.PlayerVisibility[ply] = 1
					visibilityData[ply:EntIndex()] = {visible = true, alpha = 255, glow = true}
				else
					-- Player is still - fade out
					self.PlayerVisibility[ply] = math.max(0, (self.PlayerVisibility[ply] or 1) - self.FadeSpeed)
					
					if self.PlayerVisibility[ply] <= 0 then
						visibilityData[ply:EntIndex()] = {visible = false, alpha = 0, glow = false}
					else
						local alpha = math.floor(255 * self.PlayerVisibility[ply])
						visibilityData[ply:EntIndex()] = {visible = true, alpha = alpha, glow = false}
					end
				end
				
				self.LastPlayerPositions[ply] = currentPos
			end
		end
	end
	
	net.Start("SCP939_UpdateVision")
	net.WriteTable(visibilityData)
	net.Send(owner)
end

function SWEP:CreateActionSpot(ply, actionType)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return end
	
	-- Find all SCP-939 players
	for _, scp939Player in pairs(player.GetAll()) do
		if IsValid(scp939Player) and scp939Player:Alive() and scp939Player != ply then
			local wep = scp939Player:GetActiveWeapon()
			if IsValid(wep) and wep:GetClass() == "weapon_scp_939" then
				local distance = scp939Player:GetPos():Distance(ply:GetPos())
				
				if distance <= 8000 then
					net.Start("SCP939_ActionSpot")
					net.WriteVector(ply:GetPos() + Vector(0, 0, 40))
					net.WriteString(actionType)
					net.WriteString(ply:SteamID())
					net.WriteFloat(0.5)
					net.Send(scp939Player)
				end
			end
		end
	end
end

function SWEP:StartHealthRegeneration()
	if not SERVER then return end
	
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
	timer.Create("SCP939_HealthRegen_" .. owner:SteamID(), 2, 0, function()
		if IsValid(self) and IsValid(owner) and owner:Alive() then
			local currentHealth = owner:Health()
			local maxHealth = owner:GetNWInt("SCP939_MaxHP", currentHealth)
			
			if currentHealth < (maxHealth * 0.5) and currentHealth > 0 then
				local newHealth = math.min(maxHealth, currentHealth + 2)
				owner:SetHealth(newHealth)
			end
		else
			timer.Remove("SCP939_HealthRegen_" .. (IsValid(owner) and owner:SteamID() or "unknown"))
		end
	end)
end

function SWEP:StopHealthRegeneration()
	if not SERVER then return end
	
	local owner = self:GetOwner()
	if IsValid(owner) then
		timer.Remove("SCP939_HealthRegen_" .. owner:SteamID())
	end
end

-- Funkcje voice lines wyłączone - SCP-939 nie emituje ludzkich dźwięków
--[[
function SWEP:StartVoiceLines()
	if not SERVER then return end
	
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
	timer.Create("SCP939_VoiceLines_" .. owner:SteamID(), 30, 0, function()
		if IsValid(self) and IsValid(owner) and owner:Alive() then
			local voiceLines = {
				"vo/npc/male01/help01.wav",
				"vo/npc/male01/question06.wav",
				"vo/npc/male01/question11.wav",
				"vo/npc/male01/question17.wav",
				"vo/npc/male01/question22.wav",
				"vo/npc/male01/question27.wav",
				"vo/npc/female01/help01.wav",
				"vo/npc/female01/question06.wav",
				"vo/npc/female01/question11.wav",
				"vo/npc/female01/question17.wav",
				"vo/npc/female01/question22.wav",
				"vo/npc/female01/question27.wav"
			}
			
			local randomVoice = voiceLines[math.random(1, #voiceLines)]
			owner:EmitSound(randomVoice, 75, math.random(90, 110))
		else
			timer.Remove("SCP939_VoiceLines_" .. (IsValid(owner) and owner:SteamID() or "unknown"))
		end
	end)
end

function SWEP:StopVoiceLines()
	if not SERVER then return end
	
	local owner = self:GetOwner()
	if IsValid(owner) then
		timer.Remove("SCP939_VoiceLines_" .. owner:SteamID())
	end
end
--]]

function SWEP:StartMaxHPCheck()
	if not SERVER then return end
	
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
	timer.Create("SCP939_MaxHPCheck_" .. owner:SteamID(), 1, 0, function()
		if IsValid(self) and IsValid(owner) and owner:Alive() then
			local currentHP = owner:Health()
			local savedMaxHP = owner:GetNWInt("SCP939_MaxHP", 0)
			
			if currentHP > savedMaxHP then
				owner:SetNWInt("SCP939_MaxHP", currentHP)
			end
		else
			timer.Remove("SCP939_MaxHPCheck_" .. (IsValid(owner) and owner:SteamID() or "unknown"))
		end
	end)
end

function SWEP:StopMaxHPCheck()
	if not SERVER then return end
	
	local owner = self:GetOwner()
	if IsValid(owner) then
		timer.Remove("SCP939_MaxHPCheck_" .. owner:SteamID())
	end
end

function SWEP:DrawHUD()
	if disablehud == true then return end
	if self.Owner:Team() == TEAM_SPEC then return end
	
	self:DrawSCPHUD()
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
	
	-- Background
	surface.SetDrawColor(20, 20, 20, 180)
	surface.DrawRect(hudX, hudY, hudWidth, hudHeight)
	
	-- Border
	surface.SetDrawColor(100, 100, 100, 200)
	surface.DrawOutlinedRect(hudX, hudY, hudWidth, hudHeight)
	
	-- Decorative line
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawRect(hudX + 10, hudY + 5, hudWidth - 20, 2)
	
	-- Title
	surface.SetFont("DermaLarge")
	surface.SetTextColor(200, 200, 200, 255)
	local titleW, titleH = surface.GetTextSize("SCP-939")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-939")
	
	-- Status
	local statusText = ""
	local statusColor = Color(200, 200, 200, 255)
	
	if self:GetIsTracking() then
		statusText = "TRACKING..."
		statusColor = Color(255, 150, 0, 255)
	else
		-- Show voice chat mode
		local vcMode = self:GetVoiceChatAll() and "Voice: ALL" or "Voice: SCP"
		statusText = vcMode .. " [R]"
		statusColor = self:GetVoiceChatAll() and Color(100, 255, 100, 255) or Color(255, 255, 100, 255)
	end
	
	if statusText != "" then
		surface.SetFont("DermaDefaultBold")
		surface.SetTextColor(statusColor.r, statusColor.g, statusColor.b, 255)
		local statusW, statusH = surface.GetTextSize(statusText)
		surface.SetTextPos(centerX - statusW / 2, hudY + 95)
		surface.DrawText(statusText)
	end
	
	-- Cooldowns
	local cooldownY = hudY + 60
	local barWidth = 230
	local barHeight = 8
	local spacing = 20
	local totalWidth = barWidth * 2 + spacing
	local startX = centerX - totalWidth / 2
	
	-- LMB Cooldown (Bite)
	local lmbBarX = startX
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(lmbBarX, cooldownY - 15)
	surface.DrawText("LMB - Bite")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
	
	local attackCooldown = 0
	local nextAttack = self:GetNextPrimary()
	if nextAttack > CurTime() then
		attackCooldown = nextAttack - CurTime()
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
	
	-- RMB Cooldown (Tracking)
	local rmbBarX = startX + barWidth + spacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rmbBarX, cooldownY - 15)
	surface.DrawText("RMB - Detect")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
	
	local trackingCooldown = 0
	local nextTracking = self:GetNextTracking()
	if nextTracking > CurTime() and !self:GetIsTracking() then
		trackingCooldown = nextTracking - CurTime()
	end
	
	if self:GetIsTracking() then
		surface.SetDrawColor(255, 150, 0, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 200, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText("ACTIVE")
	elseif trackingCooldown > 0 then
		local progress = 1 - (trackingCooldown / self.TrackingCooldown)
		surface.SetDrawColor(255, 150, 0, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 200, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", trackingCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- Celownik
	local x = ScrW() / 2.0
	local y = ScrH() / 2.0
	
	local scale = 0.3
	-- Efekt na celowniku podczas damage boost
	if CurTime() < self:GetDamageBonusEndTime() then
		-- Pulsujący żółty celownik podczas damage boost
		local pulse = math.sin(CurTime() * 8) * 0.5 + 0.5
		surface.SetDrawColor(255, 200 + pulse * 55, 0, 255)
		scale = 0.3 + pulse * 0.1
	elseif CLIENT and self.LastBleedApplication and CurTime() - self.LastBleedApplication < 1 then
		-- Czerwony gdy aplikuje krwawienie
		surface.SetDrawColor(255, 0, 0, 255)
	else
		surface.SetDrawColor(200, 200, 200, 255)
	end
	
	local gap = 5
	local length = gap + 20 * scale
	surface.DrawLine( x - length, y, x - gap, y )
	surface.DrawLine( x + length, y, x + gap, y )
	surface.DrawLine( x, y - length, x, y - gap )
	surface.DrawLine( x, y + length, x, y + gap )
	
	-- Dodatkowy efekt podczas damage boost
	if CurTime() < self:GetDamageBonusEndTime() then
		local timeLeft = self:GetDamageBonusEndTime() - CurTime()
		local alpha = math.min(255, timeLeft * 100)
		surface.SetDrawColor(255, 200, 0, alpha)
		local extraGap = gap + 10
		local extraLength = extraGap + 25 * scale
		surface.DrawLine( x - extraLength, y, x - extraGap, y )
		surface.DrawLine( x + extraLength, y, x + extraGap, y )
		surface.DrawLine( x, y - extraLength, x, y - extraGap )
		surface.DrawLine( x, y + extraLength, x, y + extraGap )
	end
end

-- Client-side hooks and rendering
if CLIENT then
	local playerOutlines = {}
	local bloodSpots = {}
	local actionSpots = {}
	
	-- Motion vision rendering
	hook.Add("PrePlayerDraw", "SCP939_PlayerVisibility", function(ply)
		local localPly = LocalPlayer()
		if not IsValid(localPly) then return end
		
		local wep = localPly:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() != "weapon_scp_939" then return end
		
		if wep.PlayerVisibilityData and wep.PlayerVisibilityData[ply:EntIndex()] then
			local data = wep.PlayerVisibilityData[ply:EntIndex()]
			if not data.visible or data.alpha <= 0 then
				return true
			elseif data.glow then
				ply:SetRenderMode(RENDERMODE_NORMAL)
				ply:SetColor(Color(255, 255, 255, 255))
			elseif data.alpha < 255 then
				ply:SetRenderMode(RENDERMODE_TRANSALPHA)
				ply:SetColor(Color(255, 255, 255, data.alpha))
			else
				ply:SetRenderMode(RENDERMODE_NORMAL)
				ply:SetColor(Color(255, 255, 255, 255))
			end
		else
			ply:SetRenderMode(RENDERMODE_NORMAL)
			ply:SetColor(Color(255, 255, 255, 255))
		end
	end)
	
	-- Renderuj efekt świecenia dla ruszających się graczy (tylko gdy widoczni)
	hook.Add("PostDrawTranslucentRenderables", "SCP939_MotionGlow", function()
		local localPly = LocalPlayer()
		if not IsValid(localPly) then return end
		
		local wep = localPly:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() != "weapon_scp_939" then return end
		
		if not wep.PlayerVisibilityData then return end
		
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply != localPly and ply:Alive() then
				local data = wep.PlayerVisibilityData[ply:EntIndex()]
				if data and data.visible and data.glow then
					-- Sprawdź czy gracz jest widoczny (nie za ścianą)
					local trace = util.TraceLine({
						start = localPly:EyePos(),
						endpos = ply:EyePos(),
						filter = {localPly, ply}
					})
					
					if not trace.Hit then
						-- Gracz jest widoczny - renderuj z efektem świecenia
						render.SuppressEngineLighting(true)
						render.SetColorModulation(1, 0.8, 0.8)
						render.SetBlend(0.9)
						render.MaterialOverride(Material("models/debug/debugwhite"))
						
						ply:DrawModel()
						
						-- Dodatkowy obrys
						local mat = Matrix()
						mat:Scale(Vector(1.02, 1.02, 1.02))
						ply:EnableMatrix("RenderMultiply", mat)
						
						render.SetColorModulation(1, 0.5, 0.5)
						render.SetBlend(0.6)
						ply:DrawModel()
						
						ply:DisableMatrix("RenderMultiply")
						
						-- Przywróć ustawienia
						render.MaterialOverride()
						render.SetColorModulation(1, 1, 1)
						render.SetBlend(1)
						render.SuppressEngineLighting(false)
					end
				end
			end
		end
	end)
	
	-- Hook do ukrywania nicków niewidocznych graczy
	hook.Add("HUDDrawTargetID", "SCP939_HideInvisibleNames", function()
		local localPly = LocalPlayer()
		if not IsValid(localPly) then return end
		
		local wep = localPly:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() != "weapon_scp_939" then return end
		
		local trace = localPly:GetEyeTrace()
		if not IsValid(trace.Entity) or not trace.Entity:IsPlayer() then return end
		
		-- Sprawdź czy gracz jest widoczny w motion vision
		if wep.PlayerVisibilityData and wep.PlayerVisibilityData[trace.Entity:EntIndex()] then
			local data = wep.PlayerVisibilityData[trace.Entity:EntIndex()]
			if not data.visible or data.alpha <= 0 then
				return false -- Ukryj nick
			end
		end
	end)
	
	-- Network receivers
	net.Receive("SCP939_UpdateVision", function()
		local localPly = LocalPlayer()
		if not IsValid(localPly) then return end
		
		local wep = localPly:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() != "weapon_scp_939" then return end
		
		wep.PlayerVisibilityData = net.ReadTable()
	end)
	
	net.Receive("SCP939_ClearVision", function()
		local localPly = LocalPlayer()
		if not IsValid(localPly) then return end
		
		local wep = localPly:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() != "weapon_scp_939" then return end
		
		wep.PlayerVisibilityData = {}
		
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply != localPly then
				ply:SetRenderMode(RENDERMODE_NORMAL)
				ply:SetColor(Color(255, 255, 255, 255))
			end
		end
	end)
	
	net.Receive("SCP939_ShowOutline", function()
		local ply = net.ReadEntity()
		local pos = net.ReadVector()
		local duration = net.ReadFloat()
		
		if IsValid(ply) then
			playerOutlines[ply:EntIndex()] = {
				player = ply,
				pos = pos,
				endTime = CurTime() + duration,
				followPlayer = true
			}
		end
	end)
	
	net.Receive("SCP939_ClearOutlines", function()
		playerOutlines = {}
	end)
	
	net.Receive("SCP939_BloodSpot", function()
		local pos = net.ReadVector()
		local duration = net.ReadFloat()
		
		table.insert(bloodSpots, {
			pos = pos,
			endTime = CurTime() + duration,
			intensity = 1
		})
	end)
	
	net.Receive("SCP939_ActionSpot", function()
		local pos = net.ReadVector()
		local actionType = net.ReadString()
		local playerSteamID = net.ReadString()
		local extensionTime = net.ReadFloat()
		
		local localPly = LocalPlayer()
		if not IsValid(localPly) then return end
		
		local wep = localPly:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() != "weapon_scp_939" then return end
		
		local foundExisting = false
		for i, spot in ipairs(actionSpots) do
			if spot.playerSteamID == playerSteamID and spot.type == actionType and spot.pos:Distance(pos) < 50 then
				spot.endTime = CurTime() + extensionTime
				spot.pos = pos
				foundExisting = true
				break
			end
		end
		
		if not foundExisting then
			table.insert(actionSpots, {
				pos = pos,
				type = actionType,
				playerSteamID = playerSteamID,
				endTime = CurTime() + extensionTime,
				startTime = CurTime()
			})
		end
	end)
	
	-- Draw outlines
	hook.Add("PostDrawTranslucentRenderables", "SCP939_DrawOutlines", function()
		local localPly = LocalPlayer()
		if not IsValid(localPly) then return end
		
		local wep = localPly:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() != "weapon_scp_939" then return end
		
		render.SetStencilEnable(false)
		render.OverrideDepthEnable(true, false)
		cam.IgnoreZ(true)
		
		for entIndex, data in pairs(playerOutlines) do
			if CurTime() < data.endTime then
				local drawPos = data.pos
				if data.followPlayer and IsValid(data.player) then
					drawPos = data.player:GetPos()
				end
				
				local mins = Vector(-16, -16, 0)
				local maxs = Vector(16, 16, 72)
				
				render.SetColorMaterial()
				render.DrawWireframeBox(drawPos, Angle(0, 0, 0), mins, maxs, Color(255, 100, 100, 255), true)
				
				local pulse = math.sin(CurTime() * 3) * 0.3 + 0.7
				render.DrawWireframeBox(drawPos, Angle(0, 0, 0), mins * pulse, maxs * pulse, Color(255, 150, 150, 200), true)
			else
				playerOutlines[entIndex] = nil
			end
		end
		
		cam.IgnoreZ(false)
		render.OverrideDepthEnable(false)
	end)
	
	-- Draw blood spots
	hook.Add("PostDrawTranslucentRenderables", "SCP939_DrawBloodSpots", function()
		local localPly = LocalPlayer()
		if not IsValid(localPly) then return end
		
		local wep = localPly:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() != "weapon_scp_939" then return end
		
		render.SetStencilEnable(false)
		render.OverrideDepthEnable(true, false)
		cam.IgnoreZ(true)
		
		for i = #bloodSpots, 1, -1 do
			local spot = bloodSpots[i]
			if CurTime() < spot.endTime then
				local timeLeft = spot.endTime - CurTime()
				local alpha = math.min(255, (timeLeft / 5) * 255)
				local pulse = math.sin(CurTime() * 3) * 0.3 + 0.8
				
				render.SetColorMaterial()
				render.DrawSphere(spot.pos, 15 * pulse, 16, 16, Color(255, 50, 50, alpha))
				render.DrawSphere(spot.pos, 8, 12, 12, Color(255, 0, 0, alpha))
			else
				table.remove(bloodSpots, i)
			end
		end
		
		cam.IgnoreZ(false)
		render.OverrideDepthEnable(false)
	end)
	
	-- Draw action spots
	hook.Add("PostDrawTranslucentRenderables", "SCP939_DrawActionSpots", function()
		local localPly = LocalPlayer()
		if not IsValid(localPly) then return end
		
		local wep = localPly:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() != "weapon_scp_939" then return end
		
		render.SetStencilEnable(false)
		render.OverrideDepthEnable(true, false)
		render.SuppressEngineLighting(true)
		cam.IgnoreZ(true)
		
		render.SetColorMaterial()
		
		for i = #actionSpots, 1, -1 do
			local spot = actionSpots[i]
			
			if CurTime() > spot.endTime then
				table.remove(actionSpots, i)
			else
				local color = Color(255, 255, 0, 255) -- yellow
				if spot.type == "shooting" then
					color = Color(255, 150, 0, 255) -- orange
				elseif spot.type == "attack" then
					color = Color(255, 50, 50, 255) -- red
				elseif spot.type == "voice" then
					color = Color(50, 255, 255, 255) -- cyan
				end
				
				local pulse = math.sin(CurTime() * 4) * 0.3 + 0.7
				
				local alpha = 255
				local finalColor = Color(color.r, color.g, color.b, alpha)
				
				local distance = localPly:GetPos():Distance(spot.pos)
				
				local baseSize = 25
				local distanceScale = math.max(1, distance / 1000)
				local size = (baseSize + distanceScale * 10) * pulse
				
				local pos = spot.pos
				
				render.SetColorMaterial()
				render.DrawSphere(pos, size * 0.7, 16, 16, Color(0, 0, 0, alpha * 0.8))
				render.DrawSphere(pos, size * 0.6, 16, 16, finalColor)
				
				-- Exclamation mark
				local lineHeight = size * 0.5
				local lineWidth = size * 0.12
				render.DrawBox(pos + Vector(0, 0, lineHeight * 0.15), Angle(0, 0, 0),
					Vector(-lineWidth/2, -lineWidth/2, -lineHeight/2),
					Vector(lineWidth/2, lineWidth/2, lineHeight/2),
					Color(255, 255, 255, alpha))
				
				local dotSize = size * 0.15
				render.DrawSphere(pos + Vector(0, 0, -size * 0.35), dotSize, 12, 12, Color(255, 255, 255, alpha))
			end
		end
		
		cam.IgnoreZ(false)
		render.OverrideDepthEnable(false)
		render.SuppressEngineLighting(false)
	end)
end

-- Server-side hooks
if SERVER then
	-- Blood detection
	hook.Add("PlayerHurt", "SCP939_BloodDetection", function(victim, attacker, healthRemaining, damageTaken)
		if not IsValid(victim) or not victim:IsPlayer() then return end
		
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply:Alive() and ply != victim then
				local wep = ply:GetActiveWeapon()
				if IsValid(wep) and wep:GetClass() == "weapon_scp_939" then
					local distance = ply:GetPos():Distance(victim:GetPos())
					if distance <= 2500 then
						net.Start("SCP939_BloodSpot")
						net.WriteVector(victim:GetPos() + Vector(0, 0, 20))
						net.WriteFloat(5)
						net.Send(ply)
					end
				end
			end
		end
	end)
	
	-- Attack detection
	if not timer.Exists("SCP939_GlobalAttackCheck") then
		timer.Create("SCP939_GlobalAttackCheck", 0.1, 0, function()
			for _, ply in pairs(player.GetAll()) do
				if IsValid(ply) and ply:Alive() and ply:KeyDown(IN_ATTACK) then
					-- Nie pokazuj wykrzykników dla SCP i SPEC
					if ply:GTeam() != TEAM_SCP and ply:GTeam() != TEAM_SPEC then
						for _, scp939Player in pairs(player.GetAll()) do
							if IsValid(scp939Player) and scp939Player:Alive() and scp939Player != ply then
								local wep = scp939Player:GetActiveWeapon()
								if IsValid(wep) and wep:GetClass() == "weapon_scp_939" then
									local distance = scp939Player:GetPos():Distance(ply:GetPos())
									if distance <= 7000 then
										net.Start("SCP939_ActionSpot")
										net.WriteVector(ply:GetPos() + Vector(0, 0, 40))
										net.WriteString("attack")
										net.WriteString(ply:SteamID())
										net.WriteFloat(0.5)
										net.Send(scp939Player)
									end
								end
							end
						end
					end
				end
			end
		end)
	end
	
	-- Clean up bleeding on death/spawn
	hook.Add("PlayerDeath", "SCP939_ClearBleedOnDeath", function(victim, inflictor, attacker)
		local steamid = victim:SteamID()
		timer.Remove("SCP939_Bleed_" .. steamid)
		
		-- Clean up from all SCP-939 weapons
		for _, ply in pairs(player.GetAll()) do
			local wep = ply:GetActiveWeapon()
			if IsValid(wep) and wep:GetClass() == "weapon_scp_939" then
				if wep.BleedingPlayers then
					wep.BleedingPlayers[steamid] = nil
					wep.BiteCounter[steamid] = nil
				end
			end
		end
	end)
	
	hook.Add("PlayerSpawn", "SCP939_ClearBleedOnSpawn", function(ply)
		local steamid = ply:SteamID()
		timer.Remove("SCP939_Bleed_" .. steamid)
		
		-- Clean up from all SCP-939 weapons
		for _, scp in pairs(player.GetAll()) do
			local wep = scp:GetActiveWeapon()
			if IsValid(wep) and wep:GetClass() == "weapon_scp_939" then
				if wep.BleedingPlayers then
					wep.BleedingPlayers[steamid] = nil
					wep.BiteCounter[steamid] = nil
				end
			end
		end
	end)
end