ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "SCP-294"
ENT.Author = "Breach SCP"
ENT.Contact = ""
ENT.Purpose = "The Coffee Machine"
ENT.Instructions = "Press E to interact"

ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "SCP Breach"

ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "UsesLeft")
    self:NetworkVar("Bool", 0, "IsActive")
end 