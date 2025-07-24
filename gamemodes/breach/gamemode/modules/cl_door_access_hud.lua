-- Client-side door access indicator system
local doorAccessData = {}

-- Materials for access indicators
local matCheck = Material("icon16/accept.png", "smooth")
local matX = Material("icon16/cancel.png", "smooth")

-- Test command to verify materials and drawing
concommand.Add("br_test_indicators", function()
    print("[DOOR ACCESS] Testing indicators...")
    print("  - Material Check valid: " .. tostring(matCheck and true or false))
    print("  - Material X valid: " .. tostring(matX and true or false))
    
    -- Draw test icons for 5 seconds
    local testTime = CurTime() + 5
    hook.Add("HUDPaint", "BR_TestIndicators", function()
        if CurTime() > testTime then
            hook.Remove("HUDPaint", "BR_TestIndicators")
            return
        end
        
        -- Draw test icons in center of screen
        surface.SetDrawColor(255, 255, 255, 255)
        
        surface.SetMaterial(matCheck)
        surface.DrawTexturedRect(ScrW()/2 - 64, ScrH()/2 - 32, 32, 32)
        
        surface.SetMaterial(matX)
        surface.DrawTexturedRect(ScrW()/2 + 32, ScrH()/2 - 32, 32, 32)
        
        draw.SimpleText("TEST INDICATORS (5s)", "Trebuchet24", ScrW()/2, ScrH()/2 + 32, Color(255,255,255), TEXT_ALIGN_CENTER)
    end)
end)

-- Receive door access data from server
net.Receive("BR_SyncDoorAccess", function()
    doorAccessData = net.ReadTable() or {}
    print("[DOOR ACCESS CLIENT] Received " .. table.Count(doorAccessData) .. " doors with access requirements")
    
    -- Debug: Print first few doors
    local count = 0
    for _, data in pairs(doorAccessData) do
        if type(data) == "table" and count < 3 then
            print("[DOOR ACCESS CLIENT] Door: " .. (data.name or "unknown") .. " at " .. tostring(data.pos) .. " with access: " .. (data.access or 0))
            count = count + 1
        end
    end
end)

-- Request door data from server when we're ready
local dataRequested = false
hook.Add("InitPostEntity", "BR_RequestDoorData", function()
    if not dataRequested then
        dataRequested = true
        timer.Simple(2, function()
            -- print("[DOOR ACCESS CLIENT] Requesting door data from server")
            net.Start("BR_RequestDoorAccess")
            net.SendToServer()
        end)
    end
end)

-- Also request when we spawn
hook.Add("LocalPlayerSpawn", "BR_RequestDoorDataSpawn", function()
    timer.Simple(1, function()
        if table.Count(doorAccessData) == 0 then
            -- print("[DOOR ACCESS CLIENT] No door data, requesting from server")
            net.Start("BR_RequestDoorAccess")
            net.SendToServer()
        end
    end)
end)

-- Request data if we don't have it after some time
timer.Simple(15, function()
    if table.Count(doorAccessData) == 0 then
        -- print("[DOOR ACCESS CLIENT] Still no door data, requesting from server")
        net.Start("BR_RequestDoorAccess")
        net.SendToServer()
    end
end)

-- Function to check if player has keycard access
local function CheckKeycardAccess(ply, requiredAccess)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "br_keycard" then
        return false
    end
    
    -- Check if keycard has the required access bits (use networked value)
    local keycardAccess = wep:GetNWInt("KeycardAccess", 0)
    return bit.band(keycardAccess, requiredAccess) > 0
end

-- Debug command to check door data
concommand.Add("br_debug_doors", function()
    print("[DOOR ACCESS DEBUG] Total doors stored: " .. table.Count(doorAccessData))
    
    local ply = LocalPlayer()
    if not IsValid(ply) then
        print("[DOOR ACCESS DEBUG] LocalPlayer not valid")
        return
    end
    
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then
        print("[DOOR ACCESS DEBUG] No active weapon")
    elseif wep:GetClass() ~= "br_keycard" then
        print("[DOOR ACCESS DEBUG] Active weapon is not a keycard: " .. wep:GetClass())
    else
        local networkAccess = wep:GetNWInt("KeycardAccess", 0)
        local localAccess = wep.Access or 0
        
        -- Convert to binary string manually
        local function toBinary(num)
            local binary = ""
            local temp = num
            if temp == 0 then return "00000000000" end
            while temp > 0 do
                binary = (temp % 2) .. binary
                temp = math.floor(temp / 2)
            end
            -- Pad to 11 digits
            while string.len(binary) < 11 do
                binary = "0" .. binary
            end
            return binary
        end
        
        print("[DOOR ACCESS DEBUG] Keycard equipped:")
        print("  - Networked access level: " .. networkAccess .. " (binary: " .. toBinary(networkAccess) .. ")")
        print("  - Local access level: " .. localAccess)
        print("  - Keycard type: " .. (wep:GetNWString("K_TYPE", "unknown")))
    end
    
    print("[DOOR ACCESS DEBUG] br_door_indicators_3d = " .. GetConVar("br_door_indicators_3d"):GetInt())
    print("[DOOR ACCESS DEBUG] disablehud = " .. tostring(disablehud))
    
    -- List all doors
    for k, v in pairs(doorAccessData) do
        if type(v) == "table" then
            print(string.format("[DOOR ACCESS DEBUG] Door %s: %s at %s, access required: %d",
                k, v.name or "unknown", tostring(v.pos), v.access or 0))
        end
    end
end)

-- Find doors in the world and match them with our data
local function UpdateDoorEntities()
    if not doorAccessData or #doorAccessData == 0 then return end
    
    -- Find all func_door and func_door_rotating entities
    local doors = {}
    table.Add(doors, ents.FindByClass("func_door"))
    table.Add(doors, ents.FindByClass("func_door_rotating"))
    table.Add(doors, ents.FindByClass("prop_door_rotating"))
    table.Add(doors, ents.FindByClass("func_button"))
    
    -- Match doors with our access data based on position
    for _, door in pairs(doors) do
        local doorPos = door:GetPos()
        
        for _, accessData in pairs(doorAccessData) do
            -- Skip non-table entries
            if type(accessData) ~= "table" then continue end
            
            -- Check if positions match (with some tolerance)
            if doorPos:Distance(accessData.pos) < 50 then
                -- Store access data on the entity for quick lookup
                door.BR_AccessRequired = accessData.access
                door.BR_AccessName = accessData.name
                break
            end
        end
    end
end

-- Update door entities when we receive new data
hook.Add("Think", "BR_UpdateDoorEntities", function()
    if not doorAccessData._updated then
        doorAccessData._updated = true
        timer.Simple(0.5, UpdateDoorEntities)
    end
end)

-- Alternative method: Draw indicators on doors themselves in 3D space
hook.Add("PostDrawTranslucentRenderables", "BR_DoorAccess3D", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    -- Check if player has a keycard equipped
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "br_keycard" then return end
    
    local eyePos = ply:EyePos()
    
    -- Draw 3D indicators for each door
    for _, doorData in pairs(doorAccessData) do
        -- Skip non-table entries
        if type(doorData) ~= "table" then continue end
        
        local doorPos = doorData.pos
        if not doorPos then continue end
        
        -- Calculate distance
        local dist = eyePos:Distance(doorPos)
        if dist > 400 then continue end
        
        -- Check access
        local hasAccess = CheckKeycardAccess(ply, doorData.access)
        
        -- Draw 3D2D panel
        local ang = (eyePos - doorPos):Angle()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        
        cam.Start3D2D(doorPos + Vector(0, 0, 20), ang, 0.2)
            -- Draw background
            surface.SetDrawColor(0, 0, 0, 180)
            surface.DrawRect(-50, -50, 100, 100)
            
            -- Draw icon
            if hasAccess then
                surface.SetDrawColor(100, 255, 100, 255)
                surface.SetMaterial(matCheck)
            else
                surface.SetDrawColor(255, 100, 100, 255)
                surface.SetMaterial(matX)
            end
            surface.DrawTexturedRect(-32, -32, 64, 64)
        cam.End3D2D()
    end
end)

-- ConVar to toggle between 2D HUD and 3D world indicators
CreateClientConVar("br_door_indicators_3d", "0", true, false, "Toggle between 2D HUD (0) and 3D world (1) door access indicators")

-- ConVar to enable/disable door indicators
CreateClientConVar("breach_door_indicators_enabled", "1", true, false, "Enable/disable door access indicators")

-- Debug function
local debugEnabled = false
local function DebugPrint(msg)
    if debugEnabled then
        -- print("[DOOR ACCESS HUD] " .. msg)
    end
end

-- Removed br_door_debug_draw command

-- Remove duplicate hook and rename to avoid conflicts
hook.Remove("HUDPaint", "BR_DoorAccessIndicators")

-- Main HUDPaint hook for 2D indicators
hook.Add("HUDPaint", "BR_DoorAccessHUD", function()
    -- Check if indicators are enabled
    if not GetConVar("breach_door_indicators_enabled"):GetBool() then return end
    
    if GetConVar("br_door_indicators_3d"):GetBool() then return end
    
    if disablehud then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    -- Check if player has a keycard equipped
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "br_keycard" then
        return
    end
    
    -- Debug: Check if we have data
    if table.Count(doorAccessData) == 0 then
        DebugPrint("No door access data available")
        return
    end
    
    -- Get player position and view direction
    local eyePos = ply:EyePos()
    local eyeAngles = ply:EyeAngles()
    local forward = eyeAngles:Forward()
    
    DebugPrint("Starting door drawing, total doors: " .. table.Count(doorAccessData))
    
    local doorsProcessed = 0
    local doorsInRange = 0
    local doorsInView = 0
    local doorsDrawn = 0
    
    -- Draw indicators for each door
    for _, doorData in pairs(doorAccessData) do
        -- Skip non-table entries (like _updated flag)
        if type(doorData) ~= "table" then continue end
        
        local doorPos = doorData.pos
        if not doorPos then continue end
        
        -- Calculate distance to door
        local dist = eyePos:Distance(doorPos)
        doorsProcessed = doorsProcessed + 1
        
        -- Only show indicators for nearby doors (within 500 units)
        if dist > 500 then
            DebugPrint("Door " .. (doorData.name or "unknown") .. " too far: " .. dist)
            continue
        end
        doorsInRange = doorsInRange + 1
        
        -- Check if door is in front of player
        local toTarget = (doorPos - eyePos):GetNormalized()
        local dot = forward:Dot(toTarget)
        
        -- Only show if door is in front of player (dot > 0.5 means within ~60 degree cone)
        if dot < 0.5 then
            DebugPrint("Door " .. (doorData.name or "unknown") .. " not in view cone: " .. dot)
            continue
        end
        doorsInView = doorsInView + 1
        
        -- Convert 3D position to 2D screen position
        local screenPos = doorPos:ToScreen()
        if not screenPos.visible then
            DebugPrint("Door " .. (doorData.name or "unknown") .. " not visible on screen")
            continue
        end
        doorsDrawn = doorsDrawn + 1
        
        -- Check if player has access
        local hasAccess = CheckKeycardAccess(ply, doorData.access)
        
        -- Calculate alpha based on distance (fade out as player gets further)
        local alpha = math.Clamp((500 - dist) / 500 * 255, 0, 255)
        
        -- Draw the appropriate icon
        surface.SetDrawColor(255, 255, 255, alpha)
        if hasAccess then
            surface.SetMaterial(matCheck)
        else
            surface.SetMaterial(matX)
        end
        
        -- Scale icon based on distance
        local iconSize = math.Clamp(32 * (500 - dist) / 500, 16, 32)
        surface.DrawTexturedRect(screenPos.x - iconSize/2, screenPos.y - iconSize/2, iconSize, iconSize)
        
        -- Draw door name below icon
        local font = "Trebuchet18"
        local textAlpha = math.Clamp(alpha - 50, 0, 255)
        
        if hasAccess then
            draw.SimpleTextOutlined(doorData.name, font, screenPos.x, screenPos.y + iconSize/2 + 5, 
                Color(100, 255, 100, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, textAlpha))
        else
            draw.SimpleTextOutlined(doorData.name, font, screenPos.x, screenPos.y + iconSize/2 + 5, 
                Color(255, 100, 100, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, textAlpha))
        end
    end
    
    if debugEnabled and doorsProcessed > 0 then
        DebugPrint("Doors processed: " .. doorsProcessed .. ", in range: " .. doorsInRange .. ", in view: " .. doorsInView .. ", drawn: " .. doorsDrawn)
    end
end)

-- Modified 3D hook to check ConVar
hook.Add("PostDrawTranslucentRenderables", "BR_DoorAccess3D", function()
    -- Check if indicators are enabled
    if not GetConVar("breach_door_indicators_enabled"):GetBool() then return end
    
    if not GetConVar("br_door_indicators_3d"):GetBool() then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    -- Check if player has a keycard equipped
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "br_keycard" then return end
    
    local eyePos = ply:EyePos()
    
    -- Draw 3D indicators for each door
    for _, doorData in pairs(doorAccessData) do
        -- Skip non-table entries
        if type(doorData) ~= "table" then continue end
        
        local doorPos = doorData.pos
        if not doorPos then continue end
        
        -- Calculate distance
        local dist = eyePos:Distance(doorPos)
        if dist > 400 then continue end
        
        -- Check access
        local hasAccess = CheckKeycardAccess(ply, doorData.access)
        
        -- Draw 3D2D panel
        local ang = (eyePos - doorPos):Angle()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        
        cam.Start3D2D(doorPos + Vector(0, 0, 20), ang, 0.2)
            -- Draw background
            surface.SetDrawColor(0, 0, 0, 180)
            surface.DrawRect(-50, -50, 100, 100)
            
            -- Draw icon
            if hasAccess then
                surface.SetDrawColor(100, 255, 100, 255)
                surface.SetMaterial(matCheck)
            else
                surface.SetDrawColor(255, 100, 100, 255)
                surface.SetMaterial(matX)
            end
            surface.DrawTexturedRect(-32, -32, 64, 64)
        cam.End3D2D()
    end
end)