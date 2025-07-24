-- VIP Panic Button System - Client Side
-- Handles key binding, HUD alerts and visual effects

-- VIP panic variables
local VIPPanicCooldown = 0
local VIPPanicAlerts = {}

-- Create font for VIP alerts
surface.CreateFont("VIPPanicFont", {
    font = "Arial",
    extended = false,
    size = 16,
    weight = 700,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = true,
    additive = false,
    outline = false,
})

surface.CreateFont("VIPPanicFontBig", {
    font = "Arial",
    extended = false,
    size = 18,
    weight = 700,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = true,
    additive = false,
    outline = false,
})

-- Function to send panic signal
local function SendVIPPanic()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    if ply:GetNClass() != ROLES.ROLE_VIP then return end
    
    -- Send panic signal to server
    net.Start("VIP_PanicButtonPressed")
    net.SendToServer()
end

-- Key binding for VIP panic button
hook.Add("PlayerButtonDown", "VIP_PanicButton", function(ply, button)
    if ply != LocalPlayer() then return end
    if button != KEY_P then return end -- P key for panic button
    if ply:GetNClass() != ROLES.ROLE_VIP then return end
    
    SendVIPPanic()
end)

-- Receive panic alerts from server
net.Receive("VIP_PanicAlert", function()
    local vipName = net.ReadString()
    local vipPos = net.ReadVector()
    local endTime = net.ReadFloat()
    
    -- Store alert data
    table.insert(VIPPanicAlerts, {
        vipName = vipName,
        pos = vipPos,
        endTime = endTime,
        startTime = CurTime()
    })
    
    -- Play alert sound
    surface.PlaySound("ambient/alarms/klaxon1.wav")
    
    -- Show message
    local prefix = "[VIP PANIC] "
    local message = vipName .. " has activated their panic button!"
    if clang and clang.VIP_PANIC then
        prefix = clang.VIP_PANIC.alert_prefix
        message = string.format(clang.VIP_PANIC.alert_message, vipName)
    end
    chat.AddText(Color(255, 100, 100), prefix, Color(255, 255, 255), message)
end)

-- Draw VIP panic alerts on HUD
hook.Add("HUDPaint", "VIP_DrawPanicAlerts", function()
    if disablehud then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    if ply:GTeam() == TEAM_SPEC then return end
    
    -- Only show alerts to MTF and CI Spy
    if not (ply:GTeam() == TEAM_GUARD or (ply:GTeam() == TEAM_CHAOS and ply:GetNClass() == ROLES.ROLE_CHAOSSPY)) then return end
    
    -- Clean up expired alerts
    for i = #VIPPanicAlerts, 1, -1 do
        if CurTime() > VIPPanicAlerts[i].endTime then
            table.remove(VIPPanicAlerts, i)
        end
    end
    
    -- Draw active alerts
    for i, alert in ipairs(VIPPanicAlerts) do
        local timeLeft = math.max(0, alert.endTime - CurTime())
        local alertAge = CurTime() - alert.startTime
        
        -- Convert 3D position to 2D screen position
        local screenPos = alert.pos:ToScreen()
        
        if screenPos.visible then
            -- Calculate blinking alpha for red border
            local blinkSpeed = 3 -- Blinks per second
            local blinkAlpha = math.abs(math.sin(CurTime() * blinkSpeed * math.pi)) * 255
            
            -- Draw yellow circle with red blinking border
            local circleRadius = 25
            local circleX, circleY = screenPos.x, screenPos.y
            
            -- Draw yellow circle with custom function
            draw.NoTexture()
            
            -- Yellow background circle
            surface.SetDrawColor(255, 255, 0, 200)
            local segments = 32
            for i = 0, segments do
                local angle1 = (i / segments) * 360
                local angle2 = ((i + 1) / segments) * 360
                
                local x1 = circleX + math.cos(math.rad(angle1)) * circleRadius
                local y1 = circleY + math.sin(math.rad(angle1)) * circleRadius
                local x2 = circleX + math.cos(math.rad(angle2)) * circleRadius
                local y2 = circleY + math.sin(math.rad(angle2)) * circleRadius
                
                surface.DrawPoly({
                    {x = circleX, y = circleY},
                    {x = x1, y = y1},
                    {x = x2, y = y2}
                })
            end
            
            -- Red blinking border
            surface.SetDrawColor(255, 0, 0, blinkAlpha)
            for thickness = 1, 3 do
                local borderRadius = circleRadius + thickness
                for i = 0, segments do
                    local angle1 = (i / segments) * 360
                    local angle2 = ((i + 1) / segments) * 360
                    
                    local x1 = circleX + math.cos(math.rad(angle1)) * borderRadius
                    local y1 = circleY + math.sin(math.rad(angle1)) * borderRadius
                    local x2 = circleX + math.cos(math.rad(angle2)) * borderRadius
                    local y2 = circleY + math.sin(math.rad(angle2)) * borderRadius
                    
                    surface.DrawLine(x1, y1, x2, y2)
                end
            end
            
            -- Draw "VIP" text in center
            draw.SimpleText("VIP", "VIPPanicFontBig", circleX, circleY, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Draw VIP name above circle
            draw.SimpleText(alert.vipName, "VIPPanicFont", circleX, circleY - 40, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Draw timer below circle
            draw.SimpleText(string.format("%.0fs", timeLeft), "VIPPanicFont", circleX, circleY + 35, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    
    -- Draw panic button instruction for VIP
    if ply:GetNClass() == ROLES.ROLE_VIP then
        local instructionText = "Press [P] - VIP Panic Button"
        if VIPPanicCooldown > CurTime() then
            local cooldownLeft = math.ceil(VIPPanicCooldown - CurTime())
            instructionText = "VIP Panic Button - Cooldown: " .. cooldownLeft .. "s"
            if clang and clang.VIP_PANIC then
                instructionText = string.format(clang.VIP_PANIC.cooldown_hint, cooldownLeft)
            end
        else
            if clang and clang.VIP_PANIC then
                instructionText = clang.VIP_PANIC.button_hint
            end
        end
        
        -- Draw at bottom center of screen
        draw.SimpleText(instructionText, "VIPPanicFont", ScrW() / 2, ScrH() - 100, Color(255, 255, 100, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-- Handle panic button cooldown updates from server
net.Receive("VIP_PanicCooldown", function()
    VIPPanicCooldown = net.ReadFloat()
end)

-- Console command for VIP panic (alternative to key press)
concommand.Add("vip_panic", function()
    SendVIPPanic()
end)

-- Bind suggestion message
hook.Add("Initialize", "VIP_PanicBindSuggestion", function()
    timer.Simple(5, function()
        local ply = LocalPlayer()
        if IsValid(ply) and ply:GetNClass() == ROLES.ROLE_VIP then
            local message = "Press P for panic button or type 'vip_panic' in console!"
            if clang and clang.VIP_PANIC then
                message = clang.VIP_PANIC.bind_suggestion
            end
            chat.AddText(Color(255, 255, 100), "[VIP] ", Color(255, 255, 255), message)
        end
    end)
end) 