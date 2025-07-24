-- Jarate system for Breach gamemode
-- Original by orange_blossom, integrated for Breach

-- ConVars for configuration
CreateConVar("blossomJarateDuration", 10, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Duration of Jarate effect in seconds")
CreateConVar("blossomJarateStrenght", 0.35, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Bonus damage multiplier, 0.01 = 1%")
CreateConVar("blossomJarateRange", 150, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Range of the Jarate explosion")
CreateConVar("blossomJarateThrow", 650, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Throwing strength")
CreateConVar("blossomJarateCount", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Number of jars given")

-- Add jarate ammo type
if !game.GetAmmoID("jarate") or game.GetAmmoID("jarate") == -1 then
    game.AddAmmoType({
        name = "jarate",
        dmgtype = DMG_GENERIC,
        tracer = TRACER_NONE,
        plydmg = 0,
        npcdmg = 0,
        force = 500,
        minsplash = 4,
        maxsplash = 8,
        maxcarry = 20,
    })
end

-- Jarate damage hook
hook.Add("EntityTakeDamage", "Breach_Jarate_DamageHook", function(target, dmginfo)
    if IsValid(target) and target.orange_blossom_pissed ~= nil and target.orange_blossom_pissed > CurTime() then
        -- Add bonus damage based on ConVar
        local bonus = dmginfo:GetDamage() * GetConVar("blossomJarateStrenght"):GetFloat()
        dmginfo:AddDamage(bonus)
        
        -- Play mini-crit sound effect if file exists
        if SERVER then
            local soundFile = "orange_blossom/piss/crit_hit_mini" .. tostring(math.random(1, 5)) .. ".wav"
            if file.Exists("sound/" .. soundFile, "GAME") then
                sound.Play(soundFile, target:GetPos(), 75, 100, 1)
            else
                -- Fallback sound
                target:EmitSound("player/crit_hit2.wav", 75, math.random(90, 110))
            end
        end
    end
end)

-- Admin menu for Breach (optional)
if SERVER then
    hook.Add("PopulateToolMenu", "Breach_Jarate_AdminMenu", function()
        spawnmenu.AddToolMenuOption("Utilities", "Breach Admin", "JarateSettings", "Jarate Settings", "", "", function(panel)
            panel:ClearControls()
            
            panel:AddControl("Label", {
                Text = "Configure Jarate settings for Breach gamemode"
            })
            
            panel:NumSlider("Effect Duration", "blossomJarateDuration", 1, 60, 0)
            panel:NumSlider("Bonus Damage %", "blossomJarateStrenght", 0, 2, 2)
            panel:NumSlider("Explosion Range", "blossomJarateRange", 10, 300, 0)
            panel:NumSlider("Throw Strength", "blossomJarateThrow", 100, 1500, 0)
            panel:NumSlider("Jars Amount", "blossomJarateCount", 1, 20, 0)
            
            local button = panel:Button("Reset to Default")
            button.DoClick = function()
                RunConsoleCommand("blossomJarateDuration", "10")
                RunConsoleCommand("blossomJarateStrenght", "0.35")
                RunConsoleCommand("blossomJarateRange", "150")
                RunConsoleCommand("blossomJarateThrow", "650")
                RunConsoleCommand("blossomJarateCount", "1")
            end
        end)
    end)
end

-- Cleanup on player spawn/death
hook.Add("PlayerSpawn", "Breach_Jarate_CleanupSpawn", function(ply)
    -- Clean up jarate effect on respawn
    if ply.orange_blossom_pissed then
        ply.orange_blossom_pissed = nil
        ply:SetColor(Color(255, 255, 255))
    end
end)

hook.Add("PostPlayerDeath", "Breach_Jarate_CleanupDeath", function(ply)
    -- Clean up jarate effect on death
    if ply.orange_blossom_pissed then
        ply.orange_blossom_pissed = nil
        ply:SetColor(Color(255, 255, 255))
    end
end) 