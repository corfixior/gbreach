-- SCP-1123 Client Module
-- Moduł kliencki dla SCP-1123 "Skull of Memories"

-- Font dla HUD (taki sam jak SCP-1499)
surface.CreateFont("SCP1123_Small", {
	font = "Trebuchet24", 
	size = 18,
	weight = 500,
	antialias = true,
	shadow = true
})

-- Zmienne lokalne
local effectActive = false
local effectEndTime = 0

-- Network message handlers
net.Receive("SCP1123_StartEffect", function()
	effectActive = true
	effectEndTime = CurTime() + 60
end)

net.Receive("SCP1123_EndEffect", function()
	effectActive = false
	effectEndTime = 0
end)

-- HUD Timer dla gracza w efekcie SCP-1123 (styl SCP-1499)
hook.Add("HUDPaint", "SCP1123_EffectTimer", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	-- Sprawdź czy gracz jest w efekcie (przez network var lub local var)
	local inEffect = ply:GetNWBool("SCP1123_InEffect", false) or effectActive
	
	if inEffect then
		local timeLeft = math.max(0, ply:GetNWFloat("SCP1123_EffectEnd", effectEndTime) - CurTime())
		
		if timeLeft > 0 then
			-- Pozycja HUD prosto nad celownikiem (jak w SCP-1499)
			local x = ScrW() / 2
			local y = ScrH() / 2 - 50 -- 50 pikseli nad środkiem ekranu
			
			-- Tekst timera
			local timerText = string.format("MEMORY: %.1fs", timeLeft)
			
			-- Kolor zmieniający się z czasem
			local progress = timeLeft / 60
			local color
			if progress > 0.5 then
				color = Color(100, 255, 100) -- Zielony
			elseif progress > 0.25 then
				color = Color(255, 255, 100) -- Żółty
			else
				color = Color(255, 100, 100) -- Czerwony
			end
			
			-- Tekst (styl SCP-1499)
			draw.SimpleText(timerText, "SCP1123_Small", x, y - 20, color, TEXT_ALIGN_CENTER)
			
			-- Pasek postępu (styl SCP-1499)
			local barWidth = 100
			local barHeight = 4
			
			-- Tło paska
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(x - barWidth/2, y, barWidth, barHeight)
			
			-- Wypełnienie paska
			surface.SetDrawColor(color.r, color.g, color.b, 255)
			surface.DrawRect(x - barWidth/2, y, barWidth * progress, barHeight)
		end
	end
end)

-- Prosty efekt rozmycia i szarości podczas obserwacji
hook.Add("RenderScreenspaceEffects", "SCP1123_SimpleEffects", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	local inEffect = ply:GetNWBool("SCP1123_InEffect", false) or effectActive
	
	if inEffect then
		-- Rozmycie ekranu
		DrawMotionBlur(0.2, 0.9, 0.02)
		
		-- Szarość (desaturacja)
		local colorModify = {
			["$pp_colour_colour"] = 0.3,  -- Mocna desaturacja (30% kolorów)
			["$pp_colour_brightness"] = -0.1  -- Trochę ciemniej
		}
		DrawColorModify(colorModify)
	end
end)

-- HUD dla pokazania cooldownu SCP-1123 (gdy gracz jest blisko) - styl SCP-1499
hook.Add("HUDPaint", "SCP1123_CooldownDisplay", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	-- Znajdź najbliższą SCP-1123 entity
	local closestSCP1123 = nil
	local closestDist = 200 -- Maksymalna odległość do pokazania cooldownu
	
	for _, ent in pairs(ents.FindByClass("scp_1123")) do
		if IsValid(ent) then
			local dist = ent:GetPos():Distance(ply:GetPos())
			if dist < closestDist then
				closestSCP1123 = ent
				closestDist = dist
			end
		end
	end
	
	-- Jeśli jest blisko SCP-1123, pokaż cooldown (styl SCP-1499)
	if IsValid(closestSCP1123) then
		local nextUse = closestSCP1123:GetNWFloat("SCP1123_NextUse", 0)
		local currentTime = CurTime()
		
		-- Pozycja HUD (jak w SCP-1499)
		local x = ScrW() / 2
		local y = ScrH() / 2 - 50
		
		-- Pasek postępu - ustawienia (jak w SCP-1499)
		local barWidth = 100
		local barHeight = 4
		
		if currentTime < nextUse then
			-- Jest cooldown - pokaż pozostały czas
			local timeLeft = nextUse - currentTime
			local minutes = math.floor(timeLeft / 60)
			local seconds = math.floor(timeLeft % 60)
			
			local cooldownText = string.format("CD: %d:%02d", minutes, seconds)
			
			-- Tekst (styl SCP-1499)
			draw.SimpleText(cooldownText, "SCP1123_Small", x, y - 20, Color(255, 100, 100), TEXT_ALIGN_CENTER)
			
			-- Pasek postępu
			local progress = 1 - (timeLeft / 360)
			
			-- Tło paska
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(x - barWidth/2, y, barWidth, barHeight)
			
			-- Wypełnienie paska
			surface.SetDrawColor(255, 100, 100, 255)
			surface.DrawRect(x - barWidth/2, y, barWidth * progress, barHeight)
		else
			-- Gotowe do użycia (styl SCP-1499)
			draw.SimpleText("READY", "SCP1123_Small", x, y - 20, Color(100, 255, 100), TEXT_ALIGN_CENTER)
			
			-- Pasek pełny
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(x - barWidth/2, y, barWidth, barHeight)
			
			surface.SetDrawColor(100, 255, 100, 255)
			surface.DrawRect(x - barWidth/2, y, barWidth, barHeight)
		end
	end
end)

print("[Breach] SCP-1123 Client Module Loaded") 