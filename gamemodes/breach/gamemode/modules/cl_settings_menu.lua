-- Settings menu for Breach gamemode
local PANEL = {}

function PANEL:Init()
    self:SetSize(400, 300)
    self:Center()
    self:SetTitle("Settings / Ustawienia")
    self:SetVisible(true)
    self:SetDraggable(true)
    self:ShowCloseButton(true)
    self:MakePopup()
    
    -- Dark theme
    self.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 255))
        draw.RoundedBox(4, 0, 0, w, 25, Color(60, 60, 60, 255))
    end
    
    -- Tips checkbox
    local tipsCheck = vgui.Create("DCheckBoxLabel", self)
    tipsCheck:SetPos(20, 50)
    tipsCheck:SetText("Enable Tips / Włącz podpowiedzi")
    tipsCheck:SetConVar("breach_tips_enabled")
    tipsCheck:SetTextColor(Color(255, 255, 255))
    tipsCheck:SizeToContents()
    
    -- Vest HUD checkbox
    local vestHudCheck = vgui.Create("DCheckBoxLabel", self)
    vestHudCheck:SetPos(20, 80)
    vestHudCheck:SetText("Show Vest Info / Pokaż info o kamizelce")
    vestHudCheck:SetConVar("breach_vest_hud_enabled")
    vestHudCheck:SetTextColor(Color(255, 255, 255))
    vestHudCheck:SizeToContents()
    
    -- Door indicators checkbox
    local doorIndicatorCheck = vgui.Create("DCheckBoxLabel", self)
    doorIndicatorCheck:SetPos(20, 110)
    doorIndicatorCheck:SetText("Show Door Access Indicators / Pokaż wskaźniki dostępu do drzwi")
    doorIndicatorCheck:SetConVar("breach_door_indicators_enabled")
    doorIndicatorCheck:SetTextColor(Color(255, 255, 255))
    doorIndicatorCheck:SizeToContents()
    
    -- Weapon damage modifiers HUD checkbox
    local weaponModifiersCheck = vgui.Create("DCheckBoxLabel", self)
    weaponModifiersCheck:SetPos(20, 140)
    weaponModifiersCheck:SetText("Show Weapon Damage Modifiers / Pokaż mnożniki obrażeń broni")
    weaponModifiersCheck:SetConVar("br_weapon_modifiers_hud")
    weaponModifiersCheck:SetTextColor(Color(255, 255, 255))
    weaponModifiersCheck:SizeToContents()
    
    -- FPS/Ping display checkbox
    local fpsPingCheck = vgui.Create("DCheckBoxLabel", self)
    fpsPingCheck:SetPos(20, 170)
    fpsPingCheck:SetText("Show FPS/Ping / Pokaż FPS/Ping")
    fpsPingCheck:SetConVar("breach_fps_ping_enabled")
    fpsPingCheck:SetTextColor(Color(255, 255, 255))
    fpsPingCheck:SizeToContents()
    
    -- More settings can be added here later
    
    -- Close button
    local closeBtn = vgui.Create("DButton", self)
    closeBtn:SetText("Close / Zamknij")
    closeBtn:SetPos(150, 250)
    closeBtn:SetSize(100, 30)
    closeBtn.DoClick = function()
        self:Close()
    end
    
    closeBtn.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(100, 100, 100, 255))
        if s:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(120, 120, 120, 255))
        end
    end
end

vgui.Register("BreachSettingsMenu", PANEL, "DFrame")

-- Open settings menu function
function OpenSettingsMenu()
    if IsValid(SettingsMenu) then
        SettingsMenu:Remove()
    end
    
    SettingsMenu = vgui.Create("BreachSettingsMenu")
end

-- Hook for chat commands
hook.Add("OnPlayerChat", "BreachSettingsCommand", function(ply, text, team, dead)
    if ply == LocalPlayer() then
        text = string.lower(text)
        if text == "!settings" or text == "!ustawienia" then
            OpenSettingsMenu()
            return true -- Hide the message
        end
    end
end)