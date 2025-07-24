-- Kill notification system
-- Displays kill notifications on the right side of the screen

-- Table of active notifications
local killNotifications = {}

-- Colors for different classes (initialized later)
local classColors = {}
local classNames = {}

-- Initialize colors and names after all modules are loaded
hook.Add("Initialize", "InitKillNotifications", function()
    -- Colors for different classes
    classColors = {
        [TEAM_GUARD] = Color(100, 150, 255), -- Blue for MTF
        [TEAM_CHAOS] = Color(50, 150, 50), -- Dark green for Chaos
        [TEAM_CLASSD] = Color(255, 150, 50), -- Orange for Class-D
        [TEAM_SCI] = Color(100, 255, 255), -- Cyan for Scientists
        [TEAM_SCP] = Color(100, 255, 100), -- Green for SCP
        [TEAM_GOC] = Color(255, 255, 0), -- Yellow for GOC
        teamkill = Color(255, 50, 50) -- Red for teamkill
    }

    -- Class names in English
    classNames = {
        [TEAM_GUARD] = "MTF",
        [TEAM_CHAOS] = "Chaos Insurgency",
        [TEAM_CLASSD] = "Class-D",
        [TEAM_SCI] = "Scientist",
        [TEAM_SCP] = "SCP",
        [TEAM_GOC] = "GOC"
    }
end)

-- Function to add new notification
local function AddKillNotification(victimClass, victimName, points, isTeamkill)
    local notification = {
        victimClass = victimClass,
        victimName = victimName,
        points = points,
        isTeamkill = isTeamkill,
        startTime = CurTime(),
        alpha = 0,
        fadeIn = true,
        fadeOut = false
    }
    
    table.insert(killNotifications, notification)
    
    -- Remove old notifications if there are too many
    if #killNotifications > 5 then
        table.remove(killNotifications, 1)
    end
end

-- Network receiver for kill notifications
net.Receive("KillNotification", function()
    local victimClass = net.ReadInt(8)
    local victimName = net.ReadString()
    local points = net.ReadInt(16)
    local isTeamkill = net.ReadBool()
    
    AddKillNotification(victimClass, victimName, points, isTeamkill)
end)

-- Hook to draw notifications
hook.Add("HUDPaint", "DrawKillNotifications", function()
    if #killNotifications == 0 then return end
    
    local scrW, scrH = ScrW(), ScrH()
    local baseX = scrW * 0.51 -- Pozycja po prawej stronie crosshaira
    local baseY = scrH * 0.49
    local notificationHeight = 15
    local font = "DermaDefaultBold"
    
    -- Iterate through notifications from back to newest on top
    for i = #killNotifications, 1, -1 do
        local notif = killNotifications[i]
        local currentTime = CurTime()
        local timeSinceStart = currentTime - notif.startTime
        
        -- Calculate alpha based on time
        if notif.fadeIn and timeSinceStart < 0.3 then
            -- Fade in for first 0.3 seconds
            notif.alpha = math.min(255, (timeSinceStart / 0.3) * 255)
        elseif timeSinceStart >= 0.3 and timeSinceStart < 3.5 then
            -- Full visibility for 3.2 seconds
            notif.alpha = 255
            notif.fadeIn = false
        elseif timeSinceStart >= 3.5 and timeSinceStart < 4.0 then
            -- Fade out for last 0.5 seconds
            notif.fadeOut = true
            notif.alpha = math.max(0, 255 - ((timeSinceStart - 3.5) / 0.5) * 255)
        else
            -- Remove notification after 4 seconds
            table.remove(killNotifications, i)
            continue
        end
        
        -- Y position for this notification
        local yPos = baseY + (i - 1) * notificationHeight
        
        -- Choose color and text
        local classColor, text1, text2, text3
        local whiteColor = Color(255, 255, 255, notif.alpha)
        local shadowColor = Color(0, 0, 0, notif.alpha * 0.8)
        
        if notif.isTeamkill then
            classColor = Color(classColors.teamkill.r, classColors.teamkill.g, classColors.teamkill.b, notif.alpha)
            text1 = "TEAMKILL "
            text2 = notif.victimName
            text3 = string.format(", lose %d points", math.abs(notif.points))
        else
            classColor = Color((classColors[notif.victimClass] or Color(255, 255, 255)).r,
                              (classColors[notif.victimClass] or Color(255, 255, 255)).g,
                              (classColors[notif.victimClass] or Color(255, 255, 255)).b, notif.alpha)
            local className = classNames[notif.victimClass] or "Enemy"
            text1 = string.format("Killed %s ", className)
            text2 = notif.victimName
            text3 = string.format(", receive %d points", notif.points)
        end
        
        -- Calculate text widths
        surface.SetFont(font)
        local text1Width = surface.GetTextSize(text1)
        local text2Width = surface.GetTextSize(text2)
        
        -- Draw shadows
        draw.SimpleText(text1, font, baseX + 2, yPos + 2, shadowColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(text2, font, baseX + text1Width + 2, yPos + 2, shadowColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(text3, font, baseX + text1Width + text2Width + 2, yPos + 2, shadowColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Draw main texts
        draw.SimpleText(text1, font, baseX, yPos, classColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(text2, font, baseX + text1Width, yPos, whiteColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(text3, font, baseX + text1Width + text2Width, yPos, classColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end)