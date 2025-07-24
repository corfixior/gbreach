// Shared file
GM.Name 	= "Breach"
GM.Author 	= "Kanade, edited by danx91"
GM.Email 	= ""
GM.Website 	= ""

VERSION = "0.32"
DATE = "19/04/2019"

function GM:Initialize()
	self.BaseClass.Initialize( self )
end

TEAM_SCP = 1
TEAM_GUARD = 2
TEAM_CLASSD = 3
TEAM_SPEC = 4
TEAM_SCI = 5
TEAM_CHAOS = 6
TEAM_GOC = 7

MINPLAYERS = 2

// Team setup
team.SetUp( 1, "Default", Color(255, 255, 0) )
/* Replaced with GTeams
team.SetUp( TEAM_SCP, "SCPs", Color(237, 28, 63) )
team.SetUp( TEAM_GUARD, "MTF Guards", Color(0, 100, 255) )
team.SetUp( TEAM_CLASSD, "Class Ds", Color(255, 130, 0) )
team.SetUp( TEAM_SPEC, "Spectators", Color(141, 186, 160) )
team.SetUp( TEAM_SCI, "Scientists", Color(66, 188, 244) )
team.SetUp( TEAM_CHAOS, "Chaos Insurgency", Color(0, 100, 255) )
*/

game.AddDecal( "Decal106", "decals/decal106" )

function GetLangRole(rl)
	if clang == nil then return rl end
	local rolef = nil
	for k,v in pairs(ROLES) do
		if rl == v then
			rolef = k
		end
	end
	if rolef != nil then
		if clang.ROLES and clang.ROLES[rolef] then
			return clang.ROLES[rolef]
		else
			return rl -- Zwróć oryginalną nazwę jeśli nie ma tłumaczenia
		end
	else
		return rl or "Unknown" -- Zabezpieczenie przed nil
	end
end

SCPS = {}

ROLES = {}
ROLES.ROLE_SCP0082 = "SCP0082"

ROLES.ADMIN = "ADMIN MODE"

// Researchers
ROLES.ROLE_RES = "Researcher"
ROLES.ROLE_MEDIC = "Medic"
ROLES.ROLE_NO3 = "Level 3 Researcher"
ROLES.ROLE_JANITOR = "Janitor"
ROLES.ROLE_VIP = "VIP"
ROLES.ROLE_CLEARANCE_TECH = "Clearance Technician"
ROLES.ROLE_ENGINEER = "Engineer"
ROLES.ROLE_COOK = "Cook"
ROLES.ROLE_DRHOUSE = "Dr. House"
ROLES.ROLE_PSYCHOLOGIST = "Site Psychologist"
-- ROLES.ROLE_MEDIC_DROID = "Medic Droid" -- Usunięto klasę Medic Droid

// Class D Personell
ROLES.ROLE_CLASSD = "Class D Personell"
ROLES.ROLE_VETERAN = "Veteran"
ROLES.ROLE_SCOUT_D = "Scout D"
ROLES.ROLE_FAT_D = "Fat D"
ROLES.ROLE_SKINNY_D = "Skinny D"
ROLES.ROLE_DCLASS_INFECTED = "D-Class Infected"
ROLES.ROLE_THIEF_D = "Thief D"

ROLES.ROLE_SCP527 = "SCP-527"
ROLES.ROLE_CIC = "CI Agent"

// Security
ROLES.ROLE_SECURITY = "Security Officer"
ROLES.ROLE_MTFGUARD = "MTF Guard"
ROLES.ROLE_MTF_HEAVY_SUPPORT = "MTF Heavy Support"
ROLES.ROLE_MTFMEDIC = "MTF Medic"
ROLES.ROLE_MTFL = "MTF Lieutenant"
ROLES.ROLE_HAZMAT = "MTF SCU"
ROLES.ROLE_MTFNTF = "MTF Nine Tailed Fox"
ROLES.ROLE_CSECURITY = "Security Chief"
ROLES.ROLE_MTFCOM = "MTF Commander"
ROLES.ROLE_SD = "Site Director"
ROLES.ROLE_O5 = "O5 Council Member"
ROLES.ROLE_SECURITY_DROID = "Security Droid"

// Infect round
ROLES.ROLE_INFECTD = "Class D Presonnel"
ROLES.ROLE_INFECTMTF = "MTF"

// Chaos Insurgency
ROLES.ROLE_CHAOSSPY = "Chaos Insurgency Spy"
ROLES.ROLE_CHAOS = "Chaos Insurgency"
ROLES.ROLE_CHAOSCOM = "CI Commander"

// GOC (Global Occult Coalition)
ROLES.ROLE_GOC_SOLDIER = "GOC Soldier"
ROLES.ROLE_GOC_OPERATIVE = "GOC Operative"
ROLES.ROLE_GOC_COMMANDER = "GOC Commander"

// Other
ROLES.ROLE_SPEC = "Spectator"

// SCPs (missing definitions)
ROLES.ROLE_SCP173 = "SCP173"
ROLES.ROLE_SCP106 = "SCP106"
ROLES.ROLE_SCP049 = "SCP049"
ROLES.ROLE_SCP457 = "SCP457"
ROLES.ROLE_SCP966 = "SCP966"
ROLES.ROLE_SCP096 = "SCP096"
ROLES.ROLE_SCP066 = "SCP066"
ROLES.ROLE_SCP689 = "SCP689"
ROLES.ROLE_SCP682 = "SCP682"
ROLES.ROLE_SCP082 = "SCP082"
ROLES.ROLE_SCP939 = "SCP939"
ROLES.ROLE_SCP999 = "SCP999"
ROLES.ROLE_SCP023 = "SCP023"
ROLES.ROLE_SCP076 = "SCP076"
ROLES.ROLE_SCP1471 = "SCP1471"
ROLES.ROLE_SCP8602 = "SCP8602"
ROLES.ROLE_SCP1048A = "SCP1048A"
ROLES.ROLE_SCP1048B = "SCP1048B"
ROLES.ROLE_SCP0492 = "SCP0492"
ROLES.ROLE_SCP035 = "SCP035"
ROLES.ROLE_SCP957 = "SCP957"
ROLES.ROLE_SCP9571 = "SCP9571"
ROLES.ROLE_SCP069 = "SCP069"
ROLES.ROLE_SCP054 = "SCP054"
ROLES.ROLE_SCP2521 = "SCP2521"
ROLES.ROLE_SCP239 = "SCP239"
ROLES.ROLE_SCP3166 = "SCP3166"
ROLES.ROLE_SCPTTT_SAHUR = "SCPTTT_SAHUR"
ROLES.ROLE_SCP1316 = "SCP1316"
ROLES.ROLE_SCP2137J = "SCP2137J"
ROLES.ROLE_SCPSTEVEJ = "SCPSTEVEJ"
ROLES.ROLE_SCPDOOMGUYJ = "SCPDOOMGUYJ"
ROLES.ROLE_SCPIMPOSTORJ = "SCPIMPOSTORJ"

--Keycard access help
ACCESS_SAFE = bit.lshift( 1, 0 )
ACCESS_EUCLID = bit.lshift( 1, 1 )
ACCESS_KETER = bit.lshift( 1, 2 )
ACCESS_CHECKPOINT = bit.lshift( 1, 3 )
ACCESS_OMEGA = bit.lshift( 1, 4 )
ACCESS_GENERAL = bit.lshift( 1, 5 )
ACCESS_GATEA = bit.lshift( 1, 6 )
ACCESS_GATEB = bit.lshift( 1, 7 )
ACCESS_ARMORY = bit.lshift( 1, 8 )
ACCESS_FEMUR = bit.lshift( 1, 9 )
ACCESS_EC = bit.lshift( 1, 10 )

--include( "sh_playersetups.lua" )

if !ConVarExists("br_roundrestart") then CreateConVar( "br_roundrestart", "0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Restart the round" ) end
if !ConVarExists("br_time_preparing") then CreateConVar( "br_time_preparing", "40", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Set preparing time" ) end
if !ConVarExists("br_time_round") then CreateConVar( "br_time_round", "780", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Set round time" ) end
if !ConVarExists("br_time_postround") then CreateConVar( "br_time_postround", "30", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Set postround time" ) end
if !ConVarExists("br_time_ntfenter") then CreateConVar( "br_time_ntfenter", "360", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Time that NTF units will enter the facility" ) end
if !ConVarExists("br_time_blink") then CreateConVar( "br_time_blink", "0.25", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Blink timer" ) end
if !ConVarExists("br_time_blinkdelay") then CreateConVar( "br_time_blinkdelay", "5", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Delay between blinks" ) end
if !ConVarExists("br_spawnzombies") then CreateConVar( "br_spawnzombies", "0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Do you want zombies?" ) end
if !ConVarExists("br_scoreboardranks") then CreateConVar( "br_scoreboardranks", "0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "" ) end
if !ConVarExists("br_defaultlanguage") then CreateConVar( "br_defaultlanguage", "english", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "" ) end
if !ConVarExists("br_expscale") then CreateConVar( "br_expscale", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "" ) end
if !ConVarExists("br_scp_cars") then CreateConVar( "br_scp_cars", "0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Allow SCPs to drive cars?" ) end
if !ConVarExists("br_allow_vehicle") then CreateConVar( "br_allow_vehicle", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Allow vehicle spawn?" ) end
if !ConVarExists("br_dclass_keycards") then CreateConVar( "br_dclass_keycards", "0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Is D class supposed to have keycards? (D Class Weterans have keycard anyway)" ) end
if !ConVarExists("br_time_explode") then CreateConVar( "br_time_explode", "30", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Time from call br_destroygatea to explode" ) end
if !ConVarExists("br_ci_percentage") then CreateConVar("br_ci_percentage", "25", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Percentage of CI spawn" ) end
if !ConVarExists("br_i4_min_mtf") then CreateConVar("br_i4_min_mtf", "4", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Percentage of CI spawn" ) end
if !ConVarExists("br_cars_oldmodels") then CreateConVar("br_cars_oldmodels", "0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Use old cars models?" ) end
if !ConVarExists("br_premium_url") then CreateConVar("br_premium_url", "", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Link to premium members list" ) end
if !ConVarExists("br_premium_mult") then CreateConVar("br_premium_mult", "1.25", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Premium members exp multiplier" ) end
if !ConVarExists("br_premium_display") then CreateConVar("br_premium_display", "Premium player %s has joined!", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Text shown to all players when premium member joins" ) end
if !ConVarExists("br_rounds") then CreateConVar("br_rounds", "0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "How many round before map restart? 0 - dont restart" ) end
if !ConVarExists("br_min_players") then CreateConVar("br_min_players", "2", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Minimum players to start round" ) end
if !ConVarExists("br_firstround_debug") then CreateConVar("br_firstround_debug", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Skip first round" ) end
if !ConVarExists("br_force_specialround") then CreateConVar("br_force_specialround", "", {FCVAR_SERVER_CAN_EXECUTE}, "Available special rounds [ infect, multi, ttt, bomber, swapper, moveordie ]" ) end
if !ConVarExists("br_specialround_pct") then CreateConVar("br_specialround_pct", "10", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Skip first round" ) end
if !ConVarExists("br_punishvote_time") then CreateConVar("br_punishvote_time", "30", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "How much time players have to vote" ) end
if !ConVarExists("br_allow_punish") then CreateConVar("br_allow_punish", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Is punish system allowed?" ) end
if !ConVarExists("br_cars_ammount") then CreateConVar("br_cars_ammount", "12", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "How many cars should spawn?" ) end
if !ConVarExists("br_dropvestondeath") then CreateConVar("br_dropvestondeath", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Do players drop vests on death?" ) end
if !ConVarExists("br_force_showupdates") then CreateConVar("br_force_showupdates", "0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Should players see update logs any time they join to server?" ) end
if !ConVarExists("br_allow_scptovoicechat") then CreateConVar("br_allow_scptovoicechat", "0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Can SCPs talk with humans?" ) end
if !ConVarExists("br_ulx_premiumgroup_name") then CreateConVar("br_ulx_premiumgroup_name", "", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Name of ULX premium group" ) end
if !ConVarExists("br_experimental_bulletdamage_system") then CreateConVar("br_experimental_bulletdamage_system", "0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Turn it off when you see any problems with bullets" ) end
if !ConVarExists("br_experimental_antiknockback_force") then CreateConVar("br_experimental_antiknockback_force", "5", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Turn it off when you see any problems with bullets" ) end
if !ConVarExists("br_allow_ineye_spectate") then CreateConVar("br_allow_ineye_spectate", "0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "" ) end
if !ConVarExists("br_allow_roaming_spectate") then CreateConVar("br_allow_roaming_spectate", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "" ) end
if !ConVarExists("br_scale_bullet_damage") then CreateConVar("br_scale_bullet_damage", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Bullet damage scale" ) end
if !ConVarExists("br_new_eq") then CreateConVar("br_new_eq", "0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enables new EQ" ) end
if !ConVarExists("br_enable_warhead") then CreateConVar("br_enable_warhead", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE }, "Enables OMEGA Warhead" ) end
if !ConVarExists("br_scale_human_damage") then CreateConVar("br_scale_human_damage", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE }, "Scales damage dealt by humans" ) end
if !ConVarExists("br_scale_scp_damage") then CreateConVar("br_scale_scp_damage", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE }, "Scales damage dealt by SCP" ) end
if !ConVarExists("br_scp_penalty") then CreateConVar("br_scp_penalty", "3", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE }, "" ) end
if !ConVarExists("br_premium_penalty") then CreateConVar("br_premium_penalty", "0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE }, "" ) end

-- OPTYMALIZACJA: ConVary dla systemu optymalizacji wydajności
if !ConVarExists("br_optimization_enabled") then CreateConVar("br_optimization_enabled", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Enable performance optimizations") end
if !ConVarExists("br_cache_update_interval") then CreateConVar("br_cache_update_interval", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Player cache update interval") end
if !ConVarExists("br_entity_cache_time") then CreateConVar("br_entity_cache_time", "0.5", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Entity search cache time") end
if !ConVarExists("br_timer_group_interval") then CreateConVar("br_timer_group_interval", "0.1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Timer group update interval") end

MINPLAYERS = GetConVar("br_min_players"):GetInt()

-- Removed br_debug_armor command

function GetPrepTime()
	return GetConVar("br_time_preparing"):GetInt()
end

function GetRoundTime()
	return GetConVar("br_time_round"):GetInt()
end

function GetPostTime()
	return GetConVar("br_time_postround"):GetInt()
end

function GetGateOpenTime()
	return GetConVar("br_time_gateopen"):GetInt()
end

function GetNTFEnterTime()
	return GetConVar("br_time_ntfenter"):GetInt()
end

function GM:EntityFireBullets( ent, data )
	if GetConVar( "br_experimental_bulletdamage_system" ):GetInt() != 0 then
		local damage = data.Damage
		data.Damage = 0
		data.Callback = function( ent, tr, info )
			if !SERVER then return end
			local vic = tr.Entity
			if IsValid( vic ) then
				if vic:IsPlayer() then
					info:SetDamage( damage )
					gamemode.Call( "ScalePlayerDamage", vic, nil, info )
					local scaleddamge = info:GetDamage()
					local force = info:GetDamageForce():GetNormalized()
					local antiforce = GetConVar( "br_experimental_antiknockback_force" ):GetInt() * -1
					info:SetDamage( 0 )
					info:SetDamageForce( Vector( 0 ) )
					vic:TakeDamage( scaleddamge, ent, ent )
					vic:SetVelocity( force * scaleddamge * antiforce )
				else
					vic:TakeDamage( info:GetDamage(), ent, ent )
				end
			end
		end
		return true
	end
end

function GM:PlayerFootstep( ply, pos, foot, sound, volume, rf )
	if not ply.GetNClass then
		player_manager.RunClass( ply, "SetupDataTables" )
	end
	if not ply.GetNClass then return end
	if ply:GetNClass() == ROLE_SCP173 then
		if ply.steps == nil then ply.steps = 0 end
		ply.steps = ply.steps + 1
		if ply.steps > 6 then
			ply.steps = 1
			if SERVER then
				ply:EmitSound( "173sound"..math.random(1,3)..".ogg", 300, 100, 1 )
			end
		end
		return true
	end
	return false
end

function GM:ShouldCollide( ent1, ent2 )
	/*local ply = ent1:IsPlayer() and ent1 or ent2:IsPlayer() and ent2
	local ent
	if ply then
		if ent1 == ply then
			ent = ent2
		else
			ent = ent1
		end
		if ply:GetNClass() == ROLES.ROLE_SCP106 then
			if ent.ignorecollide106 then
				return false
			end
		end
	end*/
	-- SCP-106 door passing
if ent1:IsPlayer() and ent1:GetNClass() == ROLES.ROLE_SCP106 or ent2:IsPlayer() and ent2:GetNClass() == ROLES.ROLE_SCP106 then
	if ent1.ignorecollide106 or ent2.ignorecollide106 then
		return false
	end
end

-- SCP-054 door passing (używa tego samego systemu co SCP-106)
if ent1:IsPlayer() and ent1:GetNClass() == ROLES.ROLE_SCP054 or ent2:IsPlayer() and ent2:GetNClass() == ROLES.ROLE_SCP054 then
	if ent1.ignorecollide106 or ent2.ignorecollide106 then
		return false
	end
end
	
	-- SCP-999 door passing (używa tego samego systemu co SCP-106)
	if ent1:IsPlayer() and ent1:GetNClass() == ROLES.ROLE_SCP999 and ent1.SCP999Active or ent2:IsPlayer() and ent2:GetNClass() == ROLES.ROLE_SCP999 and ent2.SCP999Active then
		if ent1.ignorecollide999 or ent2.ignorecollide999 then
			return false
		end
	end
	
	-- SCP-X01-J plasma projectile collision
	if ent1:GetClass() == "scp_x01j_plasma_projectile" or ent2:GetClass() == "scp_x01j_plasma_projectile" then
		local projectile = ent1:GetClass() == "scp_x01j_plasma_projectile" and ent1 or ent2
		local other = ent1 == projectile and ent2 or ent1
		
		if IsValid(other) and other:IsPlayer() then
			local owner = projectile:GetOwner()
			if IsValid(owner) and owner:GTeam() == TEAM_SCP and other:GTeam() == TEAM_SCP then
				-- Projectile nie koliduje z innymi SCP
				return false
			end
		end
	end
		
	return true
end

/*
function GM:PlayerShouldTakeDamage( ply, attacker ) 
	if attacker:IsVehicle() then
	
	end
	
end
*/

function GM:PlayerButtonDown( ply, button )
	if CLIENT and IsFirstTimePredicted() then
		//local bind = _G[ "KEY_"..string.upper( input.LookupBinding( "+menu" ) or "q" ) ] or 
		local key = input.LookupBinding( "+menu" )

		if key then
			if input.GetKeyCode( key ) == button then
				if CanShowEQ() then
					ShowEQ()
				end
			end
		end
	end
end

function GM:PlayerButtonUp( ply, button )
	if CLIENT and IsFirstTimePredicted() then
		//local bind = _G[ "KEY_"..string.upper( input.LookupBinding( "+menu" ) ) ] or KEY_Q
		local key = input.LookupBinding( "+menu" )

		if key then
			if input.GetKeyCode( key ) == button and IsEQVisible() then
				HideEQ()
			end
		end
	end
end

-- Hook z wyższym priorytetem dla kamizelek
hook.Add("EntityTakeDamage", "BR_VestProtection", function(target, dmginfo)
	if not target:IsPlayer() or not target:Alive() then return end
	
	local dmgtype = dmginfo:GetDamageType()
	
	-- Debug dla wszystkich obrażeń na graczach z vestem
	if SERVER and target.UsingArmor then
		print("[VEST DEBUG] " .. target:Nick() .. " taking damage. Type: " .. dmgtype .. ", Amount: " .. dmginfo:GetDamage() .. ", Vest: " .. tostring(target.UsingArmor))
	end
	
	-- Fireproof vest protection
	if target.UsingArmor == "armor_fireproof" then
		if dmgtype == DMG_BURN or dmgtype == 268435464 or bit.band(dmgtype, DMG_BURN) > 0 then
			local originalDmg = dmginfo:GetDamage()
			dmginfo:ScaleDamage(0.25)
			
			if SERVER then
				print("[FIREPROOF VEST] ACTIVATED! Reduced damage from " .. originalDmg .. " to " .. dmginfo:GetDamage())
			end
			return
		end
	end
	
	-- Electroproof vest protection
	if target.UsingArmor == "armor_electroproof" then
		if dmgtype == DMG_SHOCK or dmgtype == DMG_ENERGYBEAM then
			dmginfo:SetDamage(0)
			if SERVER then
				print("[ELECTROPROOF VEST] Blocked all electric damage!")
			end
			return
		end
	end
end, HOOK_HIGH)

function GM:EntityTakeDamage( target, dmginfo )
	local at = dmginfo:GetAttacker()
	
	-- MEGA DEBUG dla wszystkich obrażeń między graczami
	if SERVER and target:IsPlayer() and IsValid(at) and at:IsPlayer() then
		local inflictor = dmginfo:GetInflictor()
		print("[DAMAGE DEBUG] Damage event:")
		print("  Target: " .. target:Nick() .. " (Team: " .. target:GTeam() .. ", Class: " .. tostring(target:GetNClass()))
		print("  Attacker: " .. at:Nick() .. " (Team: " .. at:GTeam() .. ", Class: " .. tostring(at:GetNClass()))
		print("  Damage: " .. dmginfo:GetDamage())
		print("  Inflictor: " .. tostring(inflictor) .. " (" .. (IsValid(inflictor) and inflictor:GetClass() or "invalid") .. ")")
		if IsValid(at) and at.GetActiveWeapon and IsValid(at:GetActiveWeapon()) then
			print("  Weapon: " .. at:GetActiveWeapon():GetClass())
		end
	end
	
	-- SCP-239 Immortality System - HIGHEST PRIORITY
	if target:IsPlayer() and target:GetNClass() == ROLES.ROLE_SCP239 then
		-- Check if SCP-239 is in vulnerability window
		local isVulnerable = target:GetNWBool("SCP239_Vulnerable", false)
		if SERVER then
			print("[SCP-239 DEBUG] Damage to SCP-239:", dmginfo:GetDamage(), "Vulnerable:", isVulnerable, "Attacker:", tostring(at))
		end
		if !isVulnerable then
			-- Block all damage when not vulnerable - COMPLETE IMMUNITY
			dmginfo:SetDamage( 0 )
			dmginfo:ScaleDamage( 0 )
			if SERVER then
				print("[SCP-239 DEBUG] BLOCKED ALL DAMAGE - SCP-239 is immortal")
			end
			return true -- Stop processing other damage hooks
		else
			if SERVER then
				print("[SCP-239 DEBUG] Allowing damage - SCP-239 is vulnerable")
			end
		end
	end
	
	-- Blokuj friendly fire między SCPkami (oprócz SCP-035)
	if target:IsPlayer() and at:IsPlayer() then
		if target:GTeam() == TEAM_SCP and at:GTeam() == TEAM_SCP then
			-- SCP-035 może atakować inne SCP
			if at:GetNClass() == ROLES.ROLE_SCP035 then
				print("[SCP-035 DAMAGE DEBUG] SCP-035 attacking SCP - ALLOWING DAMAGE")
				print("  Attacker: " .. at:Nick() .. " (Class: " .. tostring(at:GetNClass()) .. ")")
				print("  Target: " .. target:Nick() .. " (Class: " .. tostring(target:GetNClass()) .. ")")
				print("  Damage: " .. dmginfo:GetDamage())
				-- SCP-035 może zabijać wszystkich, nawet SCP
				return false -- Pozwól na obrażenia
			end
			
			-- Inne SCP mogą atakować SCP-035
			if target:GetNClass() == ROLES.ROLE_SCP035 then
				print("[SCP-035 DAMAGE DEBUG] SCP attacking SCP-035 - ALLOWING DAMAGE")
				print("  Attacker: " .. at:Nick() .. " (Class: " .. tostring(at:GetNClass()) .. ")")
				print("  Target: " .. target:Nick() .. " (Class: " .. tostring(target:GetNClass()) .. ")")
				print("  Damage: " .. dmginfo:GetDamage())
				-- SCP-035 może być atakowany przez inne SCP
				return false -- Pozwól na obrażenia
			end
			
			print("[EntityTakeDamage] BLOCKING SCP friendly fire")
			print("  Attacker: " .. at:Nick() .. " (Class: " .. tostring(at:GetNClass()) .. ")")
			print("  Target: " .. target:Nick() .. " (Class: " .. tostring(target:GetNClass()) .. ")")
			dmginfo:SetDamage( 0 )
			return true
		end
	end
	
	-- Specjalne zabezpieczenie dla projectiles SCP
	if target:IsPlayer() and IsValid(at) then
		local inflictor = dmginfo:GetInflictor()
		if IsValid(inflictor) and inflictor:GetClass() == "scp_x01j_plasma_projectile" then
			local owner = inflictor:GetOwner()
			if IsValid(owner) and owner:IsPlayer() and owner:GTeam() == TEAM_SCP and target:GTeam() == TEAM_SCP then
				print("[EntityTakeDamage] Blocked SCP projectile friendly fire")
				dmginfo:SetDamage( 0 )
				return true
			end
		end
	end
	
	if at:IsVehicle() or ( at:IsPlayer() and at:InVehicle() ) then
		dmginfo:SetDamage( 0 )
	end

	if target:IsPlayer() then
		if target:Alive() then
			local dmgtype = dmginfo:GetDamageType()
			
			-- SCP fire immunity
			if dmgtype == DMG_BURN or dmgtype == 268435464 or bit.band(dmgtype, DMG_BURN) > 0 then
				if target:GTeam() == TEAM_SCP then
					dmginfo:SetDamage( 0 )
					return true
				end
			end

			if dmgtype == DMG_VEHICLE then
				dmginfo:SetDamage( 0 )
			end
		end
	end

	if at:IsPlayer() and target:IsPlayer() and at:GetNClass() == ROLES.ROLE_SCP9571 and target:GTeam() == TEAM_SCP and target:GetNClass() != ROLES.ROLE_SCP035 then
		return true
	end

	if at:IsPlayer() and ply:IsPlayer() then
		if at.GetActiveWeapon then
			local wep = at:GetActiveWeapon()
			if IsValid(wep) then
				if wep:GetClass() == "weapon_crowbar" then
					dmginfo:ScaleDamage(0.3)
				elseif wep:GetClass() == "weapon_stunstick" then
					dmginfo:ScaleDamage(0.5)
				end
			end
		end

		if SERVER then
		end
	end
end

-- Priority hook for SCP-500 auto-use before death (must be highest priority)
hook.Add("EntityTakeDamage", "SCP500_AutoUse", function(target, dmginfo)
	if not SERVER then return end
	if not IsValid(target) or not target:IsPlayer() then return end
	if preparing or postround then return end
	
	-- SCP-500 automatic use when about to die
	if target:HasWeapon("item_scp_500") then
		if target:Health() <= dmginfo:GetDamage() then
			target:GetWeapon("item_scp_500"):OnUse()
			target:PrintMessage(HUD_PRINTTALK, "Using SCP 500")
		end
	end
end, HOOK_MONITOR_HIGHEST)

-- Additional SCP-239 immortality hook with highest priority
hook.Add("EntityTakeDamage", "SCP239_ImmunitySystem", function(target, dmginfo)
	if not SERVER then return end
	if not IsValid(target) or not target:IsPlayer() then return end
	if target:GetNClass() != ROLES.ROLE_SCP239 then return end
	
	local isVulnerable = target:GetNWBool("SCP239_Vulnerable", false)
	print("[SCP-239 HOOK] Direct hook - Vulnerable:", isVulnerable, "Damage:", dmginfo:GetDamage())
	
	if not isVulnerable then
		-- Complete damage immunity
		dmginfo:SetDamage(0)
		dmginfo:ScaleDamage(0)
		print("[SCP-239 HOOK] BLOCKED via direct hook")
		return true
	end
end, HOOK_HIGH)

function GM:ScalePlayerDamage( ply, hitgroup, dmginfo )
	/*
	if SERVER then
		local at = dmginfo:Getat()
		if ply:GTeam() == at:GTeam() then
			at:TakeDamage( 25, at, at )
		end
	end
	*/
	local at = dmginfo:GetAttacker()

	local mul = 1
	local armormul = 1

	if at:IsPlayer() then
		if at:GTeam() == TEAM_SCP then
			local scale = GetConVar( "br_scale_scp_damage" ):GetFloat()
			if scale == 0 then scale = 1 end
			scale = math.Clamp( scale, 0.1, 5 )
			dmginfo:ScaleDamage( scale )
		elseif at:GTeam() != TEAM_SPEC then
			local scale = GetConVar( "br_scale_human_damage" ):GetFloat()
			if scale == 0 then scale = 1 end
			scale = math.Clamp( scale, 0.1, 5 )
			dmginfo:ScaleDamage( scale )
		end

		if at.GetActiveWeapon then
			local wep = at:GetActiveWeapon()
			if IsValid(wep) then
				-- Engineer crowbar healing for Security Droids
				if wep:GetClass() == "weapon_crowbar" and at:GetNClass() == ROLES.ROLE_ENGINEER and ply:GetNClass() == ROLES.ROLE_SECURITY_DROID then
					if SERVER then
						-- Prevent damage and heal instead
						dmginfo:SetDamage(0)
						
						-- Initialize heal cooldown
						if not at.EngineerHealCooldown then
							at.EngineerHealCooldown = 0
						end
						
						-- Check cooldown (2 seconds)
						if CurTime() >= at.EngineerHealCooldown then
							at.EngineerHealCooldown = CurTime() + 2.0
							
							-- Heal the droid
							local healAmount = 30
							local newHealth = math.min(ply:Health() + healAmount, ply:GetMaxHealth())
							ply:SetHealth(newHealth)
							
							-- Special effects
							at:EmitSound("ambient/energy/newspark0" .. math.random(1, 9) .. ".wav")
							ply:EmitSound("ambient/energy/newspark0" .. math.random(1, 9) .. ".wav")
							
							-- Visual effect
							local effectdata = EffectData()
							effectdata:SetOrigin(ply:GetPos() + Vector(0, 0, 40))
							effectdata:SetEntity(ply)
							effectdata:SetMagnitude(8)
							effectdata:SetScale(2)
							util.Effect("ElectricSpark", effectdata)
							
							-- Clear overheat status if droid is overheated
							if ply.SecurityDroidOverheated then
								ply:SetWalkSpeed(ply.SecurityDroidOriginalSpeeds.walk)
								ply:SetRunSpeed(ply.SecurityDroidOriginalSpeeds.run)
								ply:SetJumpPower(ply.SecurityDroidOriginalSpeeds.jump)
								ply.SecurityDroidOverheated = false
								ply.SecurityDroidStunHits = 0
								
								-- Remove overheat timer
								timer.Remove("SecurityDroid_Overheat_" .. ply:EntIndex())
								
								ply:PrintMessage(HUD_PRINTTALK, "[SYSTEM] Emergency repair complete. Systems restored by Engineer.")
								at:PrintMessage(HUD_PRINTTALK, "[REPAIR] Security Droid systems repaired successfully!")
							else
								ply:PrintMessage(HUD_PRINTTALK, "[SYSTEM] Maintenance repair: +" .. healAmount .. " HP")
								at:PrintMessage(HUD_PRINTTALK, "[REPAIR] Security Droid repaired: +" .. healAmount .. " HP")
							end
						else
							-- Cooldown message
							at:PrintMessage(HUD_PRINTTALK, "[REPAIR] Cooldown: " .. math.ceil(at.EngineerHealCooldown - CurTime()) .. "s")
						end
					end
					return -- Stop processing damage
				elseif wep:GetClass() == "weapon_crowbar" then
					dmginfo:ScaleDamage(0.3)
				elseif wep:GetClass() == "weapon_stunstick" then
					dmginfo:ScaleDamage(0.5)
				end
			end
		end

		if SERVER then
		end
	end
	
	/*
	if SERVER then
		print("DMG to "..ply:GetName().."["..ply:GetClass().."]", "DMG: "..dmginfo:GetDamage(), "TYPE: "..dmginfo:GetDamageType())
	end
	*/
	
	-- Debug: pokaż początkowe obrażenia
	local originalDmg = dmginfo:GetDamage()
	local debugInfo = {}
	
	if SERVER and ply.UsingArmor then
		debugInfo.original = originalDmg
		debugInfo.vest = ply.UsingArmor
		debugInfo.hitgroup = hitgroup
	end
	
	if hitgroup == HITGROUP_HEAD then
		mul = 1.5
	elseif hitgroup == HITGROUP_CHEST then
		mul = 1
	elseif hitgroup == HITGROUP_STOMACH then
		mul = 1
	elseif hitgroup == HITGROUP_LEFTARM or hitgroup == HITGROUP_RIGHTARM then
		mul = 0.9
	elseif hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG then
		mul = 0.8
	end

	if SERVER then
		-- Debug: zapisz mnożnik hitgroup
		if ply.UsingArmor then
			debugInfo.hitgroupMul = mul
		end
		
		-- Redukcja obrażeń od pocisków dla vestów (CW 2.0 compatibility)
		if ply.UsingArmor and at:IsPlayer() then
			local armorProtection = {
				["armor_security"] = 0.90,      -- 10% redukcja
				["armor_mtfguard"] = 0.85,      -- 15% redukcja
				["armor_mtfl"] = 0.83,          -- 17% redukcja
				["armor_mtfmedic"] = 0.85,      -- 15% redukcja
				["armor_csecurity"] = 0.83,     -- 17% redukcja
				["armor_mtfcom"] = 0.73,        -- 27% redukcja
				["armor_hazmat"] = 0.80,        -- 20% redukcja
				["armor_ntf"] = 0.75,           -- 25% redukcja
				["armor_chaosins"] = 0.80,      -- 20% redukcja
				["armor_goc"] = 0.70,           -- 30% redukcja
				["armor_heavysupport"] = 0.50,  -- 50% redukcja (najlepszy vest!)
				["armor_fireproof"] = 1.0,      -- 0% redukcja (tylko ogień)
				["armor_electroproof"] = 1.0    -- 0% redukcja (tylko elektryczność)
			}
			
			if armorProtection[ply.UsingArmor] then
				armormul = armormul * armorProtection[ply.UsingArmor]
				debugInfo.armorMul = armorProtection[ply.UsingArmor]
			end
		end
		
		mul = mul * armormul
		dmginfo:ScaleDamage(mul)
		
		-- Debug: pokaż finalne obrażenia
		if ply.UsingArmor then
			debugInfo.finalMul = mul
			debugInfo.finalDmg = dmginfo:GetDamage()
			print("[VEST DEBUG DETAILED] " .. ply:Nick() .. " | Vest: " .. ply.UsingArmor)
			print("  Original DMG: " .. debugInfo.original)
			print("  Hitgroup: " .. debugInfo.hitgroup .. " (mul: " .. debugInfo.hitgroupMul .. ")")
			print("  Armor reduction: " .. (debugInfo.armorMul or 1))
			print("  Final multiplier: " .. debugInfo.finalMul)
			print("  Final DMG: " .. debugInfo.finalDmg)
			print("  ----")
		end
		if ply:GTeam() == TEAM_SCP and OUTSIDE_BUFF( ply:GetPos() ) then
			dmginfo:ScaleDamage( 0.75 )
		end
		local scale = math.Clamp( GetConVar( "br_scale_bullet_damage" ):GetFloat(), 0.1, 2 )
		dmginfo:ScaleDamage( scale )

		if ply:GetNClass() == ROLES.ROLE_SCP957 then
			local wep = ply:GetActiveWeapon()
			if wep and wep:BuffEnabled() then
				dmginfo:ScaleDamage( 0.1 )
			end
		end

		-- Security Droid: 50% redukcja obrażeń od pocisków
		if ply:GetNClass() == ROLES.ROLE_SECURITY_DROID and at:IsPlayer() then
			local wep = at:GetActiveWeapon()
			if IsValid(wep) and wep:GetClass():find("cw_") then
				dmginfo:ScaleDamage(0.5) -- 50% redukcja od pocisków
			end
		end

		-- Security Droid: system przegrzania od stunstick
		if ply:GetNClass() == ROLES.ROLE_SECURITY_DROID and at:IsPlayer() then
			local wep = at:GetActiveWeapon()
			if IsValid(wep) and wep:GetClass() == "weapon_stunstick" then
				-- Inicjalizuj licznik uderzeń stunstick
				if not ply.SecurityDroidStunHits then
					ply.SecurityDroidStunHits = 0
				end
				
				ply.SecurityDroidStunHits = ply.SecurityDroidStunHits + 1
				
				-- Po 2 uderzeniach - przegrzanie (90% spowolnienie)
				if ply.SecurityDroidStunHits >= 2 then
					-- Efekt przegrzania - dźwięki
					ply:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 100, math.random(80, 120))
					ply:EmitSound("ambient/energy/zap" .. math.random(1, 9) .. ".wav", 100, math.random(90, 110))
					
					-- Efekt wizualny iskier
					local effectdata = EffectData()
					effectdata:SetOrigin(ply:GetPos() + Vector(0, 0, 40))
					effectdata:SetEntity(ply)
					effectdata:SetMagnitude(8)
					effectdata:SetScale(2)
					util.Effect("ElectricSpark", effectdata)
					
					-- Dodatkowe iskry wokół gracza
					for i = 1, 5 do
						timer.Simple(i * 0.2, function()
							if IsValid(ply) and ply.SecurityDroidOverheated then
								local sparkPos = ply:GetPos() + Vector(math.random(-20, 20), math.random(-20, 20), math.random(20, 60))
								local sparkData = EffectData()
								sparkData:SetOrigin(sparkPos)
								sparkData:SetMagnitude(6)
								sparkData:SetScale(1.5)
								util.Effect("ElectricSpark", sparkData)
								ply:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 60, math.random(80, 120))
							end
						end)
					end
					
					-- Komunikat
					ply:PrintMessage(HUD_PRINTTALK, "[SYSTEM] CRITICAL ERROR: OVERHEATING! Systems slowed!")
					
					-- Zapisz oryginalne prędkości jeśli jeszcze nie zapisane
					if not ply.SecurityDroidOriginalSpeeds then
						ply.SecurityDroidOriginalSpeeds = {
							walk = ply:GetWalkSpeed(),
							run = ply:GetRunSpeed(),
							jump = ply:GetJumpPower()
						}
					end
					
					-- Zastosuj 90% spowolnienie (zostaje 10% prędkości)
					ply:SetWalkSpeed(ply.SecurityDroidOriginalSpeeds.walk * 0.1)
					ply:SetRunSpeed(ply.SecurityDroidOriginalSpeeds.run * 0.1)
					ply:SetJumpPower(ply.SecurityDroidOriginalSpeeds.jump * 0.1)
					
					-- Flaga przegrzania
					ply.SecurityDroidOverheated = true
					
					-- Przywróć prędkości po 8 sekundach
					timer.Create("SecurityDroid_Overheat_" .. ply:EntIndex(), 8, 1, function()
						if IsValid(ply) and ply.SecurityDroidOverheated then
							ply:SetWalkSpeed(ply.SecurityDroidOriginalSpeeds.walk)
							ply:SetRunSpeed(ply.SecurityDroidOriginalSpeeds.run)
							ply:SetJumpPower(ply.SecurityDroidOriginalSpeeds.jump)
							ply.SecurityDroidOverheated = false
							ply.SecurityDroidStunHits = 0 -- Reset licznika
							ply:PrintMessage(HUD_PRINTTALK, "[SYSTEM] Cooling complete. Systems restored.")
							ply:EmitSound("ambient/energy/newspark" .. math.random(1, 9) .. ".wav", 75, 100)
						end
					end)
				else
					-- Pierwszy hit - ostrzeżenie
					ply:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 75, math.random(90, 110))
					
					-- Efekt wizualny iskier przy pierwszym uderzeniu
					local effectdata = EffectData()
					effectdata:SetOrigin(ply:GetPos() + Vector(0, 0, 40))
					effectdata:SetEntity(ply)
					effectdata:SetMagnitude(4)
					effectdata:SetScale(1)
					util.Effect("ElectricSpark", effectdata)
					
					ply:PrintMessage(HUD_PRINTTALK, "[SYSTEM] WARNING: Electrical interference detected! (" .. ply.SecurityDroidStunHits .. "/2)")
				end
			end
		end

		-- Nie zmniejszaj obrażeń zadawanych przez SCP-957-1 i SCP-035.
		if at:IsPlayer() then
			if at:GetNClass() == ROLES.ROLE_SCP9571 and ply:GTeam() == TEAM_SCP and ply:GetNClass() != ROLES.ROLE_SCP035 then
				-- Nadal blokuj friendly-fire na innych SCP (oprócz SCP-035)
				return true
			end
			
			-- SCP-035 może atakować wszystkich, nawet SCP
			if at:GetNClass() == ROLES.ROLE_SCP035 then
				return false -- Pozwól na normalne obrażenia
			end
		end
	end
end

function GM:Move( ply, mv )
	if ply:GTeam() == TEAM_SCP and OUTSIDE_BUFF( ply:GetPos() ) then
		local speed = 0.0025
		local ang = mv:GetMoveAngles()
		local vel = mv:GetVelocity()
		if vel.z == 0 then 
			vel = vel + ang:Forward() * mv:GetForwardSpeed() * speed
			vel = vel + ang:Right() * mv:GetSideSpeed() * speed
			vel.z = 0
		end

		mv:SetVelocity( vel )
	end
end

-- Entity names display system (SUPERADMIN ONLY)
if CLIENT then
	local showEntityNames = CreateClientConVar("br_show_entity_names", "0", true, false, "Show entity names above all entities (SuperAdmin only)")
	
	hook.Add("HUDPaint", "BR_EntityNames", function()
		-- Check if player is superadmin
		if not LocalPlayer():IsSuperAdmin() then
			if showEntityNames:GetBool() then
				showEntityNames:SetBool(false)
			end
			return
		end
		
		if not showEntityNames:GetBool() then return end
		
		local tr = LocalPlayer():GetEyeTrace()
		local maxDist = 2000
		
		for _, ent in pairs(ents.GetAll()) do
			if not IsValid(ent) then continue end
			if ent == LocalPlayer() then continue end
			
			local pos = ent:GetPos()
			local distance = pos:Distance(LocalPlayer():GetPos())
			
			if distance > maxDist then continue end
			
			-- Add offset based on entity type
			local offset = Vector(0, 0, 10)
			if ent:IsPlayer() then
				offset = Vector(0, 0, 80)
			elseif ent:IsNPC() then
				offset = Vector(0, 0, 70)
			elseif ent:IsVehicle() then
				offset = Vector(0, 0, 50)
			end
			
			local screenPos = (pos + offset):ToScreen()
			
			if screenPos.visible then
				local alpha = math.Clamp(255 - (distance / maxDist * 255), 0, 255)
				local size = math.Clamp(20 - (distance / maxDist * 10), 10, 20)
				
				-- Entity class name
				draw.SimpleTextOutlined(
					ent:GetClass(),
					"DermaDefaultBold",
					screenPos.x,
					screenPos.y,
					Color(255, 255, 255, alpha),
					TEXT_ALIGN_CENTER,
					TEXT_ALIGN_BOTTOM,
					1,
					Color(0, 0, 0, alpha)
				)
				
				-- Additional info for certain entities
				local extraInfo = ""
				if ent:IsPlayer() then
					extraInfo = ent:Nick() .. " [" .. ent:Health() .. " HP]"
				elseif ent:IsNPC() then
					extraInfo = "NPC [" .. ent:Health() .. " HP]"
				elseif ent:IsWeapon() then
					extraInfo = "Weapon"
				elseif ent:GetClass():find("item_") then
					extraInfo = "Item"
				end
				
				if extraInfo != "" then
					draw.SimpleTextOutlined(
						extraInfo,
						"DermaDefaultBold",
						screenPos.x,
						screenPos.y + 15,
						Color(200, 200, 200, alpha),
						TEXT_ALIGN_CENTER,
						TEXT_ALIGN_BOTTOM,
						1,
						Color(0, 0, 0, alpha)
					)
				end
				
				-- Highlight entity under crosshair
				if tr.Entity == ent then
					draw.SimpleTextOutlined(
						"[TARGETED]",
						"DermaDefaultBold",
						screenPos.x,
						screenPos.y - 15,
						Color(255, 0, 0, alpha),
						TEXT_ALIGN_CENTER,
						TEXT_ALIGN_BOTTOM,
						1,
						Color(0, 0, 0, alpha)
					)
				end
			end
		end
	end)
	
	-- Console command override to check permissions
	cvars.AddChangeCallback("br_show_entity_names", function(name, oldVal, newVal)
		if not LocalPlayer():IsSuperAdmin() and newVal == "1" then
			GetConVar("br_show_entity_names"):SetBool(false)
			chat.AddText(Color(255, 0, 0), "[BREACH] ", Color(255, 255, 255), "Ta komenda jest dostępna tylko dla SuperAdminów!")
		end
	end, "br_entity_names_permission_check")
	
	-- Console command help
	concommand.Add("br_show_entity_names_help", function()
		print("=== Entity Names Display (SUPERADMIN ONLY) ===")
		if LocalPlayer():IsSuperAdmin() then
			print("Use 'br_show_entity_names 1' to enable")
			print("Use 'br_show_entity_names 0' to disable")
			print("Shows class names of all entities within 2000 units")
			print("Additional info shown for players, NPCs, weapons and items")
		else
			print("Ta komenda jest dostępna tylko dla SuperAdminów!")
		end
	end)
end

-- Jarate damage bonus hook
if SERVER then
	hook.Add("EntityTakeDamage", "Breach_JarateDamageBonus", function(target, dmginfo)
		if not IsValid(target) or not target:IsPlayer() then return end
		
		-- Check if target is covered in jarate
		if target.breach_jarate_pissed and target.breach_jarate_pissed > CurTime() then
			local originalDamage = dmginfo:GetDamage()
			local bonusDamage = originalDamage * 0.35 -- 35% bonus damage
			dmginfo:AddDamage(bonusDamage)
			
			-- Play crit sound effect
			sound.Play("orange_blossom/piss/crit_hit_mini" .. tostring(math.random(1, 5)) .. ".wav", target:GetPos(), 75, 100, 1)
		end
	end)
end