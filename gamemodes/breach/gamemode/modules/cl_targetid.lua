
function GM:HUDDrawTargetID()
	local trace = LocalPlayer():GetEyeTrace()
	if !trace.Hit then return end
	if !trace.HitNonWorld then return end
	
	-- If the entity you're looking at is a player using SCP-268 invisibility, don't show TargetID
	if IsValid(trace.Entity) and trace.Entity:IsPlayer() and trace.Entity:GetNWBool("SCP268_Invisible", false) then return end
	
	local text = clang.class_unknown or "Unknown"
	local font = "TargetID"
	local ply =  trace.Entity
	
	local clr = color_white
	local clr2 = color_white
	
	if ply:IsPlayer() then
		if ply:Alive() == false then return end
		if ply:GetPos():Distance(LocalPlayer():GetPos()) > 500 then return end
		if not ply.GetNClass or not ply.GetLastRole then
			player_manager.RunClass( ply, "SetupDataTables" )
		end
		if ply:GTeam() == TEAM_SPEC then return end
		if ply:GetNClass() == ROLES.ROLE_SCP966 then
			local hide = true
			-- Use new NVG toggle system
			if LocalPlayer().NVGActive then
					hide = false
			end
			if (LocalPlayer():GTeam() == TEAM_SCP) then
				hide = false
			end
			if hide == true then return end
		end
		if ply:GetNClass() == ROLES.ROLE_SCP9571 and LocalPlayer():GTeam() != TEAM_SCP then
			text = GetLangRole(ply:GetLastRole())
			clr = gteams.GetColor(ply:GetLastTeam())
			if !text or text == "" then
				text = clang.class_unknown or "Unknown"
			end
		elseif ply:GTeam() == TEAM_SCP then
			text = GetLangRole(ply:GetNClass())
			-- Zabezpieczenie dla SCP0492 (zombie)
			if not text or text == "" then
				text = ply:GetNClass() or "SCP-049-2"
			end
			clr = gteams.GetColor(ply:GTeam())
		else
			for k,v in pairs(SAVEDIDS) do
				if v.pl == ply then
					if v.id != nil then
						if isstring(v.id) then
							text = v.pl.knownrole
							clr = gteams.GetColor(ply:GTeam())
							text = GetLangRole(v.pl.knownrole)
						end
					end
				end
			end
		end
		AddToIDS(ply)
	else
		-- Check if entity has health (func_breakable only)
		if IsValid(trace.Entity) and trace.Entity.Health and trace.Entity:Health() > 0 then
			local ent = trace.Entity
			local entClass = ent:GetClass()
			
			-- Check if it's func_breakable only
			if entClass == "func_breakable" then
				local health = ent:Health()
				local maxHealth = ent:GetMaxHealth()
				
				-- If max health is 0 or unknown, assume current health is max
				if maxHealth <= 0 then
					maxHealth = health
				end
				
				local healthPercent = math.ceil(health * 100 / math.max(1, maxHealth))
				
				-- Determine color based on health percentage
				local healthColor
				if healthPercent >= 75 then
					healthColor = Color(0, 255, 0) -- Green for high health
				elseif healthPercent >= 50 then
					healthColor = Color(255, 255, 0) -- Yellow for medium health
				elseif healthPercent >= 25 then
					healthColor = Color(255, 165, 0) -- Orange for low health
				else
					healthColor = Color(255, 0, 0) -- Red for critical health
				end
				
				local x = ScrW() / 2
				local y = ScrH() / 2 + 30
				
				-- Display object health
				draw.Text( {
					text = "Object (" .. health .. "/" .. maxHealth .. ")",
					pos = { x, y },
					font = "TargetID",
					color = Color(255, 255, 255),
					xalign = TEXT_ALIGN_CENTER,
					yalign = TEXT_ALIGN_CENTER,
				})
				
				draw.Text( {
					text = "Health: " .. healthPercent .. "%",
					pos = { x, y + 16 },
					font = "TargetID",
					color = healthColor,
					xalign = TEXT_ALIGN_CENTER,
					yalign = TEXT_ALIGN_CENTER,
				})
				
				return
			end
		end
		
		
		return
	end
	
	local x = ScrW() / 2
	local y = ScrH() / 2 + 30

	local health = math.ceil( ply:Health() * 100 / math.max( 1, ply:GetMaxHealth() ) )

	-- Determine color based on player health percentage
	local healthColor
	if health >= 75 then
		healthColor = Color(0, 255, 0) -- Green for high health
	elseif health >= 50 then
		healthColor = Color(255, 255, 0) -- Yellow for medium health
	elseif health >= 25 then
		healthColor = Color(255, 165, 0) -- Orange for low health
	else
		healthColor = Color(255, 0, 0) -- Red for critical health
	end

	-- Calculate text widths for proper centering
	surface.SetFont("TargetID")
	local nameText = ply:Nick() .. " ("
	local healthText = health .. "%"
	local endText = ")"
	local fullText = nameText .. healthText .. endText
	
	local nameWidth = surface.GetTextSize(nameText)
	local healthWidth = surface.GetTextSize(healthText)
	local fullWidth = surface.GetTextSize(fullText)
	
	-- Calculate starting position to center the entire text
	local startX = x - fullWidth / 2
	
	-- Draw player name and opening bracket in white
	draw.Text( {
		text = nameText,
		pos = { startX, y },
		font = "TargetID",
		color = color_white,
		xalign = TEXT_ALIGN_LEFT,
		yalign = TEXT_ALIGN_CENTER,
	})
	
	-- Draw health percentage in color
	draw.Text( {
		text = healthText,
		pos = { startX + nameWidth, y },
		font = "TargetID",
		color = healthColor,
		xalign = TEXT_ALIGN_LEFT,
		yalign = TEXT_ALIGN_CENTER,
	})
	
	-- Draw closing bracket in white
	draw.Text( {
		text = endText,
		pos = { startX + nameWidth + healthWidth, y },
		font = "TargetID",
		color = color_white,
		xalign = TEXT_ALIGN_LEFT,
		yalign = TEXT_ALIGN_CENTER,
	})
	
	draw.Text( {
		text = text,
		pos = { x, y + 16 },
		font = "TargetID",
		color = clr,
		xalign = TEXT_ALIGN_CENTER,
		yalign = TEXT_ALIGN_CENTER,
	})
end
