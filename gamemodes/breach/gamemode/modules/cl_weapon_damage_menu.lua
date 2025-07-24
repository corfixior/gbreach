-- Weapon Damage Modifiers Menu
-- Client-side GUI with improved layout

local WEAPON_DAMAGE_MODIFIERS = {}
local WeaponDamagePanel = nil
local CurrentWeaponPanel = nil

-- Receive modifiers from server
net.Receive("BR_SyncWeaponModifiers", function()
    WEAPON_DAMAGE_MODIFIERS = net.ReadTable()
    
    -- Update GUI if open
    if IsValid(WeaponDamagePanel) and WeaponDamagePanel.UpdateWeaponList then
        WeaponDamagePanel:UpdateWeaponList()
    end
    
    -- Update current weapon display
    if IsValid(CurrentWeaponPanel) then
        CurrentWeaponPanel:UpdateDisplay()
    end
end)

-- Function to create weapon panel with text inputs
local function CreateWeaponPanel(weaponClass, modifiers, parent)
    local weaponPanel = vgui.Create("DPanel", parent)
    weaponPanel:SetHeight(80)
    weaponPanel:Dock(TOP)
    weaponPanel:DockMargin(0, 0, 0, 5)
    weaponPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60, 200))
        
        -- Weapon name
        draw.SimpleText(weaponClass, "DermaDefaultBold", 10, 15, Color(255, 255, 255))
        
        -- Get weapon print name if available
        local wepTable = weapons.Get(weaponClass)
        if wepTable and wepTable.PrintName then
            draw.SimpleText(wepTable.PrintName, "DermaDefault", 10, 35, Color(200, 200, 200))
        end
    end
    
    -- VS SCP controls
    local scpLabel = vgui.Create("DLabel", weaponPanel)
    scpLabel:SetPos(400, 15)
    scpLabel:SetText("VS SCP:")
    scpLabel:SetTextColor(Color(255, 100, 100))
    scpLabel:SizeToContents()
    
    local scpInput = vgui.Create("DTextEntry", weaponPanel)
    scpInput:SetPos(460, 10)
    scpInput:SetSize(60, 25)
    scpInput:SetNumeric(true)
    scpInput:SetValue(string.format("%.2f", modifiers.vs_scp))
    scpInput.OnEnter = function(self)
        local value = tonumber(self:GetValue()) or 1.0
        value = math.Clamp(value, 0, 5)
        self:SetValue(string.format("%.2f", value))
        
        -- Send update to server
        net.Start("BR_UpdateWeaponModifier")
        net.WriteString(weaponClass)
        net.WriteFloat(value)
        net.WriteFloat(modifiers.vs_human)
        net.SendToServer()
        
        modifiers.vs_scp = value
    end
    scpInput.OnLoseFocus = scpInput.OnEnter
    
    -- VS Human controls
    local humanLabel = vgui.Create("DLabel", weaponPanel)
    humanLabel:SetPos(400, 45)
    humanLabel:SetText("VS Human:")
    humanLabel:SetTextColor(Color(100, 200, 100))
    humanLabel:SizeToContents()
    
    local humanInput = vgui.Create("DTextEntry", weaponPanel)
    humanInput:SetPos(460, 40)
    humanInput:SetSize(60, 25)
    humanInput:SetNumeric(true)
    humanInput:SetValue(string.format("%.2f", modifiers.vs_human))
    humanInput.OnEnter = function(self)
        local value = tonumber(self:GetValue()) or 1.0
        value = math.Clamp(value, 0, 5)
        self:SetValue(string.format("%.2f", value))
        
        -- Send update to server
        net.Start("BR_UpdateWeaponModifier")
        net.WriteString(weaponClass)
        net.WriteFloat(modifiers.vs_scp)
        net.WriteFloat(value)
        net.SendToServer()
        
        modifiers.vs_human = value
    end
    humanInput.OnLoseFocus = humanInput.OnEnter
    
    -- Reset button for this weapon
    local resetBtn = vgui.Create("DButton", weaponPanel)
    resetBtn:SetPos(weaponPanel:GetWide() - 80, 25)
    resetBtn:SetSize(70, 30)
    resetBtn:SetText("Reset")
    resetBtn.DoClick = function()
        scpInput:SetValue("1.00")
        humanInput:SetValue("1.00")
        scpInput:OnEnter()
        humanInput:OnEnter()
    end
    resetBtn.Paint = function(self, w, h)
        local color = self:IsHovered() and Color(100, 100, 100) or Color(70, 70, 70)
        draw.RoundedBox(4, 0, 0, w, h, color)
    end
    
    return weaponPanel
end

-- Create current weapon display panel
local function CreateCurrentWeaponPanel(parent)
    CurrentWeaponPanel = vgui.Create("DPanel", parent)
    CurrentWeaponPanel:Dock(RIGHT)
    CurrentWeaponPanel:SetWide(250)
    CurrentWeaponPanel:DockMargin(5, 5, 5, 5)
    CurrentWeaponPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(40, 40, 40, 250))
        draw.RoundedBox(8, 0, 0, w, 30, Color(20, 20, 20, 255))
        draw.SimpleText("Current Weapon", "DermaDefaultBold", w/2, 15, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    CurrentWeaponPanel.UpdateDisplay = function(self)
        -- Clear old display
        for _, child in pairs(self:GetChildren()) do
            if child.IsInfoPanel then
                child:Remove()
            end
        end
        
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) then
            local noWepPanel = vgui.Create("DPanel", self)
            noWepPanel:SetPos(10, 40)
            noWepPanel:SetSize(230, 60)
            noWepPanel.IsInfoPanel = true
            noWepPanel.Paint = function(self, w, h)
                draw.SimpleText("No weapon equipped", "DermaDefault", w/2, h/2, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            return
        end
        
        local weaponClass = wep:GetClass()
        local modifiers = WEAPON_DAMAGE_MODIFIERS[weaponClass] or { vs_scp = 1.0, vs_human = 1.0 }
        
        -- Weapon info panel
        local infoPanel = vgui.Create("DPanel", self)
        infoPanel:SetPos(10, 40)
        infoPanel:SetSize(230, 150)
        infoPanel.IsInfoPanel = true
        infoPanel.Paint = function(self, w, h)
            -- Weapon class
            draw.SimpleText("Class:", "DermaDefault", 5, 5, Color(200, 200, 200))
            draw.SimpleText(weaponClass, "DermaDefaultBold", 5, 20, Color(255, 255, 255))
            
            -- Weapon print name
            if wep.PrintName then
                draw.SimpleText("Name:", "DermaDefault", 5, 45, Color(200, 200, 200))
                draw.SimpleText(wep.PrintName, "DermaDefaultBold", 5, 60, Color(255, 255, 255))
            end
            
            -- Divider
            surface.SetDrawColor(100, 100, 100, 255)
            surface.DrawLine(5, 85, w-5, 85)
            
            -- Modifiers
            draw.SimpleText("Current Modifiers:", "DermaDefaultBold", 5, 95, Color(255, 200, 0))
            
            -- VS SCP
            local scpColor = modifiers.vs_scp > 1 and Color(255, 100, 100) or 
                           modifiers.vs_scp < 1 and Color(100, 100, 255) or 
                           Color(200, 200, 200)
            draw.SimpleText("VS SCP:", "DermaDefault", 5, 115, Color(255, 100, 100))
            draw.SimpleText(string.format("%.2fx", modifiers.vs_scp), "DermaDefaultBold", 100, 115, scpColor)
            
            -- VS Human
            local humanColor = modifiers.vs_human > 1 and Color(255, 100, 100) or 
                             modifiers.vs_human < 1 and Color(100, 100, 255) or 
                             Color(200, 200, 200)
            draw.SimpleText("VS Human:", "DermaDefault", 5, 135, Color(100, 200, 100))
            draw.SimpleText(string.format("%.2fx", modifiers.vs_human), "DermaDefaultBold", 100, 135, humanColor)
        end
    end
    
    -- Update timer
    timer.Create("UpdateCurrentWeapon", 0.5, 0, function()
        if IsValid(CurrentWeaponPanel) then
            CurrentWeaponPanel:UpdateDisplay()
        else
            timer.Remove("UpdateCurrentWeapon")
        end
    end)
    
    CurrentWeaponPanel:UpdateDisplay()
    
    return CurrentWeaponPanel
end

-- Create the main menu
local function CreateWeaponDamageMenu()
    if IsValid(WeaponDamagePanel) then
        WeaponDamagePanel:Remove()
    end
    
    -- Request latest data from server
    net.Start("BR_RequestWeaponModifiers")
    net.SendToServer()
    
    -- Main frame - larger size
    WeaponDamagePanel = vgui.Create("DFrame")
    WeaponDamagePanel:SetSize(1000, 700)
    WeaponDamagePanel:Center()
    WeaponDamagePanel:SetTitle("Weapon Damage Modifiers")
    WeaponDamagePanel:SetVisible(true)
    WeaponDamagePanel:SetDraggable(true)
    WeaponDamagePanel:ShowCloseButton(true)
    WeaponDamagePanel:MakePopup()
    WeaponDamagePanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(50, 50, 50, 250))
        draw.RoundedBox(8, 0, 0, w, 25, Color(30, 30, 30, 255))
    end
    WeaponDamagePanel.OnClose = function()
        timer.Remove("UpdateCurrentWeapon")
    end
    
    -- Main container
    local mainContainer = vgui.Create("DPanel", WeaponDamagePanel)
    mainContainer:Dock(FILL)
    mainContainer:DockMargin(5, 5, 5, 5)
    mainContainer.Paint = function() end
    
    -- Left panel for weapon list
    local leftPanel = vgui.Create("DPanel", mainContainer)
    leftPanel:Dock(FILL)
    leftPanel:DockMargin(0, 0, 0, 0)
    leftPanel.Paint = function() end
    
    -- Current weapon panel on the right
    CreateCurrentWeaponPanel(mainContainer)
    
    -- Info panel
    local infoPanel = vgui.Create("DPanel", leftPanel)
    infoPanel:Dock(TOP)
    infoPanel:SetHeight(60)
    infoPanel:DockMargin(0, 0, 0, 5)
    infoPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200))
        draw.SimpleText("Modify damage multipliers for CW2.0 weapons", "DermaDefault", 10, 10, Color(255, 255, 255))
        draw.SimpleText("Enter values between 0.00 and 5.00 | 1.00 = Normal damage", "DermaDefault", 10, 25, Color(200, 200, 200))
        draw.SimpleText("Changes are saved automatically and applied immediately", "DermaDefault", 10, 40, Color(200, 200, 200))
    end
    
    -- Search bar
    local searchPanel = vgui.Create("DPanel", leftPanel)
    searchPanel:Dock(TOP)
    searchPanel:SetHeight(35)
    searchPanel:DockMargin(0, 0, 0, 5)
    searchPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200))
    end
    
    local searchLabel = vgui.Create("DLabel", searchPanel)
    searchLabel:SetPos(10, 8)
    searchLabel:SetText("Search:")
    searchLabel:SetTextColor(Color(255, 255, 255))
    searchLabel:SizeToContents()
    
    local searchBox = vgui.Create("DTextEntry", searchPanel)
    searchBox:SetPos(60, 5)
    searchBox:SetSize(200, 25)
    searchBox:SetText("")
    searchBox.OnChange = function()
        if IsValid(WeaponDamagePanel) then
            WeaponDamagePanel:UpdateWeaponList(searchBox:GetValue())
        end
    end
    
    -- Reset all button
    local resetAllBtn = vgui.Create("DButton", searchPanel)
    resetAllBtn:SetPos(searchPanel:GetWide() - 270, 5)
    resetAllBtn:SetSize(150, 25)
    resetAllBtn:SetText("Reset All to Default")
    resetAllBtn.DoClick = function()
        Derma_Query(
            "Are you sure you want to reset ALL weapon damage modifiers to 1.0?",
            "Confirm Reset",
            "Yes", function()
                RunConsoleCommand("br_reset_weapon_modifiers")
            end,
            "No", function() end
        )
    end
    resetAllBtn.Paint = function(self, w, h)
        local color = self:IsHovered() and Color(200, 50, 50) or Color(150, 50, 50)
        draw.RoundedBox(4, 0, 0, w, h, color)
    end
    
    -- Headers
    local headerPanel = vgui.Create("DPanel", leftPanel)
    headerPanel:Dock(TOP)
    headerPanel:SetHeight(30)
    headerPanel:DockMargin(0, 0, 0, 5)
    headerPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))
        draw.SimpleText("Weapon", "DermaDefaultBold", 10, h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("VS SCP", "DermaDefaultBold", 430, h/2, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("VS Human", "DermaDefaultBold", 490, h/2, Color(100, 200, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Actions", "DermaDefaultBold", w - 45, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Weapon list
    local weaponScroll = vgui.Create("DScrollPanel", leftPanel)
    weaponScroll:Dock(FILL)
    weaponScroll:DockMargin(0, 0, 0, 0)
    
    local weaponContainer = vgui.Create("DPanel", weaponScroll)
    weaponContainer:Dock(FILL)
    weaponContainer.Paint = function() end
    
    -- Store weapon panels
    local weaponPanels = {}
    
    -- Function to update weapon list
    WeaponDamagePanel.UpdateWeaponList = function(self, filter)
        -- Clear existing panels
        for _, panel in pairs(weaponPanels) do
            if IsValid(panel) then
                panel:Remove()
            end
        end
        weaponPanels = {}
        
        -- Get all CW weapons
        local allWeapons = {}
        
        -- First add all known modifiers
        for weaponClass, modifiers in pairs(WEAPON_DAMAGE_MODIFIERS) do
            allWeapons[weaponClass] = modifiers
        end
        
        -- Then add any CW weapons from the weapon list that aren't already in modifiers
        for _, wep in pairs(weapons.GetList()) do
            if string.StartWith(wep.ClassName or "", "cw_") then
                if not allWeapons[wep.ClassName] then
                    allWeapons[wep.ClassName] = { vs_scp = 1.0, vs_human = 1.0 }
                end
            end
        end
        
        -- Sort weapons alphabetically
        local sortedWeapons = {}
        for weaponClass, _ in pairs(allWeapons) do
            if not filter or filter == "" or string.find(string.lower(weaponClass), string.lower(filter)) then
                table.insert(sortedWeapons, weaponClass)
            end
        end
        table.sort(sortedWeapons)
        
        -- Create entry for each weapon
        local yPos = 5
        for _, weaponClass in ipairs(sortedWeapons) do
            local modifiers = allWeapons[weaponClass]
            local panel = CreateWeaponPanel(weaponClass, modifiers, weaponContainer)
            panel:SetPos(5, yPos)
            panel:SetWide(weaponContainer:GetWide() - 10)
            table.insert(weaponPanels, panel)
            yPos = yPos + 85
        end
        
        -- Update container height
        weaponContainer:SetTall(yPos)
    end
    
    -- Initial population
    WeaponDamagePanel:UpdateWeaponList()
end

-- Console command to open menu
concommand.Add("br_weapon_damage_menu", function()
    if not LocalPlayer():IsSuperAdmin() then
        chat.AddText(Color(255, 0, 0), "[WEAPON MODIFIERS] ", Color(255, 255, 255), "Only super admins can access this menu!")
        return
    end
    
    CreateWeaponDamageMenu()
end)

-- Add to F4 menu or custom menu
hook.Add("OnSpawnMenuOpen", "BR_WeaponDamageMenuHint", function()
    if LocalPlayer():IsSuperAdmin() then
        -- Show hint once per session
        if not LocalPlayer().WeaponMenuHintShown then
            LocalPlayer().WeaponMenuHintShown = true
            timer.Simple(0.5, function()
                chat.AddText(Color(255, 200, 0), "[TIP] ", Color(255, 255, 255), "Use console command 'br_weapon_damage_menu' to open weapon damage modifiers menu")
            end)
        end
    end
end)

-- Help command
concommand.Add("br_weapon_damage_help", function()
    print("=== Weapon Damage Modifiers System ===")
    print("Commands:")
    print("  br_weapon_damage_menu - Opens the weapon damage modifiers menu (admin only)")
    print("  br_reload_weapon_modifiers - Reloads modifiers from file (admin only)")
    print("  br_reset_weapon_modifiers - Resets all modifiers to 1.0 (admin only)")
    print("  br_weapon_modifiers_hud 0/1 - Toggle HUD display")
    print("")
    print("Multiplier values:")
    print("  1.0 = Normal damage (100%)")
    print("  0.5 = Half damage (50%)")
    print("  2.0 = Double damage (200%)")
    print("  0.0 = No damage")
    print("  5.0 = Maximum allowed (500%)")
end)

-- HUD Display for weapon modifiers
local showModifiersHUD = CreateClientConVar("br_weapon_modifiers_hud", "1", true, false, "Show weapon damage modifiers on HUD")

hook.Add("HUDPaint", "BR_WeaponModifiersHUD", function()
    if not showModifiersHUD:GetBool() then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    
    local weaponClass = wep:GetClass()
    
    -- Only show for CW weapons
    if not string.StartWith(weaponClass, "cw_") then
        return
    end
    
    local modifiers = WEAPON_DAMAGE_MODIFIERS[weaponClass] or { vs_scp = 1.0, vs_human = 1.0 }
    
    -- Get base damage (for CW weapons)
    local baseDamage = 0
    if wep.Damage then
        baseDamage = wep.Damage
    elseif wep.Primary and wep.Primary.Damage then
        baseDamage = wep.Primary.Damage
    end
    
    -- Position on the right side of screen (compact layout)
    local x = ScrW() - 100
    local y = ScrH() / 2 - 50
    
    -- Background
    draw.RoundedBox(6, x - 10, y - 5, 100, 90, Color(0, 0, 0, 200))
    
    -- Title
    draw.SimpleText("DMG MOD", "DermaDefaultBold", x + 35, y + 5, Color(255, 200, 0), TEXT_ALIGN_CENTER)
    
    -- SCP Section
    local scpY = y + 20
    local scpColor = modifiers.vs_scp > 1 and Color(255, 100, 100) or
                   modifiers.vs_scp < 1 and Color(100, 150, 255) or
                   Color(200, 200, 200)
    
    draw.SimpleText("SCP", "DermaDefault", x, scpY, Color(255, 150, 150))
    draw.SimpleText(string.format("%.2fx", modifiers.vs_scp), "DermaDefaultBold", x + 75, scpY, scpColor, TEXT_ALIGN_RIGHT)
    
    if baseDamage > 0 then
        local scpDamage = baseDamage * modifiers.vs_scp
        draw.SimpleText(string.format("%.0f dmg", scpDamage), "DermaDefault", x + 75, scpY + 12, Color(200, 200, 200), TEXT_ALIGN_RIGHT)
    end
    
    -- Human Section
    local humanY = y + 50
    local humanColor = modifiers.vs_human > 1 and Color(255, 100, 100) or
                     modifiers.vs_human < 1 and Color(100, 150, 255) or
                     Color(200, 200, 200)
    
    draw.SimpleText("Human", "DermaDefault", x, humanY, Color(150, 255, 150))
    draw.SimpleText(string.format("%.2fx", modifiers.vs_human), "DermaDefaultBold", x + 75, humanY, humanColor, TEXT_ALIGN_RIGHT)
    
    if baseDamage > 0 then
        local humanDamage = baseDamage * modifiers.vs_human
        draw.SimpleText(string.format("%.0f dmg", humanDamage), "DermaDefault", x + 75, humanY + 12, Color(200, 200, 200), TEXT_ALIGN_RIGHT)
    end
end)