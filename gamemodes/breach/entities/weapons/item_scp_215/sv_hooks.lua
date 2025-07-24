-- Hooki serwerowe dla SCP-215
if SERVER then
	-- Hook serwerowy dla czyszczenia po śmierci gracza
	hook.Add("PlayerDeath", "SCP215_CleanupOnDeath", function(victim, inflictor, attacker)
		if IsValid(victim) and victim:HasWeapon("item_scp_215") then
			-- Wyczyść network variables
			victim:SetNWBool("SCP215_Active", false)
		end
	end)
	
	-- Hook dla disconnectu gracza
	hook.Add("PlayerDisconnected", "SCP215_CleanupOnDisconnect", function(ply)
		if IsValid(ply) then
			-- Wyczyść network variables
			ply:SetNWBool("SCP215_Active", false)
		end
	end)
	
	-- Hook dla wyrzucenia okularów
	hook.Add("PlayerDroppedWeapon", "SCP215_HandleDrop", function(ply, wep)
		if not IsValid(ply) or not IsValid(wep) then return end

		if wep:GetClass() ~= "item_scp_215" then return end

		if ply:GetNWBool("SCP215_Active", false) then
			-- Wyłącz wykrywanie
			ply:SetNWBool("SCP215_Active", false)
		end
	end)
	
	-- Hook dla rozpoczęcia rundy (wyczyść wszystkie stany)
	hook.Add("RoundStart", "SCP215_RoundCleanup", function()
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) then
				ply:SetNWBool("SCP215_Active", false)
			end
		end
	end)
end