-- Custom HUD for br_hud 3
-- Modern minimalist design

local hide = {
	CHudHealth = true,
	CHudBattery = true,
	CHudAmmo = true,
	CHudSecondaryAmmo = true,
	CHudDeathNotice = true,
}

hook.Add( "HUDShouldDraw", "HideHUDElements_Custom", function( name )
	-- Custom HUD disabled
	return
	--[[
	if name == "CHudWeaponSelection" and GetConVar( "br_new_eq" ):GetInt() == 1 then
		return false
	end
	if hide[ name ] then return false end
	--]]
end )

-- Custom fonts for the new HUD
surface.CreateFont( "CustomHUDFont", {
    font = "Roboto",
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

surface.CreateFont( "CustomHUDFontBig", {
    font = "Roboto",
    extended = false,
    size = 24,
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

surface.CreateFont( "CustomHUDFontSmall", {
    font = "Roboto",
    extended = false,
    size = 14,
    weight = 400,
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

-- Custom HUD Paint Hook
hook.Add( "HUDPaint", "Breach_CustomHUD", function()
	if disablehud then return end
	-- Custom HUD disabled - using classic HUD only
	return
	--[[
	local ply = LocalPlayer()
	local w, h = ScrW(), ScrH()
	
	-- Get player info (works for both alive and spectator)
	local role = "Unknown"
	local displayPly = ply
	local isSpectating = false
	
	if ply:GTeam() == TEAM_SPEC then
		isSpectating = true
		local ent = ply:GetObserverTarget()
		if IsValid(ent) and ent:IsPlayer() then
			displayPly = ent
			if ent.GetNClass then
				role = GetLangRole(ent:GetNClass()) or "Unknown"
			end
		else
			if ply:Alive() == false then return end
		end
	else
		if ply:Alive() == false then return end
		if not ply.GetNClass then
			player_manager.RunClass( ply, "SetupDataTables" )
		else
			role = GetLangRole(ply:GetNClass()) or "Unknown"
		end
	end
	
	local hp = displayPly:Health()
	local maxhp = displayPly:GetMaxHealth()
	local blink = blinkHUDTime or 0
	local bd = GetConVar("br_time_blinkdelay"):GetFloat()
	local color = gteams.GetColor(displayPly:GTeam())
	if displayPly:GTeam() == TEAM_CHAOS then
		color = Color(29, 81, 56)
	end
	
	-- Use neutral color when spectating
	if isSpectating then
		color = Color(60, 60, 60) -- Neutral gray color
	end
	
	-- Time display (top center)
	local timel = tostring(string.ToMinutesSeconds(cltime))
	local timeW, timeH = 120, 35
	local timeX, timeY = w / 2 - timeW / 2, 15
	
	draw.RoundedBox(8, timeX, timeY, timeW, timeH, Color(0, 0, 0, 150))
	draw.RoundedBox(8, timeX + 2, timeY + 2, timeW - 4, timeH - 4, Color(60, 60, 60, 180))
	draw.SimpleText(timel, "CustomHUDFontBig", w / 2, timeY + timeH / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
	-- Main HUD panel (left side)
	local panelW, panelH = 280, 120
	local panelX, panelY = 20, h - panelH - 20
	
	-- Main panel background
	draw.RoundedBox(12, panelX, panelY, panelW, panelH, Color(0, 0, 0, 160))
	draw.RoundedBox(12, panelX + 3, panelY + 3, panelW - 6, panelH - 6, Color(30, 30, 30, 200))
	
	-- Role header with player name (if spectating)
	local roleH = 30
	local headerText = role
	if isSpectating and IsValid(displayPly) then
		headerText = string.sub(displayPly:Nick(), 1, 20)
	end
	draw.RoundedBox(8, panelX + 10, panelY + 10, panelW - 20, roleH, color)
	draw.SimpleText(headerText, "CustomHUDFont", panelX + panelW / 2, panelY + 10 + roleH / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
	-- Health bar
	local barY = panelY + 50
	local barW = panelW - 40
	local barH = 20
	local barX = panelX + 20
	
	draw.RoundedBox(4, barX, barY, barW, barH, Color(60, 60, 60))
	local hpPercent = math.Clamp(hp / maxhp, 0, 1)
	local hpColor = Color(255 * (1 - hpPercent), 255 * hpPercent, 0)
	draw.RoundedBox(4, barX + 2, barY + 2, (barW - 4) * hpPercent, barH - 4, hpColor)
	
	-- Health text
	draw.SimpleText("HP: " .. hp .. "/" .. maxhp, "CustomHUDFontSmall", barX + 5, barY + barH / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	
	-- Blink bar (if applicable)
	if bd > 0 then
		barY = barY + 25
		draw.RoundedBox(4, barX, barY, barW, barH, Color(60, 60, 60))
		local blinkPercent = math.Clamp(blink / bd, 0, 1)
		draw.RoundedBox(4, barX + 2, barY + 2, (barW - 4) * blinkPercent, barH - 4, Color(100, 150, 255))
		
		-- Blink text
		local blinkText = string.format("Blink: %.1f/%.1f", blink, bd)
		draw.SimpleText(blinkText, "CustomHUDFontSmall", barX + 5, barY + barH / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
	
	-- Ammo display (left side, below main panel)
	local ammo = -1
	local mag = -1
	if displayPly:GetActiveWeapon() != nil then
		local wep = displayPly:GetActiveWeapon()
		if wep.Clip1 and wep:Clip1() > -1 then
			ammo = wep:Clip1()
			mag = displayPly:GetAmmoCount(wep:GetPrimaryAmmoType())
		end
	end
	
	if ammo >= 0 then
		local ammoW, ammoH = 120, 60
		local ammoX, ammoY = panelX, panelY - ammoH - 10
		
		draw.RoundedBox(8, ammoX, ammoY, ammoW, ammoH, Color(0, 0, 0, 160))
		draw.RoundedBox(8, ammoX + 3, ammoY + 3, ammoW - 6, ammoH - 6, Color(40, 40, 40, 200))
		
		-- Ammo numbers
		draw.SimpleText(tostring(ammo), "CustomHUDFontBig", ammoX + ammoW / 2, ammoY + 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("+" .. tostring(mag), "CustomHUDFont", ammoX + ammoW / 2, ammoY + 40, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	--]]
end )