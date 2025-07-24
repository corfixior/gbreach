AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:Initialize()
	self:SetModel("models/lolixtin/ender_pearl.mdl")
	self:PhysicsInitSphere(6,"metal")
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
end

function ENT:OnRemove()
	local pos = nil
	local x = self:GetPos():ToTable()[1] - self:GetOwner():GetPos():ToTable()[1]
	local y = self:GetPos():ToTable()[2] - self:GetOwner():GetPos():ToTable()[2]
	if x > 0 then x=Vector(-20,0,0) else x=Vector(20,0,0) end
	if y > 0 then y=Vector(0,-20,0) else y=Vector(0,20,0) end
	pos = self:GetPos()+x+y;
	if self:GetOwner():GetAimVector():ToTable()[3] > 0 then pos = pos - Vector(0,0,self:GetOwner():GetAimVector():ToTable()[3])*100 end

	self:GetOwner():SetPos(pos)
end

function ENT:PhysicsCollide(cd,po)	
	self:EmitSound(Sound("portal"..math.random(1,2)..".wav"))
	local e = EffectData()
	e:SetOrigin(self:GetPos()+Vector(0,0,25))
	util.Effect("pearl_particle",e)
	self:Remove()
end 