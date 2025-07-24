AddCSLuaFile()

SWEP.Base 				= "weapon_scp_base"
SWEP.PrintName			= "SCP096"

SWEP.DrawCrosshair		= true
SWEP.ViewModel			= "models/weapons/v_arms_scp096.mdl"

SWEP.Primary.Sound 		= "weapons/scp96/attack1.wav"
SWEP.HoldType 			= "knife"

SWEP.NextAttackW		= 0
SWEP.IsWatched			= false

if CLIENT then
	SWEP.WepSelectIcon	= surface.GetTextureID( "vgui/entities/weapon_scp096" )
end

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_096" )

    self:SetHoldType( self.HoldType )
		
	sound.Add( { name = "096_1", channel = CHAN_STATIC, volume = 1.0, level = 80, pitch = { 95, 110 }, sound = "weapons/scp96/096_1.mp3" } )
	sound.Add( { name = "096_2", channel = CHAN_STATIC, volume = 1.0, level = 80, pitch = { 95, 110 }, sound = "weapons/scp96/096_2.mp3" } )
	sound.Add( { name = "096_3", channel = CHAN_STATIC, volume = 1.0, level = 80, pitch = { 95, 110 }, sound = "weapons/scp96/096_3.mp3" } )
	
	util.PrecacheSound("096_1")
	util.PrecacheSound("096_2")
	util.PrecacheSound("096_3")
	util.PrecacheSound("weapons/scp96/attack1.wav")
	util.PrecacheSound("weapons/scp96/attack2.wav")
	util.PrecacheSound("weapons/scp96/attack3.wav")
	util.PrecacheSound("weapons/scp96/attack4.wav")
	util.PrecacheSound("weapons/scp96/096_idle1.wav")
	util.PrecacheSound("weapons/scp96/096_idle2.wav")
	util.PrecacheSound("weapons/scp96/096_idle3.wav")
end

function SWEP:IsLookingAt( ply )
	local yes = ply:GetAimVector():Dot( ( self.Owner:GetPos() - ply:GetPos() + Vector( 70 ) ):GetNormalized() )
	return yes > 0.39
end

SWEP.NextIdle = 0
function SWEP:Think()
	if self.NextIdle < CurTime() then
		self:SendWeaponAnim( ACT_VM_IDLE )
		self.NextIdle = CurTime() + self:SequenceDuration( ACT_VM_IDLE )
	end
	if postround then return end
	local watching = 0
	for k,v in pairs(player.GetAll()) do
		if IsValid(v) and v:GTeam() != TEAM_SPEC and v:Alive() and v != self.Owner and v.canblink then
			local tr_eyes = util.TraceLine( {
				start = v:EyePos() + v:EyeAngles():Forward() * 15,
				//start = v:LocalToWorld( v:OBBCenter() ),
				//start = v:GetPos() + (self.Owner:EyeAngles():Forward() * 5000),
				endpos = self.Owner:EyePos(),
				//filter = v
			} )
			local tr_center = util.TraceLine( {
				start = v:LocalToWorld( v:OBBCenter() ),
				endpos = self.Owner:LocalToWorld( self.Owner:OBBCenter() ),
				filter = v
			} )
			if tr_eyes.Entity == self.Owner or tr_center.Entity == self.Owner then
				//self.Owner:PrintMessage(HUD_PRINTTALK, tostring(tr_eyes.Entity) .. " : " .. tostring(tr_center.Entity) .. " : " .. tostring(tr_center.Entity))
				if self:IsLookingAt( v ) and v.isblinking == false then
					watching = watching + 1
					//if self:GetPos():Distance(v:GetPos()) > 100 then
						//self.Owner:PrintMessage(HUD_PRINTTALK, v:Nick() .. " is looking at you")
					//end 
				end
			end
		end
	end
	
	self.IsWatched = watching > 0
	
	if self.basestats then
		if watching > 0 then
			self.Owner:SetRunSpeed( self.basestats.fast )
			self.Owner:SetWalkSpeed( self.basestats.fast )
		else
			self.Owner:SetRunSpeed( self.basestats.slow )
			self.Owner:SetWalkSpeed( self.basestats.slow )
		end
	end
end

function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if self.NextAttackW > CurTime() then return end
	
	-- Ustaw cooldown na początku dla wszystkich ataków
	self.NextAttackW = CurTime() + 1.25

	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self.NextIdle = CurTime() + 0.7
	
	if SERVER then
		local trace = self.Owner:GetEyeTrace()
		local tr = util.TraceHull( {
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 125,
			filter = { self, self.Owner },
			mins = Vector( -15, -15, -15 ),
			maxs = Vector( 15, 15, 15 ),
			mask = MASK_SHOT_HULL
		} )

		local ent = tr.Entity
		
		if IsValid( ent ) then
			if ent:IsPlayer() then
				if ent:GTeam() == TEAM_SCP and ent:GetNClass() != ROLES.ROLE_SCP035 then return end
				if ent:GTeam() == TEAM_SPEC then return end
				ent:TakeDamage(math.random(60, 100), self.Owner, self.Owner)
			else
				-- Możliwość niszczenia drzwi gdy ktoś się patrzy
				if self.IsWatched and (ent:GetClass() == "func_door" or ent:GetClass() == "func_door_rotating" or ent:GetClass() == "prop_dynamic") then
					-- Znajdź wszystkie powiązane entity drzwi w okolicy
					local doorPos = ent:GetPos()
					local doorsToRemove = {}
					
					-- Dodaj trafioną entity
					table.insert(doorsToRemove, ent)
					
					-- Szukaj innych części drzwi w promieniu 100 jednostek
					for _, nearEnt in pairs(ents.FindInSphere(doorPos, 100)) do
						if IsValid(nearEnt) and nearEnt != ent then
							local class = nearEnt:GetClass()
							if class == "func_door" or class == "func_door_rotating" or class == "prop_dynamic" then
								-- Sprawdź czy entity są blisko siebie (prawdopodobnie część tych samych drzwi)
								if nearEnt:GetPos():Distance(doorPos) < 50 then
									table.insert(doorsToRemove, nearEnt)
								end
							end
						end
					end
					
					-- Usuń wszystkie znalezione części drzwi
					for _, door in pairs(doorsToRemove) do
						if IsValid(door) then
							door:Remove()
						end
					end
					
					-- Efekt dźwiękowy
					self.Owner:EmitSound("physics/wood/wood_crate_break"..math.random(1,5)..".wav", 100, math.random(90, 110))
					-- Efekt wizualny
					local effectdata = EffectData()
					effectdata:SetOrigin(tr.HitPos)
					effectdata:SetNormal(tr.HitNormal)
					util.Effect("ManhackSparks", effectdata)
				else
					self:SCPDamageEvent( ent, 10 )
				end
			end
		end
	end
end

function SWEP:Deploy()
	if self.Owner:IsValid() then
		if SERVER and !self.basestats then
			self.basestats = {
				slow = self.Owner:GetWalkSpeed(),
				fast = self.Owner:GetRunSpeed()
			}
		end

		self.Owner:SetRunSpeed( self.Owner:GetWalkSpeed() )

		self.Owner:DrawWorldModel( false )
		self.Weapon:EmitSound( "weapons/scp96/096_idle"..math.random(1,3)..".wav" )
		
		self:SendWeaponAnim( ACT_VM_DRAW )

		self.NextIdle = CurTime() + self:SequenceDuration( ACT_VM_DRAW )
	end
end

SWEP.NextSpecial = 0
function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextSpecial > CurTime() then return end
	self.NextSpecial = CurTime() + 60 -- Cooldown 60 sekund

	if SERVER then
		-- Znajdź najbliższego gracza w zasięgu 200 jednostek
		local nearbyPlayers = {}
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply != self.Owner and ply:Alive() then
				if ply:GTeam() != TEAM_SCP and ply:GTeam() != TEAM_SPEC then
					local dist = ply:GetPos():Distance(self.Owner:GetPos())
					if dist <= 200 then
						table.insert(nearbyPlayers, ply)
					end
				end
			end
		end
		
		-- Jeśli są gracze w pobliżu
		if #nearbyPlayers > 0 then
			-- Krzyk
			self.Owner:EmitSound("096_"..math.random(1,3))
			
			-- Dla każdego gracza w pobliżu
			for _, ply in pairs(nearbyPlayers) do
				-- 50% szans na wyrzucenie broni
				if math.random() <= 0.5 then
					local wep = ply:GetActiveWeapon()
					if IsValid(wep) then
						local class = wep:GetClass()
						-- Nie wyrzucaj br_id i br_holster
						if class != "br_id" and class != "br_holster" then
							ply:DropWeapon(wep)
							

						end
					end
				end
			end
		else
			-- Jeśli nikogo nie ma w pobliżu, tylko krzyk
			self.Owner:EmitSound("096_"..math.random(1,3))
		end
	end
end

-- HUD
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
	local titleW, titleH = surface.GetTextSize("SCP-096")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-096")
	
	-- Cooldowny (LMB i RMB)
	local cooldownY = hudY + 60
	local barWidth = 180
	local barHeight = 8
	local spacing = 60
	local totalWidth = barWidth * 2 + spacing
	local startX = centerX - totalWidth / 2
	
	-- LMB Cooldown
	local lmbBarX = startX
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(lmbBarX, cooldownY - 15)
	surface.DrawText("LMB - Attack")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
	
	local attackCooldown = 0
	if self.NextAttackW and self.NextAttackW > CurTime() then
		attackCooldown = self.NextAttackW - CurTime()
	end
	
	-- Pokaż cooldown
	if attackCooldown > 0 then
		local progress = 1 - (attackCooldown / 1.25)
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
	
	-- RMB Cooldown (Disarm)
	local rmbBarX = startX + barWidth + spacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rmbBarX, cooldownY - 15)
	surface.DrawText("RMB - Scream")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
	
	local screamCooldown = 0
	if self.NextSpecial and self.NextSpecial > CurTime() then
		screamCooldown = self.NextSpecial - CurTime()
	end
	
	if screamCooldown > 0 then
		local progress = 1 - (screamCooldown / 60)
		surface.SetDrawColor(255, 255, 0, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 255, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", screamCooldown))
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
	surface.SetDrawColor(200, 100, 100, 255)
	
	local gap = 5
	local length = gap + 20 * scale
	surface.DrawLine( x - length, y, x - gap, y )
	surface.DrawLine( x + length, y, x + gap, y )
	surface.DrawLine( x, y - length, x, y - gap )
	surface.DrawLine( x, y + length, x, y + gap )
end