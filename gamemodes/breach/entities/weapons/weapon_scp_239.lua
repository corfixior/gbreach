AddCSLuaFile()

SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-239"

SWEP.HoldType = "normal"
SWEP.DrawCrosshair = true

-- SCP-239 Configuration
SWEP.AbilityDelay = 25 -- 3 second cooldown between abilities
SWEP.VulnerabilityDuration = 30 -- 30 seconds of vulnerability
SWEP.VulnerabilityInterval = 120 -- 2 minutes between vulnerability windows
SWEP.InvisibilityDuration = 10 -- 10 seconds of invisibility
SWEP.LowGravityDuration = 10 -- 10 seconds of low gravity

SWEP.NextAttackW = 0
SWEP.NextSpecial = 0
SWEP.AbilityCooldown = 0
SWEP.NextAbilities = {} -- Lista następnych umiejętności

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID("breach/wep_239")
	
	-- Client-side only code
	
	-- HUD Drawing
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
		
		-- Tło HUD (identyczne jak inne SCPy)
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
		local titleW, titleH = surface.GetTextSize("SCP-239")
		surface.SetTextPos(centerX - titleW / 2, hudY + 10)
		surface.DrawText("SCP-239")
		
		-- Cooldown LMB (lewa strona)
		local cooldownY = hudY + 60
		local barWidth = 180
		local barHeight = 8
		local lmbBarX = hudX + 20
		
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		surface.SetTextPos(lmbBarX, cooldownY - 15)
		surface.DrawText("LMB - Random Ability")
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
		
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
		
		local cooldownRemaining = math.max(0, self.AbilityCooldown - CurTime())
		
		if cooldownRemaining > 0 then
			local progress = 1 - (cooldownRemaining / self.AbilityDelay)
			surface.SetDrawColor(255, 100, 255, 255)
			surface.DrawRect(lmbBarX, cooldownY, barWidth * progress, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(255, 150, 255, 255)
			surface.SetTextPos(lmbBarX, cooldownY + 10)
			surface.DrawText(string.format("%.1fs", cooldownRemaining))
		else
			surface.SetDrawColor(100, 255, 100, 255)
			surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(150, 255, 150, 255)
			surface.SetTextPos(lmbBarX, cooldownY + 10)
			surface.DrawText("READY")
		end
		
		-- Tabelka z umiejętnościami (prawa strona)
		local abilitiesX = hudX + hudWidth - 100
		local abilitiesY = hudY + 45
		
		-- Nazwy umiejętności
		local abilityNames = {
			[1] = "Instant Kill",
			[2] = "Swap Positions", 
			[3] = "Prop Transform",
			[4] = "Drain Health",
			[5] = "Low Gravity",
			[6] = "Explode Player",
			[7] = "Shrink Player",
			[8] = "Drop Items",
			[9] = "Invisibility"
		}
		
		-- Tytuł tabelki
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		surface.SetTextPos(abilitiesX, abilitiesY - 15)
		surface.DrawText("Next Abilities:")
		
		-- Pokaż 3 następne umiejętności z serwera
		for i = 1, 3 do
			local abilityIndex = self:GetNWInt("NextAbility" .. i, 0)
			if abilityIndex > 0 and abilityNames[abilityIndex] then
				surface.SetTextColor(180, 180, 180, 255)
				surface.SetFont("DermaDefault")
				surface.SetTextPos(abilitiesX, abilitiesY + (i * 15))
				surface.DrawText("• " .. abilityNames[abilityIndex])
			end
		end
		
		-- Celownik
		local x = ScrW() / 2.0
		local y = ScrH() / 2.0
		
		local scale = 0.3
		local color = Color(255, 100, 255, 255)
		surface.SetDrawColor(color)
		
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
end

function SWEP:Initialize()
	self:InitializeLanguage("SCP_239")
	self:SetHoldType(self.HoldType)
	
	-- Initialize glass break cooldown
	self.NextGlassBreak = 0
	
	if SERVER then
		-- Initialize vulnerability system
		self.VulnerabilityDuration = 30
		self.IsVulnerable = false
		
		-- Initialize abilities queue
		self.NextAbilities = {}
		self:GenerateNextAbilities()
		
		-- Wait for owner to be valid before setting NWBool
		timer.Simple(0.1, function()
			if IsValid(self) and IsValid(self.Owner) then
				-- Initialize as immortal
				self.Owner:SetNWBool("SCP239_Vulnerable", false)
				self:SetNWBool("SCP239_Vulnerable", false)
				self:SetNWFloat("SCP239_VulnerabilityTime", 0)
				
				-- Debug
				print("[SCP-239] Initialized as IMMORTAL for player:", self.Owner:Nick())
				print("[SCP-239] NWBool set to:", self.Owner:GetNWBool("SCP239_Vulnerable", true)) -- Should be false
				
				-- Start vulnerability timer
				local timerName = "SCP239_Vulnerability_" .. self.Owner:EntIndex()
				timer.Create(timerName, 120, 0, function()
					if IsValid(self) and IsValid(self.Owner) then
						self:StartVulnerability()
					else
						timer.Remove(timerName)
					end
				end)
			end
		end)
	end
end

-- SERVER FUNCTIONS
if SERVER then
	util.AddNetworkString("SCP239_VulnerabilityStart")
	util.AddNetworkString("SCP239_VulnerabilityEnd")
	
	-- Generate next 3 abilities
	function SWEP:GenerateNextAbilities()
		self.NextAbilities = {}
		
		-- Generate 3 random abilities
		for i = 1, 3 do
			local abilityIndex = math.random(1, 9)
			table.insert(self.NextAbilities, abilityIndex)
		end
		
		-- Sync to client
		self:SyncAbilitiesToClient()
	end
	
	-- Sync abilities to client via NWVars
	function SWEP:SyncAbilitiesToClient()
		for i = 1, 3 do
			local abilityIndex = self.NextAbilities[i] or 0
			self:SetNWInt("NextAbility" .. i, abilityIndex)
		end
	end
	
	-- Update abilities queue when one is used
	function SWEP:UseNextAbility()
		-- Remove first ability and add new one at the end
		table.remove(self.NextAbilities, 1)
		
		-- Add new random ability
		local newAbility = math.random(1, 9)
		table.insert(self.NextAbilities, newAbility)
		
		-- Sync to client
		self:SyncAbilitiesToClient()
	end
	
	function SWEP:StartVulnerability()
		if not IsValid(self.Owner) then return end
		
		self.IsVulnerable = true
		self.Owner:SetNWBool("SCP239_Vulnerable", true)
		self:SetNWBool("SCP239_Vulnerable", true)
		self:SetNWFloat("SCP239_VulnerabilityTime", CurTime() + self.VulnerabilityDuration)
		
		-- Debug
		print("[SCP-239] Started VULNERABILITY for player:", self.Owner:Nick())
		print("[SCP-239] Will end in", self.VulnerabilityDuration, "seconds")
		
		-- Notify all players
		net.Start("SCP239_VulnerabilityStart")
		net.Broadcast()
		
		-- Play alarm sound
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) then
				ply:EmitSound("buttons/button10.wav", 100, 80)
			end
		end
		
		-- End vulnerability after duration
		timer.Simple(self.VulnerabilityDuration, function()
			if IsValid(self) and IsValid(self.Owner) then
				self:EndVulnerability()
			end
		end)
	end
	
	function SWEP:EndVulnerability()
		if not IsValid(self.Owner) then return end
		
		self.IsVulnerable = false
		self.Owner:SetNWBool("SCP239_Vulnerable", false)
		self:SetNWBool("SCP239_Vulnerable", false)
		self:SetNWFloat("SCP239_VulnerabilityTime", 0)
		
		-- Debug
		print("[SCP-239] Ended VULNERABILITY for player:", self.Owner:Nick())
		print("[SCP-239] Player is now IMMORTAL again")
		
		-- Notify all players
		net.Start("SCP239_VulnerabilityEnd")
		net.Broadcast()
	end
	
	-- Invisibility system
	function SWEP:StartInvisibility()
		if IsValid(self.Owner) then
			self.Owner:SetNoDraw(true)
			self.Owner:SetNotSolid(true)
			
			timer.Simple(self.InvisibilityDuration, function()
				if IsValid(self.Owner) then
					self.Owner:SetNoDraw(false)
					self.Owner:SetNotSolid(false)
				end
			end)
		end
	end
	
	-- GLOBAL ABILITIES (no range restrictions)
	function SWEP:InstantKill()
		local enemies = {}
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply != self.Owner and ply:Alive() then
				if (ply:GTeam() != TEAM_SCP or ply:GetNClass() == ROLES.ROLE_SCP035) and ply:GTeam() != TEAM_SPEC then
					table.insert(enemies, ply)
				end
			end
		end
		
		if #enemies == 0 then return end
		
		local target = enemies[math.random(1, #enemies)]
		
		local dmginfo = DamageInfo()
		dmginfo:SetDamage(target:Health() + 100)
		dmginfo:SetAttacker(self.Owner)
		dmginfo:SetInflictor(self)
		dmginfo:SetDamageType(DMG_DIRECT)
		target:TakeDamageInfo(dmginfo)
		
		self.Owner:AddExp(200, true)
	end
	
	function SWEP:SwapPositions()
		local allPlayers = {}
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply != self.Owner and ply:Alive() and ply:GTeam() != TEAM_SPEC then
				table.insert(allPlayers, ply)
			end
		end
		
		if #allPlayers == 0 then return end
		
		local target = allPlayers[math.random(1, #allPlayers)]
		local ownerPos = self.Owner:GetPos()
		local targetPos = target:GetPos()
		
		self.Owner:SetPos(targetPos)
		target:SetPos(ownerPos)
	end
	
	function SWEP:PropTransform()
		local enemies = {}
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply != self.Owner and ply:Alive() then
				if (ply:GTeam() != TEAM_SCP or ply:GetNClass() == ROLES.ROLE_SCP035) and ply:GTeam() != TEAM_SPEC then
					table.insert(enemies, ply)
				end
			end
		end
		
		if #enemies == 0 then return end
		
		local target = enemies[math.random(1, #enemies)]
		local originalPos = target:GetPos() -- Zapisz pozycję PRZED teleportacją
		
		-- Teleportuj gracza poza mapę (bardzo daleko w dół)
		local farAwayPos = originalPos + Vector(0, 0, -10000)
		target:SetPos(farAwayPos)
		
		-- Natychmiast zabij gracza po teleportacji
		timer.Simple(0.05, function()
			if IsValid(target) then
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(target:Health() + 1000)
				dmginfo:SetAttacker(self.Owner)
				dmginfo:SetInflictor(self)
				dmginfo:SetDamageType(DMG_DIRECT)
				target:TakeDamageInfo(dmginfo)
			end
		end)
		
		-- Stwórz prop w miejscu gdzie wcześniej stał gracz (originalPos)
		local propModels = {
			"models/props_c17/FurnitureChair001a.mdl",
			"models/props/cs_office/chair_office.mdl",
			"models/props_c17/FurnitureTable001a.mdl",
			"models/props_c17/FurnitureDrawer001a.mdl",
			"models/props_c17/FurnitureCouch001a.mdl",
			"models/props_interiors/refrigerator01a.mdl",
			"models/props_c17/FurnitureWashingmachine001a.mdl",
			"models/props_c17/FurnitureToilet001a.mdl",
			"models/props/cs_office/sofa.mdl",
			"models/props_c17/FurnitureBed001a.mdl"
		}
		
		local prop = ents.Create("prop_physics")
		prop:SetModel(propModels[math.random(1, #propModels)])
		prop:SetPos(originalPos + Vector(0, 0, 50)) -- Spawn 50 jednostek wyżej od oryginalnej pozycji
		prop:Spawn()
		
		-- Dodaj fizyczne siły żeby prop spadł naturalnie
		timer.Simple(0.1, function()
			if IsValid(prop) then
				local phys = prop:GetPhysicsObject()
				if IsValid(phys) then
					phys:Wake()
				end
			end
		end)
		
		-- Usuń prop po 30 sekundach
		timer.Simple(30, function()
			if IsValid(prop) then
				prop:Remove()
			end
		end)
		
		self.Owner:AddExp(150, true)
	end
	
	function SWEP:DrainHealth()
		local enemies = {}
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply != self.Owner and ply:Alive() then
				if (ply:GTeam() != TEAM_SCP or ply:GetNClass() == ROLES.ROLE_SCP035) and ply:GTeam() != TEAM_SPEC then
					table.insert(enemies, ply)
				end
			end
		end
		
		if #enemies == 0 then return end
		
		local target = enemies[math.random(1, #enemies)]
		target:SetHealth(1)
	end
	
	function SWEP:LowGravity()
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply:Alive() then
				ply:SetGravity(0.3)
			end
		end
		
		timer.Simple(self.LowGravityDuration, function()
			for _, ply in pairs(player.GetAll()) do
				if IsValid(ply) then
					ply:SetGravity(1)
				end
			end
		end)
	end
	
	function SWEP:ExplodePlayer()
		local enemies = {}
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply != self.Owner and ply:Alive() then
				if (ply:GTeam() != TEAM_SCP or ply:GetNClass() == ROLES.ROLE_SCP035) and ply:GTeam() != TEAM_SPEC then
					table.insert(enemies, ply)
				end
			end
		end
		
		if #enemies == 0 then return end
		
		local target = enemies[math.random(1, #enemies)]
		local targetPos = target:GetPos()
		
		-- Kill the player
		local dmginfo = DamageInfo()
		dmginfo:SetDamage(target:Health() + 100)
		dmginfo:SetAttacker(self.Owner)
		dmginfo:SetInflictor(self)
		dmginfo:SetDamageType(DMG_BLAST)
		target:TakeDamageInfo(dmginfo)
		
		-- Create explosion effect
		local explode = ents.Create("env_explosion")
		explode:SetPos(targetPos)
		explode:SetKeyValue("iMagnitude", "100")
		explode:Spawn()
		explode:Fire("Explode", 0, 0)
		
		self.Owner:AddExp(175, true)
	end
	
	function SWEP:ShrinkPlayer()
		local enemies = {}
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply != self.Owner and ply:Alive() then
				if (ply:GTeam() != TEAM_SCP or ply:GetNClass() == ROLES.ROLE_SCP035) and ply:GTeam() != TEAM_SPEC then
					table.insert(enemies, ply)
				end
			end
		end
		
		if #enemies == 0 then return end
		
		local target = enemies[math.random(1, #enemies)]
		target:SetModelScale(0.5)
		
		timer.Simple(60, function()
			if IsValid(target) then
				target:SetModelScale(1)
			end
		end)
	end
	
	function SWEP:DropItems()
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply:Alive() and ply:GTeam() != TEAM_SCP and ply:GTeam() != TEAM_SPEC then
				local weapon = ply:GetActiveWeapon()
				if IsValid(weapon) then
					local class = weapon:GetClass()
					-- Nie wyrzucaj br_holster i br_id
					if class != "br_holster" and class != "br_id" then
						ply:DropWeapon(weapon)
					end
				end
			end
		end
	end
	
	function SWEP:Invisibility()
		self:StartInvisibility()
	end
end

function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if self.AbilityCooldown > CurTime() then return end
	
	self.AbilityCooldown = CurTime() + self.AbilityDelay
	
	if SERVER then
		self:UseRandomAbility()
	end
end

if SERVER then
	function SWEP:UseRandomAbility()
		-- Use first ability from queue
		if not self.NextAbilities or #self.NextAbilities == 0 then
			self:GenerateNextAbilities()
		end
		
		local abilityIndex = self.NextAbilities[1] or 1
		
		local abilities = {
			function() self:InstantKill() end,
			function() self:SwapPositions() end,
			function() self:PropTransform() end,
			function() self:DrainHealth() end,
			function() self:LowGravity() end,
			function() self:ExplodePlayer() end,
			function() self:ShrinkPlayer() end,
			function() self:DropItems() end,
			function() self:Invisibility() end
		}
		
		-- Execute the ability
		if abilities[abilityIndex] then
			abilities[abilityIndex]()
		end
		
		-- Update abilities queue
		self:UseNextAbility()
	end
end

function SWEP:SecondaryAttack()
	-- No secondary attack for SCP-239
end

function SWEP:Deploy()
	if IsValid(self.Owner) then
		self.Owner:DrawWorldModel(false)
		self.Owner:DrawViewModel(false)
	end
end

-- Clean up on holster
function SWEP:Holster()
	if SERVER then
		-- Clean up timers when weapon is holstered
		local timerName = "SCP239_Vulnerability_" .. (IsValid(self.Owner) and self.Owner:EntIndex() or "unknown")
		timer.Remove(timerName)
		
		-- Reset vulnerability state
		if IsValid(self.Owner) then
			self.Owner:SetNWBool("SCP239_Vulnerable", false)
		end
	end
	
	return true
end

-- Rozbijanie szyb na klawisz E dla SCP-239
if SERVER then
	hook.Add("KeyPress", "SCP239_GlassBreak", function(ply, key)
		if !IsValid(ply) or !ply:Alive() then return end
		local wep = ply:GetActiveWeapon()
		if !IsValid(wep) or wep:GetClass() != "weapon_scp_239" then return end
		
		-- Sprawdź czy to E (32)
		if key != 32 then return end
		
		-- Cooldown
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
			elseif string.find(ent:GetClass(), "door") then
				-- Możliwość rozbicia drzwi ze szkłem
				wep:SCPDamageEvent(ent, 100)
			end
		end
	end)
end