SWEP.Base = "weapon_base"
SWEP.Category = "Breach SWEPs"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.PrintName = "SCP Radar"
SWEP.Author = "Breach Team"
SWEP.Instructions = "Passive radar that shows SCP locations. No interaction required."
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.HoldType = "slam"

SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.Ammo = "none"

SWEP.Slot = 2
SWEP.SlotPos = 1

-- Breach gamemode integration
SWEP.droppable = true
SWEP.teams = {TEAM_SCI}

-- Radar settings
SWEP.RadarRange = 2000
SWEP.RadarSize = 150

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
	self.Owner:DrawViewModel(false)
	return true
end

function SWEP:DrawWorldModel()
	if not IsValid(self.Owner) then
		self:DrawModel()
	end
end

function SWEP:PrimaryAttack()
	-- No primary attack
end

function SWEP:SecondaryAttack()
	-- No secondary attack
end



function SWEP:Holster()
	return true
end

-- Client-side radar display
if CLIENT then
	hook.Add("HUDPaint", "SCPRadar_Display", function()
		local ply = LocalPlayer()
		if not IsValid(ply) or not ply:Alive() then return end
		
		-- Check if player has SCP radar in inventory
		local hasRadar = false
		for _, weapon in pairs(ply:GetWeapons()) do
			if IsValid(weapon) and weapon:GetClass() == "weapon_scp_radar" then
				hasRadar = true
				break
			end
		end
		
		if not hasRadar then return end
		
		-- Radar display settings
		local radarSize = 200
		local radarX = ScrW() - radarSize - 50
		local radarY = 50
		local radarRange = 2000
		
		-- Draw black background
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(radarX, radarY, radarSize, radarSize)
		
		-- Draw border
		surface.SetDrawColor(100, 100, 100, 255)
		surface.DrawOutlinedRect(radarX, radarY, radarSize, radarSize)
		
		-- Player position (center of radar)
		local playerPos = ply:GetPos()
		local centerX = radarX + radarSize / 2
		local centerY = radarY + radarSize / 2
		
		-- Draw player (green triangle pointing up in center)
		surface.SetDrawColor(0, 255, 0, 255)
		local triangleSize = 5
		surface.DrawPoly({
			{x = centerX, y = centerY - triangleSize},           -- Top point
			{x = centerX - triangleSize, y = centerY + triangleSize}, -- Bottom left
			{x = centerX + triangleSize, y = centerY + triangleSize}  -- Bottom right
		})
		
		-- Get player's view angle for dynamic rotation
		local playerAngle = ply:EyeAngles().y
		
		-- Draw SCPs (red squares)
		for _, target in pairs(player.GetAll()) do
			if IsValid(target) and target != ply and target:Alive() and target:GTeam() == TEAM_SCP then
				local targetPos = target:GetPos()
				local distance = playerPos:Distance(targetPos)
				
				-- Only show SCPs within range
				if distance <= radarRange then
					-- Calculate relative position
					local relativePos = targetPos - playerPos
					
					-- Get forward and right vectors from player's view angle
					local playerForward = ply:GetForward()
					local playerRight = ply:GetRight()
					
					-- Project relative position onto player's forward and right vectors
					local forwardDist = relativePos:Dot(playerForward)
					local rightDist = relativePos:Dot(playerRight)
					
					-- Convert to radar coordinates (player view always up)
					local scale = (radarSize / 2) / radarRange
					local dotX = centerX + (rightDist * scale)    -- Right = positive X on screen
					local dotY = centerY - (forwardDist * scale)  -- Forward = negative Y on screen
					
					-- Keep dots within radar bounds
					dotX = math.Clamp(dotX, radarX + 2, radarX + radarSize - 2)
					dotY = math.Clamp(dotY, radarY + 2, radarY + radarSize - 2)
					
					-- Draw SCP as red inverted triangle
					surface.SetDrawColor(255, 0, 0, 255)
					local scpTriangleSize = 4
					surface.DrawPoly({
						{x = dotX, y = dotY + scpTriangleSize},              -- Bottom point
						{x = dotX - scpTriangleSize, y = dotY - scpTriangleSize}, -- Top left
						{x = dotX + scpTriangleSize, y = dotY - scpTriangleSize}  -- Top right
					})
				end
			end
		end
	end)
end 