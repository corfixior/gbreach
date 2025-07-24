AddCSLuaFile()

SWEP.Base 				= "weapon_scp_base"
SWEP.PrintName			= "SCP-066 Rework"			

SWEP.Primary.Delay0		= 3
SWEP.Primary.Delay1		= 30

SWEP.Primary.Eric		= "scp/066/eric.ogg"
SWEP.Primary.Beethoven	= "scp/066/beethoven.ogg"

SWEP.ShockwaveCooldown	= 60 -- Cooldown dla fali uderzeniowej
SWEP.ShockwaveRadius	= 400 -- Promień fali
SWEP.ShockwaveDamage	= 50 -- Obrażenia fali
SWEP.ShockwaveForce		= 1000 -- Siła wyrzucenia

SWEP.HoldType 			= "normal"

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_066" )

	self:SetHoldType( self.HoldType )
	
	sound.Add( {
		name = "eric",
		channel = CHAN_STATIC,
		volume = 1.0,
		level = 300,
		pitch = 100,
		sound = self.Primary.Eric
	} )
	
	sound.Add( {
		name = "beethoven",
		channel = CHAN_STATIC,
		volume = 1.0,
		level = 511,
		pitch = 100,
		sound = self.Primary.Beethoven
	} )
	
	-- Inicjalizacja zmiennych
	self.Eric = false
	self.NextPrimary = 0
	self.NextShockwave = 0
	self.NextGlassBreak = 0
	
	-- Networking dla efektów
	if SERVER then
		util.AddNetworkString("SCP066_ScreenEffect")
		util.AddNetworkString("SCP066_Shockwave")
	end
	
	if CLIENT then
		self.WepSelectIcon = surface.GetTextureID("breach/wep_066")
		self.ScreenShakeTime = 0
		self.ScreenBlurTime = 0
	end
end

-- LMB - Eric/Beethoven z efektami
function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextPrimary > CurTime() then return end
	
	if !self.Eric then
		self.NextPrimary = CurTime() + self.Primary.Delay0
		self.Eric = true
		if !SERVER then return end
		self.Owner:EmitSound( "eric" )
	else
		self.NextPrimary = CurTime() + self.Primary.Delay1
		self.Eric = false
		if !SERVER then return end
		self.Owner:EmitSound( "beethoven" )
		
		timer.Create( "DMGTimer" .. self:EntIndex(), 1, self.Primary.Delay1 - 10, function()
			if !IsValid( self ) or !IsValid( self.Owner ) then
				timer.Remove( "DMGTimer" .. self:EntIndex() )
				return
			end
			
			local fent = ents.FindInSphere( self.Owner:GetPos(), 400 )
			for k, v in pairs( fent ) do
				if IsValid( v ) then
					if v:IsPlayer() then
						if (v:GTeam() != TEAM_SCP or v:GetNClass() == ROLES.ROLE_SCP035) and v:GTeam() != TEAM_SPEC then
							v:TakeDamage( 2, self.Owner, self.Owner )
							
							-- Wyślij efekt do klienta
							net.Start("SCP066_ScreenEffect")
								net.WriteFloat(CurTime() + 2) -- Czas trwania efektu
							net.Send(v)
						end
					end
				end
			end
		end )
	end
end

-- RMB - Fala uderzeniowa
function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextShockwave > CurTime() then return end
	
	self.NextShockwave = CurTime() + self.ShockwaveCooldown
	
	if SERVER then
		-- Dźwięk fali
		self.Owner:EmitSound("ambient/explosions/explode_" .. math.random(1,5) .. ".wav", 100, 80)
		
		-- Efekt wizualny
		local effectdata = EffectData()
		effectdata:SetOrigin(self.Owner:GetPos())
		effectdata:SetNormal(Vector(0,0,1))
		effectdata:SetMagnitude(self.ShockwaveRadius)
		effectdata:SetScale(1)
		effectdata:SetRadius(self.ShockwaveRadius)
		util.Effect("cball_explode", effectdata)
		
		-- Znajdź graczy w zasięgu
		local targets = ents.FindInSphere(self.Owner:GetPos(), self.ShockwaveRadius)
		for _, ent in pairs(targets) do
			if IsValid(ent) then
				if ent:IsPlayer() and ent != self.Owner then
					if (ent:GTeam() != TEAM_SCP or ent:GetNClass() == ROLES.ROLE_SCP035) and ent:GTeam() != TEAM_SPEC then
						-- Zadaj obrażenia
						local dmg = DamageInfo()
						dmg:SetDamage(self.ShockwaveDamage)
						dmg:SetAttacker(self.Owner)
						dmg:SetInflictor(self)
						dmg:SetDamageType(DMG_SONIC)
						ent:TakeDamageInfo(dmg)
						
						-- Wyrzuć gracza
						local dir = (ent:GetPos() - self.Owner:GetPos()):GetNormalized()
						dir.z = 0.5
						ent:SetVelocity(dir * self.ShockwaveForce)
						
						-- Ogłusz
						ent:ViewPunch(Angle(math.random(-25, 25), math.random(-25, 25), 0))
					end
				elseif ent:GetClass() == "prop_physics" then
					-- Wyrzuć obiekty fizyczne
					local phys = ent:GetPhysicsObject()
					if IsValid(phys) then
						local dir = (ent:GetPos() - self.Owner:GetPos()):GetNormalized()
						phys:ApplyForceCenter(dir * self.ShockwaveForce * 100)
					end
				end
			end
		end
		
		-- Wyślij efekt do klientów
		net.Start("SCP066_Shockwave")
			net.WriteVector(self.Owner:GetPos())
		net.Broadcast()
	end
end

-- Odbieranie efektów po stronie klienta
if CLIENT then
	net.Receive("SCP066_ScreenEffect", function()
		local endTime = net.ReadFloat()
		local ply = LocalPlayer()
		if IsValid(ply) then
			ply.SCP066_ScreenEffect = endTime
		end
	end)
	
	-- Tablica dla efektów shockwave
	local shockwaveEffects = {}
	
	net.Receive("SCP066_Shockwave", function()
		local pos = net.ReadVector()
		
		-- Efekt dźwiękowy dla wszystkich
		sound.Play("ambient/explosions/explode_" .. math.random(1,5) .. ".wav", pos, 100, 80)
		
		-- Wstrząśnij ekranem jeśli blisko
		local ply = LocalPlayer()
		local dist = ply:GetPos():Distance(pos)
		if dist < 600 then
			util.ScreenShake(pos, 10, 10, 2, 600)
		end
		
		-- Dodaj nowy efekt shockwave
		table.insert(shockwaveEffects, {
			pos = pos,
			startTime = CurTime(),
			duration = 1.5,
			maxRadius = 400
		})
	end)
	
	-- Hook do rysowania efektu shockwave
	hook.Add("PostDrawTranslucentRenderables", "SCP066_ShockwaveEffect", function()
		for i = #shockwaveEffects, 1, -1 do
			local effect = shockwaveEffects[i]
			local elapsed = CurTime() - effect.startTime
			
			if elapsed > effect.duration then
				table.remove(shockwaveEffects, i)
			else
				-- Oblicz aktualny promień
				local progress = elapsed / effect.duration
				local radius = effect.maxRadius * progress
				local alpha = 255 * (1 - progress)
				
				-- Rysuj pierścień shockwave
				render.SetColorMaterial()
				
				-- Zewnętrzny pierścień
				render.StartBeam(32)
				for j = 0, 31 do
					local angle = (j / 31) * math.pi * 2
					local x = effect.pos.x + math.cos(angle) * radius
					local y = effect.pos.y + math.sin(angle) * radius
					local z = effect.pos.z + 10
					
					render.AddBeam(Vector(x, y, z), radius * 0.1, j / 31, Color(100, 150, 255, alpha))
				end
				render.EndBeam()
				
				-- Drugi pierścień (mniejszy)
				if progress < 0.7 then
					local radius2 = radius * 0.7
					local alpha2 = alpha * 0.6
					
					render.StartBeam(24)
					for j = 0, 23 do
						local angle = (j / 23) * math.pi * 2
						local x = effect.pos.x + math.cos(angle) * radius2
						local y = effect.pos.y + math.sin(angle) * radius2
						local z = effect.pos.z + 5
						
						render.AddBeam(Vector(x, y, z), radius2 * 0.08, j / 23, Color(150, 200, 255, alpha2))
					end
					render.EndBeam()
				end
				
				-- Efekt zniekształcenia (refraction)
				if progress < 0.5 then
					cam.Start3D()
					render.SetMaterial(Material("models/spawn_effect"))
					render.DrawSphere(effect.pos, radius, 20, 20, Color(255, 255, 255, alpha * 0.3))
					cam.End3D()
				end
			end
		end
	end)
	
	-- Hook do rysowania efektów
	hook.Add("RenderScreenspaceEffects", "SCP066_Effects", function()
		local ply = LocalPlayer()
		if ply.SCP066_ScreenEffect and ply.SCP066_ScreenEffect > CurTime() then
			-- Silne rozmazanie
			DrawMotionBlur(0.8, 0.95, 0.05)
			
			-- Efekt nieostrego widzenia
			DrawSharpen(0.5, 2)
			
			-- Lekkie przyciemnienie bez czerwieni
			local tab = {
				["$pp_colour_addr"] = 0,
				["$pp_colour_addg"] = 0,
				["$pp_colour_addb"] = 0,
				["$pp_colour_brightness"] = -0.3,
				["$pp_colour_contrast"] = 0.7,
				["$pp_colour_colour"] = 0.5,
				["$pp_colour_mulr"] = 1,
				["$pp_colour_mulg"] = 1,
				["$pp_colour_mulb"] = 1
			}
			DrawColorModify(tab)
			
			-- Losowe wstrząsy widoku
			if math.random() > 0.85 then
				ply:ViewPunch(Angle(math.random(-8, 8), math.random(-8, 8), 0))
			end
		else
			-- Czyść efekt gdy czas minął
			ply.SCP066_ScreenEffect = nil
		end
	end)
end

-- HUD w stylu innych SCP
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
	local titleW, titleH = surface.GetTextSize("SCP-066")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-066")
	
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
	surface.DrawText("LMB - Sound Attack")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
	
	local primaryCooldown = 0
	local maxCooldown = self.Eric and self.Primary.Delay0 or self.Primary.Delay1
	if self.NextPrimary and self.NextPrimary > CurTime() then
		primaryCooldown = self.NextPrimary - CurTime()
	end
	
	if primaryCooldown > 0 then
		local progress = 1 - (primaryCooldown / maxCooldown)
		surface.SetDrawColor(255, 100, 100, 255)
		surface.DrawRect(lmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 150, 150, 255)
		surface.SetTextPos(lmbBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", primaryCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(lmbBarX, cooldownY + 10)
		surface.DrawText(self.Eric and "ERIC READY" or "BEETHOVEN READY")
	end
	
	-- RMB Cooldown
	local rmbBarX = startX + barWidth + spacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(rmbBarX, cooldownY - 15)
	surface.DrawText("RMB - Shockwave")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
	
	local shockwaveCooldown = 0
	if self.NextShockwave and self.NextShockwave > CurTime() then
		shockwaveCooldown = self.NextShockwave - CurTime()
	end
	
	if shockwaveCooldown > 0 then
		local progress = 1 - (shockwaveCooldown / self.ShockwaveCooldown)
		surface.SetDrawColor(255, 255, 0, 255)
		surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 255, 150, 255)
		surface.SetTextPos(rmbBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", shockwaveCooldown))
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
	local color = self.Eric and Color(255, 100, 100) or Color(100, 100, 255)
	surface.SetDrawColor(color.r, color.g, color.b, 255)
	
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

-- Rozbijanie szyb na klawisz E dla SCP-066
if SERVER then
	hook.Add("KeyPress", "SCP066_GlassBreak", function(ply, key)
		if !IsValid(ply) or !ply:Alive() then return end
		local wep = ply:GetActiveWeapon()
		if !IsValid(wep) or wep:GetClass() != "weapon_scp_066" then return end
		
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
				-- Usunięto dźwięk rozbijania szyby
				
				-- Usunięto efekt wizualny szyby
			elseif string.find(ent:GetClass(), "door") then
				-- Możliwość rozbicia drzwi ze szkłem
				wep:SCPDamageEvent(ent, 100)
			end
		end
	end)
end