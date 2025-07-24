AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "SCP-1123"
ENT.Category = "SCP"
ENT.Spawnable = false
ENT.AdminSpawnable = true

-- Globalne zmienne dla cooldownu
SCP1123_LastUse = 0
SCP1123_CooldownTime = 360 -- 6 minut

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/Gibs/HGIBS.mdl") -- Model czaszki z GModa
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE) -- Przyklejony do podłogi
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false) -- Blokada ruchu
		end
		
		-- Ustawienie pozycji
		self:SetPos(Vector(575.883728, -1745.303711, 51.031250))
		self:SetAngles(Angle(0, 90, 0))
		
		-- Network zmienne dla cooldownu
		self:SetNWFloat("SCP1123_NextUse", 0)
	end
end

function ENT:Use(activator, caller)
	if not SERVER then return end
	if not IsValid(activator) or not activator:IsPlayer() then return end
	
	-- Zablokuj użycie przez SCP
	if activator:GTeam() == TEAM_SCP then
		activator:PrintMessage(HUD_PRINTTALK, "SCP entities cannot use SCP-1123!")
		return
	end
	
	-- Sprawdź cooldown
	local currentTime = CurTime()
	local nextUseTime = self:GetNWFloat("SCP1123_NextUse", 0)
	
	if currentTime < nextUseTime then
		local timeLeft = math.ceil(nextUseTime - currentTime)
		local minutes = math.floor(timeLeft / 60)
		local seconds = timeLeft % 60
		activator:PrintMessage(HUD_PRINTTALK, string.format("SCP-1123 is still recharging... %d:%02d remaining", minutes, seconds))
		return
	end
	
	-- Sprawdź czy gracz nie jest już w efekcie SCP-1123
	if activator:GetNWBool("SCP1123_InEffect", false) then
		activator:PrintMessage(HUD_PRINTTALK, "You are already under SCP-1123's influence!")
		return
	end
	
	-- Ustaw cooldown
	self:SetNWFloat("SCP1123_NextUse", currentTime + SCP1123_CooldownTime)
	
	-- Rozpocznij efekt
	self:StartSCP1123Effect(activator)
	
	activator:PrintMessage(HUD_PRINTTALK, "You touch the skull... memories flood your mind...")
end

function ENT:StartSCP1123Effect(ply)
	if not IsValid(ply) then return end
	
	-- Zapisz pozycję gracza
	ply.SCP1123_OriginalPos = ply:GetPos()
	ply.SCP1123_OriginalAngles = ply:GetAngles()
	
	-- Ustaw status efektu
	ply:SetNWBool("SCP1123_InEffect", true)
	ply:SetNWFloat("SCP1123_EffectEnd", CurTime() + 60) -- 60 sekund
	
	-- Zamroź gracza
	ply:Freeze(true)
	
	-- Teleportuj za mapę
	local hiddenPos = Vector(-10000, -10000, -1000) -- Pozycja za mapą
	ply:SetPos(hiddenPos)
	
	-- Znajdź losowego SCP i ustaw kamerę
	self:SetCameraToRandomSCP(ply)
	
	-- Timer na zakończenie efektu
	timer.Create("SCP1123_Effect_" .. ply:SteamID64(), 60, 1, function()
		if IsValid(ply) then
			self:EndSCP1123Effect(ply)
		end
	end)
	
	-- Wyślij wiadomość do klienta o rozpoczęciu efektu
	net.Start("SCP1123_StartEffect")
	net.Send(ply)
end

function ENT:SetCameraToRandomSCP(ply)
	if not IsValid(ply) then return end
	
	-- Znajdź wszystkich SCP
	local scps = {}
	for _, p in pairs(player.GetAll()) do
		if IsValid(p) and p:Alive() and p:GTeam() == TEAM_SCP then
			table.insert(scps, p)
		end
	end
	
	-- Jeśli są SCP, ustaw kamerę na losowego
	if #scps > 0 then
		local randomSCP = scps[math.random(1, #scps)]
		-- Stwórz niewidzialną kamerę za SCP
		local camera = ents.Create("prop_physics")
		camera:SetModel("models/hunter/plates/plate.mdl")
		camera:SetMaterial("engine/writez") -- Niewidzialna
		camera:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		camera:SetMoveType(MOVETYPE_NOCLIP)
		camera:SetSolid(SOLID_NONE)
		
		-- Pozycja kamery za SCP
		local backOffset = randomSCP:GetAngles():Forward() * -150
		local upOffset = Vector(0, 0, 100)
		camera:SetPos(randomSCP:GetPos() + backOffset + upOffset)
		camera:SetAngles(randomSCP:EyeAngles())
		camera:Spawn()
		
		-- Zapisz referencje
		ply.SCP1123_Camera = camera
		ply.SCP1123_Target = randomSCP
		ply:SetNWEntity("SCP1123_Target", randomSCP)
		
		-- Ustaw kamerę na naszą encję
		ply:SetViewEntity(camera)
		
		-- Timer do aktualizacji pozycji kamery
		timer.Create("SCP1123_Camera_" .. ply:SteamID64(), 0.05, 0, function()
			if IsValid(ply) and IsValid(camera) and IsValid(randomSCP) and ply:GetNWBool("SCP1123_InEffect", false) then
				local newBackOffset = randomSCP:GetAngles():Forward() * -150
				local newUpOffset = Vector(0, 0, 100)
				
				-- Płynne przemieszczanie kamery
				local targetPos = randomSCP:GetPos() + newBackOffset + newUpOffset
				local currentPos = camera:GetPos()
				local lerpedPos = LerpVector(0.1, currentPos, targetPos)
				
				-- Płynne obracanie kamery
				local targetAngles = randomSCP:EyeAngles()
				local currentAngles = camera:GetAngles()
				local lerpedAngles = LerpAngle(0.1, currentAngles, targetAngles)
				
				camera:SetPos(lerpedPos)
				camera:SetAngles(lerpedAngles)
			else
				timer.Remove("SCP1123_Camera_" .. ply:SteamID64())
			end
		end)
		ply:PrintMessage(HUD_PRINTTALK, "You see through the eyes of " .. randomSCP:Nick() .. "...")
	else
		-- Brak SCP - pozostaw normalną kamerę
		ply:PrintMessage(HUD_PRINTTALK, "The memories are unclear... no current presence detected...")
	end
end

function ENT:EndSCP1123Effect(ply)
	if not IsValid(ply) then return end
	
	-- Przywróć normalną kamerę
	ply:SetViewEntity(ply)
	
	-- Usuń kamerę
	if IsValid(ply.SCP1123_Camera) then
		ply.SCP1123_Camera:Remove()
	end
	timer.Remove("SCP1123_Camera_" .. ply:SteamID64())
	
	-- Teleportuj z powrotem na pierwotną pozycję
	if ply.SCP1123_OriginalPos then
		ply:SetPos(ply.SCP1123_OriginalPos)
		ply:SetAngles(ply.SCP1123_OriginalAngles)
	end
	
	-- Odblokuj gracza
	ply:Freeze(false)
	
	-- Nagroda: +30 max HP i pełne życie
	local newMaxHP = ply:GetMaxHealth() + 30
	ply:SetMaxHealth(newMaxHP)
	ply:SetHealth(newMaxHP)
	
	-- Wyczyść zmienne
	ply:SetNWBool("SCP1123_InEffect", false)
	ply:SetNWFloat("SCP1123_EffectEnd", 0)
	ply.SCP1123_OriginalPos = nil
	ply.SCP1123_OriginalAngles = nil
	ply:SetNWEntity("SCP1123_Target", NULL)
	
	-- Usuń timer
	timer.Remove("SCP1123_Effect_" .. ply:SteamID64())
	
	-- Wyślij wiadomość do klienta o zakończeniu
	net.Start("SCP1123_EndEffect")
	net.Send(ply)
	
	ply:PrintMessage(HUD_PRINTTALK, "The memories fade... you feel stronger (+30 Max Health)")
end

-- Cleanup przy disconneccie
if SERVER then
	hook.Add("PlayerDisconnected", "SCP1123_Cleanup", function(ply)
		if IsValid(ply) then
			timer.Remove("SCP1123_Effect_" .. ply:SteamID64())
		end
	end)
end 