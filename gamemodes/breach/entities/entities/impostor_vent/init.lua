AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.Category = "SCP"
ENT.Author = "Breach"
ENT.PrintName = "Impostor Vent"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "LinkedVent")
    self:NetworkVar("Entity", 1, "Owner")
end

function ENT:Initialize()
    print("Impostor vent Initialize() called!")
    -- Używamy dużego, widocznego modelu
    self:SetModel("models/props_c17/oildrum001.mdl") -- Duży beczka jako test
    print("Vent model set to: " .. self:GetModel())
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    
    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
    end
    
    -- Bardzo jasny, widoczny kolor
    self:SetColor(Color(255, 0, 0, 255))
    self:SetMaterial("models/debug/debugwhite")
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false) -- Nie pozwól się ruszać
    end
end

function ENT:Use(ply)
    if !IsValid(ply) or !ply:IsPlayer() then return end
    if !IsValid(self:GetOwner()) then return end
    if ply != self:GetOwner() then return end -- Tylko właściciel może używać
    
    local linkedVent = self:GetLinkedVent()
    if !IsValid(linkedVent) then
        ply:PrintMessage(HUD_PRINTCENTER, "No linked vent found!")
        return
    end
    
    -- Teleportuj do drugiego venta
    local teleportPos = linkedVent:GetPos() + Vector(0, 0, 50) -- Trochę wyżej żeby nie wpaść w ziemię
    ply:SetPos(teleportPos)
    
    -- Efekty dźwiękowe i wizualne
    ply:EmitSound("ambient/machines/teleport1.wav", 70, 100)
    linkedVent:EmitSound("ambient/machines/teleport3.wav", 70, 100)
    
    -- Efekt wizualny
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    util.Effect("Sparks", effectdata)
    
    effectdata:SetOrigin(teleportPos)
    util.Effect("Sparks", effectdata)
end

function ENT:Draw()
    -- Rysuj model - czerwona beczka jako test
    self:DrawModel()
    
    local ply = LocalPlayer()
    if !IsValid(ply) then return end
    if ply:GetPos():Distance(self:GetPos()) > 150 then return end
    if self:GetOwner() != ply then return end
    
    -- Pokaż tekst "Press E to use vent"
    cam.Start2D()
        if DrawInfo then
            DrawInfo(self:GetPos() + Vector(0, 0, 50), "Press E to use vent", Color(255, 255, 255))
        else
            -- Fallback text rendering
            local pos2d = self:GetPos():ToScreen()
            if pos2d.visible then
                draw.SimpleText("Press E to use vent", "DermaDefault", pos2d.x, pos2d.y - 20, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            end
        end
    cam.End2D()
end

function ENT:OnRemove()
    -- Usuń połączenie z drugim ventem
    local linkedVent = self:GetLinkedVent()
    if IsValid(linkedVent) then
        linkedVent:SetLinkedVent(NULL)
    end
end 