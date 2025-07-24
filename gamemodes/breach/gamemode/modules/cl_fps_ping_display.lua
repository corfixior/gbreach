-- FPS and Ping Display for Breach gamemode

-- ConVar for toggling the display
local showFPSPing = CreateClientConVar("breach_fps_ping_enabled", "1", true, false, "Show FPS and Ping display")

-- Variables for FPS calculation
local fps = 0
local lastUpdate = 0
local frameCount = 0

-- Hook for calculating FPS
hook.Add("Think", "BR_CalculateFPS", function()
    frameCount = frameCount + 1
    
    if CurTime() - lastUpdate >= 1 then
        fps = frameCount
        frameCount = 0
        lastUpdate = CurTime()
    end
end)

-- Hook for drawing FPS and Ping
hook.Add("HUDPaint", "BR_FPSPingDisplay", function()
    if not showFPSPing:GetBool() then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Position at top left
    local x = 10
    local y = 10
    
    -- Background
    draw.RoundedBox(6, x, y, 120, 50, Color(0, 0, 0, 200))
    
    -- FPS Display
    local fpsColor = fps >= 60 and Color(100, 255, 100) or 
                    fps >= 30 and Color(255, 255, 100) or 
                    Color(255, 100, 100)
    
    draw.SimpleText("FPS:", "DermaDefault", x + 10, y + 10, Color(200, 200, 200))
    draw.SimpleText(tostring(fps), "DermaDefaultBold", x + 100, y + 10, fpsColor, TEXT_ALIGN_RIGHT)
    
    -- Ping Display
    local ping = ply:Ping()
    local pingColor = ping <= 50 and Color(100, 255, 100) or 
                     ping <= 100 and Color(255, 255, 100) or 
                     Color(255, 100, 100)
    
    draw.SimpleText("Ping:", "DermaDefault", x + 10, y + 28, Color(200, 200, 200))
    draw.SimpleText(ping .. " ms", "DermaDefaultBold", x + 100, y + 28, pingColor, TEXT_ALIGN_RIGHT)
end)

-- Console command to toggle
concommand.Add("breach_toggle_fps_ping", function()
    local current = showFPSPing:GetBool()
    showFPSPing:SetBool(not current)
    
    if showFPSPing:GetBool() then
        print("FPS/Ping display enabled")
    else
        print("FPS/Ping display disabled")
    end
end)