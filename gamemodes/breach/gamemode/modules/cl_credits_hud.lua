-- ===============================================
-- KLIENCKI HUD SYSTEMU KREDYTÓW - SCP BREACH
-- ===============================================

-- Zmienne lokalne
local playerCredits = 0
local notifications = {}
local showCredits = true

-- Odbieranie aktualizacji kredytów
net.Receive("UpdateCredits", function()
    playerCredits = net.ReadInt(32)
end)

-- Odbieranie powiadomień o kredytach - wyłączone
-- net.Receive("CreditsNotification", function()
--     local amount = net.ReadInt(32)
--     local reason = net.ReadString()
--     local newTotal = net.ReadInt(32)
--     -- Powiadomienia wyłączone
-- end)

-- Funkcja rysowania HUD kredytów
local function DrawCreditsHUD()
    if not showCredits then return end
    if LocalPlayer():GTeam() == TEAM_SPEC then return end
    if not LocalPlayer():Alive() then return end
    
    local scrW, scrH = ScrW(), ScrH()
    
    -- Pozycja HUD (prawy górny róg)
    local x = scrW - 250
    local y = 20
    
    -- Tło dla kredytów
    draw.RoundedBox(8, x, y, 220, 50, Color(20, 20, 20, 180))
    draw.RoundedBox(8, x, y, 220, 25, Color(40, 40, 40, 200))
    
    -- Ikona kredytów
    draw.SimpleText("💰", "DermaLarge", x + 15, y + 5, Color(255, 215, 0), TEXT_ALIGN_LEFT)
    
    -- Tekst kredytów
    draw.SimpleText("Credits", "DermaDefault", x + 50, y + 5, Color(255, 255, 255), TEXT_ALIGN_LEFT)
    draw.SimpleText(tostring(playerCredits), "DermaDefaultBold", x + 50, y + 25, Color(255, 215, 0), TEXT_ALIGN_LEFT)
    
    -- Dodatkowe info (zabójstwa w rundzie)
    if LocalPlayer().RoundKills and LocalPlayer().RoundKills > 0 then
        draw.SimpleText("Kills: " .. LocalPlayer().RoundKills, "DermaDefault", x + 150, y + 25, Color(100, 255, 100), TEXT_ALIGN_LEFT)
    end
end

-- Funkcja rysowania powiadomień o kredytach
local function DrawCreditsNotifications()
    local scrW, scrH = ScrW(), ScrH()
    local startY = 100
    
    for i = #notifications, 1, -1 do
        local notif = notifications[i]
        if not notif then continue end
        
        -- Sprawdź czas życia powiadomienia (5 sekund)
        local age = CurTime() - notif.time
        if age > 5 then
            table.remove(notifications, i)
            continue
        end
        
        -- Animacja zanikania
        if age > 4 then
            notif.alpha = math.max(0, 255 - (age - 4) * 255)
        end
        
        -- Pozycja powiadomienia
        local y = startY + (i - 1) * 60
        local x = scrW - 300
        
        -- Kolor zależny od kwoty
        local amountColor = Color(100, 255, 100, notif.alpha) -- Zielony dla dodatnich
        if notif.amount < 0 then
            amountColor = Color(255, 100, 100, notif.alpha) -- Czerwony dla ujemnych
        end
        
        -- Tło powiadomienia
        draw.RoundedBox(6, x, y, 280, 50, Color(30, 30, 30, notif.alpha * 0.8))
        draw.RoundedBox(6, x, y, 280, 20, Color(50, 50, 50, notif.alpha * 0.9))
        
        -- Tekst powiadomienia
        local prefix = notif.amount > 0 and "+" or ""
        draw.SimpleText(prefix .. notif.amount .. " Credits", "DermaDefaultBold", x + 10, y + 2, amountColor, TEXT_ALIGN_LEFT)
        
        if notif.reason and notif.reason != "" then
            draw.SimpleText(notif.reason, "DermaDefault", x + 10, y + 25, Color(200, 200, 200, notif.alpha), TEXT_ALIGN_LEFT)
        end
    end
end

-- Hook rysowania HUD - wyłączony
-- hook.Add("HUDPaint", "CreditsHUD", function()
--     DrawCreditsHUD()
--     DrawCreditsNotifications()
-- end)

-- Komenda do ukrywania/pokazywania kredytów - wyłączona
-- concommand.Add("br_toggle_credits", function()
--     showCredits = not showCredits
--     LocalPlayer():PrintMessage(HUD_PRINTTALK, "[CREDITS] HUD " .. (showCredits and "enabled" or "disabled"))
-- end)

-- Funkcja dostępowa do kredytów (dla innych modułów)
function GetPlayerCredits()
    return playerCredits
end

-- Czyszczenie powiadomień na początku rundy
hook.Add("BreachPreround", "CreditsHUD_Reset", function()
    notifications = {}
    playerCredits = 0
end)

print("[BREACH] Credits HUD loaded!")