-- VIP Panic Button System
-- Allows VIP to send panic signal visible to MTF and CI Spy

-- Network strings
util.AddNetworkString("VIP_PanicButtonPressed")
util.AddNetworkString("VIP_PanicAlert")
util.AddNetworkString("VIP_PanicCooldown")

-- VIP panic button variables
local VIP_PANIC_COOLDOWN = 60 -- 60 seconds cooldown
local VIP_PANIC_DURATION = 30 -- Alert lasts 30 seconds

-- Store active panic alerts
local ActivePanicAlerts = {}

-- Function to send panic alert
local function SendPanicAlert(vipPlayer, vipPos, alertEndTime)
    -- Remove any existing alerts from this VIP
    for i = #ActivePanicAlerts, 1, -1 do
        if ActivePanicAlerts[i].vip == vipPlayer then
            table.remove(ActivePanicAlerts, i)
        end
    end
    
    -- Add new alert
    table.insert(ActivePanicAlerts, {
        vip = vipPlayer,
        pos = vipPos,
        endTime = alertEndTime,
        startTime = CurTime()
    })
    
    -- Send to authorized players (MTF and CI Spy)
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            if ply:GTeam() == TEAM_GUARD or (ply:GTeam() == TEAM_CHAOS and ply:GetNClass() == ROLES.ROLE_CHAOSSPY) then
                net.Start("VIP_PanicAlert")
                    net.WriteString(vipPlayer:Nick())
                    net.WriteVector(vipPos)
                    net.WriteFloat(alertEndTime)
                net.Send(ply)
            end
        end
    end
    
    -- Send confirmation to VIP
    local message = "[PANIC] Emergency signal sent to security forces!"
    if ALLLANGUAGES.english and ALLLANGUAGES.english.VIP_PANIC then
        message = ALLLANGUAGES.english.VIP_PANIC.signal_sent
    end
    vipPlayer:PrintMessage(HUD_PRINTTALK, message)
    
    -- Send cooldown info to client
    net.Start("VIP_PanicCooldown")
        net.WriteFloat(vipPlayer.VIPPanicCooldown)
    net.Send(vipPlayer)
    
    -- Play sound for VIP
    vipPlayer:EmitSound("buttons/button09.wav", 75, 120)
end

-- Handle panic button press
net.Receive("VIP_PanicButtonPressed", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if ply:GetNClass() != ROLES.ROLE_VIP then return end
    if preparing or postround then 
        local message = "[PANIC] Cannot use panic button during this phase!"
        if ALLLANGUAGES.english and ALLLANGUAGES.english.VIP_PANIC then
            message = ALLLANGUAGES.english.VIP_PANIC.phase_blocked
        end
        ply:PrintMessage(HUD_PRINTTALK, message)
        return 
    end
    
    -- Check cooldown
    if not ply.VIPPanicCooldown then
        ply.VIPPanicCooldown = 0
    end
    
    if CurTime() < ply.VIPPanicCooldown then
        local timeLeft = math.ceil(ply.VIPPanicCooldown - CurTime())
        local message = "[PANIC] Cooldown: " .. timeLeft .. "s"
        if ALLLANGUAGES.english and ALLLANGUAGES.english.VIP_PANIC then
            message = string.format(ALLLANGUAGES.english.VIP_PANIC.cooldown_active, timeLeft)
        end
        ply:PrintMessage(HUD_PRINTTALK, message)
        return
    end
    
    -- Set cooldown
    ply.VIPPanicCooldown = CurTime() + VIP_PANIC_COOLDOWN
    
    -- Send panic alert
    local alertEndTime = CurTime() + VIP_PANIC_DURATION
    SendPanicAlert(ply, ply:GetPos(), alertEndTime)
    
    -- Log the panic button usage
    print("[VIP PANIC] " .. ply:Nick() .. " (" .. ply:SteamID() .. ") used panic button at " .. tostring(ply:GetPos()))
end)

-- Clean up expired alerts
timer.Create("VIP_CleanupPanicAlerts", 1, 0, function()
    for i = #ActivePanicAlerts, 1, -1 do
        if CurTime() > ActivePanicAlerts[i].endTime then
            table.remove(ActivePanicAlerts, i)
        end
    end
end)

-- Reset panic cooldowns on round restart
hook.Add("PostCleanupMap", "VIP_ResetPanicCooldowns", function()
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) then
            ply.VIPPanicCooldown = 0
        end
    end
    ActivePanicAlerts = {}
end)

-- Console command for admin testing
concommand.Add("br_vip_panic_test", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    
    -- Force trigger panic as admin
    ply.VIPPanicCooldown = 0
    local alertEndTime = CurTime() + VIP_PANIC_DURATION
    SendPanicAlert(ply, ply:GetPos(), alertEndTime)
    ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] VIP panic test activated!")
end) 