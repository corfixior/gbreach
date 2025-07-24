-- D-CLASS INFECTED PASSIVE ABILITY FIX
-- Skopiuj ten kod do sv_player.lua zamiast istniejącego kodu infected

-- Viral Aura - damages players who stay too close for too long
local InfectedProximity = {} -- Tabela do śledzenia czasu bliskości

-- Usuń stary timer jeśli istnieje
if timer.Exists("DClassInfected_ViralAura") then
	timer.Remove("DClassInfected_ViralAura")
end

timer.Create("DClassInfected_ViralAura", 1, 0, function()
	for _, infected in pairs(player.GetAll()) do
		if IsValid(infected) and infected:Alive() and infected:GetNClass() == ROLES.ROLE_DCLASS_INFECTED then
			local nearbyPlayers = ents.FindInSphere(infected:GetPos(), 50) -- 50 unit radius
			
			-- Sprawdź wszystkich graczy w pobliżu
			for _, ply in pairs(nearbyPlayers) do
				if IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply != infected and ply:GetNClass() != ROLES.ROLE_DCLASS_INFECTED then
					local steamID = ply:SteamID()
					
					-- Inicjalizuj tracking dla gracza jeśli nie istnieje
					if not InfectedProximity[steamID] then
						InfectedProximity[steamID] = 0
					end
					
					-- Zwiększ czas bliskości
					InfectedProximity[steamID] = InfectedProximity[steamID] + 1
					
					-- Po 10 sekundach bliskości zacznij zadawać damage
					if InfectedProximity[steamID] >= 10 then
						-- Własny system trucizny - zadaj 2 damage co sekundę
						ply:SetHealth(ply:Health() - 2)
						
						-- Sprawdź czy gracz nie umarł
						if ply:Health() <= 0 then
							ply:Kill()
							-- Ustaw infected jako zabójcę
							if IsValid(infected) then
								ply:SetNWEntity("killer", infected)
							end
						end
						
						-- Komunikat co 5 sekund żeby nie spamować
						local safeProx = InfectedProximity[steamID] or 0
						if safeProx % 5 == 0 then
							ply:ChatPrint("You feel sick from prolonged exposure to the infected...")
						end
						
						-- Efekt wizualny trucizny
						ply:ScreenFade(SCREENFADE.IN, Color(50, 200, 50, 20), 0.5, 0)
					end
				end
			end
			
			-- Reset czasu dla graczy którzy odeszli za daleko
			for steamID, time in pairs(InfectedProximity) do
				local ply = player.GetBySteamID(steamID)
				if not IsValid(ply) or not ply:Alive() or ply:GetPos():Distance(infected:GetPos()) > 50 then
					InfectedProximity[steamID] = 0
				end
			end
		end
	end
end)

-- Reset przy śmierci
hook.Add("PostPlayerDeath", "InfectedReset", function(ply)
	if ply:GetNClass() == ROLES.ROLE_DCLASS_INFECTED then
		-- Wyczyść wszystkie timery dla tego gracza
		InfectedProximity = {}
	else
		-- Wyczyść timer dla zmarłego gracza
		InfectedProximity[ply:SteamID()] = nil
	end
end)

-- ConVar do włączania/wyłączania debugowania
if not ConVarExists("breach_infected_debug") then
	CreateConVar("breach_infected_debug", "0", FCVAR_ARCHIVE, "Enable debug messages for D-Class Infected")
end 