AddCSLuaFile()

SWEP.Author = "AI Assistant"
SWEP.Category = "SCP"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = ""

SWEP.PrintName = "SCP-1499"
SWEP.Slot = 2
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModelFOV = 62
SWEP.ViewModelFlip = false
SWEP.AnimPrefix = "rpg"

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.droppable = true
SWEP.teams = {2,3,5,6,7}

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

SWEP.ViewModel = ""
SWEP.WorldModel = "models/scp1499/scp1499mask.mdl"

SWEP.HoldType = "slam"

SWEP.NextTeleport = 0

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self.NextTeleport = 0
end

function SWEP:Deploy()
    return true
end

function SWEP:PrimaryAttack()
    if not IsFirstTimePredicted() then return end
    if preparing or postround then return end
    if not IsValid(self.Owner) then return end
    
    -- Check team restrictions (no SCPs)
    if self.Owner:GTeam() == TEAM_SCP then 
        return 
    end
    
    -- Check cooldown (90 seconds)
    if self.NextTeleport > CurTime() then
        if CLIENT then
            local timeLeft = math.ceil(self.NextTeleport - CurTime())
            LocalPlayer():PrintMessage(HUD_PRINTCENTER, "SCP-1499 on cooldown: " .. timeLeft .. "s")
        end
        return
    end
    
    if SERVER then
        self:TeleportToDimension()
    end
end

function SWEP:SecondaryAttack()
    -- No secondary attack
end

if SERVER then
    function SWEP:TeleportToDimension()
        if not IsValid(self.Owner) then return end
        
        -- Save original position
        local originalPos = self.Owner:GetPos()
        local originalAng = self.Owner:GetAngles()
        
        -- Set cooldown (90 seconds)
        self.NextTeleport = CurTime() + 90
        
        -- Teleport to dimension (outside map)
        local dimensionPos = originalPos + Vector(0, 0, -10000)
        self.Owner:SetPos(dimensionPos)
        
        -- Visual effect
        self.Owner:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 150), 1.5, 0)
        
        -- Save return data
        self.Owner.SCP1499_ReturnPos = originalPos
        self.Owner.SCP1499_ReturnAng = originalAng
        self.Owner.SCP1499_ReturnTime = CurTime() + 10
        
        -- Synchronizuj czas powrotu do klienta
        self.Owner:SetNWFloat("SCP1499_ReturnTime", CurTime() + 10)
        
        -- Set timer for return
        timer.Create("SCP1499_Return_" .. self.Owner:SteamID64(), 10, 1, function()
            if IsValid(self.Owner) then
                self:ReturnFromDimension()
            end
        end)
        
        -- Freeze player briefly
        self.Owner:Freeze(true)
        timer.Simple(1.5, function()
            if IsValid(self.Owner) then
                self.Owner:Freeze(false)
            end
        end)
    end
    
    function SWEP:ReturnFromDimension()
        if not IsValid(self.Owner) then return end
        if not self.Owner.SCP1499_ReturnPos then return end
        
        -- 10% chance to go to Pocket Dimension instead
        if math.random(1, 100) <= 10 then
            local pocketPos = GetPocketPos()
            if pocketPos then
                self.Owner:SetPos(pocketPos)
                self.Owner:SetAngles(Angle(0, math.random(-180, 180), 0))
                
                -- Visual effect for pocket dimension
                self.Owner:ScreenFade(SCREENFADE.IN, Color(100, 0, 0, 100), 2, 0)
                
                -- Clear return data
                self.Owner.SCP1499_ReturnPos = nil
                self.Owner.SCP1499_ReturnAng = nil
                self.Owner.SCP1499_ReturnTime = nil
                self.Owner:SetNWFloat("SCP1499_ReturnTime", 0)
                return
            end
        end
        
        -- Normal return to original position
        self.Owner:SetPos(self.Owner.SCP1499_ReturnPos)
        self.Owner:SetAngles(self.Owner.SCP1499_ReturnAng)
        
        -- Visual effect
        self.Owner:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 100), 1, 0)
        
        -- Clear return data
        self.Owner.SCP1499_ReturnPos = nil
        self.Owner.SCP1499_ReturnAng = nil
        self.Owner.SCP1499_ReturnTime = nil
        
        -- Wyczyść timer na kliencie
        self.Owner:SetNWFloat("SCP1499_ReturnTime", 0)
    end
    
    -- Clean up on disconnect
    hook.Add("PlayerDisconnected", "SCP1499_Cleanup", function(ply)
        timer.Remove("SCP1499_Return_" .. ply:SteamID64())
    end)
    
    -- Clean up on round end
    hook.Add("PrepareRound", "SCP1499_RoundCleanup", function()
        for _, ply in pairs(player.GetAll()) do
            timer.Remove("SCP1499_Return_" .. ply:SteamID64())
            ply.SCP1499_ReturnPos = nil
            ply.SCP1499_ReturnAng = nil
            ply.SCP1499_ReturnTime = nil
            ply:SetNWFloat("SCP1499_ReturnTime", 0)
        end
    end)
end

function SWEP:Think()
    -- Sync cooldown to client
    if SERVER then
        self:SetNWFloat("NextTeleport", self.NextTeleport)
    else
        self.NextTeleport = self:GetNWFloat("NextTeleport", 0)
    end
end

function SWEP:Holster()
    return true
end

function SWEP:OnRemove()
    if SERVER and IsValid(self.Owner) then
        timer.Remove("SCP1499_Return_" .. self.Owner:SteamID64())
        self.Owner:SetNWFloat("SCP1499_ReturnTime", 0)
    end
end

if CLIENT then
    surface.CreateFont("SCP1499_Small", {
        font = "Trebuchet24", 
        size = 18,
        weight = 500,
        antialias = true,
        shadow = true
    })

    function SWEP:DrawHUD()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        -- Pozycja HUD prosto nad celownikiem
        local x = ScrW() / 2
        local y = ScrH() / 2 - 50 -- 50 pikseli nad środkiem ekranu
        
        -- Cooldown
        local cooldown = math.max(0, self.NextTeleport - CurTime())
        
        -- Czas do powrotu z wymiaru
        local returnTime = ply:GetNWFloat("SCP1499_ReturnTime", 0)
        local timeUntilReturn = math.max(0, returnTime - CurTime())
        
        -- Pasek postępu - ustawienia
        local barWidth = 100
        local barHeight = 4
        
        -- Jeśli jesteś w wymiarze (pokazuje tylko pasek i czas)
        if timeUntilReturn > 0 then
            -- Tekst
            local timeText = string.format("COMEBACK: %.1fs", timeUntilReturn)
            draw.SimpleText(timeText, "SCP1499_Small", x, y - 20, Color(255, 255, 100), TEXT_ALIGN_CENTER)
            
            -- Pasek postępu
            local progress = 1 - (timeUntilReturn / 10)
            
            -- Tło paska
            surface.SetDrawColor(0, 0, 0, 150)
            surface.DrawRect(x - barWidth/2, y, barWidth, barHeight)
            
            -- Wypełnienie paska
            surface.SetDrawColor(255, 255, 100, 255)
            surface.DrawRect(x - barWidth/2, y, barWidth * progress, barHeight)
            
        -- Jeśli nie jesteś w wymiarze (cooldown)
        elseif cooldown > 0 then
            -- Tekst
            draw.SimpleText("CD: " .. math.ceil(cooldown) .. "s", "SCP1499_Small", x, y - 20, Color(255, 100, 100), TEXT_ALIGN_CENTER)
            
            -- Pasek postępu
            local progress = 1 - (cooldown / 90)
            
            -- Tło paska
            surface.SetDrawColor(0, 0, 0, 150)
            surface.DrawRect(x - barWidth/2, y, barWidth, barHeight)
            
            -- Wypełnienie paska
            surface.SetDrawColor(255, 100, 100, 255)
            surface.DrawRect(x - barWidth/2, y, barWidth * progress, barHeight)
            
        else
            -- Gotowy do użycia
            draw.SimpleText("READY", "SCP1499_Small", x, y - 20, Color(100, 255, 100), TEXT_ALIGN_CENTER)
            
            -- Pasek pełny
            surface.SetDrawColor(0, 0, 0, 150)
            surface.DrawRect(x - barWidth/2, y, barWidth, barHeight)
            
            surface.SetDrawColor(100, 255, 100, 255)
            surface.DrawRect(x - barWidth/2, y, barWidth, barHeight)
        end
    end
end 