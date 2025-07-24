-- Jailbird Admin Commands for Breach
-- Server-side admin management for Jailbird weapon

if SERVER then
    -- Help command for Jailbird
    concommand.Add("breach_jailbird_help", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        ply:PrintMessage(HUD_PRINTTALK, "=== Jailbird Admin Commands ===")
        ply:PrintMessage(HUD_PRINTTALK, "breach_give_jailbird [player] - Give Jailbird to player")
        ply:PrintMessage(HUD_PRINTTALK, "breach_spawn_jailbird - Spawn Jailbird at crosshair")
        ply:PrintMessage(HUD_PRINTTALK, "breach_jailbird_cleanup [player] - Remove all Jailbird effects from player")
        ply:PrintMessage(HUD_PRINTTALK, "breach_jailbird_force_spawn - Force spawn Jailbird (100% chance)")
        ply:PrintMessage(HUD_PRINTTALK, "breach_jailbird_test_spawn - Test auto-spawn (normal 10% chance)")
        ply:PrintMessage(HUD_PRINTTALK, "breach_jailbird_info - Show Jailbird status information")
        ply:PrintMessage(HUD_PRINTTALK, "breach_jailbird_debug [player] - Debug player speeds and effects")
        ply:PrintMessage(HUD_PRINTTALK, "breach_jailbird_help - Show this help message")
    end)
    
    -- Give Jailbird to player
    concommand.Add("breach_give_jailbird", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local target = args[1]
        local targetPly = ply
        
        if target then
            targetPly = nil
            for _, p in pairs(player.GetAll()) do
                if string.find(string.lower(p:Nick()), string.lower(target)) then
                    targetPly = p
                    break
                end
            end
            
            if not targetPly then
                ply:PrintMessage(HUD_PRINTTALK, "Player not found!")
                return
            end
        end
        
        if IsValid(targetPly) then
            targetPly:Give("weapon_jailbird")
            ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] Gave Jailbird to " .. targetPly:Nick())
            print("[ADMIN] " .. ply:Nick() .. " gave Jailbird to " .. targetPly:Nick())
        end
    end)
    
    -- Spawn Jailbird entity
    concommand.Add("breach_spawn_jailbird", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local trace = ply:GetEyeTrace()
        local pos = trace.HitPos + trace.HitNormal * 5
        
        local jailbird = ents.Create("weapon_jailbird")
        if IsValid(jailbird) then
            jailbird:SetPos(pos)
            jailbird:Spawn()
            
            print("[ADMIN] " .. ply:Nick() .. " spawned Jailbird at " .. tostring(pos))
            ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] Jailbird spawned successfully!")
        end
    end)
    
    -- Check Jailbird status
    concommand.Add("breach_jailbird_info", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        ply:PrintMessage(HUD_PRINTTALK, "=== Jailbird Information ===")
        ply:PrintMessage(HUD_PRINTTALK, "Active Jailbird weapons: " .. #ents.FindByClass("weapon_jailbird"))
        
        local playersWithJailbird = 0
        for _, p in pairs(player.GetAll()) do
            if p:HasWeapon("weapon_jailbird") then
                playersWithJailbird = playersWithJailbird + 1
            end
        end
        
        ply:PrintMessage(HUD_PRINTTALK, "Players carrying Jailbird: " .. playersWithJailbird)
        ply:PrintMessage(HUD_PRINTTALK, "Auto-spawn location: Vector(3488.99, 1715.43, 0.03)")
        ply:PrintMessage(HUD_PRINTTALK, "Auto-spawn chance: 10% per round")
        ply:PrintMessage(HUD_PRINTTALK, "Models path: models/weapons/sweps/scpsl/jailbird/")
        ply:PrintMessage(HUD_PRINTTALK, "Sounds path: weapons/scpsl/jailbird/")
        
        -- Count stored speeds
        local storedSpeedsCount = 0
        for _, weapon in pairs(ents.FindByClass("weapon_jailbird")) do
            if IsValid(weapon) and weapon.OriginalSpeeds then
                for steamID, speeds in pairs(weapon.OriginalSpeeds) do
                    storedSpeedsCount = storedSpeedsCount + 1
                end
            end
        end
        ply:PrintMessage(HUD_PRINTTALK, "Players with stored speeds: " .. storedSpeedsCount)
    end)
    
    -- Debug command to check player speeds
    concommand.Add("breach_jailbird_debug", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local target = args[1] or ply:Nick()
        local targetPly = nil
        
        for _, p in pairs(player.GetAll()) do
            if string.find(string.lower(p:Nick()), string.lower(target)) then
                targetPly = p
                break
            end
        end
        
        if not targetPly then
            ply:PrintMessage(HUD_PRINTTALK, "Player not found!")
            return
        end
        
        local steamID = targetPly:SteamID64()
        
        ply:PrintMessage(HUD_PRINTTALK, "=== " .. targetPly:Nick() .. " Speed Debug ===")
        ply:PrintMessage(HUD_PRINTTALK, "Current Walk Speed: " .. targetPly:GetWalkSpeed())
        ply:PrintMessage(HUD_PRINTTALK, "Current Run Speed: " .. targetPly:GetRunSpeed())
        
        -- Check stored speeds
        local hasStoredSpeeds = false
        for _, weapon in pairs(ents.FindByClass("weapon_jailbird")) do
            if IsValid(weapon) and weapon.OriginalSpeeds and weapon.OriginalSpeeds[steamID] then
                ply:PrintMessage(HUD_PRINTTALK, "Stored Walk Speed: " .. weapon.OriginalSpeeds[steamID].walk)
                ply:PrintMessage(HUD_PRINTTALK, "Stored Run Speed: " .. weapon.OriginalSpeeds[steamID].run)
                hasStoredSpeeds = true
                break
            end
        end
        
        if not hasStoredSpeeds then
            ply:PrintMessage(HUD_PRINTTALK, "No stored speeds found")
        end
        
        -- Check active timers
        local activeTimers = {}
        if timer.Exists("JailbirdHaste_" .. targetPly:EntIndex()) then
            table.insert(activeTimers, "Haste")
        end
        if timer.Exists("JailbirdDischarge_" .. targetPly:EntIndex()) then
            table.insert(activeTimers, "Discharge")
        end
        if timer.Exists("JailbirdHindered_" .. targetPly:EntIndex()) then
            table.insert(activeTimers, "Hindered")
        end
        
        if #activeTimers > 0 then
            ply:PrintMessage(HUD_PRINTTALK, "Active effects: " .. table.concat(activeTimers, ", "))
        else
            ply:PrintMessage(HUD_PRINTTALK, "No active effects")
        end
    end)
    
    -- Clean up Jailbird effects for a player
    concommand.Add("breach_jailbird_cleanup", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local target = args[1] or ply:Nick()
        local targetPly = nil
        
        for _, p in pairs(player.GetAll()) do
            if string.find(string.lower(p:Nick()), string.lower(target)) then
                targetPly = p
                break
            end
        end
        
        if not targetPly then
            ply:PrintMessage(HUD_PRINTTALK, "Player not found!")
            return
        end
        
        local steamID = targetPly:SteamID64()
        
        -- Remove all Jailbird effects
        timer.Remove("JailbirdHaste_" .. targetPly:EntIndex())
        timer.Remove("JailbirdDischarge_" .. targetPly:EntIndex())
        timer.Remove("JailbirdHindered_" .. targetPly:EntIndex())
        
        -- Check for any Jailbird weapon and clean its speed storage
        local jailbirdWeapon = targetPly:GetWeapon("weapon_jailbird")
        if IsValid(jailbirdWeapon) and jailbirdWeapon.OriginalSpeeds then
            if jailbirdWeapon.OriginalSpeeds[steamID] then
                targetPly:SetWalkSpeed(jailbirdWeapon.OriginalSpeeds[steamID].walk)
                targetPly:SetRunSpeed(jailbirdWeapon.OriginalSpeeds[steamID].run)
                jailbirdWeapon.OriginalSpeeds[steamID] = nil
            else
                -- Fallback speed reset
                targetPly:SetWalkSpeed(100)
                targetPly:SetRunSpeed(400)
            end
        else
            -- No weapon found, use fallback
            targetPly:SetWalkSpeed(100)
            targetPly:SetRunSpeed(400)
        end
        
        ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] Cleaned up Jailbird effects for " .. targetPly:Nick())
        print("[ADMIN] " .. ply:Nick() .. " cleaned up Jailbird effects for " .. targetPly:Nick())
    end)
    
    -- Reset all Jailbird effects on round start
    hook.Add("BreachPreround", "JailbirdEffects_RoundReset", function()
        print("[Breach] Resetting all Jailbird effects for new round...")
        for _, ply in pairs(player.GetAll()) do
            if IsValid(ply) then
                local steamID = ply:SteamID64()
                
                -- Remove all Jailbird effect timers
                timer.Remove("JailbirdHaste_" .. ply:EntIndex())
                timer.Remove("JailbirdDischarge_" .. ply:EntIndex())
                timer.Remove("JailbirdHindered_" .. ply:EntIndex())
                
                -- Clean up stored speeds from any Jailbird weapons
                for _, weapon in pairs(ents.FindByClass("weapon_jailbird")) do
                    if IsValid(weapon) and weapon.OriginalSpeeds and weapon.OriginalSpeeds[steamID] then
                        ply:SetWalkSpeed(weapon.OriginalSpeeds[steamID].walk)
                        ply:SetRunSpeed(weapon.OriginalSpeeds[steamID].run)
                        weapon.OriginalSpeeds[steamID] = nil
                    end
                end
                
                -- Fallback reset (other systems will override if needed)
                if ply:GetWalkSpeed() == 0 or ply:GetRunSpeed() == 0 then
                    ply:SetWalkSpeed(100)
                    ply:SetRunSpeed(400)
                end
            end
        end
    end)
    
    -- Also reset on player spawn
    hook.Add("PlayerSpawn", "JailbirdEffects_PlayerSpawn", function(ply)
        if IsValid(ply) then
            local steamID = ply:SteamID64()
            
            timer.Remove("JailbirdHaste_" .. ply:EntIndex())
            timer.Remove("JailbirdDischarge_" .. ply:EntIndex())
            timer.Remove("JailbirdHindered_" .. ply:EntIndex())
            
            -- Clean up stored speeds
            for _, weapon in pairs(ents.FindByClass("weapon_jailbird")) do
                if IsValid(weapon) and weapon.OriginalSpeeds and weapon.OriginalSpeeds[steamID] then
                    weapon.OriginalSpeeds[steamID] = nil
                end
            end
        end
    end)
    
    -- Jailbird Auto-Spawn System
    function JailbirdAutoSpawn()
        local spawnPos = Vector(3488.990723, 1715.433716, 0.031250)
        local spawnAngles = Angle(0, 0, 0)
        
        -- 10% chance to spawn
        if math.random(100) <= 10 then
            -- Remove any existing Jailbirds first
            for _, ent in pairs(ents.FindByClass("weapon_jailbird")) do
                if ent:GetPos():Distance(spawnPos) < 100 then -- Within 100 units of spawn point
                    ent:Remove()
                end
            end
            
            -- Spawn new Jailbird
            local jailbird = ents.Create("weapon_jailbird")
            if IsValid(jailbird) then
                jailbird:SetPos(spawnPos)
                jailbird:SetAngles(spawnAngles)
                jailbird:Spawn()
                
                print("[Breach] Jailbird auto-spawned at " .. tostring(spawnPos) .. " (10% chance triggered)")
                return true
            end
        else
            print("[Breach] Jailbird auto-spawn skipped (90% chance)")
            return false
        end
    end
    
    -- Auto-spawn on round start
    hook.Add("PostCleanupMap", "JailbirdAutoSpawn", function()
        timer.Simple(2, function() -- Small delay to ensure map is fully loaded
            JailbirdAutoSpawn()
        end)
    end)
    
    -- Alternative hook for round restarts
    hook.Add("BreachPreround", "JailbirdAutoSpawn_Round", function()
        timer.Simple(2, function()
            JailbirdAutoSpawn()
        end)
    end)
    
    -- Force spawn command for testing
    concommand.Add("breach_jailbird_force_spawn", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local spawnPos = Vector(3488.990723, 1715.433716, 0.031250)
        local spawnAngles = Angle(0, 0, 0)
        
        -- Remove existing first
        for _, ent in pairs(ents.FindByClass("weapon_jailbird")) do
            if ent:GetPos():Distance(spawnPos) < 100 then
                ent:Remove()
            end
        end
        
        -- Force spawn (100% chance)
        local jailbird = ents.Create("weapon_jailbird")
        if IsValid(jailbird) then
            jailbird:SetPos(spawnPos)
            jailbird:SetAngles(spawnAngles)
            jailbird:Spawn()
            
            ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] Jailbird force spawned at " .. tostring(spawnPos))
            print("[ADMIN] " .. ply:Nick() .. " force spawned Jailbird at " .. tostring(spawnPos))
        end
    end)
    
    -- Test auto-spawn command (with normal 10% chance)
    concommand.Add("breach_jailbird_test_spawn", function(ply, cmd, args)
        if not ply:IsAdmin() then return end
        
        local success = JailbirdAutoSpawn()
        if success then
            ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] Jailbird auto-spawn test succeeded (10% chance)")
        else
            ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] Jailbird auto-spawn test failed (90% chance)")
        end
    end)
    
    print("[Breach] Jailbird admin commands and auto-spawn system loaded successfully!")
end 