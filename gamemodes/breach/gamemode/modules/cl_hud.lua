local hide = {
	CHudHealth = true,
	CHudBattery = true,
	CHudAmmo = true,
	CHudSecondaryAmmo = true,
	//CHudWeaponSelection = true,
	CHudDeathNotice = true
	//CHudWeapon = true
}

surface.CreateFont("ImpactBig", {font = "Impact",
                                  size = 45,
                                  weight = 700})
surface.CreateFont("ImpactSmall", {font = "Impact",
                                  size = 30,
                                  weight = 700})

surface.CreateFont( "RadioFont", {
	font = "Impact",
	extended = false,
	size = 26,
	weight = 700,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

-- Additional fonts for classic HUD
surface.CreateFont( "ClassName", {
	font = "Impact",
	extended = false,
	size = 20,
	weight = 700,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

surface.CreateFont( "TimeLeft", {
	font = "Impact",
	extended = false,
	size = 18,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

surface.CreateFont( "HealthAmmo", {
	font = "Impact",
	extended = false,
	size = 16,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

-- Font for tips
surface.CreateFont( "TipFont", {
	font = "Impact",
	extended = false,
	size = 20,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

-- Tips system
local tips = {
	"TIP: Remember to blink regularly when playing as human classes to avoid SCP-173!",
	-- Add more tips here later
}

local currentTip = 1
local tipX = ScrW()
local tipSpeed = 80 -- pixels per second (will be recalculated dynamically)
local tipShowTime = 0
local tipInterval = 120 -- 2 minutes between tips
local tipDuration = 10 -- Show tip for 10 seconds
local tipFadeStart = 0 -- When fade animation starts
local tipFading = false -- Whether tip is fading
local tipsEnabled = CreateClientConVar("breach_tips_enabled", "1", true, false, "Enable/disable tips display")

-- Initialize tip timer
timer.Create("ShowTips", tipInterval, 0, function()
	if !tipsEnabled:GetBool() then return end
	tipShowTime = CurTime() + tipDuration
	tipFadeStart = CurTime() + (tipDuration - 2) -- Start fade 2 seconds before end
	tipX = ScrW() -- Reset position to right side
	tipFading = false
	currentTip = math.random(1, #tips)
end)

-- Show first tip after 30 seconds
timer.Simple(30, function()
	if !tipsEnabled:GetBool() then return end
	tipShowTime = CurTime() + tipDuration
	tipFadeStart = CurTime() + (tipDuration - 2) -- Start fade 2 seconds before end
	tipX = ScrW()
	tipFading = false
	currentTip = 1
end)

function GM:DrawDeathNotice( x,  y )
end

hook.Add( "HUDShouldDraw", "HideHUD", function( name )
	if ( hide[ name ] ) then return false end
end )
timer.Simple( 0, function()
	endmessages = {
		{
			main = clang.lang_end1,
			txt = clang.lang_end2,
			clr = gteams.GetColor(TEAM_SCP)
		},
		{
			main = clang.lang_end1,
			txt = clang.lang_end3,
			clr = gteams.GetColor(TEAM_SCP)
		}
	}
end )

function DrawInfo(pos, txt, clr)
	pos = pos:ToScreen()
	draw.TextShadow( {
		text = txt,
		pos = { pos.x, pos.y },
		font = "DermaDefaultBold",
		color = clr,
		xalign = TEXT_ALIGN_CENTER,
		yalign = TEXT_ALIGN_CENTER,
	}, 2, 255 )
end

hook.Add( "Tick", "966check", function()
	local hide = true
	if LocalPlayer().GTeam == nil then return end
	if LocalPlayer():GTeam() == TEAM_SCP then
		hide = false
	end
	-- Use new NVG toggle system
	if LocalPlayer().NVGActive then
			hide = false
	end
	if LocalPlayer().n420endtime and LocalPlayer().n420endtime > CurTime() then
		hide = false
	end
	for k,v in pairs(player.GetAll()) do
		if not v.GetNClass then
			player_manager.RunClass( v, "SetupDataTables" )
		end
		if v.GetNClass == nil then return end
		if v:GetNClass() == ROLES.ROLE_SCP966 then
			v:SetNoDraw(hide)
		end
	end
end )

SCPMarkers = {}

local info1 = Material( "breach/info_mtf.png")
hook.Add( "HUDPaint", "Breach_DrawHUD", function()
	-- Check if classic HUD is enabled
	local hudVar = GetConVar("br_hud")
	if !hudVar or hudVar:GetInt() != 2 then return end
	
	for i, v in ipairs( SCPMarkers ) do
		local scr = v.data.pos:ToScreen()

		if scr.visible then
			surface.SetDrawColor( Color( 255, 100, 100, 200 ) )
			//surface.DrawRect( scr.x - 5, scr.y - 5, 10, 10 )
			surface.DrawPoly( {
				{ x = scr.x, y = scr.y - 10 },
				{ x = scr.x + 5, y = scr.y },
				{ x = scr.x, y = scr.y + 10 },
				{ x = scr.x - 5, y = scr.y },
			} )

			draw.Text( {
				text = v.data.name,
				font = "HUDFont",
				color = Color( 255, 100, 100, 200 ),
				pos = { scr.x, scr.y + 10 },
				xalign = TEXT_ALIGN_CENTER,
				yalign = TEXT_ALIGN_TOP,
			} )

			draw.Text( {
				text = math.Round( v.data.pos:Distance( LocalPlayer():GetPos() ) * 0.019 ) .. "m",
				font = "HUDFont",
				color = Color( 255, 100, 100, 200 ),
				pos = { scr.x, scr.y + 25 },
				xalign = TEXT_ALIGN_CENTER,
				yalign = TEXT_ALIGN_TOP,
			} )
		end

		if v.time < CurTime() then
			table.remove( SCPMarkers, i )
		end
	end

	if disablehud then return end
	//cam.Start3D()
	//	for id, ply in pairs( player.GetAll() ) do
	//		if ply:GetNClass() == ROLES.ROLE_SCP966 then
	//			ply:DrawModel()
	//		end
	//	end
	//cam.End3D()
	/*if disablehud == true then return end
	if POS_914B_BUTTON != nil and isstring(buttonstatus) then
		if LocalPlayer():GetPos():Distance(POS_914B_BUTTON) < 200 then
			DrawInfo(POS_914B_BUTTON, buttonstatus, Color(255,255,255))
		end
	end*/
	
	/*
	for k,v in pairs(SPAWN_ARMORS) do
		DrawInfo(v, "Armor", Color(255,255,255))
	end
	
	for k,v in pairs(SPAWN_FIREPROOFARMOR) do
		DrawInfo(v, "FArmor", Color(255,255,255))
	end
	
	
	if BUTTONS != nil then
		for k,v in pairs(BUTTONS) do
			DrawInfo(v.pos, v.name, Color(0,255,50))
		end
		
		
		for k,v in pairs(SPAWN_KEYCARD2) do
			for _,v2 in pairs(v) do
				DrawInfo(v2, "Keycard2", Color(255,255,0))
			end
		end
		for k,v in pairs(SPAWN_KEYCARD3) do
			for _,v2 in pairs(v) do
				DrawInfo(v2, "Keycard3", Color(255,120,0))
			end
		end
		for k,v in pairs(SPAWN_KEYCARD4) do
			for _,v2 in pairs(v) do
				DrawInfo(v2, "Keycard4", Color(255,0,0))
			end
		end
		
		
		for k,v in pairs(SPAWN_SMGS) do
			DrawInfo(v, "SMG", Color(255,255,255))
		end
		for k,v in pairs(SPAWN_RIFLES) do
			DrawInfo(v, "RIFLE", Color(0,255,255))
		end
		
	end
	*/
	/*
	if #player.GetAll() < MINPLAYERS then
		draw.TextShadow( {
			text = "Not enough players to start the round",
			pos = { ScrW() / 2, ScrH() / 15 },
			font = "ImpactBig",
			color = Color(255,255,255),
			xalign = TEXT_ALIGN_CENTER,
			yalign = TEXT_ALIGN_CENTER,
		}, 2, 255 )
		draw.TextShadow( {
			text = "Waiting for more players to join the server",
			pos = { ScrW() / 2, ScrH() / 15 + 45 },
			font = "ImpactSmall",
			color = Color(255,255,255),
			xalign = TEXT_ALIGN_CENTER,
			yalign = TEXT_ALIGN_CENTER,
		}, 2, 255 )
		return
	
	elseif gamestarted == false then
		draw.TextShadow( {
			text = "Game is starting",
			pos = { ScrW() / 2, ScrH() / 15 },
			font = "ImpactBig",
			color = Color(255,128,70),
			xalign = TEXT_ALIGN_CENTER,
			yalign = TEXT_ALIGN_CENTER,
		}, 2, 255 )
		draw.TextShadow( {
			text = "Wait for the round to start",
			pos = { ScrW() / 2, ScrH() / 15 + 45 },
			font = "ImpactSmall",
			color = Color(255,255,255),
			xalign = TEXT_ALIGN_CENTER,
			yalign = TEXT_ALIGN_CENTER,
		}, 2, 255 )
		return
	end
	*/
	/*if OMEGA_DETONATION then
		local dist = LocalPlayer():GetPos():DistToSqr( OMEGA_DETONATION )
		if dist < 90000 and dist > 5625 then
			DrawInfo( OMEGA_DETONATION + Vector( 0, 0, -5 ), "Remote OMEGA Warhead detonation", Color( 255, 255, 255 ) )
		end
	end*/

	-- New HUD 2 implementation based on provided design
	local ply = LocalPlayer()
	
	-- Show time even when dead or spectating
	if ply:Alive() == false or ply:GTeam() == TEAM_SPEC then
		-- Display time for dead/spectating players
		local margin = 20
		local barWidth = 250
		local barHeight = 35
		
		local x = margin
		local y = ScrH() - margin - (barHeight * 3) -- Same position as when alive
		
		-- Time display bar with dark background
		draw.RoundedBox(0, x, y, barWidth, barHeight, Color(50, 50, 50, 255))
		draw.TextShadow( {
			text = "SPECTATING",
			pos = { x + 10, y + barHeight / 2 },
			font = "ImpactSmall",
			color = Color(200, 200, 200),
			xalign = TEXT_ALIGN_LEFT,
			yalign = TEXT_ALIGN_CENTER,
		}, 2, 255 )
		
		-- Time display outside the bar
		draw.TextShadow( {
			text = tostring(string.ToMinutesSeconds( cltime )),
			pos = { x + barWidth + 15, y + barHeight / 2 },
			font = "ImpactSmall",
			color = Color(255,255,255),
			xalign = TEXT_ALIGN_LEFT,
			yalign = TEXT_ALIGN_CENTER,
		}, 2, 255 )
		
		-- Show observed player info if spectating someone
		local ent = ply:GetObserverTarget()
		if IsValid(ent) and ent:IsPlayer() and ply:GTeam() == TEAM_SPEC then
			local sw = 300
			local sh = 50
			local sx = ScrW() / 2 - (sw / 2)
			local sy = 20
			
			-- Dark background bar
			draw.RoundedBox(0, sx, sy, sw, sh, Color(60, 60, 60, 255))
			
			-- Player name
			draw.TextShadow( {
				text = string.upper(string.sub(ent:Nick(), 1, 15)),
				pos = { sx + sw / 2, sy + 15 },
				font = "ImpactSmall",
				color = Color(255,255,255),
				xalign = TEXT_ALIGN_CENTER,
				yalign = TEXT_ALIGN_CENTER,
			}, 2, 255 )
			
			-- Health info
			local hp = ent:Health()
			local maxhp = ent:GetMaxHealth()
			draw.TextShadow( {
				text = "HP: " .. hp .. "/" .. maxhp,
				pos = { sx + sw / 2, sy + 35 },
				font = "ImpactSmall",
				color = Color(255, 100, 100),
				xalign = TEXT_ALIGN_CENTER,
				yalign = TEXT_ALIGN_CENTER,
			}, 2, 255 )
		end
		
		return
	end
	
	
	-- Get player info
	local name = "None"
	if not ply.GetNClass then
		player_manager.RunClass( ply, "SetupDataTables" )
	elseif LocalPlayer():GTeam() != TEAM_SPEC then
		name = GetLangRole(ply:GetNClass())
		if ply:GTeam() == TEAM_CHAOS and ply:GetNClass() != ROLES.ROLE_CHAOSSPY and ply:GetNClass() != ROLES.ROLE_CIC then
			name = GetLangRole(ROLES.ROLE_CHAOS)
		end
	end
	
	-- Get team color
	local color = gteams.GetColor( ply:GTeam() )
	if ply:GTeam() == TEAM_CHAOS then
		color = Color(29, 81, 56)
	end
	
	-- HUD positioning - bottom left corner
	local margin = 20
	local barWidth = 250
	local barHeight = 35
	local spacing = 5
	
	local x = margin
	local y = ScrH() - margin - (barHeight * 3) - (spacing * 2) -- Calculate from bottom, accounting for 3 bars
	
	-- Class/Role bar
	draw.RoundedBox(0, x, y, barWidth, barHeight, color)
	draw.TextShadow( {
		text = string.upper(name or "Unknown"),
		pos = { x + 10, y + barHeight / 2 },
		font = "ImpactSmall",
		color = Color(255,255,255),
		xalign = TEXT_ALIGN_LEFT,
		yalign = TEXT_ALIGN_CENTER,
	}, 2, 255 )
	
	-- Time display outside the bar, to the right
	draw.TextShadow( {
		text = tostring(string.ToMinutesSeconds( cltime )),
		pos = { x + barWidth + 15, y + barHeight / 2 },
		font = "ImpactSmall",
		color = Color(255,255,255),
		xalign = TEXT_ALIGN_LEFT,
		yalign = TEXT_ALIGN_CENTER,
	}, 2, 255 )
	
	-- Health bar
	y = y + barHeight + spacing
	local health = ply:Health()
	local maxHealth = ply:GetMaxHealth()
	local healthPercent = math.Clamp(health / maxHealth, 0, 1)
	
	-- Background (dark red)
	draw.RoundedBox(0, x, y, barWidth, barHeight, Color(100, 25, 25, 255))
	-- Health fill (bright red, width based on health percentage)
	draw.RoundedBox(0, x, y, barWidth * healthPercent, barHeight, Color(200, 50, 50, 255))
	
	draw.TextShadow( {
		text = tostring(health),
		pos = { x + 10, y + barHeight / 2 },
		font = "ImpactSmall",
		color = Color(255,255,255),
		xalign = TEXT_ALIGN_LEFT,
		yalign = TEXT_ALIGN_CENTER,
	}, 2, 255 )
	
	-- Ammo bar (only if player has weapon)
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep.Clip1 and wep:Clip1() > -1 then
		y = y + barHeight + spacing
		local ammo1 = wep:Clip1()
		local ammo2 = ply:GetAmmoCount( wep:GetPrimaryAmmoType() )
		local ammotext = ammo1 .. " + " .. ammo2
		
		-- Calculate ammo percentage based on current clip vs max clip
		local ammoPercent = 1
		if wep:GetMaxClip1() > 0 then
			ammoPercent = math.Clamp(ammo1 / wep:GetMaxClip1(), 0, 1)
		end
		
		-- Background (dark orange/yellow)
		draw.RoundedBox(0, x, y, barWidth, barHeight, Color(100, 75, 25, 255))
		-- Ammo fill (bright orange/yellow, width based on ammo percentage)
		draw.RoundedBox(0, x, y, barWidth * ammoPercent, barHeight, Color(200, 150, 50, 255))
		
		draw.TextShadow( {
			text = ammotext,
			pos = { x + 10, y + barHeight / 2 },
			font = "ImpactSmall",
			color = Color(255,255,255),
			xalign = TEXT_ALIGN_LEFT,
			yalign = TEXT_ALIGN_CENTER,
		}, 2, 255 )
	end
end )

-- Start info messages - displayed regardless of HUD type
hook.Add( "HUDPaint", "Breach_StartMessages", function()
	if shoulddrawinfo == true then
		local getrl = LocalPlayer():GetNClass()
		for k,v in pairs(ROLES) do
			if v == getrl then
				getrl = k
				break
			end
		end
		for k,v in pairs(clang.starttexts) do
			if k == getrl then
				getrl = v
				break
			end
		end
		local align = 32
		local tcolor = gteams.GetColor(LocalPlayer():GTeam())
		if LocalPlayer():GTeam() == TEAM_CHAOS then
			tcolor = Color(29, 81, 56)
		end
		
		if getrl[1] then
			draw.TextShadow( {
				text = getrl[1],
				pos = { ScrW() / 2, ScrH() / 15 },
				font = "ImpactBig",
				color = tcolor,
				xalign = TEXT_ALIGN_CENTER,
				yalign = TEXT_ALIGN_CENTER,
			}, 2, 255 )
		end
		if type( getrl[2] ) == "table" then
			for i,txt in ipairs(getrl[2]) do
				draw.TextShadow( {
					text = txt,
					pos = { ScrW() / 2, ScrH() / 15 + 10 + (align * i) },
					font = "ImpactSmall",
					color = Color(255,255,255),
					xalign = TEXT_ALIGN_CENTER,
					yalign = TEXT_ALIGN_CENTER,
				}, 2, 255 )
			end
		end
		-- Moved round type display to top right corner - only show during preparing phase
		if roundtype != nil and preparing == true then
			draw.TextShadow( {
				text = string.Replace( clang.roundtype,  "{type}", roundtype ),
				pos = { ScrW() - 20, 20 },
				font = "ImpactSmall",
				color = Color(255, 130, 0),
				xalign = TEXT_ALIGN_RIGHT,
				yalign = TEXT_ALIGN_TOP,
			}, 2, 255 )
			if roundtype != "Containment Breach" then
				draw.TextShadow( {
					text = clang.specialround,
					pos = { ScrW() - 20, 50 },
					font = "ImpactSmall",
					color = Color(255, 255, 255),
					xalign = TEXT_ALIGN_RIGHT,
					yalign = TEXT_ALIGN_TOP,
				}, 2, 255 )
			end
		end
	end
end )

-- SCP-239 Global Health Bar - displayed for all players when SCP-239 is alive
hook.Add( "HUDPaint", "Breach_SCP239_HealthBar", function()
	if disablehud then return end
	
	-- Find SCP-239 player
	local scp239 = nil
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and ply:Alive() and ply.GetNClass and ply:GetNClass() == ROLES.ROLE_SCP239 then
			scp239 = ply
			break
		end
	end
	
	if not scp239 then return end
	
	-- Get SCP-239's vulnerability status
	local wep = scp239:GetActiveWeapon()
	local isVulnerable = scp239:GetNWBool("SCP239_Vulnerable", false)
	local vulnerabilityTime = 0
	
	if IsValid(wep) and wep:GetClass() == "weapon_scp_239" then
		vulnerabilityTime = wep:GetNWFloat("SCP239_VulnerabilityTime", 0)
	end
	
	-- Health bar dimensions and position (top center of screen)
	local barWidth = 400
	local barHeight = 30
	local x = ScrW() / 2 - barWidth / 2
	local y = 10
	
	-- Background
	draw.RoundedBox(8, x - 5, y - 5, barWidth + 10, barHeight + 50, Color(0, 0, 0, 200))
	
	-- Title
	local titleColor = isVulnerable and Color(255, 100, 100) or Color(255, 150, 255)
	draw.TextShadow( {
		text = "SCP-239",
		pos = { ScrW() / 2, y + 8 },
		font = "ImpactSmall",
		color = titleColor,
		xalign = TEXT_ALIGN_CENTER,
		yalign = TEXT_ALIGN_CENTER,
	}, 2, 255 )
	
	-- Health bar
	local hp = scp239:Health()
	local maxhp = scp239:GetMaxHealth()
	local healthPercent = math.Clamp(hp / maxhp, 0, 1)
	
	local healthBarY = y + 18
	
	-- Health bar background
	draw.RoundedBox(4, x, healthBarY, barWidth, 12, Color(60, 60, 60, 255))
	
	-- Health bar fill
	local healthColor = isVulnerable and Color(255, 100, 100) or Color(255, 150, 255)
	draw.RoundedBox(4, x + 1, healthBarY + 1, (barWidth - 2) * healthPercent, 10, healthColor)
	
	-- Health text
	draw.TextShadow( {
		text = hp .. "/" .. maxhp .. " HP",
		pos = { x + barWidth / 2, healthBarY + 6 },
		font = "HealthAmmo",
		color = Color(255, 255, 255),
		xalign = TEXT_ALIGN_CENTER,
		yalign = TEXT_ALIGN_CENTER,
	}, 1, 200 )
	
	-- Vulnerability status
	local statusText = ""
	local statusColor = Color(255, 255, 255)
	
	if isVulnerable then
		local timeLeft = math.max(0, vulnerabilityTime - CurTime())
		statusText = string.format("VULNERABLE - %.1fs", timeLeft)
		statusColor = Color(255, 100, 100)
	else
		statusText = "IMMORTAL"
		statusColor = Color(100, 255, 100)
	end
	
	draw.TextShadow( {
		text = statusText,
		pos = { ScrW() / 2, y + 40 },
		font = "HealthAmmo",
		color = statusColor,
		xalign = TEXT_ALIGN_CENTER,
		yalign = TEXT_ALIGN_CENTER,
	}, 1, 200 )
end )

-- End messages and escape messages - displayed regardless of HUD type
hook.Add( "HUDPaint", "Breach_EndMessages", function()
	if isnumber(drawendmsg) then
		local ndtext = clang.lang_end2
		if drawendmsg == 2 then
			ndtext = clang.lang_end3
		end
		shoulddrawinfo = false
		draw.TextShadow( {
			text = clang.lang_end1,
			pos = { ScrW() / 2, ScrH() / 15 },
			font = "ImpactBig",
			color = Color(0,255,0),
			xalign = TEXT_ALIGN_CENTER,
			yalign = TEXT_ALIGN_CENTER,
		}, 2, 255 )
		draw.TextShadow( {
			text = ndtext,
			pos = { ScrW() / 2, ScrH() / 15 + 45 },
			font = "ImpactSmall",
			color = Color(255,255,255),
			xalign = TEXT_ALIGN_CENTER,
			yalign = TEXT_ALIGN_CENTER,
		}, 2, 255 )
		for i,txt in ipairs(endinformation) do
			draw.TextShadow( {
				text = txt,
				pos = { ScrW() / 2, ScrH() / 8 + (35 * i)},
				font = "ImpactSmall",
				color = color_white,
				xalign = TEXT_ALIGN_CENTER,
				yalign = TEXT_ALIGN_CENTER,
			}, 2, 255 )
		end
	else
		if isnumber(shoulddrawescape) then
			if CurTime() > lastescapegot then
				shoulddrawescape = nil
			end
			if clang.escapemessages[shoulddrawescape] then
				local tab = clang.escapemessages[shoulddrawescape]
				draw.TextShadow( {
					text = tab.main,
					pos = { ScrW() / 2, ScrH() / 15 },
					font = "ImpactBig",
					color = tab.clr,
					xalign = TEXT_ALIGN_CENTER,
					yalign = TEXT_ALIGN_CENTER,
				}, 2, 255 )
				draw.TextShadow( {
					text = string.Replace( tab.txt, "{t}", string.ToMinutesSecondsMilliseconds(esctime) ),
					pos = { ScrW() / 2, ScrH() / 15 + 45 },
					font = "ImpactSmall",
					color = Color(255,255,255),
					xalign = TEXT_ALIGN_CENTER,
					yalign = TEXT_ALIGN_CENTER,
				}, 2, 255 )
				draw.TextShadow( {
					text = tab.txt2,
					pos = { ScrW() / 2, ScrH() / 15 + 75 },
					font = "ImpactSmall",
					color = Color(255,255,255),
					xalign = TEXT_ALIGN_CENTER,
					yalign = TEXT_ALIGN_CENTER,
				}, 2, 255 )
			end
		end
	end
end )

net.Receive( "ShowText", function( len )
	local com = net.ReadString()
	if com == "vote_fail" then
		LocalPlayer():PrintMessage( HUD_PRINTTALK, clang.votefail )
	elseif	com == "text_punish" then
		local name = net.ReadString()
		LocalPlayer():PrintMessage( HUD_PRINTTALK, string.format( clang.votepunish, name ) )
		LocalPlayer():PrintMessage( HUD_PRINTTALK, clang.voterules )
	elseif	com == "text_punish_end" then
		local data = net.ReadTable()
		local result
		if data.punish then 
			result = clang.punish
		else 
			result = clang.forgive
		end
		local vp, vf = data.punishvotes, data.forgivevotes
		//print( vp, vf )
		LocalPlayer():PrintMessage( HUD_PRINTTALK, string.format( clang.voteresult, data.punished, result ) )
		LocalPlayer():PrintMessage( HUD_PRINTTALK, string.format( clang.votes, vp + vf, vp, vf ) )
	elseif com == "text_punish_cancel" then
		LocalPlayer():PrintMessage( HUD_PRINTTALK, clang.votecancel )
	end
end)

-- Tips display system
hook.Add( "HUDPaint", "Breach_Tips", function()
	-- Don't show tips during certain states or if disabled
	if disablehud or shoulddrawinfo or drawendmsg or shoulddrawescape or !tipsEnabled:GetBool() then return end
	
	-- Check if we should show a tip
	if tipShowTime > CurTime() and tips[currentTip] then
		local tipText = tips[currentTip]
		local tipHeight = 30
		local tipY = 0
		
		-- Calculate fade alpha
		local alpha = 200
		if CurTime() > tipFadeStart then
			-- Fade out effect
			local fadeProgress = (CurTime() - tipFadeStart) / 2 -- 2 seconds fade
			alpha = math.max(0, 200 * (1 - fadeProgress))
			tipFading = true
		elseif CurTime() < tipFadeStart - tipDuration + 2 then
			-- Fade in effect (first 2 seconds)
			local fadeInProgress = (CurTime() - (tipShowTime - tipDuration)) / 2
			alpha = math.min(200, 200 * fadeInProgress)
		end
		
		-- Dark semi-transparent background bar with fade
		surface.SetDrawColor(0, 0, 0, alpha)
		surface.DrawRect(0, tipY, ScrW(), tipHeight)
		
		-- Calculate text width
		surface.SetFont("TipFont")
		local textWidth = surface.GetTextSize(tipText)
		
		-- Calculate dynamic speed to complete scroll in 10 seconds
		-- Distance to travel: screen width + text width (from right edge to completely off left edge)
		local totalDistance = ScrW() + textWidth
		local dynamicSpeed = totalDistance / tipDuration
		
		-- Update tip position (scroll left)
		tipX = tipX - (dynamicSpeed * FrameTime())
		
		-- Reset position when text goes off screen (shouldn't happen with 10 second duration)
		if tipX + textWidth < 0 then
			tipX = ScrW()
		end
		
		-- Draw the tip text with fade
		local textAlpha = alpha + 55 -- Text slightly more visible than background
		draw.TextShadow( {
			text = tipText,
			pos = { tipX, tipY + tipHeight / 2 },
			font = "TipFont",
			color = Color(255, 200, 0, textAlpha), -- Yellow/gold color with alpha
			xalign = TEXT_ALIGN_LEFT,
			yalign = TEXT_ALIGN_CENTER,
		}, 1, textAlpha )
	end
end )