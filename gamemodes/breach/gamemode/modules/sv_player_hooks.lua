// Serverside file for all player related functions

-- Network string dla powiadomień o zabójstwach
util.AddNetworkString("KillNotification")

-- Funkcja wysyłająca powiadomienie o zabójstwie
local function SendKillNotification(attacker, victimClass, victimName, points, isTeamkill)
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	
	net.Start("KillNotification")
		net.WriteInt(victimClass, 8)
		net.WriteString(victimName)
		net.WriteInt(points, 16)
		net.WriteBool(isTeamkill or false)
	net.Send(attacker)
end

function IsPremium( ply, silent )
	ply:SetNPremium( false )
	ply.Premium = false
	if CheckULXPremium( ply, silent ) == true then return end
	if GetConVar("br_premium_url"):GetString() == "" or GetConVar("br_premium_url"):GetString() == "none" then return end
	http.Fetch( GetConVar("br_premium_url"):GetString(), function( body, size, headers, code )
		if ( body == nil ) then return end
		local ID = string.find( tostring(body), "<ID64>"..ply:SteamID64().."</ID64>" )
			if ID != nil then
				ply.Premium = true
				ply:SetNPremium( true )
				if GetConVar("br_premium_display"):GetString() != "" and GetConVar("br_premium_display"):GetString() != "none" and !silent then
					print("Premium member "..ply:GetName().." has joined")
					PrintMessage(HUD_PRINTCENTER, string.format(GetConVar("br_premium_display"):GetString(), ply:GetName()))
				end
			end
	end,
	function( error )
		print("HTTP ERROR")
		print(error)
	end )
end

function CheckULXPremium( ply, silent )
	if GetConVar("br_ulx_premiumgroup_name"):GetString() == "" or GetConVar("br_ulx_premiumgroup_name"):GetString() == "none" then return end
	if !ply.CheckGroup then
		print( "To use br_ulx_premiumgroup_name you have to install ULX!" )
		return
	end
	local pgroups = string.Split( GetConVar("br_ulx_premiumgroup_name"):GetString(), "," )
	local ispremium
	for k,v in pairs( pgroups ) do
		if ply:CheckGroup( v ) then
			ispremium = true
			break
		end
	end
	if ispremium then
		ply.Premium = true
		ply:SetNPremium( true )
		if GetConVar("br_premium_display"):GetString() != "" and GetConVar("br_premium_display"):GetString() != "none" and !silent then
			print("Premium member "..ply:GetName().." has joined")
			PrintMessage(HUD_PRINTCENTER, string.format(GetConVar("br_premium_display"):GetString(), ply:GetName()))
		end
		return true
	end
end

local roundStartInProgress = false

function CheckStart()
	MINPLAYERS = GetConVar("br_min_players"):GetInt()
	
	-- Zapobiegaj wielokrotnemu uruchamianiu rundy
	if roundStartInProgress then return end
	
	if gamestarted == false and #GetActivePlayers() >= MINPLAYERS then
		print("[BREACH] CheckStart: Wystarczająca liczba graczy, rozpoczynanie rundy...")
		roundStartInProgress = true
		-- Dodaj małe opóźnienie dla pierwszej rundy
		timer.Simple(0.5, function()
			RoundRestart()
			roundStartInProgress = false
		end)
	end
	if gamestarted then
		BroadcastLua( 'gamestarted = true' )
	end
end

function GM:PlayerInitialSpawn( ply )
	ply:SetCanZoom( false )
	ply:SetNoDraw(true)
	ply.Active = false
	ply.freshspawn = true
	ply.isblinking = false
	ply.Premium = false
	if timer.Exists( "RoundTime" ) == true then
		net.Start("UpdateTime")
			net.WriteString(tostring(timer.TimeLeft( "RoundTime" )))
		net.Send(ply)
	end
	player_manager.SetPlayerClass( ply, "class_breach" )
	player_manager.RunClass( ply, "SetupDataTables" )
	IsPremium(ply)
	
	-- Napraw problem z przezroczystością na scoreboardzie
	-- Ustaw ActivePlayer przed SetActive, żeby uniknąć problemów z synchronizacją
	ply.ActivePlayer = false
	ply:SetActive( false )
	if ply:IsBot() then
		ply.ActivePlayer = true
		ply:SetActive( true )
	end
	
	-- Wymuś synchronizację zmiennej sieciowej
	timer.Simple(0.1, function()
		if IsValid(ply) then
			ply:SetNActive(ply.ActivePlayer or false)
		end
	end)
	
	--print( ply.ActivePlayer, ply:GetNActive() )
	CheckStart()
	if gamestarted then
		ply:SendLua( 'gamestarted = true' )
	end
end
/*
function GM:PlayerAuthed( ply, steamid, uniqueid )
	ply.Active = false
	ply.Leaver = "none"
	if prepring then
		ply:SetClassD()
	else
		ply:SetSpectator()
	end
end
*/
function GM:PlayerSpawn( ply )
	//ply:SetupHands()
	ply:SetTeam(1)
	ply:SetNoCollideWithTeammates(true)
	//ply:SetCustomCollisionCheck( true )
	if ply.freshspawn then
		ply:SetSpectator()
		ply.freshspawn = false
	end
	
	-- RESET manipulacji kości przy spawnie - naprawia problem z Fat D i Skinny D
	timer.Simple(0.05, function()
		if IsValid(ply) then
			ply:SetModelScale(1.0, 0)
			-- Reset wszystkich manipulacji kości do wartości domyślnych
			for i = 0, ply:GetBoneCount() - 1 do
				ply:ManipulateBoneScale(i, Vector(1, 1, 1))
				ply:ManipulateBonePosition(i, Vector(0, 0, 0))
				ply:ManipulateBoneAngles(i, Angle(0, 0, 0))
			end
		end
	end)
	
	//ply:SetupHands()
end

function GM:PlayerSetHandsModel( ply, ent )
	local simplemodel = player_manager.TranslateToPlayerModelName( ply:GetModel() )
	local info = player_manager.TranslatePlayerHands( simplemodel )
	if ( info ) then
		if ply.handsmodel != nil then
			info.model = ply.handsmodel
		end
		ent:SetModel( info.model )
		ent:SetSkin( info.skin )
		ent:SetBodyGroups( info.body )
	end
end

function GM:DoPlayerDeath( ply, attacker, dmginfo )
	if (ply.noragdoll != true) then
		CreateRagdollPL(ply, attacker, dmginfo:GetDamageType())
	end
	ply:AddDeaths(1)
end


function GM:PlayerDeathThink( ply )
	if ply:GetNClass() == ROLES.ROLE_SCP076 and IsValid( SCP0761 ) then
		if ply.n076nextspawn and ply.n076nextspawn < CurTime() then
			--ply:SetSCP076()
			local scp = GetSCP( "SCP076" )
			if scp then
				scp:SetupPlayer( ply )
			end
		end
		return
	end
	if !ply:IsBot() and ply:GTeam() != TEAM_SPEC then
		ply:SetGTeam(TEAM_SPEC)
	end
	if ( ply:IsBot() || ply:KeyPressed( IN_ATTACK ) || ply:KeyPressed( IN_ATTACK2 ) || ply:KeyPressed( IN_JUMP ) || postround ) then
		ply:Spawn()
		ply:SetSpectator()
	end
end

function GM:PlayerNoClip( ply, desiredState )
	if ply:GTeam() == TEAM_SPEC and desiredState == true then return true end
end

function GM:PlayerDeath( victim, inflictor, attacker )
	net.Start( "Effect" )
		net.WriteBool( false )
	net.Send( victim )

	net.Start( "957Effect" )
		net.WriteBool( false )
	net.Send( victim )

	victim:SetModelScale( 1 )
	if attacker:IsPlayer() then
		print("[KILL] " .. attacker:Nick() .. " [" .. attacker:GetNClass() .. "] killed " .. victim:Nick() .. " [" .. victim:GetNClass() .. "]")
	end
	
	-- SYSTEM KREDYTÓW ZA ZABÓJSTWA
	if IsValid(attacker) and attacker:IsPlayer() and IsValid(victim) and victim:IsPlayer() and attacker != victim and not preparing and not postround then
		-- Inicjalizuj kredyty jeśli nie istnieją
		if not attacker.Credits then attacker.Credits = 0 end
		if not attacker.RoundKills then attacker.RoundKills = 0 end
		if not attacker.TeamKills then attacker.TeamKills = 0 end
		
		local attackerTeam = attacker:GTeam()
		local victimTeam = victim:GTeam()
		
		-- Stała nagroda za zabójstwo przeciwnika
		local KILL_REWARD = 1  -- 1 kredyt za każde zabójstwo przeciwnika
		
		-- Sprawdź czy to zabójstwo przeciwnika
		local isEnemyKill = false
		local creditsReward = 0
		
		if attackerTeam != victimTeam then
			-- Różne drużyny - sprawdź czy to nie są sojusznicy
			local isAlly = ((attackerTeam == TEAM_GUARD and victimTeam == TEAM_SCI) or 
							(attackerTeam == TEAM_SCI and victimTeam == TEAM_GUARD) or
							(attackerTeam == TEAM_CLASSD and victimTeam == TEAM_CHAOS) or
							(attackerTeam == TEAM_CHAOS and victimTeam == TEAM_CLASSD))
			
			if not isAlly then
				isEnemyKill = true
				creditsReward = KILL_REWARD
				
				-- Sprawdź czy to nie SCP-999 (nie nagradzaj za jego zabicie)
				local victimClass = victim:GetNClass()
				if victimClass == ROLES.ROLE_SCP999 then
					creditsReward = 0 -- Nie nagradzaj za zabicie SCP-999
				end
			end
		end
		
		if isEnemyKill and creditsReward > 0 then
			-- Dodaj kredyty za zabójstwo przeciwnika
			attacker.RoundKills = attacker.RoundKills + 1
			attacker:AddCredits(creditsReward, "Killed " .. victim:Nick() .. " (+" .. creditsReward .. " credits)")
			print("[CREDITS] " .. attacker:Nick() .. " earned " .. creditsReward .. " credits for killing " .. victim:Nick() .. " (" .. attacker:GetCredits() .. " total)")
		elseif attackerTeam == victimTeam or 
			   (attackerTeam == TEAM_GUARD and victimTeam == TEAM_SCI) or
			   (attackerTeam == TEAM_SCI and victimTeam == TEAM_GUARD) or
			   (attackerTeam == TEAM_CLASSD and victimTeam == TEAM_CHAOS) or
			   (attackerTeam == TEAM_CHAOS and victimTeam == TEAM_CLASSD) then
			-- Teamkill - kara
			attacker.TeamKills = attacker.TeamKills + 1
			attacker:AddCredits(-10, "Teamkill penalty (-10 credits)")
			print("[CREDITS] " .. attacker:Nick() .. " lost 10 credits for teamkill (" .. attacker:GetCredits() .. " total)")
		end
	end
	
	-- Specjalna kara za zabicie SCP-999
	if attacker:IsPlayer() and attacker != victim and victim:GetNClass() == ROLES.ROLE_SCP999 then
		attacker:AddFrags(-10)
		SendKillNotification(attacker, TEAM_SCP, victim:Nick(), -10, false)
		print("[" .. attacker:Nick() .. "] killed SCP-999! -10 points penalty!")
	end
	if victim:GetNClass() == ROLES.ROLE_SCP9571 then
		for k, v in pairs( player.GetAll() ) do
			if v:GetNClass() == ROLES.ROLE_SCP957 then
				v:TakeDamage( 500, attacker, inflictor)
			end
		end
	end
	if victim:GetNClass() == ROLES.ROLE_SCP076 and IsValid( SCP0761 ) and !postround then
		victim.n076nextspawn = CurTime() + 10
		return
	end
	victim:SetNClass(ROLES.ROLE_SPEC)
	if attacker != victim and postround == false and attacker:IsPlayer() then
		if attacker:IsPlayer() then
			if attacker:GTeam() == TEAM_GUARD then
				victim:PrintMessage(HUD_PRINTTALK, "You were killed by an MTF Guard: " .. attacker:Nick())
				if victim:GTeam() == TEAM_SCP then
					-- Nie dawaj punktów za zabicie SCP-999 (już obsłużone wcześniej)
					if victim:GetNClass() != ROLES.ROLE_SCP999 then
						print("[" .. attacker:Nick() .. "] You've been awarded with 10 points for killing an SCP!")
						attacker:AddFrags(10)
						SendKillNotification(attacker, TEAM_SCP, victim:Nick(), 10, false)
					end
				elseif victim:GTeam() == TEAM_CHAOS then
					print("[" .. attacker:Nick() .. "] You've been awarded with 5 points for killing a Chaos Insurgency member!")
					attacker:AddFrags(5)
					SendKillNotification(attacker, TEAM_CHAOS, victim:Nick(), 5, false)
				elseif victim:GTeam() == TEAM_CLASSD then
					print("[" .. attacker:Nick() .. "] You've been awarded with 2 points for killing a Class D Personell!")
					attacker:AddFrags(2)
					SendKillNotification(attacker, TEAM_CLASSD, victim:Nick(), 2, false)
				elseif victim:GTeam() == TEAM_GOC then
					print("[" .. attacker:Nick() .. "] You've been awarded with 5 points for killing a GOC member!")
					attacker:AddFrags(5)
					SendKillNotification(attacker, TEAM_GOC, victim:Nick(), 5, false)
				end
			elseif attacker:GTeam() == TEAM_CHAOS then
				victim:PrintMessage(HUD_PRINTTALK, "You were killed by a Chaos Insurgency Soldier: " .. attacker:Nick())
				if victim:GTeam() == TEAM_GUARD then
					print("[" .. attacker:Nick() .. "] You've been awarded with 2 points for killing an MTF Guard!")
					attacker:AddFrags(2)
					SendKillNotification(attacker, TEAM_GUARD, victim:Nick(), 2, false)
				elseif victim:GTeam() == TEAM_SCI then
					print("[" .. attacker:Nick() .. "] You've been awarded with 2 points for killing a Researcher!")
					attacker:AddFrags(2)
					SendKillNotification(attacker, TEAM_SCI, victim:Nick(), 2, false)
				elseif victim:GTeam() == TEAM_SCP then
					-- Nie dawaj punktów za zabicie SCP-999 (już obsłużone wcześniej)
					if victim:GetNClass() != ROLES.ROLE_SCP999 then
						print("[" .. attacker:Nick() .. "] You've been awarded with 10 points for killing an SCP!")
						attacker:AddFrags(10)
						SendKillNotification(attacker, TEAM_SCP, victim:Nick(), 10, false)
					end
				elseif victim:GTeam() == TEAM_CLASSD then
					print("[" .. attacker:Nick() .. "] Don't kill Class D Personnel, they are your allies!")
					-- Usunięto punkty za zabicie Klasy D - to są sojusznicy Chaos
				elseif victim:GTeam() == TEAM_GOC then
					print("[" .. attacker:Nick() .. "] You've been awarded with 5 points for killing a GOC member!")
					attacker:AddFrags(5)
					SendKillNotification(attacker, TEAM_GOC, victim:Nick(), 5, false)
				end
			elseif attacker:GTeam() == TEAM_SCP then
				victim:PrintMessage(HUD_PRINTTALK, "You were killed by an SCP: " .. attacker:Nick())
				print("[" .. attacker:Nick() .. "] You've been awarded with 2 points for killing " .. victim:Nick())
				attacker:AddFrags(2)
				SendKillNotification(attacker, victim:GTeam(), victim:Nick(), 2, false)
			elseif attacker:GTeam() == TEAM_CLASSD then
				victim:PrintMessage(HUD_PRINTTALK, "You were killed by a Class D: " .. attacker:Nick())
				if victim:GTeam() == TEAM_GUARD then
					print("[" .. attacker:Nick() .. "] You've been awarded with 4 points for killing an MTF Guard!")
					attacker:AddFrags(4)
					SendKillNotification(attacker, TEAM_GUARD, victim:Nick(), 4, false)
				elseif victim:GTeam() == TEAM_SCI then
					print("[" .. attacker:Nick() .. "] You've been awarded with 2 points for killing a Researcher!")
					attacker:AddFrags(2)
					SendKillNotification(attacker, TEAM_SCI, victim:Nick(), 2, false)
				elseif victim:GTeam() == TEAM_SCP then
					-- Nie dawaj punktów za zabicie SCP-999 (już obsłużone wcześniej)
					if victim:GetNClass() != ROLES.ROLE_SCP999 then
						print("[" .. attacker:Nick() .. "] You've been awarded with 10 points for killing an SCP!")
						attacker:AddFrags(10)
						SendKillNotification(attacker, TEAM_SCP, victim:Nick(), 10, false)
					end
				elseif victim:GTeam() == TEAM_CHAOS then
					print("[" .. attacker:Nick() .. "] Don't kill Chaos Insurgency members, they are your allies!")
					-- Usunięto punkty za zabicie Chaos - to są sojusznicy Klasy D
				elseif victim:GTeam() == TEAM_GOC then
					print("[" .. attacker:Nick() .. "] You've been awarded with 5 points for killing a GOC member!")
					attacker:AddFrags(5)
					SendKillNotification(attacker, TEAM_GOC, victim:Nick(), 5, false)
				end
			elseif attacker:GTeam() == TEAM_SCI then
				victim:PrintMessage(HUD_PRINTTALK, "You were killed by a Researcher: " .. attacker:Nick())
				if victim:GTeam() == TEAM_SCP then
					-- Nie dawaj punktów za zabicie SCP-999 (już obsłużone wcześniej)
					if victim:GetNClass() != ROLES.ROLE_SCP999 then
						print("[" .. attacker:Nick() .. "] You've been awarded with 10 points for killing an SCP!")
						attacker:AddFrags(10)
						SendKillNotification(attacker, TEAM_SCP, victim:Nick(), 10, false)
					end
				elseif victim:GTeam() == TEAM_CHAOS then
					print("[" .. attacker:Nick() .. "] You've been awarded with 5 points for killing a Chaos Insurgency member!")
					attacker:AddFrags(5)
					SendKillNotification(attacker, TEAM_CHAOS, victim:Nick(), 5, false)
				elseif victim:GTeam() == TEAM_CLASSD then
					print("[" .. attacker:Nick() .. "] You've been awarded with 2 points for killing a Class D Personell!")
					attacker:AddFrags(2)
					SendKillNotification(attacker, TEAM_CLASSD, victim:Nick(), 2, false)
				elseif victim:GTeam() == TEAM_GOC then
					print("[" .. attacker:Nick() .. "] You've been awarded with 5 points for killing a GOC member!")
					attacker:AddFrags(5)
					SendKillNotification(attacker, TEAM_GOC, victim:Nick(), 5, false)
				end
			elseif attacker:GTeam() == TEAM_GOC then
				-- GOC nie dostaje punktów za zabijanie innych GOC (friendly fire)
				if victim:GTeam() != TEAM_GOC then
					victim:PrintMessage(HUD_PRINTTALK, "You were killed by a GOC member: " .. attacker:Nick())
					if victim:GTeam() == TEAM_SCP then
						-- Nie dawaj punktów za zabicie SCP-999 (już obsłużone wcześniej)
						if victim:GetNClass() != ROLES.ROLE_SCP999 then
							print("[" .. attacker:Nick() .. "] You've been awarded with 10 points for killing an SCP!")
							attacker:AddFrags(10)
							SendKillNotification(attacker, TEAM_SCP, victim:Nick(), 10, false)
						end
					elseif victim:GTeam() == TEAM_CHAOS then
						print("[" .. attacker:Nick() .. "] You've been awarded with 5 points for killing a Chaos Insurgency member!")
						attacker:AddFrags(5)
						SendKillNotification(attacker, TEAM_CHAOS, victim:Nick(), 5, false)
					elseif victim:GTeam() == TEAM_GUARD then
						print("[" .. attacker:Nick() .. "] You've been awarded with 5 points for killing an MTF Guard!")
						attacker:AddFrags(5)
						SendKillNotification(attacker, TEAM_GUARD, victim:Nick(), 5, false)
					elseif victim:GTeam() == TEAM_SCI then
						print("[" .. attacker:Nick() .. "] You've been awarded with 2 points for killing a Researcher!")
						attacker:AddFrags(2)
						SendKillNotification(attacker, TEAM_SCI, victim:Nick(), 2, false)
					elseif victim:GTeam() == TEAM_CLASSD then
						print("[" .. attacker:Nick() .. "] You've been awarded with 2 points for killing a Class D Personnel!")
						attacker:AddFrags(2)
						SendKillNotification(attacker, TEAM_CLASSD, victim:Nick(), 2, false)
					end
				else
					-- Friendly fire - brak punktów
					victim:PrintMessage(HUD_PRINTTALK, "You were killed by a fellow GOC member: " .. attacker:Nick())
				end
			end
		end
	end
	if not roundstats then
		roundstats = { deaths = 0 }
	end
	roundstats.deaths = roundstats.deaths + 1
	local wasteam = victim:GTeam()
	victim:SetTeam(TEAM_SPEC)
	victim:SetGTeam(TEAM_SPEC)
	
	victim:DropAllWeapons( true )

	WinCheck()
	if !postround then
		if !IsValid( attacker ) or !attacker.GTeam then return end
		local isTeamkill = false
		local teamkillPenalty = 0
		
		if attacker:GTeam() == wasteam then
			PunishVote( attacker, victim )
			isTeamkill = true
			teamkillPenalty = -5
		elseif attacker:GTeam() == TEAM_GUARD then
			if wasteam == TEAM_SCI then
				PunishVote( attacker, victim )
				isTeamkill = true
				teamkillPenalty = -3
			end
		elseif attacker:GTeam() == TEAM_SCI then
			if wasteam == TEAM_GUARD then
				PunishVote( attacker, victim )
				isTeamkill = true
				teamkillPenalty = -3
			end
		elseif attacker:GTeam() == TEAM_CLASSD then
			if wasteam == TEAM_CHAOS then
				PunishVote( attacker, victim )
				isTeamkill = true
				teamkillPenalty = -3
			end
		elseif attacker:GTeam() == TEAM_CHAOS then
			if wasteam == TEAM_CLASSD then
				PunishVote( attacker, victim )
				isTeamkill = true
				teamkillPenalty = -3
			end
		end
		
		-- Wyślij powiadomienie o teamkill
		if isTeamkill then
			attacker:AddFrags(teamkillPenalty)
			SendKillNotification(attacker, wasteam, victim:Nick(), teamkillPenalty, true)
		end
	end
end

function GM:PlayerDisconnected( ply )
	 ply:SetTeam(TEAM_SPEC)
	 if #player.GetAll() < MINPLAYERS then
		BroadcastLua('gamestarted = false')
		gamestarted = false
	 end
	 WinCheck()
end

function HaveRadio(pl1, pl2)
	if pl1:HasWeapon("item_radio") then
		if pl2:HasWeapon("item_radio") then
			local r1 = pl1:GetWeapon("item_radio")
			local r2 = pl2:GetWeapon("item_radio")
			if !IsValid(r1) or !IsValid(r2) then return false end
			/*
			print(pl1:Nick() .. " - " .. pl2:Nick())
			print(r1.Enabled)
			print(r1.Channel)
			print(r2.Enabled)
			print(r2.Channel)
			*/
			if r1.Enabled == true then
				if r2.Enabled == true then
					if r1.Channel == r2.Channel then
						if r1.Channel > 4 then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

function GM:PlayerCanHearPlayersVoice( listener, talker )
	if talker:Alive() == false then return false end
	if listener:Alive() == false then return false end

	if !talker.GetNClass then
		player_manager.SetPlayerClass( talker, "class_breach" )
		player_manager.RunClass( talker, "SetupDataTables" )
	end

	if !listener.GetNClass then
		player_manager.SetPlayerClass( listener, "class_breach" )
		player_manager.RunClass( listener, "SetupDataTables" )
	end

	if talker:GetNClass() == ROLES.ROLE_SCP957 or listener:GetNClass() == ROLES.ROLE_SCP957 then
		if talker:GetNClass() == ROLES.ROLE_SCP9571 or listener:GetNClass() == ROLES.ROLE_SCP9571 then
			return true
		end
	end

	-- Sprawdź efekt SCP-420-J
	local talkerHas420J = talker.n420endtime and talker.n420endtime > CurTime()
	local listenerHas420J = listener.n420endtime and listener.n420endtime > CurTime()
	
	-- Jeśli któryś ma efekt SCP-420-J i jedna osoba jest SCP, pozwól na komunikację
	if talkerHas420J or listenerHas420J then
		if talker:GTeam() == TEAM_SCP or listener:GTeam() == TEAM_SCP then
			return true
		end
	end

	if talker:GTeam() == TEAM_SCP and talker:GetNClass() != ROLES.ROLE_SCP9571 then
		local omit = false

		if talker:GetNClass() == ROLES.ROLE_SCP939 then
			local wep = talker:GetWeapon("weapon_scp_939")
			if IsValid( wep ) then
				if wep.Channel == "ALL" then
					omit = true
				end
			end
		end

		if !omit and GetConVar( "br_allow_scptovoicechat" ):GetInt() == 0 then
			if listener:GTeam() != TEAM_SCP then
				return false
			end
		end
	end
	if talker:GTeam() == TEAM_SPEC then
		if listener:GTeam() == TEAM_SPEC then
			return true
		else
			return false
		end
	end
	if HaveRadio(listener, talker) == true then
		return true
	end
	if talker:GetPos():Distance(listener:GetPos()) < 750 then
		return true, true
	else
		return false
	end
end

function GM:PlayerCanSeePlayersChat( text, teamOnly, listener, talker )
	if activevote and ( text == "!forgive" or text == "!punish" ) then
		local votemsg = false
		if talker.voted == true or talker:SteamID64() == activesuspect then
			if !talker.timeout then talker.timeout = 0 end
			if talker.timeout < CurTime() then
				talker.timeout = CurTime() + 0.5
				net.Start( "ShowText" )
					net.WriteString( "vote_fail" )
				net.Send( talker )
			end
			return
		end
		if text == "!forgive" then
			if talker:SteamID64() == activevictim then
				voteforgive = voteforgive + 5
			elseif talker:GTeam() == TEAM_SPEC then
				specforgive = specforgive + 1
			else
				voteforgive = voteforgive + 1
			end
			talker.voted = true
			votemsg = true
			talker.timeout = CurTime() + 0.5
		elseif text == "!punish" then
			if talker:SteamID64() == activevictim then
				votepunish = votepunish + 5
			elseif talker:GTeam() == TEAM_SPEC then
				specpunish = specpunish + 1
			else
				votepunish = votepunish + 1
			end
			talker.voted = true
			votemsg = true
			talker.timeout = CurTime() + 0.5
		end
		if votemsg then
			if listener:IsSuperAdmin() then
				return true
			else
				return false
			end
		end
	end

	if !talker.GetNClass or !listener.GetNClass then
		player_manager.SetPlayerClass( ply, "class_breach" )
		player_manager.RunClass( ply, "SetupDataTables" )
	end

	-- SCP-957: specjalne grupowanie głosowe / czatowe
	if talker:GetNClass() == ROLES.ROLE_SCP957 or listener:GetNClass() == ROLES.ROLE_SCP957 then
		if talker:GetNClass() == ROLES.ROLE_SCP9571 or listener:GetNClass() == ROLES.ROLE_SCP9571 then
			return true
		end
	end

	-- SCP-420-J: pozwól na widoczność czatu pomiędzy graczem pod efektem 420-J a drużyną SCP
	local talkerHas420J   = talker.n420endtime   and talker.n420endtime   > CurTime()
	local listenerHas420J = listener.n420endtime and listener.n420endtime > CurTime()
	if (talkerHas420J or listenerHas420J) and (talker:GTeam() == TEAM_SCP or listener:GTeam() == TEAM_SCP) then
		return true
	end

	if talker:GetNClass() == ROLES.ADMIN or listener:GetNClass() == ROLES.ADMIN then return true end
	if talker:Alive() == false then return false end
	if listener:Alive() == false then return false end
	if teamOnly then
		if talker:GetPos():Distance(listener:GetPos()) < 750 then
			return (listener:GTeam() == talker:GTeam())
		else
			return false
		end
	end
	if talker:GTeam() == TEAM_SPEC then
		if listener:GTeam() == TEAM_SPEC then
			return true
		else
			return false
		end
	end
	if HaveRadio(listener, talker) == true then
		return true
	end
	return (talker:GetPos():Distance(listener:GetPos()) < 750)
end

function GM:PlayerDeathSound()
	return true
end

hook.Add( "PlayerSay", "SCPPenaltyShow", function( ply, msg, teamonly )
	if string.lower( msg ) == "!scp" then
		if !ply.nscpcmdcheck or ply.nscpcmdcheck < CurTime() then
			ply.nscpcmdcheck = CurTime() + 10

			local r = tonumber( ply:GetPData( "scp_penalty", 0 ) ) - 1
			r = math.max( r, 0 )

			if r == 0 then
				ply:PrintTranslatedMessage( "scpready#50,200,50" )
			else
				ply:PrintTranslatedMessage( "scpwait".."$"..r.."#200,50,50" )
			end
		end

		return ""
	end
end )

hook.Add( "SetupPlayerVisibility", "CCTVPVS", function( ply, viewentity )
	local wep = ply:GetActiveWeapon()
	if IsValid( wep ) and wep:GetClass() == "item_cameraview" then
		if wep:GetEnabled() and IsValid( CCTV[wep:GetCAM()].ent ) then
			AddOriginToPVS( CCTV[wep:GetCAM()].pos )// + Vector( 0, 0, -10 ) )
		end
	end
end )

function GM:PlayerCanPickupWeapon( ply, wep )
	//if ply.lastwcheck == nil then ply.lastwcheck = 0 end
	//if ply.lastwcheck > CurTime() then return end
	//ply.lastwcheck = CurTime() + 0.5
	-- if wep.IDK != nil then
	-- 	for k,v in pairs(ply:GetWeapons()) do
	-- 		if wep.Slot == v.Slot then return false end
	-- 	end
	-- end

	if ply:GTeam() == TEAM_SCP and ply:GetNClass() != ROLES.ROLE_SCP9571 and ply:GetNClass() != ROLES.ROLE_SCP035 then
		if wep.ISSCP then
			return true
		end

		return false
		/*if not wep.ISSCP then
			return false
		else
			if wep.ISSCP == true then
				return true
			else
				return false
			end
		end*/
	end

	if ply:GTeam() != TEAM_SPEC then
		-- Security Droid nie może podnosić SCP-714 i eyedrops (nie działają na androidy)
		if ply:GetNClass() == ROLES.ROLE_SECURITY_DROID then
			local wepClass = wep:GetClass()
			if wepClass == "item_scp_714" or wepClass == "item_czysty" or wepClass == "item_eyedrops" then
				return false
			end
		end
		
		if wep.teams then
			local canuse = false
			for k,v in pairs(wep.teams) do
				if v == ply:GTeam() then
					canuse = true
				end
			end

			if canuse == false and ply:GetNClass() != ROLES.ROLE_SCP9571 and ply:GetNClass() != ROLES.ROLE_SCP035 then
				return false
			end
		end

		for k,v in pairs(ply:GetWeapons()) do
			if v:GetClass() == wep:GetClass() then
				return false
			end
		end

		if string.Left( wep:GetClass(), 3 ) == "cw_" then
			for k, v in pairs( ply:GetWeapons() ) do
				//if ( string.starts( v:GetClass(), "cw_" ) and string.starts( wep:GetClass(), "cw_" )) then return false end
				if string.Left( v:GetClass(), 3 ) == "cw_" then return false end
			end
		end

		if table.Count( ply:GetWeapons() ) >= 12 then
			return false
		end

		ply.gettingammo = wep.SavedAmmo

		return true
	else
		if ply:GetNClass() == ROLES.ADMIN then
			if wep:GetClass() == "br_holster" then return true end
			if wep:GetClass() == "weapon_physgun" then return true end
			if wep:GetClass() == "gmod_tool" then return true end
			if wep:GetClass() == "br_entity_remover" then return true end
			if wep:GetClass() == "br_tool_teleporter" then return true end
		end

		return false
	end
end

function GM:PlayerCanPickupItem( ply, item )
	-- Blokuj SCP możliwość podnoszenia itemów (oprócz SCP-9571 i SCP-035)
	if ply:GTeam() == TEAM_SCP and ply:GetNClass() != ROLES.ROLE_SCP9571 and ply:GetNClass() != ROLES.ROLE_SCP035 then
		return false
	end
	
	return ply:GTeam() != TEAM_SPEC or ply:GetNClass() == ROLES.ADMIN
end

function GM:AllowPlayerPickup( ply, ent )
	-- Blokuj SCP możliwość podnoszenia obiektów (oprócz SCP-9571 i SCP-035)
	if ply:GTeam() == TEAM_SCP and ply:GetNClass() != ROLES.ROLE_SCP9571 and ply:GetNClass() != ROLES.ROLE_SCP035 then
		return false
	end
	
	return ply:GTeam() != TEAM_SPEC or ply:GetNClass() == ROLES.ADMIN
end
// usesounds = true,
function IsInTolerance( spos, dpos, tolerance )
	if spos == dpos then return true end

	if isnumber( tolerance ) then
		tolerance = { x = tolerance, y = tolerance, z = tolerance }
	end

	local allaxes = { "x", "y", "z" }
	for k, v in pairs( allaxes ) do
		if spos[v] != dpos[v] then
			if tolerance[v] then
				if math.abs( dpos[v] - spos[v] ) > tolerance[v] then
					return false
				end
			else
				return false
			end
		end
	end

	return true
end

function GM:PlayerUse( ply, ent )
	if ply:GTeam() == TEAM_SPEC and ply:GetNClass() != ROLES.ADMIN then return false end
	if ply:GetNClass() == ROLES.ADMIN then return true end
	if ply.lastuse == nil then ply.lastuse = 0 end
	if ply.lastuse > CurTime() then return false end

	if MAPBUTTONS then
		for k, v in pairs( MAPBUTTONS ) do
		if v.pos == ent:GetPos() or v.tolerance then
			if v.tolerance and !IsInTolerance( v.pos, ent:GetPos(), v.tolerance ) then
				continue
			end

			ply.lastuse = CurTime() + 1

			if v.access then
				if OMEGADoors then
					return true
				end

				if v.levelOverride and v.levelOverride( ply ) then
					return true
				end

				local wep = ply:GetActiveWeapon()
				if IsValid( wep ) and wep:GetClass() == "br_keycard" then
					local keycard = wep
					if IsValid( keycard ) then
						if bit.band( keycard.Access, v.access ) > 0 then
							if !v.nosound then
								ply:EmitSound( "KeycardUse1.ogg" )
							end

							ply:PrintMessage( HUD_PRINTCENTER, v.custom_access or "Access granted to "..v.name )

							if v.custom_access_granted then
								return v.custom_access_granted( ply, ent ) or false
							else
								return true
							end
						else
							if !v.nosound then
								ply:EmitSound( "KeycardUse2.ogg" )
							end

							ply:PrintMessage( HUD_PRINTCENTER, v.custom_deny or "You cannot operate this door with this keycard" )

							return false
						end
					end
				else
					ply:PrintMessage( HUD_PRINTCENTER, v.custom_nocard or "A keycard is required to operate this door" )
					return false
				end
			end

			if v.canactivate == nil or v.canactivate( ply, ent ) then
				if !v.nosound then
					ply:EmitSound( "KeycardUse1.ogg" )
				end

				if v.customaccessmsg then
					ply:PrintMessage( HUD_PRINTCENTER, v.customaccessmsg )
				else
					ply:PrintMessage( HUD_PRINTCENTER, "Access granted to " .. v["name"] )
				end

				return true
			else
				if !v.nosound then
					ply:EmitSound( "KeycardUse2.ogg" )
				end

				if v.customdenymsg then
					ply:PrintMessage( HUD_PRINTCENTER, v.customdenymsg )
				else
					ply:PrintMessage( HUD_PRINTCENTER, "Access denied" )
				end

				return false
			end
		end
		end
	end

	if ( GetConVar( "br_scp_cars" ):GetInt() == 0 ) then
		if ( ply:GTeam() == TEAM_SCP and ply:GetNClass() != ROLES.ROLE_SCP9571 ) then
			if ( ent:GetClass() == "prop_vehicle_jeep" ) then
				return false
			end
		end
	end

	if ply:GTeam() == TEAM_SCP and ply:GetNClass() != ROLES.ROLE_SCP9571 and ply:GetNClass() != ROLES.ROLE_SCP035 then
		if ent:GetClass() == "cw_ammo_40mm" then
			return false
		end
		
		-- Blokuj SCP możliwość podnoszenia przedmiotów (itemów)
		if string.find(ent:GetClass(), "item_") then
			return false
		end
	end

	-- Medic Droid healing system - DISABLED (class removed)
	-- if ply:GetNClass() == ROLES.ROLE_MEDIC_DROID and ent:IsPlayer() then
	--	local target = ent
	--	-- Sprawdź czy target to Security Droid z życiem poniżej 50%
	--	if target:GetNClass() == ROLES.ROLE_SECURITY_DROID and target:Health() < 50 and target:Health() > 0 then
	--		-- Rozpocznij proces leczenia
	--		if not ply.HealingTarget then
	--			ply.HealingTarget = target
	--			ply.HealingStartTime = CurTime()
	--			ply:PrintMessage(HUD_PRINTCENTER, "Rozpoczynam leczenie Security Droid...")
	--			target:PrintMessage(HUD_PRINTCENTER, "Medic Droid rozpoczął Twoje leczenie...")
	--		end
	--		return false -- Blokuj normalne użycie
	--	end
	-- end

	return true
end

function GM:CanPlayerSuicide( ply )
	return false
end

-- Hook naprawiający problem z przezroczystością na scoreboardzie
function GM:ScoreboardShow( ply )
	-- Wymuś synchronizację ActivePlayer dla wszystkich graczy gdy ktoś otwiera scoreboard
	timer.Simple(0.1, function()
		for k, v in pairs(player.GetAll()) do
			if IsValid(v) then
				if v.ActivePlayer == nil then
					v.ActivePlayer = true
				end
				if v.GetNActive and v.SetNActive then
					v:SetNActive(v.ActivePlayer)
				end
			end
		end
	end)
end

-- Ochrona przed spawn killingiem MTF podczas preparing i wsparcia
function GM:EntityTakeDamage( target, dmginfo )
	-- Sprawdź czy to gracz
	if not target:IsPlayer() then return end
	
	-- Ochrona MTF i CI Spy podczas fazy preparing
	if preparing then
		if target:GTeam() == TEAM_GUARD or (target:GTeam() == TEAM_CHAOS and target:GetNClass() == ROLES.ROLE_CHAOSSPY) then
			local attacker = dmginfo:GetAttacker()
			if IsValid(attacker) and attacker:IsPlayer() then
				dmginfo:SetDamage(0)
				dmginfo:ScaleDamage(0)
				return true
			end
		end
	end
	
	-- Ochrona wsparcia MTF i Chaos przed spawn killingiem (5 sekund)
	if target.SupportSpawnProtection and CurTime() < target.SupportSpawnProtection then
		dmginfo:SetDamage(0)
		dmginfo:ScaleDamage(0)
		return true
	end
end

-- System przezroczystości dla chronionych MTF i CI Spy TYLKO podczas preparing
local function UpdateMTFProtection()
	if not preparing then 
		-- Zatrzymaj timer gdy preparing się kończy
		timer.Remove("MTFProtectionEffect")
		return 
	end
	
	for k, v in pairs(player.GetAll()) do
		if IsValid(v) then
			-- Chroń MTF i CI Spy podczas preparing (ale NIE tych co mają ochronę wsparcia)
			if (v:GTeam() == TEAM_GUARD or (v:GTeam() == TEAM_CHAOS and v:GetNClass() == ROLES.ROLE_CHAOSSPY)) and not v.SupportSpawnProtection then
				-- Efekt przezroczystości (miganie)
				local alpha = math.sin(CurTime() * 3) * 50 + 100 -- Oscyluje między 50 a 150
				v:SetColor(Color(255, 255, 255, alpha))
				v:SetRenderMode(RENDERMODE_TRANSALPHA)
			end
		end
	end
end

-- Timer dla efektu przezroczystości
timer.Create("MTFProtectionEffect", 0.1, 0, UpdateMTFProtection)

-- OPTYMALIZACJA: Zastąpienie Think hook event-driven systemem
local preparingEndHandled = false

-- Timer zamiast Think hook - znacznie lepsza wydajność
local function CheckPreparingEnd()
	if not preparing and not preparingEndHandled then
		-- Wykonaj tylko raz po zakończeniu preparing
		timer.Remove("MTFProtectionEffect")
		timer.Remove("CheckPreparingEnd") -- Usuń timer po wykonaniu

		-- Użyj cache graczy zamiast player.GetAll()
		if UpdatePlayerCache then UpdatePlayerCache() end
		local players = PlayerCache and PlayerCache.All or player.GetAll()

		-- Resetuj przezroczystość dla wszystkich graczy (oprócz tych z ochroną wsparcia)
		for k, v in pairs(players) do
			if IsValid(v) and not (v.SupportSpawnProtection and CurTime() < v.SupportSpawnProtection) then
				v:SetColor(Color(255, 255, 255, 255))
				v:SetRenderMode(RENDERMODE_NORMAL)
			end
		end

		preparingEndHandled = true
		print("[OPTIMIZATION] MTF Protection reset completed")
	elseif preparing then
		-- Reset flagi gdy preparing się zaczyna ponownie
		preparingEndHandled = false
	end
end

-- Event-driven system zamiast Think hook
hook.Add("OnRoundStateChanged", "OptimizedMTFProtection", function(newState)
	if newState == "active" and not preparingEndHandled then
		CheckPreparingEnd()
	elseif newState == "preparing" then
		preparingEndHandled = false
	end
end)

-- Fallback timer dla kompatybilności
timer.Create("CheckPreparingEnd", 1, 0, CheckPreparingEnd)

-- Hook blokujący strzelanie dla chronionych graczy wsparcia
hook.Add("EntityFireBullets", "BlockSupportProtectedShooting", function(ent, data)
	if IsValid(ent) and ent:IsPlayer() then
		if ent.SupportSpawnProtection and CurTime() < ent.SupportSpawnProtection then
			return false -- Blokuj strzelanie
		end
	end
end)

-- Medic Droid healing system - KeyPress hook - DISABLED (class removed)
-- hook.Add("KeyPress", "MedicDroidHealing", function(ply, key)
--	if not IsValid(ply) or not ply:Alive() then return end
--	if ply:GetNClass() ~= ROLES.ROLE_MEDIC_DROID then return end
--
--	-- Sprawdź czy gracz przytrzymuje klawisz E (IN_USE)
--	if ply:KeyDown(IN_USE) then
--		-- Znajdź Security Droid w pobliżu
--		local trace = ply:GetEyeTrace()
--		local target = trace.Entity
--
--		if IsValid(target) and target:IsPlayer() and target:GetNClass() == ROLES.ROLE_SECURITY_DROID then
--			local distance = ply:GetPos():Distance(target:GetPos())
--
--			-- Sprawdź dystans (maksymalnie 100 jednostek)
--			if distance <= 100 and target:Health() < 50 and target:Health() > 0 then
--				-- Rozpocznij leczenie jeśli jeszcze nie rozpoczęte
--				if not ply.HealingTarget then
--					ply.HealingTarget = target
--					ply.HealingStartTime = CurTime()
--					ply.HealingProgress = 0
--					ply:PrintMessage(HUD_PRINTCENTER, "Rozpoczynam leczenie Security Droid...")
--					target:PrintMessage(HUD_PRINTCENTER, "Medic Droid rozpoczął Twoje leczenie...")
--
--					-- OPTYMALIZACJA: Użyj nowej funkcji zamiast Think hook
--					StartMedicHealing(ply, target)
--				end
--			end
--		end
--	end
-- end)

-- Medic Droid healing system - KeyRelease hook - DISABLED (class removed)
-- hook.Add("KeyRelease", "MedicDroidHealingStop", function(ply, key)
--	if not IsValid(ply) then return end
--	if ply:GetNClass() ~= ROLES.ROLE_MEDIC_DROID then return end
--
--	-- Sprawdź czy gracz puścił klawisz E (IN_USE)
--	if key == IN_USE then
--		-- Zatrzymaj leczenie
--		if ply.HealingTarget then
--			ply:PrintMessage(HUD_PRINTCENTER, "Healing interrupted")
--		if IsValid(ply.HealingTarget) then
--			ply.HealingTarget:PrintMessage(HUD_PRINTCENTER, "Healing interrupted")
--			end
--			ply.HealingTarget = nil
--			ply.HealingStartTime = nil
--			ply.HealingProgress = nil
--		end
--	end
-- end)

-- ========================================
-- OPTYMALIZACJE WYDAJNOŚCI - WBUDOWANE
-- ========================================

-- Cache dla graczy (aktualizowany co sekundę)
PlayerCache = PlayerCache or {}
local LastCacheUpdate = 0

function UpdatePlayerCache()
	if CurTime() - LastCacheUpdate < 1 then return end

	PlayerCache.All = player.GetAll()
	PlayerCache.Alive = {}
	PlayerCache.SCP = {}
	PlayerCache.Human = {}

	for _, ply in pairs(PlayerCache.All) do
		if IsValid(ply) and ply:Alive() then
			table.insert(PlayerCache.Alive, ply)

			local team = ply:GTeam()
			if team == TEAM_SCP then
				table.insert(PlayerCache.SCP, ply)
			else
				table.insert(PlayerCache.Human, ply)
			end
		end
	end

	LastCacheUpdate = CurTime()
end

-- Zoptymalizowane wyszukiwanie graczy w pobliżu
function FindNearbyPlayers(pos, radius, excludePlayer)
	UpdatePlayerCache()
	local players = PlayerCache.Alive or player.GetAll()
	local nearbyPlayers = {}
	local radiusSq = radius * radius

	for _, ply in pairs(players) do
		if IsValid(ply) and ply ~= excludePlayer and ply:Alive() then
			if ply:GetPos():DistToSqr(pos) <= radiusSq then
				table.insert(nearbyPlayers, ply)
			end
		end
	end

	return nearbyPlayers
end

-- Eksportuj funkcje globalnie
_G.UpdatePlayerCache = UpdatePlayerCache
_G.FindNearbyPlayers = FindNearbyPlayers

-- OPTYMALIZACJA: Medic Droid healing system - Timer zamiast Think hook - DISABLED (class removed)
-- local ActiveHealers = {}
--
-- local function ProcessMedicHealing()
--	for steamid, data in pairs(ActiveHealers) do
--		local ply = data.healer
--		local target = data.target
--
--		if not IsValid(ply) or not IsValid(target) or not ply:Alive() then
--			ActiveHealers[steamid] = nil
--			continue
--		end
--
--		local distance = ply:GetPos():Distance(target:GetPos())
--
--		-- Sprawdź warunki leczenia
--		if ply:KeyDown(IN_USE) and distance <= 100 and target:Health() < 50 and target:Health() > 0 then
--			local healTime = CurTime() - data.startTime
--
--			if healTime >= 3.0 then
--				-- Heal to 50% health
--				target:SetHealth(50)
--				ply:PrintMessage(HUD_PRINTCENTER, "Security Droid healed successfully!")
--				target:PrintMessage(HUD_PRINTCENTER, "You have been healed by Medic Droid!")
--
--				-- Efekt dźwiękowy
--				ply:EmitSound("items/medshot4.wav")
--				target:EmitSound("items/medshot4.wav")
--
--				-- Zakończ leczenie
--				ActiveHealers[steamid] = nil
--				ply.HealingTarget = nil
--				ply.HealingStartTime = nil
--				ply.HealingProgress = nil
--			else
--				-- Show healing progress
--				local progress = math.floor((healTime / 3.0) * 100)
--				ply:PrintMessage(HUD_PRINTCENTER, "Healing: " .. progress .. "%")
--				target:PrintMessage(HUD_PRINTCENTER, "Healing: " .. progress .. "%")
--			end
--		else
--			-- Warunki nie spełnione, przerwij leczenie
--			ply:PrintMessage(HUD_PRINTCENTER, "Healing interrupted")
--			if IsValid(target) then
--				target:PrintMessage(HUD_PRINTCENTER, "Healing interrupted")
--			end
--			ActiveHealers[steamid] = nil
--			ply.HealingTarget = nil
--			ply.HealingStartTime = nil
--			ply.HealingProgress = nil
--		end
--	end
--
--	-- Usuń timer jeśli nie ma aktywnych lecących
--	if table.IsEmpty(ActiveHealers) then
--		timer.Remove("OptimizedMedicHealing")
--	end
-- end
--
-- -- Funkcja do rozpoczęcia leczenia (wywoływana z KeyPress hook)
-- function StartMedicHealing(healer, target)
--	if not IsValid(healer) or not IsValid(target) then return end
--
--	local steamid = healer:SteamID64()
--	ActiveHealers[steamid] = {
--		healer = healer,
--		target = target,
--		startTime = CurTime()
--	}
--
--	-- Uruchom timer jeśli nie istnieje
--	if not timer.Exists("OptimizedMedicHealing") then
--		timer.Create("OptimizedMedicHealing", 0.1, 0, ProcessMedicHealing)
--	end
-- end

-- Medic Droid weapon pickup restriction - DISABLED (class removed)
-- hook.Add("PlayerCanPickupWeapon", "MedicDroidWeaponRestriction", function(ply, weapon)
--	if not IsValid(ply) or not IsValid(weapon) then return end
--	if ply:GetNClass() ~= ROLES.ROLE_MEDIC_DROID then return end
--
--	-- Sprawdź czy to broń CW2
--	if weapon.CW20Weapon then
--		ply:PrintMessage(HUD_PRINTCENTER, "As Medic Droid you cannot pick up CW2 weapons!")
--		return false
--	end
--
--	-- Sprawdź czy to broń z prefiksem "cw_"
--	local weaponClass = weapon:GetClass()
--	if string.StartWith(weaponClass, "cw_") then
--		ply:PrintMessage(HUD_PRINTCENTER, "As Medic Droid you cannot pick up CW2 weapons!")
--		return false
--	end
-- end)

-- Hook obsługujący strzałki dla kamer
hook.Add("PlayerButtonDown", "CameraArrowKeys", function(ply, button)
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep:GetClass() == "item_cameraview" and wep:GetEnabled() then
		if button == KEY_LEFT then
			if wep.NextChange and wep.NextChange < CurTime() then
				wep:PrevCamera()
				wep.NextChange = CurTime() + 0.1
			end
		elseif button == KEY_RIGHT then
			if wep.NextChange and wep.NextChange < CurTime() then
				wep:NextCamera()
				wep.NextChange = CurTime() + 0.1
			end
		end
	end
end)

-- Hook blokujący wszystkie ataki dla chronionych graczy wsparcia
hook.Add("PlayerButtonDown", "BlockSupportProtectedAttack", function(ply, button)
	if ply.SupportSpawnProtection and CurTime() < ply.SupportSpawnProtection then
		if button == KEY_LMOUSE or button == KEY_RMOUSE then
			return false -- Blokuj atak
		end
	end
end)

-- Hook blokujący prop damage od cw_40mm_explosive
hook.Add("EntityTakeDamage", "BlockCW40mmPropDamage", function(target, dmginfo)
	if target:IsPlayer() then
		local inflictor = dmginfo:GetInflictor()
		local attacker = dmginfo:GetAttacker()
		
		-- Blokuj prop damage od cw_40mm_explosive (uderza przed eksplozją)
		if IsValid(inflictor) and inflictor:GetClass() == "cw_40mm_explosive" then
			-- Sprawdź czy to prop damage (gdy attacker == world/inflictor)
			if not IsValid(attacker) or attacker == inflictor or attacker:GetClass() == "worldspawn" then
				dmginfo:SetDamage(0)
				dmginfo:ScaleDamage(0)
				return true
			end
		end
	end
end)

-- OPTYMALIZACJA: System wsparcia - indywidualne timery zamiast Think hook
local function RemoveSupportProtection(ply)
	if not IsValid(ply) then return end

	ply.SupportSpawnProtection = nil
	ply:SetColor(Color(255, 255, 255, 255))
	ply:SetRenderMode(RENDERMODE_NORMAL)

	-- Upewnij się że bronie mogą strzelać
	local weapon = ply:GetActiveWeapon()
	if IsValid(weapon) then
		weapon:SetNextPrimaryFire(CurTime())
		weapon:SetNextSecondaryFire(CurTime())
	end

	print("[OPTIMIZATION] Support protection removed for " .. ply:Nick())
end

-- Funkcja do ustawienia ochrony wsparcia
function SetSupportSpawnProtection(ply, duration)
	if not IsValid(ply) then return end

	duration = duration or 10 -- Domyślnie 10 sekund

	ply.SupportSpawnProtection = CurTime() + duration
	ply:SetColor(Color(255, 255, 255, 100))
	ply:SetRenderMode(RENDERMODE_TRANSALPHA)

	-- Indywidualny timer dla gracza
	local timerName = "SupportProtection_" .. ply:SteamID64()
	timer.Create(timerName, duration, 1, function()
		RemoveSupportProtection(ply)
	end)

	print("[OPTIMIZATION] Support protection set for " .. ply:Nick() .. " (" .. duration .. "s)")
end

-- Hook do blokowania akcji podczas ochrony (zoptymalizowany)
hook.Add("PlayerButtonDown", "OptimizedSupportProtection", function(ply, button)
	if ply.SupportSpawnProtection and CurTime() < ply.SupportSpawnProtection then
		if button == IN_ATTACK or button == IN_ATTACK2 then
			return false -- Blokuj atak
		end
	end
end)

function string.starts( String, Start )
   return string.sub( String, 1, string.len( Start ) ) == Start
end

-- SCP-035 Transformation Function
local PlayerMeta = FindMetaTable("Player")

function PlayerMeta:BecomeSCP035()
    if not IsValid(self) then return end
    
    -- Zapisz starą drużynę dla logów
    local oldTeam = self:GTeam()
    
    print("[SCP-035 DEBUG] Starting transformation for " .. self:Nick() .. " (Team: " .. team.GetName(oldTeam) .. ")")
    
    -- Zapisz aktualny vest PRZED transformacją
    local currentVest = self.UsingArmor
    print("[SCP-035 DEBUG] Current vest: " .. tostring(currentVest))
    
    -- Oznacz jako SCP-035
    self.IsSCP035 = true
    
    -- Użyj systemu RegisterSCP który automatycznie zachowa ekwipunek dzięki no_strip = true
    local scp035 = GetSCP("SCP035")
    if scp035 then
        print("[SCP-035 DEBUG] Using RegisterSCP system with no_strip = true")
        scp035:SetupPlayer(self)
    else
        print("[SCP-035 ERROR] SCP-035 not found in RegisterSCP system!")
        -- Fallback do starej metody
        self:SetGTeam(TEAM_SCP)
        self:SetNClass(ROLES.ROLE_SCP035)
        self:SetHealth(200)
        self:SetMaxHealth(200)
        self:SetRunSpeed(250)
        self:SetWalkSpeed(125)
    end
    
    -- Ustaw system vestów dla SCP-035
    if currentVest then
        -- Miał vest przed transformacją - zablokuj go na ciele
        self.UsingArmor = currentVest
        self.LockedArmor = true -- Vest jest przytwierdzony do ciała
        print("[SCP-035 DEBUG] Vest locked to body: " .. currentVest)
        
        -- Wyślij informację o kamizelce do klienta
        net.Start("BR_UpdateVest")
            net.WriteString(currentVest)
        net.Send(self)
    else
        -- Nie miał vesta - całkowity zakaz zakładania vestów
        self.LockedArmor = false -- Oznacza że nie może zakładać vestów w ogóle
        print("[SCP-035 DEBUG] No vest before transformation - vest equipping blocked")
    end
    
    -- Efekty
    self:PrintMessage(HUD_PRINTTALK, "[SCP-035] The mask has bonded with you... You feel... different.")
    self:PrintMessage(HUD_PRINTTALK, "[SCP-035] You can now kill both humans AND SCPs!")
    self:PrintMessage(HUD_PRINTTALK, "[SCP-035] Your equipment remains with you...")
    if currentVest then
        self:PrintMessage(HUD_PRINTTALK, "[SCP-035] Your vest has fused with your body - you cannot remove it.")
    end
    
    -- Log dla adminów
    print("[SCP-035] " .. self:Nick() .. " became SCP-035 (was " .. team.GetName(oldTeam) .. ") - Using RegisterSCP system")
end

-- SCP-035 Death Hook - maska spada po śmierci
hook.Add("PlayerDeath", "SCP035_DropMask", function(victim, inflictor, attacker)
	if IsValid(victim) and victim:GetNClass() == ROLES.ROLE_SCP035 then
		-- Stwórz maskę w miejscu śmierci
		timer.Simple(0.1, function() -- Małe opóźnienie dla stabilności
			local mask = ents.Create("scp_035")
			if IsValid(mask) then
				mask:SetPos(victim:GetPos() + Vector(0, 0, 10))
				mask:SetAngles(Angle(0, math.random(0, 360), 0))
				mask:Spawn()
				mask:Activate()
				
				-- Dodaj małą siłę
				local phys = mask:GetPhysicsObject()
				if IsValid(phys) then
					phys:Wake()
					phys:SetVelocity(Vector(math.random(-100, 100), math.random(-100, 100), 100))
				end
				
				print("[SCP-035] Mask dropped after " .. victim:Nick() .. "'s death")
			end
		end)
		
		-- Wyczyść flagi SCP-035
		victim.IsSCP035 = nil
		victim.LockedArmor = nil
	end
end)

-- Blokada komendy thirdperson_toggle
hook.Add("PlayerSay", "BlockThirdPersonToggle", function(ply, text, public)
    local msg = string.lower(string.Trim(text))
    
    -- Blokuj tylko !thirdperson na czacie
    if msg == "!thirdperson" then
        ply:ChatPrint("[SERWER] Komenda thirdperson jest zablokowana na tym serwerze!")
        return ""  -- Blokuj wyświetlenie wiadomości
    end
end)

-- Blokada console command thirdperson_toggle
concommand.Add("thirdperson_toggle", function(ply, cmd, args)
    if IsValid(ply) then
        ply:ChatPrint("[SERWER] Komenda thirdperson jest zablokowana na tym serwerze!")
    end
end)