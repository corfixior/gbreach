AddCSLuaFile()

SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-Steve-J"

SWEP.HoldType = "crowbar"

-- SCP-Steve-J Configuration
SWEP.SwordDelay = 0.8
SWEP.PearlDelay = 30.0
SWEP.SwordDamage = 80
SWEP.SwordRange = 80

-- Weapon properties from original sweps
SWEP.ViewModelFOV = 70
SWEP.ViewModel = "models/weapons/v_diamond_mc_sword.mdl"
SWEP.WorldModel = "models/weapons/w_diamond_mc_sword.mdl"
SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true

-- VElements and WElements - using sword viewmodel so no need for sword VElement
SWEP.VElements = {
	["pearl"] = { 
		type = "Model", 
		model = "models/lolixtin/ender_pearl.mdl", 
		bone = "ValveBiped.Bip01_L_Hand", 
		rel = "", 
		pos = Vector(2.596, 1.557, -2.597), 
		angle = Angle(115.713, 0, -3.507), 
		size = Vector(0.5, 0.5, 0.5), 
		color = Color(255, 255, 255, 255), 
		surpresslightning = false, 
		material = "", 
		skin = 0, 
		bodygroup = {} 
	}
}

SWEP.WElements = {
	["pearl"] = { 
		type = "Model", 
		model = "models/lolixtin/ender_pearl.mdl", 
		bone = "ValveBiped.Bip01_L_Hand", 
		rel = "", 
		pos = Vector(4.196, 6.752, -2.597), 
		angle = Angle(125.065, 0, 0), 
		size = Vector(0.5, 0.5, 0.5), 
		color = Color(255, 255, 255, 255), 
		surpresslightning = false, 
		material = "", 
		skin = 0, 
		bodygroup = {} 
	}
}

SWEP.ViewModelBoneMods = {}

if SERVER then
	util.AddNetworkString("scp_steve_j_sword_hit")
	util.AddNetworkString("scp_steve_j_pearl_throw")
end

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID("breach/wep_steve_j")
end

function SWEP:Initialize()
	self:InitializeLanguage("SCP_STEVE_J")
	self:SetHoldType(self.HoldType)
	
	self.NextSwordAttack = 0
	self.NextPearlThrow = 0

	if CLIENT then
		// Create a new table for every weapon instance
		self.VElements = table.FullCopy( self.VElements )
		self.WElements = table.FullCopy( self.WElements )
		self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

		self:CreateModels(self.VElements) // create viewmodels
		self:CreateModels(self.WElements) // create worldmodels
		
		// init view model bone build function
		if IsValid(self.Owner) then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
				
				// Init viewmodel visibility
				if (self.ShowViewModel == nil or self.ShowViewModel) then
					vm:SetColor(Color(255,255,255,255))
				else
					// we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
					vm:SetColor(Color(255,255,255,1))
					// ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
					// however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
					vm:SetMaterial("Debug/hsv")			
				end
			end
		end
	end
end

function SWEP:OwnerChanged()
	self:Holster()
end

function SWEP:Holster()
	if CLIENT and IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
	end
	return true
end

function SWEP:OnRemove()
	self:Holster()
end

function SWEP:Deploy()
	if CLIENT then
		self:SendWeaponAnim(ACT_VM_DRAW)
	end
	return true
end

function SWEP:PrimaryAttack()
	if not IsFirstTimePredicted() then return end
	if CurTime() < self.NextSwordAttack then return end
	
	self:SwordAttack()
	self.NextSwordAttack = CurTime() + self.SwordDelay
end

function SWEP:SwordAttack()
	if not IsValid(self.Owner) then return end
	
	local ply = self.Owner
	
	-- Send weapon animation
	if CLIENT then
		self:SendWeaponAnim(ACT_VM_HITCENTER)
	end
	
	if SERVER then
		local spos = ply:GetShootPos()
		local sdest = spos + (ply:GetAimVector() * self.SwordRange)
		
		local kmins = Vector(1,1,1) * -15
		local kmaxs = Vector(1,1,1) * 15
		
		local tr = util.TraceHull({
			start = spos, 
			endpos = sdest, 
			filter = ply, 
			mask = MASK_SHOT_HULL, 
			mins = kmins, 
			maxs = kmaxs
		})
		
		-- Hull might hit environment stuff that line does not hit
		if not IsValid(tr.Entity) then
			tr = util.TraceLine({
				start = spos, 
				endpos = sdest, 
				filter = ply, 
				mask = MASK_SHOT_HULL
			})
		end
		
		local hitEnt = tr.Entity
		local hit = false
		
		if IsValid(hitEnt) then
			-- Damage only non-SCP players and SCP-035
			if hitEnt:IsPlayer() and (hitEnt:GTeam() != TEAM_SCP or hitEnt:GetNClass() == ROLES.ROLE_SCP035) then
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(self.SwordDamage)
				dmginfo:SetDamageType(DMG_SLASH)
				dmginfo:SetAttacker(ply)
				dmginfo:SetInflictor(self)
				dmginfo:SetDamagePosition(tr.HitPos)
				
				hitEnt:TakeDamageInfo(dmginfo)
				hit = true
			end
			
			-- Damage breakable entities
			if hitEnt:GetClass() == "func_breakable" or 
			   hitEnt:GetClass() == "func_breakable_surf" or
			   hitEnt:GetClass() == "prop_physics" or
			   hitEnt:GetClass() == "prop_dynamic" then
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(self.SwordDamage)
				dmginfo:SetDamageType(DMG_SLASH)
				dmginfo:SetAttacker(ply)
				dmginfo:SetInflictor(self)
				dmginfo:SetDamagePosition(tr.HitPos)
				
				hitEnt:TakeDamageInfo(dmginfo)
				hit = true
			end
		end
		
		-- Network hit effect
		net.Start("scp_steve_j_sword_hit")
		net.WriteBool(hit)
		net.WriteVector(tr.HitPos)
		net.WriteVector(tr.Normal)
		net.Broadcast()
		
		-- Play attack animation
		ply:SetAnimation(PLAYER_ATTACK1)
		
		-- Play sound
		if hit then
			self:EmitSound("Weapon_Crowbar.Melee_Hit")
		else
			self:EmitSound("Zombie.AttackMiss")
		end
	end
end

function SWEP:SecondaryAttack()
	if not IsFirstTimePredicted() then return end
	if CurTime() < self.NextPearlThrow then return end
	
	self:ThrowEnderPearl()
	self.NextPearlThrow = CurTime() + self.PearlDelay
end

function SWEP:ThrowEnderPearl()
	if not IsValid(self.Owner) then return end
	
	local ply = self.Owner
	
	-- Send weapon animation
	if CLIENT then
		self:SendWeaponAnim(ACT_VM_THROW)
		timer.Create("steve_j_draw_" .. self:EntIndex(), 0.35, 1, function() 
			if IsValid(self) then 
				self:SendWeaponAnim(ACT_VM_DRAW) 
			end 
		end)
	end
	
	if SERVER then
		local eyePos = ply:EyePos()
		local eyeAng = ply:EyeAngles()
		local forward = eyeAng:Forward()
		
		-- Create ender pearl entity using original entity
		local pearl = ents.Create("ender_pearl")
		if not IsValid(pearl) then return end
		
		pearl:SetModel("models/lolixtin/ender_pearl.mdl")
		pearl:SetPos(ply:GetShootPos())
		pearl:SetAngles(ply:EyeAngles() + Angle(0, 0, 90))
		pearl:SetOwner(ply)
		pearl:Spawn()
		
		-- Set physics velocity like in original
		local phys = pearl:GetPhysicsObject()
		if IsValid(phys) then
			phys:AddVelocity(pearl:GetForward() * 3000)
		end
		
		-- Play throw sound
		ply:EmitSound("throw.wav", 75, math.random(90, 110))
	end
end

function SWEP:Reload()
	-- No reload
end

function SWEP:Think()
	-- No special think behavior needed
end



if CLIENT then
	function SWEP:DrawHUD()
		if disablehud == true then return end
		
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		
		-- Draw standard SCP HUD
		self:DrawSCPHUD()
		
		-- Draw crosshair
		local centerX, centerY = ScrW() / 2, ScrH() / 2
		surface.SetDrawColor(0, 255, 0, 200)
		surface.DrawLine(centerX - 10, centerY, centerX + 10, centerY)
		surface.DrawLine(centerX, centerY - 10, centerX, centerY + 10)
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
		local titleW, titleH = surface.GetTextSize("SCP-Steve-J")
		surface.SetTextPos(centerX - titleW / 2, hudY + 10)
		surface.DrawText("SCP-Steve-J")
		
		-- Cooldowny
		local cooldownY = hudY + 60
		local barWidth = 120
		local barHeight = 8
		local spacing = 20
		local totalWidth = barWidth * 2 + spacing
		local startX = centerX - totalWidth / 2
		
		-- LMB Cooldown (Sword)
		local lmbBarX = startX
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		surface.SetTextPos(lmbBarX, cooldownY - 15)
		surface.DrawText("LMB - Diamond Sword")
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
		
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
		
		local swordCooldown = math.max(0, self.NextSwordAttack - CurTime())
		
		if swordCooldown > 0 then
			local progress = 1 - (swordCooldown / self.SwordDelay)
			surface.SetDrawColor(255, 200, 0, 200)
			surface.DrawRect(lmbBarX, cooldownY, barWidth * progress, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(255, 255, 150, 255)
			surface.SetTextPos(lmbBarX, cooldownY + 10)
			surface.DrawText(string.format("%.1fs", swordCooldown))
		else
			surface.SetDrawColor(100, 255, 100, 255)
			surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(150, 255, 150, 255)
			surface.SetTextPos(lmbBarX, cooldownY + 10)
			surface.DrawText("READY")
		end
		
		-- RMB Cooldown (Ender Pearl)
		local rmbBarX = startX + barWidth + spacing
		surface.SetTextColor(200, 200, 200, 255)
		surface.SetFont("DermaDefaultBold")
		surface.SetTextPos(rmbBarX, cooldownY - 15)
		surface.DrawText("RMB - Ender Pearl")
		
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
		
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
		
		local pearlCooldown = math.max(0, self.NextPearlThrow - CurTime())
		
		if pearlCooldown > 0 then
			local progress = 1 - (pearlCooldown / self.PearlDelay)
			surface.SetDrawColor(255, 100, 255, 200)
			surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(255, 150, 255, 255)
			surface.SetTextPos(rmbBarX, cooldownY + 10)
			surface.DrawText(string.format("%.1fs", pearlCooldown))
		else
			surface.SetDrawColor(100, 255, 100, 255)
			surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(150, 255, 150, 255)
			surface.SetTextPos(rmbBarX, cooldownY + 10)
			surface.DrawText("READY")
		end
	end

	-- SWEP Construction Kit functions
	SWEP.vRenderOrder = nil
	function SWEP:ViewModelDrawn()
		
		local vm = self.Owner:GetViewModel()
		if !IsValid(vm) then return end
		
		if (!self.VElements) then return end
		
		self:UpdateBonePositions(vm)

		if (!self.vRenderOrder) then
			
			// we build a render order because sprites need to be drawn after models
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
				//model:SetModelScale(v.size)
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
			// when the weapon is dropped
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
				//model:SetModelScale(v.size)
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
			
			// Technically, if there exists an element with the same name as a bone
			// you can get in an infinite loop. Let's just hope nobody's that stupid.
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
				ang.r = -ang.r // Fixes mirrored models
			end
		
		end
		
		return pos, ang
	end

	function SWEP:CreateModels( tab )

		if (!tab) then return end

		// Create the clientside models here because Garry says we can't do it in the render hook
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
				// make sure we create a unique name based on the selected options
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
			
			// !! WORKAROUND !! //
			// We need to check all model names :/
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
			// !! ----------- !! //
			
			for k, v in pairs( loopthrough ) do
				local bone = vm:LookupBone(k)
				if (!bone) then continue end
				
				// !! WORKAROUND !! //
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
				// !! ----------- !! //
				
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
	
	-- Receive sword hit effect
	net.Receive("scp_steve_j_sword_hit", function()
		local hit = net.ReadBool()
		local hitPos = net.ReadVector()
		local normal = net.ReadVector()
		
		if hit then
			-- Blood effect for hits
			local effectdata = EffectData()
			effectdata:SetOrigin(hitPos)
			effectdata:SetNormal(normal)
			util.Effect("BloodImpact", effectdata)
		end
	end)
	
	-- Receive pearl teleport effect
	net.Receive("scp_steve_j_pearl_throw", function()
		local pos = net.ReadVector()
		-- Additional client effects can be added here
	end)
end

/**************************
	Global utility code
**************************/

// Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
// Does not copy entities of course, only copies their reference.
// WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
function table.FullCopy( tab )

	if (!tab) then return nil end
	
	local res = {}
	for k, v in pairs( tab ) do
		if (type(v) == "table") then
			res[k] = table.FullCopy(v) // recursion ho!
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