-- Client-side vest HUD display
CreateClientConVar("breach_vest_hud_enabled", "1", true, false, "Enable/disable vest HUD display")

local vestInfo = {
    ["armor_security"] = {name = "Security Vest", reduction = "10%", color = Color(100, 100, 200)},
    ["armor_mtfguard"] = {name = "MTF Guard Vest", reduction = "15%", color = Color(50, 100, 200)},
    ["armor_mtfl"] = {name = "MTF-L Vest", reduction = "17%", color = Color(50, 100, 200)},
    ["armor_mtfmedic"] = {name = "MTF Medic Vest", reduction = "15%", color = Color(200, 50, 50)},
    ["armor_csecurity"] = {name = "Security Chief Vest", reduction = "17%", color = Color(150, 150, 200)},
    ["armor_mtfcom"] = {name = "MTF Commander Vest", reduction = "27%", color = Color(200, 200, 50)},
    ["armor_hazmat"] = {name = "Hazmat Suit", reduction = "20%", color = Color(200, 200, 100)},
    ["armor_ntf"] = {name = "NTF Vest", reduction = "25%", color = Color(50, 50, 200)},
    ["armor_chaosins"] = {name = "Chaos Insurgency Vest", reduction = "20%", color = Color(100, 50, 50)},
    ["armor_goc"] = {name = "GOC Vest", reduction = "30%", color = Color(150, 150, 150)},
    ["armor_fireproof"] = {name = "Fireproof Vest", reduction = "75% Fire", color = Color(255, 100, 0)},
    ["armor_electroproof"] = {name = "Electroproof Vest", reduction = "100% Electric", color = Color(100, 200, 255)},
    ["armor_heavysupport"] = {name = "Heavy Support Vest", reduction = "50%", color = Color(80, 80, 80)}
}

-- Create font for vest display
surface.CreateFont("VestHUDFont", {
    font = "Roboto",
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
    shadow = true,
    additive = false,
    outline = false,
})

surface.CreateFont("VestHUDFontSmall", {
    font = "Roboto",
    extended = false,
    size = 14,
    weight = 400,
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

-- Hook to draw vest info
hook.Add("HUDPaint", "Breach_VestHUD", function()
    if disablehud then return end
    if playing then return end
    
    -- Check if vest HUD is enabled
    if GetConVar("breach_vest_hud_enabled"):GetInt() == 0 then return end
    
    local ply = LocalPlayer()
    if not ply:Alive() then return end
    if ply:GTeam() == TEAM_SPEC then return end
    
    -- Check if player has vest
    if ply.UsingArmor and vestInfo[ply.UsingArmor] then
        local vest = vestInfo[ply.UsingArmor]
        local w, h = ScrW(), ScrH()
        
        -- Position at very bottom
        local yPos = h - 20
        
        -- Simple text display
        draw.SimpleText(vest.name, "VestHUDFont", w / 2, yPos - 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Damage Reduction: " .. vest.reduction, "VestHUDFontSmall", w / 2, yPos, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-- Network receiver for vest updates
net.Receive("BR_UpdateVest", function()
    local ply = LocalPlayer()
    local vestType = net.ReadString()
    
    if vestType == "" then
        ply.UsingArmor = nil
    else
        ply.UsingArmor = vestType
    end
end)

-- Clear vest info on death
hook.Add("PlayerDeath", "BR_ClearVestOnDeath", function(victim, inflictor, attacker)
    if victim == LocalPlayer() then
        victim.UsingArmor = nil
    end
end)

-- Clear vest info on spawn
hook.Add("PlayerSpawn", "BR_ClearVestOnSpawn", function(ply)
    if ply == LocalPlayer() then
        timer.Simple(0.1, function()
            if IsValid(ply) and not ply.UsingArmor then
                ply.UsingArmor = nil
            end
        end)
    end
end)

-- Clear vest info when selecting a new class
hook.Add("BR_SelectingClass", "BR_ClearVestOnClassSelect", function()
    LocalPlayer().UsingArmor = nil
end)

-- Clear vest info on round restart
hook.Add("BR_RoundRestart", "BR_ClearVestOnRoundRestart", function()
    LocalPlayer().UsingArmor = nil
end)

-- Additional cleanup on respawn
gameevent.Listen("player_spawn")
hook.Add("player_spawn", "BR_ClearVestOnRespawn", function(data)
    local ply = Player(data.userid)
    if ply == LocalPlayer() then
        ply.UsingArmor = nil
    end
end)