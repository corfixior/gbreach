CreateConVar("doorcontrol_admin_only", "0", FCVAR_ARCHIVE, "Only allow admins to equip the door control SWEP. You must restart the server to apply the changes")
CreateConVar("doorcontrol_max_distance", "1000", FCVAR_ARCHIVE, "Maximum distance to interact with doors (units)")
CreateConVar("doorcontrol_multipart_range", "100", FCVAR_ARCHIVE, "Range to search for additional door parts (units)")
CreateConVar("doorcontrol_block_time", "10", FCVAR_ARCHIVE, "Time in seconds to block doors with RMB")

local function SetViewModelSkin(ply, skinIndex)
	local vm = ply:GetViewModel()
	if not IsValid(vm) then return end
	vm:SetSkin(skinIndex)
	timer.Simple(0.65, function()
		if IsValid(vm) and vm:GetSkin() == skinIndex then
		vm:SetSkin(0)
		end
	end)
end


SWEP.PrintName = "Door Controller"
SWEP.Author = "Echo"
SWEP.Instructions = "LMB: Open Door\nRMB: Block Door (Timed)"
SWEP.Category = "Other"

SWEP.Spawnable = true
SWEP.AdminOnly = GetConVar("doorcontrol_admin_only"):GetBool()

SWEP.UseHands = true
SWEP.DrawAmmo = false
SWEP.ViewModelFOV = 60
SWEP.ViewModel = "models/weapons/c_door_opener.mdl"
SWEP.WorldModel = "models/weapons/w_door_opener.mdl"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary = SWEP.Primary

SWEP.SharedCooldown = 0.8

function SWEP:CanUse()
	if not self.NextUse then self.NextUse = 0 end
	return CurTime() >= self.NextUse
end

function SWEP:CanUseRMB()
	if not self.NextRMBUse then self.NextRMBUse = 0 end
	return CurTime() >= self.NextRMBUse
end

function SWEP:SetSharedCooldown()
	self.NextUse = CurTime() + self.SharedCooldown
end

function SWEP:SetRMBCooldown()
	self.NextRMBUse = CurTime() + 30.0 -- 3 sekundy cooldown dla RMB
end

function SWEP:Initialize()
	self:SetHoldType("pistol")
end

local function IsDoor(ent)
	if not IsValid(ent) then return false end
	local class = ent:GetClass()
	return class == "prop_door_rotating" or class == "func_door" or class == "func_door_rotating"
end

-- Funkcja do znajdowania wszystkich części drzwi w pobliżu
local function GetAllDoorParts(mainDoor, searchRadius)
	if not IsValid(mainDoor) then return {} end
	
	local doorParts = {mainDoor}
	local mainPos = mainDoor:GetPos()
	local searchRange = searchRadius or GetConVar("doorcontrol_multipart_range"):GetFloat()
	
	-- Znajdź wszystkie entity w pobliżu
	local nearbyEnts = ents.FindInSphere(mainPos, searchRange)
	
	for _, ent in pairs(nearbyEnts) do
		if IsValid(ent) and ent ~= mainDoor then
			local class = ent:GetClass():lower()
			local isDoorEntity = false
			
			-- Sprawdź czy to entity drzwiowe
			if class:find("door") or class == "func_door" or class == "func_door_rotating" or class == "prop_door_rotating" then
				isDoorEntity = true
			elseif ent.IsDoor and ent:IsDoor() then
				isDoorEntity = true
			end
			
			-- Jeśli to część drzwi, sprawdź czy nie jest zablokowana
			if isDoorEntity then
				if ent.ignoredoorcontroller ~= false then -- Dozwolone jeśli nie jest explicite zablokowane dla Door Controller
					-- Sprawdź czy już nie ma tego w tablicy
					local alreadyAdded = false
					for _, existingDoor in pairs(doorParts) do
						if existingDoor == ent then
							alreadyAdded = true
							break
						end
					end
					
					if not alreadyAdded then
						table.insert(doorParts, ent)
					end
				end
			end
		end
	end
	
	return doorParts
end

local function GetDoor(ply)
	local tr = ply:GetEyeTrace()
	local ent = tr.Entity

	local maxDist = GetConVar("doorcontrol_max_distance"):GetFloat()
	if not IsValid(ent) or tr.HitPos:DistToSqr(ply:GetShootPos()) > maxDist * maxDist then return nil end

	local class = ent:GetClass():lower()
	local mainDoor = nil

	if class:find("door") or class == "func_door" or class == "func_door_rotating" or class == "prop_door_rotating" then
		-- Sprawdź czy drzwi nie są zablokowane dla Door Controller
		if ent.ignoredoorcontroller == false then
			-- Te drzwi są zablokowane - Door Controller nie może na nich działać
			return nil
		end
		mainDoor = ent
	elseif ent.IsDoor and ent:IsDoor() then
		-- Sprawdź czy custom door nie jest zablokowany dla Door Controller
		if ent.ignoredoorcontroller == false then
			return nil
		end
		mainDoor = ent
	else
		local parent = ent:GetParent()
		if IsValid(parent) then
			local parentClass = parent:GetClass():lower()
			if parentClass:find("door") or parentClass == "func_door" or parentClass == "func_door_rotating" or parentClass == "prop_door_rotating" then
				-- Sprawdź czy parent door nie jest zablokowany dla Door Controller
				if parent.ignoredoorcontroller == false then
					return nil
				end
				mainDoor = parent
			elseif parent.IsDoor and parent:IsDoor() then
				-- Sprawdź czy parent door nie jest zablokowany dla Door Controller
				if parent.ignoredoorcontroller == false then
					return nil
				end
				mainDoor = parent
			end
		end

		if not mainDoor and (ent:GetClass() == "prop_dynamic" or ent:GetClass() == "prop_physics") then
			local constraints = constraint.GetAllConstrainedEntities(ent)
			for _, constrainedEnt in pairs(constraints) do
				local class = constrainedEnt:GetClass():lower()
				if class:find("door") or constrainedEnt.IsDoor and constrainedEnt:IsDoor() then
					-- Sprawdź czy constrained door nie jest zablokowany dla Door Controller
					if constrainedEnt.ignoredoorcontroller == false then
						return nil
					end
					mainDoor = constrainedEnt
					break
				end
			end
		end
	end

	-- Jeśli znaleźliśmy główne drzwi, znajdź wszystkie części
	if mainDoor then
		return GetAllDoorParts(mainDoor)
	end

	return nil
end


local function PlayCustomAnim(wep, sequence)
	local ply = wep:GetOwner()
	local vm = ply:GetViewModel()
	if not IsValid(vm) then return end

	local seq = vm:LookupSequence(sequence)
	if not seq or seq < 0 then
	seq = vm:LookupSequence("fire") //fallback sequence lol
	if not seq or seq < 0 then return end
	end

	vm:SendViewModelMatchingSequence(seq)
	ply:SetAnimation(PLAYER_ATTACK1)

	local duration = vm:SequenceDuration(seq)
	if duration > 0 then
		timer.Simple(duration, function()
			if not IsValid(wep) or not IsValid(ply) then return end
			if ply:GetActiveWeapon() ~= wep then return end

				local idleSeq = vm:LookupSequence("idle01")
				if idleSeq and idleSeq >= 0 then
				vm:SendViewModelMatchingSequence(idleSeq)
			end
		end)
	end
end

local function PlaySound(ply, snd)
	if IsValid(ply) then ply:EmitSound(snd) end
end

function SWEP:PrimaryAttack()
if CLIENT then return end
if not self:CanUse() then return end

	self:SetSharedCooldown()
	PlayCustomAnim(self, "open")

	local ply = self:GetOwner()

	timer.Simple(0.3, function()
	if not IsValid(self) or not IsValid(ply) then return end

        local doorParts = GetDoor(ply)

	if not doorParts or #doorParts == 0 then
		PlaySound(self:GetOwner(), "echo/button_fail.mp3")
		SetViewModelSkin(ply, 5)
	return
        end

        -- Otwórz wszystkie części drzwi
        local openedCount = 0
        local totalParts = #doorParts
        local initialStates = {}
        local blockedParts = 0
        
        -- Sprawdź czy któreś części są czasowo zablokowane
        for _, door in pairs(doorParts) do
        	if IsValid(door) and door._IsTemporarilyBlocked and door._BlockedUntil and CurTime() < door._BlockedUntil then
        		blockedParts = blockedParts + 1
        	end
        end
        
        -- Jeśli wszystkie części są zablokowane, nie pozwól otworzyć
        if blockedParts == totalParts then
        	PlaySound(self:GetOwner(), "echo/button_fail.mp3")
        	SetViewModelSkin(ply, 6)
        	local remainingTime = math.ceil(doorParts[1]._BlockedUntil - CurTime())
        	return
        end
        
        -- Zapisz początkowe stany wszystkich części
        for i, door in pairs(doorParts) do
        	if IsValid(door) then
        		initialStates[i] = {
        			angles = door:GetAngles(),
        			pos = door:GetPos()
        		}
        	end
        end
        
        for _, door in pairs(doorParts) do
        	if IsValid(door) then
        		-- Sprawdź czy ta część nie jest czasowo zablokowana
        		if not (door._IsTemporarilyBlocked and door._BlockedUntil and CurTime() < door._BlockedUntil) then
        			door:Fire("Open")
        			openedCount = openedCount + 1
        		end
        	end
        end

        -- Sprawdź czy którakolwiek część się otworzyła
        timer.Simple(0.1, function()
            if not IsValid(self) then return end
            
            local anyMoved = false
            local anyUnlocked = false
            local movedCount = 0
            
            for i, door in pairs(doorParts) do
            	if IsValid(door) then
            		local doorClass = door:GetClass()
            		local fallbackOpen = doorClass:find("door") and door:GetInternalVariable("m_bLocked") == false
            		
            		if fallbackOpen then
            			anyUnlocked = true
            		end
            		
            		-- Sprawdź czy ta część się ruszyła
            		if initialStates[i] then
            			local moved = door:GetAngles() ~= initialStates[i].angles or door:GetPos() ~= initialStates[i].pos
            			if moved then
            				anyMoved = true
            				movedCount = movedCount + 1
            			end
            		end
            		
            		door._IsLocked = false
            	end
            end

            if anyMoved or anyUnlocked then
				PlaySound(self:GetOwner(), "echo/button_activate1.mp3")
				SetViewModelSkin(ply, 1)
				-- Komunikat usunięty
			else
				for _, door in pairs(doorParts) do
					if IsValid(door) then
						door._IsLocked = true
					end
				end
				PlaySound(self:GetOwner(), "echo/button_fail.mp3")
				SetViewModelSkin(ply, 6)
				-- Komunikat usunięty
			end
		end)
	end)
end

function SWEP:SecondaryAttack()
	if CLIENT then return end
	if not self:CanUse() then return end
	
	-- Sprawdź cooldown RMB i pokaż komunikat jeśli jest aktywny
	if not self:CanUseRMB() then
		local ply = self:GetOwner()
		if IsValid(ply) then
			local remainingTime = math.ceil(self.NextRMBUse - CurTime())
			ply:PrintMessage(HUD_PRINTCENTER, "Door Controller: RMB Cooldown (" .. remainingTime .. "s)")
		end
		return
	end
	
	self:SetSharedCooldown()
	self:SetRMBCooldown()

	local ply = self:GetOwner()
	PlayCustomAnim(self, "lock")

	timer.Simple(0.3, function()
	if not IsValid(self) or not IsValid(ply) then return end
	
	local doorParts = GetDoor(ply)
	if not doorParts or #doorParts == 0 then
		PlaySound(self:GetOwner(), "echo/button_fail.mp3")
		SetViewModelSkin(ply, 5)
		return
	end

	-- Sprawdź czy którekolwiek drzwi są już zablokowane
	local alreadyBlockedCount = 0
	local totalParts = #doorParts
	
	for _, door in pairs(doorParts) do
		if IsValid(door) and door._IsTemporarilyBlocked and door._BlockedUntil and CurTime() < door._BlockedUntil then
			alreadyBlockedCount = alreadyBlockedCount + 1
		end
	end
	
	-- Antyspam - jeśli wszystkie części są już zablokowane
	if alreadyBlockedCount == totalParts then
		PlaySound(self:GetOwner(), "echo/button_fail.mp3")
		SetViewModelSkin(ply, 6)
		local remainingTime = math.ceil(doorParts[1]._BlockedUntil - CurTime())
		-- Komunikat usunięty
		return
	end

	local blockTime = GetConVar("doorcontrol_block_time"):GetFloat()
	local blockedCount = 0
	
	-- Zablokuj wszystkie części drzwi
	for _, door in pairs(doorParts) do
		if IsValid(door) then
			-- Pomiń jeśli już zablokowane
			if door._IsTemporarilyBlocked and door._BlockedUntil and CurTime() < door._BlockedUntil then
				continue
			end
			
			-- Zapisz oryginalny stan
			if not door._OriginalLocked then
				door._OriginalLocked = door._IsLocked or false
			end
			
			-- Zapisz oryginalny kolor
			if not door._OriginalColor then
				door._OriginalColor = door:GetColor()
			end
			
			-- Zapisz oryginalny materiał
			if not door._OriginalMaterial then
				door._OriginalMaterial = door:GetMaterial()
			end

			-- Zapisz oryginalny skin
			if not door._OriginalSkin then
				door._OriginalSkin = door:GetSkin()
			end
			
			-- Zablokuj drzwi
			door:Fire("Lock")
			door._IsLocked = true
			door._BlockedUntil = CurTime() + blockTime
			door._IsTemporarilyBlocked = true
			
			blockedCount = blockedCount + 1
			
			-- Unikalna nazwa timera dla każdego drzwi
			local timerName = "DoorBlock_" .. door:EntIndex() .. "_" .. CurTime()
			
			-- Timer do odblokowania
			timer.Create(timerName, blockTime, 1, function()
				if IsValid(door) then
					-- Przywróć oryginalny stan blokady
					if door._OriginalLocked then
						door:Fire("Lock")
						door._IsLocked = true
					else
						door:Fire("Unlock")
						door._IsLocked = false
					end
					
					-- Usuń blokadę czasową
					door._BlockedUntil = nil
					door._IsTemporarilyBlocked = nil
					door._OriginalLocked = nil
				end
			end)
		end
	end

	-- Feedback dla gracza
	PlaySound(self:GetOwner(), "echo/button_activate3.mp3")
	SetViewModelSkin(ply, 4)
	
	-- Komunikaty usunięte
	end)
end

-- Funkcja do czyszczenia czasowych blokad
local function ClearTemporaryBlocks()
	for _, ent in pairs(ents.GetAll()) do
		if IsValid(ent) and ent._IsTemporarilyBlocked then
			-- Przywróć oryginalny stan
			if ent._OriginalLocked then
				ent:Fire("Lock")
				ent._IsLocked = true
			else
				ent:Fire("Unlock") 
				ent._IsLocked = false
			end
			
			-- Usuń blokadę czasową
			ent._BlockedUntil = nil
			ent._IsTemporarilyBlocked = nil
			ent._OriginalLocked = nil
		end
	end
end

-- Wyczyść blokady przy restarcie rundy
if SERVER then
	hook.Add("PostCleanupMap", "DoorController_ClearBlocks", ClearTemporaryBlocks)
	hook.Add("BreachPreRound", "DoorController_ClearBlocks", ClearTemporaryBlocks)
end



function SWEP:Deploy()
	local ply = self:GetOwner()
	if not IsValid(ply) then return true end
	if ply:GetActiveWeapon() ~= self then return true end

	PlayCustomAnim(self, "draw")

	local vm = ply:GetViewModel()
	if IsValid(vm) then
		vm:SetSkin(0)
	end

	self:EmitSound("echo/button_enable.mp3", 75, 100, 1, CHAN_ITEM)

	return true
end

function SWEP:Holster()
if CLIENT then return true end

local vm = self:GetOwner():GetViewModel()
	if IsValid(vm) then
	local seq = vm:LookupSequence("holster")
	if not seq or seq < 0 then
	seq = vm:LookupSequence("holster")
	end

	if seq and seq >= 0 then
	vm:SendViewModelMatchingSequence(seq)
	self:GetOwner():SetAnimation(PLAYER_IDLE)
	end
end
return true
end

-- Funkcja do wyświetlania informacji o drzwiach
function SWEP:Think()
	if CLIENT then return end
	
	local ply = self:GetOwner()
	if not IsValid(ply) then return end
	
	-- Sprawdź co jest przed graczem co sekundę
	if not self.NextDoorCheck then self.NextDoorCheck = 0 end
	if CurTime() < self.NextDoorCheck then return end
	self.NextDoorCheck = CurTime() + 0.5
	
	local doorParts = GetDoor(ply)
	if doorParts and #doorParts > 0 then
		local blockedParts = 0
		local minBlockTime = 9999
		
		-- Sprawdź ile części jest czasowo zablokowanych
		for _, door in pairs(doorParts) do
			if IsValid(door) and door._IsTemporarilyBlocked and door._BlockedUntil and CurTime() < door._BlockedUntil then
				blockedParts = blockedParts + 1
				local remainingTime = door._BlockedUntil - CurTime()
				if remainingTime < minBlockTime then
					minBlockTime = remainingTime
				end
			end
		end
		
		if blockedParts > 0 then
			local timeLeft = math.ceil(minBlockTime)
			if blockedParts == #doorParts then
				ply:PrintMessage(HUD_PRINTCENTER, "Door Controller: BLOCKED (" .. timeLeft .. "s)")
			else
				ply:PrintMessage(HUD_PRINTCENTER, "Door Controller: " .. blockedParts .. "/" .. #doorParts .. " BLOCKED (" .. timeLeft .. "s)")
			end
		elseif #doorParts > 1 then
			ply:PrintMessage(HUD_PRINTCENTER, "Door Controller: OPEN or BLOCK")
		else
			ply:PrintMessage(HUD_PRINTCENTER, "Door Controller: Ready")
		end
	else
		ply:PrintMessage(HUD_PRINTCENTER, "Door Controller: No door found")
	end
end 