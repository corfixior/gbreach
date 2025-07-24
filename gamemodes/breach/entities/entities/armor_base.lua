AddCSLuaFile()

ENT.PrintName		= "Base Armor"
ENT.Author		    = "Kanade"
ENT.Type			= "anim"
ENT.Spawnable		= true
ENT.AdminSpawnable	= true
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.ArmorType = "armor_mtfguard"

function ENT:Initialize()
	self.Entity:SetModel("models/combine_vests/militaryvest.mdl")
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	//self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_NONE)
	self.Entity:SetSolid(SOLID_BBOX)
	if SERVER then
		self:SetUseType(SIMPLE_USE)
	end
	
	//local phys = self.Entity:GetPhysicsObject()

	//if phys and phys:IsValid() then phys:Wake() end
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON) 
end

function ENT:Use(ply)
	if ply:GTeam() == TEAM_SPEC or ( ply:GTeam() == TEAM_SCP and ply:GetNClass() != ROLES.ROLE_SCP9571 and ply:GetNClass() != ROLES.ROLE_SCP035 ) or ply:Alive() == false then return end
	if ply.UsingArmor != nil then
		ply:PrintMessage(HUD_PRINTTALK, 'You already have a vest, type "dropvest" in the chat to drop it')
		return
	end
	-- Security Droid nie może nosić vestów
	if ply:GetNClass() == ROLES.ROLE_SECURITY_DROID then
		ply:PrintMessage(HUD_PRINTTALK, "[SYSTEM] ERROR: Armor incompatible with droid chassis!")
		ply:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 75, math.random(90, 110))
		return
	end
	-- SCP-035 system vestów
	if ply:GetNClass() == ROLES.ROLE_SCP035 then
		if ply.LockedArmor == true then
			-- Miał vest przed transformacją - nie może go zmienić
			ply:PrintMessage(HUD_PRINTTALK, "[SCP-035] Your vest is fused with your body and cannot be changed!")
			print("[SCP-035 DEBUG] " .. ply:Nick() .. " tried to change locked vest")
			return
		elseif ply.LockedArmor == false then
			-- Nie miał vesta przed transformacją - nie może założyć żadnego
			ply:PrintMessage(HUD_PRINTTALK, "[SCP-035] The vest phases through your corrupted body...")
			print("[SCP-035 DEBUG] " .. ply:Nick() .. " tried to equip vest but had none before transformation")
			return
		else
			-- LockedArmor nie jest ustawione - gracz nie był SCP-035 od początku
			ply:PrintMessage(HUD_PRINTTALK, "[SCP-035] ERROR: Invalid vest state for SCP-035!")
			print("[SCP-035 ERROR] " .. ply:Nick() .. " has undefined LockedArmor state")
			return
		end
	end

	if SERVER then
		ply:ApplyArmor(self.ArmorType)
		self:EmitSound( Sound("npc/combine_soldier/gear".. math.random(1, 6).. ".wav") )
		self:Remove()
		ply.UsingArmor = self.ArmorType
	end
	if CLIENT then
		chat.AddText('You are now wearing an armor, type "dropvest" in the chat to drop it')
	end
end

function ENT:Draw()
	self:DrawModel()
	local ply = LocalPlayer()
	if ply:GetPos():Distance(self:GetPos()) > 180 then
		return
	end
	if IsValid(self) then
		cam.Start2D()
			if DrawInfo != nil then
				DrawInfo(self:GetPos() + Vector(0,0,15), self.PrintName, Color(255,255,255))
			end
		cam.End2D()
	end
end