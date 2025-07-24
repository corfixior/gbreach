-- Syringe regeneration and poison system for Breach
DHPRegenList = DHPRegenList or {}
SyringePoisonList = SyringePoisonList or {}

-- Add ammo type for syringes
game.AddAmmoType({name = "Syringes", dmgtype = DMG_DIRECT})

-- Network strings for client communication
util.AddNetworkString("regen_hp")

-- Main regeneration think hook
hook.Add("Think", "SyringeHPRegen", function()
    -- Handle healing regeneration
    for target, value in pairs(DHPRegenList) do
        if value and IsValid(target) and target:Health() > 0 and target.DHPRegen then
            if target.LastDHPRegen <= CurTime() then
                target:SetHealth(math.min(target:Health() + 1, target:GetMaxHealth()))
                target.DHPRegen = target.DHPRegen - 1
                target.LastDHPRegen = CurTime() + 1
                
                if target:Health() >= target:GetMaxHealth() or target.DHPRegen == 0 then
                    target.DHPRegen = nil
                    target.LastDHPRegen = nil
                    DHPRegenList[target] = nil
                end

                if target:IsPlayer() then
                    net.Start("regen_hp")
                    net.WriteUInt(target.DHPRegen and target.DHPRegen or 0, 8)
                    net.Send(target)
                end
            end
        else
            if IsValid(target) then
                target.DHPRegen = nil
                target.LastDHPRegen = nil
            end
            DHPRegenList[target] = nil
        end
    end

    -- Handle poison damage
    for target, value in pairs(SyringePoisonList) do
        if value and IsValid(target) and target:Health() > 0 and target.SyringePoison then
            if target.SyringePoisonNext <= CurTime() then
                -- Deal poison damage
                local dmginfo = DamageInfo()
                dmginfo:SetDamage(1)
                dmginfo:SetAttacker(target.SyringePoisonAttacker or target)
                dmginfo:SetInflictor(target.SyringePoisonAttacker or target)
                dmginfo:SetDamageType(DMG_POISON)
                
                target:TakeDamageInfo(dmginfo)
                target.SyringePoisonNext = CurTime() + 2 -- Next tick in 2 seconds
                
                if target:IsPlayer() then
                    target:PrintMessage(HUD_PRINTCENTER, "Poison Effect (-1 HP)")
                end
            end
        else
            -- Clean up dead/invalid targets
            if IsValid(target) then
                target.SyringePoison = nil
                target.SyringePoisonNext = nil
                target.SyringePoisonAttacker = nil
            end
            SyringePoisonList[target] = nil
        end
    end
end)

-- Cancel regeneration when taking damage
hook.Add("PostEntityTakeDamage", "SyringeRegenDamage", function(ply, dmginfo, took)
    if IsValid(ply) and ply:IsPlayer() and ply.DHPRegen then
        local RegenLeft = math.max(0, ply.DHPRegen - dmginfo:GetDamage())

        if RegenLeft == 0 then
            ply.DHPRegen = nil
            ply.LastDHPRegen = nil
            DHPRegenList[ply] = nil
        else
            ply.DHPRegen = RegenLeft
            ply.LastDHPRegen = CurTime()
        end

        net.Start("regen_hp")
        net.WriteUInt(ply.DHPRegen and ply.DHPRegen or 0, 8)
        net.Send(ply)
    end
end)

-- Clean up poison on death
hook.Add("PlayerDeath", "CleanSyringePoison", function(victim, inflictor, attacker)
    if IsValid(victim) then
        victim.SyringePoison = nil
        victim.SyringePoisonNext = nil
        victim.SyringePoisonAttacker = nil
        SyringePoisonList[victim] = nil
    end
end)

-- Clean up on round restart
hook.Add("RoundRestart", "CleanSyringeEffects", function()
    DHPRegenList = {}
    SyringePoisonList = {}
    for k, v in pairs(player.GetAll()) do
        if IsValid(v) then
            v.DHPRegen = nil
            v.LastDHPRegen = nil
            v.SyringePoison = nil
            v.SyringePoisonNext = nil
            v.SyringePoisonAttacker = nil
        end
    end
end) 