AddCSLuaFile()

SWEP.Base 			= "weapon_scp_base"
SWEP.PrintName		= "SCP-682"

SWEP.HoldType			= "normal"

SWEP.Roar 				= "scp/682/roar.ogg"

SWEP.DrawCrosshair 			= true

--SWEP.SantasHatPositionOffset = Vector( 16, -5, 3.5 )
--SWEP.SantasHatAngleOffset = Angle( -10, 180, -20 )

function SWEP:Deploy()
	self:HideModels()

	if SERVER and !self.basespeed then
		self.basespeed = self.Owner:GetWalkSpeed()
		self.furyspeed = self.Owner:GetRunSpeed()
		self.Owner:SetRunSpeed( self.basespeed )
	end

	//self.Owner:SetModelScale( 0.75 )
end

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_682" )

	self:SetHoldType(self.HoldType)
	/*if CLIENT then
		if !self.SantasHat then
			self.SantasHat = ClientsideModel( "models/cloud/kn_santahat.mdl" )
			self.SantasHat:SetModelScale( 1.8 )
			self.SantasHat:SetNoDraw( true )
		end
	end*/
end

function SWEP:OnRemove()
	//if IsValid( self.Owner ) then
		//self.Owner:SetModelScale( 1 )
	//end
	/*if CLIENT and IsValid( self.SantasHat ) then
		self.SantasHat:Remove()
	end*/
end

SWEP.NextAttackW	= 0
SWEP.AttackDelay	= 4
SWEP.OnFuryCD = 0.7
function SWEP:PrimaryAttack()
	if preparing then return end
	if not IsFirstTimePredicted() then return end
	if self.NextAttackW > CurTime() then return end
	if CLIENT then return end
	local ent = nil
	local tr = util.TraceHull({
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + (self.Owner:GetAimVector() * 75),
		mins = Vector(-10, -10, -10),
		maxs = Vector(10, 10, 10),
		filter = self.Owner,
		mask = MASK_SHOT,
	})
	ent = tr.Entity
	if IsValid(ent) then
		if ent:IsPlayer() then
			if ent:GTeam() == TEAM_SPEC or (ent:GTeam() == TEAM_SCP and ent:GetNClass() != ROLES.ROLE_SCP035) then return end
				local rdmdmg = math.random(50, 100)
				ent:TakeDamage(rdmdmg, self.Owner, self.Owner)
			--ent:Kill()
			--self.Owner:AddExp(15, true)
			if self.fury == true then
				self.NextAttackW = CurTime() + self.OnFuryCD
			else
				self.NextAttackW = CurTime() + self.AttackDelay
				self:EmitSound( self.Roar )
			end
			self:SetNWFloat("NextAttackW", self.NextAttackW) -- Synchronizuj z klientem
		else
			self:SCPDamageEvent( ent, 10 )
		end
	end
end

SWEP.NextSpeial = 0
SWEP.SpecialDelay = 45
SWEP.fury = false
function SWEP:SecondaryAttack()
	if self.NextSpeial > CurTime() then
		if SERVER then
			self.Owner:PrintMessage(HUD_PRINTTALK, "Special ability is on cooldown!")
		end
		return
	end
	self.NextSpeial = CurTime() + self.SpecialDelay
	self:SetNWFloat("NextSpecial", self.NextSpeial) -- Synchronizuj z klientem
	
	if SERVER then
		local hp = self:ApplyEffect()
		timer.Create( "682BuffEnd"..self.Owner:SteamID64(), 7, 1, function()
			self:RemoveEffect( hp, 0 )
		end )
	end
end

function SWEP:ApplyEffect()
	self.fury = true
	self:SetNWBool("IsFury", true) -- Synchronizuj status fury
	self.NextAttackW = CurTime() + 0.5
	self:SetNWFloat("NextAttackW", self.NextAttackW)
	self:EmitSound( self.Roar )
	self.Owner:SetWalkSpeed(self.furyspeed)
	self.Owner:SetRunSpeed(self.furyspeed)
	local hp = self.Owner:Health()
	self.Owner:SetHealth( 9999 )
	return hp
end

function SWEP:RemoveEffect( hp, regen )
	self.fury = false
	self:SetNWBool("IsFury", false) -- Synchronizuj status fury
	self.Owner:SetWalkSpeed(self.basespeed)
	self.Owner:SetRunSpeed(self.basespeed)
	hp = hp + regen
	if hp > self.Owner:GetMaxHealth() then hp = self.Owner:GetMaxHealth() end
	self.Owner:SetHealth( hp )
end

hook.Add("EntityTakeDamage", "AcidDamage", function(target, dmg)
	if !target or !target:IsPlayer() or !target:Alive() then return end
	if !IsValid( target:GetActiveWeapon() ) or target:GetActiveWeapon():GetClass() != "weapon_scp_682" then return end
	if dmg:GetDamageType() == DMG_ACID then
		if preparing then return true end
		dmg:ScaleDamage( 3 )
	end
end)

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
	local titleW, titleH = surface.GetTextSize("SCP-682")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-682")
	
	-- Status Fury
	local isFury = self:GetNWBool("IsFury", false)
	if isFury then
		surface.SetFont("DermaDefaultBold")
		surface.SetTextColor(255, 0, 0, 255)
		local furyText = "FURY MODE ACTIVE"
		local furyW, furyH = surface.GetTextSize(furyText)
		surface.SetTextPos(centerX - furyW / 2, hudY + 95)
		surface.DrawText(furyText)
	end
	
	-- Cooldowny
	local cooldownY = hudY + 60
	local barWidth = 210  -- Szersze paski bo tylko 2
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
	local nextAttack = self:GetNWFloat("NextAttackW", 0)
	if nextAttack > CurTime() then
		attackCooldown = nextAttack - CurTime()
	end
	
	if attackCooldown > 0 then
		local maxCooldown = isFury and self.OnFuryCD or self.AttackDelay
		local progress = 1 - (attackCooldown / maxCooldown)
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
	
	-- RMB Cooldown (Fury)
	local rmbBarX = startX + barWidth + spacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rmbBarX, cooldownY - 15)
	surface.DrawText("RMB - Fury")
	
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
		surface.SetDrawColor(255, 0, 0, 255) -- Czerwony dla fury
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 150, 150, 255)
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
	
	-- Celownik
	local x = ScrW() / 2.0
	local y = ScrH() / 2.0
	
	local scale = 0.3
	-- Czerwony celownik gdy fury aktywne
	if isFury then
		surface.SetDrawColor(255, 0, 0, 255)
	else
		surface.SetDrawColor(0, 255, 0, 255)
	end
	
	local gap = 5
	local length = gap + 20 * scale
	surface.DrawLine( x - length, y, x - gap, y )
	surface.DrawLine( x + length, y, x + gap, y )
	surface.DrawLine( x, y - length, x, y - gap )
	surface.DrawLine( x, y + length, x, y + gap )
end

function SWEP:DrawWorldModel()
	/*if !IsValid( self.SantasHat ) then return end
	local boneid = self.Owner:LookupBone( "Bip01_Head" )
	if not boneid then
		for i=0, self.Owner:GetBoneCount()-1 do
			print( i, self.Owner:GetBoneName( i ) )
		end
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
	self.SantasHat:DrawModel()*/
end