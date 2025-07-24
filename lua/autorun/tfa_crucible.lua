-- TFA Crucible Sound Register dla Breach
-- Rejestruje dźwięki broni Crucible

if SERVER then
	resource.AddFile("sound/weapons/tfa_kf2/crucible/shock_impact.wav")
	resource.AddFile("sound/weapons/tfa_kf2/crucible/WPN_LS_Equip_01.wav")
	resource.AddFile("sound/weapons/tfa_kf2/crucible/WPN_LS_UnEquip_01.wav")
	resource.AddFile("sound/weapons/tfa_kf2/crucible/wpn_ls_idle_01_lpm.wav")
end

-- Rejestracja dźwięków
sound.Add({
	name = "TFA_crucible.Swing",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 75,
	pitch = {95, 105},
	sound = {
		"weapons/tfa_kf2/crucible/wpn_ls_swing_01.wav",
		"weapons/tfa_kf2/crucible/wpn_ls_swing_02.wav",
		"weapons/tfa_kf2/crucible/wpn_ls_swing_03.wav"
	}
})

sound.Add({
	name = "TFA_crucible.HitFlesh",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 75,
	pitch = {95, 105},
	sound = {
		"weapons/tfa_kf2/crucible/wpn_ls_hit_flesh_01.wav",
		"weapons/tfa_kf2/crucible/wpn_ls_hit_flesh_02.wav",
		"weapons/tfa_kf2/crucible/wpn_ls_hit_flesh_03.wav"
	}
})

sound.Add({
	name = "TFA_crucible.HitWorld",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 75,
	pitch = {95, 105},
	sound = {
		"weapons/tfa_kf2/crucible/wpn_ls_hit_world_01.wav",
		"weapons/tfa_kf2/crucible/wpn_ls_hit_world_02.wav"
	}
})

-- Upewnij się że dźwięki są precache
if CLIENT then
	timer.Simple(1, function()
		util.PrecacheSound("TFA_crucible.Swing")
		util.PrecacheSound("TFA_crucible.HitFlesh")
		util.PrecacheSound("TFA_crucible.HitWorld")
		util.PrecacheSound("weapons/tfa_kf2/crucible/shock_impact.wav")
		util.PrecacheSound("weapons/tfa_kf2/crucible/WPN_LS_Equip_01.wav")
		util.PrecacheSound("weapons/tfa_kf2/crucible/WPN_LS_UnEquip_01.wav")
		util.PrecacheSound("weapons/tfa_kf2/crucible/wpn_ls_idle_01_lpm.wav")
	end)
end