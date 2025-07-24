AddCSLuaFile()

SWEP.Base 			= "weapon_scp_base"
SWEP.PrintName		= "SCP-173"

SWEP.HoldType		= "normal"

SWEP.AttackDelay			= 0.25
SWEP.SpecialDelay			= 30
SWEP.NextAttackW			= 0
SWEP.NextKillAoE			= 0
SWEP.KillRadius				= 10 -- Bardzo blisko
SWEP.TeleportDelay			= 120 -- Cooldown na teleportację
SWEP.TeleportRange			= 300 -- Maksymalny zasięg teleportacji

if CLIENT then
	SWEP.WepSelectIcon 	= surface.GetTextureID("breach/wep_173")
end
 
--SWEP.SantasHatPositionOffset = Vector( -3, 47, 1 )
--SWEP.SantasHatAngleOffset = Angle( -90, -20, -20 )

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_173" )

	self:SetHoldType(self.HoldType)
	/*if CLIENT then
		if !self.SantasHat then
			self.SantasHat = ClientsideModel( "models/cloud/kn_santahat.mdl" )
			self.SantasHat:SetModelScale( 1.2 )
			self.SantasHat:SetNoDraw( true )
		end
	end*/
end

/*function SWEP:Remove()
	if CLIENT and IsValid( self.SantasHat ) then
		self.SantasHat:Remove()
	end
end*/

/*function SWEP:IsLookingAt( ply )
	local yes = ply:GetAimVector():Dot( ( self.Owner:GetPos() - ply:GetPos() + Vector( 70 ) ):GetNormalized() )
	return (yes > 0.39)
end*/
 
SWEP.Watching = 0
SWEP.NextTeleport = 0
function SWEP:Think()
	if CLIENT then
		self.Watching = CurTime() + 0.1
	end

	if postround then return end

	local watching = false

	local ply = self.Owner
	local obb_bot, obb_top = ply:GetModelBounds()
	local obb_mid = ( obb_bot + obb_top ) / 2

	obb_bot.x = obb_mid.x
	obb_bot.y = obb_mid.y
	obb_bot.z = obb_bot.z + 10

	obb_top.x = obb_mid.x
	obb_top.y = obb_mid.y
	obb_top.z = obb_top.z - 10

	local top, mid, bot = ply:LocalToWorld( obb_top ), ply:LocalToWorld( obb_mid ), ply:LocalToWorld( obb_bot )
	local mask = MASK_BLOCKLOS_AND_NPCS

	for k, v in pairs( player.GetAll() ) do
		if IsValid( v ) and v:GTeam() != TEAM_SPEC and v:GTeam() != TEAM_SCP and v:Alive() and v.canblink and !v.isblinking then
			if v.scp173allow and ply:GetPos():DistToSqr( v:GetPos() ) > 62500 then
				-- skip this player
			else

			local eyepos = v:EyePos()
			local eyevec = v:EyeAngles():Forward()

			local mid_z = mid:Copy()
			mid_z.z = mid_z.z + 17.5

			local line = ( mid_z - eyepos ):GetNormalized()
			local angle = math.acos( eyevec:Dot( line ) )

			if angle <= 0.8 then
				local trace_top = util.TraceLine( {
					start = eyepos,
					endpos = top,
					filter = { ply, v },
					mask = mask
				} )

				local trace_mid = util.TraceLine( {
					start = eyepos,
					endpos = mid,
					filter = { ply, v },
					mask = mask
				} )

				local trace_bot = util.TraceLine( {
					start = eyepos,
					endpos = bot,
					filter = { ply, v },
					mask = mask
				} )

				if !trace_top.Hit and !trace_mid.Hit and !trace_bot.Hit then
					watching = true
					break
				end
			end
			end -- End of else for continue replacement
		end
	end

	if watching then
		ply:Freeze( true )
		self:SetNWBool("IsWatched", true)
	else
		ply:Freeze( false )
		self:SetNWBool("IsWatched", false)
		
		-- Automatyczne AoE zabijanie gdy nikt nie patrzy
		if SERVER and self.NextKillAoE <= CurTime() then
			self.NextKillAoE = CurTime() + 0.5 -- Sprawdzaj co pół sekundy
			
			local nearbyPlayers = ents.FindInSphere(ply:GetPos(), self.KillRadius)
			for _, target in pairs(nearbyPlayers) do
				if IsValid(target) and target:IsPlayer() and target:Alive() then
					if (target:GTeam() != TEAM_SCP or target:GetNClass() == ROLES.ROLE_SCP035) and target:GTeam() != TEAM_SPEC then
						-- Zabij gracza
						local dmginfo = DamageInfo()
						dmginfo:SetDamage(target:Health() + 100)
						dmginfo:SetAttacker(ply)
						dmginfo:SetInflictor(self)
						dmginfo:SetDamageType(DMG_DIRECT)
						target:TakeDamageInfo(dmginfo)
						ply:AddExp(175, true)
						roundstats.snapped = roundstats.snapped + 1
						target:EmitSound("snap.wav", 500, 100)
					end
				end
			end
		end
	end
	/*local watching = 0
	for k,v in pairs(player.GetAll()) do
		if IsValid(v) and v:GTeam() != TEAM_SPEC and v:Alive() and v != self.Owner and v.canblink then
			local tr_eyes = util.TraceLine( {
				start = v:EyePos() - v:EyeAngles():Forward() * 5,
				//start = v:LocalToWorld( v:OBBCenter() ),
				//start = v:GetPos() + (self.Owner:EyeAngles():Forward() * 5000),
				endpos = self.Owner:EyePos() - self.Owner:EyeAngles():Forward() * 5,
				//filter = v
			} )

			/*local tr_center = util.TraceLine( {
				start = v:LocalToWorld( v:OBBCenter() ),
				endpos = self.Owner:LocalToWorld( self.Owner:OBBCenter() ),
				filter = v
			} )*/

			/*if tr_eyes.Entity == self.Owner then//tr_center.Entity == self.Owner then
				//self.Owner:PrintMessage(HUD_PRINTTALK, tostring(tr_eyes.Entity) .. " : " .. tostring(tr_center.Entity) .. " : " .. tostring(tr_center.Entity))
				if self:IsLookingAt( v ) and v.isblinking == false then
					if v.scp173allow and self.Owner:GetPos():DistToSqr( v:GetPos() ) > 62500 then
						continue
					end
					watching = watching + 1
					//if self:GetPos():Distance(v:GetPos()) > 100 then
						//self.Owner:PrintMessage(HUD_PRINTTALK, v:Nick() .. " is looking at you")
					//end 
				end
			end
		end
	end
	if watching > 0 then
		self.Owner:Freeze(true)
	else
		self.Owner:Freeze(false)
	end*/
end

function SWEP:PrimaryAttack()
	-- Usunięta funkcja - teraz zabijanie jest automatyczne w Think()
end

SWEP.NextSpecial = 0
function SWEP:SecondaryAttack()
	local time = 5
	if self.NextSpecial > CurTime() then return end
	self.NextSpecial = CurTime() + self.SpecialDelay
	self:SetNWFloat("NextSpecial", self.NextSpecial) -- Synchronizuj z klientem
	
	if CLIENT then
		surface.PlaySound("Horror2.ogg")
	end
	local findents = ents.FindInSphere( self.Owner:GetPos(), 600 )
	local foundplayers = {}
	for k,v in pairs(findents) do
		if v:IsPlayer() then
			if !((v:GTeam() == TEAM_SCP and v:GetNClass() != ROLES.ROLE_SCP035) or v:GTeam() == TEAM_SPEC or v.Using714 ) then
				if v.usedeyedrops == false then
					table.ForceInsert(foundplayers, v)
				end
			end
		end
	end
	if #foundplayers > 0 then
		local fixednicks = "Blinded: "
		if CLIENT then return end
		local numi = 0
		for k,v in pairs(foundplayers) do
			numi = numi + 1
			
			if numi == 1 then
				fixednicks = fixednicks .. v:Nick()
			elseif numi == #foundplayers then
				fixednicks = fixednicks .. " and " .. v:Nick()
			else
				fixednicks = fixednicks .. ", " .. v:Nick()
			end
			v:SendLua( 'surface.PlaySound("Horror2.ogg")' )
			net.Start("PlayerBlink")
				net.WriteFloat(time)
			net.Send(v)
			v.isblinking = true
			v.blinkedby173 = true
		end
		self.Owner:PrintMessage(HUD_PRINTTALK, fixednicks)
		timer.Create("UnBlinkTimer173", time + 0.2, 1, function()
			for k,v in pairs(player.GetAll()) do
				if v.blinkedby173 then
					v.isblinking = false
					v.blinkedby173 = false
				end
			end
		end)
	end
end

-- Nowa funkcja teleportacji na R
function SWEP:Reload()
	if !IsFirstTimePredicted() then return end
	if self.NextTeleport > CurTime() then return end
	
	self.NextTeleport = CurTime() + self.TeleportDelay
	
	if SERVER then
		self:SetNWFloat("NextTeleport", self.NextTeleport) -- Synchronizuj z klientem
		
		-- Znajdź najbliższego gracza w zasięgu
		local closestPlayer = nil
		local closestDist = math.huge
		local maxRangeSqr = self.TeleportRange * self.TeleportRange
		
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply:Alive() and ply != self.Owner then
				if (ply:GTeam() != TEAM_SCP or ply:GetNClass() == ROLES.ROLE_SCP035) and ply:GTeam() != TEAM_SPEC then
					local dist = self.Owner:GetPos():DistToSqr(ply:GetPos())
					-- Sprawdź czy w zasięgu
					if dist < closestDist and dist <= maxRangeSqr then
						closestDist = dist
						closestPlayer = ply
					end
				end
			end
		end
		
		if IsValid(closestPlayer) then
			-- Teleportuj na pozycję gracza
			self.Owner:SetPos(closestPlayer:GetPos())
			
			-- Obróć SCP-173 w stronę, w którą patrzy gracz
			local ang = closestPlayer:GetAngles()
			ang.p = 0
			ang.r = 0
			self.Owner:SetAngles(ang)
			

			
			-- Wiadomość
			self.Owner:PrintMessage(HUD_PRINTTALK, "Teleported to " .. closestPlayer:Nick())
		else
			self.Owner:PrintMessage(HUD_PRINTTALK, "No valid targets within range!")
			self.NextTeleport = CurTime() + 5 -- Krótszy cooldown jeśli nie ma celu
			self:SetNWFloat("NextTeleport", self.NextTeleport)
		end
	end
end

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
	local titleW, titleH = surface.GetTextSize("SCP-173")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-173")
	
	-- Status patrzenia
	local isWatched = self:GetNWBool("IsWatched", false)
	local statusText = isWatched and "BEING WATCHED" or "UNOBSERVED"
	local statusColor = isWatched and Color(255, 0, 0, 255) or Color(0, 255, 0, 255)
	
	surface.SetFont("DermaDefaultBold")
	surface.SetTextColor(statusColor)
	local statusW, statusH = surface.GetTextSize(statusText)
	surface.SetTextPos(centerX - statusW / 2, hudY + 95)  -- Przesunięte niżej z 35 na 45
	surface.DrawText(statusText)
	
	-- Cooldowny
	local cooldownY = hudY + 60
	local barWidth = 140
	local barHeight = 8
	local spacing = 20
	local totalWidth = barWidth * 3 + spacing * 2
	local startX = centerX - totalWidth / 2
	
	-- Auto Kill Status (LMB zastąpione przez status)
	local lmbBarX = startX
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(lmbBarX, cooldownY - 15)
	surface.DrawText("AUTO-KILL")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
	
	-- Zawsze aktywne gdy nie jest obserwowany
	if not isWatched then
		surface.SetDrawColor(255, 0, 0, 255)
		surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 150, 150, 255)
		surface.SetTextPos(lmbBarX, cooldownY + 10)
		surface.DrawText("ACTIVE")
	else
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 150, 150, 255)
		surface.SetTextPos(lmbBarX, cooldownY + 10)
		surface.DrawText("DISABLED")
	end
	
	-- RMB Cooldown (Blind)
	local rmbBarX = startX + barWidth + spacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rmbBarX, cooldownY - 15)
	surface.DrawText("RMB - Blind")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
	
	local blindCooldown = 0
	local nextSpecial = self:GetNWFloat("NextSpecial", 0)
	if nextSpecial > CurTime() then
		blindCooldown = nextSpecial - CurTime()
	end
	
	if blindCooldown > 0 then
		local progress = 1 - (blindCooldown / self.SpecialDelay)
		surface.SetDrawColor(255, 255, 0, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 255, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", blindCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- R Cooldown (Teleport)
	local rBarX = startX + (barWidth + spacing) * 2
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rBarX, cooldownY - 15)
	surface.DrawText("R - Teleport")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rBarX, cooldownY, barWidth, barHeight)
	
	local tpCooldown = 0
	local nextTeleport = self:GetNWFloat("NextTeleport", 0)
	if nextTeleport > CurTime() then
		tpCooldown = nextTeleport - CurTime()
	end
	
	if tpCooldown > 0 then
		local progress = 1 - (tpCooldown / self.TeleportDelay)
		surface.SetDrawColor(0, 150, 255, 255) -- Niebieski dla teleportu
		surface.DrawRect(rBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 200, 255, 255)
		surface.SetTextPos(rBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", tpCooldown))
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
	local color = isWatched and Color(255, 0, 0, 255) or Color(0, 255, 0, 255)
	surface.SetDrawColor(color)
	
	local gap = 5
	local length = gap + 20 * scale
	surface.DrawLine( x - length, y, x - gap, y )
	surface.DrawLine( x + length, y, x + gap, y )
	surface.DrawLine( x, y - length, x, y - gap )
	surface.DrawLine( x, y + length, x, y + gap )
end

/*function SWEP:DrawWorldModel()
	if !IsValid( self.SantasHat ) then return end
	local boneid = self.Owner:LookupBone( "joint1" )
	if not boneid then
		return
	end

	local matrix = self.Owner:GetBoneMatrix( boneid )
	if not matrix then
		return
	end

	local newpos, newang = LocalToWorld( self.SantasHatPositionOffset, self.SantasHatAngleOffset, matrix:GetTranslation(), matrix:GetAngles() )

	self.SantasHat:SetPos( newpos )
	self.SantasHat:SetAngles( newang )
	self.SantasHat:SetupBones()
	self.SantasHat:DrawModel()
end*/