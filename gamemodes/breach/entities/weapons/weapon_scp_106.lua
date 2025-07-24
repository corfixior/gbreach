AddCSLuaFile()

SWEP.Base 			= "weapon_scp_base"
SWEP.PrintName		= "SCP-106"

SWEP.ViewModel		= "models/vinrax/props/keycard.mdl"
SWEP.WorldModel		= "models/vinrax/props/keycard.mdl"

SWEP.HoldType		= "normal"

SWEP.Chase 			= "scp/106/chase.ogg"
SWEP.Place 			= "scp/106/place.ogg"
SWEP.Teleport 		= "scp/106/tp.ogg"
SWEP.Disappear 		= "scp/106/disappear.ogg"

SWEP.NextAttackW	= 0
SWEP.AttackDelay	= 1.5
SWEP.AttackCount    = 0 -- Licznik ataków dla instakill

if CLIENT then
	SWEP.WepSelectIcon 	= surface.GetTextureID("breach/wep_106")
	SWEP.AttackCounter = 0 -- Kopia dla klienta
end

function SWEP:OnRemove()
	if IsValid( self.Owner ) then
		self.Owner:SetCustomCollisionCheck( false )
	end
end

function SWEP:Deploy()
	if IsValid( self.Owner ) then
		self.Owner:SetCustomCollisionCheck( true )
	end
	self:HideModels()
end

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_106" )

	self:SetHoldType(self.HoldType)

	self:PrecacheSnd( {
		{ name = "Place", snd = self.Place, level = 75 },
		{ name = "Disappear", snd = self.Disappear, level = 125 },
		{ name = "Teleport", snd = self.Teleport, level = 325 },
	} )
end

function SWEP:PrecacheSnd( tab )
	for k, v in pairs( tab ) do
		sound.Add( {
			name = v.name,
			channel = CHAN_STATIC,
			volume = 1.0,
			level = v.level or 75,
			pitch = 100,
			sound = v.snd
		} )
	end
end

SWEP.SoundPlayers = {}
SWEP.NThink = 0
function SWEP:Think()
	if self.NThink > CurTime() then return end
	self.NThink = CurTime() + 1
	if SERVER then
		for k, v in pairs( self.SoundPlayers ) do
			if v.ply:GTeam() == TEAM_SPEC or v.ply:GTeam() == TEAM_SCP or ( v.time and v.time < CurTime() ) or self.Owner:GetPos():DistToSqr( v.ply:GetPos() ) > 562500 then
				net.Start( "SendSound" )
					net.WriteInt( 0, 2 )
					net.WriteString( self.Chase )
				net.Send( v.ply )
				self.SoundPlayers[k] = nil
				--print( "Removing ", v.ply )
			end
		end
		-- OPTYMALIZACJA: Użyj zoptymalizowanej funkcji wyszukiwania graczy
		local nearbyPlayers = {}
		if _G.FindNearbyPlayers then
			nearbyPlayers = _G.FindNearbyPlayers(self.Owner:GetPos(), 750, self.Owner)
		else
			-- Fallback do oryginalnej metody
			local e = ents.FindInSphere( self.Owner:GetPos(), 750 )
			for k, v in pairs( e ) do
				if IsValid( v ) and v:IsPlayer() then
					table.insert(nearbyPlayers, v)
				end
			end
		end

		for k, v in pairs( nearbyPlayers ) do
			if IsValid( v ) and  v:IsPlayer() then
				if  v:GTeam() != TEAM_SPEC and v:GTeam() != TEAM_SCP then
					if !self:IsInTable( self.SoundPlayers, v ) then
						net.Start( "SendSound" )
							net.WriteInt( 1, 2 )
							net.WriteString( self.Chase )
						net.Send( v )
						table.insert( self.SoundPlayers, { ply = v, time = CurTime() + 31 } )
						--print( "inserting ", v )
					end
				end
			end
		end
	end
end

function SWEP:PrimaryAttack()
	//if ( !self:CanPrimaryAttack() ) then return end
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextAttackW > CurTime() then return end
	
	if SERVER then
		local ent = nil
		local tr = util.TraceHull( {
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + ( self.Owner:GetAimVector() * 100 ),
			filter = self.Owner,
			mins = Vector( -10, -10, -10 ),
			maxs = Vector( 10, 10, 10 ),
			mask = MASK_SHOT_HULL
		} )
		ent = tr.Entity
		if IsValid(ent) then
			-- Ustaw cooldown tylko gdy trafiliśmy w coś
			self.NextAttackW = CurTime() + self.AttackDelay
			self:SetNWFloat("NextAttackW", self.NextAttackW) -- Synchronizuj z klientem
			
			if ent:IsPlayer() then
				if ent:GTeam() == TEAM_SCP and ent:GetNClass() != ROLES.ROLE_SCP035 then return end
				if ent:GTeam() == TEAM_SPEC then return end
				if ent.Using714 then return end
				
				-- Zwiększ licznik ataków
				self.AttackCount = self.AttackCount + 1
				self:SetNWInt("AttackCounter", self.AttackCount) -- Synchronizuj z klientem
				
				local pos = GetPocketPos()
				local ang = ent:GetAngles()
				ang.yaw = math.random( -180, 180 )
				if pos then
					roundstats.teleported = roundstats.teleported + 1
					
					-- Co trzeci atak = instakill
					if self.AttackCount >= 3 then
						self.AttackCount = 0 -- Reset licznika
						self:SetNWInt("AttackCounter", 0) -- Synchronizuj reset
						ent:Kill() -- Instakill
						self.Owner:AddExp(150, true) -- Więcej EXP za instakill
					else
						-- Normalny atak
						ent:TakeDamage( math.random( 25, 50 ), self.Owner, self.Owner )
						ent:SetPos(pos)
						ent:SetAngles( ang )
						self.Owner:AddExp(75, true)
					end
				end
			else
				self:SCPDamageEvent( ent, 10 )
			end
		end
		-- Jeśli nie trafiliśmy w nic, nie ustawiamy cooldownu
	end
end

SWEP.NextPlace = 0
SWEP.TPPoint = nil
function SWEP:SecondaryAttack()
	if SERVER then
		if self.NextPlace > CurTime() then
			self.Owner:PrintMessage( HUD_PRINTTALK, "You have to wait "..math.ceil( self.NextPlace - CurTime() ).." before next use!" )
			return
		end
		self.NextPlace = CurTime() + 15

		-- Synchronizuj z klientem
		self:SetNWFloat("NextPlace", self.NextPlace)

		self.Owner:EmitSound( "Place" )
		self.TPPoint = self.Owner:GetPos()
		
		local tr = util.TraceLine( {
			start = self.Owner:GetPos(),
			endpos = self.Owner:GetPos() - Vector( 0, 0, 100 ),
			filter = self.Owner
		} )
		if tr.Hit then
			util.Decal( "Decal106", tr.HitPos - tr.HitNormal, tr.HitPos + tr.HitNormal )
		end
	end
end

SWEP.NextTP = 0
function SWEP:Reload()
	if !IsFirstTimePredicted() then return end

	if self.NextTP > CurTime() then return end
	self.NextTP = CurTime() + 60 -- Zmiana z 90 na 60 sekund

	if SERVER then
		if self.TPPoint then
			self:TeleportSequence( self.TPPoint )
		end
	end
end

function SWEP:TeleportSequence( point )
	self.NextAttackW = CurTime() + 8
	self:SetNWFloat("NextAttackW", self.NextAttackW) -- Synchronizuj atak
	self.NextPlace = CurTime() + 15
	self:SetNWFloat("NextPlace", self.NextPlace) -- Synchronizuj z klientem

	local tr = util.TraceLine( {
		start = self.Owner:GetPos(),
		endpos = self.Owner:GetPos() - Vector( 0, 0, 100 ),
		filter = self.Owner
	} )
	if tr.Hit then
		util.Decal( "Decal106", tr.HitPos - tr.HitNormal, tr.HitPos + tr.HitNormal )
	end

	self.Owner:Freeze( true )

	if timer.Exists( "106TP_1"..self.Owner:SteamID64() ) then timer.Remove( "106TP_1"..self.Owner:SteamID64() ) end
	if timer.Exists( "106TP_2"..self.Owner:SteamID64() ) then timer.Remove( "106TP_2"..self.Owner:SteamID64() ) end

	local i = 40
	local ppos = self.Owner:GetPos()
	timer.Create( "106TP_1"..self.Owner:SteamID64(), 0.1, 40, function()
		if IsValid( self ) and IsValid( self.Owner ) then
			if i % 20 == 0 then
				self:SendSound( self.Disappear, 500 )
			end
			self.Owner:SetPos( ppos - Vector( 0, 0, 2 * ( 40 - i ) ) )
		end
		i = i - 1
	end )
	timer.Simple( 4.1, function()
		if IsValid( self ) and IsValid( self.Owner ) then
			self.Owner:SetPos( point - Vector( 0, 0, 80 ) )
		end
		local i = 40
		timer.Create( "106TP_2"..self.Owner:SteamID64(), 0.1, 41, function()
			if IsValid( self ) and IsValid( self.Owner ) then
				if i == 40 or i == 10 then
					self:SendSound( self.Teleport, 500 )
				end
				self.Owner:SetPos( point - Vector( 0, 0, 80 ) + Vector( 0, 0, 2 * ( 41 - i ) ) )
				i = i - 1
			end
		end )
		timer.Simple( 4.1, function()
			if IsValid( self ) and IsValid( self.Owner ) then
				self.Owner:SetPos( point )
				self.Owner:Freeze( false )
			end			
		end )
	end )
end

function SWEP:SendSound( sound, range )
	-- OPTYMALIZACJA: Użyj zoptymalizowanej funkcji wyszukiwania
	local nearbyPlayers = {}
	if _G.FindNearbyPlayers then
		nearbyPlayers = _G.FindNearbyPlayers(self.Owner:GetPos(), range, self.Owner)
	else
		-- Fallback do oryginalnej metody
		local e = ents.FindInSphere( self.Owner:GetPos(), range )
		for k, v in pairs( e ) do
			if IsValid( v ) and v:IsPlayer() then
				table.insert(nearbyPlayers, v)
			end
		end
	end

	for k, v in pairs( nearbyPlayers ) do
		if IsValid( v ) and  v:IsPlayer() then
			net.Start( "SendSound" )
				net.WriteInt( 1, 2 )
				net.WriteString( sound )
			net.Send( v )
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
	local titleW, titleH = surface.GetTextSize("SCP-106")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-106")
	
	-- Cooldowny
	local cooldownY = hudY + 60
	local barWidth = 140
	local barHeight = 8
	local spacing = 20 -- Zmniejszony odstęp z 40 na 20
	local totalWidth = barWidth * 3 + spacing * 2
	local startX = centerX - totalWidth / 2
	
	-- LMB Cooldown (Pocket Dimension)
	local lmbBarX = startX
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(lmbBarX, cooldownY - 15)
	surface.DrawText("LMB - Pocket")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
	
	local attackCooldown = 0
	-- Pobierz z networked variable
	local nextAttack = self:GetNWFloat("NextAttackW", 0)
	if nextAttack > CurTime() then
		attackCooldown = nextAttack - CurTime()
	end
	
	if attackCooldown > 0 then
		local progress = 1 - (attackCooldown / self.AttackDelay)
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
	
	-- RMB Cooldown (Place TP)
	local rmbBarX = startX + barWidth + spacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rmbBarX, cooldownY - 15)
	surface.DrawText("RMB - Place TP")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
	
	local placeCooldown = 0
	-- Pobierz z networked variable
	local nextPlace = self:GetNWFloat("NextPlace", 0)
	if nextPlace > CurTime() then
		placeCooldown = nextPlace - CurTime()
	end
	
	if placeCooldown > 0 then
		local progress = 1 - (placeCooldown / 15)
		surface.SetDrawColor(255, 255, 0, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 255, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", placeCooldown))
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
	if self.NextTP and self.NextTP > CurTime() then
		tpCooldown = self.NextTP - CurTime()
	end
	
	if tpCooldown > 0 then
		local progress = 1 - (tpCooldown / 60)
		surface.SetDrawColor(148, 0, 211, 255) -- Fioletowy dla teleportu
		surface.DrawRect(rBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(200, 150, 255, 255)
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
	
	-- Pobierz licznik z networked variable
	local attackCounter = self:GetNWInt("AttackCounter", 0)
	
	-- Efekt gdy następny atak będzie instakill
	if attackCounter == 2 then
		local time = CurTime()
		
		-- Pulsujący efekt
		local pulse = math.sin(time * 5) * 0.3 + 0.7 -- Wartość od 0.4 do 1.0
		local pulseScale = 1 + math.sin(time * 3) * 0.2 -- Pulsująca wielkość
		
		-- Czerwone pulsujące zewnętrzne okręgi
		local radius = 40 * pulseScale
		surface.SetDrawColor(255, 0, 0, 100 * pulse)
		
		-- Rysuj okręgi
		for i = 1, 3 do
			local r = radius + i * 10
			-- Górny łuk
			surface.DrawLine(x - r, y, x - r + 10, y - 10)
			surface.DrawLine(x - r + 10, y - 10, x, y - r)
			surface.DrawLine(x, y - r, x + r - 10, y - 10)
			surface.DrawLine(x + r - 10, y - 10, x + r, y)
			-- Dolny łuk
			surface.DrawLine(x + r, y, x + r - 10, y + 10)
			surface.DrawLine(x + r - 10, y + 10, x, y + r)
			surface.DrawLine(x, y + r, x - r + 10, y + 10)
			surface.DrawLine(x - r + 10, y + 10, x - r, y)
		end
		
		-- Czerwony pulsujący celownik
		local scale = 0.3 + pulse * 0.1
		surface.SetDrawColor(255, 0, 0, 255) -- Jasny czerwony
		
		local gap = 5
		local length = gap + 20 * scale
		
		-- Grubsze linie
		for i = -1, 1 do
			surface.DrawLine( x - length, y + i, x - gap, y + i )
			surface.DrawLine( x + length, y + i, x + gap, y + i )
			surface.DrawLine( x + i, y - length, x + i, y - gap )
			surface.DrawLine( x + i, y + length, x + i, y + gap )
		end
		
		-- Tekst ostrzeżenia
		local warningAlpha = 255 * pulse
		draw.SimpleTextOutlined("INSTAKILL READY", "DermaLarge", x, y - 60,
			Color(255, 0, 0, warningAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
			2, Color(0, 0, 0, warningAlpha))
		
		-- Małe czerwone kropki wokół celownika
		local dotRadius = 25 + math.sin(time * 4) * 5
		for i = 0, 7 do
			local angle = (i / 8) * math.pi * 2 + time
			local dx = x + math.cos(angle) * dotRadius
			local dy = y + math.sin(angle) * dotRadius
			surface.SetDrawColor(255, 0, 0, warningAlpha)
			surface.DrawRect(dx - 2, dy - 2, 4, 4)
		end
	else
		-- Normalny celownik
		local scale = 0.3
		surface.SetDrawColor(100, 0, 100, 255) -- Ciemny fiolet dla 106
		
		local gap = 5
		local length = gap + 20 * scale
		surface.DrawLine( x - length, y, x - gap, y )
		surface.DrawLine( x + length, y, x + gap, y )
		surface.DrawLine( x, y - length, x, y - gap )
		surface.DrawLine( x, y + length, x, y + gap )
	end
end

function SWEP:IsInTable( tab, element )
	for k, v in pairs( tab ) do
		if v.ply == element then return true end
	end
	return false
end