-- SAM Breach Integration
-- Ten plik powinien być umieszczony w folderze modułów gamemode'u Breach
-- aby załadować się po wszystkich funkcjach Breach

if not sam or not sam.command then
	print("[SAM Breach] SAM not found, skipping Breach integration")
	return
end

local sam, command, language = sam, sam.command, sam.language

print("[SAM Breach] Loading Breach integration for SAM...")

-- Sprawdź czy dane Breach są dostępne
if not ALLCLASSES or not SCPS then
	print("[SAM Breach] Breach data not available")
	return
end

command.set_category("SCP: Breach")

-- Definiuj niestandardowe argumenty
command.new_argument("breach_class")
	:OnExecute(function(arg, input, ply, _, result)
		if not ALLCLASSES then
			ply:sam_send_message("breach_classes_not_loaded")
			return false
		end
		
		-- Sprawdź czy klasa istnieje
		local found = false
		for _, group in pairs(ALLCLASSES) do
			for k, class in pairs(group.roles) do
				if class.name == input or class.name == ROLES["ROLE_"..input] then
					found = true
					break
				end
			end
			if found then break end
		end
		
		if not found then
			ply:sam_send_message("breach_invalid_class", {V = input})
			return false
		end
		
		table.insert(result, input)
	end)
	
	:Menu(function(set_result, body, buttons, arg)
		local default = arg.hint or "Select Class"
		
		local cbo = buttons:Add("SAM.ComboBox")
		cbo:SetValue(default)
		cbo:SetTall(25)
		
		function cbo:OnSelect(_, value)
			set_result(value)
			default = value
		end
		
		function cbo:DoClick()
			if self:IsMenuOpen() then
				return self:CloseMenu()
			end
			
			self:Clear()
			self:SetValue(default)
			
			if not ALLCLASSES then
				LocalPlayer():sam_send_message("breach_classes_not_loaded")
				return
			end
			
			-- Dodaj wszystkie klasy do dropdown w uporządkowany sposób
			local class_list = {}
			for _, group in pairs(ALLCLASSES) do
				for k, class in pairs(group.roles) do
					table.insert(class_list, class.name)
				end
			end
			
			table.sort(class_list)
			
			for _, class_name in pairs(class_list) do
				self:AddChoice(class_name)
			end
			
			self:OpenMenu()
		end
		
		return cbo
	end)
	
	:AutoComplete(function(arg, result, name)
		if not ALLCLASSES then return end
		
		name = name:lower()
		for _, group in pairs(ALLCLASSES) do
			for k, class in pairs(group.roles) do
				if class.name:lower():find(name, 1, true) then
					table.insert(result, class.name)
				end
			end
		end
	end)
:End()

command.new_argument("breach_scp")
	:OnExecute(function(arg, input, ply, _, result)
		if not SCPS then
			ply:sam_send_message("breach_scps_not_loaded")
			return false
		end
		
		-- Sprawdź czy SCP istnieje
		local found = false
		for _, scp_name in pairs(SCPS) do
			if scp_name == input then
				found = true
				break
			end
		end
		
		if not found then
			ply:sam_send_message("breach_invalid_scp", {V = input})
			return false
		end
		
		table.insert(result, input)
	end)
	
	:Menu(function(set_result, body, buttons, arg)
		local default = arg.hint or "Select SCP"
		
		local cbo = buttons:Add("SAM.ComboBox")
		cbo:SetValue(default)
		cbo:SetTall(25)
		
		function cbo:OnSelect(_, value)
			set_result(value)
			default = value
		end
		
		function cbo:DoClick()
			if self:IsMenuOpen() then
				return self:CloseMenu()
			end
			
			self:Clear()
			self:SetValue(default)
			
			if not SCPS then
				LocalPlayer():sam_send_message("breach_scps_not_loaded")
				return
			end
			
			-- Dodaj wszystkie SCP do dropdown w uporządkowany sposób
			local scp_list = table.Copy(SCPS)
			table.sort(scp_list)
			
			for _, scp_name in pairs(scp_list) do
				self:AddChoice(scp_name)
			end
			
			self:OpenMenu()
		end
		
		return cbo
	end)
	
	:AutoComplete(function(arg, result, name)
		if not SCPS then return end
		
		name = name:lower()
		for _, scp_name in pairs(SCPS) do
			if scp_name:lower():find(name, 1, true) then
				table.insert(result, scp_name)
			end
		end
	end)
:End()

-- Komenda force_spawn - Wymusza spawn gracza jako określona klasa
command.new("force_spawn")
	:SetPermission("breach_force_spawn", "superadmin")
	
	:AddArg("player")
	:AddArg("breach_class", {hint = "class name"})
	
	:Help("Forces player(s) to spawn as specific class")
	
	:OnExecute(function(ply, targets, class_name)
		if not class_name then return end
		
		-- Znajdź klasę w ALLCLASSES
		local cl, gr
		for _, group in pairs(ALLCLASSES) do
			gr = group.name
			for k, clas in pairs(group.roles) do
				if clas.name == class_name or clas.name == ROLES["ROLE_"..class_name] then
					cl = clas
					break
				end
			end
			if cl then break end
		end
		
		if cl and gr then
			local pos
			if gr == "Armed Site Support" then
				pos = SPAWN_OUTSIDE
			elseif gr == "Armed Site Security" then
				pos = SPAWN_GUARD
			elseif gr == "Unarmed Site Staff" then
				-- Special handling for Cook role
				if cl.name == ROLES.ROLE_COOK and SPAWN_COOK and #SPAWN_COOK > 0 then
					pos = SPAWN_COOK
				-- Special handling for Dr. House role
				elseif cl.name == ROLES.ROLE_DRHOUSE and SPAWN_DRHOUSE and #SPAWN_DRHOUSE > 0 then
					pos = SPAWN_DRHOUSE
				-- Special handling for Psychologist role
				elseif cl.name == ROLES.ROLE_PSYCHOLOGIST and SPAWN_PSYCHOLOGIST and #SPAWN_PSYCHOLOGIST > 0 then
					pos = SPAWN_PSYCHOLOGIST
				else
					pos = SPAWN_SCIENT
				end
			elseif gr == "Class D Personell" then
				pos = SPAWN_CLASSD
			end
			
			for k, v in pairs(targets) do
				-- Sprawdź czy gracz jest prawidłowy i aktywny
				if IsValid(v) and v:IsPlayer() then
					-- Sprawdź czy ma funkcję GetNActive (specyficzną dla Breach)
					local isActive = true
					if v.GetNActive then
						isActive = v:GetNActive()
					end
					
					if isActive then
						-- Sprawdź czy ma funkcje Breach
						if v.SetupNormal and v.ApplyRoleStats then
							v:SetupNormal()
							v:ApplyRoleStats(cl)
							if pos and #pos > 0 then
								v:SetPos(table.Random(pos))
							end
						else
							-- Fallback - podstawowy spawn
							v:Spawn()
							if pos and #pos > 0 then
								v:SetPos(table.Random(pos))
							end
						end
					else
						sam.player.send_message(ply, "breach_player_inactive", {
							T = v:Name()
						})
					end
				else
					sam.player.send_message(ply, "breach_invalid_target")
				end
			end
			
			sam.player.send_message(nil, "breach_force_spawn", {
				A = ply, T = targets, V = cl.name
			})
		else
			sam.player.send_message(ply, "breach_invalid_class", {
				V = class_name
			})
		end
	end)
:End()

-- Komenda force_scp - Wymusza spawn gracza jako SCP
command.new("force_scp")
	:SetPermission("breach_force_scp", "superadmin")
	
	:AddArg("player", {single_target = true})
	:AddArg("breach_scp", {hint = "SCP name"})
	
	:Help("Forces player to spawn as specific SCP")
	
	:OnExecute(function(ply, targets, scp_name)
		local target = targets[1]
		
		-- Sprawdź czy gracz jest prawidłowy
		if not IsValid(target) or not target:IsPlayer() then
			sam.player.send_message(ply, "breach_invalid_target")
			return
		end
		
		-- Sprawdź czy gracz jest aktywny (jeśli ma funkcję GetNActive)
		local isActive = true
		if target.GetNActive then
			isActive = target:GetNActive()
		end
		
		if not isActive then
			sam.player.send_message(ply, "breach_player_inactive", {
				T = target:Name()
			})
			return
		end
		
		-- Sprawdź czy funkcja GetSCP istnieje
		if not GetSCP then
			sam.player.send_message(ply, "breach_scps_not_loaded")
			return
		end
		
		local scp_obj = GetSCP(scp_name)
		if scp_obj and scp_obj.SetupPlayer then
			scp_obj:SetupPlayer(target)
			
			sam.player.send_message(nil, "breach_force_scp", {
				A = ply, T = target:Name(), V = scp_name
			})
		else
			sam.player.send_message(ply, "breach_invalid_scp", {
				V = scp_name
			})
		end
	end)
:End()

-- Komenda restart_round - Restartuje rundę
command.new("restart_round")
	:SetPermission("breach_restart_round", "superadmin")
	
	:Help("Restarts current round")
	
	:OnExecute(function(ply)
		if not RoundRestart then
			sam.player.send_message(ply, "breach_function_not_available", {
				V = "RoundRestart"
			})
			return
		end
		
		RoundRestart()
		
		sam.player.send_message(nil, "breach_restart_round", {
			A = ply
		})
	end)
:End()

-- Komenda admin_mode - Przełącza tryb administratora
command.new("admin_mode")
	:SetPermission("breach_admin_mode", "admin")
	
	:Help("Toggles admin mode for next round")
	
	:OnExecute(function(ply)
		if not ply.ToggleAdminModePref then
			sam.player.send_message(ply, "breach_function_not_available", {
				V = "ToggleAdminModePref"
			})
			return
		end
		
		ply:ToggleAdminModePref()
		
		if ply.admpref then
			if ply.AdminMode then
				sam.player.send_message(nil, "breach_admin_mode_entered", {
					A = ply
				})
			else
				sam.player.send_message(nil, "breach_admin_mode_next", {
					A = ply
				})
			end
		else
			sam.player.send_message(nil, "breach_admin_mode_disabled", {
				A = ply
			})
		end
	end)
:End()

-- Komenda request_ntf - Spawnuje jednostki wsparcia
command.new("request_ntf")
	:SetPermission("breach_request_ntf", "superadmin")
	
	:Help("Spawns support units (NTF/GOC/Chaos)")
	
	:OnExecute(function(ply)
		-- Sprawdź czy funkcje spawn istnieją
		if not SpawnNTFS then
			sam.player.send_message(ply, "breach_function_not_available", {
				V = "SpawnNTFS"
			})
			return
		end
		
		-- Losowanie z właściwymi proporcjami: NTF 50%, GOC 10%, Chaos 40%
		local rand = math.random(1, 100)
		if rand <= 50 then
			-- 50% szans dla NTF
			SpawnNTFS()
		elseif rand <= 60 and SpawnGOC then
			-- 10% szans dla GOC (51-60)
			SpawnGOC()
		else
			-- 40% szans dla Chaos (61-100)
			SpawnNTFS(true) -- Wymusza spawn Chaos
		end
		
		sam.player.send_message(nil, "breach_request_ntf", {
			A = ply
		})
	end)
:End()

-- Komenda tsay - Wyświetla kolorową wiadomość wszystkim graczom
command.new("tsay")
	:SetPermission("breach_tsay", "admin")
	
	:AddArg("text", {hint = "message"})
	
	:GetRestArgs()
	:Help("Displays a colored message to all players")
	
	:OnExecute(function(ply, message)
		-- Wyślij tylko kolorową wiadomość (bez standardowej)
		if sam.netstream then
			sam.netstream.Start(nil, "breach_tsay_display", {
				message = message,
				admin = ply:Name()
			})
		else
			-- Fallback jeśli netstream nie działa
			for _, v in pairs(player.GetAll()) do
				if IsValid(v) then
					v:PrintMessage(HUD_PRINTCENTER, "[ADMIN] " .. message)
				end
			end
		end
		
		sam.player.send_message(nil, "breach_tsay", {
			A = ply, V = message
		})
	end)
:End()

-- Komenda getpos - Pobiera pozycję gracza
command.new("getpos")
	:SetPermission("breach_getpos", "admin")
	
	:AddArg("player", {single_target = true, optional = true})
	
	:Help("Gets player position coordinates")
	
	:OnExecute(function(ply, targets)
		local target = targets and targets[1] or ply
		
		if not IsValid(target) then
			sam.player.send_message(ply, "breach_invalid_target")
			return
		end
		
		local pos = target:GetPos()
		local ang = target:GetAngles()
		
		local posString = string.format("%.2f %.2f %.2f", pos.x, pos.y, pos.z)
		local angString = string.format("%.2f %.2f %.2f", ang.p, ang.y, ang.r)
		
		sam.player.send_message(ply, "breach_getpos", {
			T = target:Name(), V = posString, V_2 = angString
		})
	end)
:End()

-- Komenda bot - Dodaje boty do serwera
command.new("bot")
	:SetPermission("breach_bot", "admin")
	
	:AddArg("number", {hint = "amount", min = 1, max = 32, default = 1})
	
	:Help("Adds bots to the server")
	
	:OnExecute(function(ply, amount)
		amount = math.Clamp(amount, 1, 32)
		
		for i = 1, amount do
			RunConsoleCommand("bot")
		end
		
		sam.player.send_message(nil, "breach_bot_add", {
			A = ply, V = amount
		})
	end)
:End()

-- Komenda kickbot - Usuwa wszystkie boty
command.new("kickbot")
	:SetPermission("breach_kickbot", "admin")
	
	:Help("Kicks all bots from the server")
	
	:OnExecute(function(ply)
		local botCount = 0
		for _, v in pairs(player.GetAll()) do
			if v:IsBot() then
				v:Kick("Kicked by admin")
				botCount = botCount + 1
			end
		end
		
		sam.player.send_message(nil, "breach_kickbot", {
			A = ply, V = botCount
		})
	end)
:End()

-- Komenda recheck_premium - Przeładowuje status premium graczy
command.new("recheck_premium")
	:SetPermission("breach_recheck_premium", "admin")
	
	:Help("Reloads all players premium status")
	
	:OnExecute(function(ply)
		-- Sprawdź czy funkcja IsPremium istnieje
		if not IsPremium then
			sam.player.send_message(ply, "breach_function_not_available", {
				V = "IsPremium"
			})
			return
		end
		
		for k, v in pairs(player.GetAll()) do
			if IsValid(v) and v:IsPlayer() then
				IsPremium(v, true)
			end
		end
		
		sam.player.send_message(nil, "breach_recheck_premium", {
			A = ply
		})
	end)
:End()

-- Komenda punish_cancel - Anuluje ostatnie głosowanie karania
command.new("punish_cancel")
	:SetPermission("breach_punish_cancel", "admin")
	
	:Help("Cancels last punish vote")
	
	:OnExecute(function(ply)
		-- Sprawdź czy funkcja CancelVote istnieje
		if not CancelVote then
			sam.player.send_message(ply, "breach_function_not_available", {
				V = "CancelVote"
			})
			return
		end
		
		CancelVote()
		
		sam.player.send_message(nil, "breach_punish_cancel", {
			A = ply
		})
	end)
:End()

-- Komenda clear_stats - Czyści statystyki gracza
command.new("clear_stats")
	:SetPermission("breach_clear_stats", "superadmin")
	
	:AddArg("player", {single_target = true})
	:AddArg("text", {hint = "SteamID64", optional = true})
	
	:Help("Clears player data by name or SteamID64")
	
	:OnExecute(function(ply, targets, steamid)
		local target = targets[1]
		
		if ply == target and steamid and steamid ~= "" then
			if steamid == "&ALL" then
				sam.player.send_message(ply, "breach_clear_all_error")
				return
			end
			
			if IsValidSteamID and IsValidSteamID(steamid) then
				if clearDataID then
					clearDataID(steamid)
					sam.player.send_message(nil, "breach_clear_stats_id", {
						A = ply, V = steamid
					})
				else
					sam.player.send_message(ply, "breach_function_not_available", {
						V = "clearDataID"
					})
				end
			else
				sam.player.send_message(ply, "breach_invalid_steamid")
			end
			return
		end
		
		if clearData then
			clearData(target)
			sam.player.send_message(nil, "breach_clear_stats", {
				A = ply, T = target:Name()
			})
		else
			sam.player.send_message(ply, "breach_function_not_available", {
				V = "clearData"
			})
		end
	end)
:End()

-- Komenda restart_game - Restartuje grę
command.new("restart_game")
	:SetPermission("breach_restart_game", "superadmin")
	
	:Help("Restarts the game")
	
	:OnExecute(function(ply)
		if not RestartGame then
			sam.player.send_message(ply, "breach_function_not_available", {
				V = "RestartGame"
			})
			return
		end
		
		RestartGame()
		
		sam.player.send_message(nil, "breach_restart_game", {
			A = ply
		})
	end)
:End()

-- Komenda destroy_gate_a - Niszczy Bramę A
command.new("destroy_gate_a")
	:SetPermission("breach_destroy_gate_a", "admin")
	
	:Help("Destroys Gate A")
	
	:OnExecute(function(ply)
		if not explodeGateA then
			sam.player.send_message(ply, "breach_function_not_available", {
				V = "explodeGateA"
			})
			return
		end
		
		explodeGateA()
		
		sam.player.send_message(nil, "breach_destroy_gate_a", {
			A = ply
		})
	end)
:End()

-- Komenda setlvl - Ustawia poziom gracza
command.new("setlvl")
	:SetPermission("breach_setlvl", "superadmin")
	
	:AddArg("player", {single_target = true})
	:AddArg("number", {hint = "level", min = 0, max = 100})
	
	:Help("Sets player level")
	
	:OnExecute(function(ply, targets, level)
		local target = targets[1]
		
		if not IsValid(target) then
			sam.player.send_message(ply, "breach_invalid_target")
			return
		end
		
		-- Sprawdź czy gracz ma funkcje poziomu
		if not target.SetNLevel then
			sam.player.send_message(ply, "breach_level_not_supported")
			return
		end
		
		level = math.Clamp(level, 0, 100)
		
		target:SetNLevel(level)
		if target.SetPData then
			target:SetPData("breach_level", level)
		end
		if target.SaveLevel then
			target:SaveLevel()
		end
		
		sam.player.send_message(nil, "breach_setlvl", {
			A = ply, T = target:Name(), V = level
		})
	end)
:End()

-- Komenda addlvl - Dodaje poziomy graczowi
command.new("addlvl")
	:SetPermission("breach_addlvl", "superadmin")
	
	:AddArg("player", {single_target = true})
	:AddArg("number", {hint = "levels", min = 1, max = 50})
	
	:Help("Adds levels to player")
	
	:OnExecute(function(ply, targets, levels)
		local target = targets[1]
		
		if not IsValid(target) then
			sam.player.send_message(ply, "breach_invalid_target")
			return
		end
		
		-- Sprawdź czy gracz ma funkcje poziomu
		if not target.GetLevel or not target.SetNLevel then
			sam.player.send_message(ply, "breach_level_not_supported")
			return
		end
		
		levels = math.Clamp(levels, 1, 50)
		local currentLevel = target:GetLevel()
		local newLevel = math.Clamp(currentLevel + levels, 0, 100)
		
		target:SetNLevel(newLevel)
		if target.SetPData then
			target:SetPData("breach_level", newLevel)
		end
		if target.SaveLevel then
			target:SaveLevel()
		end
		
		sam.player.send_message(nil, "breach_addlvl", {
			A = ply, T = target:Name(), V = levels, V_2 = newLevel
		})
	end)
:End()

-- Komenda addexp - Dodaje doświadczenie graczowi
command.new("addexp")
	:SetPermission("breach_addexp", "admin")
	
	:AddArg("player", {single_target = true})
	:AddArg("number", {hint = "experience", min = 1, max = 10000})
	
	:Help("Adds experience to player")
	
	:OnExecute(function(ply, targets, exp)
		local target = targets[1]
		
		if not IsValid(target) then
			sam.player.send_message(ply, "breach_invalid_target")
			return
		end
		
		-- Sprawdź czy gracz ma funkcje doświadczenia
		if not target.AddExp then
			sam.player.send_message(ply, "breach_exp_not_supported")
			return
		end
		
		exp = math.Clamp(exp, 1, 10000)
		
		target:AddExp(exp, true)
		
		sam.player.send_message(nil, "breach_addexp", {
			A = ply, T = target:Name(), V = exp
		})
	end)
:End()

print("[SAM Breach] Successfully loaded " .. 18 .. " commands")