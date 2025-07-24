AddCSLuaFile()

SWEP.Base = "weapon_base"

SWEP.PrintName = "Kapkan Mines Placer"
SWEP.Category = "Arsen's Gadgets"
SWEP.Icon = "entities/weapon_kapkan_placer.png"
SWEP.Author = "Arsen"
SWEP.Instructions = "LMB - place mine, RMB - change direction"

SWEP.Slot = 4            
SWEP.DrawAmmo = false      
SWEP.DrawCrosshair = true 
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.HoldType = "slam"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true

SWEP.ViewModelBoneMods = {
    ["ValveBiped.Bip01_L_Finger1"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(36.575, -21.084, -52.669) },
    ["ValveBiped.Bip01_L_Finger11"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -15.877, 0) },
    ["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(-11.183, 4.473, 1.958), angle = Angle(4.281, 16.481, -23.729) },
    ["ValveBiped.Bip01_R_Forearm"] = { scale = Vector(1, 1, 1), pos = Vector(0, 1.606, 2.686), angle = Angle(0, 0, 0) },
    ["ValveBiped.Bip01_R_UpperArm"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-10.254, -1.499, 14.039) },
    ["Detonator"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, -30), angle = Angle(0, 0, 0) },
    ["ValveBiped.Bip01_L_UpperArm"] = { scale = Vector(1, 1, 1), pos = Vector(-0.213, -0.352, 1.108), angle = Angle(10.994, -5.578, -20.146) },
    ["ValveBiped.Bip01_L_Finger4"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(5.682, 0, 0) },
    ["ValveBiped.Bip01_R_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(0.172, -0.935, 0), angle = Angle(3.621, 3.484, 1.598) },
    ["Slam_base"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(-30, -30, -30), angle = Angle(10, 0, 0) },
    ["ValveBiped.Bip01_R_Hand"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(32.2, 41.077, 0.694) }
}

SWEP.VElements = {
    ["Trimpine"] = { type = "Model", model = "models/arsen/Tripmine.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.454, 5.084, 1.241), angle = Angle(-101.689, 80.649, 78.311), size = Vector(0.61, 0.61, 0.61), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
    ["Tripmine"] = { type = "Model", model = "models/arsen/Tripmine.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.22, 4.419, -1.759), angle = Angle(50.432, 0, 0), size = Vector(0.791, 0.791, 0.791), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.DrawAmmo = false

local lastToggleTime = 0
local SOUND_TOGGLE = "buttons/lightswitch2.wav"
local SOUND_PLACE = "buttons/button19.wav"

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "PlaceSide")
    self:NetworkVar("Int", 1, "RemainingUses")
    
    if SERVER then
        self:SetPlaceSide(1)
        self:SetRemainingUses(KAPKAN_CONFIG.MaxUses)
    end
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    
    if CLIENT then
        self:CreateModels(self.VElements)
        self:CreateModels(self.WElements)
        
        if IsValid(self.Owner) then
            local vm = self.Owner:GetViewModel()
            if IsValid(vm) then
                self:ResetBonePositions(vm)
            end
        end
    end
end

function SWEP:PrimaryAttack()
    if CLIENT then return end
    
    local ply = self:GetOwner()
    if self:GetRemainingUses() <= 0 then
        ply:ChatPrint("Out of charges!")
        return
    end

    if self.NextPlacement and self.NextPlacement > CurTime() then
        return
    end

    local tr = ply:GetEyeTrace()
    if not tr.Hit or not tr.HitNormal or tr.HitPos:DistToSqr(ply:GetPos()) > KAPKAN_CONFIG.MaxPlaceDistance * KAPKAN_CONFIG.MaxPlaceDistance then 
        return 
    end

    local ent = ents.Create("ent_kapkan_mine")
    if not IsValid(ent) then return end

    local spawnPos = tr.HitPos + tr.HitNormal * 1
    local ang = tr.HitNormal:Angle()
    ang:RotateAroundAxis(ang:Up(), self:GetPlaceSide())

    ent:SetPos(spawnPos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:SetNWInt("ExplosionDamage", KAPKAN_CONFIG.ExplosionDamage)
    ent:GetPhysicsObject():EnableMotion(false)

    if KAPKAN_CONFIG.AllowUndo and undo and undo.Create and undo.AddEntity and undo.SetPlayer and undo.Finish then
        undo.Create("Kapkan Mine")
            undo.AddEntity(ent)
            undo.SetPlayer(ply)
        undo.Finish()
    end

    self:EmitSound(SOUND_PLACE)
    self:SetRemainingUses(self:GetRemainingUses() - 1)
    
    if self:GetRemainingUses() <= 0 then
        timer.Simple(0.1, function()
            if IsValid(ply) and IsValid(self) then
                ply:StripWeapon(self:GetClass())
            end
        end)
    end
    
    self:SetNextPrimaryFire(CurTime() + 0.1)
    self.NextPlacement = CurTime() + KAPKAN_CONFIG.PlacementDelay
end

function SWEP:SecondaryAttack()
    if CurTime() - lastToggleTime < 0.2 then return end
    lastToggleTime = CurTime()
    
    local currentSide = self:GetPlaceSide()
    self:SetPlaceSide(currentSide == 1 and 180 or 1)
    self:EmitSound(SOUND_TOGGLE)
    self:SetNextSecondaryFire(CurTime() + 0.3)
end

function SWEP:Reload()
    return
end

if CLIENT then
    function SWEP:DrawHUD()
        local ply = LocalPlayer()
        local tr = ply:GetEyeTrace()
        if not tr.Hit or tr.HitPos:DistToSqr(ply:GetPos()) > KAPKAN_CONFIG.MaxPlaceDistance * KAPKAN_CONFIG.MaxPlaceDistance then return end

        cam.Start3D(EyePos(), EyeAngles())
            render.SetColorMaterial()
            local ang = tr.HitNormal:Angle()
            ang:RotateAroundAxis(ang:Up(), self:GetPlaceSide())
            local pos = tr.HitPos + tr.HitNormal * 1

            render.DrawWireframeBox(pos, ang, Vector(-8, -8, -8), Vector(8, 8, 8), Color(255, 0, 0, 200), true)
            render.DrawLine(pos, pos + ang:Right() * 10, Color(0,255,0), true)
            
            cam.Start2D()
                draw.SimpleText("Charges: "..self:GetRemainingUses(), "DermaDefault", ScrW()/2, ScrH()/2 + 50, Color(255,255,255), TEXT_ALIGN_CENTER)
            cam.End2D()
        cam.End3D()
    end

    -- Create convars
    if not ConVarExists("kapkan_max_uses") then
        CreateClientConVar("kapkan_max_uses", KAPKAN_CONFIG.MaxUses, true, false)
        CreateClientConVar("kapkan_explosion_dmg", KAPKAN_CONFIG.ExplosionDamage, true, false)
        CreateClientConVar("kapkan_explosion_delay", KAPKAN_CONFIG.ExplosionDelay, true, false)
        CreateClientConVar("kapkan_laser_length", KAPKAN_CONFIG.LaserLength, true, false)
        CreateClientConVar("kapkan_mine_health", KAPKAN_CONFIG.MineHealth, true, false)
        CreateClientConVar("kapkan_allow_undo", KAPKAN_CONFIG.AllowUndo and 1 or 0, true, false)
        CreateClientConVar("kapkan_placement_delay", KAPKAN_CONFIG.PlacementDelay, true, false)
        CreateClientConVar("kapkan_player_collisions", KAPKAN_CONFIG.PlayerCollisions and 1 or 0, true, false)
    end

    -- Utilities Menu
    hook.Add("PopulateToolMenu", "KapkanSettingsMenu", function()
        spawnmenu.AddToolMenuOption("Utilities", "Admin", "KapkanConfig", "Kapkan Mines", "", "", function(panel)
            panel:ClearControls()
            
            panel:Help("Configure Kapkan Mine settings")
            
            panel:NumSlider("Max Uses", "kapkan_max_uses", 1, 10, 0)
            GetConVar("kapkan_max_uses"):SetInt(KAPKAN_CONFIG.MaxUses)
            panel:ControlHelp("Number of mines each placer can deploy")
            
            panel:NumSlider("Explosion Damage", "kapkan_explosion_dmg", 50, 500, 0)
            GetConVar("kapkan_explosion_dmg"):SetInt(KAPKAN_CONFIG.ExplosionDamage)
            panel:ControlHelp("Damage dealt when mine explodes")
            
            panel:NumSlider("Explosion Delay", "kapkan_explosion_delay", 0.1, 5, 1)
            GetConVar("kapkan_explosion_delay"):SetFloat(KAPKAN_CONFIG.ExplosionDelay)
            panel:ControlHelp("Delay before explosion after trigger (seconds)")
            
            panel:NumSlider("Laser Length", "kapkan_laser_length", 50, 300, 0)
            GetConVar("kapkan_laser_length"):SetInt(KAPKAN_CONFIG.LaserLength)
            panel:ControlHelp("Length of the detection laser")
            
            panel:NumSlider("Mine Health", "kapkan_mine_health", 1, 50, 0)
            GetConVar("kapkan_mine_health"):SetInt(KAPKAN_CONFIG.MineHealth)
            panel:ControlHelp("How much damage the mine can take")
            
            panel:CheckBox("Allow Undo", "kapkan_allow_undo")
            GetConVar("kapkan_allow_undo"):SetBool(KAPKAN_CONFIG.AllowUndo)
            panel:ControlHelp("Allow players to undo placements")
            
            panel:CheckBox("Player Collisions", "kapkan_player_collisions")
			GetConVar("kapkan_player_collisions"):SetBool(KAPKAN_CONFIG.PlayerCollisions)
			panel:ControlHelp("Whether mines collide with players")
            
            panel:NumSlider("Placement Delay", "kapkan_placement_delay", 0, 5, 2)
            GetConVar("kapkan_placement_delay"):SetFloat(KAPKAN_CONFIG.PlacementDelay)
            panel:ControlHelp("Delay between placing mines (seconds)")
            
            panel:Button("Apply Settings", "kapkan_apply_settings")
            panel:Button("Reset to Default", "kapkan_reset_settings")
        end)
    end)

    concommand.Add("kapkan_apply_settings", function()
        if not LocalPlayer():IsAdmin() then return end
        
        net.Start("UpdateKapkanConfig")
            net.WriteTable({
                MaxUses = GetConVar("kapkan_max_uses"):GetInt(),
                ExplosionDamage = GetConVar("kapkan_explosion_dmg"):GetInt(),
                ExplosionDelay = GetConVar("kapkan_explosion_delay"):GetFloat(),
                LaserLength = GetConVar("kapkan_laser_length"):GetInt(),
                MineHealth = GetConVar("kapkan_mine_health"):GetInt(),
                AllowUndo = GetConVar("kapkan_allow_undo"):GetBool(),
                PlayerCollisions = GetConVar("kapkan_player_collisions"):GetBool(),
                MaxPlaceDistance = 150,
                PlacementDelay = GetConVar("kapkan_placement_delay"):GetFloat()
            })
        net.SendToServer()
        
        LocalPlayer():ChatPrint("Kapkan Mines settings applied!")
    end)

    concommand.Add("kapkan_reset_settings", function()
        if not LocalPlayer():IsAdmin() then return end
        
        GetConVar("kapkan_max_uses"):SetInt(4)
        GetConVar("kapkan_explosion_dmg"):SetInt(95)
        GetConVar("kapkan_explosion_delay"):SetFloat(0.5)
        GetConVar("kapkan_laser_length"):SetInt(80)
        GetConVar("kapkan_mine_health"):SetInt(10)
        GetConVar("kapkan_allow_undo"):SetBool(true)
        GetConVar("kapkan_player_collisions"):SetBool(false)
        GetConVar("kapkan_placement_delay"):SetFloat(0.9)
    end)

    SWEP.WepSelectIcon = surface.GetTextureID("vgui/weapons/arsen/weapon_kapkan_placer")
    SWEP.BounceWeaponIcon = false 
    killicon.Add("weapon_hdevice", "gui/weapons/arsen/weapon_kapkan_placer", Color(255, 255, 255, 255))
end

/********************************************************
	SWEP Construction Kit base code
		Created by Clavus
	Available for public use, thread at:
	   facepunch.com/threads/1032378
	   
	   
	DESCRIPTION:
		This script is meant for experienced scripters 
		that KNOW WHAT THEY ARE DOING. Don't come to me 
		with basic Lua questions.
		
		Just copy into your SWEP or SWEP base of choice
		and merge with your own code.
		
		The SWEP.VElements, SWEP.WElements and
		SWEP.ViewModelBoneMods tables are all optional
		and only have to be visible to the client.
********************************************************/

function SWEP:Initialize()

	// other initialize code goes here

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

if CLIENT then

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
		
			bone = tab.bone
			
			if (!bone) then bone = bone_override end
			if (!bone) then return end
			
			pos, ang = Vector(0,0,0), Angle(0,0,0)
			local m = ent:GetBoneMatrix(ent:LookupBone(bone))
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
				
				local name = v.sprite..".vmt"
				v.spriteMaterial = Material(name)
				v.createdSprite = v.sprite
			end
		end
		
	end
	
	function SWEP:UpdateBonePositions(vm)
		
		if self.ViewModelBoneMods then
			
			if (!self.ViewModelBoneModData) then
				self.ViewModelBoneModData = {}
			end
			
			for k, v in pairs( self.ViewModelBoneMods ) do
				local bone = vm:LookupBone(k)
				if (!bone) then continue end
				
				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms = Vector(1,1,1)
				if (!self.ViewModelBoneModData[bone]) then
					self.ViewModelBoneModData[bone] = { 
						s = ms,
						p = p, 
						ms = ms
					}
				end
				
				local d = self.ViewModelBoneModData[bone]
				
				if (d.s != s) then vm:ManipulateBoneScale( bone, s ) d.s = s end
				if (d.p != p) then vm:ManipulateBonePosition( bone, p ) d.p = p end
				if (d.ms != ms) then vm:ManipulateBoneScale( bone, ms ) d.ms = ms end
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

	/**************************
		Global utility code
	**************************/

	// Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
	// Does not copy entities of course, only copies their reference.
	// WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
	function table.FullCopy( t )

		if (!t) then return end
		
		local res = {}
		for k, v in pairs( t ) do
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
	
end