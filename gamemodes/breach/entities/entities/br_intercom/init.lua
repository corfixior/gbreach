AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Global cooldown table for players
INTERCOM_COOLDOWNS = INTERCOM_COOLDOWNS or {}

function ENT:Initialize()
    self:SetModel("models/veeds/intercom/intercom.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end
    
    -- Intercom state variables
    self.InUse = false
    self.CurrentUser = nil
    self.UseStartTime = 0
    self.MaxUseTime = 30 -- 30 seconds max transmission time
    self.CooldownTime = 60 -- 60 seconds cooldown between uses
    
    print("[BREACH] Intercom spawned at position: " .. tostring(self:GetPos()))
end

function ENT:Use(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    -- Basic checks
    if ply:GTeam() == TEAM_SPEC then
        ply:PrintMessage(HUD_PRINTTALK, "[INTERCOM] Spectators cannot use the intercom!")
        return
    end
    
    if not ply:Alive() then
        ply:PrintMessage(HUD_PRINTTALK, "[INTERCOM] You must be alive to use the intercom!")
        return
    end
    
    if preparing then
        ply:PrintMessage(HUD_PRINTTALK, "[INTERCOM] The intercom is disabled during preparation phase!")
        return
    end
    
    -- Block SCP entities from using intercom
    if ply:GTeam() == TEAM_SCP then
        ply:PrintMessage(HUD_PRINTTALK, "[INTERCOM] SCP entities cannot use the facility intercom system!")
        return
    end
    
    -- Check player cooldown
    local steamid = ply:SteamID()
    if INTERCOM_COOLDOWNS[steamid] and INTERCOM_COOLDOWNS[steamid] > CurTime() then
        local remaining = math.ceil(INTERCOM_COOLDOWNS[steamid] - CurTime())
        ply:PrintMessage(HUD_PRINTTALK, "[INTERCOM] You must wait " .. remaining .. " seconds before using the intercom again!")
        return
    end
    
    -- Check if intercom is already in use
    if self.InUse then
        if self.CurrentUser == ply then
            -- Player wants to stop using intercom
            self:StopTransmission()
            return
        else
            ply:PrintMessage(HUD_PRINTTALK, "[INTERCOM] The intercom is currently being used by " .. (IsValid(self.CurrentUser) and self.CurrentUser:Nick() or "someone") .. "!")
            return
        end
    end
    
    -- Start transmission
    self:StartTransmission(ply)
end

function ENT:StartTransmission(ply)
    self.InUse = true
    self.CurrentUser = ply
    self.UseStartTime = CurTime()
    
    -- DON'T set cooldown here - only after transmission ends!
    
    -- Play activation sound
    self:EmitSound("buttons/button14.wav", 75, 100)
    
    -- Notify player
    ply:PrintMessage(HUD_PRINTTALK, "[INTERCOM] You are now broadcasting to the entire facility!")
    ply:PrintMessage(HUD_PRINTTALK, "[INTERCOM] Speak in chat OR use your microphone to transmit. Press E again to stop.")
    ply:PrintMessage(HUD_PRINTTALK, "[INTERCOM] Maximum transmission time: " .. self.MaxUseTime .. " seconds.")
    
    -- Broadcast start message to all players (WITHOUT showing class)
    for _, v in pairs(player.GetAll()) do
        if IsValid(v) and v:Alive() and v:GTeam() != TEAM_SPEC then
            v:PrintMessage(HUD_PRINTTALK, "[FACILITY INTERCOM] *** ANNOUNCEMENT SYSTEM ACTIVATED ***")
            v:PrintMessage(HUD_PRINTTALK, "[FACILITY INTERCOM] " .. ply:Nick() .. " is broadcasting:")
        end
    end
    
    -- Set up automatic timeout
    timer.Create("IntercomTimeout_" .. self:EntIndex(), self.MaxUseTime, 1, function()
        if IsValid(self) then
            self:StopTransmission(true)
        end
    end)
    
    print("[INTERCOM] " .. ply:Nick() .. " (" .. ply:GetNClass() .. ") started intercom transmission")
end

function ENT:StopTransmission(timeout)
    if not self.InUse then return end
    
    local user = self.CurrentUser
    
    -- Set cooldown NOW when transmission actually ends
    if IsValid(user) then
        INTERCOM_COOLDOWNS[user:SteamID()] = CurTime() + self.CooldownTime
    end
    
    -- Play deactivation sound
    self:EmitSound("buttons/button10.wav", 75, 120)
    
    -- Notify user
    if IsValid(user) then
        if timeout then
            user:PrintMessage(HUD_PRINTTALK, "[INTERCOM] Transmission ended - time limit reached!")
        else
            user:PrintMessage(HUD_PRINTTALK, "[INTERCOM] Transmission ended.")
        end
        
        -- Show cooldown info
        local remaining = math.ceil(self.CooldownTime)
        user:PrintMessage(HUD_PRINTTALK, "[INTERCOM] You can use the intercom again in " .. remaining .. " seconds.")
    end
    
    -- Broadcast end message to all players
    for _, v in pairs(player.GetAll()) do
        if IsValid(v) and v:Alive() and v:GTeam() != TEAM_SPEC then
            v:PrintMessage(HUD_PRINTTALK, "[FACILITY INTERCOM] *** TRANSMISSION ENDED ***")
        end
    end
    
    -- Reset state
    self.InUse = false
    self.CurrentUser = nil
    self.UseStartTime = 0
    
    -- Remove timeout timer
    timer.Remove("IntercomTimeout_" .. self:EntIndex())
    
    print("[INTERCOM] Transmission ended" .. (timeout and " (timeout)" or ""))
end

function ENT:Think()
    -- Check if current user is still valid and alive
    if self.InUse and IsValid(self.CurrentUser) then
        if not self.CurrentUser:Alive() or self.CurrentUser:GTeam() == TEAM_SPEC or self.CurrentUser:GTeam() == TEAM_SCP then
            self:StopTransmission()
        end
    end
    
    self:NextThink(CurTime() + 1)
    return true
end

function ENT:OnRemove()
    -- Clean up timer
    timer.Remove("IntercomTimeout_" .. self:EntIndex())
    
    -- If intercom was in use, stop transmission
    if self.InUse then
        self:StopTransmission()
    end
end

-- Hook to intercept chat messages from intercom users
hook.Add("PlayerSay", "IntercomBroadcast", function(ply, text, team)
    -- Find active intercom being used by this player
    for _, ent in pairs(ents.FindByClass("br_intercom")) do
        if IsValid(ent) and ent.InUse and ent.CurrentUser == ply then
            -- Broadcast message to entire facility
            for _, v in pairs(player.GetAll()) do
                if IsValid(v) and v:Alive() and v:GTeam() != TEAM_SPEC then
                    v:PrintMessage(HUD_PRINTTALK, "[FACILITY INTERCOM] " .. text)
                end
            end
            
            -- Play transmission sound
            ent:EmitSound("buttons/button17.wav", 75, 110)
            
            print("[INTERCOM BROADCAST] " .. ply:Nick() .. ": " .. text)
            
            -- Prevent normal chat message
            return ""
        end
    end
end)

-- Hook to make intercom users heard by everyone via voice chat
hook.Add("PlayerCanHearPlayersVoice", "IntercomVoiceBroadcast", function(listener, talker)
    -- Check if talker is using any intercom
    for _, ent in pairs(ents.FindByClass("br_intercom")) do
        if IsValid(ent) and ent.InUse and ent.CurrentUser == talker then
            -- Talker is using intercom - everyone can hear them
            if IsValid(listener) and listener:Alive() and listener:GTeam() != TEAM_SPEC then
                return true, true -- Can hear, and hear at full volume
            end
        end
    end
    
    -- Return nil to use default voice chat behavior
    return nil
end)

-- Hook when player starts speaking via voice chat while using intercom
hook.Add("PlayerStartVoice", "IntercomVoiceStart", function(ply)
    -- Check if player is using intercom
    for _, ent in pairs(ents.FindByClass("br_intercom")) do
        if IsValid(ent) and ent.InUse and ent.CurrentUser == ply then
            -- Notify all players that voice transmission started
            for _, v in pairs(player.GetAll()) do
                if IsValid(v) and v:Alive() and v:GTeam() != TEAM_SPEC then
                    v:PrintMessage(HUD_PRINTTALK, "[FACILITY INTERCOM] *** VOICE TRANSMISSION ACTIVE ***")
                end
            end
            
            -- Play transmission sound
            ent:EmitSound("buttons/button17.wav", 75, 110)
            break
        end
    end
end)

-- Hook when player stops speaking via voice chat while using intercom  
hook.Add("PlayerEndVoice", "IntercomVoiceEnd", function(ply)
    -- Check if player is using intercom
    for _, ent in pairs(ents.FindByClass("br_intercom")) do
        if IsValid(ent) and ent.InUse and ent.CurrentUser == ply then
            -- Small delay then notify voice transmission ended
            timer.Simple(0.5, function()
                for _, v in pairs(player.GetAll()) do
                    if IsValid(v) and v:Alive() and v:GTeam() != TEAM_SPEC then
                        v:PrintMessage(HUD_PRINTTALK, "[FACILITY INTERCOM] *** VOICE TRANSMISSION ENDED ***")
                    end
                end
            end)
            break
        end
    end
end)

-- Clean up cooldowns when player disconnects
hook.Add("PlayerDisconnected", "IntercomCleanupCooldowns", function(ply)
    if IsValid(ply) then
        INTERCOM_COOLDOWNS[ply:SteamID()] = nil
        
        -- If this player was using any intercom, stop transmission
        for _, ent in pairs(ents.FindByClass("br_intercom")) do
            if IsValid(ent) and ent.InUse and ent.CurrentUser == ply then
                ent:StopTransmission()
                break
            end
        end
    end
end) 