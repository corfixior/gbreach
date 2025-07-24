AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"

ENT.Author = "danx91"

ENT.HP = 500

function ENT:Initialize()
	-- Zmiana modelu na kostkę
	self:SetModel( "models/hunter/blocks/cube075x075x075.mdl" )
	self:SetModelScale( 0.75 ) -- Mniejsza kostka
	
	-- Ustawienie szarego koloru
	self:SetColor(Color(128, 128, 128))
	self:SetMaterial("models/debug/debugwhite")

	if SERVER then
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
		self:CollisionRulesChanged()

		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )

		self:PhysicsInit( SOLID_VPHYSICS )
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:SetMass(1000) -- Ciężka kostka
		end
	end
end

function ENT:Think()
end

function ENT:OnTakeDamage( dmg )
	self.HP = self.HP - dmg:GetDamage()
	if self.HP <= 0 then
		local attacker = dmg:GetAttacker()
		if !attacker:IsPlayer() then return end
		if attacker:GTeam() == TEAM_SCP or attacker:GTeam() == TEAM_SPEC then return end
		self:Remove()
		attacker:PrintMessage(HUD_PRINTTALK, "You've been awarded with 5 points for destroying an SCP!")
		attacker:AddFrags( 5 )
	end
end