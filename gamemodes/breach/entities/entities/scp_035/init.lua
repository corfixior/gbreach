AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Cooldown system for mask usage
local MaskCooldown = {}

function ENT:Initialize()
    self:SetModel("models/scp_035_real/scp_035_real.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
    
    print("[SCP-035] Mask spawned at position: " .. tostring(self:GetPos()))
end

function ENT:PhysicsCollide(data, physobj)
    if data.DeltaTime > 0.2 then
        if data.Speed > 250 then
            self:EmitSound("physics/concrete/concrete_impact_hard" .. math.random(1, 3) .. ".wav", 75, math.random(100, 110))
        else
            self:EmitSound("physics/concrete/concrete_impact_soft" .. math.random(1, 3) .. ".wav", 75, math.random(100, 110))
        end
    end
end

function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    print("[SCP-035 DEBUG] Player " .. ply:Nick() .. " trying to use mask")
    print("[SCP-035 DEBUG] Player team: " .. team.GetName(ply:GTeam()))
    print("[SCP-035 DEBUG] Player alive: " .. tostring(ply:Alive()))
    print("[SCP-035 DEBUG] Preparing state: " .. tostring(preparing))
    
    -- Sprawdź czy gracz jest spektatorem
    if ply:GTeam() == TEAM_SPEC then
        ply:PrintMessage(HUD_PRINTTALK, "[SCP-035] Spectators cannot use the mask!")
        print("[SCP-035 DEBUG] Blocked spectator from using mask")
        return
    end
    
    -- Sprawdź czy gracz jest żywy
    if not ply:Alive() then
        ply:PrintMessage(HUD_PRINTTALK, "[SCP-035] You must be alive to use the mask!")
        print("[SCP-035 DEBUG] Blocked dead player from using mask")
        return
    end
    
    -- Sprawdź czy runda się jeszcze nie zaczęła (preparing)
    if preparing then
        ply:PrintMessage(HUD_PRINTTALK, "[SCP-035] You cannot use the mask during preparation phase!")
        print("[SCP-035 DEBUG] Blocked mask usage during preparing")
        return
    end
    
    -- Sprawdź cooldown
    local steamID = ply:SteamID()
    if MaskCooldown[steamID] and CurTime() < MaskCooldown[steamID] then
        local timeLeft = math.ceil(MaskCooldown[steamID] - CurTime())
        ply:PrintMessage(HUD_PRINTTALK, "[SCP-035] You must wait " .. timeLeft .. " seconds before using the mask again!")
        print("[SCP-035 DEBUG] Blocked mask usage - cooldown active")
        return
    end
    
    -- Sprawdź czy gracz już jest SCP-035
    if ply:GetNClass() == ROLES.ROLE_SCP035 then 
        ply:PrintMessage(HUD_PRINTTALK, "[SCP-035] You are already wearing the mask!")
        print("[SCP-035 DEBUG] Player already is SCP-035")
        return 
    end
    
    -- Sprawdź czy gracz już jest SCP (oprócz SCP-035)
    if ply:GTeam() == TEAM_SCP then
        ply:PrintMessage(HUD_PRINTTALK, "[SCP-035] SCPs cannot wear the mask!")
        print("[SCP-035 DEBUG] Blocked SCP from using mask")
        return
    end
    
    -- Ustaw cooldown (30 sekund)
    MaskCooldown[steamID] = CurTime() + 30
    
    print("[SCP-035 DEBUG] All checks passed - transforming player")
    
    -- Transformuj gracza w SCP-035
    ply:BecomeSCP035()
    
    -- Usuń maskę
    self:Remove()
    
    print("[SCP-035] Player " .. ply:Nick() .. " successfully transformed into SCP-035")
end 