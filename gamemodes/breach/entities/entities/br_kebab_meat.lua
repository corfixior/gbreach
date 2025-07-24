AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Döner Meat"
ENT.Author = "Breach Team"
ENT.Contact = ""
ENT.Purpose = "Rotating döner meat"
ENT.Instructions = ""
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.Category = "Breach Food Service"

function ENT:Initialize()
    print("[KEBAB MEAT DEBUG] Initialize called")
    self:SetModel("models/doner_makinesi/doner_doner.mdl")
    print("[KEBAB MEAT DEBUG] Model set to doner_doner.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    print("[KEBAB MEAT DEBUG] Physics initialized")

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
        print("[KEBAB MEAT DEBUG] Physics object configured")
    else
        print("[KEBAB MEAT DEBUG] WARNING: No physics object!")
    end

    self.RotationSpeed = 30 -- degrees per second
    print("[KEBAB MEAT DEBUG] Kebab meat initialization complete")
end

function ENT:Think()
    if CLIENT then return end
    
    -- Rotate the meat slowly
    local angles = self:GetAngles()
    angles.y = angles.y + (self.RotationSpeed * FrameTime())
    self:SetAngles(angles)
    
    self:NextThink(CurTime() + 0.01)
    return true
end 