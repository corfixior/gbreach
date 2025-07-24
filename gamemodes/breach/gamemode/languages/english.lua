english = {}

english.roundtype = "Round type: {type}"
english.preparing = "Prepare, round will start in {num} seconds"
english.round = "Game is live, good luck!"
english.specialround = "This is special round"

english.lang_pldied = "{num} player(s) died"
english.lang_descaped = "{num} Class D(s) escaped"
english.lang_sescaped = "{num} SCP(s) escaped"
english.lang_rescaped = "{num} Researcher(s) escaped"
english.lang_dcaptured = "Chaos Insurgency captured {num} Class D(s)"
english.lang_rescorted = "MTF escorted {num} Researcher(s)"
english.lang_teleported = "SCP - 106 caputred {num} victim(s) to the Pocket Dimension "
english.lang_snapped = "{num} neck(s) were snapped by SCP173"
english.lang_zombies = 'SCP - 049 "cured the disease" {num} time(s) '
english.lang_secret_found = "Secret has been found"
english.lang_secret_nfound = "Secret has not been found"

english.class_unknown = "Unknown"

english.NRegistry = {
	scpready = "You can be selected as SCP in next round",
	scpwait = "You have to wait %s rounds to be able to play as SCP"
}

english.NFailed = "Filed to access NRegistry with key: %s"

english.votefail = "You already voted or you are not allowed to vote!"
english.votepunish = "Vote for punish or forgive %s"
english.voterules = [[
	Write !punish to punish player or !forgive to forgive him
	The victim vote = 5 votes
	Normal player vote = 1 vote
	Additional 3 votes are calculated from spectators average votes
	Remember you can vote only once!
]]
english.punish = "PUNISH"
english.forgive = "FORGIVE"
english.voteresult = "Voting result against %s is... %s"
english.votes = "From %s players %s voted for punish and %s for forgive"
english.votecancel = "Last punish vote was canceled by admin"

english.eq_tip = "LMB - Select | RMB - Drop"
english.eq_open = "Press 'Q' to open new EQ!"

english.starttexts = {
	ROLE_SCPSantaJ = {
		"You are the SCP-SANTA-J",
		{"Your objective is to escape the facility",
		"You are Santa Claus! Give gifts to everyone!",
		"Merry Christmas and Happy New Year",
		"This is special SCP available only in Christmas event!"}
	},
	ROLE_SCP173 = {
		"You are the SCP-173",
		{"Your objective is to escape the facility",
		"You cannot move when someone is looking at you",
		"Remember, humans are blinking",
		"You have a special ability on RMB: blind everyone around you"}
	},
	ROLE_SCP096 = {
		"You are the SCP-096",
		{"Your objective is to escape the facility",
		"You move extremely fast when somebody is looking",
		"You can scream by using RMB"}
	},
	ROLE_SCP066 = {
		"You are the SCP-066",
		{"Your objective is to escape the facility",
		"You can play VERY loud sound",
		"LMB - attack, RMB - you can destroy windows"}
	},
	ROLE_SCP106 = {
		"You are the SCP-106",
		{"Your objective is to escape the facility",
		"When you touch someone, they will teleport",
		"to your pocket dimension"}
	},
	ROLE_SCP966 = {
		"You are the SCP-966",
		{"Your objective is to escape the facility",
		"You are invisible, humans can only see you using a nvg",
		"You hurt humans when you are near them",
		"You also disorientate them"}
	},
	ROLE_SCP682 = {
		"You are the SCP-682",
		{"Your objective is to escape the facility",
		"You are a Hard-to-Destroy Reptile",
		"You kill people instantly, although you are very slow",
		"You have a special ability on RMB"}
	},
	ROLE_SCP457 = {
		"You are the SCP-457",
		{"Your objective is to escape then facility",
		"You are always burning",
		"If you are close enough to a human, you will burn them"}
	},
	ROLE_SCP049 = {
		"You are the SCP-049",
		{"Your objective is to escape the facility",
		"If you use your special ability on someone, they will become SCP-049-2"}
	},
	ROLE_SCP689 = {
		"You are the SCP-689",
		{"Your objective is to escape the facility",
		"You are extremly slow, but also deadly",
		"You can kill anyone who look at you",
		"After you kill someone, you appear on the body",
		"LMB - attack, RMB - destroy windows"}
	},
	ROLE_SCP939 = {
		"You are the SCP-939",
		{"Your objective is to escape the facility",
		"Your are fast and strong",
		"You can deceive your targets by talking in their voice chat",
		"LMB - attack, RMB - change voice chat"}
	},
	ROLE_SCP999 = {
		"You are the SCP-999",
		{"Your objective is to escape the facility",
		"You can heal anybody you want",
		"You have to co-operate with other personnel or SCPs"}
	},
	ROLE_SCP082 = {
		"You are the SCP-082",
		{"Your objective is to escape the facility",
		"You are a cannibal with a machete",
		"Your attacks reduces your target's stamina",
		"When you kill somebody you will gain health"}
	},
	ROLE_SCP054 = {
		"You are the SCP-054",
		{"Your objective is to escape the facility",
		"You are a water-based entity",
		"LMB - Water laser attack, RMB - Steam explosion",
		"You have damage reduction against most attacks"}
	},
	ROLE_SCP2521 = {
		"You are the SCP-2521",
		{"Your objective is to escape the facility",
		"You are a dark entity that feeds on information",
		"LMB - Dark Strike (99 DMG), RMB - Silence Field",
		"R - Teleport, PASSIVE - Damage from chat/voice"}
	},
	ROLE_SCP239 = {
		"You are the SCP-239",
		{"Your objective is to escape the facility",
		"You are a reality bender with immense power",
		"LMB - Random reality manipulation ability",
		"You are immortal most of the time, but vulnerable every 2 minutes"}
	},
	ROLE_SCP3166 = {
		"You are the SCP-3166",
		{"Your objective is to escape the facility",
		"You are Garfield, a malevolent entity",
		"LMB - Claw attack (75 damage, 150 to lasagna target)",
		"RMB - Select new lasagna target",
		"PASSIVE - Kill lasagna target for +1500 HP and 50% speed boost"}
	},
	ROLE_SCPTTT_SAHUR = {
		"You are the SCP-TTT-SAHUR",
		{"Your objective is to escape the facility",
		"You are a dangerous entity wielding a baseball bat",
		"LMB - Baseball bat attack (60 damage)",
		"Fast and aggressive melee combat"}
	},
	ROLE_SCP1316 = {
		"You are the SCP-1316",
		{"Your objective is to escape the facility",
		"You are a cat-like entity with riding abilities",
		"LMB - Ride/Stop riding non-SCP players",
		"RMB - Defensive ability (99% damage reduction + 2x speed)",
		"When riding: You become invisible, immortal, and grant target +1 HP/s + 20% speed"}
	},
	ROLE_SCP2137J = {
		"You are the SCP-2137-J",
		{"Your objective is to escape the facility",
		"You are the holy Papaj entity",
		"LMB - Throw kremówka (explodes after 3 seconds)",
		"Kremówka deals AOE damage to non-SCP players"}
	},
	ROLE_SCPSTEVEJ = {
		"You are the SCP-Steve-J",
		{"Your objective is to escape the facility",
		"You are the legendary Minecraft Steve",
		"LMB - Diamond Sword attack (melee)",
		"RMB - Throw Ender Pearl (teleports you to impact location)"}
	},
	ROLE_SCPIMPOSTORJ = {
		"You are the SCP-Impostor-J",
		{"Your objective is to escape the facility",
		"You are a suspicious crewmate from Among Us",
		"LMB - Bowie knife attack (38 damage)",
		"Simple melee combat with knife weapon"}
	},
	ROLE_SCP617 = {
		"You are the SCP-617",
		{"Your objective is to escape the facility",
		"You are a Petrifying Statue",
		"PASSIVE - Anyone who touches you turns to stone",
		"No abilities needed - just exist and be deadly"}
	},
	ROLE_SCP3199 = {
		"You are the SCP-3199",
		{"Your objective is to escape the facility",
		"You are a hostile humanoid entity",
		"LMB - Bite attack, RMB - Corrosive spit",
		"Use Reload to roar and intimidate enemies"}
	},
	ROLE_SCP0082 = {
		"You are the SCP-0082",
		{"Your objective is to escape the facility",
		"You are a cannibal with a machete",
		"Your attacks reduces your target's stamina",
		"When you kill somebody you will gain health"}
	},
	ROLE_SCP023 = {
		"You are the SCP-023",
		{"Your objective is to escape the facility",
		"You are a wolf and you ignite everyone who goes through you",
		"Igniting others regenerate your health",
		"LMB - attack, RMB - you gain speed but you lose heath"}
	},
	ROLE_SCP1471 = {
		"You are the SCP-1471-A",
		{"Your objective is to escape the facility",
		"You can teleport yourself to your target",
		"LMB - attack, RMB - teleport to your target"}
	},
	ROLE_SCP1048A = {
		"You are the SCP-1048-A",
		{"Your objective is to escape the facility",
		"You look like SCP-1048, but you are made entirely out of human ears",
		"You emit a very loud scream"}
	},
	ROLE_SCP1048B = {
		"You are the SCP-1048-B",
		{"Your objective is to escape the facility",
		"Kill'em all"}
	},
	ROLE_SCP8602 = {
		"You are the SCP-860-2",
		{"Your objective is to escape the facility",
		"You are forest monster",
		"When you attack somebody near wall you charging on him"}
	},
	ROLE_SCP0492 = {
		"You are the SCP-049-2",
		{"Your objective is to escape the facility",
		"Cooperate with SCP-049 to kill more people"}
	},
	ROLE_SCP035 = {
		"You are SCP-035 - The Possessive Mask",
		{"Your objective is to escape the facility",
		"You can use human equipment and weapons",
		"You can kill both humans AND other SCPs",
		"You are the universal threat - everyone is your enemy"}
	},
	ROLE_SCP076 = {
		"You are the SCP-076-2",
		{"Your objective is to escape the facility",
		"You are fast and you have low HP",
		"You will be respawning until somebody destroy SCP-076-1"}
	},
	ROLE_SCP957 = {
		"You are the SCP-957",
		{"Your objective is to escape the facility",
		"You receive less damage, but on SCP-957-1 death you will receive damage",
		"Use LMB to deal AOE damage",
		"After attack, you and SCP-957-1 will receive some health"}
	},
	ROLE_SCP9571 = {
		"You are the SCP-957-1",
		{"Your objective is bring your friends to SCP-957",
		"Your vision is limited and you can talk with SCP-957",
		"Nobody knows that you are SCP, don't get exposed",
		"If you die, SCP-957 will receive damage"}
	},
	ROLE_SCP069 = {
		"You are SCP-069",
		{"Your objective is to escape the facility",
		"You can instantly kill humans with your touch",
		"You can disguise as your victims",
		"LMB - Instant kill touch, RMB - Open disguise menu"}
	},
	ROLE_SCPDOOMGUYJ = {
		"You are SCP-DOOMGUY-J - The Doom Slayer",
		{"Your objective is to escape the facility",
		"You wield the legendary DOOM Crucible sword",
		"LMB - Light melee attack | RMB - Heavy melee attack",
		"Your attacks deal massive damage to all enemies",
		"Rip and tear until it is done!"}
	},
	ROLE_SCP0082 = {
		"You are the SCP-008-2",
		{"Your objective is to infect every MTF and D",
		"If you kill someone, they will become 008-2 aswell"}
	},
	ROLE_RES = {
		"You are a Researcher",
		{"Your objective is to escape from the facility",
		"You need to find a MTF Guard that will help you",
		"Be on the look out of Class Ds as they might try to kill you"}
	},
	ROLE_MEDIC = {
		"You are a Medic",
		{"Your objective is to escape from the facility",
		"You need to find a MTF Guards that will help you",
		"Be on the look out of Class Ds as they might try to kill you",
		"If someone gets injured, heal them"}
	},
	ROLE_NO3 = {
		"You are a Level 3 Researcher",
		{"Your objective is to escape from the facility",
		"You know this place as nobody else",
		"Be on the look out of Class Ds as they might try to kill you",
		"You can communicate with security using the radio"}
	},
	ROLE_JANITOR = {
		"You are a Janitor",
		{"Your objective is to escape from the facility",
		"You maintain and clean the facility",
		"Use your broom to clean decals and move objects",
		"You have basic keycard access"}
	},
	ROLE_VIP = {
		"You are a VIP",
		{"You have special access to checkpoints",
		"Use your radio to coordinate with other personnel",
		"You may have a pocket knife for self-defense (25% chance)",
		"Help researchers and maintain facility security"}
	},
	ROLE_CLEARANCE_TECH = {
		"You are a Clearance Technician",
		{"You maintain and repair facility systems",
		"Use your radio to coordinate with researchers",
		"You may have a Universal Access Device (10% chance) - can override any door",
		"Your SCP Radar detects nearby anomalies visually",
		"You have standard researcher keycard access",
		"Help maintain facility operations and security"}
	},
	ROLE_ENGINEER = {
		"You are an Engineer",
		{"You design and maintain facility infrastructure",
		"Use your radio to coordinate with research teams",
		"You have standard researcher keycard access",
		"Your crowbar can repair Security Droids (+30 HP)",
		"You can fix overheated Security Droid systems",
		"Your Door Hacker can unlock locked doors (3 uses)",
		"Solve the memory sequence minigame to hack doors",
		"Help with technical operations and system maintenance"}
	},
	ROLE_COOK = {
		"You are a Cook",
		{"Your objective is to escape from the facility",
		"You prepare meals for facility personnel",
		"You have standard researcher keycard access",
		"Your doner knife is excellent for food preparation and self-defense",
		"Use your Kebab Stand Spawner to deploy döner stands",
		"Deploy stands in safe areas to serve nutritious food",
		"Kebab and ayran provide health restoration to consumers",
		"Help maintain facility morale through quality catering"}
	},
	ROLE_DRHOUSE = {
		"You are Dr. House",
		{"Your objective is to escape from the facility",
		"You are a brilliant but unconventional diagnostician",
		"Your medical syringe can heal injured personnel",
		"Your walking cane (House Canebar) serves as both support and weapon",
		"Use your medical expertise to help other survivors",
		"Your cynical wit and pill addiction don't affect your medical skills",
		"Everybody lies, but your diagnoses are usually correct",
		"PASSIVE: Death Harvest - gain 10 HP when someone dies nearby",
		"Solve medical mysteries and survive the containment breach"}
	},
	ROLE_PSYCHOLOGIST = {
		"You are a Site Psychologist",
		{"Your objective is to escape from the facility",
		"You provide psychological support to facility personnel",
		"You have standard researcher keycard access",
		"Your training helps you understand human behavior",
		"Use your radio to provide therapeutic communication",
		"Help maintain team morale and mental health",
		"Your psychological expertise may reveal hidden threats",
		"Assist in managing stress and trauma responses",
		"Support facility personnel through crisis situations"}
	},
	ROLE_CLASSD = {
		"You are a Class D",
		{"Your objective is to escape from the facility",
		"You need to cooperate with other Class Ds",
		"Search for keycards and be aware of MTF and SCPs"}
	},
	ROLE_VETERAN = {
		"You are a Veteran Class D",
		{"Your objective is to escape from the facility",
		"You need to cooperate with other Class Ds",
		"Search for keycards and be aware of MTF and SCPs",
		"25% chance to spawn with Jarate - a throwable jar of piss that marks enemies"}
	},
	ROLE_SCOUT_D = {
		"You are a Scout D",
		{"Your objective is to escape from the facility",
		"You are faster and more agile than regular Class D",
		"Use your speed to scout ahead and find escape routes",
		"Cooperate with other Class D personnel"}
	},
	ROLE_FAT_D = {
		"You are a Fat D",
		{"Your objective is to escape from the facility",
		"You are larger and slower than regular Class D",
		"You have more health but reduced mobility",
		"Use your bulk to block doorways and protect others"}
	},
	ROLE_SKINNY_D = {
		"You are a Skinny D",
		{"Your objective is to escape from the facility",
		"You are thinner and faster than regular Class D",
		"You have less health but increased mobility",
		"Use your speed and agility to avoid dangers"}
	},

	ROLE_THIEF_D = {
		"You are a Thief D",
		{"Your objective is to escape from the facility",
		"You are a skilled pickpocket and thief",
		"PASSIVE: Weapon Theft - Press E on players to steal their active weapon",
		"Cannot steal from SCPs, holsters, or security tags",
		"Ability has 60-second cooldown after each successful theft",
		"Use your thievery skills to arm yourself and other Class D"}
	},
	ROLE_SCP527 = {
		"You are SCP-527 (Mr. Fish)",
		{"Your objective is to escape from the facility",
		"You appear as a normal Class D personnel to others",
		"You are actually an anomalous humanoid with a fish head",
		"Nobody seems to notice anything unusual about you"}
	},
	ROLE_CIC = {
		"You are a Chaos Insurgency Agent",
		{"Your objective is to help Class D",
		"You organize them",
		"Be aware of MTF and SCPs, and wait for support"}
	},
	ROLE_SECURITY = {
		"You are a Security Officer",
		{"Your objective is to find and rescue all",
		"of the researchers that are still in the facility",
		"You have to kill any Class D or SCP that you will find",
		"Listen to your boss's orders and stick to your team"}
	},
	ROLE_CSECURITY = {
		"You are a Security Chief",
		{"Your objective is to find and rescue all",
		"of the researchers that are still in the facility",
		"You have to kill any Class D or SCP that you will find",
		"Give orders to Security Officers and listen to your boss"}
	},
	ROLE_MTFGUARD = {
		"You are a MTF Guard",
		{"Your objective is to find and rescue all",
		"of the researchers that are still in the facility",
		"You have to kill any Class D or SCP that you will find",
		"Listen to MTF Commander's orders and stick to your team"}
	},
	ROLE_MTF_HEAVY_SUPPORT = {
		"You are a MTF Heavy Support",
		{"Your objective is to provide heavy firepower support",
		"You have the best armor but move slower",
		"Your role is to eliminate high-threat targets",
		"Listen to MTF Commander's orders and protect your team"}
	},
	ROLE_SECURITY_DROID = {
		"You are a Security Droid",
		{"Your objective is to find and rescue all",
		"of the researchers that are still in the facility",
		"You have to kill any Class D or SCP that you will find",
		"You cannot wear armor but take 50% less bullet damage",
		"WARNING: 2 stunstick hits cause overheating (90% slower for 8s)!"}
	},
	-- ROLE_MEDIC_DROID = { -- Usunięto klasę Medic Droid
	-- 	"You are a Medic Droid",
	-- 	{"Your objective is to support Security Droids and MTF personnel",
	-- 	"You cannot pick up any CW2 weapons - you are a medical unit",
	-- 	"PASSIVE ABILITY: Hold E on Security Droid with <50% HP to heal them to 50%",
	-- 	"You are equipped with advanced medical protocols",
	-- 	"Focus on keeping your team alive and operational"}
	-- },
	ROLE_MTFMEDIC = {
		"You are a MTF Medic",
		{"Your objective is support your teammates",
		"If someone gets injured, heal them",
		"Listen to MTF Commander's orders and stick to your team"}
	},
	ROLE_HAZMAT = {
		"You are a Special MTF Unit",
		{"Your objective is to find and rescue all",
		"of the researchers that are still in the facility",
		"You have to kill any Class Ds or SCPs that you will find",
		"Listen to the MTF Commander and Site Director"}
	},
	ROLE_MTFL = {
		"You are a MTF Lieutenant",
		{"Your objective is to find and rescue all",
		"of the researchers that are still in the facility",
		"You have to kill any Class Ds or SCPs that you will find",
		"Give orders to Guards to simplify the task",
		"Listen to the MTF Commander and Site Director"}
	},
	ROLE_SD = {
		"You are a Site Director",
		{"Your objective is to give objectives",
		"You need to give objectives to the site security",
		"You need to keep the site secure, don't let any SCP or Class D escape"}
	},
	ROLE_O5 = {
		"You are O5 Council Member",
		{"Your have unlimited access to everything",
		"You are the most important person here, give orders",
		"Do everything what you can to save foundation reputation and world"}
	},
	ROLE_MTFNTF = {
		"You are a MTF Unit Nine-Tailed Fox",
		{"Your objective is to find and rescue all",
		"of the researchers that are still in the facility",
		"You have to kill any Class D or SCP that you will find",
		"Go to the facility and help Guards to embrace a chaos"}
	},
	ROLE_MTFCOM = {
		"You are a MTF Commander",
		{"Your objective is to find and rescue all",
		"of the researchers that are still in the facility",
		"You have to kill any Class Ds or SCPs that you will find",
		"Give orders to Guards to simplify the task"}
	},
	ROLE_CHAOS = {
		"You are the Chaos Insurgency Soldier",
		{"Your objective is to capture as much Class Ds as it is possible",
		"Escort them to the helipad outisde of the facility",
		"You have to kill anyone who will stop you"}
	},
	ROLE_CHAOSSPY = {
		"You are the Chaos Insurgency Spy",
		{"Your objective is to kill all MTF Guards and capture the Class D",
		"They are unaware of your disguise",
		"Don't destroy your disguise",
		"If you find any class ds, try to escort them to the helipad"}
	},
	ROLE_CHAOSCOM = {
		"You are the Chaos Insurgency Commander",
		{"Your objective is to give objectives to your team",
		"Kill anyone who will stop you"}
	},
	ROLE_GOC_SOLDIER = {
		"You are a GOC Soldier",
		{"Your mission is to eliminate all anomalous entities and hostile personnel",
		"You have no allies - everyone is your enemy",
		"Secure, Contain, Protect - by any means necessary"}
	},
	ROLE_GOC_OPERATIVE = {
		"You are a GOC Operative",
		{"Advanced operative tasked with anomaly containment and elimination",
		"Trust no one - eliminate all threats to normalcy",
		"Use your training to neutralize all anomalous activity"}
	},
	ROLE_GOC_COMMANDER = {
		"You are a GOC Commander",
		{"Lead GOC operations and coordinate elimination protocols",
		"Your authority extends to all anomalous threats",
		"Command your forces to restore normalcy"}
	},
	ROLE_SPEC = {
		"You are a Spectator",
		{'Use command "br_spectate" to come back'}
	},
	ADMIN = {
		"You are in admin mode",
		{'Use command "br_admin_mode" to come back in next round'}
	},
	ROLE_INFECTD = {
		"You are Class D Presonnel",
		{'This is special round "infect"',
		"You need to cooperate with MTFs to stop the infection",
		"When you will be killed by zombie you will be one of them"}
	},
	ROLE_INFECTMTF = {
		"You are MTF",
		{'This is special round "infect"',
		"You need to cooperate with D Class to stop the infection",
		"When you will be killed by zombie you will be one of them"}
	},
	

}

english.lang_end1 = "The game ends here"
english.lang_end2 = "Time limit has been reached"
english.lang_end3 = "Game ended due to the inability to continue"

english.escapemessages = {
	{
		main = "You escaped",
		txt = "You escaped the facility in {t} minutes, good job!",
		txt2 = "Try to get escorted by MTF next time to get bonus points.",
		clr = Color(237, 28, 63),
	},
	{
		main = "You escaped",
		txt = "You escaped the facility in {t} minutes, good job!",
		txt2 = "Try to get escorted by Chaos Insurgency Soldiers next time to get bonus points.",
		clr = Color(237, 28, 63),
	},
	{
		main = "You were escorted",
		txt = "You were escorted in {t} minutes, good job!",
		txt2 = "",
		clr = Color(237, 28, 63),
	},
	{
		main = "You escaped",
		txt = "You escaped in {t} minutes, good job!",
		txt2 = "",
		clr = Color(237, 28, 63),
	}
}



english.ROLES = {}

english.ROLES.ADMIN = "ADMIN MODE"
english.ROLES.ROLE_INFECTD = "Class D Personnel"
english.ROLES.ROLE_INFECTMTF = "MTF"

english.ROLES.ROLE_SCPSantaJ = "SCP-SANTA-J"
english.ROLES.ROLE_SCP173 = "SCP-173"
english.ROLES.ROLE_SCP106 = "SCP-106"
english.ROLES.ROLE_SCP049 = "SCP-049"
english.ROLES.ROLE_SCP457 = "SCP-457"
english.ROLES.ROLE_SCP966 = "SCP-966"
english.ROLES.ROLE_SCP096 = "SCP-096"
english.ROLES.ROLE_SCP066 = "SCP-066"
english.ROLES.ROLE_SCP689 = "SCP-689"
english.ROLES.ROLE_SCP682 = "SCP-682"
english.ROLES.ROLE_SCP082 = "SCP-082"
english.ROLES.ROLE_SCP939 = "SCP-939"
english.ROLES.ROLE_SCP999 = "SCP-999"
english.ROLES.ROLE_SCP023 = "SCP-023"
english.ROLES.ROLE_SCP076 = "SCP-076-2"
english.ROLES.ROLE_SCP1471 = "SCP-1471-A"
english.ROLES.ROLE_SCP8602 = "SCP-860-2"
english.ROLES.ROLE_SCP1048A = "SCP-1048-A"
english.ROLES.ROLE_SCP1048B = "SCP-1048-B"
english.ROLES.ROLE_SCP0492 = "SCP-049-2"
english.ROLES.ROLE_SCP035 = "SCP-035"
english.ROLES.ROLE_SCP0082 = "SCP-008-2"
english.ROLES.ROLE_SCP957 = "SCP-957"
english.ROLES.ROLE_SCP9571 = "SCP-957-1"
english.ROLES.ROLE_SCP069 = "SCP-069"
english.ROLES.ROLE_SCPDOOMGUYJ = "SCP-DOOMGUY-J"
english.ROLES.ROLE_SCP3199 = "SCP-3199"
english.ROLES.ROLE_SCP054 = "SCP-054"
english.ROLES.ROLE_SCP2521 = "SCP-2521"
english.ROLES.ROLE_SCP239 = "SCP-239"
english.ROLES.ROLE_SCP3166 = "SCP-3166"
english.ROLES.ROLE_SCPTTT_SAHUR = "SCP-TTT-SAHUR"
english.ROLES.ROLE_SCP1316 = "SCP-1316"
english.ROLES.ROLE_SCP2137J = "SCP-2137-J"
english.ROLES.ROLE_SCPSTEVEJ = "SCP-Steve-J"
english.ROLES.ROLE_SCPIMPOSTORJ = "SCP-Impostor-J"
english.ROLES.ROLE_SCP617 = "SCP-617"

english.ROLES.ROLE_RES = "Researcher"
english.ROLES.ROLE_MEDIC = "Medic"
english.ROLES.ROLE_NO3 = "Level 3 Researcher"
english.ROLES.ROLE_JANITOR = "Janitor"
english.ROLES.ROLE_VIP = "VIP"
english.ROLES.ROLE_CLEARANCE_TECH = "Clearance Technician"
english.ROLES.ROLE_ENGINEER = "Engineer"
english.ROLES.ROLE_COOK = "Cook"
english.ROLES.ROLE_DRHOUSE = "Dr. House"
english.ROLES.ROLE_PSYCHOLOGIST = "Site Psychologist"
english.ROLES.ROLE_DCLASS_INFECTED = "D-Class Infected"

english.ROLES.ROLE_CLASSD = "Class D Personnel"
english.ROLES.ROLE_VETERAN = "Class D Veteran"
english.ROLES.ROLE_SCOUT_D = "Scout D"
english.ROLES.ROLE_FAT_D = "Fat D"
english.ROLES.ROLE_SKINNY_D = "Skinny D"
english.ROLES.ROLE_THIEF_D = "Thief D"

english.ROLES.ROLE_SCP527 = "SCP-527"
english.ROLES.ROLE_CIC = "CI Agent"

english.ROLES.ROLE_SECURITY = "Security Officer"
english.ROLES.ROLE_MTFGUARD = "MTF Guard"
english.ROLES.ROLE_MTF_HEAVY_SUPPORT = "MTF Heavy Support"
english.ROLES.ROLE_SECURITY_DROID = "Security Droid"
-- english.ROLES.ROLE_MEDIC_DROID = "Medic Droid" -- Usunięto klasę Medic Droid
english.ROLES.ROLE_MTFMEDIC = "MTF Medic"
english.ROLES.ROLE_MTFL = "MTF Lieutenant"
english.ROLES.ROLE_HAZMAT = "MTF SCU"
english.ROLES.ROLE_MTFNTF = "MTF NTF"
english.ROLES.ROLE_CSECURITY = "Security Chief"
english.ROLES.ROLE_MTFCOM = "MTF Commander"
english.ROLES.ROLE_SD = "Site Director"
english.ROLES.ROLE_O5 = "O5 Council Member"

english.ROLES.ROLE_CHAOSSPY = "CI Spy"
english.ROLES.ROLE_CHAOS = "CI Soldier"
english.ROLES.ROLE_CHAOSCOM = "CI Commander"

english.ROLES.ROLE_GOC_SOLDIER = "GOC Soldier"
english.ROLES.ROLE_GOC_OPERATIVE = "GOC Operative"
english.ROLES.ROLE_GOC_COMMANDER = "GOC Commander"

english.ROLES.ROLE_SPEC = "Spectator"

english.credits_orig = "Created by:"
english.credits_edit = "Modified and repaired by:"
english.settings = "Settings"
english.updateinfo = "Show changes after update"
english.done = "Ready"
english.repe = "Write br_reset_intro to show intro again"

english.author = "Author"
english.helper = "Assistant"
english.originator = "Collaborator"

english.updates = {
	"english",
	"Update notes",
	"Update notes of version %s are unavailable",
	"Server version",
}

-- Weapon descriptions
english.WEAPON_UNIVERSAL_ACCESS = {
	name = "Universal Access Device",
	desc = "Advanced override device that can bypass any door system. Limited uses with cooldown."
}

english.WEAPON_SCP_RADAR = {
	name = "SCP Radar",
	desc = "Passive radar display showing SCP locations. Works automatically when in inventory."
}

english.DONER_KNIFE = {
	name = "Döner Kebab Knife",
	author = "Professional Kitchen Equipment Ltd.",
	contact = "chef@kitchen.com",
	purpose = "Professional-grade chef's knife for döner preparation",
	instructions = [[Professional chef's knife used for cutting döner kebab.
Sharp blade excellent for food preparation and self-defense.

LMB - Light cut (15-20 dmg)
RMB - Heavy stab (45 dmg, 80 backstab)
R - Inspect]]
}

-- VIP Panic Button messages
english.VIP_PANIC = {
	button_hint = "Press [P] - VIP Panic Button",
	cooldown_hint = "VIP Panic Button - Cooldown: %ds",
	signal_sent = "[PANIC] Emergency signal sent to security forces!",
	cooldown_active = "[PANIC] Cooldown: %ds",
	phase_blocked = "[PANIC] Cannot use panic button during this phase!",
	alert_message = "%s has activated their panic button!",
	alert_prefix = "[VIP PANIC] ",
	bind_suggestion = "Press P for panic button or type 'vip_panic' in console!"
}



ALLLANGUAGES.english = english
