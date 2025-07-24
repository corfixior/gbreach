// Initialization file
-- AddCSLuaFile( "fonts.lua" )
-- AddCSLuaFile( "cl_font.lua" )
-- AddCSLuaFile( "class_breach.lua" )
-- AddCSLuaFile( "cl_hud_new.lua" )
-- AddCSLuaFile( "cl_hud.lua" )
-- AddCSLuaFile( "shared.lua" )
-- AddCSLuaFile( "gteams.lua" )
-- AddCSLuaFile( "cl_scoreboard.lua" )
-- AddCSLuaFile( "cl_mtfmenu.lua" )
-- AddCSLuaFile( "sh_player.lua" )
-- AddCSLuaFile( "sh_playersetups.lua" )
-- mapfile = "mapconfigs/" .. game.GetMap() .. ".lua"
-- AddCSLuaFile(mapfile)
-- ALLLANGUAGES = {}
-- WEPLANG = {}
-- clang = nil
-- cwlang = nil

-- local files, dirs = file.Find(GM.FolderName .. "/gamemode/languages/*.lua", "LUA" )
-- for k,v in pairs(files) do
-- 	local path = "languages/"..v
-- 	if string.Right(v, 3) == "lua" and string.Left(v, 3) != "wep" then
-- 		AddCSLuaFile( path )
-- 		include( path )
-- 		print("Language found: " .. path)
-- 	end
-- end
-- local files, dirs = file.Find(GM.FolderName .. "/gamemode/languages/wep_*.lua", "LUA" )
-- for k,v in pairs(files) do
-- 	local path = "languages/"..v
-- 	if string.Right(v, 3) == "lua" then
-- 		AddCSLuaFile( path )
-- 		include( path )
-- 		print("Weapon lang found: " .. path)
-- 	end
-- end
-- AddCSLuaFile( "rounds.lua" )
-- AddCSLuaFile( "cl_sounds.lua" )
-- AddCSLuaFile( "cl_targetid.lua" )
-- AddCSLuaFile( "classes.lua" )
-- AddCSLuaFile( "cl_classmenu.lua" )
-- AddCSLuaFile( "cl_headbob.lua" )
-- --AddCSLuaFile( "cl_splash.lua" )
-- AddCSLuaFile( "cl_init.lua" )
-- AddCSLuaFile( "ulx.lua" )
-- AddCSLuaFile( "cl_minigames.lua" )
-- AddCSLuaFile( "cl_eq.lua" )
-- include( "server.lua" )
-- include( "rounds.lua" )
-- include( "class_breach.lua" )
-- include( "shared.lua" )
-- include( "classes.lua" )
-- include( mapfile )
-- include( "sh_player.lua" )
-- include( "sv_player.lua" )
-- include( "player.lua" )
-- include( "sv_round.lua" )
-- include( "gteams.lua" )
-- include( "sv_func.lua" )

-- Death card system
AddCSLuaFile( "cl_deathcard.lua" )
include( "sv_deathcard.lua" )

-- Door access indicator system
AddCSLuaFile( "cl_door_access_hud.lua" )
include( "sv_door_access_sync.lua" )

-- Weapon damage modifiers system
AddCSLuaFile( "cl_weapon_damage_menu.lua" )
include( "sv_weapon_damage_modifiers.lua" )



-- Include SCP Upgrader modules
AddCSLuaFile( "sh_upgrader_config.lua" )
AddCSLuaFile( "cl_upgrader_menu.lua" )
include( "sh_upgrader_config.lua" )

-- Include SCP-313 module
include( "sv_scp313.lua" )



AddCSLuaFile( "cl_bomber_lottery.lua" )

-- SCP-294 Network Strings removed - menu system no longer used

resource.AddFile( "sound/radio/chatter1.ogg" )
resource.AddFile( "sound/radio/chatter2.ogg" )
resource.AddFile( "sound/radio/chatter3.ogg" )
resource.AddFile( "sound/radio/chatter4.ogg" )
resource.AddFile( "sound/radio/franklin1.ogg" )
resource.AddFile( "sound/radio/franklin2.ogg" )
resource.AddFile( "sound/radio/franklin3.ogg" )
resource.AddFile( "sound/radio/franklin4.ogg" )
resource.AddFile( "sound/radio/radioalarm.ogg" )
resource.AddFile( "sound/radio/radioalarm2.ogg" )
resource.AddFile( "sound/radio/scpradio0.ogg" )
resource.AddFile( "sound/radio/scpradio1.ogg" )
resource.AddFile( "sound/radio/scpradio2.ogg" )
resource.AddFile( "sound/radio/scpradio3.ogg" )
resource.AddFile( "sound/radio/scpradio4.ogg" )
resource.AddFile( "sound/radio/scpradio5.ogg" )
resource.AddFile( "sound/radio/scpradio6.ogg" )
resource.AddFile( "sound/radio/scpradio7.ogg" )
resource.AddFile( "sound/radio/scpradio8.ogg" )
resource.AddFile( "sound/radio/ohgod.ogg" )

// Variables
gamestarted = gamestarted or false
preparing = false
postround = false
roundcount = 0
MAPBUTTONS = table.Copy(BUTTONS)
itemsSpawned = false

function GM:PlayerSpray( ply )
	if ply:GTeam() == TEAM_SPEC then
		return true
	end
	if ply:GetPos():WithinAABox( POCKETD_MINS, POCKETD_MAXS ) then
		ply:PrintMessage( HUD_PRINTCENTER, "You can't use spray in Pocket Dimension" )
		return true
	end
end

function GetActivePlayers()
	local tab = {}
	for k,v in pairs(player.GetAll()) do
		if IsValid( v ) then
			if v.ActivePlayer == nil then
				v.ActivePlayer = true
				v:SetNActive( true )
			end

			if v.ActivePlayer == true then
				table.ForceInsert(tab, v)
			end
		end
	end
	return tab
end

function GetNotActivePlayers()
	local tab = {}
	for k,v in pairs(player.GetAll()) do
		if v.ActivePlayer == nil then v.ActivePlayer = true v:SetNActive( true ) end
		if v.ActivePlayer == false then
			table.ForceInsert(tab, v)
		end
	end
	return tab
end

function GM:ShutDown()
	--
end

function WakeEntity(ent)
	local phys = ent:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
		phys:SetVelocity( Vector( 0, 0, 25 ) )
	end
end

function PlayerNTFSound(sound, ply)
	if (ply:GTeam() == TEAM_GUARD or ply:GTeam() == TEAM_CHAOS) and ply:Alive() then
		if ply.lastsound == nil then ply.lastsound = 0 end
		if ply.lastsound > CurTime() then
			ply:PrintMessage(HUD_PRINTTALK, "You must wait " .. math.Round(ply.lastsound - CurTime()) .. " seconds to do this.")
			return
		end
		//ply:EmitSound( "Beep.ogg", 500, 100, 1 )
		ply.lastsound = CurTime() + 3
		//timer.Create("SoundDelay"..ply:SteamID64() .. "s", 1, 1, function()
			ply:EmitSound( sound, 450, 100, 1 )
		//end)
	end
end

function OnUseEyedrops(ply)
	if ply.usedeyedrops == true then
		ply:PrintMessage(HUD_PRINTTALK, "Don't use them that fast!")
		return
	end
	ply.usedeyedrops = true
	ply:StripWeapon("item_eyedrops")
	ply:PrintMessage(HUD_PRINTTALK, "Used eyedrops, you will not be blinking for 10 seconds")
	timer.Create("Unuseeyedrops" .. ply:SteamID64(), 10, 1, function()
		ply.usedeyedrops = false
		ply:PrintMessage(HUD_PRINTTALK, "You will be blinking now")
	end)
end

timer.Create( "CheckStart", 10, 0, function()
	if !gamestarted then
		CheckStart()
	end
end )

// Timer naprawiający problem z przezroczystością na scoreboardzie
timer.Create( "FixActivePlayerSync", 5, 0, function()
	for k, v in pairs(player.GetAll()) do
		if IsValid(v) then
			// Napraw ActivePlayer jeśli jest nil
			if v.ActivePlayer == nil then
				v.ActivePlayer = true
			end
			
			// Wymuś synchronizację zmiennej sieciowej
			if v.GetNActive and v.SetNActive then
				if v:GetNActive() != v.ActivePlayer then
					v:SetNActive(v.ActivePlayer)
				end
			end
		end
	end
end )

timer.Create("BlinkTimer", GetConVar("br_time_blinkdelay"):GetInt(), 0, function()
	local time = GetConVar("br_time_blink"):GetFloat()
	if time >= 5 then return end
	for k,v in pairs(player.GetAll()) do
		if v.canblink and v.blinkedby173 == false and v.usedeyedrops == false then
			net.Start("PlayerBlink")
				net.WriteFloat(time)
			net.Send(v)
			v.isblinking = true
		end
	end
	timer.Create("UnBlinkTimer", time + 0.2, 1, function()
		for k,v in pairs(player.GetAll()) do
			if v.blinkedby173 == false then
				v.isblinking = false
			end
		end
	end)
end)

timer.Create("EffectTimer", 0.3, 0, function()
	for k, v in pairs( player.GetAll() ) do
		if v.mblur == nil then v.mblur = false end
		net.Start("Effect")
			net.WriteBool( v.mblur )
		net.Send(v)
	end
end )

/*nextgateaopen = 0
function RequestOpenGateA(ply)
	if preparing or postround then return end
	if !(ply:GTeam() == TEAM_GUARD or ply:GTeam() == TEAM_CHAOS) then return end
	if nextgateaopen > CurTime() then
		ply:PrintMessage(HUD_PRINTTALK, "You cannot open Gate A now, you must wait " .. math.Round(nextgateaopen - CurTime()) .. " seconds")
		return
	end
	local gatea
	local rdc
	for id,ent in pairs(ents.FindByClass("func_rot_button")) do
		for k,v in pairs(MAPBUTTONS) do
			if v["pos"] == ent:GetPos() then
				if v["name"] == "Remote Door Control" then
					rdc = ent
					rdc:Use(ply, ply, USE_ON, 1)
				end
			end
		end
	end
	for id,ent in pairs(ents.FindByClass("func_button")) do
		for k,v in pairs(MAPBUTTONS) do
			if v["pos"] == ent:GetPos() then
				if v["name"] == "Gate A" then
					gatea = ent
				end
			end
		end
	end
	if IsValid(gatea) then
		nextgateaopen = CurTime() + 20
		timer.Simple(2, function()
			if IsValid(gatea) then
				gatea:Use(ply, ply, USE_ON, 1)
			end
		end)
	end
end*/

function GetPocketPos()
	if istable( POS_POCKETD ) then
		return table.Random( POS_POCKETD )
	else
		return POS_POCKETD
	end
end

function UseAll()
	for k, v in pairs( FORCE_USE ) do
		local enttab = ents.FindInSphere( v, 3 )
		for _, ent in pairs( enttab ) do
			if ent:GetPos() == v then
				ent:Fire( "Use" )
				break
			end
		end
	end
end

function DestroyAll()
	for k, v in pairs( FORCE_DESTROY ) do
		if isvector( v ) then
			local enttab = ents.FindInSphere( v, 1 )
			for _, ent in pairs( enttab ) do
				if ent:GetPos() == v then
					ent:Remove()
					break
				end
			end
		elseif isnumber( v ) then
			local ent = ents.GetByIndex( v )
			if IsValid( ent ) then
				ent:Remove()
			end
		end
	end
end

function SpawnAllItems()
	if itemsSpawned then return end
	if not MAP_LOADED then return end
	itemsSpawned = true



	// Remove old kebab stands
	for _, ent in pairs( ents.FindByClass("br_kebab_stand") ) do
		if IsValid(ent) then
			ent:Remove()
		end
	end

	------XMAS PART------

	/*for k, v in pairs( XMAS_TREES ) do
		local tree = ents.Create( "prop_physics" )
		tree:SetModel( "models/unconid/xmas/xmas_tree.mdl" )
		tree:SetPos( v )
		local phys = tree:GetPhysicsObject()
		if IsValid( phys ) then
			phys:Wake()
			phyas:EnableMotion( false )
		end
	end

	for k, v in pairs( XMAS_SNOWMANS_SMALL ) do
		local snowman = ents.Create( "prop_physics" )
		snowman:SetModel( "models/unconid/xmas/snowman_u.mdl" )
		snowman:SetPos( v[1] )
		snowman:SetAngles( v[2] )
		local phys = snowman:GetPhysicsObject()
		if IsValid( phys ) then
			phys:Wake()
			phyas:EnableMotion( false )
		end
	end

	for k, v in pairs( XMAS_SNOWMANS_BIG ) do
		local snowman = ents.Create( "prop_physics" )
		snowman:SetModel( "models/unconid/xmas/snowman_u_big.mdl" )
		snowman:SetPos( v[1] )
		snowman:SetAngles( v[2] )
		local phys = snowman:GetPhysicsObject()
		if IsValid( phys ) then
			phys:Wake()
			phyas:EnableMotion( false )
		end
	end*/

	---------------------

	for k,v in pairs(SPAWN_FIREPROOFARMOR) do
		local vest = ents.Create( "armor_fireproof" )
		if IsValid( vest ) then
			vest:Spawn()
			vest:SetPos( v )
			WakeEntity(vest)
		end
	end
	
	for k,v in pairs(SPAWN_ARMORS) do
		local vest = ents.Create( "armor_mtfguard" )
		if IsValid( vest ) then
			vest:Spawn()
			vest:SetPos( v )
			WakeEntity(vest)
		end
	end
	
	for k,v in pairs(SPAWN_ELECTROPROOFARMOR) do
		local vest = ents.Create( "armor_electroproof" )
		if IsValid( vest ) then
			vest:Spawn()
			vest:SetPos( v )
			WakeEntity( vest )
		end
	end
	
	local pistols = {
		"cw_deagle",
		"cw_fiveseven",
	}

	for k,v in pairs( SPAWN_PISTOLS ) do
		local selected = table.Random( pistols )
		local wep = ents.Create( selected )
		if IsValid( wep ) then
			wep:Spawn()
			wep:SetPos( v )
			WakeEntity( wep )
		end
	end
	
	local smgs = {
		"cw_g36c",
		"cw_ump45",
		"cw_mp5",
	}

	for k,v in pairs( SPAWN_SMGS ) do
		local selected = table.Random( smgs )
		local wep = ents.Create( selected )
		if IsValid( wep ) then
			wep:Spawn()
			wep:SetPos( v )
			WakeEntity( wep )
		end
	end
	
	local rifles = {
		"cw_ak74",
		"cw_ar15",
		"cw_m14",
		"cw_scarh",
	}

	for k,v in pairs( SPAWN_RIFLES ) do
		local selected = table.Random( rifles )
		local wep = ents.Create( selected )
		if IsValid( wep ) then
			wep:Spawn()
			wep:SetPos( v )
			WakeEntity( wep )
		end
	end
	
	for k,v in pairs( SPAWN_SNIPER ) do
		local wep = ents.Create( "cw_l115" )
		if IsValid( wep ) then
			wep:Spawn()
			wep:SetPos( v )
			WakeEntity( wep )
		end
	end
	
	local pumps = {
		"cw_shorty",
		"cw_m3super90",
	}

	for k,v in pairs(SPAWN_PUMP) do
		local selected = table.Random( pumps )
		local wep = ents.Create( selected )
		if IsValid( wep ) then
			wep:Spawn()
			wep:SetPos( v )
			WakeEntity( wep )
		end
	end
	
	for k,v in pairs(SPAWN_AMMO_CW) do
		local wep = ents.Create("cw_ammo_kit_regular")
		if IsValid( wep ) then
			wep.AmmoCapacity = 25
			wep:Spawn()
			wep:SetPos( v )
			// Disable collision with players
			wep:SetCollisionGroup(COLLISION_GROUP_WEAPON)
			WakeEntity( wep )
		end
	end
	
/*	for k,v in pairs(SPAWN_AMMO_G) do
		local wep = ents.Create("cw_ammo_40mm")
		if IsValid( wep ) then
			wep:Spawn()
			wep:SetPos( v )
			WakeEntity(wep)
		end
	end */
	
	if GetConVar("br_allow_vehicle"):GetInt() != 0 then
		for k, v in pairs(SPAWN_VEHICLE_GATE_A) do
			local car = ents.Create("prop_vehicle_jeep")
			if IsValid(car) then
				if GetConVar("br_cars_oldmodels"):GetInt() == 0 then
					car:SetModel("models/tdmcars/jeep_wrangler_fnf.mdl")
					car:SetKeyValue("vehiclescript","scripts/vehicles/TDMCars/wrangler_fnf.txt")
				else
					car:SetModel("models/buggy.mdl")
					car:SetKeyValue("vehiclescript","scripts/vehicles/jeep_test.txt")
				end
				car:SetPos( v )
				car:SetAngles( Angle( 0, 90, 0 ) )
				car:Spawn()
				WakeEntity( car )
			else
				ErrorNoHalt("Could not create 'prop_vehicle_jeep' entity!\n")
			end
		end
	
		for k, v in ipairs(SPAWN_VEHICLE_NTF) do
			if k > math.Clamp( GetConVar( "br_cars_ammount" ):GetInt(), 0, 12 ) then
				break
			end
			local car = ents.Create("prop_vehicle_jeep")
			if IsValid(car) then
				if GetConVar("br_cars_oldmodels"):GetInt() == 0 then
					car:SetModel("models/tdmcars/jeep_wrangler_fnf.mdl")
					car:SetKeyValue("vehiclescript","scripts/vehicles/TDMCars/wrangler_fnf.txt")
				else
					car:SetModel("models/buggy.mdl")
					car:SetKeyValue("vehiclescript","scripts/vehicles/jeep_test.txt")
				end
				car:SetPos( v )
				car:SetAngles( Angle( 0, 270, 0 ) )
				car:Spawn()
				WakeEntity( car )
			else
				ErrorNoHalt("Could not create 'prop_vehicle_jeep' entity!\n")
			end
		end
	end
	
	local item = ents.Create( "item_scp_714" )
	if IsValid( item ) then
		item:SetPos( SPAWN_714 )
		item:Spawn()
	end
	
	// Spawn SCP-035 mask with 25% chance
	if SPAWN_SCP035 then
		local spawnChance = math.random(1, 100)
		if spawnChance <= 25 then
			local mask = ents.Create("scp_035")
			if IsValid(mask) then
				mask:SetPos(SPAWN_SCP035)
				mask:SetAngles(Angle(0, math.random(0, 360), 0))
				mask:Spawn()
				mask:Activate()
				
				-- Add small physics force
				local phys = mask:GetPhysicsObject()
				if IsValid(phys) then
					phys:Wake()
				end
				
				print("[BREACH] SCP-035 mask spawned successfully (25% chance)")
			else
				print("[BREACH] ERROR: Failed to create SCP-035 mask entity!")
			end
		else
			print("[BREACH] SCP-035 mask spawn skipped (rolled " .. spawnChance .. "%, needed <= 25%)")
		end
	end
	
	// Spawn SCP-1499
	if SPAWN_1499 then
		local item1499 = ents.Create( "weapon_scp_1499" )
		if IsValid( item1499 ) then
			item1499:SetPos( SPAWN_1499 )
			item1499:Spawn()
			WakeEntity( item1499 )
		end
	end
	
	// Spawn SCP Wall Hole
	if SPAWN_WALLHOLE then
		local wallhole = ents.Create( "scp_wall_hole" )
		if IsValid( wallhole ) then
			wallhole:SetPos( SPAWN_WALLHOLE )
			wallhole:Spawn()
		end
	end
	
	// SCP-297 (Wish Machine) - DISABLED to avoid conflict with SCP-294
	// Use br_spawn_scp297 command to manually spawn if needed
	// local scp297 = ents.Create( "scp_297" )
	// if IsValid( scp297 ) then
	//	scp297:SetPos( Vector(94.679100, 3120.276855, -88.759789) )
	//	scp297:SetAngles( Angle(0, 90, 0) )
	//	scp297:Spawn()
	//	print("[BREACH] SCP-297 Wish Machine spawned")
	// end
	
	// OPTYMALIZACJA: Zoptymalizowane wyszukiwanie SCP-294 z cache
	timer.Simple(3, function() // Zwiększono delay dla lepszej stabilności
		local foundSCP294 = false
		local foundCount = 0

		print("[OPTIMIZATION] Searching for SCP-294 models...")

		// Znajdź wszystkie entity na mapie - tylko raz
		for _, ent in pairs(ents.GetAll()) do
			if IsValid(ent) and ent:GetModel() == "models/vinrax/scp294/scp294.mdl" then
				// Stwórz interaktywne entity w tym miejscu
				local scp294 = ents.Create("scp_294")
				if IsValid(scp294) then
					scp294:SetPos(ent:GetPos())
					scp294:SetAngles(ent:GetAngles())
					scp294:Spawn()
					scp294:Activate()

					// Usuń oryginalny model
					ent:Remove()

					foundSCP294 = true
					foundCount = foundCount + 1
					print("[OPTIMIZATION] Found and converted SCP-294 model #" .. foundCount .. " at position: " .. tostring(scp294:GetPos()))
				end
			end
		end

		if not foundSCP294 then
			print("[BREACH] No SCP-294 models found on map. To spawn manually, use: ent_create scp_294")
		else
			print("[OPTIMIZATION] SCP-294 search completed. Found: " .. foundCount .. " models")
		end
	end)
	
	local pos500 = table.Copy( SPAWN_500 )
	
	for i = 1, 2 do
		local item = ents.Create( "item_scp_500" )
		if IsValid( item ) then
			local pos = table.Random( pos500 )
			item:SetPos( pos )
			item:Spawn()
			table.RemoveByValue( pos500, pos )
		end
	end
	
	-- Spawn SCP-018
	local item = ents.Create( "weapon_scp_018" )
	if IsValid( item ) then
		item:SetPos( Vector(1819.275024, 1296.073730, 41.031250) )
		item:Spawn()
	end
	
	-- Spawn SCP-313
	local scp313 = ents.Create( "scp_313" )
	if IsValid( scp313 ) then
		scp313:SetPos( Vector(1901.448975, 145.031250, 53.363686) )
		scp313:SetAngles( Angle(0, 360, 0) ) -- Skierowana do ściany
		scp313:Spawn()
	end
	
	-- Spawn Facility Intercom
	local intercom = ents.Create( "br_intercom" )
	if IsValid( intercom ) then
		intercom:SetPos( Vector(-2505.753662, 3720.031250, 317.261230) )
		intercom:SetAngles( Angle(90, 90, 0) )
		intercom:Spawn()
		print("[BREACH] Facility Intercom spawned")
	end
	
	-- Spawn SCP-207 (Max 3 random bottles)
	if SPAWN_SCP207 and #SPAWN_SCP207 > 0 then
		local pos207 = table.Copy( SPAWN_SCP207 )
		local maxBottles = math.min(3, #pos207) -- Maximum 3 bottles
		
		for i = 1, maxBottles do
			local scp207 = ents.Create( "scp_207" )
			if IsValid( scp207 ) then
				local pos = table.remove( pos207, math.random( 1, #pos207 ) )
				scp207:SetPos( pos )
				scp207:Spawn()
			end
		end
		print("[BREACH] SCP-207 bottles spawned: " .. maxBottles .. " bottles at random locations")
	end
	
	for k, v in pairs( SPAWN_420 ) do
		local item = ents.Create( "item_scp_420j" )
		if IsValid( item ) then
			local pos
			if istable(v) then
				// If 'v' is a table of spawn points, pick one
				pos = table.Random(v)
			else
				// Otherwise, assume 'v' is the spawn point itself
				pos = v
			end
			item:SetPos( pos )
			item:Spawn()
		end
	end
	
	for k, v in pairs( KEYCARDS or {} ) do
		local spawns = table.Copy( v.spawns )
		//local cards = table.Copy( v.ents )
		local dices = {}

		local n = 0
		for _, dice in pairs( v.ents ) do
			local d = {
				min = n,
				max = n + dice[2],
				ent = dice[1]
			}
			
			table.insert( dices, d )
			n = n + dice[2]
		end

		for i = 1, math.min( v.amount, #spawns ) do
			local spawn = table.remove( spawns, math.random( 1, #spawns ) )
			local dice = math.random( 0, n - 1 )
			local ent

			for _, d in pairs( dices ) do
				if d.min <= dice and d.max > dice then
					ent = d.ent
					break
				end
			end

			if ent then
				local keycard = ents.Create( "br_keycard" )
				if IsValid( keycard ) then
					keycard:Spawn()
					keycard:SetPos( spawn )
					keycard:SetKeycardType( ent )
				end
			end
		end
	end
	
	local resps_items = table.Copy( SPAWN_MISCITEMS )
	local resps_melee = table.Copy( SPAWN_MELEEWEPS )
	local resps_medkits = table.Copy( SPAWN_MEDKITS )
	
	for i = 1, 2 do
		local item = ents.Create( "item_medkit" )
		if IsValid( item ) then
			local spawn = table.remove( resps_medkits, math.random( 1, #resps_medkits ) )
			item:Spawn()
			item:SetPos( spawn )
		end
	end

	local item = ents.Create( "item_radio" )
	if IsValid( item ) then
		local spawn = table.remove( resps_items, math.random( 1, #resps_items ) )
		item:Spawn()
		item:SetPos( spawn )
	end
	
	local item = ents.Create( "item_eyedrops" )
	if IsValid( item ) then
		local spawn = table.remove( resps_items, math.random( 1, #resps_items ) )
		item:Spawn()
		item:SetPos( spawn )
	end
	
	local item = ents.Create( "item_snav_300" )
	if IsValid( item ) then
		local spawn = table.remove( resps_items, math.random( 1, #resps_items ) )
		item:Spawn()
		item:SetPos( spawn )
	end
	
	local item = ents.Create( "item_snav_ultimate" )
	if IsValid( item ) then
		local spawn = table.remove( resps_items, math.random( 1, #resps_items ) )
		item:Spawn()
		item:SetPos( spawn )
	end
	
	local item = ents.Create( "item_nvg" )
	if IsValid( item ) then
		local spawn = table.remove( resps_items, math.random( 1, #resps_items ) )
		item:Spawn()
		item:SetPos( spawn )
	end
	
	for i = 1, 2 do
		local item = ents.Create( "weapon_crowbar" )
		if IsValid( item ) then
			local spawn = table.remove( resps_melee, math.random( 1, #resps_melee ) )
			item:Spawn()
			item:SetPos( spawn )
		end
	end
	
	for i, v in ipairs( CCTV ) do
		local cctv = ents.Create( "item_cctv" )

		if IsValid( cctv ) then
			cctv:Spawn()
			cctv:SetPos( v.pos )

			cctv:SetCam( i )

			v.ent = cctv
		end
	end

	// Spawn Kebab Stand only if Cook is in the game
	local hasCook = false
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and ply:GetNClass() == ROLES.ROLE_COOK then
			hasCook = true
			break
		end
	end
	
	if hasCook then
		print("[BREACH] Cook found in game, spawning kebab stand...")
		local kebab_stand = ents.Create( "br_kebab_stand" )
		if IsValid( kebab_stand ) then
			kebab_stand:SetPos( Vector(227.936295, 3185.166016, -87.968750) )
			kebab_stand:SetAngles( Angle(0, 0, 0) )
			kebab_stand:Spawn()
			print("[BREACH] Kebab stand spawned successfully at cafeteria")
		else
			print("[BREACH] ERROR: Failed to create br_kebab_stand entity!")
		end
	else
		print("[BREACH] No Cook in game, skipping kebab stand spawn")
	end


end

function SpawnNTFS(forceChaos)
	if disableNTF then return end

	// Niestandardowe pozycje spawnu dla GOC
	local GOC_SPAWN_POSITIONS = {
		Vector(558.671509, 7106.799316, 2087.195557),
		Vector(555.054871, 6996.205078, 2087.200195),
		Vector(554.845947, 6909.542480, 2087.218262),
		Vector(554.125305, 6822.297852, 2088.832520),
		Vector(405.279938, 6975.074219, 2122.880371)
	}

	// Sprawdź czy są żywi gracze Klasy D przed spawnem Chaos
	local aliveclassd = 0
	for _, ply in pairs(player.GetAll()) do
		if ply:GTeam() == TEAM_CLASSD and ply:Alive() then
			aliveclassd = aliveclassd + 1
		end
	end

	local usechaos = forceChaos or (math.random( 1, 100 ) <= GetConVar("br_ci_percentage"):GetInt())
	
	// Jeśli nie ma żywej Klasy D, wymuś spawn MTF zamiast Chaos
	if usechaos and aliveclassd == 0 then
		usechaos = false
		print("[BREACH] Chaos spawn blocked - no alive Class D personnel")
	end

	local roles = {}
	local plys = {}
	local inuse = {}
	local spawnpos = usechaos and SPAWN_OUTSIDE_CI or SPAWN_OUTSIDE

	for k, v in pairs( ALLCLASSES.support.roles ) do
		if usechaos then
			if v.team == TEAM_CHAOS then
				table.insert( roles, v )
			end
		else
			if v.team == TEAM_GUARD then
				table.insert( roles, v )
			end
		end
	end

	// Zbierz wszystkich dostępnych graczy (spektatorzy i martwi)
	local availablePlayers = {}
	for _, ply in pairs( player.GetAll() ) do
		if (ply:GTeam() == TEAM_SPEC or !ply:Alive()) and ply.ActivePlayer then
			table.insert(availablePlayers, ply)
		end
	end

	// Przypisz graczy do ról (brak wymagania poziomu tylko dla MTF NTF i CI Soldier)
	for k, v in pairs( roles ) do
		plys[v.name] = {}
		inuse[v.name] = 0
		for _, ply in pairs( availablePlayers ) do
			local levelCheck = true
			// Sprawdź wymagania poziomu tylko dla ról innych niż MTF NTF i CI Soldier
			if v.name != ROLES.ROLE_MTFNTF and v.name != ROLES.ROLE_CHAOS then
				levelCheck = ply:GetLevel() >= v.level
			end
			
			if levelCheck and ( v.customcheck and v.customcheck( ply ) or true ) then
				table.insert( plys[v.name], ply )
			end
		end

		if #plys[v.name] < 1 then
			roles[k] = nil
		end
	end

	if #roles < 1 then
		return
	end

	// Spawn pozostałych dostępnych graczy jako MTF/Chaos
	local spawnedCount = 0
	
	for _, ply in pairs(availablePlayers) do
		if #roles > 0 then
			local role = table.Random( roles )
			
			ply:SetupNormal()
			ply:ApplyRoleStats( role )
			
			// Użyj pozycji spawnu lub losowej pozycji w pobliżu jeśli brakuje pozycji
			local spawnIndex = (spawnedCount % #spawnpos) + 1
			local basePos = spawnpos[spawnIndex]
			local offset = Vector(math.random(-100, 100), math.random(-100, 100), 0)
			ply:SetPos( basePos + offset )

			// Dodaj ochronę przed spawn killingiem na 5 sekund
			SetSupportSpawnProtection(ply, 5)

			spawnedCount = spawnedCount + 1
		end
	end

	// Zachowaj dźwiękowy komunikat dla MTF
	if !usechaos and spawnedCount > 0 then
		BroadcastLua( 'surface.PlaySound( "EneteredFacility.ogg" )' )
	end
end

function SpawnGOC()
	// Niestandardowe pozycje spawnu dla GOC
	local GOC_SPAWN_POSITIONS = {
		Vector(558.671509, 7106.799316, 2087.195557),
		Vector(555.054871, 6996.205078, 2087.200195),
		Vector(554.845947, 6909.542480, 2087.218262),
		Vector(554.125305, 6822.297852, 2088.832520),
		Vector(405.279938, 6975.074219, 2122.880371)
	}

	local maxGOC = 5 // Maksymalnie 5 graczy GOC
	local gocRoles = {}
	
	// Zbierz role GOC
	for k, v in pairs( ALLCLASSES.goc.roles ) do
		if v.team == TEAM_GOC then
			table.insert( gocRoles, v )
		end
	end
	
	if #gocRoles < 1 then
		return
	end
	
	// Zbierz wszystkich dostępnych graczy (spektatorzy i martwi)
	local availablePlayers = {}
	for _, ply in pairs( player.GetAll() ) do
		if (ply:GTeam() == TEAM_SPEC or !ply:Alive()) and ply.ActivePlayer then
			table.insert(availablePlayers, ply)
		end
	end
	
	if #availablePlayers < 1 then
		return
	end
	
	// Filtruj graczy według poziomów dla każdej roli GOC
	local qualifiedPlayers = {}
	for _, role in pairs(gocRoles) do
		for _, ply in pairs(availablePlayers) do
			// Sprawdź poziom gracza
			if ply:GetLevel() >= role.level and (role.customcheck and role.customcheck(ply) or true) then
				if !qualifiedPlayers[ply] then
					qualifiedPlayers[ply] = {}
				end
				table.insert(qualifiedPlayers[ply], role)
			end
		end
	end
	
	// Sprawdź czy są jakikolwiek gracze spełniający wymagania
	local hasQualifiedPlayers = false
	for k, v in pairs(qualifiedPlayers) do
		hasQualifiedPlayers = true
		break
	end
	
	if !hasQualifiedPlayers then
		print("[BREACH] No players qualified for GOC roles - spawning MTF instead")
		// Jeśli nikt nie ma poziomu na GOC, spawnuj MTF zamiast tego
		SpawnNTFS()
		return
	end
	
	// Spawn GOC graczy (max 5)
	local gocSpawned = 0
	local usedPlayers = {}
	
	for i = 1, math.min(maxGOC, #availablePlayers) do
		// Znajdź gracza który może być GOC
		local selectedPly = nil
		local selectedRole = nil
		
		for ply, roles in pairs(qualifiedPlayers) do
			if !usedPlayers[ply] and #roles > 0 then
				selectedPly = ply
				selectedRole = table.Random(roles)
				usedPlayers[ply] = true
				break
			end
		end
		
		if !selectedPly then
			// Brak więcej kwalifikujących się graczy
			break
		end
		
		if IsValid(selectedPly) then
			selectedPly:SetupNormal()
			selectedPly:ApplyRoleStats( selectedRole )
			
			// Użyj niestandardowej pozycji spawnu dla GOC
			local spawnPos = GOC_SPAWN_POSITIONS[gocSpawned + 1]
			selectedPly:SetPos( spawnPos )
			
			// Ustaw odpowiedni kąt patrzenia
			local spawnIndex = gocSpawned + 1
			if spawnIndex == 1 then
				selectedPly:SetAngles(Angle(3.855751, 175.663879, 0))
			elseif spawnIndex == 2 then
				selectedPly:SetAngles(Angle(-2.179303, -179.893661, 0))
			elseif spawnIndex == 3 then
				selectedPly:SetAngles(Angle(-2.682222, -179.809799, 0))
			elseif spawnIndex == 4 then
				selectedPly:SetAngles(Angle(-1.676380, 179.603409, 0))
			elseif spawnIndex == 5 then
				selectedPly:SetAngles(Angle(-2.095481, 179.687286, 0))
			end
			
			// Dodaj ochronę przed spawn killingiem na 5 sekund
			SetSupportSpawnProtection(selectedPly, 5)
			
			gocSpawned = gocSpawned + 1
		end
	end
	
	if gocSpawned > 0 then
		print("[BREACH] Spawned " .. gocSpawned .. " GOC players")
		// GOC ma swoją własną wiadomość dźwiękową lub brak
		// BroadcastLua( 'surface.PlaySound( "goc_arrival.ogg" )' )
	else
		print("[BREACH] Could not spawn any GOC - spawning MTF instead")
		// Jeśli nie udało się zrespić żadnego GOC, spawnuj MTF
		SpawnNTFS()
	end
end

SCP914InUse = false
function Use914( ent )
	if SCP914InUse then return false end
	SCP914InUse = true

	if SCP_914_BUTTON and ent:GetPos() != SCP_914_BUTTON then
		for k, v in pairs( ents.FindByClass( "func_door" ) ) do
			if v:GetPos() == SCP_914_DOORS[1] or v:GetPos() == SCP_914_DOORS[2] then
				v:Fire( "Close" )
				timer.Create( "914DoorOpen"..v:EntIndex(), 15, 1, function()
					v:Fire( "Open" )
				end )
			end
		end
	end

	local button = ents.FindByName( SCP_914_STATUS )[1]
	local angle = button:GetAngles().roll
	local mode = 0

	if angle == 45 then
		mode = 1
	elseif	angle == 90 then
		mode = 2
	elseif	angle == 135 then
		mode = 3
	elseif	angle == 180 then
		mode = 4
	end
	
	timer.Create( "SCP914UpgradeEnd", 16, 1, function()
		SCP914InUse = false
	end )

	timer.Create( "SCP914Upgrade", 10, 1, function()
		local items = ents.FindInBox( SCP_914_INTAKE_MINS, SCP_914_INTAKE_MAXS )
		for k, v in pairs( items ) do
			if IsValid( v ) then
				if v.HandleUpgrade then
					v:HandleUpgrade( mode, SCP_914_OUTPUT )
				elseif v.betterone or v.GetBetterOne then
					local item_class
					if v.betterone then item_class = v.betterone end
					if v.GetBetterOne then item_class = v:GetBetterOne( mode ) end

					local item = ents.Create( item_class )
					if IsValid( item ) then
						v:Remove()
						item:SetPos( SCP_914_OUTPUT )
						item:Spawn()
						WakeEntity( item )
					end
				end
			end
		end
	end )

	return true
end

function OpenSCPDoors()
	for k, v in pairs( ents.FindByClass( "func_door" ) ) do
		for k0, v0 in pairs( POS_DOOR ) do
			if ( v:GetPos() == v0 ) then
				v:Fire( "unlock" )
				v:Fire( "open" )
			end
		end
	end
	for k, v in pairs( ents.FindByClass( "func_button" ) ) do
		for k0, v0 in pairs( POS_BUTTON ) do
			if ( v:GetPos() == v0 ) then
				v:Fire( "use" )
			end
		end
	end
	for k, v in pairs( ents.FindByClass( "func_rot_button" ) ) do
		for k0, v0 in pairs( POS_ROT_BUTTON ) do
			if ( v:GetPos() == v0 ) then
				v:Fire( "use" )
			end
		end
	end
end

function GetAlivePlayers()
	local plys = {}
	for k,v in pairs(player.GetAll()) do
		if v:GTeam() != TEAM_SPEC then
			if v:Alive() or v:GetNClass() == ROLES.ROLE_SCP076 then
				table.ForceInsert(plys, v)
			end
		end
	end
	return plys
end

function BroadcastDetection( ply, tab )
	local transmit = { ply }
	local radio = ply:GetWeapon( "item_radio" )

	if radio and radio.Enabled and radio.Channel > 4 then
		local ch = radio.Channel

		for k, v in pairs( player.GetAll() ) do
			if v:GTeam() != TEAM_SCP and v:GTeam() != TEAM_SPEC and v != ply then
				local r = v:GetWeapon( "item_radio" )

				if r and r.Enabled and r.Channel == ch then
					table.insert( transmit, v )
				end
			end
		end
	end

	local info = {}

	for k, v in pairs( tab ) do
		table.insert( info, {
			name = v:GetNClass(),
			pos = v:GetPos() + v:OBBCenter()
		} )
	end

	net.Start( "CameraDetect" )
		net.WriteTable( info )
	net.Send( transmit )
end

function GM:GetFallDamage( ply, speed )
	return ( speed / 6 )
end

function PlayerCount()
	return #player.GetAll()
end

function GM:OnEntityCreated( ent )
	ent:SetShouldPlayPickupSound( false )
end

function GetPlayer(nick)
	for k,v in pairs(player.GetAll()) do
		if v:Nick() == nick then
			return v
		end
	end
	return nil
end

function CreateRagdollPL(victim, attacker, dmgtype)
	if victim:GetGTeam() == TEAM_SPEC then return end
	if not IsValid(victim) then return end

	local rag = ents.Create("prop_ragdoll")
	if not IsValid(rag) then return nil end

	rag:SetPos(victim:GetPos())
	rag:SetModel(victim:GetModel())
	rag:SetAngles(victim:GetAngles())
	rag:SetColor(victim:GetColor())

	rag:Spawn()
	rag:Activate()
	
	// Copy bodygroups from player to ragdoll
	for i = 0, victim:GetNumBodyGroups() - 1 do
		local bodygroup = victim:GetBodygroup(i)
		rag:SetBodygroup(i, bodygroup)
	end
	
	// Copy model scale (for Child D and others)
	local modelScale = victim:GetModelScale()
	if modelScale and modelScale != 1 then
		rag:SetModelScale(modelScale, 0)
	end
	
	// Note: Ragdolls don't support SetPlayerColor, so we skip this
	
	// Copy bone manipulations (for Fat D, Skinny D, etc.)
	timer.Simple(0.1, function()
		if IsValid(rag) and IsValid(victim) then
			// Copy all bone manipulations from player to ragdoll
			for i = 0, victim:GetBoneCount() - 1 do
				local boneName = victim:GetBoneName(i)
				if boneName then
					local boneScale = victim:GetManipulateBoneScale(i)
					local bonePos = victim:GetManipulateBonePosition(i)
					local boneAng = victim:GetManipulateBoneAngles(i)
					
					// Only copy if bone manipulation is not default
					if boneScale != Vector(1, 1, 1) or bonePos != Vector(0, 0, 0) or boneAng != Angle(0, 0, 0) then
						local ragBoneID = rag:LookupBone(boneName)
						if ragBoneID then
							rag:ManipulateBoneScale(ragBoneID, boneScale)
							rag:ManipulateBonePosition(ragBoneID, bonePos)
							rag:ManipulateBoneAngles(ragBoneID, boneAng)
						end
					end
				end
			end
		end
	end)
	
	rag.Info = {}
	rag.Info.CorpseID = rag:GetCreationID()
	rag:SetNWInt( "CorpseID", rag.Info.CorpseID )
	rag.Info.Victim = victim:Nick()
	rag.Info.DamageType = dmgtype
	rag.Info.Time = CurTime()
	
	local group = COLLISION_GROUP_DEBRIS_TRIGGER
	rag:SetCollisionGroup(group)
	timer.Simple( 1, function() if IsValid( rag ) then rag:CollisionRulesChanged() end end )
	timer.Simple( 60, function() if IsValid( rag ) then rag:Remove() end end )
	
	local num = rag:GetPhysicsObjectCount()-1
	local v = victim:GetVelocity() * 0.35
	
	for i=0, num do
		local bone = rag:GetPhysicsObjectNum(i)
		if IsValid(bone) then
		local bp, ba = victim:GetBonePosition(rag:TranslatePhysBoneToBone(i))
		if bp and ba then
			bone:SetPos(bp)
			bone:SetAngles(ba)
		end
		bone:SetVelocity(v * 1.2)
		end
	end
end

function ServerSound( file, ent, filter )
	ent = ent or game.GetWorld()
	if !filter then
		filter = RecipientFilter()
		filter:AddAllPlayers()
	end

	local sound = CreateSound( ent, file, filter )

	return sound
end

inUse = false
function explodeGateA( ply )
	if ply and !isInTable( ply, ents.FindInSphere(POS_EXPLODE_A, 250) ) then return end
	if inUse == true then return end
	if isGateAOpen() then return end
	inUse = true
	
	local filter = RecipientFilter()
	filter:AddAllPlayers()
	local sound = CreateSound( game.GetWorld(), "ambient/alarms/alarm_citizen_loop1.wav", filter )
	sound:SetSoundLevel( 0 )
	
	BroadcastLua( 'surface.PlaySound("radio/franklin1.ogg")' )
	sound:Play()
	sound:ChangeVolume( 0.25 )
	local waitTime = GetConVar( "br_time_explode" ):GetInt()
	local ttime = 0
	PrintMessage( HUD_PRINTTALK, "Time to Gate A explosion: "..waitTime.."s")
	timer.Create( "GateExplode", 1, waitTime, function()
		if ttime > waitTime then return end
		if isGateAOpen() then 
			timer.Destroy( "GateExplode" )
			sound:Stop()
			PrintMessage( HUD_PRINTTALK, "Gate A explosion terminated")
			inUse = false
			return
		end
		
		ttime = ttime + 1
		if ttime % 5 == 0 then PrintMessage( HUD_PRINTTALK, "Time to Gate A explosion: "..waitTime - ttime.."s" ) end
		if ttime + 1 == waitTime then sound:Stop() end
		if ttime == waitTime then
			BroadcastLua( 'surface.PlaySound("ambient/explosions/exp2.wav")' )
			local explosion = ents.Create( "env_explosion" ) // Creating our explosion
			explosion:SetKeyValue( "spawnflags", 210 ) //Setting the key values of the explosion 
			explosion:SetPos( POS_MIDDLE_GATE_A )
			explosion:Spawn()
			explosion:Fire( "explode", "", 0 )
			destroyGate()
			takeDamage( explosion, ply )
			if ply then
				ply:AddExp(100, true)
			end
		end
	end )
end

function takeDamage( ent, ply )
	local dmg = 0
	for k, v in pairs( ents.FindInSphere( POS_MIDDLE_GATE_A, 1000 ) ) do
		if v:IsPlayer() then
			if v:Alive() then
				if v:GTeam() != TEAM_SPEC then
					dmg = ( 1001 - v:GetPos():Distance( POS_MIDDLE_GATE_A ) ) * 10
					if dmg > 0 then 
						v:TakeDamage( dmg, ply or v, ent )
					end
				end
			end
		end
	end
end

function destroyGate()
	if isGateAOpen() then return end
	local doorsEnts = ents.FindInSphere( POS_MIDDLE_GATE_A, 125 )
	for k, v in pairs( doorsEnts ) do
		if v:GetClass() == "prop_dynamic" or v:GetClass() == "func_door" then
			v:Remove()
		end
	end
end

function isGateAOpen()
	local doors = ents.FindInSphere( POS_MIDDLE_GATE_A, 125 )
	for k, v in pairs( doors ) do
		if v:GetClass() == "prop_dynamic" then 
			if isInTable( v:GetPos(), POS_GATE_A_DOORS ) then return false end
		end
	end
	return true
end

function Recontain106( ply )
	if Recontain106Used then
		ply:PrintMessage( HUD_PRINTCENTER, "SCP 106 recontain procedure can be triggered only once per round" )
		return false
	end

	local cage
	for k, v in pairs( ents.GetAll() ) do
		if v:GetPos() == CAGE_DOWN_POS then
			cage = v
			break
		end
	end
	if !cage then
		ply:PrintMessage( HUD_PRINTCENTER, "Power down ELO-IID electromagnet in order to start SCP 106 recontain procedure" )
		return false
	end

	local e = ents.FindByName( SOUND_TRANSMISSION_NAME )[1]
	if e:GetAngles().roll == 0 then
		ply:PrintMessage( HUD_PRINTCENTER, "Enable sound transmission in order to start SCP 106 recontain procedure" )
		return false
	end

	local fplys = ents.FindInBox( CAGE_BOUNDS.MINS, CAGE_BOUNDS.MAXS )
	local plys = {}
	for k, v in pairs( fplys ) do
		if IsValid( v ) and v:IsPlayer() and v:GTeam() != TEAM_SPEC and v:GTeam() != TEAM_SCP then
			table.insert( plys, v )
		end
	end

	if #plys < 1 then
		ply:PrintMessage( HUD_PRINTCENTER, "Living human in cage is required in order to start SCP 106 recontain procedure" )
		return false
	end

	local scps = {}
	for k, v in pairs( player.GetAll() ) do
		if IsValid( v ) and v:GTeam() == TEAM_SCP and v:GetNClass() == ROLES.ROLE_SCP106 then
			table.insert( scps, v )
		end
	end

	if #scps < 1 then
		ply:PrintMessage( HUD_PRINTCENTER, "SCP 106 is already recontained" )
		return false
	end

	Recontain106Used = true

	timer.Simple( 6, function()
		if postround or !Recontain106Used then return end
		for k, v in pairs( plys ) do
			if IsValid( v ) then
				v:Kill()
			end
		end

		for k, v in pairs( scps ) do
			if IsValid( v ) then
				local swep = v:GetActiveWeapon()
				if IsValid( swep ) and swep:GetClass() == "weapon_scp_106" then
					swep:TeleportSequence( CAGE_INSIDE )
				end
			end
		end

		timer.Simple( 11, function()
			if postround or !Recontain106Used then return end
			for k, v in pairs( scps ) do
				if IsValid( v ) then
					v:Kill()
				end
			end
			local eloiid = ents.FindByName( ELO_IID_NAME )[1]
			eloiid:Use( game.GetWorld(), game.GetWorld(), USE_TOGGLE, 1 )
			if IsValid( ply ) then
				ply:PrintMessage(HUD_PRINTTALK, "You've been awarded with 10 points for recontaining SCP 106!")
				ply:AddFrags( 10 )
			end
		end )


	end )

	return true
end

OMEGAEnabled = false
OMEGADoors = false
-- Funkcja sprawdzająca czy gracz może aktywować Omega Warhead
function CanActivateOmegaWarhead( ply )
	-- 1. Sprawdź czy warhead jest włączony
	if GetConVar( "br_enable_warhead" ):GetInt() != 1 then
		return false, "You inserted keycard but nothing happened"
	end

	-- 2. Sprawdź czy dźwignia istnieje i czy nie jest wyłączona (obrócona)
	local remote = ents.FindByName( OMEGA_REMOTE_NAME )[1]
	if IsValid( remote ) and remote:GetAngles().pitch == 180 then
		return false, "OMEGA Warhead has been disabled"
	end

	-- 3. Sprawdź czy zostało więcej niż 10 minut rundy (blokada aktywna gdy za dużo czasu)
	if timer.Exists("RoundTime") then
		local timeLeft = timer.TimeLeft("RoundTime")
		
		if timeLeft > 600 then -- 600 sekund = 10 minut
			local minutes = math.floor(timeLeft / 60)
			local seconds = math.floor(timeLeft % 60)
			return false, string.format("OMEGA Warhead is locked until 10:00 remaining. Current time: %d:%02d", minutes, seconds)
		end
	end

	-- 4. Sprawdź czy gracz może aktywować warhead na podstawie teamów
	local playerTeam = ply:GTeam()
	local playerClass = ply:GetNClass()
	
	-- SCP - całkowity zakaz aktywacji
	if playerTeam == TEAM_SCP then
		return false, "SCP entities cannot activate OMEGA Warhead"
	end
	
	-- MTF/Guard - nie mogą aktywować jeśli w placówce są żywi naukowcy
	if playerTeam == TEAM_GUARD then
		local scientistsInside = {}
		local scientistsOutside = 0
		
		for k, v in pairs(player.GetAll()) do
			if IsValid(v) and v:Alive() and v:GTeam() == TEAM_SCI then
				-- Sprawdź czy naukowiec jest w placówce (nie na zewnątrz)
				if not OUTSIDE_BUFF or not OUTSIDE_BUFF(v:GetPos()) then
					table.insert(scientistsInside, v:Nick())
				else
					scientistsOutside = scientistsOutside + 1
				end
			end
		end
		
		if #scientistsInside > 0 then
			local message = string.format("Cannot detonate OMEGA Warhead! %d scientists still inside facility: %s", 
				#scientistsInside, table.concat(scientistsInside, ", "))
			if scientistsOutside > 0 then
				message = message .. string.format(" (%d already evacuated)", scientistsOutside)
			end
			return false, message
		end
	end
	
	-- Chaos Insurgency - nie mogą aktywować jeśli w placówce są żywi Class-D
	if playerTeam == TEAM_CHAOS then
		local classDInside = {}
		local classDOutside = 0
		
		for k, v in pairs(player.GetAll()) do
			if IsValid(v) and v:Alive() and v:GTeam() == TEAM_CLASSD then
				-- Sprawdź czy Class-D jest w placówce (nie na zewnątrz)
				if not OUTSIDE_BUFF or not OUTSIDE_BUFF(v:GetPos()) then
					table.insert(classDInside, v:Nick())
				else
					classDOutside = classDOutside + 1
				end
			end
		end
		
		if #classDInside > 0 then
			local message = string.format("Cannot detonate OMEGA Warhead! %d Class-D personnel still inside facility: %s", 
				#classDInside, table.concat(classDInside, ", "))
			if classDOutside > 0 then
				message = message .. string.format(" (%d already evacuated)", classDOutside)
			end
			return false, message
		end
	end
	
	-- Class-D - nie mogą aktywować jeśli w placówce są żywi Class-D
	if playerTeam == TEAM_CLASSD then
		local classDInside = {}
		local classDOutside = 0
		
		for k, v in pairs(player.GetAll()) do
			if IsValid(v) and v:Alive() and v:GTeam() == TEAM_CLASSD and v != ply then -- Pomijamy aktywującego gracza
				-- Sprawdź czy Class-D jest w placówce (nie na zewnątrz)
				if not OUTSIDE_BUFF or not OUTSIDE_BUFF(v:GetPos()) then
					table.insert(classDInside, v:Nick())
				else
					classDOutside = classDOutside + 1
				end
			end
		end
		
		if #classDInside > 0 then
			local message = string.format("Cannot detonate OMEGA Warhead! %d other Class-D personnel still inside facility: %s", 
				#classDInside, table.concat(classDInside, ", "))
			if classDOutside > 0 then
				message = message .. string.format(" (%d already evacuated)", classDOutside)
			end
			return false, message
		end
	end
	
	-- Scientists - nie mogą aktywować jeśli w placówce są żywi naukowcy
	if playerTeam == TEAM_SCI then
		local scientistsInside = {}
		local scientistsOutside = 0
		
		for k, v in pairs(player.GetAll()) do
			if IsValid(v) and v:Alive() and v:GTeam() == TEAM_SCI and v != ply then -- Pomijamy aktywującego gracza
				-- Sprawdź czy naukowiec jest w placówce (nie na zewnątrz)
				if not OUTSIDE_BUFF or not OUTSIDE_BUFF(v:GetPos()) then
					table.insert(scientistsInside, v:Nick())
				else
					scientistsOutside = scientistsOutside + 1
				end
			end
		end
		
		if #scientistsInside > 0 then
			local message = string.format("Cannot detonate OMEGA Warhead! %d other scientists still inside facility: %s", 
				#scientistsInside, table.concat(scientistsInside, ", "))
			if scientistsOutside > 0 then
				message = message .. string.format(" (%d already evacuated)", scientistsOutside)
			end
			return false, message
		end
	end
	
	-- Wszystkie warunki spełnione - można aktywować warhead
	local playerTeam = ply:GTeam()
	local successMessage = "OMEGA Warhead activation authorized"
	
	if playerTeam == TEAM_GUARD then
		successMessage = "All scientists evacuated. OMEGA Warhead activation authorized"
	elseif playerTeam == TEAM_GOC then
		successMessage = "OMEGA Warhead activation authorized"
	elseif playerTeam == TEAM_CHAOS then
		successMessage = "All Class-D personnel evacuated. OMEGA Warhead activation authorized"
	elseif playerTeam == TEAM_CLASSD then
		successMessage = "All other Class-D personnel evacuated. OMEGA Warhead activation authorized"
	elseif playerTeam == TEAM_SCI then
		successMessage = "All other scientists evacuated. OMEGA Warhead activation authorized"
	end
	
	return true, successMessage
end

function OMEGAWarhead( ply )
	if OMEGAEnabled then return end

	-- Sprawdź wszystkie warunki aktywacji
	local canActivate, message = CanActivateOmegaWarhead( ply )
	if not canActivate then
		ply:PrintMessage( HUD_PRINTCENTER, message )
		return
	end
	
	-- Wyświetl komunikat sukcesu
	ply:PrintMessage( HUD_PRINTCENTER, message )
	PrintMessage( HUD_PRINTTALK, ply:Nick() .. " activated OMEGA Warhead!" )

	OMEGAEnabled = true

	//local alarm = ServerSound( "warhead/alarm.ogg" )
	//alarm:SetSoundLevel( 0 )
	//alarm:Play()
	net.Start( "SendSound" )
		net.WriteInt( 1, 2 )
		net.WriteString( "warhead/alarm.ogg" )
	net.Broadcast()

	timer.Create( "omega_announcement", 3, 1, function()
		//local announcement = ServerSound( "warhead/announcement.ogg" )
		//announcement:SetSoundLevel( 0 )
		//announcement:Play()
		net.Start( "SendSound" )
			net.WriteInt( 1, 2 )
			net.WriteString( "warhead/announcement.ogg" )
		net.Broadcast()

		timer.Create( "omega_delay", 11, 1, function()
			for k, v in pairs( ents.FindByClass( "func_door" ) ) do
				if IsInTolerance( OMEGA_GATE_A_DOORS[1], v:GetPos(), 100 ) or IsInTolerance( OMEGA_GATE_A_DOORS[2], v:GetPos(), 100 ) then
					v:Fire( "Unlock" )
					v:Fire( "Open" )
					v:Fire( "Lock" )
				end
			end

			OMEGADoors = true

			//local siren = ServerSound( "warhead/siren.ogg" )
			//siren:SetSoundLevel( 0 )
			//siren:Play()
			net.Start( "SendSound" )
				net.WriteInt( 1, 2 )
				net.WriteString( "warhead/siren.ogg" )
			net.Broadcast()
			timer.Create( "omega_alarm", 12, 5, function()
				//siren = ServerSound( "warhead/siren.ogg" )
				//siren:SetSoundLevel( 0 )
				//siren:Play()
				net.Start( "SendSound" )
					net.WriteInt( 1, 2 )
					net.WriteString( "warhead/siren.ogg" )
				net.Broadcast()
			end )

			// OPTYMALIZACJA: Sprawdzaj co 3 sekundy zamiast co sekundę
			local checkCount = 0
			local maxChecks = 30 // 30 sprawdzeń co 3 sekundy = 90 sekund

			local function OptimizedOmegaCheck()
				checkCount = checkCount + 1

				local remote_check = ents.FindByName( OMEGA_REMOTE_NAME )[1]
				if (IsValid( remote_check ) and remote_check:GetAngles().pitch == 180) or !OMEGAEnabled then
					WarheadDisabled( siren )
					return // Early exit
				end

				if checkCount < maxChecks then
					timer.Simple(3, OptimizedOmegaCheck) // Co 3 sekundy zamiast co sekundę
				end
			end

			OptimizedOmegaCheck() // Rozpocznij sprawdzanie
		end )

		timer.Create( "omega_detonation", 90, 1, function()
			//local boom = ServerSound( "warhead/explosion.ogg" )
			//boom:SetSoundLevel( 0 )
			//boom:Play()
			net.Start( "SendSound" )
				net.WriteInt( 1, 2 )
				net.WriteString( "warhead/explosion.ogg" )
			net.Broadcast()
			for k, v in pairs( player.GetAll() ) do
				v:Kill()
			end
		end )
	end )
end

function WarheadDisabled( siren )
	OMEGAEnabled = false
	OMEGADoors = false

	//if siren then
		//siren:Stop()
	//end
	net.Start( "SendSound" )
		net.WriteInt( 0, 2 )
		net.WriteString( "warhead/siren.ogg" )
	net.Broadcast()

	if timer.Exists( "omega_check" ) then timer.Remove( "omega_check" ) end
	if timer.Exists( "omega_alarm" ) then timer.Remove( "omega_alarm" ) end
	if timer.Exists( "omega_detonation" ) then timer.Remove( "omega_detonation" ) end
	
	for k, v in pairs( ents.FindByClass( "func_door" ) ) do
		if IsInTolerance( OMEGA_GATE_A_DOORS[1], v:GetPos(), 100 ) or IsInTolerance( OMEGA_GATE_A_DOORS[2], v:GetPos(), 100 ) then
			v:Fire( "Unlock" )
			v:Fire( "Close" )
		end
	end
end

function GM:BreachSCPDamage( ply, ent, dmg )
	if IsValid( ply ) and IsValid( ent ) then
		if ent:GetClass() == "func_breakable" then
			ent:TakeDamage( dmg, ply, ply )
			return true
		end
	end
end

function isInTable( element, tab )
	for k, v in pairs( tab ) do
		if v == element then return true end
	end
	return false
end

function DARK()
    -- Ustawienie normalnego oświetlenia zamiast jasnego 'a'
    engine.LightStyle( 0, "m" )  -- 'm' = normalne oświetlenie zamiast 'a' = maksymalna jasność
    BroadcastLua('render.RedownloadAllLightmaps(true)')
    BroadcastLua('RunConsoleCommand("mat_specular", 0)')  -- mat_specular na 0 dla SCP: Breach
end

-- Funkcja przywracająca normalne ustawienia renderowania
function RestoreNormalLighting()
    engine.LightStyle( 0, "m" )  -- Normalne oświetlenie
    BroadcastLua('render.RedownloadAllLightmaps(true)')
    BroadcastLua('RunConsoleCommand("mat_specular", 0)')  -- mat_specular na 0 dla SCP: Breach
    BroadcastLua('RunConsoleCommand("mat_bloom_scalefactor_scalar", 1)')
    print("[BREACH] Przywrócono normalne ustawienia oświetlenia mapy")
end

-- Komenda dla administratorów do ręcznego przywracania normalnego oświetlenia
concommand.Add("br_fix_lighting", function(ply, cmd, args)
    if IsValid(ply) and !ply:IsAdmin() then
        ply:PrintMessage(HUD_PRINTTALK, "[BREACH] Tylko administratorzy mogą używać tej komendy!")
        return
    end
    
    RestoreNormalLighting()
    
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTTALK, "[BREACH] Przywrócono normalne oświetlenie mapy")
    end
end)

// NAPRAWA PROBLEMU Z MAP_LOADED
hook.Add("InitPostEntity", "BreachMapLoadedEmergencyFix", function()
    -- Przywróć normalne ustawienia oświetlenia po załadowaniu mapy
    timer.Simple(1, function()
        RestoreNormalLighting()
    end)
    
    timer.Simple(2, function()
        if not MAP_LOADED then
            print("[BREACH FIX] UWAGA: MAP_LOADED = false! Wymuszam true dla mapy: " .. game.GetMap())
            MAP_LOADED = true
        end
        
        -- Inicjalizuj zmienne globalne jeśli to pierwsza runda
        if rounds == -1 then
            print("[BREACH FIX] Inicjalizacja zmiennych dla pierwszej rundy")
            itemsSpawned = false
            gamestarted = false
            preparing = false
            postround = false
        end
    end)
end)

// Usunięto nadpisywanie RoundRestart - może powodować problemy

print("[BREACH] Załadowano awaryjną naprawę systemu rund")

// Hook blokujący obrażenia dla ammo kitów CW2.0
hook.Add("EntityTakeDamage", "BR_BlockAmmoKitDamage", function(target, dmginfo)
	if not IsValid(target) then return end
	
	local class = target:GetClass()
	// Blokuj obrażenia dla wszystkich ammo kitów CW2.0
	if string.StartWith(class, "cw_ammo_") then
		// Całkowicie anuluj obrażenia
		dmginfo:SetDamage(0)
		dmginfo:ScaleDamage(0)
		return true // Blokuj dalsze przetwarzanie
	end
end)

print("[BREACH] Załadowano ochronę ammo kitów przed eksplozją")

// Debug command to spawn kebab stand
concommand.Add("br_spawn_kebab", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	// Remove existing kebab stands
	for _, ent in pairs( ents.FindByClass("br_kebab_stand") ) do
		if IsValid(ent) then
			ent:Remove()
		end
	end
	
	// Spawn new kebab stand
	local kebab_stand = ents.Create( "br_kebab_stand" )
	if IsValid( kebab_stand ) then
		kebab_stand:SetPos( Vector(227.936295, 3185.166016, -87.968750) )
		kebab_stand:SetAngles( Angle(0, 0, 0) )
		kebab_stand:Spawn()
		ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] Kebab stand spawned at cafeteria")
		print("[BREACH ADMIN] " .. ply:Nick() .. " spawned kebab stand")
	else
		ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] ERROR: Failed to spawn kebab stand!")
		print("[BREACH ERROR] Failed to create br_kebab_stand entity for " .. ply:Nick())
	end
end)

// Test command to check position
concommand.Add("br_test_pos", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	// Spawn test prop
	local test_prop = ents.Create( "prop_physics" )
	if IsValid( test_prop ) then
		test_prop:SetModel("models/props_c17/oildrum001.mdl")
		test_prop:SetPos( Vector(227.936295, 3185.166016, -87.968750) )
		test_prop:SetAngles( Angle(0, 0, 0) )
		test_prop:Spawn()
		ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] Test prop spawned at kebab position")
	else
		ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] ERROR: Failed to spawn test prop!")
	end
end)

// Test command to spawn kebab meat
concommand.Add("br_test_meat", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	// Spawn kebab meat at player position
	local kebab_meat = ents.Create( "br_kebab_meat" )
	if IsValid( kebab_meat ) then
		kebab_meat:SetPos( ply:GetPos() + ply:GetForward() * 50 + Vector(0,0,20) )
		kebab_meat:SetAngles( ply:GetAngles() )
		kebab_meat:Spawn()
		ply:PrintMessage(HUD_PRINTTALK, "[BREACH] Spawned kebab meat")
	end
end)

// SCP-294 admin commands
concommand.Add("br_spawn_scp294", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	local scp294 = ents.Create("scp_294")
	if IsValid(scp294) then
		scp294:SetPos(ply:GetPos() + ply:GetForward() * 100)
		scp294:SetAngles(ply:GetAngles())
		scp294:Spawn()
		scp294:Activate()
		ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] Spawned SCP-294 Coffee Machine")
	end
end)

concommand.Add("br_find_scp294", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	local found = 0
	for _, ent in pairs(ents.GetAll()) do
		if IsValid(ent) and ent:GetModel() == "models/vinrax/scp294/scp294.mdl" then
			found = found + 1
			ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] Found model at: " .. tostring(ent:GetPos()))
		end
	end
	
	if found == 0 then
		ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] No SCP-294 models found on this map")
	else
		ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] Found " .. found .. " SCP-294 models")
	end
end)

concommand.Add("br_convert_scp294", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	local converted = 0
	for _, ent in pairs(ents.GetAll()) do
		if IsValid(ent) and ent:GetModel() == "models/vinrax/scp294/scp294.mdl" then
			// Create interactive entity
			local scp294 = ents.Create("scp_294")
			if IsValid(scp294) then
				scp294:SetPos(ent:GetPos())
				scp294:SetAngles(ent:GetAngles())
				scp294:Spawn()
				scp294:Activate()
				
				// Remove original model
				ent:Remove()
				converted = converted + 1
			end
		end
	end
	
	ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] Converted " .. converted .. " SCP-294 models to interactive entities")
end)

-- Komenda do spawnowania SCP-035 maski
concommand.Add("br_spawn_scp035", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	local mask = ents.Create("scp_035")
	if IsValid(mask) then
		mask:SetPos(ply:GetPos() + ply:GetForward() * 100)
		mask:SetAngles(ply:GetAngles())
		mask:Spawn()
		mask:Activate()
		
		ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] SCP-035 mask spawned")
		print("[ADMIN] " .. ply:Nick() .. " spawned SCP-035 mask")
	end
end)

-- Komenda do spawnowania interkomu
concommand.Add("br_spawn_intercom", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	local intercom = ents.Create("br_intercom")
	if IsValid(intercom) then
		intercom:SetPos(ply:GetPos() + ply:GetForward() * 100)
		intercom:SetAngles(ply:GetAngles())
		intercom:Spawn()
		
		ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] Facility Intercom spawned")
		print("[ADMIN] " .. ply:Nick() .. " spawned Facility Intercom")
	end
end)

-- Komenda do testowania interkomu
concommand.Add("br_test_intercom", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	-- Broadcast test message to all players
	for _, v in pairs(player.GetAll()) do
		if IsValid(v) and v:Alive() and v:GTeam() != TEAM_SPEC then
			v:PrintMessage(HUD_PRINTTALK, "[FACILITY INTERCOM] *** TEST TRANSMISSION ***")
			v:PrintMessage(HUD_PRINTTALK, "[FACILITY INTERCOM] This is a test of the facility intercom system.")
			v:PrintMessage(HUD_PRINTTALK, "[FACILITY INTERCOM] *** END TEST ***")
		end
	end
	
	ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] Intercom test broadcast sent")
	print("[ADMIN] " .. ply:Nick() .. " sent intercom test broadcast")
end)

-- Komenda do spawnowania SCP-268
concommand.Add("br_spawn_scp268", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	local scp268 = ents.Create("item_scp_268")
	if IsValid(scp268) then
		scp268:SetPos(ply:GetPos() + ply:GetForward() * 100 + Vector(0, 0, 20))
		scp268:SetAngles(ply:GetAngles())
		scp268:Spawn()
		scp268:Activate()
		
		ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] SCP-268 (Berret of Invisibility) spawned")
		print("[ADMIN] " .. ply:Nick() .. " spawned SCP-268")
	end
end)

-- Komenda do dania graczowi SCP-268
concommand.Add("br_give_scp268", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	
	local target = ply
	if args[1] then
		target = nil
		for _, v in pairs(player.GetAll()) do
			if string.find(string.lower(v:Nick()), string.lower(args[1])) then
				target = v
				break
			end
		end
		
		if not IsValid(target) then
			ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] Player not found: " .. args[1])
			return
		end
	end
	
	if target:HasWeapon("item_scp_268") then
		ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] " .. target:Nick() .. " already has SCP-268")
		return
	end
	
	target:Give("item_scp_268")
	ply:PrintMessage(HUD_PRINTTALK, "[ADMIN] Gave SCP-268 to " .. target:Nick())
	target:PrintMessage(HUD_PRINTTALK, "[ADMIN] You received SCP-268 - The Berret of Invisibility")
	print("[ADMIN] " .. ply:Nick() .. " gave SCP-268 to " .. target:Nick())
end)

