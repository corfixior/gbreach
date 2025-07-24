CLASSMENU = nil
selectedclass = nil
selectedclr = nil

surface.CreateFont("MTF_2Main",   {font = "Trebuchet24",
									size = 20,
									weight = 750})
surface.CreateFont("MTF_Main",   {font = "Trebuchet24",
									size = ScreenScale(9),
									weight = 750})
surface.CreateFont("MTF_Secondary", {font = "Trebuchet24",
									size = ScreenScale(14),
									weight = 750,
									shadow = true})
surface.CreateFont("MTF_Third", {font = "Trebuchet24",
									size = ScreenScale(10),
									weight = 750,
									shadow = true})

--[[-----------------------------------------------------------------
	Pre-defined modele dla SCP – używane w podglądzie F2.
	Wzięte z sv_base_scps.lua, aby uniknąć BRENA / ERROR.
-------------------------------------------------------------------]]
local SCP_MODEL_MAP = {
	["SCP023"]    = "models/Novux/023/Novux_SCP-023.mdl",
	["SCP049"]    = "models/vinrax/player/scp049_player.mdl",
	["SCP0492"]   = "models/player/zombie_classic.mdl",
	["SCP054"]    = "models/xiali/scp_054/ctg/scp_054.mdl",
	["SCP066"]    = "models/player/mrsilver/scp_066pm/scp_066_pm.mdl",
	["SCP076"]    = "models/abel/abel.mdl",
	["SCP082"]    = "models/models/konnie/savini/savini.mdl",
	["SCP096"]    = "models/scp096anim/player/scp096pm_raf.mdl",
	["SCP106"]    = "models/scp/106/unity/unity_scp_106_player.mdl",
	["SCP173"]    = "models/jqueary/scp/unity/scp173/scp173unity.mdl",
	["SCP457"]    = "models/player/corpse1.mdl",
	["SCP682"]    = "models/scp_682/scp_682.mdl",
	["SCP689"]    = "models/dwdarksouls/models/darkwraith.mdl",
	["SCP8602"]   = "models/props/forest_monster/forest_monster2.mdl",
	["SCP939"]    = "models/scp/939/unity/unity_scp_939.mdl",
	["SCP957"]    = "models/immigrant/outlast/walrider_pm.mdl",
	["SCP966"]    = "models/player/mishka/966_new.mdl",
	["SCP999"]    = "models/scp/999/jq/scp_999_pmjq.mdl",
	["SCP1048A"]  = "models/1048/tdyear/tdybrownearpm.mdl",
	["SCP1048B"]  = "models/player/teddy_bear/teddy_bear.mdl",
	["SCP1316"] = "models/yevocore/cat/cat.mdl",
	["SCP1471"]   = "models/burd/scp1471/scp1471.mdl",
	["SCP2137J"] = "models/t37/papaj.mdl",
	["SCPSTEVEJ"] = "models/minecraft/steve/steve.mdl",
	["SCP069"]    = "models/player/alski/re2remake/mr_x.mdl",
	["SCP2521"]   = "models/cultist/scp/scp_no1.mdl",
	["SCP239"]    = "models/cultist/scp/scp_239.mdl",
	["SCP3166"]   = "models/nickelodeon_all_stars/garfield/garfield.mdl",
	["SCPIMPOSTORJ"]   = "models/lenoax/amongus/suit_pm.mdl",
	["SCP3199"]   = "models/washton/3199.mdl",
	["SCPDOOMGUYJ"] = "models/player/doom_fn_pm.mdl",
	["SCPTTT_SAHUR"] = "models/gacommissions/tungtungtungsahur.mdl"
}

-- Stała lista SCP dla Class Manager
local ALL_SCPS = {
	"SCP023", "SCP049", "SCP0492", "SCP054", "SCP066", "SCP069", "SCP076", "SCP082",
	"SCP096", "SCP106", "SCP173", "SCP239", "SCP457", "SCP682", "SCP689",
	"SCP8602", "SCP939", "SCP957", "SCP966", "SCP999", "SCP1048A",
	"SCP1048B", "SCP1316", "SCP1471", "SCP2137J", "SCPSTEVEJ", "SCP2521", "SCP3166", "SCPIMPOSTORJ", "SCP3199", "SCPDOOMGUYJ", "SCPTTT_SAHUR"
}

function OpenClassMenu()
	if IsValid(CLASSMENU) then return end
	local ply = LocalPlayer()
	
	surface.CreateFont("MTF_2Main",   {font = "Trebuchet24",
										size = 35,
										weight = 750})
	surface.CreateFont("MTF_Main",   {font = "Trebuchet24",
										size = ScreenScale(9),
										weight = 750})
	surface.CreateFont("MTF_Secondary", {font = "Trebuchet24",
										size = ScreenScale(14),
										weight = 750,
										shadow = true})
	surface.CreateFont("MTF_Third", {font = "Trebuchet24",
										size = ScreenScale(10),
										weight = 750,
										shadow = true})
	
	local ourlevel = LocalPlayer():GetLevel()
	
	selectedclass = ALLCLASSES["support"]["roles"][1]
	selectedclr = ALLCLASSES["support"]["color"]
	
	if selectedclr == nil then selectedclr = Color(255,255,255) end
	
	local width = ScrW() / 1.5
	local height = ScrH() / 1.5
	
	CLASSMENU = vgui.Create( "DFrame" )
	CLASSMENU:SetTitle( "" )
	CLASSMENU:SetSize( width, height )
	CLASSMENU:Center()
	CLASSMENU:SetDraggable( true )
	CLASSMENU:SetDeleteOnClose( true )
	CLASSMENU:SetDraggable( false )
	CLASSMENU:ShowCloseButton( true )
	CLASSMENU:MakePopup()
	CLASSMENU.Paint = function( self, w, h )
		draw.RoundedBox( 2, 0, 0, w, h, Color(0, 0, 0) )
		draw.RoundedBox( 2, 1, 1, w - 2, h - 2, Color(90, 90, 95) )
	end
	
	local maininfo = vgui.Create( "DLabel", CLASSMENU )
	maininfo:SetText( "Class Manager" )
	maininfo:Dock( TOP )
	maininfo:SetFont("MTF_Main")
	maininfo:SetContentAlignment( 5 )
	//maininfo:DockMargin( 245, 8, 8, 175	)
	maininfo:SetSize(0,28)
	maininfo.Paint = function( self, w, h )
		draw.RoundedBox( 2, 0, 0, w, h, Color(0, 0, 0) )
		draw.RoundedBox( 2, 1, 1, w - 2, h - 2, Color(90, 90, 95) )
	end
	
	local panel_right = vgui.Create( "DPanel", CLASSMENU )
	panel_right:Dock( FILL )
	panel_right:DockMargin( width / 2 - 5, 0, 0, 0	)
	panel_right.Paint = function( self, w, h ) end
	
	
	local sclass_toppanel = vgui.Create( "DPanel", panel_right )
	sclass_toppanel:Dock( TOP )
	sclass_toppanel:SetSize(0, height / 2.5)
	sclass_toppanel.Paint = function( self, w, h ) end
	
	local smodel
	if selectedclass.showmodel == nil then
		smodel = table.Random(selectedclass.models)
	else
		smodel = selectedclass.showmodel
	end
	
	local class_modelpanel = vgui.Create( "DPanel", sclass_toppanel )
	class_modelpanel:Dock( LEFT )
	class_modelpanel:SetSize(width / 6)
	class_modelpanel.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color(50,50,50) )
	end

	sclass_model = vgui.Create( "DModelPanel", class_modelpanel )
	sclass_model:Dock( FILL )
	sclass_model:SetFOV(50)
	sclass_model:SetModel( smodel )
	function sclass_model:LayoutEntity( entity )
		entity:SetAngles(Angle(0,18,0))
		
		-- Ustaw bodygroups dla SCP-527
		if selectedclass.name == ROLES.ROLE_SCP527 then
			local hatGroup = entity:FindBodygroupByName("Hat")
			local clothesGroup = entity:FindBodygroupByName("Clothes")
			
			if hatGroup != -1 then
				entity:SetBodygroup(hatGroup, 1)
			end
			
			if clothesGroup != -1 then
				entity:SetBodygroup(clothesGroup, 1)
			end
		end
		
		-- Ogólny system bodygroups dla dużego modelu
		if selectedclass.bodygroups then
			for _, bg in pairs(selectedclass.bodygroups) do
				local groupID = bg[1]
				local value = bg[2]
				entity:SetBodygroup(groupID, value)
			end
		end
		
		-- Random bodygroups system dla dużego modelu (używa środkowych wartości)
		if selectedclass.bodygroups_random then
			for _, bg in pairs(selectedclass.bodygroups_random) do
				local groupID = bg[1]
				local range = bg[2]
				local middleValue = math.floor((range[1] + range[2]) / 2)
				entity:SetBodygroup(groupID, middleValue)
			end
		end
	end
	local ent = sclass_model:GetEntity()
	if selectedclass.pmcolor != nil then
		function ent:GetPlayerColor() return Vector ( selectedclass.pmcolor.r / 255, selectedclass.pmcolor.g / 255, selectedclass.pmcolor.b / 255 ) end
	end
	
	local sclass_name = vgui.Create( "DPanel", sclass_toppanel )
	sclass_name:Dock( TOP )
	sclass_name:SetSize(0, 50)
	sclass_name.Paint = function( self, w, h )
		draw.RoundedBox( 2, 0, 0, w, h, Color(0, 0, 0) )
		draw.RoundedBox( 2, 1, 1, w - 2, h - 2, selectedclr )
		draw.Text( {
			text = GetLangRole(selectedclass.name),
			font = "MTF_Secondary",
			xalign = TEXT_ALIGN_CENTER,
			yalign = TEXT_ALIGN_CENTER,
			pos = { w / 2, h / 2 }
		} )
	end
	
	local sclass_name = vgui.Create( "DPanel", sclass_toppanel )
	sclass_name:Dock( FILL )
	sclass_name:SetSize(0, 50)
	sclass_name.Paint = function( self, w, h )
		draw.RoundedBox( 2, 0, 0, w, h, Color(0, 0, 0) )
		draw.RoundedBox( 2, 1, 1, w - 2, h - 2, Color(86, 88, 90) )
		local atso = w / 13
		local starpos = w / 16
		draw.Text( {
			text = "Health: " .. selectedclass.health,
			font = "MTF_Third",
			xalign = TEXT_ALIGN_LEFT,
			yalign = TEXT_ALIGN_CENTER,
			pos = { 12, starpos }
		} )
		draw.Text( {
			text = "Walk speed: " .. math.Round(240 * selectedclass.walkspeed),
			font = "MTF_Third",
			xalign = TEXT_ALIGN_LEFT,
			yalign = TEXT_ALIGN_CENTER,
			pos = { 12, starpos + (atso) }
		} )
		draw.Text( {
			text = "Run speed: " .. math.Round(240 * selectedclass.runspeed),
			font = "MTF_Third",
			xalign = TEXT_ALIGN_LEFT,
			yalign = TEXT_ALIGN_CENTER,
			pos = { 12, starpos + (atso * 2) }
		} )
		draw.Text( {
			text = "Jump Power: " .. math.Round(200 * selectedclass.jumppower),
			font = "MTF_Third",
			xalign = TEXT_ALIGN_LEFT,
			yalign = TEXT_ALIGN_CENTER,
			pos = { 12, starpos + (atso * 3) }
		} )
		-- Sprawdź czy klasa jest dostępna dla wszystkich
		local isNoLevelRequired = (selectedclass.level == 0)
		
		if isNoLevelRequired then
			draw.Text( {
				text = "Available for all players",
				font = "MTF_Third",
				color = Color(0,255,0),
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				pos = { 12, h - starpos }
			} )
		else
			local lvl = selectedclass.level
			local clr = Color(255,0,0)
			if ourlevel >= lvl then clr = Color(0,255,0) end
			draw.Text( {
				text = "Clearance level: " .. lvl,
				font = "MTF_Third",
				color = clr,
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				pos = { 12, h - starpos }
			} )
		end
	end
	
	local sclass_downpanel = vgui.Create( "DPanel", panel_right )
	sclass_downpanel:Dock( FILL )
	sclass_downpanel:SetSize(0, height / 2.5)
	sclass_downpanel.Paint = function( self, w, h )
		local atso = w / 18
		local starpos = w / 12
		local numw = 0
		for k,v in pairs(selectedclass.showweapons) do
			draw.Text( {
				text = "- " .. v,
				font = "MTF_Third",
				xalign = TEXT_ALIGN_LEFT,
				yalign = TEXT_ALIGN_CENTER,
				pos = { 12, starpos + (numw * atso) }
			} )
			numw = numw + 1
		end
	end
	
	local maininfo = vgui.Create( "DLabel", sclass_downpanel )
	maininfo:SetText( "Equipment" )
	maininfo:Dock( TOP )
	maininfo:SetFont("MTF_Main")
	maininfo:SetContentAlignment( 5 )
	//maininfo:DockMargin( 245, 8, 8, 175	)
	maininfo:SetSize(0,28)
	maininfo.Paint = function( self, w, h )
		draw.RoundedBox( 2, 0, 0, w, h, Color(0, 0, 0) )
		draw.RoundedBox( 2, 1, 1, w - 2, h - 2, selectedclr	)
	end
	
	// LEFT PANELS
	
	local panel_left = vgui.Create( "DPanel", CLASSMENU )
	panel_left:Dock( FILL )
	panel_left:DockMargin( 0, 0, width / 2 - 5, 0	)
	panel_left.Paint = function( self, w, h ) end
	
	local scroller = vgui.Create( "DScrollPanel", panel_left )
	scroller:Dock( FILL )
	
	if ALLCLASSES == nil then return end
	
	-- Przygotuj kategorię SCP
	local scp_category = nil
	
	-- Dodaj zakładkę SCP
	if true then -- Zawsze pokazuj zakładkę SCP
		-- Utwórz strukturę dla SCP
		scp_category = {
			name = "SCP Entities",
			color = Color(200, 0, 0), -- Czerwony kolor
			roles = {}
		}
		
		-- Dodaj każde SCP do listy
		for _, scp_id in pairs(ALL_SCPS) do
			local mdl = SCP_MODEL_MAP[scp_id] or "models/player/breen.mdl"
			local scp_role = {
				name = scp_id,
				health = 1000, -- Domyślne wartości
				walkspeed = 1,
				runspeed = 1,
				jumppower = 1,
				level = 0,
				models = {mdl},
				showmodel = mdl,
				showweapons = {"Special SCP abilities"},
				team = TEAM_SCP
			}
			
			-- Specjalne wartości dla WSZYSTKICH SCP z sv_base_scps.lua
			if scp_id == "SCP023" then
				scp_role.health = 2000
				scp_role.walkspeed = 150/240
				scp_role.runspeed = 250/240
				scp_role.models = {"models/Novux/023/Novux_SCP-023.mdl"}
				scp_role.showmodel = "models/Novux/023/Novux_SCP-023.mdl"
				scp_role.showweapons = {"Gaze causes death in 1 minute", "Increased speed", "Damage on touch"}
			elseif scp_id == "SCP049" then
				scp_role.health = 1600
				scp_role.walkspeed = 135/240
				scp_role.runspeed = 135/240
				scp_role.models = {"models/vinrax/player/scp049_player.mdl"}
				scp_role.showmodel = "models/vinrax/player/scp049_player.mdl"
				scp_role.showweapons = {"Instant kill touch", "Creates SCP-049-2 zombies", "Slow but tanky"}
			elseif scp_id == "SCP0492" then
				scp_role.health = 750
				scp_role.walkspeed = 160/240
				scp_role.runspeed = 160/240
				scp_role.models = {"models/player/zombie_classic.mdl"}
				scp_role.showmodel = "models/player/zombie_classic.mdl"
				scp_role.showweapons = {"Zombie created by SCP-049", "Melee attack", "Medium speed"}
			elseif scp_id == "SCP066" then
				scp_role.health = 2250
				scp_role.walkspeed = 160/240
				scp_role.runspeed = 160/240
				scp_role.models = {"models/player/mrsilver/scp_066pm/scp_066_pm.mdl"}
				scp_role.showmodel = "models/player/mrsilver/scp_066pm/scp_066_pm.mdl"
				scp_role.showweapons = {"Eric's Toy", "Plays loud music", "Damage through sound"}
			elseif scp_id == "SCP076" then
				scp_role.health = 300
				scp_role.walkspeed = 220/240
				scp_role.runspeed = 220/240
				scp_role.models = {"models/abel/abel.mdl"}
				scp_role.showmodel = "models/abel/abel.mdl"
				scp_role.showweapons = {"Summons blade weapons", "Very fast", "Low health but high damage"}
			elseif scp_id == "SCP082" then
				scp_role.health = 2300
				scp_role.walkspeed = 160/240
				scp_role.runspeed = 160/240
				scp_role.models = {"models/models/konnie/savini/savini.mdl"}
				scp_role.showmodel = "models/models/konnie/savini/savini.mdl"
				scp_role.showweapons = {"Fernand the Cannibal", "High health", "Melee attacks"}
			elseif scp_id == "SCP096" then
				scp_role.health = 1750
				scp_role.walkspeed = 120/240
				scp_role.runspeed = 500/240
				scp_role.models = {"models/scp096anim/player/scp096pm_raf.mdl"}
				scp_role.showmodel = "models/scp096anim/player/scp096pm_raf.mdl"
				scp_role.showweapons = {"Shy Guy", "Rage mode when looked at", "Extreme speed when enraged"}
			elseif scp_id == "SCP106" then
				scp_role.health = 2000
				scp_role.walkspeed = 170/240
				scp_role.runspeed = 170/240
				scp_role.models = {"models/scp/106/unity/unity_scp_106_player.mdl"}
				scp_role.showmodel = "models/scp/106/unity/unity_scp_106_player.mdl"
				scp_role.showweapons = {"Old Man", "Walk through walls", "Teleport to pocket dimension"}
			elseif scp_id == "SCP173" then
				scp_role.health = 3000
				scp_role.walkspeed = 400/240
				scp_role.runspeed = 400/240
				scp_role.models = {"models/jqueary/scp/unity/scp173/scp173unity.mdl"}
				scp_role.showmodel = "models/jqueary/scp/unity/scp173/scp173unity.mdl"
				scp_role.showweapons = {"The Sculpture", "Snap necks instantly", "Can't move when watched"}
			elseif scp_id == "SCP457" then
				scp_role.health = 2300
				scp_role.walkspeed = 135/240
				scp_role.runspeed = 135/240
				scp_role.models = {"models/player/corpse1.mdl"}
				scp_role.showmodel = "models/player/corpse1.mdl"
				scp_role.showweapons = {"Burning Man", "Fire damage", "Spreads flames"}
			elseif scp_id == "SCP682" then
				scp_role.health = 2000
				scp_role.walkspeed = 120/240
				scp_role.runspeed = 275/240
				scp_role.models = {"models/danx91/scp/scp_682.mdl"}
				scp_role.showmodel = "models/danx91/scp/scp_682.mdl"
				scp_role.showweapons = {"Hard to Destroy Reptile", "High damage attacks", "Fast when chasing"}
			elseif scp_id == "SCP689" then
				scp_role.health = 1750
				scp_role.walkspeed = 100/240
				scp_role.runspeed = 100/240
				scp_role.models = {"models/dwdarksouls/models/darkwraith.mdl"}
				scp_role.showmodel = "models/dwdarksouls/models/darkwraith.mdl"
				scp_role.showweapons = {"Haunter in the Dark", "Slow movement", "Teleports when not observed"}
			elseif scp_id == "SCP8602" then
				scp_role.health = 2250
				scp_role.walkspeed = 190/240
				scp_role.runspeed = 190/240
				scp_role.models = {"models/props/forest_monster/forest_monster2.mdl"}
				scp_role.showmodel = "models/props/forest_monster/forest_monster2.mdl"
				scp_role.showweapons = {"Forest Monster", "High health", "Medium speed hunter"}
			elseif scp_id == "SCP939" then
				scp_role.health = 2000
				scp_role.walkspeed = 190/240
				scp_role.runspeed = 190/240
				scp_role.models = {"models/scp/939/unity/unity_scp_939.mdl"}
				scp_role.showmodel = "models/scp/939/unity/unity_scp_939.mdl"
				scp_role.showweapons = {"With Many Voices", "Mimics voices", "Pack hunter"}
			elseif scp_id == "SCP957" then
				scp_role.health = 1500
				scp_role.walkspeed = 175/240
				scp_role.runspeed = 175/240
				scp_role.models = {"models/immigrant/outlast/walrider_pm.mdl"}
				scp_role.showmodel = "models/immigrant/outlast/walrider_pm.mdl"
				scp_role.showweapons = {"The Baiting", "Lures victims", "Moderate speed"}
			elseif scp_id == "SCP966" then
				scp_role.health = 800
				scp_role.walkspeed = 140/240
				scp_role.runspeed = 140/240
				scp_role.models = {"models/player/mishka/966_new.mdl"}
				scp_role.showmodel = "models/player/mishka/966_new.mdl"
				scp_role.showweapons = {"Sleep Killers", "Invisible to humans", "Causes exhaustion"}
			elseif scp_id == "SCP999" then
				scp_role.health = 1000
				scp_role.walkspeed = 150/240
				scp_role.runspeed = 150/240
				scp_role.models = {"models/scp/999/jq/scp_999_pmjq.mdl"}
				scp_role.showmodel = "models/scp/999/jq/scp_999_pmjq.mdl"
				scp_role.showweapons = {"The Tickle Monster", "Friendly SCP", "Heals and calms others"}
			elseif scp_id == "SCP1048A" then
				scp_role.health = 1500
				scp_role.walkspeed = 135/240
				scp_role.runspeed = 135/240
				scp_role.models = {"models/1048/tdyear/tdybrownearpm.mdl"}
				scp_role.showmodel = "models/1048/tdyear/tdybrownearpm.mdl"
				scp_role.showweapons = {"Ear Bear", "Screams cause damage", "Small and agile"}
			elseif scp_id == "SCP1048B" then
				scp_role.health = 2000
				scp_role.walkspeed = 165/240
				scp_role.runspeed = 165/240
				scp_role.models = {"models/player/teddy_bear/teddy_bear.mdl"}
				scp_role.showmodel = "models/player/teddy_bear/teddy_bear.mdl"
				scp_role.showweapons = {"Metal Bear", "High durability", "Strong melee attacks"}
			elseif scp_id == "SCP1471" then
				scp_role.health = 3000
				scp_role.walkspeed = 160/240
				scp_role.runspeed = 325/240
				scp_role.models = {"models/burd/scp1471/scp1471.mdl"}
				scp_role.showmodel = "models/burd/scp1471/scp1471.mdl"
				scp_role.showweapons = {"MalO", "Stalks victims", "Very fast when hunting"}
			elseif scp_id == "SCP069" then
				scp_role.health = 1800
				scp_role.walkspeed = 160/240
				scp_role.runspeed = 200/240
				scp_role.models = {"models/player/alski/re2remake/mr_x.mdl"}
				scp_role.showmodel = "models/player/alski/re2remake/mr_x.mdl"
				scp_role.showweapons = {"Second Chance", "Instant kill touch", "Can disguise as victims"}
					elseif scp_id == "SCP1678" then
			scp_role.health = 2000
			scp_role.walkspeed = 160/240
			scp_role.runspeed = 160/240
			scp_role.models = {"models/scp-1678/scp-1678.mdl"}
			scp_role.showmodel = "models/scp-1678/scp-1678.mdl"
			scp_role.showweapons = {"UnLondon Entity", "Police baton attack", "Stuns enemies"}
		elseif scp_id == "SCP3166" then
			scp_role.health = 1800
			scp_role.walkspeed = 140/240
			scp_role.runspeed = 140/240
			scp_role.models = {"models/nickelodeon_all_stars/garfield/garfield.mdl"}
			scp_role.showmodel = "models/nickelodeon_all_stars/garfield/garfield.mdl"
			scp_role.showweapons = {"Claw Attack", "Lasagna Target Selection", "Speed & HP boost on kill"}
		elseif scp_id == "SCPIMPOSTORJ" then
			scp_role.health = 1000
			scp_role.walkspeed = 150/240
			scp_role.runspeed = 150/240
			scp_role.models = {"models/lenoax/amongus/suit_pm.mdl"}
			scp_role.showmodel = "models/lenoax/amongus/suit_pm.mdl"
			scp_role.showweapons = {"Knife Attack (38 damage)", "Among Us crewmate", "Bowie knife weapon"}
		elseif scp_id == "SCP9571" then
				-- SCP-957-1 nie ma własnego modelu, używa domyślnego
				scp_role.health = 500
				scp_role.walkspeed = 165/240
				scp_role.runspeed = 165/240
				scp_role.showweapons = {"SCP-957 offspring", "Fast attacker", "Low health"}
			elseif scp_id == "SCPDOOMGUYJ" then
				scp_role.health = 2500
				scp_role.walkspeed = 180/240
				scp_role.runspeed = 280/240
				scp_role.models = {"models/player/doom_fn_pm.mdl"}
				scp_role.showmodel = "models/player/doom_fn_pm.mdl"
				scp_role.showweapons = {"Crucible Energy Sword", "High speed and damage", "Doom Slayer incarnate"}
			end
			
			table.insert(scp_category.roles, scp_role)
		end
	end
	
	-- Zdefiniuj stałą kolejność zakładek
	local category_order = {}
	
	-- Dodaj SCP na początku
	if scp_category then
		table.insert(category_order, {key = "scp", data = scp_category})
	end
	
	-- Dodaj resztę kategorii w stałej kolejności
	table.insert(category_order, {key = "classds", data = ALLCLASSES.classds})
	table.insert(category_order, {key = "researchers", data = ALLCLASSES.researchers})
	table.insert(category_order, {key = "security", data = ALLCLASSES.security})
	table.insert(category_order, {key = "support", data = ALLCLASSES.support})
	table.insert(category_order, {key = "goc", data = ALLCLASSES.goc})
	
	-- Iteruj w ustalonej kolejności
	for _, category in ipairs(category_order) do
		local key = category.key
		local v = category.data
		
		if not v then continue end -- Pomiń jeśli kategoria nie istnieje
		local name_security = vgui.Create( "DLabel", scroller )
		name_security:SetText( v.name )
		name_security:SetFont("MTF_Main")
		name_security:SetContentAlignment( 5 )
		name_security:Dock( TOP )
		name_security:SetSize(0,45)
		name_security:DockMargin( 0, 0, 0, 0 )
		name_security.Paint = function( self, w, h )
			draw.RoundedBox( 2, 0, 0, w, h, Color(0, 0, 0) )
			draw.RoundedBox( 2, 1, 1, w - 2, h - 2, v.color )
		end
		for i,cls in ipairs(v.roles) do
			if GetConVar( "br_dclass_keycards" ):GetInt() == 0 and i != 2 or GetConVar( "br_dclass_keycards" ):GetInt() != 0 and i != 1 or v.name != "Class D Personell" then
				local model
				if cls.showmodel == nil then
					model = table.Random(cls.models)
				else
					model = cls.showmodel
				end
			
				local class_panel = vgui.Create( "DButton", scroller )
				class_panel:SetText("")
				class_panel:SetMouseInputEnabled( true )
				class_panel.DoClick = function()
					selectedclass = cls
					selectedclr = v.color
					sclass_model:SetModel( model )
					
					-- Ustaw bodygroups dla głównego modelu SCP-527
					if cls.name == ROLES.ROLE_SCP527 then
						timer.Simple(0.1, function()
							if IsValid(sclass_model) then
								local entity = sclass_model:GetEntity()
								if IsValid(entity) then
									local hatGroup = entity:FindBodygroupByName("Hat")
									local clothesGroup = entity:FindBodygroupByName("Clothes")
									
									if hatGroup != -1 then
										entity:SetBodygroup(hatGroup, 1)
									end
									
									if clothesGroup != -1 then
										entity:SetBodygroup(clothesGroup, 1)
									end
								end
							end
						end)
					end
					
					-- Ogólny system bodygroups dla głównego modelu
					if cls.bodygroups then
						timer.Simple(0.1, function()
							if IsValid(sclass_model) then
								local entity = sclass_model:GetEntity()
								if IsValid(entity) then
									for _, bg in pairs(cls.bodygroups) do
										local groupID = bg[1]
										local value = bg[2]
										entity:SetBodygroup(groupID, value)
									end
								end
							end
						end)
					end
					
					-- Random bodygroups system dla głównego modelu
					if cls.bodygroups_random then
						timer.Simple(0.1, function()
							if IsValid(sclass_model) then
								local entity = sclass_model:GetEntity()
								if IsValid(entity) then
									for _, bg in pairs(cls.bodygroups_random) do
										local groupID = bg[1]
										local range = bg[2]
										local middleValue = math.floor((range[1] + range[2]) / 2)
										entity:SetBodygroup(groupID, middleValue)
									end
								end
							end
						end)
					end
				end
				//class_panel:SetText( cls.name )
				//class_panel:SetFont("MTF_Main")
				class_panel:Dock( TOP )
				class_panel:SetSize(0,60)
				if i != 1 then
					class_panel:DockMargin( 0, 4, 0, 0 )
				end
				
				local level = ""
				-- Sprawdź czy klasa jest dostępna dla wszystkich
				if cls.level == 0 then
					level = "Available for all players"
				else
					level = "Clearance Level: " .. cls.level
				end
				
				//local enabled = true
				//if enabled == true then enabled = "Yes" else enabled = "No" end
				
				class_panel.Paint = function( self, w, h )
					if selectedclass == cls then
						draw.RoundedBox( 0, 0, 0, w, h, Color(v.color.r - 20, v.color.g - 20, v.color.b - 20) )
					else
						draw.RoundedBox( 0, 0, 0, w, h, Color(v.color.r - 50, v.color.g - 50, v.color.b - 50) )
					end
					draw.Text( {
						text = GetLangRole(cls.name),
						font = "MTF_Main",
						xalign = TEXT_ALIGN_LEFT,
						yalign = TEXT_ALIGN_CENTER,
						pos = { 70, h / 3.5 }
					} )
					draw.Text( {
						text = level,
						font = "MTF_Main",
						xalign = TEXT_ALIGN_LEFT,
						yalign = TEXT_ALIGN_CENTER,
						pos = { 70, h / 1.4 }
					} )
					/*
					draw.Text( {
						text = "Enabled: " .. enabled,
						font = "MTF_Main",
						xalign = TEXT_ALIGN_RIGHT,
						yalign = TEXT_ALIGN_CENTER,
						pos = { w - 15, h / 2 }
					} )
					*/
				end
				
				local class_modelpanel = vgui.Create( "DPanel", class_panel )
				class_modelpanel:Dock( LEFT )
				class_modelpanel.Paint = function( self, w, h )
					draw.RoundedBox( 0, 0, 0, w, h, Color(v.color.r - 25, v.color.g - 25, v.color.b - 25) )
				end
				

				local class_model = vgui.Create( "DModelPanel", class_modelpanel )
				class_model:Dock( FILL )
				class_model:SetFOV(35)
				class_model:SetModel( model )
				function class_model:LayoutEntity( entity )
					entity:SetAngles(Angle(0,18,0))
					
					-- Ustaw bodygroups dla SCP-527
					if cls.name == ROLES.ROLE_SCP527 then
						local hatGroup = entity:FindBodygroupByName("Hat")
						local clothesGroup = entity:FindBodygroupByName("Clothes")
						
						if hatGroup != -1 then
							entity:SetBodygroup(hatGroup, 1)
						end
						
						if clothesGroup != -1 then
							entity:SetBodygroup(clothesGroup, 1)
						end
					end
					
					-- Ogólny system bodygroups dla małych modeli w liście
					if cls.bodygroups then
						for _, bg in pairs(cls.bodygroups) do
							local groupID = bg[1]
							local value = bg[2]
							entity:SetBodygroup(groupID, value)
						end
					end
					
					-- Random bodygroups system dla małych modeli w liście
					if cls.bodygroups_random then
						for _, bg in pairs(cls.bodygroups_random) do
							local groupID = bg[1]
							local range = bg[2]
							local middleValue = math.floor((range[1] + range[2]) / 2)
							entity:SetBodygroup(groupID, middleValue)
						end
					end
				end
				local ent = class_model:GetEntity()
				if cls.pmcolor != nil then
					function ent:GetPlayerColor() return Vector ( cls.pmcolor.r / 255, cls.pmcolor.g / 255, cls.pmcolor.b / 255 ) end
				end
				if ent:LookupBone( "ValveBiped.Bip01_Head1" ) != nil then
					local eyepos = ent:GetBonePosition( ent:LookupBone( "ValveBiped.Bip01_Head1" ) )
					eyepos:Add( Vector( 0, 0, 2 ) )
					class_model:SetLookAt( eyepos )
					class_model:SetCamPos( eyepos-Vector( -24, 0, 0 ) )
					ent:SetEyeTarget( eyepos-Vector( -24, 0, 0 ) )
				end
			end
		end -- koniec pętli for
	end
	
	//button_escort:SetFont("MTF_Main")
	//button_escort:SetContentAlignment( 5 )
	//button_escort:DockMargin( 0, 5, 0, 0	)
	//button_escort:SetSize(0,32)
	//button_escort.DoClick = function()
	//	RunConsoleCommand("br_requestescort")
	//	CLASSMENU:Close()
	//end
	/*
	local button_escort = vgui.Create( "DButton", CLASSMENU )
	button_escort:SetText( "Sound: Random" )
	button_escort:Dock( TOP )
	button_escort:SetFont("MTF_Main")
	button_escort:SetContentAlignment( 5 )
	button_escort:DockMargin( 0, 5, 0, 0	)
	button_escort:SetSize(0,32)
	button_escort.DoClick = function()
		RunConsoleCommand("br_sound_random")
		CLASSMENU:Close()
	end
	*/
end
