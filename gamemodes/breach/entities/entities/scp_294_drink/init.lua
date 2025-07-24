AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(5)
    end
    
    -- Właściwości napoju
    self.DrinkName = "Unknown Drink"
    self.DrinkEffects = function() end
    self.Owner = nil
    self.ConsumeTime = 0
    
    -- Auto-usuwanie po 5 minutach
    timer.Simple(300, function()
        if IsValid(self) then
            self:Remove()
        end
    end)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    -- Sprawdź czy gracz już pije
    if activator.IsDrinking then
        return
    end
    
    -- Rozpocznij picie
    self:StartDrinking(activator)
end

function ENT:StartDrinking(ply)
    if not IsValid(ply) then return end
    
    ply.IsDrinking = true
    
    -- Efekt picia
    ply:EmitSound("npc/barnacle/barnacle_gulp2.wav", 60, 120)
    
    -- Natychmiastowy efekt - bez blokowania ruchu
    -- Wykonaj efekty napoju
    if self.DrinkEffects and isfunction(self.DrinkEffects) then
        self.DrinkEffects(ply)
    end
    
    -- Efekt znikania
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    effectdata:SetScale(1)
    util.Effect("balloon_pop", effectdata)
    
    ply.IsDrinking = false
    
    -- Usuń napój
    self:Remove()
end

function ENT:OnTakeDamage(dmginfo)
    -- Napój może być zniszczony
    local damage = dmginfo:GetDamage()
    if damage > 10 then
        -- Efekt rozlania
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        effectdata:SetScale(2)
        effectdata:SetMagnitude(5)
        util.Effect("WaterSplash", effectdata)
        
        self:EmitSound("physics/glass/glass_bottle_break2.wav", 70, 100)
        self:Remove()
    end
end

function ENT:PhysicsCollide(data, phys)
    -- Dźwięk uderzenia
    if data.Speed > 60 then
        self:EmitSound("physics/metal/metal_canister_impact_soft" .. math.random(1,3) .. ".wav", 50, 100)
    end
end 