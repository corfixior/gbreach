AddCSLuaFile()

SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-1048-B"
SWEP.Category = "SCP"

-- Oryginalne modele z ffv_hhsaw
SWEP.ViewModel = "models/weapons/c_physcannon.mdl"
SWEP.WorldModel = "models/weapons/w_physics.mdl"
SWEP.ViewModelFOV = 62.51256281407
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true

SWEP.HoldType = "physgun"

SWEP.Primary.Ammo = ""
SWEP.Secondary.Ammo = ""
SWEP.Primary.Automatic = true
SWEP.Secondary.Automatic = true

-- KONFIGURACJA BRONI
SWEP.SawRange = 60 -- Zasięg piły w jednostkach
SWEP.DamageToPlayers = {3, 8} -- Min i max obrażenia dla graczy (nie-SCP)
SWEP.DamageToEntities = {10, 60} -- Min i max obrażenia dla innych entów
SWEP.ExpPerHit = 15 -- EXP za trafienie gracza
SWEP.ChaseSpeedBonus = 1.3 -- Mnożnik prędkości gdy goni wroga (1.3 = 30% szybciej)
SWEP.ChaseDetectionRange = 1000 -- Zasięg wykrywania wrogów do pościgu
SWEP.ChaseAngleTolerance = 45 -- Kąt patrzenia na wroga (w stopniach)
SWEP.LowHealthVisionThreshold = 30 -- Próg HP do widzenia przez ściany
SWEP.LowHealthVisionRange = 500 -- Zasięg widzenia przez ściany (jednostki)

-- Zmienne piły
SWEP.spinSound = nil
SWEP.timeShot = 0
SWEP.animPlace = 0

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID("breach/wep_106") -- Tymczasowo
	
	-- Pozycje iron sight
	SWEP.ironsightPoses = {Vector(0, 0, -6.031), Vector(0, -2, -5.031)}
	SWEP.IronSightsPos = Vector(0, 0, -6.031)
	SWEP.IronSightsAng = Vector(7.738, 0, 0)
end

function to_goal(num, goal, change)
	return math.Clamp(goal, num - change, num + change)
end

function place_between(goal, num1, num2)
	return ((num2 - num1) / goal) + num1
end

function SWEP:Initialize()
	self:InitializeLanguage("SCP_1048B")
	
	self.spinSound = CreateSound(self, "vehicles/airboat/fan_blade_fullthrottle_loop1.wav")
	self:SetHoldType(self.HoldType)
	
	-- Predicted hooks
	self:SetNWBool("firing", false)
	self:SetNWFloat("spinSpeed", 0)

	if CLIENT then
		-- Viewmodel elements
		self.VElements = {
			["backcover"] = { type = "Model", model = "models/props_c17/oildrum001.mdl", bone = "Base", rel = "base", pos = Vector(0.554, 3.418, -23.215), angle = Angle(0, 0, 0), size = Vector(0.5, 0.5, 0.057), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
			["base"] = { type = "Model", model = "models/props_c17/FurnitureBoiler001a.mdl", bone = "Base", rel = "", pos = Vector(1.1, 5.8, 9), angle = Angle(0, 180, 0), size = Vector(0.483, 0.483, 0.483), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
			["sawbase"] = { type = "Model", model = "models/props_c17/canister01a.mdl", bone = "Base", rel = "base", pos = Vector(0, 3, 20.26), angle = Angle(0, 180, 0), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
			["saw"] = { type = "Model", model = "models/props_junk/sawblade001a.mdl", bone = "Base", rel = "base", pos = Vector(0, 3, 34.631), angle = Angle(0, 90, 90), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
			["canister"] = { type = "Model", model = "models/props_junk/propane_tank001a.mdl", bone = "Base", rel = "base", pos = Vector(0, 17.885, -12.988), angle = Angle(158.498, 0, -90), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
		}
		
		-- Worldmodel elements
		self.WElements = {
			["backcover"] = { type = "Model", model = "models/props_c17/oildrum001.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(0.554, 3.418, -23.215), angle = Angle(0, 0, 0), size = Vector(0.5, 0.5, 0.057), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
			["base"] = { type = "Model", model = "models/props_c17/FurnitureBoiler001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(27.708, -2.447, -4.874), angle = Angle(35, 100, 105), size = Vector(0.483, 0.483, 0.483), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
			["sawbase"] = { type = "Model", model = "models/props_c17/canister01a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(0, 3, 20.26), angle = Angle(0, 180, 0), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
			["saw"] = { type = "Model", model = "models/props_junk/sawblade001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(0, 3, 34.631), angle = Angle(0, 90, 90), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
			["canister"] = { type = "Model", model = "models/props_junk/propane_tank001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(0, 17.885, -12.988), angle = Angle(30.993, 0, -90), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
		}
		
		self.ViewModelBoneMods = {}
		
		-- Create models
		self.VElements = table.FullCopy(self.VElements)
		self.WElements = table.FullCopy(self.WElements)
		self.ViewModelBoneMods = table.FullCopy(self.ViewModelBoneMods)

		self:CreateModels(self.VElements)
		self:CreateModels(self.WElements)
		
		if IsValid(self.Owner) then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
				
				if (self.ShowViewModel == nil or self.ShowViewModel) then
					vm:SetColor(Color(255,255,255,255))
				else
					vm:SetColor(Color(255,255,255,1))
					vm:SetMaterial("Debug/hsv")			
				end
			end
		end
	end
end

function SWEP:PrimaryAttack()
	if preparing or postround then return end
	self.timeShot = CurTime()
	self:SetNWBool("firing", true)
end

function SWEP:SecondaryAttack()
	-- RMB wyłączone - brak rzucania piłą
end

function SWEP:Think()
	local ply = self:GetOwner()
	if not IsValid(ply) then return end
	
	-- Sprawdź czy gracz goni wroga (tylko SERVER)
	if SERVER then
		local chasingEnemy = false
		local nearestEnemy = nil
		local nearestDist = self.ChaseDetectionRange
		
		-- Znajdź najbliższego wroga
		for _, target in pairs(player.GetAll()) do
			if IsValid(target) and target:Alive() and target != ply then
				-- Sprawdź czy to nie SCP/SPEC
				if target:GTeam() != TEAM_SCP and target:GTeam() != TEAM_SPEC then
					local dist = ply:GetPos():Distance(target:GetPos())
					if dist < nearestDist then
						nearestDist = dist
						nearestEnemy = target
					end
				end
			end
		end
		
		-- Sprawdź czy patrzymy na wroga
		if IsValid(nearestEnemy) then
			local toEnemy = (nearestEnemy:GetPos() - ply:GetPos()):GetNormalized()
			local forward = ply:GetAimVector()
			local dot = forward:Dot(toEnemy)
			local angle = math.deg(math.acos(dot))
			
			-- Czy patrzymy w kierunku wroga?
			if angle < self.ChaseAngleTolerance then
				chasingEnemy = true
			end
		end
		
		-- Ustaw prędkość
		if chasingEnemy then
			if not ply.OriginalSpeed then
				ply.OriginalSpeed = ply:GetWalkSpeed()
				ply.OriginalRunSpeed = ply:GetRunSpeed()
			end
			ply:SetWalkSpeed(ply.OriginalSpeed * self.ChaseSpeedBonus)
			ply:SetRunSpeed(ply.OriginalRunSpeed * self.ChaseSpeedBonus)
		else
			-- Przywróć normalną prędkość
			if ply.OriginalSpeed and ply.OriginalRunSpeed then
				ply:SetWalkSpeed(ply.OriginalSpeed)
				ply:SetRunSpeed(ply.OriginalRunSpeed)
			end
		end
	end
	
	-- Client animation
	if CLIENT then
		-- Hold position
		local animGoal = 1
		if self:GetNWBool("firing") then animGoal = 4 end
		self.animPlace = to_goal(self.animPlace, animGoal, .1)

		local x1, y1, z1 = self.ironsightPoses[1]:Unpack()
		local x2, y2, z2 = self.ironsightPoses[2]:Unpack()
		self.IronSightsPos = Vector(
			place_between(self.animPlace, x1, x2),
			place_between(self.animPlace, y1, y2),
			place_between(self.animPlace, z1, z2)
		)

		-- Spinny blade
		local goal = 0
		if self:GetNWBool("firing") then goal = 8 end
		self.VElements.saw.angle = self.VElements.saw.angle + Angle(-self:GetNWFloat("spinSpeed"), 0, 0)
		self.VElements.saw.size = Vector(.5, .5, .5) -- Piła zawsze widoczna
		return
	end

	-- Spin sound volume
	self.spinSound:ChangeVolume(self:GetNWFloat("spinSpeed") / 8)

	if (CurTime() - self.timeShot) > 0.02 then
		-- Not firing
		self:SetNWBool("firing", false)
		self:SetNWFloat("spinSpeed", to_goal(self:GetNWFloat("spinSpeed"), 0, .02))
	else
		-- Is firing
		self:SetNWFloat("spinSpeed", to_goal(self:GetNWFloat("spinSpeed"), 8, .06))

		-- Damage timer
		if not timer.Exists("sawStuff"..ply:SteamID64()) then
			timer.Create("sawStuff"..ply:SteamID64(), .1, 0, function()
				if not IsValid(self) or not self:GetNWBool("firing") then
					timer.Remove("sawStuff"..ply:SteamID64())
					return
				end
				local trace = ply:GetEyeTrace()
				if not ((trace.HitPos - trace.StartPos):Length() < self.SawRange) then
					return
				end

				local ent = trace.Entity
				if IsValid(ent) then
					-- Obrażenia dla SCP
					if ent:IsPlayer() then
						if (ent:GTeam() == TEAM_SCP and ent:GetNClass() != ROLES.ROLE_SCP035) or ent:GTeam() == TEAM_SPEC then return end
						ent:TakeDamage(math.random(self.DamageToPlayers[1], self.DamageToPlayers[2]), ply, self)
						if IsValid(ply) then
							ply:AddExp(self.ExpPerHit, true)
						end
					else
						ent:TakeDamage(math.random(self.DamageToEntities[1], self.DamageToEntities[2]), ply, self)
					end
					
					local phys = ent:GetPhysicsObject()
					if IsValid(phys) then
						phys:ApplyForceOffset(ply:GetAimVector() * 240 * self:GetNWFloat("spinSpeed"), trace.HitPos)
					end

					local effect = EffectData()
					effect:SetOrigin(trace.HitPos)
					effect:SetNormal(trace.HitNormal)

					if ent:IsNPC() or ent:IsRagdoll() or ent:IsPlayer() then
						self:EmitSound("npc/manhack/grind_flesh"..math.random(3)..".wav")
						util.Effect("BloodImpact", effect)

						-- Blood decals
						util.Decal("Blood", trace.HitPos + trace.HitNormal, trace.HitPos - trace.HitNormal)
						if math.random(3) == 1 then
							local trace2 = {}
							trace2.start = trace.HitPos
							trace2.endpos = trace.HitPos + Vector(0, 0, -10000)
							trace2.filter = ent
							trace2 = util.TraceLine(trace2)
							util.Decal("Blood", trace2.HitPos + trace2.HitNormal, trace2.HitPos - trace2.HitNormal, ent)
						end
					else
						self:EmitSound("npc/manhack/grind"..math.random(5)..".wav")
						util.Effect("ManhackSparks", effect)
					end
				end
			end)
		end
	end
end

function SWEP:Deploy()
	self.spinSound:PlayEx(0, 100)
end

function SWEP:Holster()
	self:SetNWFloat("spinSpeed", 0)
	self.spinSound:Stop()
	
	-- Przywróć normalną prędkość
	if SERVER and IsValid(self.Owner) then
		if self.Owner.OriginalSpeed and self.Owner.OriginalRunSpeed then
			self.Owner:SetWalkSpeed(self.Owner.OriginalSpeed)
			self.Owner:SetRunSpeed(self.Owner.OriginalRunSpeed)
			self.Owner.OriginalSpeed = nil
			self.Owner.OriginalRunSpeed = nil
		end
	end
	
	if CLIENT and IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
	end
	
	return true
end

function SWEP:OnRemove()
	-- Usuń timer obrażeń
	if IsValid(self.Owner) then
		timer.Remove("sawStuff"..self.Owner:SteamID64())
		
		-- Przywróć normalną prędkość
		if SERVER and self.Owner.OriginalSpeed and self.Owner.OriginalRunSpeed then
			self.Owner:SetWalkSpeed(self.Owner.OriginalSpeed)
			self.Owner:SetRunSpeed(self.Owner.OriginalRunSpeed)
			self.Owner.OriginalSpeed = nil
			self.Owner.OriginalRunSpeed = nil
		end
	end
	
	self:Holster()
end

-- Rysowanie wrogów z niskim HP przez ściany
if CLIENT then
	hook.Add("PostDrawTranslucentRenderables", "SCP1048B_LowHealthVision", function()
		local ply = LocalPlayer()
		if not IsValid(ply) or not ply:Alive() then return end
		
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() != "weapon_scp_1048b" then return end
		
		-- Znajdź wszystkich graczy z niskim HP
		for _, target in pairs(player.GetAll()) do
			if IsValid(target) and target != ply and target:Alive() then
				-- Sprawdź czy to nie SCP/SPEC i ma mało HP
				if target:GTeam() != TEAM_SCP and target:GTeam() != TEAM_SPEC then
					if target:Health() < wep.LowHealthVisionThreshold then
						-- Sprawdź zasięg
						local dist = ply:GetPos():Distance(target:GetPos())
						if dist <= wep.LowHealthVisionRange then
							-- Sprawdź czy gracz jest za ścianą
							local trace = util.TraceLine({
								start = ply:EyePos(),
								endpos = target:EyePos(),
								filter = {ply, target}
							})
							
							-- Renderuj tylko jeśli gracz jest za ścianą
							if trace.Hit then
						
						-- Ustaw kolor na podstawie HP
						local healthPercent = target:Health() / wep.LowHealthVisionThreshold
						local r = 255
						local g = 255 * healthPercent
						local b = 0
						
						-- Włącz ignorowanie Z-bufferu (renderowanie przez ściany)
						cam.IgnoreZ(true)
						
						-- Renderuj model przez ściany z efektem "glow"
						render.SuppressEngineLighting(true)
						render.SetColorModulation(r/255, g/255, b/255)
						render.SetBlend(0.8) -- Lekka przezroczystość
						render.MaterialOverride(Material("models/debug/debugwhite"))
						
						-- Rysuj model
						target:DrawModel()
						
						-- Przywróć ustawienia
						render.MaterialOverride()
						render.SetColorModulation(1, 1, 1)
						render.SetBlend(1)
						render.SuppressEngineLighting(false)
						
						-- Wyłącz ignorowanie Z-bufferu
						cam.IgnoreZ(false)
						
						-- Dodatkowo narysuj obrys
						render.SetStencilEnable(true)
						render.SetStencilWriteMask(1)
						render.SetStencilTestMask(1)
						render.SetStencilReferenceValue(1)
						
						-- Pierwszy pass - zapisz do stencil
						render.SetStencilCompareFunction(STENCIL_ALWAYS)
						render.SetStencilPassOperation(STENCIL_REPLACE)
						render.SetStencilFailOperation(STENCIL_KEEP)
						render.SetStencilZFailOperation(STENCIL_KEEP)
						
						render.OverrideDepthEnable(true, false)
						target:DrawModel()
						render.OverrideDepthEnable(false, false)
						
						-- Drugi pass - rysuj obrys
						render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
						render.SetStencilPassOperation(STENCIL_KEEP)
						render.SetStencilFailOperation(STENCIL_KEEP)
						render.SetStencilZFailOperation(STENCIL_KEEP)
						
						-- Powiększ model dla obrysu
						local mat = Matrix()
						mat:Scale(Vector(1.05, 1.05, 1.05))
						target:EnableMatrix("RenderMultiply", mat)
						
						render.SetColorModulation(r/255, g/255, b/255)
						render.MaterialOverride(Material("models/wireframe"))
						target:DrawModel()
						
						target:DisableMatrix("RenderMultiply")
						render.MaterialOverride()
						render.SetColorModulation(1, 1, 1)
						
						render.SetStencilEnable(false)
							end -- end trace.Hit
						end -- end dist check
					end
				end
			end
		end
	end)
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
	local titleW, titleH = surface.GetTextSize("SCP-1048-B")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-1048-B")
	
	-- Info o pile
	local infoY = hudY + 60
	surface.SetFont("DermaDefaultBold")
	surface.SetTextColor(200, 200, 200, 255)
	
	-- Moc piły
	local power = self:GetNWFloat("spinSpeed") / 8
	local barWidth = 300
	local barHeight = 10
	local barX = centerX - barWidth / 2
	
	surface.SetTextPos(centerX - 50, infoY - 20)
	surface.DrawText("Saw Power")
	
	-- Tło paska
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(barX, infoY, barWidth, barHeight)
	
	-- Pasek mocy
	if power > 0 then
		surface.SetDrawColor(255, 100 + power * 155, 100, 255)
		surface.DrawRect(barX, infoY, barWidth * power, barHeight)
	end
	
	-- Obramowanie
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(barX, infoY, barWidth, barHeight)
	
	-- Instrukcje
	surface.SetFont("DermaDefault")
	surface.SetTextColor(150, 150, 150, 255)
	surface.SetTextPos(centerX - 50, infoY + 15)
	surface.DrawText("LMB - Spin Saw")
	
	-- Celownik
	local x = ScrW() / 2.0
	local y = ScrH() / 2.0
	
	-- Animowany celownik gdy piła się kręci
	if self:GetNWFloat("spinSpeed") > 0 then
		local spin = CurTime() * self:GetNWFloat("spinSpeed") * 100
		local scale = 0.5 + self:GetNWFloat("spinSpeed") / 16
		
		surface.SetDrawColor(255, 150, 150, 255)
		
		-- Obracający się celownik
		for i = 0, 3 do
			local angle = math.rad(spin + i * 90)
			local cos = math.cos(angle)
			local sin = math.sin(angle)
			
			local x1 = x + cos * 10
			local y1 = y + sin * 10
			local x2 = x + cos * 30 * scale
			local y2 = y + sin * 30 * scale
			
			surface.DrawLine(x1, y1, x2, y2)
		end
	else
		-- Normalny celownik
		local scale = 0.3
		surface.SetDrawColor(200, 100, 100, 255)
		
		local gap = 5
		local length = gap + 20 * scale
		surface.DrawLine(x - length, y, x - gap, y)
		surface.DrawLine(x + length, y, x + gap, y)
		surface.DrawLine(x, y - length, x, y - gap)
		surface.DrawLine(x, y + length, x, y + gap)
	end
end

function SWEP:GetViewModelPosition(EyePos, EyeAng)
	local Mul = 1.0

	local Offset = self.IronSightsPos

	if self.IronSightsAng then
		EyeAng = EyeAng * 1
		
		EyeAng:RotateAroundAxis(EyeAng:Right(), self.IronSightsAng.x * Mul)
		EyeAng:RotateAroundAxis(EyeAng:Up(), self.IronSightsAng.y * Mul)
		EyeAng:RotateAroundAxis(EyeAng:Forward(), self.IronSightsAng.z * Mul)
	end

	local Right = EyeAng:Right()
	local Up = EyeAng:Up()
	local Forward = EyeAng:Forward()

	EyePos = EyePos + Offset.x * Right * Mul
	EyePos = EyePos + Offset.y * Forward * Mul
	EyePos = EyePos + Offset.z * Up * Mul
	
	return EyePos, EyeAng
end

-- CLIENT SIDE RENDERING
if CLIENT then
	
	SWEP.vRenderOrder = nil
	function SWEP:ViewModelDrawn()
		
		local vm = self.Owner:GetViewModel()
		if !IsValid(vm) then return end
		
		if (!self.VElements) then return end
		
		self:UpdateBonePositions(vm)

		if (!self.vRenderOrder) then
			
			self.vRenderOrder = {}

			for k, v in pairs( self.VElements ) do
				if (v.type == "Model") then
					table.insert(self.vRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.vRenderOrder, k)
				end
			end
			
		end

		for k, name in ipairs( self.vRenderOrder ) do
		
			local v = self.VElements[name]
			if (!v) then self.vRenderOrder = nil break end
			if (v.hide) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (!v.bone) then continue end
			
			local pos, ang = self:GetBoneOrientation( self.VElements, v, vm )
			
			if (!pos) then continue end
			
			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
			elseif (v.type == "Sprite" and sprite) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
				
			elseif (v.type == "Quad" and v.draw_func) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()

			end
			
		end
		
	end

	SWEP.wRenderOrder = nil
	function SWEP:DrawWorldModel()

		self.WElements.saw.angle = self.WElements.saw.angle + Angle(-self:GetNWFloat("spinSpeed"), 0, 0)
		self.WElements.saw.size = Vector(.5, .5, .5) -- Piła zawsze widoczna
		
		if (self.ShowWorldModel == nil or self.ShowWorldModel) then
			self:DrawModel()
		end
		
		if (!self.WElements) then return end
		
		if (!self.wRenderOrder) then

			self.wRenderOrder = {}

			for k, v in pairs( self.WElements ) do
				if (v.type == "Model") then
					table.insert(self.wRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.wRenderOrder, k)
				end
			end

		end
		
		if (IsValid(self.Owner)) then
			bone_ent = self.Owner
		else
			bone_ent = self
		end
		
		for k, name in pairs( self.wRenderOrder ) do
		
			local v = self.WElements[name]
			if (!v) then self.wRenderOrder = nil break end
			if (v.hide) then continue end
			
			local pos, ang
			
			if (v.bone) then
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent )
			else
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
			end
			
			if (!pos) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
			elseif (v.type == "Sprite" and sprite) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
				
			elseif (v.type == "Quad" and v.draw_func) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()

			end
			
		end
		
	end

	function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
		
		local bone, pos, ang
		if (tab.rel and tab.rel != "") then
			
			local v = basetab[tab.rel]
			
			if (!v) then return end
			
			pos, ang = self:GetBoneOrientation( basetab, v, ent )
			
			if (!pos) then return end
			
			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
		else
		
			bone = ent:LookupBone(bone_override or tab.bone)

			if (!bone) then return end
			
			pos, ang = Vector(0,0,0), Angle(0,0,0)
			local m = ent:GetBoneMatrix(bone)
			if (m) then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end
			
			if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
				ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
				ang.r = -ang.r
			end
		
		end
		
		return pos, ang
	end

	function SWEP:CreateModels( tab )

		if (!tab) then return end

		for k, v in pairs( tab ) do
			if (v.type == "Model" and v.model and v.model != "" and (!IsValid(v.modelEnt) or v.createdModel != v.model) and 
					string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") ) then
				
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if (IsValid(v.modelEnt)) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else
					v.modelEnt = nil
				end
				
			elseif (v.type == "Sprite" and v.sprite and v.sprite != "" and (!v.spriteMaterial or v.createdSprite != v.sprite) 
				and file.Exists ("materials/"..v.sprite..".vmt", "GAME")) then
				
				local name = v.sprite.."-"
				local params = { ["$basetexture"] = v.sprite }
				local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
				for i, j in pairs( tocheck ) do
					if (v[j]) then
						params["$"..j] = 1
						name = name.."1"
					else
						name = name.."0"
					end
				end

				v.createdSprite = v.sprite
				v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
				
			end
		end
		
	end
	
	local allbones
	local hasGarryFixedBoneScalingYet = false

	function SWEP:UpdateBonePositions(vm)
		
		if self.ViewModelBoneMods then
			
			if (!vm:GetBoneCount()) then return end
			
			local loopthrough = self.ViewModelBoneMods
			if (!hasGarryFixedBoneScalingYet) then
				allbones = {}
				for i=0, vm:GetBoneCount() do
					local bonename = vm:GetBoneName(i)
					if (self.ViewModelBoneMods[bonename]) then 
						allbones[bonename] = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename] = { 
							scale = Vector(1,1,1),
							pos = Vector(0,0,0),
							angle = Angle(0,0,0)
						}
					end
				end
				
				loopthrough = allbones
			end
			
			for k, v in pairs( loopthrough ) do
				local bone = vm:LookupBone(k)
				if (!bone) then continue end
				
				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms = Vector(1,1,1)
				if (!hasGarryFixedBoneScalingYet) then
					local cur = vm:GetBoneParent(bone)
					while(cur >= 0) do
						local pscale = loopthrough[vm:GetBoneName(cur)].scale
						ms = ms * pscale
						cur = vm:GetBoneParent(cur)
					end
				end
				
				s = s * ms
				
				if vm:GetManipulateBoneScale(bone) != s then
					vm:ManipulateBoneScale( bone, s )
				end
				if vm:GetManipulateBoneAngles(bone) != v.angle then
					vm:ManipulateBoneAngles( bone, v.angle )
				end
				if vm:GetManipulateBonePosition(bone) != p then
					vm:ManipulateBonePosition( bone, p )
				end
			end
		else
			self:ResetBonePositions(vm)
		end
		   
	end
	 
	function SWEP:ResetBonePositions(vm)
		
		if (!vm:GetBoneCount()) then return end
		for i=0, vm:GetBoneCount() do
			vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
			vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
			vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
		end
		
	end

	function table.FullCopy( tab )

		if (!tab) then return nil end
		
		local res = {}
		for k, v in pairs( tab ) do
			if (type(v) == "table") then
				res[k] = table.FullCopy(v)
			elseif (type(v) == "Vector") then
				res[k] = Vector(v.x, v.y, v.z)
			elseif (type(v) == "Angle") then
				res[k] = Angle(v.p, v.y, v.r)
			else
				res[k] = v
			end
		end
		
		return res
		
	end
	
end