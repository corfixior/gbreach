AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/hunter/plates/plate2x2.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    -- Zrób barierę stałą
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:SetMass(50000)
    end
    
    -- NIEWIDOCZNA bariera
    self:SetColor(Color(255, 255, 255, 0)) -- Przezroczysta
    self:SetNoDraw(true) -- Nie rysuj
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    
    print("[SCP-106 Barrier] Niewidoczna bariera SCP-106 utworzona w pozycji: " .. tostring(self:GetPos()))
end

function ENT:Touch(ent)
    if IsValid(ent) and ent:IsPlayer() then
        if ent:GetNClass() == ROLES.ROLE_SCP106 then
            -- SCP-106 może przejść - zrób barierę niekolizyjną dla niego
            self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
            print("[SCP-106 Barrier] SCP-106 (" .. ent:Nick() .. ") przechodzi przez barierę")
            
            -- Przywróć kolizję po krótkim czasie
            timer.Simple(1, function()
                if IsValid(self) then
                    self:SetCollisionGroup(COLLISION_GROUP_NONE)
                end
            end)
        else
            -- Inny gracz - zablokuj
            self:SetCollisionGroup(COLLISION_GROUP_NONE) -- Upewnij się że kolizja jest aktywna
        end
    end
end

function ENT:StartTouch(ent)
    self:Touch(ent)
end

function ENT:EndTouch(ent)
    -- Opcjonalnie można dodać coś tutaj
end

function ENT:Use(activator, caller)
    if IsValid(activator) and activator:IsPlayer() and activator:IsAdmin() then
        activator:ChatPrint("=== SCP-106 Barrier Info ===")
        activator:ChatPrint("Pozycja: " .. tostring(self:GetPos()))
        activator:ChatPrint("Model: " .. self:GetModel())
        activator:ChatPrint("Kolor: " .. tostring(self:GetColor()))
    end
end
