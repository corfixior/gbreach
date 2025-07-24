sound.Add({
    name = "SCP3199scream",
    channel = CHAN_VOICE,
    volume = 1.0,
    level = 100,
    pitch = {95, 105},
    sound = "newenemy.wav"
})

sound.Add({
    name = "SCP3199Bite1",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 65,
    pitch = {95, 105},
    sound = "3199attack.wav"
})

sound.Add({
    name = "SCP3199Bite2",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 65,
    pitch = {95, 105},
    sound = "3199attack2.wav"
})

sound.Add({
    name = "SCP3199Bite3",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 65,
    pitch = {95, 105},
    sound = "3199attack3.wav"
})

sound.Add({
    name = "SCP3199Bite4",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 65,
    pitch = {95, 105},
    sound = "3199attack4.wav"
})

sound.Add({
    name = "SCP3199Corrosion",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 55,
    pitch = {95, 105},
    sound = "3199corrosion.wav"
})

sound.Add({
    name = "SCP3199Vomit",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 65,
    pitch = {95, 105},
    sound = "3199vomit.wav"
})

sound.Add({
    name = "SCP3199Death",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 75,
    pitch = {95, 105},
    sound = "eggspawn.wav"
})

PrecacheParticleSystem( "eml_generic_crsv" )
game.AddParticles( "particles/corrosion_fx.pcf" )
game.AddParticles( "particles/cryo_fx.pcf" )
game.AddParticles( "particles/ngen_fx.pcf" )

if SERVER then
    hook.Add("PlayerDeath", "3199DeathSound", function(ply, inflictor, attacker)
        if not IsValid(ply) then return end
    
        if ply:HasWeapon("weapon_scp_3199") then
            ply:EmitSound("SCP3199Death")
        end
    end)
end