-- SCP-330 Client Module dla gamemode Breach
-- Zarządza efektami klienckie SCP-330

-- SCP-330 Client functions
SCP330 = SCP330 or {}
SCP330.Client = SCP330.Client or {}

-- Client configuration
SCP330.Client.Config = {
    ProximityRadius = 150,
    WarningDuration = 4,
    BloodOverlayDuration = 4
}

-- Track proximity warnings shown
SCP330.Client.WarningsShown = {}

-- Play sound function
function SCP330.Client:PlaySound(soundPath)
    local ply = LocalPlayer()
    if IsValid(ply) then
        ply:EmitSound(soundPath)
    end
end

-- Create blood overlay effect
function SCP330.Client:CreateBloodOverlay()
    local ply = LocalPlayer()
    if not IsValid(ply) or ply.SCP330_BloodOverlay then return end
    
    ply.SCP330_BloodOverlay = true
    
    local startTime = CurTime()
    local duration = self.Config.BloodOverlayDuration
    local fadeInTime = duration * 0.5
    local fadeOutTime = duration * 0.5
    
    -- Play breathing sound
    local breathingSounds = {
        "scp_330/heavy_breath_1.mp3",
        "scp_330/heavy_breath_2.mp3",
        "scp_330/heavy_breath_3.mp3"
    }
    self:PlaySound(breathingSounds[math.random(#breathingSounds)])
    
    -- Create overlay effect
    hook.Add("HUDPaint", "SCP330_BloodOverlay_" .. ply:EntIndex(), function()
        if not IsValid(ply) then
            hook.Remove("HUDPaint", "SCP330_BloodOverlay_" .. ply:EntIndex())
            return
        end
        
        local elapsed = CurTime() - startTime
        if elapsed >= duration then
            hook.Remove("HUDPaint", "SCP330_BloodOverlay_" .. ply:EntIndex())
            ply.SCP330_BloodOverlay = nil
            return
        end
        
        local alpha
        if elapsed <= fadeInTime then
            alpha = 200 * (elapsed / fadeInTime)
        else
            alpha = 200 * (1 - ((elapsed - fadeInTime) / fadeOutTime))
        end
        
        -- Draw blood-red overlay
        surface.SetDrawColor(139, 0, 0, alpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())
        
        -- Apply color modification for extra effect
        local colorMod = {
            ["$pp_colour_contrast"] = 1.2,
            ["$pp_colour_colour"] = 0.8,
            ["$pp_colour_mulr"] = 0.3,
            ["$pp_colour_mulg"] = 0.1,
            ["$pp_colour_mulb"] = 0.1
        }
        DrawColorModify(colorMod)
        
        -- Motion blur effect
        DrawMotionBlur(0.1, 0.5, 0.1)
    end)
end

-- Create proximity warning effect
function SCP330.Client:CreateProximityWarning(entity)
    if not IsValid(entity) then return end
    
    local entIndex = entity:EntIndex()
    if self.WarningsShown[entIndex] then return end
    
    self.WarningsShown[entIndex] = true
    
    -- Play warning sound
    self:PlaySound("scp_330/on_first_contact.mp3")
    
    local startTime = CurTime()
    local duration = self.Config.WarningDuration
    local maxAlpha = 255
    
    hook.Add("HUDPaint", "SCP330_ProximityWarning_" .. entIndex, function()
        local elapsed = CurTime() - startTime
        if elapsed >= duration then
            hook.Remove("HUDPaint", "SCP330_ProximityWarning_" .. entIndex)
            return
        end
        
        local alpha = maxAlpha * (1 - (elapsed / duration))
        local size = 0.3 + (elapsed / duration) * 2
        
        local scrW, scrH = ScrW(), ScrH()
        local centerX, centerY = scrW * 0.5, scrH * 0.5
        
        -- Create scaling matrix
        local matrix = Matrix()
        matrix:Translate(Vector(centerX, centerY, 0))
        matrix:Scale(Vector(size, size, 1))
        matrix:Translate(Vector(-centerX, -centerY, 0))
        
        cam.PushModelMatrix(matrix)
        
        -- Draw warning text with custom font if available
        local font = "DermaLarge"
        if surface.GetFont and surface.GetFont("SCP330_Warning") then
            font = "SCP330_Warning"
        end
        
        draw.DrawText("take no more than two,", font, centerX, centerY - 20, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
        draw.DrawText("please!!", font, centerX, centerY + 20, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
        
        cam.PopModelMatrix()
        
        -- Apply color modification
        local colorTab = {
            ["$pp_colour_contrast"] = math.Clamp(elapsed / duration + 0.3, 0, 1)
        }
        DrawColorModify(colorTab)
        
        -- Motion blur effect
        DrawMotionBlur(0.1, 0.2, 0.05)
    end)
end

-- Clean up warning for specific entity
function SCP330.Client:CleanupWarning(entIndex)
    if self.WarningsShown[entIndex] then
        self.WarningsShown[entIndex] = nil
        hook.Remove("HUDPaint", "SCP330_ProximityWarning_" .. entIndex)
    end
end

-- Network message handlers
net.Receive("SCP330_PlaySound", function()
    local soundPath = net.ReadString()
    SCP330.Client:PlaySound(soundPath)
end)

net.Receive("SCP330_BloodEffect", function()
    SCP330.Client:CreateBloodOverlay()
end)

net.Receive("SCP330_ProximityWarning", function()
    local entity = net.ReadEntity()
    if IsValid(entity) then
        SCP330.Client:CreateProximityWarning(entity)
    end
end)

-- Create custom font for warnings
hook.Add("Initialize", "SCP330_CreateFont", function()
    surface.CreateFont("SCP330_Warning", {
        font = "Arial",
        size = 48,
        weight = 700,
        antialias = true,
        shadow = true
    })
end)

-- Clean up on disconnect
hook.Add("ShutDown", "SCP330_Cleanup", function()
    -- Remove all SCP-330 related hooks
    for name, _ in pairs(hook.GetTable().HUDPaint or {}) do
        if string.StartWith(name, "SCP330_") then
            hook.Remove("HUDPaint", name)
        end
    end
end)

-- Debug commands for admins (available to all, but only for testing)
concommand.Add("scp330_test_blood", function(ply)
    local localPly = LocalPlayer()
    if IsValid(localPly) and localPly:IsAdmin() then
        SCP330.Client:CreateBloodOverlay()
    else
        print("[SCP-330] Admin only command")
    end
end)

concommand.Add("scp330_test_warning", function(ply)
    local localPly = LocalPlayer()
    if IsValid(localPly) and localPly:IsAdmin() then
        -- Create a fake entity for testing
        local fakeEntity = {
            EntIndex = function() return 999 end,
            IsValid = function() return true end
        }
        SCP330.Client:CreateProximityWarning(fakeEntity)
    else
        print("[SCP-330] Admin only command")
    end
end)

print("[SCP-330] Client module loaded successfully!") 