include("shared.lua")

-- Font dla HUD
if CLIENT then
	surface.CreateFont("SCP215_Small", {
		font = "Trebuchet24", 
		size = 18,
		weight = 500,
		antialias = true,
		shadow = true
	})
	
	surface.CreateFont("SCP215_Warning", {
		font = "Trebuchet24", 
		size = 24,
		weight = 700,
		antialias = true,
		shadow = true
	})
end

-- HUD dla SCP-215
function SWEP:DrawHUD()
	if disablehud == true then return end
	
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	-- Pozycja HUD
	local x = ScrW() / 2
	local y = ScrH() / 2 - 50
	
	local isActive = ply:GetNWBool("SCP215_Active", false)
	
	-- Prosty tekst instrukcji
	if isActive then
		draw.SimpleText("Take off SCP-215", "SCP215_Small", x, y, Color(255, 100, 100), TEXT_ALIGN_CENTER)
	else
		draw.SimpleText("Put on SCP-215", "SCP215_Small", x, y, Color(100, 255, 100), TEXT_ALIGN_CENTER)
	end
end

-- Globalna tabela dla modeli okularów na graczach
SCP215_PlayerGlasses = SCP215_PlayerGlasses or {}

-- Funkcja tworząca model okularów na graczu
local function CreatePlayerGlasses(ply)
	if SCP215_PlayerGlasses[ply] then return end -- Już ma okulary
	
	local glassesModel = ClientsideModel("models/maxpayne/weapons/shades.mdl")
	if not IsValid(glassesModel) then return end
	
	-- Konfiguracja modelu
	glassesModel:SetNoDraw(true) -- Nie rysuj automatycznie
	glassesModel:SetModelScale(0.8) -- Zmniejsz rozmiar
	
	SCP215_PlayerGlasses[ply] = glassesModel
end

-- Funkcja usuwająca model okularów z gracza
local function RemovePlayerGlasses(ply)
	if SCP215_PlayerGlasses[ply] then
		if IsValid(SCP215_PlayerGlasses[ply]) then
			SCP215_PlayerGlasses[ply]:Remove()
		end
		SCP215_PlayerGlasses[ply] = nil
	end
end

-- Funkcja pozycjonująca okulary na graczu
local function PositionPlayerGlasses(ply, glassesModel)
	if not IsValid(ply) or not IsValid(glassesModel) then return end
	if not ply:Alive() then return end
	
	-- Spróbuj znaleźć attachment "eyes" lub "head"
	local eyesAttach = ply:LookupAttachment("eyes")
	local headAttach = ply:LookupAttachment("head")
	
	local attachID = eyesAttach > 0 and eyesAttach or (headAttach > 0 and headAttach or 0)
	
	if attachID > 0 then
		-- Użyj attachment
		local attachData = ply:GetAttachment(attachID)
		if attachData then
			local pos = attachData.Pos
			local ang = attachData.Ang
			
			-- Offset dla okularów (przybliżony do twarzy)
			pos = pos + ang:Forward() * 0.5 + ang:Up() * -1
			ang:RotateAroundAxis(ang:Right(), 0) -- Dodatkowa rotacja jeśli potrzebna
			
			glassesModel:SetPos(pos)
			glassesModel:SetAngles(ang)
		end
	else
		-- Fallback - użyj pozycji głowy
		local headPos = ply:EyePos()
		local headAng = ply:EyeAngles()
		
		-- Offset dla okularów
		headPos = headPos + headAng:Forward() * 0.1 + headAng:Up() * -2
		
		glassesModel:SetPos(headPos)
		glassesModel:SetAngles(headAng)
	end
end

-- Hook zarządzający modelami okularów na graczach
hook.Add("Think", "SCP215_ManagePlayerGlasses", function()
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and ply:Alive() then
			-- Sprawdź czy gracz ma SCP-215 aktywny
			local hasSCP215Active = ply:GetNWBool("SCP215_Active", false)
			
			if hasSCP215Active then
				-- Gracz ma SCP-215 aktywny - utwórz okulary jeśli ich nie ma
				if not SCP215_PlayerGlasses[ply] then
					CreatePlayerGlasses(ply)
				end
				
				-- Pozycjonuj okulary
				if SCP215_PlayerGlasses[ply] and IsValid(SCP215_PlayerGlasses[ply]) then
					PositionPlayerGlasses(ply, SCP215_PlayerGlasses[ply])
				end
			else
				-- Gracz nie ma SCP-215 aktywny - usuń okulary
				RemovePlayerGlasses(ply)
			end
		else
			-- Gracz nie żyje - usuń okulary
			RemovePlayerGlasses(ply)
		end
	end
end)

-- Hook renderujący modele okularów
hook.Add("PostPlayerDraw", "SCP215_DrawPlayerGlasses", function(ply)
	if SCP215_PlayerGlasses[ply] and IsValid(SCP215_PlayerGlasses[ply]) then
		SCP215_PlayerGlasses[ply]:DrawModel()
	end
end)

-- Czyszczenie przy disconneccie gracza
hook.Add("PlayerDisconnected", "SCP215_CleanupGlasses", function(ply)
	RemovePlayerGlasses(ply)
end)

-- Czyszczenie wszystkich okularów przy rozpoczęciu rundy
hook.Add("RoundStart", "SCP215_CleanupAllGlasses", function()
	for ply, glassesModel in pairs(SCP215_PlayerGlasses) do
		if IsValid(glassesModel) then
			glassesModel:Remove()
		end
	end
	SCP215_PlayerGlasses = {}
end)

-- Funkcja sprawdzająca czy gracz jest wrogiem
local function IsEnemyPlayer(ply, localPly)
	if not IsValid(ply) or not IsValid(localPly) then return false end
	if ply == localPly then return false end
	if not ply:Alive() then return false end
	
	local localTeam = localPly:GTeam()
	local playerTeam = ply:GTeam()
	
	-- Spectatorzy nie są wrogami
	if playerTeam == TEAM_SPEC then return false end
	
	-- CLASSD i CHAOS to sojusznicy
	if (localTeam == TEAM_CLASSD and playerTeam == TEAM_CHAOS) or (localTeam == TEAM_CHAOS and playerTeam == TEAM_CLASSD) then
		return false
	end
	
	-- Różne teamy = wrogowie
	return localTeam ~= playerTeam
end

-- Funkcja rysująca czerwony kwadrat z wykrzyknikiem
local function DrawEnemyMarker(pos2d)
	local size = 30
	local x = pos2d.x - size/2
	local y = pos2d.y - size/2
	
	-- Czerwony kwadrat (tło)
	surface.SetDrawColor(255, 0, 0, 200)
	surface.DrawRect(x, y, size, size)
	
	-- Czarna ramka
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawOutlinedRect(x, y, size, size)
	
	-- Biały wykrzyknik
	draw.SimpleText("!", "SCP215_Warning", pos2d.x, pos2d.y, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Hook dla renderowania markerów wrogów
if CLIENT then
	hook.Add("HUDPaint", "SCP215_EnemyDetection", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		
		-- Sprawdź czy gracz ma SCP-215 i jest aktywny
		local isActive = ply:GetNWBool("SCP215_Active", false)
		if not isActive then return end
		
		-- Sprawdź czy gracz trzyma SCP-215
		local currentWep = ply:GetActiveWeapon()
		if not IsValid(currentWep) or currentWep:GetClass() ~= "item_scp_215" then return end
		
		-- Iteruj przez wszystkich graczy
		for _, target in pairs(player.GetAll()) do
			if IsEnemyPlayer(target, ply) then
				-- Sprawdź zasięg
				local distance = ply:GetPos():Distance(target:GetPos())
				if distance <= 2000 then -- 2000 jednostek zasięgu
					-- Sprawdź czy gracz jest w polu widzenia
					local targetPos = target:GetPos() + Vector(0, 0, 75) -- Pozycja nad głową
					local screenPos = targetPos:ToScreen()
					
					-- Sprawdź czy jest na ekranie
					if screenPos.visible then
						-- Sprawdź czy nie jest zasłonięty
						local tr = util.TraceLine({
							start = ply:EyePos(),
							endpos = target:EyePos(),
							filter = {ply, target},
							mask = MASK_VISIBLE
						})
						
						-- Sprawdź czy trace nie trafił w ścianę
						if not tr.Hit or tr.Entity == target then
							DrawEnemyMarker(screenPos)
						end
					end
				end
			end
		end
	end)
	
	-- Hook dla globalnego statusu (gdy nie trzyma okularów)
	hook.Add("HUDPaint", "SCP215_GlobalStatus", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		
		-- Sprawdź czy ma SCP-215 ale nie trzyma go aktualnie
		if ply:HasWeapon("item_scp_215") then
			local currentWep = ply:GetActiveWeapon()
			if not IsValid(currentWep) or currentWep:GetClass() ~= "item_scp_215" then
				-- Ma SCP-215 ale nie trzyma go - pokaż status
				local cooldownTime = ply:GetNWFloat("SCP215_Cooldown", 0)
				local isActive = ply:GetNWBool("SCP215_Active", false)
				
				if cooldownTime > CurTime() then
					-- Pokaż cooldown
					local x = ScrW() / 2
					local y = 30
					
					local timeLeft = math.ceil(cooldownTime - CurTime())
					local text = "SCP-215: " .. timeLeft .. "s [COOLDOWN]"
					draw.SimpleText(text, "SCP215_Small", x, y, Color(255, 150, 150), TEXT_ALIGN_CENTER)
					
					-- Pasek postępu
					local barWidth = 100
					local barHeight = 4
					local progress = 1 - (timeLeft / 5)
					
					-- Tło paska
					surface.SetDrawColor(0, 0, 0, 150)
					surface.DrawRect(x - barWidth/2, y + 20, barWidth, barHeight)
					
					-- Wypełnienie paska
					surface.SetDrawColor(255, 150, 150, 255)
					surface.DrawRect(x - barWidth/2, y + 20, barWidth * progress, barHeight)
				end
			end
		end
	end)
end