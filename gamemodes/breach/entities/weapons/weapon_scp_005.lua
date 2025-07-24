if CLIENT then
SWEP.DrawWeaponInfoBox	= false
SWEP.BounceWeaponIcon	= false 

SWEP.WepSelectIcon = surface.GetTextureID("vgui/entities/weapon_scp-005") 

language.Add("weapon_scp-005", "SCP-005")
end

SWEP.PrintName = "SCP-005"
SWEP.Category = "SCP: Breach"
SWEP.Spawnable= false
SWEP.AdminSpawnable= false
SWEP.AdminOnly = false

SWEP.ViewModelFOV = 70
SWEP.ViewModel = "models/weapons/c_invisstick2.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.ViewModelFlip = false
SWEP.BobScale = 1
SWEP.SwayScale = 1
SWEP.UseHands = true

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Weight = 0
SWEP.Slot = 3
SWEP.SlotPos = 1
SWEP.HoldType = "pistol"
SWEP.FiresUnderwater = true
SWEP.DrawCrosshair = true
SWEP.DrawAmmo = true
SWEP.CSMuzzleFlashes = 1
SWEP.Base = "weapon_base"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 0.8

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 1

SWEP.ViewModelBoneMods = {
	["ValveBiped.Bip01_R_UpperArm"] = { scale = Vector(1, 1, 1), pos = Vector(-3.754, 4.111, 11.953), angle = Angle(0, -11.072, 0) }
}

SWEP.VElements = {
	["v_element"] = { type = "Model", model = "models/scp/005/scp005.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(9.958, 3.131, -0.251), angle = Angle(0, 156.085, -93.541), size = Vector(0.8, 0.8, 0.8), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["w_element"] = { type = "Model", model = "models/scp/005/scp005.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(8.206, 1.649, 0), angle = Angle(0, 164.302, -92.001), size = Vector(0.699, 0.699, 0.699), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

function SWEP:Initialize()
	self:SetWeaponHoldType( self.HoldType )
	self:SetHoldType( self.HoldType )
	
	self.Idle = 0
	self.IdleTimer = CurTime() + 1
	
	if CLIENT then
	
		-- Create a new table for every weapon instance
		self.VElements = table.FullCopy( self.VElements )
		self.WElements = table.FullCopy( self.WElements )
		self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )
        self:SetWeaponHoldType( self.HoldType )
		
		self:CreateModels(self.VElements) -- create viewmodels
		self:CreateModels(self.WElements) -- create worldmodels
		
		-- init view model bone build function
		if IsValid(self.Owner) then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
				
				-- Init viewmodel visibility
				if (self.ShowViewModel == nil or self.ShowViewModel) then
					vm:SetColor(Color(255,255,255,255))
				else
					-- we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
					vm:SetColor(Color(255,255,255,1))
					-- ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
					-- however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
					vm:SetMaterial("Debug/hsv")			
				end
			end
		end
	end
end

----------------------------------------------------
if CLIENT then

	SWEP.vRenderOrder = nil
	function SWEP:ViewModelDrawn()
		
		local vm = self.Owner:GetViewModel()
		if !IsValid(vm) then return end
		
		if (!self.VElements) then return end
		
		self:UpdateBonePositions(vm)

		if (!self.vRenderOrder) then
			
			-- we build a render order because sprites need to be drawn after models
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
				--model:SetModelScale(v.size)
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
			-- when the weapon is dropped
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
				--model:SetModelScale(v.size)
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
				ang.r = -ang.r -- Fixes mirrored models
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
				-- make sure we create a unique name based on the selected options
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
			
			-- !! WORKAROUND !! --
			-- We need to check all model names :/
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
			-- !! ----------- !! --
			
			for k, v in pairs( loopthrough ) do
				local bone = vm:LookupBone(k)
				if (!bone) then continue end
				
				-- !! WORKAROUND !! --
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
				-- !! ----------- !! --
				
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
----------------------------------------------------

function SWEP:Think()
	if self.Idle == 0 and self.IdleTimer <= CurTime() then
		if SERVER then
			self.Weapon:SendWeaponAnim( ACT_VM_IDLE )
		end
		self.Idle = 1
	end
end

-- Funkcja do znajdowania wszystkich części drzwi w pobliżu (skopiowana z Door Controller)
local function GetAllDoorParts(mainDoor, searchRadius)
	if not IsValid(mainDoor) then return {} end
	
	local doorParts = {mainDoor}
	local mainPos = mainDoor:GetPos()
	local searchRange = searchRadius or 20 -- Domyślny zasięg dla SCP-005
	
	-- Znajdź wszystkie entity w pobliżu
	local nearbyEnts = ents.FindInSphere(mainPos, searchRange)
	
	for _, ent in pairs(nearbyEnts) do
		if IsValid(ent) and ent ~= mainDoor then
			local class = ent:GetClass():lower()
			local isDoorEntity = false
			
			-- Sprawdź czy to entity drzwiowe
			if class:find("door") or class == "func_door" or class == "func_door_rotating" or class == "prop_door_rotating" then
				isDoorEntity = true
			elseif ent.IsDoor and ent:IsDoor() then
				isDoorEntity = true
			end
			
			-- Jeśli to część drzwi, dodaj do listy
			if isDoorEntity then
				-- Sprawdź czy już nie ma tego w tablicy
				local alreadyAdded = false
				for _, existingDoor in pairs(doorParts) do
					if existingDoor == ent then
						alreadyAdded = true
						break
					end
				end
				
				if not alreadyAdded then
					table.insert(doorParts, ent)
				end
			end
		end
	end
	
	return doorParts
end

local function GetDoor(ply)
	local tr = ply:GetEyeTrace()
	local ent = tr.Entity

	local maxDist = 70 -- Zasięg SCP-005
	if not IsValid(ent) or tr.HitPos:DistToSqr(ply:GetShootPos()) > maxDist * maxDist then return nil end

	local class = ent:GetClass():lower()
	local mainDoor = nil

	if class:find("door") or class == "func_door" or class == "func_door_rotating" or class == "prop_door_rotating" then
		mainDoor = ent
	elseif ent.IsDoor and ent:IsDoor() then
		mainDoor = ent
	else
		local parent = ent:GetParent()
		if IsValid(parent) then
			local parentClass = parent:GetClass():lower()
			if parentClass:find("door") or parentClass == "func_door" or parentClass == "func_door_rotating" or parentClass == "prop_door_rotating" then
				mainDoor = parent
			elseif parent.IsDoor and parent:IsDoor() then
				mainDoor = parent
			end
		end

		if not mainDoor and (ent:GetClass() == "prop_dynamic" or ent:GetClass() == "prop_physics") then
			local constraints = constraint.GetAllConstrainedEntities(ent)
			for _, constrainedEnt in pairs(constraints) do
				local class = constrainedEnt:GetClass():lower()
				if class:find("door") or constrainedEnt.IsDoor and constrainedEnt:IsDoor() then
					mainDoor = constrainedEnt
					break
				end
			end
		end
	end

	-- Jeśli znaleźliśmy główne drzwi, znajdź wszystkie części
	if mainDoor then
		return GetAllDoorParts(mainDoor)
	end

	return nil
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime()+1)
	
	if CLIENT then return end
	
	local ply = self.Owner
	if not IsValid(ply) then return end
	
	local doorOpened = false
	
	-- Użyj nowego systemu dobierania drzwi
	local doorParts = GetDoor(ply)
	
	if not doorParts or #doorParts == 0 then
		-- Sprawdź czy to przycisk lub prop_dynamic (zachowaj oryginalną funkcjonalność)
		local tr = {}
		tr.start = ply:GetShootPos()
		tr.endpos = ply:GetShootPos() + ( ply:GetAimVector() * 70 )
		tr.filter = ply
		tr.mask = MASK_SHOT_HULL

		local trace = util.TraceLine( tr )
		
		if trace.Hit then
			local v = trace.Entity
			if v:GetClass():find("func_button") then
				self.Weapon:SendWeaponAnim(ACT_VM_HITCENTER)
				self:SetNextPrimaryFire(CurTime()+1)
				v:Input("Unlock")
				v:Input("Use")
				doorOpened = true
			elseif v:GetClass():find("prop_dynamic") then
				if v:GetModel():find("door") or v:GetModel():find("fence") or v:GetModel():find("gate") then
					self.Weapon:SendWeaponAnim(ACT_VM_HITCENTER)
					self:SetNextPrimaryFire(CurTime()+6)
					if v:GetSequence() == 1 or v:GetSequence() == 0 or v:GetSequence() == 3 then
						v:Fire("setanimation","open","0")
						sound.Play("ambient/levels/outland/ol12a_slidergate_open.wav", v:GetPos() + Vector(0,0,30), 75, 100)
					elseif v:GetSequence() == 2 then
						v:Fire("setanimation","close","0")
						sound.Play("ambient/levels/outland/ol12a_slidergate_close.wav", v:GetPos() + Vector(0,0,30), 75, 100)
					end
					sound.Play("plats/hall_elev_door.wav", v:GetPos() + Vector(0,0,30), 75, 100)
					sound.Play("plats/hall_elev_door.wav", v:GetPos() + Vector(0,0,30), 75, 100)
					sound.Play("plats/hall_elev_door.wav", v:GetPos() + Vector(0,0,30), 75, 100)
					sound.Play("plats/hall_elev_door.wav", v:GetPos() + Vector(0,0,30), 75, 100)
					sound.Play("ambient/levels/outland/ol11_blastdoorlatch.wav", v:GetPos() + Vector(0,0,30), 75, 100)
					local noor = v:GetParent()
					if IsValid(noor) then
						noor:Input("Unlock")
						noor:Input("Use")
					end
					doorOpened = true
				end
			end
		end
	else
		-- Otwórz wszystkie części drzwi
		self.Weapon:SendWeaponAnim(ACT_VM_HITCENTER)
		self:SetNextPrimaryFire(CurTime()+1)
		
		for _, door in pairs(doorParts) do
			if IsValid(door) then
				door:Input("Unlock")
				door:Input("Open")
				sound.Play("ambient/levels/outland/ol11_blastdoorlatch.wav", door:GetPos() + Vector(0,0,30), 75, 100)
			end
		end
		doorOpened = true
	end
	
	-- Jeśli drzwi zostały otwarte, zniszcz SCP-005
	if doorOpened then
		timer.Simple(0.5, function()
			if IsValid(self) and IsValid(ply) then
				ply:PrintMessage(HUD_PRINTCENTER, "SCP-005 has been destroyed after use")
				ply:StripWeapon("weapon_scp_005")
			end
		end)
	end
	
	ply:SetAnimation( PLAYER_ATTACK1 )
	self.Idle = 0
	self.IdleTimer = CurTime() + ply:GetViewModel():SequenceDuration()
end

function SWEP:SecondaryAttack()
end

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_DRAW)
	self.Idle = 0
	self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
end

function SWEP:Holster()
	self.Idle = 0
	self.IdleTimer = CurTime()

	if CLIENT and IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
			self.Owner:SetFOV( 0, 0.25 )
		end
	end
	return true
end

function SWEP:OnRemove()
	self:Holster()
end

function SWEP:OnDrop()
	self:Holster()
end