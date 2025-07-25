/*include("shared.lua")
include("gteams.lua")
include("fonts.lua")
include("class_breach.lua")
include("classes.lua")
include("cl_classmenu.lua")
include("sh_player.lua")
include("cl_mtfmenu.lua")
include("cl_scoreboard.lua")
include( "cl_sounds.lua" )
include( "cl_targetid.lua" )
include( "cl_headbob.lua" )
include( "cl_font.lua" )
include( "ulx.lua" )
include( "cl_minigames.lua" )
include( "cl_eq.lua" )*/

SAVEDIDS = {}
lastidcheck = 0
function AddToIDS(ply)
	if lastidcheck > CurTime() then return end
	local sid = nil
	local wep = ply:GetActiveWeapon()
	if not ply.GetNClass or not ply.GetLastRole then
		player_manager.RunClass( ply, "SetupDataTables" )
	end
	if ply:GTeam() == TEAM_SCP then
		if ply:GetNClass() == ROLES.ROLE_SCP9571 then
			sid = ply:GetLastRole()
			if sid == "" then sid = nil end
		else
			sid = ply:GetNClass()
		end
	else
		if IsValid(wep) then
			if wep:GetClass() == "br_id" then
				sid = ply:GetNClass()
			end
		end
	end
	if sid == ROLES.ROLE_CHAOSSPY then
		if (LocalPlayer():GTeam() == TEAM_SCI) or (LocalPlayer():GTeam() == TEAM_GUARD) or (LocalPlayer():GTeam() == TEAM_GOC) then
			sid = ROLES.ROLE_MTFGUARD
		end
	end
	for k,v in pairs(SAVEDIDS) do
		if v.pl == ply then
			if v.id == sid then
				lastidcheck = CurTime() + 0.5
				return
			end
		end
	end
	table.ForceInsert(SAVEDIDS, {pl = ply, id = sid})
	
	// messaging
	if sid == nil then
		sid = "unknown id"
	else
		sid = "id: " .. sid
	end
	-- local sname = "Added new id: " .. ply:Nick() .. " with " .. sid
	-- print(sname)
	lastidcheck = CurTime() + 0.7
end

--buttonstatus = "rough"

clang = nil
cwlang = nil

-- local files, dirs = file.Find(GM.FolderName .. "/gamemode/languages/*.lua", "LUA" )
-- for k,v in pairs(files) do
-- 	local path = "languages/"..v
-- 	if string.Right(v, 3) == "lua" and string.Left(v, 3) != "wep" then
-- 		include( path )
-- 		print("Loading language: " .. path)
-- 	end
-- end

-- local files, dirs = file.Find(GM.FolderName .. "/gamemode/languages/wep_*.lua", "LUA" )
-- for k,v in pairs(files) do
-- 	local path = "languages/"..v
-- 	if string.Right(v, 3) == "lua" then
-- 		include( path )
-- 		print("Loading weapon lang file: " .. path)
-- 	end
-- end

-- Wymuś angielski język i zablokuj zmianę
langtouse = "english"
CreateClientConVar( "cvar_br_language", "english", true, false )
GetConVar( "cvar_br_language" ):SetString( "english" )

local sv_lang = GetConVar( "br_defaultlanguage" )
if sv_lang then
	local sv_str = sv_lang:GetString()
	if ALLLANGUAGES[sv_str] and WEPLANG[sv_str] then
		GetConVar( "cvar_br_language" ):SetString( sv_str )
		langtouse = sv_str
	end
end

-- Zablokowano callback zmiany języka
cvars.AddChangeCallback( "cvar_br_language", function( convar_name, value_old, value_new )
	-- Wymuś powrót do angielskiego
	langtouse = "english"
	GetConVar( "cvar_br_language" ):SetString( "english" )
	LoadLang( langtouse )
end )

-- Zablokowano komendę br_language
concommand.Add( "br_language", function( ply, cmd, args )
	-- Komenda zablokowana - język wymuszony na angielski
	print("Language change is disabled. English is enforced.")
end, function( cmd, args )
	args = string.Trim( args )
	args = string.lower( args )

	local tab = {}

	for k, v in pairs( ALLLANGUAGES ) do
		if string.find( string.lower( k ), args ) then
			table.insert( tab, "br_language "..k )
		end
	end

	return tab
end, "Sets language", FCVAR_ARCHIVE )

hudScale = CreateClientConVar( "br_hud_scale", 1, true, false ):GetFloat()

cvars.AddChangeCallback( "br_hud_scale", function( convar_name, value_old, value_new )
	local newScale = tonumber(value_new)
	if newScale > 1 then newScale = 1 end
	if newScale < 0.1 then newScale = 0.1 end
	hudScale = newScale
end )

-- Client-side HUD selection - forced to classic HUD
CreateClientConVar( "br_hud", "2", true, false, "HUD style - locked to classic HUD" )

print("langtouse:")
print(langtouse)

//print("Alllangs:")
//PrintTable(ALLLANGUAGES)

function AddTables( tab1, tab2 )
	for k, v in pairs( tab2 ) do
		if tab1[k] and istable( v ) then
			AddTables( tab1[k], v )
		else
			tab1[k] = v
		end
	end
end

function LoadLang( lang )
	local finallang = table.Copy( ALLLANGUAGES.english )
	local ltu = {}
	if ALLLANGUAGES[lang] then
		ltu = table.Copy( ALLLANGUAGES[lang] )
	end
	AddTables( finallang, ltu )
	clang = finallang

	local finalweplang = table.Copy( WEPLANG.english )
	local wltu = {}
	if WEPLANG[lang] then
		wltu = WEPLANG[lang]
	else
		wltu = table.Copy( WEPLANG.english )
	end
	AddTables( finalweplang, wltu )
	cwlang = finalweplang
end

LoadLang( langtouse )

--mapfile = "mapconfigs/" .. game.GetMap() .. ".lua"
--include(mapfile)

include("cl_hud.lua")
include("cl_hud_new.lua")
include("cl_hud_custom.lua")
include("cl_kill_notifications.lua")
include("cl_vest_hud.lua")
include("cl_settings_menu.lua")
include("cl_deathcard.lua")
include("cl_fps_ping_display.lua")
include("cl_door_access_hud.lua")
include("cl_weapon_damage_menu.lua")
--include( "cl_splash.lua" )
include("cl_bomber_lottery.lua")

RADIO4SOUNDSHC = {
	{"chatter1", 39},
	{"chatter2", 72},
	{"chatter4", 12},
	{"franklin1", 8},
	{"franklin2", 13},
	{"franklin3", 12},
	{"franklin4", 19},
	{"ohgod", 25}
}

RADIO4SOUNDS = table.Copy(RADIO4SOUNDSHC)

disablehud = false
livecolors = false

preparing = false
postround = false

function DropCurrentVest()
	if LocalPlayer():Alive() and LocalPlayer():GTeam() != TEAM_SPEC then
		net.Start("DropCurrentVest")
		net.SendToServer()
	end
end

concommand.Add( "br_spectate", function( ply, cmd, args )
	net.Start("SpectateMode")
	net.SendToServer()
end )

concommand.Add( "br_recheck_premium", function( ply, cmd, args )
	if ply:IsSuperAdmin() then
		net.Start("RecheckPremium")
		net.SendToServer()
	end
end )

concommand.Add( "br_punish_cancel", function( ply, cmd, args )
	if ply:IsSuperAdmin() then
		net.Start("CancelPunish")
		net.SendToServer()
	end
end )

concommand.Add( "br_roundrestart_cl", function( ply, cmd, args )
	if ply:IsSuperAdmin() then
		net.Start("RoundRestart")
		net.SendToServer()
	end
end )

wantClear = false
tUse = 0

concommand.Add( "br_clear_stats", function( ply, cmd, args )
	if ply:IsSuperAdmin() then
		if tUse < CurTime() and wantClear then wantClear = false print("Last request timed out") end
		if #args > 0 then
			print( "Sending request to server..." )
			net.Start( "ClearData" )
				net.WriteString( tostring( args[1] ) )
			net.SendToServer()
		else
			if !wantClear then
				print( "Are you sure to clear players all data? Write again to confirm (this operation cannot be undone)" )
				wantClear = true
				tUse = CurTime() + 10
			else
				wantClear = false
				print( "Sending request to server..." )
				net.Start( "ClearData" )
					net.WriteString( "&ALL" )
				net.SendToServer()
			end
		end
	end
end )

concommand.Add( "br_restart_game", function( ply, cmd, args )
	if ply:IsSuperAdmin() then
		net.Start("Restart")
		net.SendToServer()
	end
end )

concommand.Add( "br_admin_mode", function( ply, cmd, args )
	if ply:IsSuperAdmin() then
		net.Start("AdminMode")
		net.SendToServer()
	end
end )

concommand.Add( "br_dropvest", function( ply, cmd, args )
	DropCurrentVest()
end )

concommand.Add( "br_disableallhud", function( ply, cmd, args )
	disablehud = !disablehud
end )

-- HUD switching command
concommand.Add( "br_hud_switch", function( ply, cmd, args )
	local hudVar = GetConVar("br_hud")
	if !hudVar then
		chat.AddText(Color(255, 100, 100), "[HUD] ", Color(255, 255, 255), "HUD system not loaded yet!")
		return
	end
	
	local currentHUD = hudVar:GetInt()
	local newHUD = currentHUD + 1
	if newHUD > 3 then newHUD = 1 end
	
	hudVar:SetInt(newHUD)
	
	local hudNames = {
		[1] = "New HUD (Modern)",
		[2] = "Classic HUD (Original)",
		[3] = "Custom HUD (Minimalist)"
	}
	
	chat.AddText(Color(100, 255, 100), "[HUD] ", Color(255, 255, 255), "Switched to: " .. hudNames[newHUD])
end )

concommand.Add( "br_livecolors", function( ply, cmd, args )
	if livecolors then
		livecolors = false
		chat.AddText("livecolors disabled")
	else
		livecolors = true
		chat.AddText("livecolors enabled")
	end
end )

concommand.Add( "br_weapon_info", function( ply, cmd, args )
	local wep = ply:GetActiveWeapon()
	if IsValid( wep ) then
		print( "Weapon name: "..wep:GetClass() )
		if wep.Damage_Orig then print( "Weapon original damage: "..wep.Damage_Orig ) end
		if wep.DamageMult then print( "Weapon damage multiplier: "..wep.DamageMult ) end
		if wep.DamageMult then print( "Weapon final damage: "..wep.Damage ) end
	end
end )
gamestarted = false
cltime = 0
drawinfodelete = 0
shoulddrawinfo = false
drawendmsg = nil
timefromround = 0

-- Timer Credits usunięty - wyłączono wyświetlanie komunikatów o autorze

-- Heartbeat sound disabled
-- timer.Create("HeartbeatSound", 2, 0, function()
-- 	if not LocalPlayer().Alive then return end
-- 	if LocalPlayer():Alive() and LocalPlayer():GTeam() != TEAM_SPEC then
-- 		if LocalPlayer():Health() < 30 then
-- 			LocalPlayer():EmitSound("heartbeat.ogg")
-- 		end
-- 	end
-- end)

function OnUseEyedrops(ply) end

function StartTime()
	timer.Destroy("UpdateTime")
	timer.Create("UpdateTime", 1, 0, function()
		if cltime > 0 then
			cltime = cltime - 1
		end
	end)
end

endinformation = {}

/*net.Receive( "Update914B", function( len )
	local sstatus = net.ReadInt(6)
	if sstatus == 0 then
		buttonstatus = "rough"
	elseif sstatus == 1 then
		buttonstatus = "coarse"
	elseif sstatus == 2 then
		buttonstatus = "1:1"
	elseif sstatus == 3 then
		buttonstatus = "fine"
	elseif sstatus == 4 then
		buttonstatus = "very fine"
	end
end)*/

net.Receive( "UpdateTime", function( len )
	cltime = tonumber(net.ReadString())
	StartTime()
end)

net.Receive( "UpdateKeycard", function( len )
	local keycard = LocalPlayer():GetWeapon( "br_keycard" )
	if IsValid( keycard ) and keycard.Think then
		keycard:Think()
	end
end )

net.Receive( "OnEscaped", function( len )
	local nri = net.ReadInt(4)
	shoulddrawescape = nri
	esctime = CurTime() - timefromround
	lastescapegot = CurTime() + 20
	StartEndSound()
end)

net.Receive( "ForcePlaySound", function( len )
	local sound = net.ReadString()
	surface.PlaySound(sound)
end)

net.Receive( "UpdateRoundType", function( len )
	roundtype = net.ReadString()
	print("Current roundtype: " .. roundtype)
end)

net.Receive( "SendRoundInfo", function( len )
	local infos = net.ReadTable()
	endinformation = {
		string.Replace( clang.lang_pldied, "{num}", infos.deaths ),
		string.Replace( clang.lang_descaped, "{num}", infos.descaped ),
		string.Replace( clang.lang_sescaped, "{num}", infos.sescaped ),
		string.Replace( clang.lang_rescaped, "{num}", infos.rescaped ),
		string.Replace( clang.lang_dcaptured, "{num}", infos.dcaptured ),
		string.Replace( clang.lang_rescorted, "{num}", infos.rescorted ),
		string.Replace( clang.lang_teleported, "{num}", infos.teleported ),
		string.Replace( clang.lang_snapped, "{num}", infos.snapped ),
		string.Replace( clang.lang_zombies, "{num}", infos.zombies )
	}
	if infos.secretf == true then
		table.ForceInsert(endinformation, clang.lang_secret_found)
	else
		table.ForceInsert(endinformation, clang.lang_secret_nfound)
	end
end)

net.Receive( "RolesSelected", function( len )
	drawinfodelete = CurTime() + 25
	shoulddrawinfo = true
end)

net.Receive( "PrepStart", function( len )
	cltime = net.ReadInt(8)
	postround = false
	preparing = true
	chat.AddText(string.Replace( clang.preparing,  "{num}", cltime ))
	StartTime()
	drawendmsg = nil
	hook457delete = CurTime() + 0.5
	hook.Add("Tick", "Stop457Sounds", function()
		if hook457delete != nil then
			if hook457delete < CurTime() then
				hook457delete = nil
				hook.Remove("Tick", "Stop457Sounds")
			end
			if LocalPlayer():GetNClass() == ROLE_SCP457 then
				RunConsoleCommand("stopsound")
			end
		end
	end)
	timer.Destroy("SoundsOnRoundStart")
	timer.Create("SoundsOnRoundStart", 1, 1, SoundsOnRoundStart)
	timefromround = CurTime() + 10
	RADIO4SOUNDS = table.Copy(RADIO4SOUNDSHC)
	SAVEDIDS = {}
end)

net.Receive( "RoundStart", function( len )
	preparing = false
	cltime = net.ReadInt(12)
	chat.AddText(clang.round)
	StartTime()
	drawendmsg = nil
end)

net.Receive( "PostStart", function( len )
	postround = true
	cltime = net.ReadInt(6)
	win = net.ReadInt(4)
	drawendmsg = win
	StartTime()
end)

net.Receive( "TranslatedMessage", function( len )
	local msg = net.ReadString()
	//local center = net.ReadBool()

	//print( msg )
	local color = nil
	local nmsg, cr, cg, cb = string.match( msg, "(.+)%#(%d+)%,(%d+)%,(%d+)$" )
	if nmsg and cr and cg and cb then
		msg = nmsg
		color = Color( cr, cg, cb )
	end

	local name, func = string.match( msg, "^(.+)%$(.+)" )
	
	if name and func then
		local args = {}

		for v in string.gmatch( func, "%w+" ) do
			table.insert( args, v )
			//print( "splitted:", v )
		end

		local translated = clang.NRegistry[name] or string.format( clang.NFailed, name )
		if color then
			chat.AddText( color, string.format( translated, unpack( args ) ) )
		else
			chat.AddText( string.format( translated, unpack( args ) ) )
		end
	else
		local translated = clang.NRegistry[msg] or string.format( clang.NFailed, msg )
		if color then
			chat.AddText( color, translated )
		else
			chat.AddText( translated )
		end
	end
end )

net.Receive( "CameraDetect", function( len )
	local tab = net.ReadTable()

	for i, v in ipairs( tab ) do
		table.insert( SCPMarkers, { time = CurTime() + 7.5, data = v } )
	end
end )

hook.Add( "OnPlayerChat", "CheckChatFunctions", function( ply, strText, bTeam, bDead )
	strText = string.lower( strText )

	if ( strText == "dropvest" ) then
		if ply == LocalPlayer() then
			DropCurrentVest()
		end
		return true
	end
end)

// Blinking system

blinkHUDTime = 0
btime = 0
blink_end = 0
blink = false

local dishudnf = false
local wasdisabled = false

function DisableHUDNextFrame()
	dishudnf = true
end

function CLTick()
	if postround == false and isnumber(drawendmsg) then
		drawendmsg = nil
	end

	if clang == nil then
		clang = english
	end

	if cwlang == nil then
		cwlang = english
	end

	if blinkHUDTime >= 0 then 
		blinkHUDTime = btime - CurTime()
	end

	if blinkHUDTime < 0 then blinkHUDTime = 0 end

	if dishudnf then
		if !disablehud then
			wasdisabled = disablehud
			disablehud = true
		end

		dishudnf = false
	elseif disablehud and wasdisabled == false then
		disablehud = false
	end

	if shoulddrawinfo then
		if CurTime() > drawinfodelete then
			shoulddrawinfo = false
			drawinfodelete = 0
		end
	end

	if CurTime() > blink_end then
		blink = false
	end
end
-- Hook usunięty - wyświetlanie nazw klas nad głowami graczy wyłączone

-- Hook usunięty - duplikat wyświetlania nazw klas nad głowami graczy

hook.Add( "Tick", "client_tick_hook", CLTick )

function Blink( time )
	blink = true
	blink_end = CurTime() + time
	btime = CurTime() + GetConVar("br_time_blinkdelay"):GetFloat() + time
end

net.Receive("PlayerBlink", function(len)
	local time = net.ReadFloat()
	Blink( time )
end)

net.Receive( "PlayerReady", function()
	local tab = net.ReadTable()
	sR = tab[1]
	sL = tab[2]
end )

net.Receive( "689", function( len )
	if LocalPlayer():GetNClass() == ROLES.ROLE_SCP689 then
		local targets = net.ReadTable()
		if targets then
			local swep = LocalPlayer():GetWeapon( "weapon_scp_689" )
			if IsValid( swep ) then
				swep.Targets = targets
			end
		end
	end
end )

net.Receive("Effect", function()
	LocalPlayer().mblur = net.ReadBool()
end )

local mat_blink = CreateMaterial( "blink_material", "UnlitGeneric", {
	["$basetexture"] = "models/debug/debugwhite",
	["$color"] = "{ 0 0 0 }"
} )

local mat_color = Material( "pp/colour" ) -- used outside of the hook for performance
hook.Add( "RenderScreenspaceEffects", "blinkeffects", function()
	if blink then
		render.SetMaterial( mat_blink )
		render.DrawScreenQuad()
		return
	end
	
	-- Efekty SCP-966 wyłączone
	--[[
	if LocalPlayer().mblur == nil then LocalPlayer().mblur = false end
	if ( LocalPlayer().mblur == true ) then
		DrawMotionBlur( 0.3, 0.8, 0.03 )
	end
	--]]
	
	local contrast = 1
	local colour = 1
	local nvgbrightness = 0
	local clr_r = 0
	local clr_g = 0
	local clr_b = 0
	local bloommul = 0  -- Zmniejszono z 1.2 aby zapobiec nadmiernemu świeceniu białych obszarów
	
	if LocalPlayer().n420endtime and LocalPlayer().n420endtime > CurTime() then
		DrawMotionBlur( 1 - ( LocalPlayer().n420endtime - CurTime() ) / 15 , 0.3, 0.025 )
		DrawSharpen( ( LocalPlayer().n420endtime - CurTime() ) / 3, ( LocalPlayer().n420endtime - CurTime() ) / 20 )
		clr_r = ( LocalPlayer().n420endtime - CurTime() ) * 2
		clr_g = ( LocalPlayer().n420endtime - CurTime() ) * 2
		clr_b = ( LocalPlayer().n420endtime - CurTime() ) * 2
	end
	
--	last996attack = last996attack - 0.002
--	if last996attack < 0 then
--		last996attack = 0
--	else
--		DrawMotionBlur( 1 - last996attack, 1, 0.05 )
--		DrawSharpen( last996attack,2 )
--		contrast = last996attack
--	end
	if IsValid(LocalPlayer():GetActiveWeapon()) then
		-- Old automatic NVG detection removed
		-- Now use toggle system
	end
	
	-- New NVG toggle system
	if LocalPlayer().NVGActive then
			nvgbrightness = 0.2
			DrawSobel( 0.7 )
	end
	
	if livecolors then
		contrast = 1.2  -- Zmniejszono z 1.1
		colour = 1.6     -- Zmniejszono z 1.5
		bloommul = 2   -- Zmniejszono z 2
	end
	-- Efekty niskiego HP wyłączone
	--[[
	if LocalPlayer():Health() < 30 and LocalPlayer():Alive() then
		colour = math.Clamp((LocalPlayer():Health() / LocalPlayer():GetMaxHealth()) * 5, 0, 2)
		DrawMotionBlur( 0.27, 0.5, 0.01 )
		DrawSharpen( 1,2 )
		DrawToyTown( 3, ScrH() / 1.8 )
	end
	--]]
	render.UpdateScreenEffectTexture()

	
	mat_color:SetTexture( "$fbtexture", render.GetScreenEffectTexture() )
	
	mat_color:SetFloat( "$pp_colour_brightness", nvgbrightness )
	mat_color:SetFloat( "$pp_colour_contrast", contrast)
	mat_color:SetFloat( "$pp_colour_colour", colour )
	mat_color:SetFloat( "$pp_colour_mulr", clr_r )
	mat_color:SetFloat( "$pp_colour_mulg", clr_g )
	mat_color:SetFloat( "$pp_colour_mulb", clr_b )
	
	render.SetMaterial( mat_color )
	render.DrawScreenQuad()
	//DrawBloom( Darken, Multiply, SizeX, SizeY, Passes, ColorMultiply, Red, Green, Blue )
	-- Zmniejszono parametry bloom aby zapobiec świeceniu białych kolorów
	DrawBloom( 0.75, bloommul, 7, 7, 1, 0.8, 1, 1, 1 )
end )

local dropnext = 0
function GM:PlayerBindPress( ply, bind, pressed )
	if bind == "+menu" then
		if GetConVar( "br_new_eq" ):GetInt() != 1 then
			DropCurrentWeapon()
		end
	elseif bind == "gm_showteam" then
		OpenClassMenu()
	elseif bind == "+menu_context" then
		thirdpersonenabled = !thirdpersonenabled
	end
end

function DropCurrentWeapon()
	if dropnext > CurTime() then return true end
	dropnext = CurTime() + 0.5
	net.Start("DropCurWeapon")
	net.SendToServer()
	if LocalPlayer().channel != nil then
		LocalPlayer().channel:EnableLooping( false )
		LocalPlayer().channel:Stop()
		LocalPlayer().channel = nil
	end
	return true
end

concommand.Add("br_requestescort", function()
	if !((LocalPlayer():GTeam() == TEAM_GUARD or LocalPlayer():GTeam() == TEAM_CHAOS) or LocalPlayer():GTeam() == TEAM_CHAOS) then return end
	net.Start("RequestEscorting")
	net.SendToServer()
end)

concommand.Add("br_requestNTFspawn", function( ply, cmd, args )
	if ply:IsSuperAdmin() then
		net.Start("NTFRequest")
		net.SendToServer()
	end
end )

concommand.Add("br_destroygatea", function( ply, cmd, args)
	if ( ply:GetNClass() == ROLES.ROLE_MTFNTF or ply:GetNClass() == ROLES.ROLE_CHAOS or ply:GTeam() == TEAM_GOC ) then
		net.Start("ExplodeRequest")
		net.SendToServer()
	end
end )

concommand.Add("br_sound_random", function()
	if (LocalPlayer():GTeam() == TEAM_GUARD or LocalPlayer():GTeam() == TEAM_CHAOS) and LocalPlayer():Alive() then
		net.Start("Sound_Random")
		net.SendToServer()
	end
end)

concommand.Add("br_sound_searching", function()
	if (LocalPlayer():GTeam() == TEAM_GUARD or LocalPlayer():GTeam() == TEAM_CHAOS) and LocalPlayer():Alive() then
		net.Start("Sound_Searching")
		net.SendToServer()
	end
end)

concommand.Add("br_sound_classd", function()
	if (LocalPlayer():GTeam() == TEAM_GUARD or LocalPlayer():GTeam() == TEAM_CHAOS) and LocalPlayer():Alive() then
		net.Start("Sound_Classd")
		net.SendToServer()
	end
end)

concommand.Add("br_sound_stop", function()
	if (LocalPlayer():GTeam() == TEAM_GUARD or LocalPlayer():GTeam() == TEAM_CHAOS) and LocalPlayer():Alive() then
		net.Start("Sound_Stop")
		net.SendToServer()
	end
end)

concommand.Add("br_sound_lost", function()
	if (LocalPlayer():GTeam() == TEAM_GUARD or LocalPlayer():GTeam() == TEAM_CHAOS) and LocalPlayer():Alive() then
		net.Start("Sound_Lost")
		net.SendToServer()
	end
end)
/*
function CalcView3DPerson( ply, pos, angles, fov )
	local view = {}
	view.origin = pos
	view.angles = angles
	view.fov = fov
	view.drawviewer = false
	if thirdpersonenabled then
		local eyepos = ply:EyePos()
		local eyeangles = ply:EyeAngles()
		local point = ply:GetEyeTrace().HitPos
		local goup = 2
		if ply:Crouching() then
			goup = 20
		end
		view.drawviewer = true
		view.origin = eyepos + Vector(0,0,goup) - (eyeangles:Forward() * 30) + (eyeangles:Right() * 20)
		view.angles = (point - view.origin):Angle()
		local endps = eyepos + Vector(0,0,goup) - (eyeangles:Forward() * 30) + (eyeangles:Right() * 15)
		local tr = util.TraceLine( { start = eyepos, endpos = endps} )
		if tr.Hit then
			view.origin = tr.HitPos
		end
	end
	return view
end
hook.Add( "CalcView", "CalcView3DPerson", CalcView3DPerson )
*/

/*function GM:HUDDrawPickupHistory()

end*/

/*function GM:HUDWeaponPickedUp( weapon )
end*/

hook.Add( "HUDWeaponPickedUp", "DonNotShowCards", function( weapon )
	EQHUD.weps = LocalPlayer():GetWeapons()
	if weapon:GetClass() == "br_keycard" then return false end
end )

function GM:CalcView( ply, origin, angles, fov )
	local data = {}
	data.origin = origin
	data.angles = angles
	data.fov = fov
	data.drawviewer = false
	local item = ply:GetActiveWeapon()
	if IsValid( item ) then
		if item.CalcView then
			local vec, ang, ifov, dw = item:CalcView( ply, origin, angles, fov )
			if vec then data.origin = vec end
			if ang then data.angles = ang end
			if ifov then data.fov = ifov end
			if dw != nil then data.drawviewer = dw end
		end
	end

	if CamEnable then
		--print( "enabled" )
		if !timer.Exists( "CamViewChange" ) then
			timer.Create( "CamViewChange", 1, 1, function()
				CamEnable = false
			end )
		end
		data.drawviewer = true
		dir = dir or Vector( 0, 0, 0 )
		--print( dir )
		data.origin = ply:GetPos() - dir - dir:GetNormalized() * 30 + Vector( 0, 0, 80 )
		data.angles = Angle( 10, dir:Angle().y, 0 )
	end

	return data
end

function GetWeaponLang()
	if cwlang then
		return cwlang
	end
end

local PrecachedSounds = {}
function ClientsideSound( file, ent )
	ent = ent or game.GetWorld()
	local sound
	if !PrecachedSounds[file] then
		sound = CreateSound( ent, file, nil )
		PrecachedSounds[file] = sound
		return sound
	else
		sound = PrecachedSounds[file]
		sound:Stop()
		return sound
	end
end

net.Receive( "SendSound", function( len )
	local com = net.ReadInt( 2 )
	local f = net.ReadString()
	if com == 1 then
		local snd = ClientsideSound( f )
		snd:SetSoundLevel( 0 )
		snd:Play()
	elseif com == 0 then
		ClientsideSound( f )
	end
end )

concommand.Add( "br_dropweapon", function( ply )
		net.Start("DropCurWeapon")
		net.SendToServer()
end )

/*if !file.Exists( "breach", "DATA" ) then
	file.CreateDir( "breach" )
end

if !file.Exists( "breach/intro.dat", "DATA" ) then
	PlayIntro( 2 )
else
	if GetConVar( "br_force_showupdates" ):GetInt() != 0 then
		showupdates = true
		PlayIntro( 5 )
	else
		local res = file.Read( "breach/intro.dat" )
		if string.match( res, "true" ) then
			showupdates = true
			PlayIntro( 4 )
		end
	end
	timer.Simple( 1, function()
		net.Start( "PlayerReady" )
		net.SendToServer()
	end )
end

concommand.Add( "br_reset_intro", function( ply )
	if file.Exists( "breach/intro.dat", "DATA" ) then
		file.Delete( "breach/intro.dat" )
	end
end ) 

concommand.Add( "br_show_update", function( ply )
	PlayIntro( 5 )
end ) */

function  GM:SetupWorldFog()
	if LocalPlayer():GetNClass() == ROLES.ROLE_SCP9571 then
		if OUTSIDE_BUFF and OUTSIDE_BUFF( ply:GetPos() ) then return end
		render.FogMode( MATERIAL_FOG_LINEAR )
		render.FogColor( 0, 0, 0 )
		render.FogStart( 250 )
		render.FogEnd( 500 )
		render.FogMaxDensity( 1 )
		return true
	end

	if !Effect957 then return end

	if Effect957Mode == 0 then
		if Effect957Density < 1 then
			Effect957Density = math.Clamp( math.abs( Effect957 - CurTime() ), 0, 1 )
		elseif Effect957Density >= 1 then
			Effect957 = CurTime() + 3
			Effect957Mode = 1
		end
	elseif Effect957Mode == 1 then
		Effect957Density = 1
		if Effect957 < CurTime() then
			Effect957 = CurTime() + 1
			Effect957Mode = 2
		end
	else
		Effect957Density = math.Clamp( Effect957 - CurTime(), 0, 1 )
		if Effect957Density == 0 then
			Effect957 = false
			Effect957Mode = 0
		end
	end



	render.FogMode( MATERIAL_FOG_LINEAR )
	render.FogColor( 0, 0, 0 )
	render.FogStart( 50 )
	render.FogEnd( 250 )
	render.FogMaxDensity( Effect957Density )
	return true
end

Effect957 = false
Effect957Density = 0
Effect957Mode = 0
net.Receive( "957Effect", function( len )
	local status = net.ReadBool()
	if status then
		Effect957 = CurTime()
		Effect957Mode = 0
	elseif Effect957 then
		//Effect957 = false
		Effect957Mode = 2
		Effect957 = CurTime() + 1
	end
end )

net.Receive( "SCPList", function( len )
	SCPS = net.ReadTable()
	local transmited = net.ReadTable()

	for k, v in pairs( SCPS ) do
		ROLES["ROLE_"..v] = v
	end
	for k, v in pairs( transmited ) do
		ROLES["ROLE_"..v] = v
	end
	--InitializeBreachULX()
	SetupForceSCP()
end )

timer.Simple( 1, function()
	net.Start( "PlayerReady" )
	net.SendToServer()
end )

print( "client ready" )

-- PSYCHOLOGIST PASSIVE ABILITIES - CLIENT SIDE
-- Initialize after ROLES are loaded
timer.Simple( 2, function()
	-- Footstep traces storage
	local FootstepTraces = {}

	-- Team colors for footstep traces (simplified to 2 colors)
	local TeamColors = {
		[TEAM_SCI] = Color(0, 255, 0, 150),     -- Green for Scientists
		[TEAM_GUARD] = Color(0, 255, 0, 150),   -- Green for MTF
		[TEAM_CHAOS] = Color(255, 0, 0, 150),   -- Red for Chaos
		[TEAM_SCP] = Color(255, 0, 0, 150),     -- Red for SCPs
		[TEAM_GOC] = Color(255, 0, 0, 150),     -- Red for GOC (enemy)
		[TEAM_CLASSD] = Color(255, 0, 0, 150),  -- Red for Class-D (enemy)
		-- TEAM_SPEC removed - spectators don't leave footsteps
	}

	-- Receive footstep data from server
	net.Receive("Psychologist_AddFootstep", function()
		local pos = net.ReadVector()
		local team = net.ReadInt(8)
		local timestamp = net.ReadFloat()
		
		-- Only show if local player is psychologist
		if ROLES and ROLES.ROLE_PSYCHOLOGIST and IsValid(LocalPlayer()) and LocalPlayer():GetNClass() == ROLES.ROLE_PSYCHOLOGIST then
			table.insert(FootstepTraces, {
				pos = pos,
				team = team,
				time = timestamp,
				alpha = 150
			})
		end
	end)

	-- Render footstep traces and healing aura
	hook.Add("PostDrawOpaqueRenderables", "Psychologist_DrawFootsteps", function()
		-- Only render if local player is psychologist
		if not ROLES or not ROLES.ROLE_PSYCHOLOGIST or not IsValid(LocalPlayer()) or LocalPlayer():GetNClass() != ROLES.ROLE_PSYCHOLOGIST then
			FootstepTraces = {} -- Clear traces if not psychologist
			return
		end
		
		local ply = LocalPlayer()
		local currentTime = CurTime()
		
		-- Draw healing aura radius on ground (only when actively healing someone)
		if ply:Alive() then
			local pos = ply:GetPos()
			local radius = 125 -- Same as server-side healing radius
			
			-- Check if there are players in range that need healing
			local isHealing = false
			for _, target in pairs(player.GetAll()) do
				if IsValid(target) and target:Alive() and target != ply then
					local distance = pos:Distance(target:GetPos())
					if distance <= radius then
						-- Check if player is from supported teams/roles and needs healing
						local team = target:GTeam()
						local class = target:GetNClass()
						
						-- Heal: Scientists, MTF, and CI Spy only (not all Chaos)
						if (team == TEAM_SCI or team == TEAM_GUARD or (team == TEAM_CHAOS and class == ROLES.ROLE_CHAOSSPY)) then
							local currentHP = target:Health()
							if currentHP < 50 and currentHP > 0 then
								isHealing = true
								break
							end
						end
					end
				end
			end
			
			-- Only draw circle if actively healing someone
			if isHealing then
				-- Trace downward to find ground
				local traceDown = util.TraceLine({
					start = pos,
					endpos = pos + Vector(0, 0, -100),
					filter = ply
				})
				
				if traceDown.Hit then
					local groundPos = traceDown.HitPos + Vector(0, 0, 1)
					
					-- Draw healing aura circle on ground
					render.SetColorMaterial()
					
					-- Draw multiple circles for better visibility
					for i = 1, 3 do
						local alpha = 30 - (i * 8) -- Fade outward
						local currentRadius = radius + (i * 5)
						
						-- Draw circle segments
						local segments = 32
						for seg = 0, segments - 1 do
							local angle1 = (seg / segments) * math.pi * 2
							local angle2 = ((seg + 1) / segments) * math.pi * 2
							
							local pos1 = groundPos + Vector(math.cos(angle1) * currentRadius, math.sin(angle1) * currentRadius, 0)
							local pos2 = groundPos + Vector(math.cos(angle2) * currentRadius, math.sin(angle2) * currentRadius, 0)
							
							render.DrawBeam(pos1, pos2, 2, 0, 1, Color(0, 255, 150, alpha))
						end
					end
					
					-- Draw center indicator
					render.DrawSphere(groundPos, 3, 8, 8, Color(0, 255, 150, 100))
				end
			end
		end
		
		-- Update and render footstep traces
		for i = #FootstepTraces, 1, -1 do
			local trace = FootstepTraces[i]
			local age = currentTime - trace.time
			
			-- Remove traces older than 15 seconds (2x faster)
			if age > 7 then
				table.remove(FootstepTraces, i)
			else
				-- Calculate alpha based on age (fade over 15 seconds)
				local fadeAlpha = math.max(0, 150 * (1 - age / 15))
				
				-- Determine color: Green for allies (MTF/Scientists/CI Spy), Red for enemies
				local color
				if trace.team == 99 or trace.team == TEAM_SCI or trace.team == TEAM_GUARD then
					color = TeamColors[TEAM_SCI] -- Green for allies (99 = CI Spy)
				else
					color = TeamColors[TEAM_SCP] -- Red for enemies
				end
				color.a = fadeAlpha
				
				-- Render smaller footstep trace
				render.SetColorMaterial()
				render.DrawSphere(trace.pos + Vector(0, 0, 2), 5, 8, 8, color) -- Smaller: 5 instead of 8
				
				-- Add a small upward effect
				render.DrawSphere(trace.pos + Vector(0, 0, 8), 2, 6, 6, Color(color.r, color.g, color.b, fadeAlpha * 0.5)) -- Smaller: 2 instead of 4
			end
		end
	end)
end)

-- Receive NVG toggle from server
net.Receive("NVG_Toggle", function()
	LocalPlayer().NVGActive = net.ReadBool()
end)

-- Clear NVG effect when player dies
hook.Add("PlayerDeath", "ClearNVGOnDeath", function(victim, inflictor, attacker)
	if victim == LocalPlayer() then
		LocalPlayer().NVGActive = false
	end
end)

-- Clear NVG effect when player spawns
hook.Add("PlayerSpawn", "ClearNVGOnSpawn", function(ply)
	if ply == LocalPlayer() then
		LocalPlayer().NVGActive = false
	end
end)