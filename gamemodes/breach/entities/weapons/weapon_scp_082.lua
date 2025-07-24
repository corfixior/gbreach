AddCSLuaFile()

SWEP.Base 			= "weapon_scp_base"
SWEP.PrintName		= "SCP-082 Rework"

SWEP.ViewModel		= "models/weapons/scp082/v_machete.mdl"
SWEP.WorldModel		= "models/weapons/scp082/w_fc2_machete.mdl"

SWEP.Primary.Sound	= Sound( "scp/082/woosh.mp3" )
SWEP.KnifeShink 	= Sound( "scp/082/hitwall.mp3" )
SWEP.KnifeSlash 	= Sound( "scp/082/slash.mp3" )
SWEP.KnifeStab 		= Sound( "scp/082/nastystab.mp3" )

SWEP.HoldType 		= "melee"
SWEP.NextPrimary	= 0
SWEP.NextIdle 		= 0

-- Nowe zmienne
SWEP.NextPanic = 0
SWEP.PanicCooldown = 15 -- Cooldown paniki
SWEP.PanicDuration = 3 -- Czas trwania paniki
SWEP.PanicRange = 500 -- Zasięg paniki

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_082" )

	self:SetHoldType( self.HoldType )

	self:SendWeaponAnim( ACT_VM_DRAW )
	self.NextPrimary = CurTime() + 1.3
	self:EmitSound( "scp/082/knife_draw_x.mp3", 50, 100 )
	
	-- Networking
	if SERVER then
		util.AddNetworkString("SCP082_Panic")
		util.AddNetworkString("SCP082_Bleed")
		
		-- Hook do jedzenia ciał
		hook.Add("PlayerUse", "SCP082_EatCorpse_" .. self:EntIndex(), function(ply, ent)
			if ply == self.Owner and IsValid(ent) and ent:GetClass() == "prop_ragdoll" and ply:KeyDown(IN_USE) then
				local dist = ply:GetPos():Distance(ent:GetPos())
				if dist < 100 then
					self:EatCorpse(ent)
					return false
				end
			end
		end)
	end
	
	if CLIENT then
		self.WepSelectIcon = surface.GetTextureID("breach/wep_082")
	end
end

function SWEP:Deploy()
end

function SWEP:Think()
	self:PlayerFreeze()

	if self.NextIdle > CurTime() then return end
	self.NextIdle = CurTime() + self:SequenceDuration( ACT_VM_IDLE )
	self:SendWeaponAnim( ACT_VM_IDLE )
end

-- LMB - Atak z krwawieniem i spowolnieniem
function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if self.NextPrimary > CurTime() then return end
	self.NextPrimary = CurTime() + 1.75
	vm = self.Owner:GetViewModel()
	self.NextIdle = CurTime() + vm:SequenceDuration( vm:LookupSequence( "stab" ) )
	self.Owner:ViewPunch( Angle( -10,0,0 ) )
	self:EmitSound( self.Primary.Sound )
	if SERVER then
		vm:SetSequence( vm:LookupSequence( "stab" ) )
		timer.Create( "hack-n-slash", 0.3, 1, function()
			if IsValid( self ) and IsValid( self.Owner ) then
				if self.Owner:Alive() then 
					self:HackNSlash() 
				end
			end
		end )		
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
	end
end

function SWEP:HackNSlash()
	self.Owner:LagCompensation( true )
	local slash = {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 65,
		filter = self.Owner,
		mins = Vector( -8, -10, 5 ),
		maxs = Vector( 8, 10, 5 ),
	}
	local slashtrace = util.TraceHull( slash )
	
	if self.Owner:GetActiveWeapon():GetClass() == self:GetClass() then
		self.Owner:ViewPunch( Angle( 15, 0, 0 ) )
		local target = slashtrace.Entity
		if IsValid( target ) then
			if target:IsPlayer() then
				if target:GTeam() == TEAM_SPEC then return end
				if target:GTeam() == TEAM_SCP and target:GetNClass() != ROLES.ROLE_SCP035 then return end
				self:EmitSound( self.KnifeSlash )
				local dmg = math.random( 30, 60 )
				local paininfo = DamageInfo()
					paininfo:SetDamage( dmg )
					paininfo:SetDamageType( DMG_SLASH )
					paininfo:SetAttacker( self.Owner )
					paininfo:SetInflictor( self )
					paininfo:SetDamageForce( slashtrace.Normal * 3500 )
				target:TakeDamageInfo( paininfo )
				
				-- Heal 50 HP za trafienie
				local hp = self.Owner:Health() + 50
				if hp > self.Owner:GetMaxHealth() then hp = self.Owner:GetMaxHealth() end
				self.Owner:SetHealth( hp )
				
				-- Krwawienie
				net.Start("SCP082_Bleed")
				net.Send(target)
				
				-- Spowolnienie na sekundę
				local originalSpeed = target:GetRunSpeed()
				local originalWalk = target:GetWalkSpeed()
				target:SetRunSpeed(originalSpeed * 0.5)
				target:SetWalkSpeed(originalWalk * 0.5)
				
				timer.Create("SCP082_Slow_" .. target:SteamID(), 1, 1, function()
					if IsValid(target) then
						target:SetRunSpeed(originalSpeed)
						target:SetWalkSpeed(originalWalk)
					end
				end)
				
				-- Timer na krwawienie
				timer.Create("SCP082_Bleed_" .. target:SteamID(), 0.5, 10, function()
					if IsValid(target) and target:Alive() then
						target:TakeDamage(2, self.Owner, self)
					else
						timer.Remove("SCP082_Bleed_" .. target:SteamID())
					end
				end)
				
				-- Bonus heal za zabicie
				if target:Health() <= 0 then
					local bonushp = self.Owner:Health() + math.random( 100, 150 )
					if bonushp > self.Owner:GetMaxHealth() then bonushp = self.Owner:GetMaxHealth() end
					self.Owner:SetHealth( bonushp )
				end
			else
				self:SCPDamageEvent( target, 10 )
			end
		elseif slashtrace.Hit then
			self:EmitSound( self.KnifeShink )
			look = self.Owner:GetEyeTrace()
			util.Decal( "ManhackCut", look.HitPos + look.HitNormal * 5, look.HitPos - look.HitNormal * 5 )
		end
	end
	self.Owner:LagCompensation(false)
end

-- RMB - Panika
function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextPanic > CurTime() then return end
	
	self.NextPanic = CurTime() + self.PanicCooldown
	
	if SERVER then
		-- Znajdź gracza na którego patrzymy
		local tr = util.TraceLine({
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.PanicRange,
			filter = self.Owner
		})
		
		if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
			if tr.Entity:GTeam() != TEAM_SCP and tr.Entity:GTeam() != TEAM_SPEC then
				-- Dźwięk krzyku
				self.Owner:EmitSound("npc/stalker/go_alert2a.wav", 100, 80)
				
				-- Wyślij efekt paniki
				net.Start("SCP082_Panic")
					net.WriteFloat(CurTime() + self.PanicDuration)
				net.Send(tr.Entity)
				
				-- Zablokuj strzelanie
				tr.Entity.PanicEnd = CurTime() + self.PanicDuration
				

			end
		end
	end
end

-- Jedzenie ciał
function SWEP:EatCorpse(ragdoll)
	if not SERVER then return end
	
	-- Animacja jedzenia
	self.Owner:EmitSound("npc/barnacle/barnacle_crunch" .. math.random(2,3) .. ".wav", 75, 100)
	
	-- Heal 200 HP
	local hp = self.Owner:Health() + 200
	if hp > self.Owner:GetMaxHealth() then hp = self.Owner:GetMaxHealth() end
	self.Owner:SetHealth(hp)
	
	-- Usuń ciało
	ragdoll:Remove()
	
	-- Efekt krwi
	local effectdata = EffectData()
	effectdata:SetOrigin(self.Owner:GetPos())
	effectdata:SetNormal(Vector(0,0,1))
	util.Effect("BloodImpact", effectdata)
end

-- Client: Efekty
if CLIENT then
	net.Receive("SCP082_Panic", function()
		local endTime = net.ReadFloat()
		LocalPlayer().PanicEnd = endTime
	end)
	
	net.Receive("SCP082_Bleed", function()
		LocalPlayer().BleedingEnd = CurTime() + 5
	end)
	
	-- Hook do blokowania strzelania podczas paniki
	hook.Add("StartCommand", "SCP082_PanicBlock", function(ply, cmd)
		if ply.PanicEnd and ply.PanicEnd > CurTime() then
			cmd:RemoveKey(IN_ATTACK)
			cmd:RemoveKey(IN_ATTACK2)
		end
	end)
	
	-- Efekty wizualne
	hook.Add("RenderScreenspaceEffects", "SCP082_Effects", function()
		local ply = LocalPlayer()
		
		-- Efekt paniki
		if ply.PanicEnd and ply.PanicEnd > CurTime() then
			-- Drżenie ekranu
			if math.random() > 0.7 then
				ply:ViewPunch(Angle(math.random(-3, 3), math.random(-3, 3), 0))
			end
			
			-- Rozmazanie
			DrawMotionBlur(0.4, 0.8, 0.01)
		else
			-- Czyść efekt gdy czas minął
			ply.PanicEnd = nil
		end
		
		-- Efekt krwawienia
		if ply.BleedingEnd and ply.BleedingEnd > CurTime() then
			-- Czerwone brzegi ekranu
			local alpha = math.sin(CurTime() * 4) * 50 + 50
			surface.SetDrawColor(255, 0, 0, alpha)
			surface.DrawRect(0, 0, ScrW(), 50)
			surface.DrawRect(0, ScrH() - 50, ScrW(), 50)
			surface.DrawRect(0, 0, 50, ScrH())
			surface.DrawRect(ScrW() - 50, 0, 50, ScrH())
		else
			-- Czyść efekt gdy czas minął
			ply.BleedingEnd = nil
		end
	end)
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
	local titleW, titleH = surface.GetTextSize("SCP-082")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-082")
	
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
	surface.DrawText("LMB - Slash Attack")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
	
	local attackCooldown = 0
	if self.NextPrimary and self.NextPrimary > CurTime() then
		attackCooldown = self.NextPrimary - CurTime()
	end
	
	if attackCooldown > 0 then
		local progress = 1 - (attackCooldown / 1.75)
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
	
	-- RMB Cooldown (Panika)
	local rmbBarX = startX + barWidth + spacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rmbBarX, cooldownY - 15)
	surface.DrawText("RMB - Panic")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
	
	local panicCooldown = 0
	if self.NextPanic and self.NextPanic > CurTime() then
		panicCooldown = self.NextPanic - CurTime()
	end
	
	if panicCooldown > 0 then
		local progress = 1 - (panicCooldown / self.PanicCooldown)
		surface.SetDrawColor(255, 255, 0, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 255, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", panicCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- Info na dole
	surface.SetFont("DermaDefault")
	surface.SetTextColor(200, 200, 200, 255)
	local infoText = "Press E on corpses to eat (+200 HP)"
	local tw, th = surface.GetTextSize(infoText)
	surface.SetTextPos(centerX - tw/2, hudY + hudHeight - 20)
	surface.DrawText(infoText)
	
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

-- Czyszczenie
function SWEP:OnRemove()
	if SERVER then
		hook.Remove("PlayerUse", "SCP082_EatCorpse_" .. self:EntIndex())
	end
end