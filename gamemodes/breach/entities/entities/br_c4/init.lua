AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

-- Dodajemy resource.AddFile dla modeli i dźwięków C4, aby klienci mogli je pobrać
resource.AddFile("models/hoff/weapons/c4/w_c4.mdl")
resource.AddFile("models/hoff/weapons/c4/c_c4.mdl")
resource.AddFile("materials/models/hoff/weapons/c4/c4_reticle.png")
resource.AddFile("sound/hoff/mpl/seal_c4/bar_selectorswitch.wav")
resource.AddFile("sound/hoff/mpl/seal_c4/c4_click.wav")
resource.AddFile("sound/hoff/mpl/seal_c4/whoosh_01.wav")
resource.AddFile("sound/hoff/mpl/seal_c4/satchel_plant.wav")

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then
		return
	end
	-- local SpawnPos = tr.HitPos + tr.HitNormal * 16
	local ent = ents.Create( "br_c4" )
	ent:SetPos( Vector(0,0,0) )
	ent:Spawn()
	ent:Activate()

	ent:SetOwner(ply) -- Disables collision between the C4 and its owner
	return ent
end


function ENT:Initialize()
	self:SetModel( "models/hoff/weapons/c4/w_c4.mdl" )
	self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:DrawShadow(false)

	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
	end

	self.Hit = false

	self.ExplodedViaWorld = false

	self:SetDTFloat( 0, math.Rand( 0.5, 1.3 ) )
	self:SetDTFloat( 1, math.Rand( 0.3, 1.2 ) )

	--self.Entity:SetOwner(self.C4Owner)

	self:SetNWBool("CanUse", false)
end

function ENT:PhysgunPickup(ply, ent)
	if ent:GetClass() == "br_c4" then
		return false
	end
end
hook.Add("PhysgunPickup", "br_c4_physgun_pickup_hook", function(ply, ent)
	if IsValid(ent) and ent.PhysgunPickup and ent:GetClass() == "br_c4" then
		return ent:PhysgunPickup(ply, ent)
	end
end)

function ENT:SetupDataTables()
	self:DTVar( "Float", 0, "RotationSeed1" )
	self:DTVar( "Float", 1, "RotationSeed2" )
end

function ENT:OnRemove()
	-- Check if the C4 owner is valid
	if IsValid(self) and IsValid(self.C4Owner) and IsValid(self.C4Owner.C4s) then
		-- Check if the C4 is in the owner's C4s table
		if table.HasValue(self.C4Owner.C4s, self) then
			-- Remove the C4 from the owner's C4s table
			table.RemoveByValue(self.C4Owner.C4s, self)
		end
	end
end

function ENT:DelayedDestroy(bTriggeredByOwner)
	if !IsValid(self) then
		return
	end
	local LastC4Position = self:GetPos()
	local ExplodedViaWorld = self.ExplodedViaWorld
	self.ExplodedViaWorld = false
	self.QueuedForExplode = true
	local CachedC4s = self.C4Owner.C4s

	-- Set a timer to explode the found C4 entity after a delay of 0.1 seconds
	if self:GetParent() ~= nil then
		self:SetParent()
	end
	timer.Simple(0.1, function()
		if bTriggeredByOwner then
			if IsValid(self) and IsValid(self.C4Owner) and self.C4Owner.C4s and type(self.C4Owner.C4s) == "table" then
				-- Index 2 is the next c4 to activate, since index 1 is this one (probably)
				local ent = self.C4Owner.C4s[2]
				while ent ~= nil and not IsValid(ent) do
					table.remove(self.C4Owner.C4s, 2)
					ent = self.C4Owner.C4s[2]
					if table.Count(self.C4Owner.C4s) < 2 and (ent == nil or !IsValid(ent)) then
						break
					end
				end
				if IsValid(ent) and IsValid(self) then
					ent.ExplodedViaWorld = false
					ent:DelayedDestroy(true)
				end
				table.remove(self.C4Owner.C4s, 1)
				if table.Count(self.C4Owner.C4s) <= 0 then
					self.C4Owner.C4s = {}
				end
			end
		end

		-- OPTYMALIZACJA: Zoptymalizowane wyszukiwanie entity z cache
		local entities = ents.FindInSphere(LastC4Position, 128)

		-- Pre-filtruj tylko potrzebne typy entity
		local validEntities = {}
		for _, ent in pairs(entities) do
			if IsValid(ent) and ent ~= self then
				local class = ent:GetClass()
				if class == "func_door" or class == "func_door_rotating" or
				   class == "prop_dynamic" or class == "prop_door_rotating" or
				   ent:IsPlayer() or class == "br_c4" then
					table.insert(validEntities, ent)
				end
			end
		end

		-- Sortuj tylko ważne entity (używaj DistToSqr dla wydajności)
		table.sort(validEntities, function(a, b)
			return a:GetPos():DistToSqr(LastC4Position) < b:GetPos():DistToSqr(LastC4Position)
		end)

		entities = validEntities

		-- Iterate over the sorted entities
		for k, v in pairs(entities) do

			if v ~= self then
				-- Check if the current entity is a C4 entity, is not the current C4 entity, and is valid
				if v:GetClass() == "br_c4" and v:IsValid() then
					if (ExplodedViaWorld or !table.HasValue(CachedC4s, v)) and v.QueuedForExplode == false then
							
						-- Check if the found C4 entity has an "Explode" function
						if (type(v.Explode) == "function") then
							
							-- Explode the found C4 entity
							--v.ThisTrigger = self.ThisTrigger
							v.ExplodedViaWorld = true
							v:DelayedDestroy(false)
								
						end
						-- Break the loop after finding and exploding the first C4 entity
						break
					end
					break
				end
			end
		end

		-- Explode this c4 and remove it from the array (if it's in there)
		if IsValid(self) then
			if IsValid(self.C4Owner) and table.HasValue(self.C4Owner.C4s, self) then
				table.RemoveByValue(self.C4Owner.C4s, self)
			end
			self:Explode(bTriggeredByOwner)
		end
	end)
end

function ENT:Explode(bTriggeredByOwner)

	self:EmitSound( "ambient/explosions/explode_4.wav" )

	local detonate = ents.Create( "env_explosion" )
		detonate:SetOwner(self.C4Owner)
		detonate:SetPos( self:GetPos() )
		detonate:SetKeyValue( "iMagnitude", GetConVar("BR_C4_Magnitude"):GetString() )
		--detonate:SetKeyValue( "iRadiusOverride", GetConVar("BR_C4_Radius"):GetString() )
		detonate:Spawn()
		detonate:Activate()
		detonate:Fire( "Explode", "", 0 )

	local shake = ents.Create( "env_shake" )
		shake:SetOwner( self:GetOwner() )
		shake:SetPos( self:GetPos() )
		shake:SetKeyValue( "amplitude", "2000" )
		shake:SetKeyValue( "radius", "400" )
		shake:SetKeyValue( "duration", "2.5" )
		shake:SetKeyValue( "frequency", "255" )
		shake:SetKeyValue( "spawnflags", "4" )
		shake:Spawn()
		shake:Activate()
		shake:Fire( "StartShake", "", 0 )

	self.QueuedForExplode = true

	if ConVarExists("BR_C4_KnockDoors") and GetConVar("BR_C4_KnockDoors"):GetBool() then
		self:KnockDownDoors()
	end

	-- Niszczenie func_door i prop_dynamic w małym zasięgu
	self:DestroyEntities()

	-- Search nearby this exploding c4, if it finds one not in the c4 table, explode it
	self:DelayedDestroy(bTriggeredByOwner)

	self:Remove()
end

-- Chronione pozycje gdzie C4 nie może niszczyć func_door i prop_dynamic
local PROTECTED_POSITIONS = {
	Vector(-448.098022, 4831.968750, 56.154514),
	Vector(-3648.947998, 2472.031250, 54.741806),
	Vector(-191.041443, 5182.749023, 60.138435),
	Vector(-191.041504, 5184.383789, 2617.533691),
	Vector(-5698.259766, 2171.968750, 2568.216309),
	Vector(-3905.577881, 1919.041504, 2624.176270),
	Vector(-3902.997070, 1919.041504, 59.270962)
}

-- Promień ochrony wokół chronionych pozycji
local PROTECTION_RADIUS = 100

-- Funkcja sprawdzająca czy pozycja jest chroniona
local function IsProtectedPosition(pos)
	for _, protectedPos in pairs(PROTECTED_POSITIONS) do
		if pos:Distance(protectedPos) <= PROTECTION_RADIUS then
			return true
		end
	end
	return false
end

function ENT:DestroyEntities()
	-- OPTYMALIZACJA: Zoptymalizowane niszczenie entity
	local DestroyRadius = 50
	local entities = ents.FindInSphere(self:GetPos(), DestroyRadius)

	-- Pre-filtruj tylko niszczalne entity
	local destroyableEntities = {}
	for _, ent in pairs(entities) do
		if IsValid(ent) and ent ~= self then
			local entClass = ent:GetClass()
			if entClass == "func_door" or entClass == "func_door_rotating" or entClass == "prop_dynamic" then
				local entPos = ent:GetPos()
				-- Sprawdź czy encja jest w chronionej pozycji
				if not IsProtectedPosition(entPos) then
					table.insert(destroyableEntities, ent)
				end
			end
		end
	end

	-- Batch processing niszczenia
	for i, ent in pairs(destroyableEntities) do
		local entClass = ent:GetClass()

		-- Rozłóż niszczenie w czasie dla lepszej wydajności
		timer.Simple(i * 0.05, function()
			if not IsValid(ent) then return end

			-- Niszczenie func_door
			if entClass == "func_door" or entClass == "func_door_rotating" then
				ent:Fire("Open", "", 0)
				timer.Simple(0.5, function()
					if IsValid(ent) then
						ent:Remove()
					end
				end)

			-- Niszczenie prop_dynamic
			elseif entClass == "prop_dynamic" then
				local effectData = EffectData()
				effectData:SetOrigin(ent:GetPos())
				effectData:SetMagnitude(1)
				util.Effect("Explosion", effectData)
				ent:Remove()
			end
		end)
	end

	print("[OPTIMIZATION] C4 destroyed " .. #destroyableEntities .. " entities")
end

function ENT:KnockDownDoors()
	local SearchRadius = ConVarExists("BR_C4_DoorSearchRadius") and GetConVar("BR_C4_DoorSearchRadius"):GetInt() or 100
	local entities = ents.FindInSphere(self:GetPos(), SearchRadius)
	for k, ItDoor in pairs(entities) do
		local DoorClass = ItDoor:GetClass()
		if DoorClass == "func_door" or DoorClass == "func_door_rotating" or DoorClass == "prop_door_rotating" then
			if !ItDoor.KnockedDown then
				self:BlastDoor(ItDoor)
			end
		end
	end
end

function ENT:BlastDoor(FoundDoor)
	FoundDoor.KnockedDown = true
	FoundDoor:Fire("lock","",0)
	FoundDoor:Fire("Open","",0)
	FoundDoor:SetCollisionGroup(COLLISION_GROUP_WORLD)
	FoundDoor:CollisionRulesChanged()
	FoundDoor:SetNoDraw(true)

	FoundDoor.FakeDoor = ents.Create("prop_physics")
	FoundDoor.FakeDoor:SetModel(FoundDoor:GetModel())
	FoundDoor.FakeDoor:SetPos(FoundDoor:GetPos())
	FoundDoor.FakeDoor:SetAngles(FoundDoor:GetAngles())
	FoundDoor.FakeDoor:Spawn()
	FoundDoor.FakeDoor:Activate()
	if FoundDoor:GetSkin() then
		FoundDoor.FakeDoor:SetSkin(FoundDoor:GetSkin())
	end

	local phys = FoundDoor.FakeDoor:GetPhysicsObject()
	if IsValid(phys) then
		local KnockStrength = ConVarExists("BR_C4_DoorKnockStrength") and GetConVar("BR_C4_DoorKnockStrength"):GetFloat() or 500
		KnockStrength = KnockStrength * -1
		phys:ApplyForceOffset((self:GetAngles():Up() * KnockStrength) * phys:GetMass(), self:GetPos())
	end
end

ENT.PhysData = nil
ENT.PhysRef = nil
function ENT:PhysicsCollide(data, phys)
	if data.HitEntity:GetClass() == "br_c4" or data.HitEntity == self.C4Owner then return end

	self:EmitSound("hoff/mpl/seal_c4/satchel_plant.wav")

	if self:IsValid() and !self.Hit then
		self.ChangeCollisionGroup = true
		timer.Simple(0, function()
			if self.ChangeCollisionGroup then
				self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
				self.ChangeCollisionGroup = false

				local bHitValidEntity = IsValid(data.HitEntity)
				if bHitValidEntity then
					local bHitWorld = data.HitEntity:IsWorld()
					local bHitAnotherC4 = data.HitEntity:GetClass() == "br_c4"
					local bHitAnNPC = data.HitEntity:IsNPC()
					local bHitAPlayer = data.HitEntity:IsPlayer()
					if bHitValidEntity and !bHitWorld and !bHitAnotherC4 and !bHitAnNPC and !bHitAPlayer then
						self:SetSolid(SOLID_VPHYSICS)
						self:SetMoveType(MOVETYPE_NONE)
						self:SetParent(data.HitEntity)
						self.Stuck = true
						self.Hit = true
					elseif bHitWorld then
						self:SetMoveType(MOVETYPE_NONE)
					end
				else
					self:SetMoveType(MOVETYPE_NONE)
				end
				self:SetNWBool("CanUse", true)

				if IsValid(phys) then
					local angVel = phys:GetAngleVelocity()
					local maxAngVel = 1000
					if angVel:Length() > maxAngVel then
						angVel = angVel:GetNormalized() * maxAngVel
						phys:SetAngleVelocity(angVel)
					end
				end

				local HitAngle = data.HitNormal:Angle()
				HitAngle.p = HitAngle.p + 270

				self:SetPos(data.HitPos + ((data.HitNormal / 5) * -11))

				-- Generate a random yaw angle between -60 and 60 degrees
				local yaw = math.random(-60, 60)

				self:SetAngles(HitAngle)
				-- Rotate the Angle object around the entity's up vector using the RotateAroundAxis function
				HitAngle:RotateAroundAxis(self:GetUp(), yaw)
				-- Set the entity's angles to the rotated angles
				self:SetAngles(HitAngle)
				self:SetOwner(nil)
			end
		end)
		self:SetNWBool("Hit", true)
		self.Hit = true
		self.PhysData = data
		self.PhysRef = phys
	end
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )

	-- Check if the attacker is not the owner of the C4, or if the damage type is not blast damage
	if dmginfo:GetDamageType() ~= DMG_BLAST then
		self.ExplodedViaWorld = true
		self:Explode(false)
	end
end

function ENT:Touch(ent)
	if ent == self.C4Owner or ent == self.ThisTrigger or ent == self:GetOwner() then
		return false
	end
	if IsValid(ent) and !self.Stuck then
		if ent:IsNPC() || (ent:IsPlayer() && ent != self:GetOwner()) || ent:IsVehicle() then
			self:SetSolid(SOLID_VPHYSICS)
			self:SetMoveType(MOVETYPE_NONE)
			self:SetParent(ent)
			self.Stuck = true
			self.Hit = true
			self:SetOwner(nil)
		end
	end
end