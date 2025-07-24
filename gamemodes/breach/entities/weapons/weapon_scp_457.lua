AddCSLuaFile()

SWEP.Base 		= "weapon_scp_base"
SWEP.PrintName	= "SCP-457"

SWEP.HoldType	= "normal"

if CLIENT then
	SWEP.WepSelectIcon 	= surface.GetTextureID("breach/wep_457")
end

-- Właściwości
SWEP.droppable = false

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_457" )
	self:SetHoldType(self.HoldType)
end

-- Zmienne
SWEP.NextAttackW = 0
SWEP.AttackDelay = 0.5
SWEP.NextSpecial = 0
SWEP.SpecialDelay = 20
SWEP.NextUltimate = 0
SWEP.UltimateDelay = 45
SWEP.FireWallDuration = 8

SWEP.LastDMG = 0
SWEP.NextBurn = 0
function SWEP:Think()
	if SERVER then
		-- Obrażenia w wodzie
		if self.Owner:WaterLevel() > 0 then
			if self.LastDMG < CurTime() and self.Owner:Health() > 1 then
				self.LastDMG = CurTime() + 0.1
				self.Owner:SetHealth( math.max( 1, self.Owner:Health() - 20 ) )
			end
		else
			-- Pasywne palenie w małym zasięgu
			if self.NextBurn < CurTime() then
				self.NextBurn = CurTime() + 0.5
				
				for k,v in pairs(ents.FindInSphere( self.Owner:GetPos(), 125 )) do
					if v:IsPlayer() and v:Alive() then
						if v:GTeam() != TEAM_SCP and v:GTeam() != TEAM_SPEC then
							v:Ignite(2, 0)
							
							-- Regeneracja
							if self.Owner.nextexp == nil then self.Owner.nextexp = 0 end
							if self.Owner.nextexp < CurTime() then
								self.Owner:SetHealth( math.Clamp( self.Owner:Health() + 20, 0, self.Owner:GetMaxHealth() ) )
								self.Owner:AddExp(5)
								self.Owner.nextexp = CurTime() + 1
							end
						end
					end
				end
			end
		end
	end
end

-- LMB - Podstawowy atak ogniem
function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextAttackW > CurTime() then return end
	
	self.NextAttackW = CurTime() + self.AttackDelay
	self:SetNWFloat("NextAttackW", self.NextAttackW)
	
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
			if ent:IsPlayer() then
				if ent:GTeam() == TEAM_SCP and ent:GetNClass() != ROLES.ROLE_SCP035 then return end
				if ent:GTeam() == TEAM_SPEC then return end
				ent:Ignite(5, 0)
				ent:TakeDamage(35, self.Owner, self)
				self.Owner:AddExp(15, true)
			else
				self:SCPDamageEvent( ent, 10 )
			end
		end
	end
end

-- RMB - Rzut kulą ognia
function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextSpecial > CurTime() then return end
	
	self.NextSpecial = CurTime() + self.SpecialDelay
	self:SetNWFloat("NextSpecial", self.NextSpecial)
	
	if SERVER then
		-- Stwórz kulę ognia
		local fireball = ents.Create("prop_physics")
		if IsValid(fireball) then
			fireball:SetModel("models/props_junk/flare.mdl")
			fireball:SetPos(self.Owner:GetShootPos() + self.Owner:GetAimVector() * 40)
			fireball:SetAngles(self.Owner:EyeAngles())
			fireball:SetOwner(self.Owner)
			fireball:Spawn()
			fireball:SetColor(Color(255, 100, 0))
			fireball:SetMaterial("models/debug/debugwhite")
			fireball:SetModelScale(2)
			fireball:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
			
			-- Nadaj prędkość
			local phys = fireball:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetVelocity(self.Owner:GetAimVector() * 1500)
				phys:SetMass(1)
				phys:EnableGravity(false)
			end
			
			-- Efekt ognia
			local fire = ents.Create("env_fire")
			fire:SetPos(fireball:GetPos())
			fire:SetParent(fireball)
			fire:SetKeyValue("health", "5")
			fire:SetKeyValue("firesize", "64")
			fire:Spawn()
			fire:Fire("StartFire")
			
			-- Funkcja eksplozji
			local function ExplodeFireball()
				if not IsValid(fireball) then return end
				
				-- Eksplozja
				local effectdata = EffectData()
				effectdata:SetOrigin(fireball:GetPos())
				effectdata:SetScale(2)
				util.Effect("Explosion", effectdata)
				
				-- Zadaj obrażenia i podpal
				for _, ent in pairs(ents.FindInSphere(fireball:GetPos(), 200)) do
					if ent:IsPlayer() and ent:GTeam() != TEAM_SCP and ent:GTeam() != TEAM_SPEC then
						ent:TakeDamage(50, self.Owner, self)
						ent:Ignite(4, 0)
					end
				end
				
				-- Dźwięk
				fireball:EmitSound("ambient/explosions/explode_4.wav", 100, 120)
				
				-- Usuń
				if IsValid(fire) then fire:Remove() end
				fireball:Remove()
			end
			
			-- Eksploduj przy kontakcie
			fireball:AddCallback("PhysicsCollide", function(ent, data)
				if data.HitEntity != self.Owner then
					ExplodeFireball()
				end
			end)
			
			-- Eksploduj po czasie
			timer.Simple(3, ExplodeFireball)
		end
		
		-- Dźwięk wystrzału
		self.Owner:EmitSound("weapons/flaregun/fire.wav", 90, 80)
	end
end

-- R - Ściana ognia
function SWEP:Reload()
	if not IsFirstTimePredicted() then return end
	if self.NextUltimate > CurTime() then return end
	
	self.NextUltimate = CurTime() + self.UltimateDelay
	
	if SERVER then
		self:SetNWFloat("NextUltimate", self.NextUltimate)
		
		-- Stwórz ścianę ognia przed sobą
		local startPos = self.Owner:GetPos() + self.Owner:GetAimVector() * 100
		local angles = self.Owner:EyeAngles()
		angles.p = 0
		local right = angles:Right()
		
		-- Stwórz linię ognia
		for i = -5, 5 do
			local firePos = startPos + right * (i * 40)
			
			-- Sprawdź czy jest podłoże
			local tr = util.TraceLine({
				start = firePos + Vector(0, 0, 50),
				endpos = firePos - Vector(0, 0, 100),
				filter = self.Owner
			})
			
			if tr.Hit then
				-- Stwórz ogień
				local fire = ents.Create("env_fire")
				if IsValid(fire) then
					fire:SetPos(tr.HitPos)
					fire:SetKeyValue("health", tostring(self.FireWallDuration))
					fire:SetKeyValue("firesize", "128")
					fire:SetKeyValue("fireattack", "3")
					fire:SetKeyValue("damagescale", "2")
					fire:Spawn()
					fire:Fire("StartFire")
					
					-- Zadawaj obrażenia co sekundę
					local burnTime = CurTime() + self.FireWallDuration
					timer.Create("FireWall_" .. fire:EntIndex(), 0.5, self.FireWallDuration * 2, function()
						if not IsValid(fire) then return end
						
						for _, ent in pairs(ents.FindInSphere(fire:GetPos(), 80)) do
							if ent:IsPlayer() and ent:GTeam() != TEAM_SCP and ent:GTeam() != TEAM_SPEC then
								ent:TakeDamage(15, IsValid(self.Owner) and self.Owner or fire, fire)
								ent:Ignite(2, 0)
							end
						end
						
						if CurTime() >= burnTime then
							fire:Remove()
						end
					end)
				end
			end
		end
		
		-- Dźwięk
		self.Owner:EmitSound("ambient/fire/ignite.wav", 110, 70)
		
		-- Efekt wizualny
		local effectdata = EffectData()
		effectdata:SetOrigin(startPos)
		effectdata:SetNormal(self.Owner:GetAimVector())
		effectdata:SetScale(3)
		util.Effect("ManhackSparks", effectdata)
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
	local titleW, titleH = surface.GetTextSize("SCP-457")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-457")
	
	-- Cooldowny
	local cooldownY = hudY + 60
	local barWidth = 140
	local barHeight = 8
	local spacing = 20
	local totalWidth = barWidth * 3 + spacing * 2
	local startX = centerX - totalWidth / 2
	
	-- LMB Cooldown
	local lmbBarX = startX
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(lmbBarX, cooldownY - 15)
	surface.DrawText("LMB - Burn")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
	
	local attackCooldown = 0
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
	
	-- RMB Cooldown
	local rmbBarX = startX + barWidth + spacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rmbBarX, cooldownY - 15)
	surface.DrawText("RMB - Fireball")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
	
	local specialCooldown = 0
	local nextSpecial = self:GetNWFloat("NextSpecial", 0)
	if nextSpecial > CurTime() then
		specialCooldown = nextSpecial - CurTime()
	end
	
	if specialCooldown > 0 then
		local progress = 1 - (specialCooldown / self.SpecialDelay)
		surface.SetDrawColor(255, 255, 0, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 255, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", specialCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- R Cooldown
	local rBarX = startX + (barWidth + spacing) * 2
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rBarX, cooldownY - 15)
	surface.DrawText("R - Fire Wall")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rBarX, cooldownY, barWidth, barHeight)
	
	local ultimateCooldown = 0
	local nextUltimate = self:GetNWFloat("NextUltimate", 0)
	if nextUltimate > CurTime() then
		ultimateCooldown = nextUltimate - CurTime()
	end
	
	if ultimateCooldown > 0 then
		local progress = 1 - (ultimateCooldown / self.UltimateDelay)
		surface.SetDrawColor(148, 0, 211, 255)
		surface.DrawRect(rBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(200, 150, 255, 255)
		surface.SetTextPos(rBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", ultimateCooldown))
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
	surface.SetDrawColor(255, 0, 0, 255)
	
	local gap = 5
	local length = gap + 20 * scale
	surface.DrawLine( x - length, y, x - gap, y )
	surface.DrawLine( x + length, y, x + gap, y )
	surface.DrawLine( x, y - length, x, y - gap )
	surface.DrawLine( x, y + length, x, y + gap )
end