AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

-- Server-side initialization function for the Entity
function ENT:Initialize()
    if SERVER then
        self.Entity:SetModel("models/canebar/w_house_canebar.mdl")      -- Sets the model for the Entity.
        self.Entity:PhysicsInit(SOLID_VPHYSICS)                         -- Initializes the physics of the Entity.
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)                      -- Sets how the Entity moves, using physics.
        self.Entity:SetSolid(SOLID_VPHYSICS)                            --  Makes the Entity solid, allowing for collisions.
        util.SpriteTrail(self.Entity, 0, Color_white, true, 3, 0, 0.5, 0, "trails/laser")
        self.NextThinkTime = CurTime() + 1 -- Initialize the next think time
    end
end

function ENT:Think()

    if not IsValid(self.Owner) then -- Owner disconnected
        self:Remove()
        return
    end

    if not self.Owner:Alive() then -- Owner died
        self:Remove()
        return
    end
    
    if SERVER and CurTime() >= self.NextThinkTime then
        for k, user in pairs(ents.FindInSphere(self.Entity:GetPos(), 75)) do -- Searches for Entities within radius of canebar entity.
            if IsValid(user) and user:IsPlayer() and self.Entity.Owner == user then -- Checks to ensure player is valid and is the owner of our entity.
                if user:HasWeapon("weapon_house_canebar_holstered") then -- Checks if they have the holstered SWEP or not as we have two SWEPS that create this entity
                    user:StripWeapon("weapon_house_canebar_holstered") -- Removes Holstered Variant of the recall SWEP, the normal variant does not use this SWEP
                    user:Give("weapon_house_canebar_recall", false)
                    user:SelectWeapon("weapon_house_canebar_recall")
                    user:EmitSound("WeaponFrag.Throw")
                    self.Entity:Remove()
                    break -- Ends the function
                else
                    user:Give("weapon_house_canebar", false)
                    user:SelectWeapon("weapon_house_canebar")
                    user:EmitSound("WeaponFrag.Throw")
                    self.Entity:Remove()
                    break -- Ends the function
                end
            end
        end
        self.NextThinkTime = CurTime() + 1 -- Set the next think time to 1 second later
    end
end

function ENT:PhysicsCollide(data, phys)
    if SERVER then
        if data.Speed > 300 then
            self.Entity:EmitSound("weapons/canebar/metal_pipe.mp3")

            local hitent = data.HitEntity
            if IsValid(hitent) then
                local dmg = DamageInfo()
                local attacker = self.Entity.Owner
                if not IsValid(attacker) then attacker = self end
                dmg:SetAttacker(attacker)
                dmg:SetInflictor(hitent)
                dmg:SetDamage(data.Speed / 50)
                hitent:TakeDamageInfo(dmg)
            end
        end
    end
end 