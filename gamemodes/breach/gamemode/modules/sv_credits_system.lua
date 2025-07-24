-- ===============================================
-- SYSTEM KREDYTÓW ZA ZABÓJSTWA - SCP BREACH
-- ===============================================

-- Player metatable
local PlayerMeta = FindMetaTable("Player")

-- Network strings
util.AddNetworkString("UpdateCredits")
-- util.AddNetworkString("CreditsNotification") -- Wyłączone powiadomienia

-- Inicjalizacja kredytów dla gracza
local function InitPlayerCredits(ply)
    if not ply.Credits then
        ply.Credits = 0
    end
    if not ply.RoundKills then
        ply.RoundKills = 0
    end
    if not ply.TeamKills then
        ply.TeamKills = 0
    end
end

-- FUNKCJE ZARZĄDZANIA KREDYTAMI
function PlayerMeta:GetCredits()
    InitPlayerCredits(self)
    return self.Credits or 0
end

function PlayerMeta:SetCredits(amount)
    InitPlayerCredits(self)
    self.Credits = math.max(0, amount)
    
    -- Wyślij aktualizację do klienta
    net.Start("UpdateCredits")
        net.WriteInt(self.Credits, 32)
    net.Send(self)
end

function PlayerMeta:AddCredits(amount, reason)
    InitPlayerCredits(self)
    local oldCredits = self.Credits
    self.Credits = math.max(0, self.Credits + amount)
    
    -- Wyślij aktualizację do klienta
    net.Start("UpdateCredits")
        net.WriteInt(self.Credits, 32)
    net.Send(self)
    
    -- Powiadomienia o kredytach wyłączone
    
    return self.Credits
end

function PlayerMeta:CanAfford(amount)
    return self:GetCredits() >= amount
end

function PlayerMeta:SpendCredits(amount, reason)
    if not self:CanAfford(amount) then
        return false
    end
    
    self:AddCredits(-amount, reason or "Purchase")
    return true
end

-- TABELA NAGRÓD ZA ZABÓJSTWA (kredyty za różne drużyny)
local KILL_REWARDS = {
    [TEAM_SCP] = 15,     -- SCP = 15 kredytów (trudne do zabicia)
    [TEAM_GUARD] = 8,    -- MTF = 8 kredytów  
    [TEAM_CLASSD] = 5,   -- Klasa D = 5 kredytów
    [TEAM_SCI] = 6,      -- Naukowcy = 6 kredytów
    [TEAM_CHAOS] = 8,    -- Chaos = 8 kredytów
    [TEAM_GOC] = 12,     -- GOC = 12 kredytów (elita)
    [TEAM_SPEC] = 0      -- Spektatorzy = 0 kredytów
}

-- UWAGA: System kredytów za zabójstwa jest teraz zintegrowany bezpośrednio w GM:PlayerDeath w sv_player_hooks.lua
-- Oryginalny hook PlayerDeath został usunięty, ponieważ GM:PlayerDeath ma pierwszeństwo nad hookami

-- Reset kredytów na początku rundy - BEZ STARTOWYCH KREDYTÓW
hook.Add("BreachPreround", "CreditsSystem_Reset", function()
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) then
            ply:SetCredits(0) -- Gracze zaczynają z 0 kredytów
            ply.RoundKills = 0
            ply.TeamKills = 0
        end
    end
    print("[CREDITS] Reset all credits to 0")
end)

-- Bonus za przeżycie - WYŁĄCZONY
-- hook.Add("BreachPostround", "CreditsSystem_SurvivalBonus", function()
--     for _, ply in pairs(player.GetAll()) do
--         if IsValid(ply) and ply:Alive() and ply:GTeam() != TEAM_SPEC then
--             ply:AddCredits(5, "Survival bonus (+5 credits)")
--         end
--     end
--     print("[CREDITS] Gave survival bonus to alive players")
-- end)

-- Inicjalizacja kredytów gdy gracz dołącza
hook.Add("PlayerInitialSpawn", "CreditsSystem_Init", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            InitPlayerCredits(ply)
            ply:SetCredits(0)
        end
    end)
end)

-- Koncommand do sprawdzania kredytów (admin) - wyłączone
-- concommand.Add("br_credits_check", function(ply, cmd, args)
--     if not IsValid(ply) or not ply:IsAdmin() then return end
--     local target = nil
--     for _, p in pairs(player.GetAll()) do
--         if string.find(string.lower(p:Nick()), string.lower(args[1])) then
--             target = p
--             break
--         end
--     end
--     if IsValid(target) then
--         ply:PrintMessage(HUD_PRINTTALK, "[CREDITS] " .. target:Nick() .. " has " .. target:GetCredits() .. " credits")
--     end
-- end)

-- Koncommand do dawania kredytów (admin) - wyłączone
-- concommand.Add("br_credits_give", function(ply, cmd, args)
--     if not IsValid(ply) or not ply:IsAdmin() then return end
--     local target = nil
--     for _, p in pairs(player.GetAll()) do
--         if string.find(string.lower(p:Nick()), string.lower(args[1])) then
--             target = p
--             break
--         end
--     end
--     if IsValid(target) and tonumber(args[2]) then
--         target:AddCredits(tonumber(args[2]), "Admin gave credits")
--     end
-- end)

-- Koncommand do resetowania kredytów (admin)
concommand.Add("br_credits_reset", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    for _, p in pairs(player.GetAll()) do
        if IsValid(p) then
            p:SetCredits(0)
        end
    end
    
    -- Komunikat o resecie kredytów wyłączony
    print("[CREDITS ADMIN] " .. ply:Nick() .. " reset all credits")
end)

-- Koncommand do ustawienia kredytów wszystkim (admin)
concommand.Add("br_credits_setall", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    if not args[1] then
        ply:PrintMessage(HUD_PRINTTALK, "[CREDITS] Usage: br_credits_setall <amount>")
        return
    end
    
    local amount = tonumber(args[1])
    if not amount then
        ply:PrintMessage(HUD_PRINTTALK, "[CREDITS] Invalid amount!")
        return
    end
    
    for _, p in pairs(player.GetAll()) do
        if IsValid(p) then
            p:SetCredits(amount)
        end
    end
    
    ply:PrintMessage(HUD_PRINTTALK, "[CREDITS] Set all player credits to " .. amount)
    print("[CREDITS ADMIN] " .. ply:Nick() .. " set all credits to " .. amount)
end)

-- Informacja o systemie kredytów przy spawnie gracza
hook.Add("PlayerSpawn", "CreditsSystem_Info", function(ply)
    if ply.CreditsInfoSent then return end
    
    timer.Simple(3, function()
        if IsValid(ply) and not ply.CreditsInfoSent then
            ply.CreditsInfoSent = true
        end
    end)
end)

-- Koncommand dla gracza do sprawdzania swoich statystyk
concommand.Add("br_mystats", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    InitPlayerCredits(ply)
    
    ply:PrintMessage(HUD_PRINTTALK, "=== YOUR ROUND STATS ===")
    ply:PrintMessage(HUD_PRINTTALK, "Credits: " .. ply:GetCredits())
    ply:PrintMessage(HUD_PRINTTALK, "Kills this round: " .. (ply.RoundKills or 0))
    ply:PrintMessage(HUD_PRINTTALK, "Team kills: " .. (ply.TeamKills or 0))
    ply:PrintMessage(HUD_PRINTTALK, "Team: " .. team.GetName(ply:GTeam() or TEAM_SPEC))
end)

-- Koncommand dla gracza do sprawdzania tylko kredytów - wyłączone
-- concommand.Add("br_credits", function(ply, cmd, args)
--     if not IsValid(ply) then return end
--     ply:PrintMessage(HUD_PRINTTALK, "[CREDITS] Your credits: " .. ply:GetCredits())
-- end)

-- Koncommand do testowania systemu kredytów - wyłączone
-- concommand.Add("br_credits_test", function(ply, cmd, args)
--     if not IsValid(ply) or not ply:IsAdmin() then return end
--     -- Test funkcjonalności kredytów bez komunikatów HUD
-- end)

print("[BREACH] Credits system loaded!")