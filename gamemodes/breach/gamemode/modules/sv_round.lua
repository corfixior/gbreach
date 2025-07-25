activeRound = activeRound
rounds = rounds or -1
roundEnd = roundEnd or 0

MAP_LOADED = MAP_LOADED or false

function RestartGame()
	game.ConsoleCommand("changelevel "..game.GetMap().."\n")
end

function CleanUp()
	timer.Destroy("PreparingTime")
	timer.Destroy("RoundTime")
	timer.Destroy("PostTime")
	timer.Destroy("GateOpen")
	timer.Destroy("PlayerInfo")
	timer.Destroy("NTFEnterTime")
	timer.Destroy("966Debug")
	timer.Destroy("MTFDebug")
	timer.Destroy("PunishEnd")
	timer.Destroy("GateExplode")
	
	-- Usuń timery specjalnych rund
	timer.Remove("SwapperTimer")		-- Swapper round
	timer.Remove("BomberTimer")		-- Bomber round
	timer.Remove("MoveOrDieCheck")		-- Move or Die round
	timer.Remove("TTTRoundTimer")		-- TTT round (jeśli istnieje)
	timer.Remove("InfectTimer")		-- Infect round (jeśli istnieje)
	
	-- Wyczyść zmienne globalne specjalnych rund
	MOVEORDIE_DATA = nil			-- Move or Die round data
	if timer.Exists("CheckEscape") == false then
		timer.Create("CheckEscape", 1, 0, CheckEscape)
	end
	
	game.CleanUpMap()
	
	-- Czyść spraypainty i decale między rundami
	for _, ply in pairs(player.GetAll()) do
		ply:ConCommand("r_cleardecals")
	end
	
	-- Usuń wszystkie spraypainty/decale z mapy
	for _, ent in pairs(ents.GetAll()) do
		if ent:GetClass() == "env_spritecard" then -- spraypainty graczy
			ent:Remove()
		end
		-- Usuń decale z entity
		if IsValid(ent) then
			ent:RemoveAllDecals()
		end
	end
	
	print("[BREACH] Wyczyszczono spraypainty i decale")
	
	Recontain106Used = false
	OMEGAEnabled = false
	OMEGADoors = false
	nextgateaopen = 0
	spawnedntfs = 0
	-- Reset zmiennej itemsSpawned aby itemy mogły się zespawnować w nowej rundzie
	itemsSpawned = false
	
	-- Clean up SCP-268 effects from all players
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) then
			-- Remove SCP-268 invisibility effects
			ply:SetColor(Color(255, 255, 255, 255))
			ply:SetRenderMode(RENDERMODE_NORMAL)
			ply:SetNWBool("SCP268_Invisible", false)
			ply:SetNWFloat("SCP268_InvisTime", 0)
			ply:SetNWFloat("SCP268_Cooldown", 0)
			
			-- Clean up SCP-1123 effects
			ply:SetNWBool("SCP1123_InEffect", false)
			ply:SetNWFloat("SCP1123_EffectEnd", 0)
			ply:SetViewEntity(ply) -- Reset camera to self
			
			-- Clean up timers
			timer.Remove("SCP268_Death_" .. ply:SteamID64())
			timer.Remove("SCP1123_Effect_" .. ply:SteamID64())
		end
	end
	roundstats = {
		descaped = 0,
		rescaped = 0,
		sescaped = 0,
		dcaptured = 0,
		rescorted = 0,
		deaths = 0,
		teleported = 0,
		snapped = 0,
		zombies = 0,
		secretf = false
	}
	inUse = false

	-- MANUALNE CZYSZCZENIE CCTV
	if CCTV then
		for i, cam in ipairs(CCTV) do
			if IsValid(cam.ent) then
				cam.ent:Remove()
			end
			cam.ent = nil -- Usuń tylko referencję do encji, a nie cały wpis
		end
		print("[BREACH] Wyczyszczono referencje do kamer CCTV")
	end
end

function CleanUpPlayers()
	for k,v in pairs(player.GetAll()) do
		v:SetModelScale( 1 )
		v:SetCrouchedWalkSpeed(0.6)
		v.mblur = false
		--print( v.ActivePlayer, v:GetNActive() )
		player_manager.SetPlayerClass( v, "class_breach" )
		player_manager.RunClass( v, "SetupDataTables" )
		--print( v.ActivePlayer, v:GetNActive() )
		v:Freeze(false)
		v.MaxUses = nil
		v.blinkedby173 = false
		v.scp173allow = false
		v.scp1471stacks = 1
		v.usedeyedrops = false
		v.isescaping = false
		v:SendLua( "CamEnable = false" )
	end
	net.Start("Effect")
		net.WriteBool( false )
	net.Broadcast()
	net.Start("957Effect")
		net.WriteBool( false )
	net.Broadcast()
end

function RoundTypeUpdate()
	local nextRoundName = GetConVar( "br_force_specialround" ):GetString()
	activeRound = nil
	if tonumber( nextRoundName ) then
		nextRoundName = tonumber( nextRoundName )
	end
	if ROUNDS[ nextRoundName ] then
		activeRound = ROUNDS[ nextRoundName ]
	end
	RunConsoleCommand( "br_force_specialround", "" )
	if !activeRound /*and #ROUNDS > 1*/ then
		local pct = math.Clamp( GetConVar( "br_specialround_pct" ):GetInt(), 0, 100 )
		--print( pct )
		if math.random( 0, 100 ) < pct then
			repeat
				activeRound = table.Random( ROUNDS )
			until( activeRound != ROUNDS.normal )
		end
	end
	if !activeRound then
		activeRound = ROUNDS.normal
	end
end

function RoundRestart()
	if !MAP_LOADED then
		error( "Map config is not loaded!" )
	end
	print( debug.traceback() )  
	print("round: starting")
	CleanUp()
	print("round: map cleaned")
	if GetConVar("br_firstround_debug"):GetInt() > 0 and rounds == -1 then
		rounds = 0
		RoundRestart()
		return
	end
	if GetConVar("br_rounds"):GetInt() > 0 then
		if rounds == GetConVar("br_rounds"):GetInt() then
			RestartGame()
		end
		rounds = rounds + 1
	else
		rounds = 0
	end	
	CleanUpPlayers()
	print("round: players cleaned")
	preparing = true
	postround = false
	activeRound = nil
	if #GetActivePlayers() < MINPLAYERS then WinCheck() end
	RoundTypeUpdate()
	SetupCollide()
	SetupAdmins( player.GetAll() )
activeRound.setup()
	print( "round: setup end" )	
	net.Start("UpdateRoundType")
		net.WriteString(activeRound.name)
	net.Broadcast()	
	activeRound.init()	
	print( "round: int end / preparation start" )	
	gamestarted = true
	BroadcastLua('gamestarted = true')
	print("round: gamestarted")
	timer.Create("966Debug", GetConVar("br_time_preparing"):GetInt() + 15, 1, function()
		local fent = ents.FindInSphere(SPAWN_SCP966, 250)
		for k, v in pairs(fent) do
			if (v:IsPlayer()) then
				if (v:GetNClass() == ROLES.ROLE_SCP966) then
					v:SetPos(OUTSIDE_966)
					print("Do SCP 966 stuck?? Debugging...")
					break
				end
			end
		end
	end )
	net.Start("PrepStart")
		net.WriteInt(GetPrepTime(), 8)
	net.Broadcast()
	UseAll()
	DestroyAll()
	
	-- Spawn SCP Items (including SCP-268)
	SpawnSCPItems()
	
	timer.Destroy("PostTime") -----?????
	hook.Run( "BreachPreround" )
	timer.Create("PreparingTime", GetPrepTime(), 1, function()
		for k,v in pairs(player.GetAll()) do
			v:Freeze(false)
		end
		preparing = false
		postround = false
		
		-- Wyświetl statystyki drużyn po zakończeniu preparing
		local scps = gteams.NumPlayers(TEAM_SCP)
		local mtfs = gteams.NumPlayers(TEAM_GUARD) + gteams.NumPlayers(TEAM_CHAOS)
		local res = gteams.NumPlayers(TEAM_SCI)
		local ds = gteams.NumPlayers(TEAM_CLASSD)
		
		local statsMessage = string.format("Runda rozpoczęta! SCP: %d | MTF: %d | Naukowcy: %d | Klasa D: %d",
			scps, mtfs, res, ds)
		PrintMessage(HUD_PRINTTALK, statsMessage)
		
		activeRound.roundstart()
		
		-- Check if TTT round and set custom time
		local roundTime = GetRoundTime()
		if activeRound and activeRound.name == "TTT" then
			roundTime = 600 -- 10 minutes for TTT round
		end
		
		net.Start("RoundStart")
			net.WriteInt(roundTime, 12)
		net.Broadcast()
		print("round: started")
		roundEnd = CurTime() + roundTime + 3
		hook.Run( "BreachRound" )
		timer.Create("RoundTime", roundTime, 1, function()
			postround = false
			postround = true	
			print( "post init: good" )
			activeRound.postround()		
			GiveExp()	
			print( "post functions: good" )
			print( "round: post" )			
			net.Start("SendRoundInfo")
				net.WriteTable(roundstats)
			net.Broadcast()		
			net.Start("PostStart")
				net.WriteInt(GetPostTime(), 6)
				net.WriteInt(1, 4)
			net.Broadcast()	
			print( "data broadcast: good" )
			roundEnd = 0
			timer.Destroy("PunishEnd")
			hook.Run( "BreachPostround" )
			timer.Create("PostTime", GetPostTime(), 1, function()
				print( "restarting round" )
				RoundRestart()
			end)		
		end)
	end)
end

canescortds = true
canescortrs = true
function CheckEscape()
	for k,v in pairs(ents.FindInSphere(POS_ESCAPE, 250)) do
		if v:IsPlayer() == true then
			if v:Alive() == false then return end
			if v.isescaping == true then return end
			if v:GTeam() == TEAM_CLASSD or v:GTeam() == TEAM_SCI or v:GTeam() == TEAM_SCP then
				if v:GTeam() == TEAM_SCI then
					roundstats.rescaped = roundstats.rescaped + 1
					local rtime = timer.TimeLeft("RoundTime")
					local exptoget = 300
					if rtime != nil then
						exptoget = GetConVar("br_time_round"):GetInt() - (CurTime() - rtime)
						exptoget = exptoget * 1.8
						exptoget = math.Round(math.Clamp(exptoget, 300, 10000))
					end
					net.Start("OnEscaped")
						net.WriteInt(1,4)
					net.Send(v)
					v:AddFrags(5)
					v:AddExp(exptoget, true)
					v:GodEnable()
					v:Freeze(true)
					v.canblink = false
					v.isescaping = true
					timer.Create("EscapeWait" .. v:SteamID64(), 2, 1, function()
						v:Freeze(false)
						v:GodDisable()
						v:SetSpectator()
						WinCheck()
						v.isescaping = false
					end)
					//v:PrintMessage(HUD_PRINTTALK, "You escaped! Try to get escorted by MTF next time to get bonus points.")
				elseif v:GTeam() == TEAM_CLASSD then
					roundstats.descaped = roundstats.descaped + 1
					local rtime = timer.TimeLeft("RoundTime")
					local exptoget = 500
					if rtime != nil then
						exptoget = GetConVar("br_time_round"):GetInt() - (CurTime() - rtime)
						exptoget = exptoget * 2
						exptoget = math.Round(math.Clamp(exptoget, 500, 10000))
					end
					net.Start("OnEscaped")
						net.WriteInt(2,4)
					net.Send(v)
					v:AddFrags(5)
					v:AddExp(exptoget, true)
					v:GodEnable()
					v:Freeze(true)
					v.canblink = false
					v.isescaping = true
					timer.Create("EscapeWait" .. v:SteamID64(), 2, 1, function()
						v:Freeze(false)
						v:GodDisable()
						v:SetSpectator()
						WinCheck()
						v.isescaping = false
					end)
					//v:PrintMessage(HUD_PRINTTALK, "You escaped! Try to get escorted by Chaos Insurgency Soldiers next time to get bonus points.")
				elseif v:GTeam() == TEAM_SCP then
					roundstats.sescaped = roundstats.sescaped + 1
					local rtime = timer.TimeLeft("RoundTime")
					local exptoget = 425
					if rtime != nil then
						exptoget = GetConVar("br_time_round"):GetInt() - (CurTime() - rtime)
						exptoget = exptoget * 1.9
						exptoget = math.Round(math.Clamp(exptoget, 425, 10000))
					end
					net.Start("OnEscaped")
						net.WriteInt(4,4)
					net.Send(v)
					v:AddFrags(5)
					v:AddExp(exptoget, true)
					v:GodEnable()
					v:Freeze(true)
					v.canblink = false
					v.isescaping = true
					timer.Create("EscapeWait" .. v:SteamID64(), 2, 1, function()
						v:Freeze(false)
						v:GodDisable()
						v:SetSpectator()
						WinCheck()
						v.isescaping = false
					end)
				end
			end
		end
	end
end
timer.Create("CheckEscape", 1, 0, CheckEscape)

function CheckEscortMTF(pl)
	if pl.nextescheck != nil then
		if pl.nextescheck > CurTime() then
			pl:PrintMessage(HUD_PRINTTALK, "Wait " .. math.Round(pl.nextescheck - CurTime()) .. " seconds.")
			return
		end
	end
	pl.nextescheck = CurTime() + 3
	if pl:GTeam() != TEAM_GUARD then return end
	local foundpl = nil
	local foundrs = {}
	local foundds = {}
	
	for k,v in pairs(ents.FindInSphere(POS_ESCORT, 350)) do
		if v:IsPlayer() then
			if pl == v then
				foundpl = v
			elseif v:GTeam() == TEAM_SCI and v:Alive() then
				table.ForceInsert(foundrs, v)
			elseif v:GTeam() == TEAM_CLASSD and v:Alive() then
				table.ForceInsert(foundds, v)
			end
		end
	end
	
	if not IsValid(foundpl) then return end
	
	-- Eskortowanie naukowców
	if #foundrs > 0 then
		local rsstr = ""
		for i,v in ipairs(foundrs) do
			if i == 1 then
				rsstr = v:Nick()
			elseif i == #foundrs then
				rsstr = rsstr .. " and " .. v:Nick()
			else
				rsstr = rsstr .. ", " .. v:Nick()
			end
		end
		
		pl:AddFrags(#foundrs * 3)
		pl:AddExp((#foundrs * 425), true)
		local rtime = timer.TimeLeft("RoundTime")
		local exptoget = 700
		if rtime != nil then
			exptoget = GetConVar("br_time_round"):GetInt() - (CurTime() - rtime)
			exptoget = exptoget * 2.25
			exptoget = math.Round(math.Clamp(exptoget, 700, 10000))
		end
		
		for k,v in ipairs(foundrs) do
			roundstats.rescaped = roundstats.rescaped + 1
			v:SetSpectator()
			v:AddFrags(10)
			v:AddExp(exptoget, true)
			v:PrintMessage(HUD_PRINTTALK, "You've been escorted by " .. pl:Nick())
			net.Start("OnEscaped")
				net.WriteInt(3,4)
			net.Send(v)
			WinCheck()
		end
		
		pl:PrintMessage(HUD_PRINTTALK, "You've successfully escorted: " .. rsstr)
	end
	
	-- Eskortowanie Class-D
	if #foundds > 0 then
		local dsstr = ""
		for i,v in ipairs(foundds) do
			if i == 1 then
				dsstr = v:Nick()
			elseif i == #foundds then
				dsstr = dsstr .. " and " .. v:Nick()
			else
				dsstr = dsstr .. ", " .. v:Nick()
			end
		end
		
		pl:AddFrags(#foundds * 3)
		pl:AddExp((#foundds * 500), true)
		local rtime = timer.TimeLeft("RoundTime")
		local exptoget = 800
		if rtime != nil then
			exptoget = GetConVar("br_time_round"):GetInt() - (CurTime() - rtime)
			exptoget = exptoget * 2.5
			exptoget = math.Round(math.Clamp(exptoget, 800, 10000))
		end
		
		for k,v in ipairs(foundds) do
			roundstats.rescaped = roundstats.rescaped + 1
			v:SetSpectator()
			v:AddFrags(10)
			v:AddExp(exptoget, true)
			v:PrintMessage(HUD_PRINTTALK, "You've been escorted by " .. pl:Nick())
			net.Start("OnEscaped")
				net.WriteInt(3,4)
			net.Send(v)
			WinCheck()
		end
		
		pl:PrintMessage(HUD_PRINTTALK, "You've successfully escorted: " .. dsstr)
	end
end

function CheckEscortChaos(pl)
	if pl.nextescheck != nil then
		if pl.nextescheck > CurTime() then
			pl:PrintMessage(HUD_PRINTTALK, "Wait " .. math.Round(pl.nextescheck - CurTime()) .. " seconds.")
			return
		end
	end
	pl.nextescheck = CurTime() + 3
	if pl:GTeam() != TEAM_CHAOS then return end
	local foundpl = nil
	local foundds = {}
	local foundrs = {}
	
	for k,v in pairs(ents.FindInSphere(POS_ESCORT_CI or POS_ESCORT, 350)) do
		if v:IsPlayer() then
			if pl == v then
				foundpl = v
			elseif v:GTeam() == TEAM_CLASSD and v:Alive() then
				table.ForceInsert(foundds, v)
			elseif v:GTeam() == TEAM_SCI and v:Alive() then
				table.ForceInsert(foundrs, v)
			end
		end
	end
	
	if not IsValid(foundpl) then return end
	
	-- Eskortowanie Class-D (oryginalna funkcjonalność)
	if #foundds > 0 then
		local dsstr = ""
		for i,v in ipairs(foundds) do
			if i == 1 then
				dsstr = v:Nick()
			elseif i == #foundds then
				dsstr = dsstr .. " and " .. v:Nick()
			else
				dsstr = dsstr .. ", " .. v:Nick()
			end
		end
		
		pl:AddFrags(#foundds * 3)
		pl:AddExp((#foundds * 500), true)
		local rtime = timer.TimeLeft("RoundTime")
		local exptoget = 800
		if rtime != nil then
			exptoget = GetConVar("br_time_round"):GetInt() - (CurTime() - rtime)
			exptoget = exptoget * 2.5
			exptoget = math.Round(math.Clamp(exptoget, 800, 10000))
		end
		
		for k,v in ipairs(foundds) do
			roundstats.dcaptured = roundstats.dcaptured + 1
			v:SetSpectator()
			v:AddFrags(10)
			v:AddExp(exptoget, true)
			v:PrintMessage(HUD_PRINTTALK, "You've been captured by " .. pl:Nick())
			net.Start("OnEscaped")
				net.WriteInt(3,4)
			net.Send(v)
			WinCheck()
		end
		
		pl:PrintMessage(HUD_PRINTTALK, "You've successfully captured: " .. dsstr)
	end
	
	-- NOWE: Eskortowanie naukowców przez CHAOS
	if #foundrs > 0 then
		local rsstr = ""
		for i,v in ipairs(foundrs) do
			if i == 1 then
				rsstr = v:Nick()
			elseif i == #foundrs then
				rsstr = rsstr .. " and " .. v:Nick()
			else
				rsstr = rsstr .. ", " .. v:Nick()
			end
		end
		
		pl:AddFrags(#foundrs * 3)
		pl:AddExp((#foundrs * 450), true) -- Nieco mniej niż za Class-D
		local rtime = timer.TimeLeft("RoundTime")
		local exptoget = 750 -- Nieco mniej niż za Class-D
		if rtime != nil then
			exptoget = GetConVar("br_time_round"):GetInt() - (CurTime() - rtime)
			exptoget = exptoget * 2.3
			exptoget = math.Round(math.Clamp(exptoget, 750, 10000))
		end
		
		for k,v in ipairs(foundrs) do
			roundstats.rescaped = roundstats.rescaped + 1
			v:SetSpectator()
			v:AddFrags(10)
			v:AddExp(exptoget, true)
			v:PrintMessage(HUD_PRINTTALK, "You've been captured by " .. pl:Nick())
			net.Start("OnEscaped")
				net.WriteInt(3,4)
			net.Send(v)
			WinCheck()
		end
		
		pl:PrintMessage(HUD_PRINTTALK, "You've successfully captured: " .. rsstr)
	end
end

function WinCheck()
	if postround then return end
	if !activeRound then return end
	activeRound.endcheck()
	if roundEnd > 0 and roundEnd < CurTime() then
		roundEnd = 0
	--	endround = true
	--	why = "game ran out of time limit"
		print( "Something went wrong! Error code: 100" )
		print( debug.traceback() )
	end
	/*if #GetActivePlayers() < 2 then 
		endround = true
		why = " there are not enough players"
		gamestarted = false
		BroadcastLua( "gamestarted = false" )
	end*/
	if endround then
		print("Ending round because " .. why)
		PrintMessage(HUD_PRINTCONSOLE, "Ending round because " .. why)
		StopRound()
		timer.Destroy("RoundTime")
		preparing = false
		postround = true
		// send infos
		net.Start("SendRoundInfo")
			net.WriteTable(roundstats)
		net.Broadcast()
		
		net.Start("PostStart")
			net.WriteInt(GetPostTime(), 6)
			net.WriteInt(2, 4)
		net.Broadcast()
		activeRound.postround()	
		GiveExp()
		endround = false
		--print( debug.traceback() )  
		hook.Run( "BreachPostround" )
		timer.Create("PostTime", GetPostTime(), 1, function()
			RoundRestart()
		end)
	end
end

function StopRound()
	timer.Stop("PreparingTime")
	timer.Stop("RoundTime")
	timer.Stop("PostTime")
	timer.Stop("GateOpen")
	timer.Stop("PlayerInfo")
end

timer.Create("WinCheckTimer", 5, 0, function()
	if postround == false and preparing == false then
		WinCheck()
	end
end)

timer.Create("EXPTimer", 180, 0, function()
	for k,v in pairs(player.GetAll()) do
		if IsValid(v) and v.AddExp != nil then
			v:AddExp(200, true)
		end
	end
end)

function SetupCollide()
	local fent = ents.GetAll()
	for k, v in pairs( fent ) do
		if v and v:GetClass() == "func_door" or v:GetClass() == "prop_dynamic" then
			if v:GetClass() == "prop_dynamic" then
				local ennt = ents.FindInSphere( v:GetPos(), 5 )
				local neardors = false
				for k, v in pairs( ennt ) do
					if v:GetClass() == "func_door" then
						neardors = true
						break
					end
				end
				if !neardors then
					v.ignorecollide106 = false
					v.ignorecollide999 = false -- Dodaj dla SCP-999
					v.ignoredoorcontroller = false -- Dodaj dla Door Controller
					continue
				end
			end

			local changed
			for _, pos in pairs( DOOR_RESTRICT106 ) do
				if v:GetPos():Distance( pos ) < 100 then
					v.ignorecollide106 = false
					v.ignorecollide999 = false -- Dodaj dla SCP-999
					changed = true
					break
				end
			end
			
			-- Sprawdź czy drzwi są w blackliście Door Controller
			local doorControllerBlocked = false
			if DOOR_RESTRICT_CONTROLLER then
				for _, pos in pairs( DOOR_RESTRICT_CONTROLLER ) do
					if v:GetPos():Distance( pos ) < 100 then
						v.ignoredoorcontroller = false
						doorControllerBlocked = true
						break
					end
				end
			end
			
			if !changed then
				v.ignorecollide106 = true
				v.ignorecollide999 = true -- Dodaj dla SCP-999
			end
			
			if !doorControllerBlocked then
				v.ignoredoorcontroller = true
			end
		end
	end
end

-- Function to spawn SCP Items
function SpawnSCPItems()
	if not SCP_ITEMS_SPAWN then return end
	
	-- Clean up existing SCP items
	for _, ent in pairs(ents.GetAll()) do
		if IsValid(ent) then
			local class = ent:GetClass()
					-- Remove any SCP items that might be configured in SCP_ITEMS_SPAWN
		for _, itemData in pairs(SCP_ITEMS_SPAWN) do
			if class == itemData.class then
				ent:Remove()
				break
			end
		end
		
		-- Also clean up SCP-1123 specifically
		if class == "scp_1123" then
			ent:Remove()
		end
		
		-- Clean up SCP-005
		if class == "weapon_scp_005" then
			ent:Remove()
		end
		end
	end
	
	-- Spawn new items based on chance
	local spawnedCount = 0
	for _, itemData in pairs(SCP_ITEMS_SPAWN) do
		if math.random() <= itemData.chance then
			local item = ents.Create(itemData.class)
			if IsValid(item) then
				item:SetPos(itemData.pos)
				item:SetAngles(Angle(0, math.random(0, 360), 0))
				item:Spawn()
				item:Activate()
				
				spawnedCount = spawnedCount + 1
				print("[BREACH] Spawned " .. itemData.class .. " at " .. tostring(itemData.pos))
			end
		end
	end
	
	-- Spawn SCP-005 with 50% chance at random location
	if SCP_005_SPAWN_POINTS and math.random() <= 0.5 then
		local randomPos = table.Random(SCP_005_SPAWN_POINTS)
		local scp005 = ents.Create("weapon_scp_005")
		if IsValid(scp005) then
			scp005:SetPos(randomPos)
			scp005:SetAngles(Angle(0, math.random(0, 360), 0))
			scp005:Spawn()
			scp005:Activate()
			
			spawnedCount = spawnedCount + 1
			print("[BREACH] Spawned SCP-005 at " .. tostring(randomPos))
		end
	end
	
	-- Spawn SCP-106 Barrier
	if SCP_106_BARRIER_SPAWN then
		-- Sprawdź czy bariera już istnieje
		local existing = ents.FindByClass("scp106_barrier")
		if #existing == 0 then
			local barrier = ents.Create("scp106_barrier")
			if IsValid(barrier) then
				barrier:SetPos(SCP_106_BARRIER_SPAWN)
				barrier:SetAngles(Angle(0, 0, 0))
				barrier:Spawn()
				barrier:Activate()
				
				spawnedCount = spawnedCount + 1
				print("[BREACH] Spawned SCP-106 barrier at " .. tostring(SCP_106_BARRIER_SPAWN))
			end
		end
	end
	
	if spawnedCount > 0 then
		print("[BREACH] Total SCP items spawned: " .. spawnedCount)
	end
end

-- Placeholder functions for compatibility
if not UseAll then
function UseAll()
	-- This placeholder will be used only if original UseAll is not defined elsewhere
end
end

if not DestroyAll then
function DestroyAll()
	-- Placeholder in case original DestroyAll is missing
end
end
