-- Client-side death card display
local deathCardPanel = nil

-- Create fonts
surface.CreateFont("DeathCardTitle", {
    font = "Roboto",
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
    shadow = true,
    additive = false,
    outline = false,
})

surface.CreateFont("DeathCardBig", {
    font = "Roboto",
    extended = false,
    size = 20,
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

surface.CreateFont("DeathCardNormal", {
    font = "Roboto",
    extended = false,
    size = 16,
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

-- Weapon name translations
local weaponNames = {
    ["weapon_crowbar"] = "Crowbar",
    ["weapon_stunstick"] = "Stun Stick",
    ["cw_ak74"] = "AK-74",
    ["cw_ar15"] = "AR-15",
    ["cw_scarh"] = "SCAR-H",
    ["cw_g36c"] = "G36C",
    ["cw_ump45"] = "UMP45",
    ["cw_mp5"] = "MP5",
    ["cw_deagle"] = "Desert Eagle",
    ["cw_m249_official"] = "M249",
    ["cw_makarov"] = "Makarov",
    ["cw_mr96"] = "MR96",
    ["cw_p99"] = "P99",
    ["cw_shorty"] = "Shorty",
    ["weapon_scp_173"] = "Neck Snap",
    ["weapon_scp_457"] = "Fire",
    ["weapon_scp_049"] = "Touch",
    ["weapon_scp_096"] = "Claws",
    ["weapon_scp_106"] = "Pocket Dimension",
    ["weapon_scp_939"] = "Bite",
    ["weapon_scp_966"] = "Claws",
    ["weapon_scp_689"] = "Stare",
    ["weapon_scp_682"] = "Bite",
    ["weapon_scp_035"] = "Possession",
    ["weapon_scp_999"] = "Unknown",
    ["weapon_br_zombie_infect"] = "Infection",
}

-- Function to create death card
local function CreateDeathCard(attacker, weaponClass, weaponName, damageDealt, damageReceived)
    -- Remove existing panel if any
    if IsValid(deathCardPanel) then
        deathCardPanel:Remove()
    end
    
    local scrW, scrH = ScrW(), ScrH()
    
    -- Main panel
    deathCardPanel = vgui.Create("DPanel")
    deathCardPanel:SetSize(400, 250)
    deathCardPanel:SetPos(scrW/2 - 200, scrH - 350) -- Positioned 350 pixels from bottom
    deathCardPanel:SetAlpha(0)
    deathCardPanel:AlphaTo(255, 0.3, 0)
    
    deathCardPanel.Paint = function(self, w, h)
        -- Background
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 20, 240))
        draw.RoundedBox(8, 2, 2, w-4, h-4, Color(30, 30, 30, 240))
        
        -- Header
        draw.RoundedBoxEx(8, 2, 2, w-4, 40, Color(50, 50, 50, 240), true, true, false, false)
        draw.SimpleText("KILLED BY", "DeathCardTitle", w/2, 20, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Avatar container
    local avatarContainer = vgui.Create("DPanel", deathCardPanel)
    avatarContainer:SetPos(10, 50)
    avatarContainer:SetSize(84, 84)
    avatarContainer.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60))
    end
    
    -- Avatar
    local avatar = vgui.Create("AvatarImage", avatarContainer)
    avatar:SetSize(80, 80)
    avatar:SetPos(2, 2)
    avatar:SetPlayer(attacker, 84)
    
    -- Player name
    local playerName = attacker:Nick()
    if #playerName > 25 then
        playerName = string.sub(playerName, 1, 22) .. "..."
    end
    
    -- Info panel
    local infoX = 110
    local infoY = 55
    
    -- Player name label
    local nameLabel = vgui.Create("DLabel", deathCardPanel)
    nameLabel:SetPos(infoX, infoY)
    nameLabel:SetSize(280, 25)
    nameLabel:SetText(playerName)
    nameLabel:SetFont("DeathCardBig")
    nameLabel:SetTextColor(Color(255, 255, 255))
    
    -- Role/class
    local roleText = "Unknown"
    if attacker.GetNClass then
        roleText = GetLangRole(attacker:GetNClass()) or "Unknown"
    end
    
    local roleLabel = vgui.Create("DLabel", deathCardPanel)
    roleLabel:SetPos(infoX, infoY + 25)
    roleLabel:SetSize(280, 20)
    roleLabel:SetText(roleText)
    roleLabel:SetFont("DeathCardNormal")
    
    -- Set role color
    local roleColor = Color(200, 200, 200)
    if attacker.GTeam then
        local team = attacker:GTeam()
        if team == TEAM_SCP then
            roleColor = Color(237, 28, 63)
        elseif team == TEAM_GUARD then
            roleColor = Color(0, 100, 255)
        elseif team == TEAM_CLASSD then
            roleColor = Color(255, 130, 0)
        elseif team == TEAM_SCI then
            roleColor = Color(66, 188, 244)
        elseif team == TEAM_CHAOS then
            roleColor = Color(29, 81, 56)
        elseif team == TEAM_GOC then
            roleColor = Color(150, 150, 150)
        end
    end
    roleLabel:SetTextColor(roleColor)
    
    -- Weapon used
    local wepName = weaponNames[weaponClass] or weaponName
    local weaponLabel = vgui.Create("DLabel", deathCardPanel)
    weaponLabel:SetPos(infoX, infoY + 50)
    weaponLabel:SetSize(280, 20)
    weaponLabel:SetText("Weapon: " .. wepName)
    weaponLabel:SetFont("DeathCardNormal")
    weaponLabel:SetTextColor(Color(200, 200, 200))
    
    -- Damage statistics
    local damageY = 160
    
    -- Damage dealt to killer
    local dealtLabel = vgui.Create("DLabel", deathCardPanel)
    dealtLabel:SetPos(20, damageY)
    dealtLabel:SetSize(180, 25)
    dealtLabel:SetText("Damage dealt to killer:")
    dealtLabel:SetFont("DeathCardNormal")
    dealtLabel:SetTextColor(Color(200, 200, 200))
    
    local dealtValue = vgui.Create("DLabel", deathCardPanel)
    dealtValue:SetPos(20, damageY + 20)
    dealtValue:SetSize(180, 30)
    dealtValue:SetText(tostring(damageDealt))
    dealtValue:SetFont("DeathCardTitle")
    dealtValue:SetTextColor(Color(100, 255, 100))
    
    -- Damage received from killer
    local receivedLabel = vgui.Create("DLabel", deathCardPanel)
    receivedLabel:SetPos(220, damageY)
    receivedLabel:SetSize(180, 25)
    receivedLabel:SetText("Damage received:")
    receivedLabel:SetFont("DeathCardNormal")
    receivedLabel:SetTextColor(Color(200, 200, 200))
    
    local receivedValue = vgui.Create("DLabel", deathCardPanel)
    receivedValue:SetPos(220, damageY + 20)
    receivedValue:SetSize(180, 30)
    receivedValue:SetText(tostring(damageReceived))
    receivedValue:SetFont("DeathCardTitle")
    receivedValue:SetTextColor(Color(255, 100, 100))
    
    -- Auto-remove after 8 seconds
    timer.Simple(8, function()
        if IsValid(deathCardPanel) then
            deathCardPanel:AlphaTo(0, 0.3, 0, function()
                if IsValid(deathCardPanel) then
                    deathCardPanel:Remove()
                end
            end)
        end
    end)
end

-- Receive death card info
net.Receive("BR_ShowDeathCard", function()
    local attacker = net.ReadEntity()
    local weaponClass = net.ReadString()
    local weaponName = net.ReadString()
    local damageDealt = net.ReadUInt(16)
    local damageReceived = net.ReadUInt(16)
    
    if IsValid(attacker) then
        CreateDeathCard(attacker, weaponClass, weaponName, damageDealt, damageReceived)
    end
end)

-- Remove death card on respawn
hook.Add("PlayerSpawn", "BR_RemoveDeathCard", function(ply)
    if ply == LocalPlayer() and IsValid(deathCardPanel) then
        deathCardPanel:Remove()
    end
end)