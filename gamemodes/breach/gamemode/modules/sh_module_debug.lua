-- Debug dla SCP-999 door passing
hook.Add("ShouldCollide", "SCP999_Debug", function(ent1, ent2)
	-- Sprawdź tylko dla graczy
	local ply, other
	if ent1:IsPlayer() then
		ply = ent1
		other = ent2
	elseif ent2:IsPlayer() then
		ply = ent2
		other = ent1
	else
		return
	end
	
	-- Jeśli gracz ma flagę SCP999Active
	if ply.SCP999Active then
		-- print("[SCP-999 DEBUG] Player " .. ply:Nick() .. " has SCP999Active flag")
		-- print("[SCP-999 DEBUG] Colliding with: " .. other:GetClass())
		
		-- Sprawdź czy obiekt ma flagę ignorecollide999
		if other.ignorecollide999 then
			-- print("[SCP-999 DEBUG] Entity has ignorecollide999 = true - WILL PASS THROUGH")
		else
			-- print("[SCP-999 DEBUG] Entity has ignorecollide999 = " .. tostring(other.ignorecollide999) .. " - WILL COLLIDE")
		end
		
		-- Dodatkowe info o typie obiektu
		local isDoor = other:GetClass() == "func_door" or
		               other:GetClass() == "func_door_rotating" or
		               other:GetClass() == "prop_door_rotating"
		local isPropDynamic = other:GetClass() == "prop_dynamic"
		
		if isDoor then
			-- print("[SCP-999 DEBUG] This is a door entity")
		elseif isPropDynamic then
			-- print("[SCP-999 DEBUG] This is a prop_dynamic (might be part of a door)")
		end
	end
end)

-- Debug dla sprawdzenia flagi
if SERVER then
	hook.Add("Think", "SCP999_FlagCheck", function()
		for _, ply in pairs(player.GetAll()) do
			if ply.SCP999Active then
				-- Wyświetl nad głową gracza
				debugoverlay.Text(ply:GetPos() + Vector(0, 0, 80), "SCP-999 ACTIVE", 0.1, false)
			end
		end
	end)
end