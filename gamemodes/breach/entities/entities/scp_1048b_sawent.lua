AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Spawnable = false
ENT.Category = "SCP"
ENT.PrintName = "SCP-1048-B Saw"

function ENT:Initialize()
	self:SetModel("models/props_junk/sawblade001a.mdl")
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetModelScale(.5)
		self:SetUseType(SIMPLE_USE)
		self:Activate()
		
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:SetMass(10)
		end

		self.ply = nil
		
		-- Efekt trail
		util.SpriteTrail(self, 0, Color(255, 100, 100), false, 15, 1, 1, 1/(15+1)*0.5, "trails/laser.vmt")
	end
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Use(ply)
	if (not ply:IsPlayer()) then return end
	local wep = ply:GetActiveWeapon()
	if (not (wep:GetClass()=="weapon_scp_1048b")) then return end
	if wep.saw then return end
	if wep:get_saw() then self:Remove() end
end

function ENT:PhysicsCollide(data,phys)
	local speed = data.OurOldAngularVelocity:Length()
	local ent = data.HitEntity

	if (not IsValid(ent)) then return end
	if (speed<800) then return end
	
	-- Sprawdź czy to gracz i czy to SCP/SPEC - jeśli tak, NIE zadawaj obrażeń
	if ent:IsPlayer() then
		if ent:GTeam() == TEAM_SCP or ent:GTeam() == TEAM_SPEC then
			-- Tylko efekty wizualne, bez obrażeń
			local effect = EffectData()
			effect:SetOrigin(data.HitPos)
			self:EmitSound("npc/manhack/grind"..math.random(5)..".wav")
			util.Effect("ManhackSparks",effect)
			
			local phys = self:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetAngleVelocity(Vector(0,0,0))
				phys:SetVelocity(phys:GetVelocity()/2)
			end
			return
		end
	end

	-- Zadaj obrażenia tylko nie-SCP
	ent:TakeDamage(speed/15,self.ply,self)
	
	if ((ent:IsNPC() or ent:IsRagdoll()) or ent:IsPlayer()) then
		local effect = EffectData()
		effect:SetOrigin(data.HitPos)
		self:EmitSound("npc/manhack/grind_flesh"..math.random(3)..".wav")
		util.Effect("BloodImpact",effect)
		util.Decal("Blood",data.HitPos+data.HitNormal,data.HitPos-data.HitNormal)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetAngleVelocity(Vector(0,0,0))
			phys:SetVelocity(phys:GetVelocity()/2)
		end
	end
end