-- SCP-1123 Server Module
-- Moduł serwerowy dla SCP-1123 "Skull of Memories"

-- Network strings
util.AddNetworkString("SCP1123_StartEffect")
util.AddNetworkString("SCP1123_EndEffect")

-- Admin commands
concommand.Add("br_spawn_scp1123", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsSuperAdmin() then return end
	
	local tr = ply:GetEyeTrace()
	if tr.Hit then
		local ent = ents.Create("scp_1123")
		if IsValid(ent) then
			ent:SetPos(tr.HitPos + tr.HitNormal * 5)
			ent:Spawn()
			ply:PrintMessage(HUD_PRINTTALK, "SCP-1123 spawned!")
		end
	end
end)

concommand.Add("br_remove_scp1123", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsSuperAdmin() then return end
	
	for _, ent in pairs(ents.FindByClass("scp_1123")) do
		if IsValid(ent) then
			ent:Remove()
		end
	end
	ply:PrintMessage(HUD_PRINTTALK, "All SCP-1123 entities removed!")
end)

-- Hook dla cleanup przy śmierci gracza
hook.Add("PlayerDeath", "SCP1123_CleanupOnDeath", function(victim, inflictor, attacker)
	if IsValid(victim) and victim:GetNWBool("SCP1123_InEffect", false) then
		-- Znajdź SCP-1123 entity i zakończ efekt
		for _, ent in pairs(ents.FindByClass("scp_1123")) do
			if IsValid(ent) then
				ent:EndSCP1123Effect(victim)
				break
			end
		end
	end
end)

-- Hook dla cleanup przy zmianie zespołu
hook.Add("OnPlayerChangedTeam", "SCP1123_CleanupOnTeamChange", function(ply, oldTeam, newTeam)
	if IsValid(ply) and ply:GetNWBool("SCP1123_InEffect", false) then
		-- Znajdź SCP-1123 entity i zakończ efekt
		for _, ent in pairs(ents.FindByClass("scp_1123")) do
			if IsValid(ent) then
				ent:EndSCP1123Effect(ply)
				break
			end
		end
	end
end)

print("[Breach] SCP-1123 Server Module Loaded") 