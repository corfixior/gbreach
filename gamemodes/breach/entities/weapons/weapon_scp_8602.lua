AddCSLuaFile()

SWEP.Base 				= "weapon_scp_base"
SWEP.PrintName			= "SCP-860-2"

SWEP.Primary.Delay      = 1.5
SWEP.GrabCooldown      = 60 -- Cooldown na grab
SWEP.GrabDuration      = 3 -- Maksymalny czas trzymania
SWEP.ShieldCooldown    = 60 -- Cooldown na tarczę
SWEP.ShieldDuration    = 3 -- Czas trwania tarczy (przed teleportacją)

SWEP.DrawCrosshair		= true
SWEP.HoldType 			= "normal"

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 0, "NextPrimary")
	self:NetworkVar("Float", 1, "NextGrab")
	self:NetworkVar("Float", 2, "NextShield")
	self:NetworkVar("Bool", 0, "IsGrabbing")
	self:NetworkVar("Bool", 1, "IsShielded")
	self:NetworkVar("Entity", 0, "GrabbedTarget")
end

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_8602" )

	self:SetHoldType(self.HoldType)
	
	-- Inicjalizacja cooldownów
	self:SetNextPrimary(0)
	self:SetNextGrab(0)
	self:SetNextShield(0)
	self:SetIsGrabbing(false)
	self:SetIsShielded(false)
	
	if SERVER then
		util.AddNetworkString("SCP8602_Shield")
	end
end

-- LPM - Zwykły bite
function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self:GetNextPrimary() > CurTime() then return end
	if self:GetIsGrabbing() then return end -- Nie może atakować podczas trzymania
	
	self:SetNextPrimary(CurTime() + self.Primary.Delay)
	
	if SERVER then
		local trace = util.TraceHull({
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 75,
			filter = self.Owner,
			mask = MASK_SHOT,
			maxs = Vector(15, 15, 15),
			mins = Vector(-15, -15, -15)
		})
		
		if trace.Hit and IsValid(trace.Entity) then
			local ent = trace.Entity
			if ent:IsPlayer() then
				if ent:GTeam() == TEAM_SPEC or (ent:GTeam() == TEAM_SCP and ent:GetNClass() != ROLES.ROLE_SCP035) then return end
				ent:TakeDamage(math.random(30, 45), self.Owner, self)
				self.Owner:EmitSound("npc/zombie/zombie_hit.wav", 90, math.random(80, 120))
				ent:ViewPunch(Angle(math.random(-15, 15), math.random(-15, 15), 0))
			else
				self:SCPDamageEvent(ent, 20)
			end
		end
	end
end

-- PPM - Grab
function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self:GetNextGrab() > CurTime() then return end
	
	if self:GetIsGrabbing() then
		-- Puść cel
		self:ReleaseGrab()
	else
		-- Spróbuj złapać
		if SERVER then
			local trace = util.TraceHull({
				start = self.Owner:GetShootPos(),
				endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 100,
				filter = self.Owner,
				mask = MASK_SHOT,
				maxs = Vector(20, 20, 20),
				mins = Vector(-20, -20, -20)
			})
			
			if trace.Hit and IsValid(trace.Entity) and trace.Entity:IsPlayer() then
				local ent = trace.Entity
				if ent:GTeam() != TEAM_SPEC and ent:GTeam() != TEAM_SCP then
					self:GrabTarget(ent)
				end
			end
		end
	end
end

function SWEP:GrabTarget(target)
	if !IsValid(target) then return end
	
	self:SetIsGrabbing(true)
	self:SetGrabbedTarget(target)
	self:SetNextGrab(CurTime() + self.GrabCooldown)
	self.GrabStartTime = CurTime()
	
	-- Nakładanie krwawienia
	target.NextBleeding = CurTime() + 1
	target.Bleeding = true
	
	-- Dźwięk złapania
	self.Owner:EmitSound("npc/barnacle/barnacle_bark2.wav", 100, 80)
	
	-- Zmiana prędkości
	self.OldWalkSpeed = self.Owner:GetWalkSpeed()
	self.OldRunSpeed = self.Owner:GetRunSpeed()
	self.Owner:SetWalkSpeed(150)
	self.Owner:SetRunSpeed(150)
end

function SWEP:ReleaseGrab()
	local target = self:GetGrabbedTarget()
	
	self:SetIsGrabbing(false)
	self:SetGrabbedTarget(nil)
	
	-- Przywróć prędkość
	if self.OldWalkSpeed then
		self.Owner:SetWalkSpeed(self.OldWalkSpeed)
		self.Owner:SetRunSpeed(self.OldRunSpeed)
	end
	
	-- Wyrzuć cel
	if IsValid(target) then
		local dir = self.Owner:GetAimVector()
		target:SetVelocity(dir * 800 + Vector(0, 0, 300))
		target:EmitSound("npc/zombie/zombie_pound_door.wav", 100, 100)
		
		-- Dodaj tymczasową ochronę przed fall damage
		target.SCP8602_FallProtection = CurTime() + 1.75
	end
end

-- R - Tarcza
function SWEP:Reload()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self:GetNextShield() > CurTime() then return end
	if self:GetIsShielded() then return end
	
	self:SetNextShield(CurTime() + self.ShieldCooldown)
	self:SetIsShielded(true)
	
	if SERVER then
		-- Najpierw aktywuj tarczę
		self.Owner:EmitSound("ambient/energy/force_field_loop1.wav", 100, 100)
		
		-- Wyślij info o tarczy
		net.Start("SCP8602_Shield")
			net.WriteBool(true)
			net.WriteEntity(self.Owner)
		net.Broadcast()
		
		-- Po 3 sekundach teleportuj i wyłącz tarczę
		timer.Simple(self.ShieldDuration, function()
			if IsValid(self) and IsValid(self.Owner) then
				-- Teleport do lokacji
				self.Owner:SetPos(Vector(6477.314941, 4795.328613, -1088.002808))
				self.Owner:SetEyeAngles(Angle(-1.278438, -0.006986, 0.000000))
				self.Owner:SetLocalVelocity(Vector(0, 0, 0))
				
				-- Wyłącz tarczę
				self:SetIsShielded(false)
				self.Owner:StopSound("ambient/energy/force_field_loop1.wav")
				self.Owner:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", 100, 100)
				
				net.Start("SCP8602_Shield")
					net.WriteBool(false)
					net.WriteEntity(self.Owner)
				net.Broadcast()
			end
		end)
	end
end

-- Think dla grab
function SWEP:Think()
	if SERVER and self:GetIsGrabbing() then
		local target = self:GetGrabbedTarget()
		
		-- Sprawdź czy minął maksymalny czas trzymania
		if self.GrabStartTime and CurTime() > self.GrabStartTime + self.GrabDuration then
			self:ReleaseGrab()
			return
		end
		
		if !IsValid(target) or !target:Alive() or target:GetPos():Distance(self.Owner:GetPos()) > 150 then
			self:ReleaseGrab()
			return
		end
		
		-- Trzymaj cel bliżej pyska
		local pos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 35
		target:SetPos(pos - Vector(0, 0, 20))
		target:SetVelocity(Vector(0, 0, 0))
		
		-- Krwawienie
		if target.NextBleeding and target.NextBleeding < CurTime() then
			target.NextBleeding = CurTime() + 2
			target:TakeDamage(5, self.Owner, self)
			
			-- Efekt krwi
			local effectdata = EffectData()
			effectdata:SetOrigin(target:GetPos() + Vector(0, 0, 40))
			effectdata:SetNormal(Vector(0, 0, -1))
			util.Effect("BloodImpact", effectdata)
		end
	end
end

-- Czyszczenie przy usunięciu broni
function SWEP:OnRemove()
	if self:GetIsGrabbing() then
		self:ReleaseGrab()
	end
	if SERVER and IsValid(self.Owner) then
		self.Owner:StopSound("ambient/energy/force_field_loop1.wav")
	end
end

-- Hook na obrażenia gdy tarcza aktywna
if SERVER then
	hook.Add("EntityTakeDamage", "SCP8602_Shield", function(target, dmg)
		if !IsValid(target) or !target:IsPlayer() then return end
		local wep = target:GetActiveWeapon()
		if !IsValid(wep) or wep:GetClass() != "weapon_scp_8602" then return end
		
		if wep:GetIsShielded() then
			dmg:ScaleDamage(0) -- 100% redukcji obrażeń podczas tarczy
			target:EmitSound("physics/plastic/plastic_box_impact_soft" .. math.random(1, 4) .. ".wav", 80, 150)
			return true
		end
	end)
	
	-- Blokuj fall damage dla złapanego gracza i przez 1.75s po wypuszczeniu
	hook.Add("EntityTakeDamage", "SCP8602_NoFallDamage", function(target, dmg)
		if !IsValid(target) or !target:IsPlayer() then return end
		
		-- Sprawdź czy gracz jest złapany przez jakiegoś SCP-860-2
		for _, ply in pairs(player.GetAll()) do
			local wep = ply:GetActiveWeapon()
			if IsValid(wep) and wep:GetClass() == "weapon_scp_8602" then
				if wep:GetIsGrabbing() and wep:GetGrabbedTarget() == target then
					-- Blokuj fall damage podczas trzymania
					if dmg:IsFallDamage() then
						return true
					end
				end
			end
		end
		
		-- Sprawdź czy gracz ma tymczasową ochronę po wypuszczeniu
		if target.SCP8602_FallProtection and target.SCP8602_FallProtection > CurTime() then
			if dmg:IsFallDamage() then
				return true
			end
		end
	end)
end

-- Efekty klienckie
if CLIENT then
	net.Receive("SCP8602_Shield", function()
		local active = net.ReadBool()
		local ent = net.ReadEntity()
		
		if !IsValid(ent) then return end
		
		if active then
			ent.ShieldEffect = true
		else
			ent.ShieldEffect = false
		end
	end)
	
	-- Renderowanie tarczy
	hook.Add("PostDrawTranslucentRenderables", "SCP8602_Shield", function()
		for _, ply in pairs(player.GetAll()) do
			if ply.ShieldEffect then
				render.SetColorMaterial()
				render.SetBlend(0.3)
				render.DrawSphere(ply:GetPos() + Vector(0, 0, 40), 80, 20, 20, Color(0, 255, 0, 100))
				render.SetBlend(1)
			end
		end
	end)
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
	local titleW, titleH = surface.GetTextSize("SCP-860-2")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-860-2")
	
	-- Status
	local statusText = ""
	local statusColor = Color(200, 200, 200, 255)
	
	if self:GetIsShielded() then
		statusText = "SHIELDED"
		statusColor = Color(0, 255, 0, 255)
	elseif self:GetIsGrabbing() then
		local target = self:GetGrabbedTarget()
		if IsValid(target) then
			statusText = "GRABBING: " .. target:GetName()
			statusColor = Color(255, 100, 100, 255)
		end
	end
	
	if statusText != "" then
		surface.SetFont("DermaDefaultBold")
		surface.SetTextColor(statusColor.r, statusColor.g, statusColor.b, 255)
		local statusW, statusH = surface.GetTextSize(statusText)
		surface.SetTextPos(centerX - statusW / 2, hudY + 35)
		surface.DrawText(statusText)
	end
	
	-- Cooldowny
	local cooldownY = hudY + 60
	local barWidth = 150
	local barHeight = 8
	local spacing = 20
	local totalWidth = barWidth * 3 + spacing * 2
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
	
	-- RMB Cooldown (Grab)
	local rmbBarX = startX + barWidth + spacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rmbBarX, cooldownY - 15)
	surface.DrawText("RMB - Grab")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
	
	local grabCooldown = 0
	local nextGrab = self:GetNextGrab()
	if nextGrab > CurTime() and !self:GetIsGrabbing() then
		grabCooldown = nextGrab - CurTime()
	end
	
	if self:GetIsGrabbing() then
		surface.SetDrawColor(255, 0, 0, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 200, 200, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText("RELEASE")
	elseif grabCooldown > 0 then
		local progress = 1 - (grabCooldown / 60)
		surface.SetDrawColor(255, 150, 0, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 200, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", grabCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- R Cooldown (Shield)
	local rBarX = startX + (barWidth + spacing) * 2
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rBarX, cooldownY - 15)
	surface.DrawText("R - Shield")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rBarX, cooldownY, barWidth, barHeight)
	
	local shieldCooldown = 0
	local nextShield = self:GetNextShield()
	if nextShield > CurTime() and !self:GetIsShielded() then
		shieldCooldown = nextShield - CurTime()
	end
	
	if self:GetIsShielded() then
		surface.SetDrawColor(0, 255, 0, 255)
		surface.DrawRect(rBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(rBarX, cooldownY + 10)
		surface.DrawText("ACTIVE")
	elseif shieldCooldown > 0 then
		local progress = 1 - (shieldCooldown / 60)
		surface.SetDrawColor(0, 255, 0, 255)
		surface.DrawRect(rBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(rBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", shieldCooldown))
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
	if self:GetIsShielded() then
		surface.SetDrawColor(0, 255, 0, 255)
	elseif self:GetIsGrabbing() then
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
end