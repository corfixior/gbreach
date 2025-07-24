AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Döner Kebab Stand"
ENT.Author = "Breach Team"
ENT.Contact = ""
ENT.Purpose = "Healing kebab station for facility personnel"
ENT.Instructions = "Use [E] to get kebab and heal"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.Category = "Breach Food Service"

if CLIENT then
    surface.CreateFont("breach_kebab_title", {
        font = "Arial",
        extended = false,
        size = 24,
        weight = 700,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    })
    
    surface.CreateFont("breach_kebab_status", {
        font = "Arial",
        extended = false,
        size = 18,
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    })
end

function ENT:Draw()
    self:DrawModel()

    local Ang = self:GetAngles()
    Ang:RotateAroundAxis(self:GetUp(), 90)
    Ang:RotateAroundAxis(self:GetRight(), 90)
    Ang:RotateAroundAxis(self:GetForward(), 180)

    -- Title sign
    cam.Start3D2D(self:GetPos() + self:GetUp() * 60 - self:GetRight() * 2 + self:GetForward() * 7, Ang, 0.1)
        draw.RoundedBox(4, -100, -20, 200, 40, Color(150, 50, 0, 200))
        draw.SimpleText("DÖNER KEBAB", "breach_kebab_title", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()

    -- Status display
    cam.Start3D2D(self:GetPos() - self:GetForward() * 16.5 - self:GetRight() * 9 - self:GetUp() * 0.5, Ang, 0.08)
        local portions = self:GetNWInt("portions", 10)
        local status_text = "Ready: " .. portions .. " portions"
        local status_color = Color(0, 255, 0)
        
        if portions <= 0 then
            status_text = "Empty"
            status_color = Color(255, 0, 0)
        elseif portions <= 3 then
            status_color = Color(255, 165, 0)
        end
        
        draw.SimpleText(status_text, "breach_kebab_status", 0, 0, status_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

function ENT:Initialize()
    print("[KEBAB DEBUG] Initialize called")
    self:SetModel("models/doner_makinesi/doner_stand.mdl")
    print("[KEBAB DEBUG] Model set")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    print("[KEBAB DEBUG] Physics initialized")

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
        print("[KEBAB DEBUG] Physics object configured")
    else
        print("[KEBAB DEBUG] WARNING: No physics object!")
    end

    if CLIENT then
        self.kebab_entity = self:GetNWEntity("kebab_entity")
        print("[KEBAB DEBUG] Client initialization done")
        return
    end

    print("[KEBAB DEBUG] Server initialization starting")
    -- SERVER only code
    self:SetUseType(SIMPLE_USE)
    
    -- Initialize player usage tracking
    self.used_players = {}
    
    -- Create döner meat entity
    local kebab = ents.Create("br_kebab_meat")
    if IsValid(kebab) then
        kebab:SetPos(self:GetPos() - self:GetForward() * 4.5 + self:GetUp() * 26)
        kebab:SetAngles(self:GetAngles())
        kebab:SetParent(self)
        kebab:Spawn()
        kebab:SetMoveType(MOVETYPE_NONE)
        kebab:SetLocalAngles(Angle(0, 0, 0))
        
        -- Make sure kebab is visible
        kebab:SetNoDraw(false)
        kebab:SetColor(Color(255, 255, 255, 255))
        
        self.kebab = kebab
        self:SetNWEntity("kebab_entity", kebab)
        print("[KEBAB DEBUG] Kebab meat entity created at: " .. tostring(kebab:GetPos()))
    else
        print("[KEBAB DEBUG] ERROR: Failed to create kebab meat entity")
    end

    self.next_use = 0
    self:SetNWInt("portions", 10) -- Start with 10 portions
    print("[KEBAB DEBUG] Server initialization complete, portions set to 10")
end

function ENT:Use(ply, caller, useType, value)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if CurTime() < self.next_use then return end
    
    -- Check if player is SCP (excluding SCP-999 which is friendly)
    if ply:GTeam() == TEAM_SCP and ply:GetNClass() != ROLES.ROLE_SCP999 then
        ply:PrintMessage(HUD_PRINTTALK, "[KEBAB] SCPs cannot consume human food!")
        return
    end
    
    -- Check if player is Security Droid
    if ply:GetNClass() == ROLES.ROLE_SECURITY_DROID then
        ply:PrintMessage(HUD_PRINTTALK, "[KEBAB] ERROR: Food incompatible with droid chassis!")
        ply:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 75, math.random(90, 110))
        return
    end
    
    -- Check if player is spectator
    if ply:GTeam() == TEAM_SPEC then
        ply:PrintMessage(HUD_PRINTTALK, "[KEBAB] Spectators cannot use kebab stand!")
        return
    end
    
    local portions = self:GetNWInt("portions", 0)
    
    if portions <= 0 then
        ply:PrintMessage(HUD_PRINTTALK, "[KEBAB] Stand is empty! Wait for next round.")
        return
    end
    
    -- Check if player already used kebab stand this round
    local steamid = ply:SteamID()
    if self.used_players[steamid] then
        ply:PrintMessage(HUD_PRINTTALK, "[KEBAB] You already got kebab this round! One per person.")
        return
    end
    
    -- Check if player already has kebab
    if ply:HasWeapon("weapon_doner_ayran") then
        ply:PrintMessage(HUD_PRINTTALK, "[KEBAB] You already have kebab! Eat it first.")
        return
    end
    
    -- Give kebab weapon instead of direct healing
    ply:Give("weapon_doner_ayran")
    
    -- Mark player as having used kebab stand this round
    self.used_players[steamid] = true
    
    -- Reduce portions
    portions = portions - 1
    self:SetNWInt("portions", portions)
    
    -- Update döner size
    if IsValid(self.kebab) then
        local scale_factor = portions / 10
        self.kebab:SetModelScale(math.max(scale_factor, 0.1), 0)
    end

    self.next_use = CurTime() + 1
    
    ply:PrintMessage(HUD_PRINTTALK, "[KEBAB] Got fresh kebab! Use LMB to eat it. Portions left: " .. portions)
    
    -- Sound effect
    ply:EmitSound("physics/cardboard/cardboard_box_impact_hard3.wav", 60, 100)
end

function ENT:OnRemove()
    if SERVER and IsValid(self.kebab) then
        self.kebab:Remove()
    end
end 