AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName = "SCP-018"
ENT.Author = "Garry Newman"
ENT.Information = "A super bouncy ball"
ENT.Category = "SCP"

ENT.Editable = true
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SpawnFunction( ply, tr, ClassName )

	if ( !tr.Hit ) then return end

	local ent = ents.Create( ClassName )
	ent:SetPos( tr.HitPos + tr.HitNormal)
	ent:Spawn()
	ent:Activate()

	return ent

end

function ENT:Initialize()
	if ( CLIENT ) then
		killicon.Add("ent_scp_018", "vgui/entities/weapon_scp-018", Color( 255, 255, 255, 255 ) );
		language.Add("ent_scp_018", "Super Ball")
	else
		self:SetModel( "models/SCP_Secret_Lab/SCP-018.mdl" )
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		
		self:SetCollisionGroup(COLLISION_GROUP_NONE)
	
		local phys = self:GetPhysicsObject()
		
		if (phys:IsValid()) then
			phys:Wake()
			phys:SetMass(5)
		end
	end
end

function ENT:Think()
	if SERVER then
		if self:GetVelocity():IsEqualTol(Vector(0,0,0),5) == true then
			local exp = ents.Create( "env_explosion" )
			exp:SetPos( self:GetPos() + Vector(0,0,5) )
			exp:Spawn()
			exp:SetKeyValue( "iMagnitude", "150" )
			exp:Fire("Explode", 0, 0)
			exp:Fire("Remove", 0, 0.2)
			self:Remove()
		end
	end
	self:NextThink(CurTime()+5)
	return true
end

local BounceSound = Sound( "garrysmod/balloon_pop_cute.wav" )

function ENT:Touch(v)
	-- Breach compatibility - don't damage spectators or teammates
	if IsValid(v) and v:IsPlayer() then
		if v:GTeam() == TEAM_SPEC then return end
		
		local owner = self:GetNWEntity("BallOwner", self)
		if IsValid(owner) and owner:IsPlayer() then
			-- Don't damage teammates (optional - remove if you want friendly fire)
			-- if owner:GTeam() == v:GTeam() and owner:GTeam() != TEAM_SCP then return end
		end
	end
	
	if self:GetVelocity():IsEqualTol(Vector(0,0,0),500) == false then
		local dmginfo=DamageInfo()
		dmginfo:SetAttacker(self:GetNWEntity("BallOwner",self))
		dmginfo:SetInflictor(self)
		dmginfo:SetDamage(self:GetVelocity():Length()/50 + v:Health()/5)
		dmginfo:SetDamageType(DMG_CRUSH)
		v:TakeDamageInfo(dmginfo)
		if v:IsPlayer() or v:IsNPC() then
			sound.Play( "player/bhit_helmet-1.wav", v:GetPos() + Vector(0,0,10), 75, 100, 100 )
			sound.Play( "player/bhit_helmet-1.wav", v:GetPos() + Vector(0,0,10), 75, 100, 100 )
			sound.Play( "player/bhit_helmet-1.wav", v:GetPos() + Vector(0,0,10), 75, 100, 100 )
		end
	end
end

function ENT:PhysicsCollide( data, physobj )
	-- Play sound on bounce
	if ( data.Speed > 10 && data.DeltaTime > 0.2 ) then
		sound.Play( BounceSound, self:GetPos(), 55, math.random(150, 170), math.Clamp( data.Speed / 150, 0, 1 ) )
	elseif data.Speed > 50 and IsValid(data.HitEntity) then
		-- Breach compatibility check
		if data.HitEntity:IsPlayer() then
			if data.HitEntity:GTeam() == TEAM_SPEC then return end
			
			local owner = self:GetNWEntity("BallOwner", self)
			if IsValid(owner) and owner:IsPlayer() then
				-- Don't damage teammates (optional - remove if you want friendly fire)
				-- if owner:GTeam() == data.HitEntity:GTeam() and owner:GTeam() != TEAM_SCP then return end
			end
		end
		
		local dmginfo=DamageInfo()
		dmginfo:SetAttacker(self:GetNWEntity("BallOwner",self))
		dmginfo:SetInflictor(self)
		dmginfo:SetDamage(data.Speed/30 + data.HitEntity:Health()/5)
		dmginfo:SetDamageType(DMG_CRUSH)
		data.HitEntity:TakeDamageInfo(dmginfo)

		if data.HitEntity:IsPlayer() or data.HitEntity:IsNPC() then
			sound.Play( "player/bhit_helmet-1.wav", data.HitEntity:GetPos() + Vector(0,0,10), 75, 100, 100 )
			sound.Play( "player/bhit_helmet-1.wav", data.HitEntity:GetPos() + Vector(0,0,10), 75, 100, 100 )
			sound.Play( "player/bhit_helmet-1.wav", data.HitEntity:GetPos() + Vector(0,0,10), 75, 100, 100 )
		else
			sound.Play( BounceSound, self:GetPos(), 55, math.random(150, 170), math.Clamp( data.Speed / 150, 0, 1 ) )
		end
	end

	-- Bounce like a crazy bitch
	local LastSpeed = math.max( data.OurOldVelocity:Length(), data.Speed )
	local NewVelocity = physobj:GetVelocity() + Vector(math.random(-2,2),math.random(-2,2),math.random(-2,2))*100
	NewVelocity:Normalize()

	LastSpeed = math.max( NewVelocity:Length(), LastSpeed )

	local TargetVelocity = NewVelocity * LastSpeed * 1.2

	physobj:SetVelocity( TargetVelocity )
end

function ENT:OnTakeDamage( dmginfo )
	-- React physically when shot/getting blown
	self:TakePhysicsDamage( dmginfo )
end

function ENT:Use( activator, caller )
	if ( activator:IsPlayer() ) then
		-- Breach compatibility - don't let spectators pick up
		if activator:GTeam() == TEAM_SPEC then return end
		
		activator:GiveAmmo(1, "ball")
		if !activator:HasWeapon("weapon_scp_018") then
			activator:Give("weapon_scp_018", true)
		end
	end
	self:Remove()
end

if ( SERVER ) then return end

function ENT:Draw()
	self.Entity:DrawModel()
end 