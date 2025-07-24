AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	-- Ustawienie modelu okularów
	self:SetModel("models/maxpayne/weapons/shades.mdl")
	
	if SERVER then
		-- Fizyka entity
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		
		-- Konfiguracja fizyki
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:SetMass(2) -- Lekkie okulary
		end
		
		-- Ustawienia kolizji
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		self:SetUseType(SIMPLE_USE)
	end
end

function ENT:Use(activator, caller)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	
	-- Sprawdź czy gracz może podnieść SCP-215
	if activator:GTeam() == TEAM_SPEC then return end
	
	-- Sprawdź czy gracz już ma SCP-215
	if activator:HasWeapon("item_scp_215") then
		return
	end
	
	-- Daj graczowi SCP-215
	if SERVER then
		activator:Give("item_scp_215")
		
		-- Usuń entity z mapy
		self:Remove()
	end
end

function ENT:Think()
	-- Lekka rotacja dla efektu wizualnego
	if SERVER then
		local angles = self:GetAngles()
		angles.y = angles.y + 0.5
		self:SetAngles(angles)
		self:NextThink(CurTime() + 0.1)
		return true
	end
end