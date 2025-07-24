local MODEL_CAMERA_HEIGHTS = {
	-- Małe modele (misie, SCP-066)
	["models/player/mrsilver/scp_066pm/scp_066_pm.mdl"] = {stand = 30, duck = 15},
	["models/yevocore/cat/cat.mdl"] = {stand = 30, duck = 15},
	["models/nickelodeon_all_stars/garfield/garfield.mdl"] = {stand = 35, duck = 15},
	["models/cktheamazingfrog/player/lasagna/lasagna.mdl"] = {stand = 35, duck = 15},
	["models/lenoax/amongus/suit_pm.mdl"] = {stand = 40, duck = 15},
	["models/scp/999/jq/scp_999_pmjq.mdl"] = {stand = 30, duck = 15},
	["models/1048/tdyear/tdybrownearpm.mdl"] = {stand = 20, duck = 15},
	["models/player/teddy_bear/teddy_bear.mdl"] = {stand = 56, duck = 28},
	
	-- Niskie modele models/yevocore/cat/cat.mdl
	["models/novux/023/novux_scp-023.mdl"] = {stand = 36, duck = 28},
	["models/props/forest_monster/forest_monster2.mdl"] = {stand = 36, duck = 28},
	
	-- Średnio-niskie modele
	--["models/vinrax/player/scp049_player.mdl"] = {stand = 46, duck = 28},--
	["models/scp/939/unity/unity_scp_939.mdl"] = {stand = 50, duck = 28},
	
	-- SCP-527 (Mr. Fish)
	["models/scp_527/scp_527.mdl"] = {stand = 64, duck = 28}, -- Normalna wysokość
	
	-- Wysokie modele models/nickelodeon_all_stars/garfield/garfield.mdl
	["models/scp096anim/player/scp096pm_raf.mdl"] = {stand = 69, duck = 28},
	["models/danx91/scp/scp_682.mdl"] = {stand = 69, duck = 28},
	["models/jqueary/scp/unity/scp173/scp173unity.mdl"] = {stand = 75, duck = 28},
}

-- Funkcja do aktualizacji wysokości kamery
local function UpdateCameraHeight(ply)
	if not IsValid(ply) then return end
	
	local model = ply:GetModel()
	if not model then return end
	

	
	-- Znajdź wysokość dla tego modelu
	local heights = MODEL_CAMERA_HEIGHTS[string.lower(model)]
	
	if heights then
		-- Ustaw niestandardową wysokość
		ply:SetViewOffset(Vector(0, 0, heights.stand))
		ply:SetViewOffsetDucked(Vector(0, 0, heights.duck))
	else
		-- Ustaw domyślną wysokość
		ply:SetViewOffset(Vector(0, 0, 64))
		ply:SetViewOffsetDucked(Vector(0, 0, 28))
	end
end

-- Hook na spawn gracza
hook.Add("PlayerSpawn", "ModelBasedCameraHeight_OnSpawn", function(ply)
	UpdateCameraHeight(ply)
end)

-- Hook na zmianę modelu
hook.Add("PlayerSetModel", "ModelBasedCameraHeight_OnSetModel", function(ply)
	UpdateCameraHeight(ply)
end)

-- Dodatkowy hook na PlayerLoadout
hook.Add("PlayerLoadout", "ModelBasedCameraHeight_OnLoadout", function(ply)
	timer.Simple(0.1, function()
		if IsValid(ply) then
			UpdateCameraHeight(ply)
		end
	end)
end)

-- Hook na PlayerInitialSpawn
hook.Add("PlayerInitialSpawn", "ModelBasedCameraHeight_OnInitialSpawn", function(ply)
	timer.Simple(0.1, function()
		if IsValid(ply) then
			UpdateCameraHeight(ply)
		end
	end)
end)

-- Hook na Think - sprawdza zmiany modelu w czasie rzeczywistym
local lastModels = {}
hook.Add("Think", "ModelBasedCameraHeight_OnThink", function()
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) then
			local currentModel = ply:GetModel()
			if lastModels[ply] ~= currentModel then
				lastModels[ply] = currentModel
				UpdateCameraHeight(ply)
			end
		end
	end
end)