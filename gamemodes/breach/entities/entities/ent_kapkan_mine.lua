AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Kapkan EDD"
ENT.Category = "Arsen's Gadgets"
ENT.Spawnable = true
ENT.Icon = "entities/weapon_kapkan_placer.png"

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/arsen/Tripmine.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_VPHYSICS)  
        self:SetMaxHealth(KAPKAN_CONFIG.MineHealth)
        self:SetHealth(KAPKAN_CONFIG.MineHealth)
        self.HasExploded = false
        self.LaserOffset = self:GetRight() * 10
        self:SetNWInt("ExplosionDamage", KAPKAN_CONFIG.ExplosionDamage)
        
        if not KAPKAN_CONFIG.PlayerCollisions then
            self:SetCollisionGroup(COLLISION_GROUP_WEAPON)  
        else
            self:SetCollisionGroup(COLLISION_GROUP_NONE)  
        end
    end
end

function ENT:SpawnFunction(ply, tr, className)
    if not tr.Hit then return end
    
    local ent = ents.Create(className)
    ent:SetPos(tr.HitPos + tr.HitNormal * 1)
    ent:SetAngles(tr.HitNormal:Angle())
    ent:Spawn()
    ent:Activate()
    ent:SetNWInt("ExplosionDamage", KAPKAN_CONFIG.ExplosionDamage)
    
    if IsValid(ply) then
        -- Usunięto wywołanie AddCleanup, które nie jest dostępne w SCP: Breach
        -- ply:AddCleanup("Kapkan Mines", ent)
    end
    
    return ent
end

function ENT:OnTakeDamage(dmg)
    if SERVER and not self.HasExploded then
        self:SetHealth(self:Health() - dmg:GetDamage())
        if self:Health() <= 0 then
            self:Explode()
        end
    end
end

function ENT:Explode()
    if SERVER and not self.HasExploded then
        self.HasExploded = true

        local explode = ents.Create("env_explosion")
        explode:SetPos(self:GetPos())
        explode:SetOwner(self)
        explode:Spawn()
        explode:SetKeyValue("iMagnitude", tostring(self:GetNWInt("ExplosionDamage") or 100))
        explode:Fire("Explode", 0, 0)
        self:Remove()
    end
end

function ENT:Use(activator, caller)
    if SERVER and not self.HasExploded then
        self:EmitSound("buttons/button11.wav")
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        effectdata:SetNormal(Vector(0, 0, 1))
        effectdata:SetMagnitude(2)
        effectdata:SetScale(1)
        effectdata:SetRadius(2)
        util.Effect("ElectricSpark", effectdata)
        self:Remove()
    end
end

function ENT:Think()
    if SERVER and not self.HasExploded then
        local laserStart = self:GetPos() + self.LaserOffset
        local laserEnd = laserStart + self:GetRight() * KAPKAN_CONFIG.LaserLength

        local tr = util.TraceLine({
            start = laserStart,
            endpos = laserEnd,
            filter = function(ent)
                if ent == self then return false end
                if ent:IsWorld() then return false end
                if ent:GetMoveType() == MOVETYPE_NONE then return false end
                return true
            end
        })

        if tr.Hit and IsValid(tr.Entity) then
            self:TriggerMine()
        end

        self:NextThink(CurTime() + 0.05)
        return true
    end
end

function ENT:TriggerMine()
    if not self.HasExploded then
        self:EmitSound("npc/roller/mine/rmine_blip1.wav")
        timer.Simple(KAPKAN_CONFIG.ExplosionDelay, function()
            if IsValid(self) and not self.HasExploded then
                self:Explode()
            end
        end)
    end
end

if CLIENT then
    local laserMat = Material("trails/laser")
    local dotMat = Material("sprites/light_glow02_add")

    function ENT:Draw()
        self:DrawModel()
        
        local startPos = self:GetPos() + self:GetRight() * 10
        local endPos = startPos + self:GetRight() * KAPKAN_CONFIG.LaserLength

        render.SetMaterial(laserMat)
        render.DrawBeam(startPos, endPos, 2, 0, 1, Color(255, 50, 50, 30))
        render.DrawBeam(startPos, endPos, 4, 0, 1, Color(255, 100, 100, 30))

        render.SetMaterial(dotMat)
        render.DrawSprite(endPos, 0, 0, Color(255, 100, 100, 0.1))
        render.DrawSprite(startPos, 4, 4, Color(255, 50, 50, 0.1))
    end

    function ENT:DrawTranslucent()
        self:Draw()
    end

    hook.Add("HUDPaint", "KapkanDisarmText", function()
        local ply = LocalPlayer()
        local ent = ply:GetEyeTrace().Entity
        
        if IsValid(ent) and ent:GetClass() == "ent_kapkan_mine" then
            local distance = ply:GetPos():Distance(ent:GetPos())
            
            if distance <= 200 then
                local pos = ent:GetPos():ToScreen()
                draw.SimpleText("Press E to disarm", "DermaDefault", pos.x, pos.y - 30, Color(0, 250, 250), TEXT_ALIGN_CENTER)
            end
        end
    end)
end