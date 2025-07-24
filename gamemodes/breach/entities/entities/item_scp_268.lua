AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"

ENT.PrintName = "SCP-268"
ENT.Author = "Breach Team"
ENT.Category = "SCP"
ENT.Spawnable = true
ENT.AdminSpawnable = true

function ENT:Initialize()
	-- Ustawienie modelu berreta
	self:SetModel("models/thenextscp/scp268/berret.mdl")
	
	if SERVER then
		-- Fizyka entity
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		
		-- Konfiguracja fizyki
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:SetMass(5) -- Lekki berret
		end
		
		-- Ustawienia kolizji
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		self:SetUseType(SIMPLE_USE)
	end
end

function ENT:Use(activator, caller)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	
	-- Sprawdź czy gracz może podnieść SCP-268
	if activator:GTeam() == TEAM_SPEC then return end
	
	-- Sprawdź czy gracz już ma SCP-268
	if activator:HasWeapon("item_scp_268") then
		if SERVER then
			activator:PrintMessage(HUD_PRINTTALK, "You already have SCP-268!")
		end
		return
	end
	
	-- Daj graczowi SCP-268
	if SERVER then
		activator:Give("item_scp_268")
		activator:PrintMessage(HUD_PRINTTALK, "You picked up SCP-268 - The Berret of Invisibility")
		activator:PrintMessage(HUD_PRINTTALK, "Left click to toggle invisibility while holding it")
		
		-- Usuń entity z mapy
		self:Remove()
	end
end

function ENT:Think()
	-- Lekka rotacja dla efektu wizualnego
	if SERVER then
		local angles = self:GetAngles()
		angles.y = angles.y + 1
		self:SetAngles(angles)
		self:NextThink(CurTime() + 0.1)
		return true
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		
		-- Efekt świecenia dla lepszej widoczności
		local glow = math.sin(CurTime() * 2) * 0.3 + 0.7
		render.SetBlend(glow)
		self:DrawModel()
		render.SetBlend(1)
	end
end 