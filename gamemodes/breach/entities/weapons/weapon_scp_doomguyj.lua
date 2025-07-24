AddCSLuaFile()

SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-DOOMGUY-J"

SWEP.ViewModelFOV = 90
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_crucible.mdl"
SWEP.WorldModel = "models/weapons/w_crucible.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true
SWEP.HoldType = "melee2"

SWEP.DrawCrosshair = true

SWEP.Primary.Delay = 1.5
SWEP.Primary.DelayHit = 0.35
SWEP.Primary.Damage = 85
SWEP.Primary.Force = 1000
SWEP.Primary.Range = 100

SWEP.Secondary.Delay = 5
SWEP.Secondary.Damage = 125
SWEP.Secondary.Force = 1500
SWEP.Secondary.Range = 120

SWEP.NextPrimary = 0
SWEP.NextSecondary = 0
SWEP.Idle = 0
SWEP.IdleTimer = 0

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_DOOMGUYJ" )
	self:SetHoldType(self.HoldType)
	self:SetWeaponHoldType(self.HoldType)
	
	self.Idle = 0
	self.IdleTimer = CurTime() + 1
	
	-- Inicjalizacja dźwięków dla broni
	if SERVER then
		util.AddNetworkString("DOOMGUYJ_PlaySound")
	end
end

function SWEP:Deploy()
	self.Idle = 0
	self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
	self:SendWeaponAnim( ACT_VM_DRAW )
	
	-- Dźwięk wyciągania broni
	if SERVER then
		self.Owner:EmitSound( "weapons/tfa_kf2/crucible/WPN_LS_Equip_01.wav", 50 )
	end
	
	-- Pętla dźwięku
	if CLIENT then
		self.NoiseLoop = CreateSound( self.Owner, Sound( "weapons/tfa_kf2/crucible/wpn_ls_idle_01_lpm.wav" ) )
		if ( self.NoiseLoop ) then 
			self.NoiseLoop:Play() 
			self.NoiseLoop:ChangeVolume( 0.6, 0.1 ) 
		end
	end
	
	return true
end

function SWEP:Holster()
	self.Idle = 0
	self.IdleTimer = CurTime()
	
	if !IsValid(self.Owner) then return false end
	
	-- Zatrzymaj pętlę dźwięku
	if CLIENT and self.NoiseLoop then 
		self.NoiseLoop:Stop() 
		self.NoiseLoop = nil 
	end
	
	-- Dźwięk chowania
	if SERVER then
		self.Owner:EmitSound( "weapons/tfa_kf2/crucible/WPN_LS_UnEquip_01.wav", 50 )
	end
	
	return true
end

function SWEP:OnRemove()
	self:Holster()
end

function SWEP:GetViewModelPosition (pos, ang, inv)
	local DefPos = Vector(0,0,0)
	local DefAng = Vector(9,10,-15)
	
	if DefAng then
		ang = ang * 1
		ang:RotateAroundAxis (ang:Right(), DefAng.x)
		ang:RotateAroundAxis (ang:Up(), DefAng.y)
		ang:RotateAroundAxis (ang:Forward(), DefAng.z)
	end

	if DefPos then
		local Right = ang:Right()
		local Up = ang:Up()
		local Forward = ang:Forward()
	
		pos = pos + DefPos.x * Right
		pos = pos + DefPos.y * Forward
		pos = pos + DefPos.z * Up
	end
	
	return pos, ang
end

function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if self.NextPrimary > CurTime() then return end
	
	local swinganims = {ACT_VM_HITLEFT, ACT_VM_HITRIGHT, ACT_VM_PRIMARYATTACK}
	self:SendWeaponAnim(swinganims[math.random(#swinganims)])
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	
	-- Dźwięk zamachu
	self:EmitSound( "TFA_crucible.Swing" )
	
	-- Zwiększ głośność pętli podczas ataku
	if CLIENT and self.NoiseLoop then 
		self.NoiseLoop:ChangeVolume( 0.7, 0.1 ) 
	end
	
	self.Idle = 0
	self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
	
	-- Opóźnione trafienie
	timer.Simple(0.2, function()
		if !IsValid(self) then return end
		if !IsValid(self.Owner) then return end
		if !IsValid(self.Owner:GetActiveWeapon()) then return end
		if self.Owner:GetActiveWeapon() ~= self then return end
		
		self:PerformMeleeAttack(self.Primary.Damage, self.Primary.Range, self.Primary.Force)
	end)
	
	-- Ustaw następny możliwy atak
	self.NextPrimary = CurTime() + self.Primary.Delay
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
end

function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if self.NextSecondary > CurTime() then return end
	
	-- Silniejszy atak
	self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	
	-- Dźwięk zamachu
	self:EmitSound( "TFA_crucible.Swing" )
	
	-- Zwiększ głośność pętli podczas ataku
	if CLIENT and self.NoiseLoop then 
		self.NoiseLoop:ChangeVolume( 0.7, 0.1 ) 
	end
	
	self.Idle = 0
	self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
	
	-- Opóźnione trafienie
	timer.Simple(0.4, function()
		if !IsValid(self) then return end
		if !IsValid(self.Owner) then return end
		if !IsValid(self.Owner:GetActiveWeapon()) then return end
		if self.Owner:GetActiveWeapon() ~= self then return end
		
		self:PerformMeleeAttack(self.Secondary.Damage, self.Secondary.Range, self.Secondary.Force)
	end)
	
	-- Ustaw następny możliwy atak
	self.NextSecondary = CurTime() + self.Secondary.Delay
	self:SetNextPrimaryFire( CurTime() + self.Secondary.Delay )
	self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
end

function SWEP:PerformMeleeAttack(damage, range, force)
	if !SERVER then return end
	
	local tr = util.TraceLine( {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * range,
		filter = self.Owner,
		mask = MASK_SHOT
	} )
	
	if !tr.Hit then
		tr = util.TraceHull( {
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * range,
			filter = self.Owner,
			mins = Vector( -16, -16, 0 ),
			maxs = Vector( 16, 16, 0 ),
			mask = MASK_SHOT
		} )
	end
	
	if tr.Hit then
		-- Efekt trafienia
		local effectdata = EffectData()
		effectdata:SetOrigin(tr.HitPos)
		effectdata:SetNormal(tr.HitNormal)
		util.Effect("cball_explode", effectdata)
		
		-- Dźwięk uderzenia
		sound.Play("weapons/tfa_kf2/crucible/shock_impact.wav", tr.HitPos + tr.HitNormal*5, 75)
		
		if IsValid(tr.Entity) then
			-- Sprawdź czy cel to SCP - ale SCP-035 może być atakowany!
			if tr.Entity:IsPlayer() and tr.Entity:GTeam() == TEAM_SCP and tr.Entity:GetNClass() != ROLES.ROLE_SCP035 then
				-- Efekt wizualny bez obrażeń dla normalnych SCP (ale nie SCP-035)
				local spark = EffectData()
				spark:SetOrigin(tr.HitPos)
				spark:SetNormal(tr.HitNormal)
				util.Effect("StunstickImpact", spark)
				
				self.Owner:EmitSound( "TFA_crucible.HitWorld" )
				print("[DOOMGUY DEBUG] Blocked damage to SCP (not SCP-035): " .. tr.Entity:Nick() .. " (" .. tostring(tr.Entity:GetNClass()) .. ")")
			else
				-- Normalnie zadaj obrażenia nie-SCP
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(damage)
				dmginfo:SetDamageType(DMG_SLASH)
				dmginfo:SetAttacker(self.Owner)
				dmginfo:SetInflictor(self)
				dmginfo:SetDamagePosition(tr.HitPos)
				dmginfo:SetDamageForce( self.Owner:GetAimVector() * force )
				
				-- Modyfikuj obrażenia w zależności od trafionej części ciała
				if tr.Entity:IsPlayer() or tr.Entity:IsNPC() then
					local finalDamage = damage
					
					if tr.HitGroup == HITGROUP_HEAD then
						finalDamage = damage * 1.5
					elseif tr.HitGroup == HITGROUP_CHEST or tr.HitGroup == HITGROUP_STOMACH then
						finalDamage = damage
					else
						finalDamage = damage * 0.75
					end
					
					dmginfo:SetDamage(finalDamage)
					
					-- Dźwięk trafienia w cel organiczny
					self.Owner:EmitSound( "TFA_crucible.HitFlesh" )
					
					-- Ukryte leczenie przy trafieniu
					self:HealOnHit()
				else
					-- Dźwięk trafienia w świat
					self.Owner:EmitSound( "TFA_crucible.HitWorld" )
				end
				
				tr.Entity:TakeDamageInfo( dmginfo )
				
				-- Wywołaj event obrażeń SCP
				self:SCPDamageEvent( tr.Entity, dmginfo:GetDamage() )
			end
		else
			-- Obrażenia obszarowe jeśli nie trafiliśmy bezpośrednio
			util.BlastDamage(self, self.Owner, tr.HitPos, 32, damage * 0.5)
		end
		
		-- Szybsze ataki po trafieniu
		self.NextPrimary = CurTime() + self.Primary.DelayHit
		self.NextSecondary = CurTime() + self.Primary.DelayHit
	else
		-- Wolniejsze ataki po chybieniu
		self.NextPrimary = CurTime() + self.Primary.Delay
		self.NextSecondary = CurTime() + self.Secondary.Delay
	end
end

-- Ukryta funkcja leczenia przy trafieniu
function SWEP:HealOnHit()
	if not SERVER then return end
	if not IsValid(self.Owner) then return end
	
	local currentHP = self.Owner:Health()
	local maxHP = self.Owner:GetMaxHealth()
	local hpPercent = currentHP / maxHP
	
	-- Oblicz leczenie - im mniej HP, tym więcej leczy
	local healAmount
	if hpPercent <= 0.25 then
		-- Poniżej 25% HP - leczy 30-40 HP
		healAmount = math.random(30, 40)
	elseif hpPercent <= 0.5 then
		-- Poniżej 50% HP - leczy 20-30 HP
		healAmount = math.random(20, 30)
	elseif hpPercent <= 0.75 then
		-- Poniżej 75% HP - leczy 10-20 HP
		healAmount = math.random(10, 20)
	else
		-- Powyżej 75% HP - leczy 5-10 HP
		healAmount = math.random(5, 10)
	end
	
	-- Zastosuj leczenie
	if currentHP < maxHP then
		local newHP = math.min(currentHP + healAmount, maxHP)
		self.Owner:SetHealth(newHP)
		
		-- DEBUG (opcjonalnie)
		-- print("[DOOMGUY] Healed: " .. currentHP .. " -> " .. newHP .. " (+" .. healAmount .. " HP)")
	end
end

function SWEP:Think()
	-- Wywołaj Think z klasy bazowej
	if self.BaseClass and self.BaseClass.Think then
		self.BaseClass.Think(self)
	end
	
	-- Animacja idle
	if self.Idle == 0 and self.IdleTimer <= CurTime() then
		if SERVER then
			self:SendWeaponAnim( ACT_VM_IDLE )
		end
		self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
	end
	
	-- Przywróć normalną głośność pętli
	if CLIENT and self.NoiseLoop then 
		self.NoiseLoop:ChangeVolume( 0.6, 0.1 ) 
	end
end

function SWEP:DoImpactEffect( tr )
	if tr.HitSky then return end
	
	local effect = EffectData()
	effect:SetOrigin(tr.HitPos)
	effect:SetNormal( tr.HitNormal )
	util.Effect("cball_explode", effect)
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
		local titleW, titleH = surface.GetTextSize("SCP-DOOMGUY-J")
		surface.SetTextPos(centerX - titleW / 2, hudY + 10)
		surface.DrawText("SCP-DOOMGUY-J")
		
		-- Cooldowny
		local lpmCooldown = 0
		local ppmCooldown = 0
		
		if self.NextPrimary and self.NextPrimary > CurTime() then
			lpmCooldown = self.NextPrimary - CurTime()
		end
		
		if self.NextSecondary and self.NextSecondary > CurTime() then
			ppmCooldown = self.NextSecondary - CurTime()
		end
		
		local cooldownY = hudY + 60
		local barWidth = 120
		local barHeight = 8
		local barSpacing = 20
		
		-- LMB (Light Attack) Cooldown
		local lpmBarX = centerX - barWidth - barSpacing
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		surface.SetTextPos(lpmBarX, cooldownY - 15)
		surface.DrawText("LMB - Light")
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(lpmBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
		
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(lpmBarX, cooldownY, barWidth, barHeight)
		
		if lpmCooldown > 0 then
			local progress = 1 - (lpmCooldown / self.Primary.Delay)
			surface.SetDrawColor(255, 100, 100, 255)
			surface.DrawRect(lpmBarX, cooldownY, barWidth * progress, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(255, 150, 150, 255)
			surface.SetTextPos(lpmBarX, cooldownY + 10)
			surface.DrawText(string.format("%.1fs", lpmCooldown))
		else
			surface.SetDrawColor(100, 255, 100, 255)
			surface.DrawRect(lpmBarX, cooldownY, barWidth, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(150, 255, 150, 255)
			surface.SetTextPos(lpmBarX, cooldownY + 10)
			surface.DrawText("READY")
		end
		
		-- RMB (Heavy Attack) Cooldown
		local ppmBarX = centerX + barSpacing
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		surface.SetTextPos(ppmBarX, cooldownY - 15)
		surface.DrawText("RMB - Heavy")
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(ppmBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
		
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(ppmBarX, cooldownY, barWidth, barHeight)
		
		if ppmCooldown > 0 then
			local progress = 1 - (ppmCooldown / self.Secondary.Delay)
			surface.SetDrawColor(255, 215, 0, 255)
			surface.DrawRect(ppmBarX, cooldownY, barWidth * progress, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(255, 255, 150, 255)
			surface.SetTextPos(ppmBarX, cooldownY + 10)
			surface.DrawText(string.format("%.1fs", ppmCooldown))
		else
			surface.SetDrawColor(100, 255, 100, 255)
			surface.DrawRect(ppmBarX, cooldownY, barWidth, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(150, 255, 150, 255)
			surface.SetTextPos(ppmBarX, cooldownY + 10)
			surface.DrawText("READY")
		end
		
	end
	
end