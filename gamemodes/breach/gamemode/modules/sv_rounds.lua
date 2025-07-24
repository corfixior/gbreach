ROUNDS = {
	normal = {
		name = "Containment Breach",
		setup = function()
			MAPBUTTONS = table.Copy(BUTTONS)
			SetupPlayers( GetRoleTable( #GetActivePlayers() ) )
			disableNTF = false
			SpawnAllItems()
			-- Usunięto OpenSCPDoors() z setup - przeniesiono do roundstart
			timer.Create( "NTFEnterTime", GetNTFEnterTime(), 1, function()
				-- Losowanie z właściwymi proporcjami: NTF 50%, GOC 10%, Chaos 40%
				local rand = math.random(1, 100)
				if rand <= 50 then
					-- 50% szans dla NTF
					SpawnNTFS()
				elseif rand <= 60 then
					-- 10% szans dla GOC (51-60)
					SpawnGOC()
				else
					-- 40% szans dla Chaos (61-100)
					SpawnNTFS(true) -- Wymusza spawn Chaos
				end
			end )
			timer.Create("MTFDebug", 2, 1, function()
				local fent = ents.FindInSphere(MTF_DEBUG, 750)
				for k, v in pairs( player.GetAll() ) do
					if v:GTeam() == TEAM_GUARD or v:GetNClass() == ROLE_CHAOSSPY then
						local found = false
						for k0, v0 in pairs(fent) do
							if v == v0 then
								found = true
								break
							end
						end
						if !found then
							v:SetPos(MTF_DEBUG)
						end
					end
				end
			end )
		end,
		init = function()
		end,
		roundstart = function()
			-- Przeniesiono OpenSCPDoors() tutaj - drzwi otworzą się dopiero po rozpoczęciu rundy
			OpenSCPDoors()
		end,
		postround = function()
			local plys = GetActivePlayers()
			for k, v in pairs( plys ) do
				local r = tonumber( v:GetPData( "scp_penalty", 0 ) ) - 1
				r = math.max( r, 0 )

				if r == 0 then
					v:PrintTranslatedMessage( "scpready#50,200,50" )
					//print( v, "can be scp" )
				else
					v:PrintTranslatedMessage( "scpwait".."$"..r.."#200,50,50" )
					//dprint( v, "must wait", r )
				end
			end
		end,
		endcheck = function()
			if #GetActivePlayers() < 2 then return end
			endround = false
			local ds = gteams.NumPlayers(TEAM_CLASSD)
			local mtfs = gteams.NumPlayers(TEAM_GUARD)
			local res = gteams.NumPlayers(TEAM_SCI)
			local scps = gteams.NumPlayers(TEAM_SCP)
			local chaos = gteams.NumPlayers(TEAM_CHAOS)
			local goc = gteams.NumPlayers(TEAM_GOC)
			local all = #GetAlivePlayers()
			why = "idk man"
			if scps == all then
				endround = true
				why = "there are only scps"
			elseif mtfs == all then
				endround = true
				why = "there are only mtfs"
			elseif res == all then
				endround = true
				why = "there are only researchers"
			elseif ds == all then
				endround = true
				why = "there are only class ds"
			elseif chaos == all then
				endround = true
				why = "there are only chaos insurgency members"
			elseif goc == all then
				endround = true
				why = "there are only goc members"
			elseif (mtfs + res) == all then
				endround = true
				why = "there are only mtfs and researchers"
			elseif (chaos + ds) == all then
				endround = true
				why = "there are only chaos insurgency members and class ds"
			end
		end,
	},
/*	dm = {
		name = "MTF vs CI Deathmatch",
		setup = function()
			MAPBUTTONS = GetTableOverride( table.Copy(BUTTONS) ) + GetTableOverride( table.Copy(BUTTONS_DM) )
			SetupPlayers( GetRoleTableCustom( #GetActivePlayers(),  ) )
			
			disableNTF = false
		end,
		init = function()
			SpawnAllItems()
			DestroyGateA()
		end,
		roundstart = function()
			OpenSCPDoors()
		end,
		postround = function() end,
		cleanup = function() end,
	},*/
/*	omega = {
		name = "Omega Problem",
		setup = function()
			MAPBUTTONS = GetTableOverride( table.Copy(BUTTONS) ) + GetTableOverride( table.Copy(BUTTONS_OMEGA) )
			SetupPlayers( GetRoleTable( #GetActivePlayers() ) )
			disableNTF = false
		end,
		init = function()
			SpawnAllItems()
			timer.Create( "NTFEnterTime", GetNTFEnterTime(), 0, function()
				SpawnNTFS()
			end )
		end,
		roundstart = function()
			OpenSCPDoors()
		end,
		postround = function() end,
		cleanup = function() end,
	}, */
	multi = {
		name = "Multi Breach",
		setup = function()
			MAPBUTTONS = table.Copy(BUTTONS)
			SetupPlayers( GetRoleTable( #GetActivePlayers() ), true )
			disableNTF = false
		end,
		init = function()
			SpawnAllItems()
			timer.Create( "NTFEnterTime", GetNTFEnterTime(), 1, function()
				-- Losowanie z właściwymi proporcjami: NTF 50%, GOC 10%, Chaos 40%
				local rand = math.random(1, 100)
				if rand <= 50 then
					-- 50% szans dla NTF
					SpawnNTFS()
				elseif rand <= 60 then
					-- 10% szans dla GOC (51-60)
					SpawnGOC()
				else
					-- 40% szans dla Chaos (61-100)
					SpawnNTFS(true) -- Wymusza spawn Chaos
				end
			end )
			timer.Create("MTFDebug", 2, 1, function()
				local fent = ents.FindInSphere(MTF_DEBUG, 750)
				for k, v in pairs( player.GetAll() ) do
					if v:GTeam() == TEAM_GUARD or v:GetNClass() == ROLE_CHAOSSPY then
						local found = false
						for k0, v0 in pairs(fent) do
							if v == v0 then
								found = true
								break
							end
						end
						if !found then
							v:SetPos(MTF_DEBUG)
						end
					end
				end
			end )	
		end,
		roundstart = function()
			OpenSCPDoors()
		end,
		postround = function()
			local plys = GetActivePlayers()
			for k, v in pairs( plys ) do
				local r = tonumber( v:GetPData( "scp_penalty", 0 ) ) - 1
				r = math.max( r, 0 )

				if r == 0 then
					v:PrintTranslatedMessage( "scpready#50,200,50" )
					//print( v, "can be scp" )
				else
					v:PrintTranslatedMessage( "scpwait".."$"..r.."#200,50,50" )
					//dprint( v, "must wait", r )
				end
			end
		end,
		endcheck = function()
			if #GetActivePlayers() < 2 then return end
			endround = false
			local ds = gteams.NumPlayers(TEAM_CLASSD)
			local mtfs = gteams.NumPlayers(TEAM_GUARD)
			local res = gteams.NumPlayers(TEAM_SCI)
			local scps = gteams.NumPlayers(TEAM_SCP)
			local chaos = gteams.NumPlayers(TEAM_CHAOS)
			local goc = gteams.NumPlayers(TEAM_GOC)
			local all = #GetAlivePlayers()
			why = "idk man"
			if scps == all then
				endround = true
				why = "there are only scps"
			elseif mtfs == all then
				endround = true
				why = "there are only mtfs"
			elseif res == all then
				endround = true
				why = "there are only researchers"
			elseif ds == all then
				endround = true
				why = "there are only class ds"
			elseif chaos == all then
				endround = true
				why = "there are only chaos insurgency members"
			elseif goc == all then
				endround = true
				why = "there are only goc members"
			elseif (mtfs + res) == all then
				endround = true
				why = "there are only mtfs and researchers"
			elseif (chaos + ds) == all then
				endround = true
				why = "there are only chaos insurgency members and class ds"
			end
		end,
	},
	ttt = {
		name = "TTT",
		setup = function()
			MAPBUTTONS = table.Copy(BUTTONS)
			
			-- Custom TTT player setup
			local players = GetActivePlayers()
			local total = #players
			
			-- Calculate roles: 25% spies, 75% MTF Guards
			local spyCount = math.max(1, math.floor(total * 0.25))
			local mtfCount = total - spyCount
			
			-- Shuffle players
			local shuffledPlayers = {}
			for k, v in pairs(players) do
				table.insert(shuffledPlayers, v)
			end
			
			-- Assign spies (Chaos Spy)
			local spyspawns = table.Copy(SPAWN_GUARD)
			for i = 1, spyCount do
				if #shuffledPlayers > 0 then
					local ply = table.remove(shuffledPlayers, math.random(#shuffledPlayers))
					
					-- Set as Chaos Spy (disguised as MTF)
					ply:SetupNormal()
					ply:SetGTeam(TEAM_CHAOS)
					ply:SetNClass(ROLES.ROLE_CHAOSSPY)
					ply:SetModel(table.Random(SECURITYMODELS))
					ply:SetHealth(100)
					ply:SetMaxHealth(100)
					ply:SetWalkSpeed(111.25) -- 0.85 * 130
					ply:SetRunSpeed(230) -- 0.92 * 250
					ply:SetJumpPower(174) -- 0.87 * 200
					
					-- Give weapons and items
					ply:Give("br_holster")
					ply:Give("br_id")
					ply:Give("item_radio")
					ply:Give("weapon_stunstick")
					ply:Give("cw_mp5")
					
					-- Give keycard
					local card = ply:Give("br_keycard")
					if IsValid(card) then
						card:SetKeycardType("mtf")
					end
					
					-- Apply armor
					ply:ApplyArmor("armor_mtfguard")
					
					-- Set spawn position
					if #spyspawns == 0 then spyspawns = table.Copy(SPAWN_GUARD) end
					local spawn = table.remove(spyspawns, math.random(#spyspawns))
					ply:SetPos(spawn)
					
					print("Assigning " .. ply:Nick() .. " to role: SPY [TTT]")
				end
			end
			
			-- Assign MTF Guards
			local mtfspawns = table.Copy(SPAWN_GUARD)
			for i = 1, mtfCount do
				if #shuffledPlayers > 0 then
					local ply = table.remove(shuffledPlayers, math.random(#shuffledPlayers))
					
					-- Set as MTF Guard
					ply:SetupNormal()
					ply:SetGTeam(TEAM_GUARD)
					ply:SetNClass(ROLES.ROLE_MTFGUARD)
					ply:SetModel(table.Random(SECURITYMODELS))
					ply:SetHealth(100)
					ply:SetMaxHealth(100)
					ply:SetWalkSpeed(111.25) -- 0.85 * 130
					ply:SetRunSpeed(230) -- 0.92 * 250
					ply:SetJumpPower(174) -- 0.87 * 200
					
					-- Give weapons and items
					ply:Give("br_holster")
					ply:Give("br_id")
					ply:Give("item_radio")
					ply:Give("weapon_stunstick")
					ply:Give("cw_mp5")
					
					-- Give keycard
					local card = ply:Give("br_keycard")
					if IsValid(card) then
						card:SetKeycardType("mtf")
					end
					
					-- Apply armor
					ply:ApplyArmor("armor_mtfguard")
					
					-- Set spawn position
					if #mtfspawns == 0 then mtfspawns = table.Copy(SPAWN_GUARD) end
					local spawn = table.remove(mtfspawns, math.random(#mtfspawns))
					ply:SetPos(spawn)
					
					print("Assigning " .. ply:Nick() .. " to role: MTF GUARD [TTT]")
				end
			end
			
			disableNTF = true -- Disable NTF spawning for TTT round
		end,
		init = function()
			-- Spawn limited items for TTT gameplay
			SpawnAllItems()
		end,
		roundstart = function()
			-- Don't open SCP doors in TTT round
			-- OpenSCPDoors()
		end,
		postround = function()
			-- Standard postround handling
		end,
		endcheck = function()
			if #GetActivePlayers() < 2 then return end
			endround = false
			local spies = 0
			local mtfs = 0
			
			-- Count alive players by role
			for k, v in pairs(GetAlivePlayers()) do
				if v:GetNClass() == ROLES.ROLE_CHAOSSPY then
					spies = spies + 1
				elseif v:GetNClass() == ROLES.ROLE_MTFGUARD then
					mtfs = mtfs + 1
				end
			end
			
			local all = #GetAlivePlayers()
			why = "idk man"
			
			if spies == all then
				endround = true
				why = "all spies survived"
			elseif mtfs == all then
				endround = true
				why = "all mtf guards survived"
			elseif spies == 0 then
				endround = true
				why = "all spies eliminated"
			elseif mtfs == 0 then
				endround = true
				why = "all mtf guards eliminated"
			end
		end,
	},
	bomber = {
		name = "Bomber",
		setup = function()
			MAPBUTTONS = table.Copy(BUTTONS)
			SetupPlayers( GetRoleTable( #GetActivePlayers() ) )
			disableNTF = false
		end,
		init = function()
			SpawnAllItems()
			timer.Create( "NTFEnterTime", GetNTFEnterTime(), 1, function()
				-- Standard NTF spawning
				local rand = math.random(1, 100)
				if rand <= 50 then
					SpawnNTFS()
				elseif rand <= 60 then
					SpawnGOC()
				else
					SpawnNTFS(true)
				end
			end )
			timer.Create("MTFDebug", 2, 1, function()
				local fent = ents.FindInSphere(MTF_DEBUG, 750)
				for k, v in pairs( player.GetAll() ) do
					if v:GTeam() == TEAM_GUARD or v:GetNClass() == ROLES.ROLE_CHAOSSPY then
						local found = false
						for k0, v0 in pairs(fent) do
							if v == v0 then
								found = true
								break
							end
						end
						if !found then
							v:SetPos(MTF_DEBUG)
						end
					end
				end
			end )
		end,
		roundstart = function()
			OpenSCPDoors()
			
			-- OPTYMALIZACJA: Bomber timer z cache graczy
BomberRoundActive = true
local BomberNextExplosion = CurTime() + 60

local function OptimizedBomberTick()
	if not BomberRoundActive then return end

	local currentTime = CurTime()
	if currentTime < BomberNextExplosion then
		return
	end

	-- Użyj cache graczy jeśli dostępny
	local alivePlayers = GetAlivePlayers()
	if #alivePlayers > 0 then
		-- Choose the player who will explode NOW, not later
		local chosenPlayer = table.Random(alivePlayers)

		-- Send lottery animation to all players WITH the chosen player
		net.Start("BomberLottery")
			net.WriteTable(alivePlayers)
			net.WriteEntity(chosenPlayer) -- Send who was chosen
		net.Broadcast()

		-- Wait 5 seconds for animation + 6 seconds countdown, then explode the chosen player
		timer.Simple(11, function()
			if IsValid(chosenPlayer) and chosenPlayer:Alive() then
				-- Create explosion effect
				local explosionPos = chosenPlayer:GetPos()

				-- Kill the player with explosion damage
				local dmg = DamageInfo()
				dmg:SetDamage(999)
				dmg:SetDamageType(DMG_BLAST)
				dmg:SetAttacker(chosenPlayer)
				dmg:SetInflictor(chosenPlayer)
				chosenPlayer:TakeDamageInfo(dmg)
				
				-- Create explosion effects
				local effectdata = EffectData()
				effectdata:SetOrigin(explosionPos)
				effectdata:SetMagnitude(8)
				effectdata:SetScale(1)
				effectdata:SetRadius(8)
				util.Effect("Explosion", effectdata)

				-- OPTYMALIZACJA: Użyj zoptymalizowanej funkcji wyszukiwania
				local nearbyPlayers = {}
				for k, v in pairs(ents.FindInSphere(explosionPos, 200)) do
					if v:IsPlayer() and v != chosenPlayer and v:Alive() then
						table.insert(nearbyPlayers, v)
					end
				end

				-- Damage nearby players
				for _, v in pairs(nearbyPlayers) do
					local distance = v:GetPos():Distance(explosionPos)
					local damage = math.max(10, 100 - (distance / 2))

					local dmgInfo = DamageInfo()
					dmgInfo:SetDamage(damage)
					dmgInfo:SetDamageType(DMG_BLAST)
					dmgInfo:SetAttacker(chosenPlayer)
					dmgInfo:SetInflictor(chosenPlayer)
					v:TakeDamageInfo(dmgInfo)
				end

				-- Sound effect
				chosenPlayer:EmitSound("weapons/explode3.wav", 100, 100)

				-- Notify all players (użyj cache jeśli dostępny)
				local allPlayers = PlayerCache and PlayerCache.All or player.GetAll()
				for k, v in pairs(allPlayers) do
					if IsValid(v) then
						v:PrintMessage(HUD_PRINTTALK, chosenPlayer:Nick() .. " exploded!")
					end
				end
			end
		end)
	end

	BomberNextExplosion = currentTime + 60 -- Następna eksplozja za minutę
	timer.Adjust("BomberTimer", 1, 0, OptimizedBomberTick) -- Kontynuuj sprawdzanie
end

timer.Create("BomberTimer", 1, 0, OptimizedBomberTick) -- Rozpocznij bomber system
		end,
		postround = function()
			-- OPTYMALIZACJA: Clean up bomber system
			BomberRoundActive = false
			timer.Remove("BomberTimer")
			print("[OPTIMIZATION] Bomber round cleanup completed")
		end,
		endcheck = function()
			if #GetActivePlayers() < 2 then return end
			endround = false
			local ds = gteams.NumPlayers(TEAM_CLASSD)
			local mtfs = gteams.NumPlayers(TEAM_GUARD)
			local res = gteams.NumPlayers(TEAM_SCI)
			local scps = gteams.NumPlayers(TEAM_SCP)
			local chaos = gteams.NumPlayers(TEAM_CHAOS)
			local goc = gteams.NumPlayers(TEAM_GOC)
			local all = #GetAlivePlayers()
			why = "idk man"
			if scps == all then
				endround = true
				why = "there are only scps"
			elseif mtfs == all then
				endround = true
				why = "there are only mtfs"
			elseif res == all then
				endround = true
				why = "there are only researchers"
			elseif ds == all then
				endround = true
				why = "there are only class ds"
			elseif chaos == all then
				endround = true
				why = "there are only chaos insurgency members"
			elseif goc == all then
				endround = true
				why = "there are only goc members"
			elseif (mtfs + res) == all then
				endround = true
				why = "there are only mtfs and researchers"
			elseif (chaos + ds) == all then
				endround = true
				why = "there are only chaos insurgency members and class ds"
			end
		end,
	},
	swapper = {
		name = "Swapper",
		setup = function()
			MAPBUTTONS = table.Copy(BUTTONS)
			SetupPlayers( GetRoleTable( #GetActivePlayers() ) )
			disableNTF = false
		end,
		init = function()
			SpawnAllItems()
			timer.Create( "NTFEnterTime", GetNTFEnterTime(), 1, function()
				-- Standard NTF spawning
				local rand = math.random(1, 100)
				if rand <= 50 then
					SpawnNTFS()
				elseif rand <= 60 then
					SpawnGOC()
				else
					SpawnNTFS(true)
				end
			end )
			timer.Create("MTFDebug", 2, 1, function()
				local fent = ents.FindInSphere(MTF_DEBUG, 750)
				for k, v in pairs( player.GetAll() ) do
					if v:GTeam() == TEAM_GUARD or v:GetNClass() == ROLES.ROLE_CHAOSSPY then
						local found = false
						for k0, v0 in pairs(fent) do
							if v == v0 then
								found = true
								break
							end
						end
						if !found then
							v:SetPos(MTF_DEBUG)
						end
					end
				end
			end )
		end,
		roundstart = function()
			OpenSCPDoors()
			
			-- OPTYMALIZACJA: Swapper timer z cache graczy
SwapperRoundActive = true
local SwapperNextSwap = CurTime() + 30

local function OptimizedSwapperTick()
	if not SwapperRoundActive then return end

	local currentTime = CurTime()
	if currentTime < SwapperNextSwap then
		return
	end

	local alivePlayers = GetAlivePlayers()
	if #alivePlayers >= 2 then
		-- Create notification about upcoming swap (użyj cache)
		local allPlayers = PlayerCache and PlayerCache.All or player.GetAll()
		for k, v in pairs(allPlayers) do
			if IsValid(v) then
				v:PrintMessage(HUD_PRINTTALK, "Position swap in 5 seconds!")
				v:EmitSound("buttons/blip1.wav", 60, 150)
			end
		end
		
		-- Wait 5 seconds, then swap
		timer.Simple(5, function()
			local currentAlivePlayers = GetAlivePlayers()
			if #currentAlivePlayers >= 2 then
				-- Store original positions and angles
				local positions = {}
				local angles = {}

				for k, v in pairs(currentAlivePlayers) do
					positions[k] = v:GetPos()
					angles[k] = v:GetAngles()
				end

				-- Shuffle players (zoptymalizowane)
				local shuffledPlayers = table.Copy(currentAlivePlayers)
				table.Shuffle(shuffledPlayers)

				-- Apply swapped positions (batch processing)
				for k, v in pairs(currentAlivePlayers) do
					if IsValid(v) and v:Alive() then
						local targetIndex = (k % #positions) + 1
						if positions[targetIndex] and angles[targetIndex] then
							-- Rozłóż teleportacje w czasie
							timer.Simple(k * 0.05, function()
								if IsValid(v) then
									v:SetPos(positions[targetIndex] + Vector(0, 0, 5))
									v:SetAngles(angles[targetIndex])
									v:SetVelocity(Vector(0, 0, 0))
								end
							end)
						end
					end
				end

				-- Notification and effects (użyj cache)
				local allPlayers = PlayerCache and PlayerCache.All or player.GetAll()
				for k, v in pairs(allPlayers) do
					if IsValid(v) then
						v:PrintMessage(HUD_PRINTTALK, "Positions swapped!")
						v:EmitSound("ambient/levels/labs/electric_explosion1.wav", 70, 120)
					end
					
					-- Screen flash effect
					if v:Alive() then
						v:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 100), 0.5, 0.1)
					end
				end

				-- Visual effects at swap locations (batch processing)
				for k, pos in pairs(positions) do
					timer.Simple(k * 0.02, function() -- Rozłóż efekty w czasie
						local effectdata = EffectData()
						effectdata:SetOrigin(pos)
						effectdata:SetMagnitude(1)
						effectdata:SetScale(0.5)
						util.Effect("TeslaHitboxes", effectdata)
					end)
				end
			end
		end)
	end

	SwapperNextSwap = currentTime + 30 -- Następny swap za 30 sekund
	timer.Adjust("SwapperTimer", 1, 0, OptimizedSwapperTick) -- Kontynuuj sprawdzanie
end

timer.Create("SwapperTimer", 1, 0, OptimizedSwapperTick) -- Rozpocznij swapper system
		end,
		postround = function()
			-- OPTYMALIZACJA: Clean up swapper system
			SwapperRoundActive = false
			timer.Remove("SwapperTimer")
			print("[OPTIMIZATION] Swapper round cleanup completed")
		end,
		endcheck = function()
			if #GetActivePlayers() < 2 then return end
			endround = false
			local ds = gteams.NumPlayers(TEAM_CLASSD)
			local mtfs = gteams.NumPlayers(TEAM_GUARD)
			local res = gteams.NumPlayers(TEAM_SCI)
			local scps = gteams.NumPlayers(TEAM_SCP)
			local chaos = gteams.NumPlayers(TEAM_CHAOS)
			local goc = gteams.NumPlayers(TEAM_GOC)
			local all = #GetAlivePlayers()
			why = "idk man"
			if scps == all then
				endround = true
				why = "there are only scps"
			elseif mtfs == all then
				endround = true
				why = "there are only mtfs"
			elseif res == all then
				endround = true
				why = "there are only researchers"
			elseif ds == all then
				endround = true
				why = "there are only class ds"
			elseif chaos == all then
				endround = true
				why = "there are only chaos insurgency members"
			elseif goc == all then
				endround = true
				why = "there are only goc members"
			elseif (mtfs + res) == all then
				endround = true
				why = "there are only mtfs and researchers"
			elseif (chaos + ds) == all then
				endround = true
				why = "there are only chaos insurgency members and class ds"
			end
		end,
	},
	moveordie = {
		name = "Move or Die",
		setup = function()
			MAPBUTTONS = table.Copy(BUTTONS)
			SetupPlayers( GetRoleTable( #GetActivePlayers() ) )
			disableNTF = false
		end,
		init = function()
			SpawnAllItems()
			timer.Create( "NTFEnterTime", GetNTFEnterTime(), 1, function()
				-- Standard NTF spawning
				local rand = math.random(1, 100)
				if rand <= 50 then
					SpawnNTFS()
				elseif rand <= 60 then
					SpawnGOC()
				else
					SpawnNTFS(true)
				end
			end )
			timer.Create("MTFDebug", 2, 1, function()
				local fent = ents.FindInSphere(MTF_DEBUG, 750)
				for k, v in pairs( player.GetAll() ) do
					if v:GTeam() == TEAM_GUARD or v:GetNClass() == ROLES.ROLE_CHAOSSPY then
						local found = false
						for k0, v0 in pairs(fent) do
							if v == v0 then
								found = true
								break
							end
						end
						if !found then
							v:SetPos(MTF_DEBUG)
						end
					end
				end
			end )
		end,
		roundstart = function()
			OpenSCPDoors()
			
			-- Initialize movement tracking for all players
			if not MOVEORDIE_DATA then
				MOVEORDIE_DATA = {}
			end
			
			for k, v in pairs(GetAlivePlayers()) do
				if IsValid(v) then
					MOVEORDIE_DATA[v:SteamID()] = {
						lastPos = v:GetPos(),
						lastMoveTime = CurTime(),
						lastDamageTime = 0
					}
				end
			end
			
			-- Start movement checking timer - check every 0.1 seconds for responsive movement detection
			timer.Create("MoveOrDieCheck", 0.1, 0, function()
				local currentTime = CurTime()
				
				for k, v in pairs(GetAlivePlayers()) do
					if IsValid(v) and v:Alive() then
						local steamid = v:SteamID()
						
						-- Initialize data if player doesn't have it
						if not MOVEORDIE_DATA[steamid] then
							MOVEORDIE_DATA[steamid] = {
								lastPos = v:GetPos(),
								lastMoveTime = currentTime,
								lastDamageTime = 0
							}
						end
						
						local data = MOVEORDIE_DATA[steamid]
						local currentPos = v:GetPos()
						
						-- Check if player moved (minimum 2 unit distance for more responsive detection)
						local distance = currentPos:Distance(data.lastPos)
						if distance > 2 then
							-- Player moved, update position and time
							data.lastPos = currentPos
							data.lastMoveTime = currentTime
						else
							-- Player hasn't moved, check if damage should be applied
							local timeSinceMove = currentTime - data.lastMoveTime
							local timeSinceLastDamage = currentTime - data.lastDamageTime
							
							-- Apply damage if not moving for more than 1 second and haven't damaged in last second
							if timeSinceMove >= 1 and timeSinceLastDamage >= 1 then
								-- Take 2 HP damage
								local newHealth = math.max(0, v:Health() - 2)
								v:SetHealth(newHealth)
								data.lastDamageTime = currentTime
								
								-- Visual and audio feedback
								v:EmitSound("player/pl_pain" .. math.random(5, 7) .. ".wav", 60, 100)
								
								-- Screen effect
								v:ScreenFade(SCREENFADE.IN, Color(255, 0, 0, 50), 0.3, 0.1)
								
								-- Kill player if health reaches 0
								if newHealth <= 0 then
									v:Kill()
									for _, ply in pairs(player.GetAll()) do
										ply:PrintMessage(HUD_PRINTTALK, v:Nick() .. " died from standing still!")
									end
								end
							end
						end
					end
				end
			end)
			

		end,
		postround = function()
			-- Clean up movement tracking
			timer.Remove("MoveOrDieCheck")
			MOVEORDIE_DATA = nil
		end,
		endcheck = function()
			if #GetActivePlayers() < 2 then return end
			endround = false
			local ds = gteams.NumPlayers(TEAM_CLASSD)
			local mtfs = gteams.NumPlayers(TEAM_GUARD)
			local res = gteams.NumPlayers(TEAM_SCI)
			local scps = gteams.NumPlayers(TEAM_SCP)
			local chaos = gteams.NumPlayers(TEAM_CHAOS)
			local goc = gteams.NumPlayers(TEAM_GOC)
			local all = #GetAlivePlayers()
			why = "idk man"
			if scps == all then
				endround = true
				why = "there are only scps"
			elseif mtfs == all then
				endround = true
				why = "there are only mtfs"
			elseif res == all then
				endround = true
				why = "there are only researchers"
			elseif ds == all then
				endround = true
				why = "there are only class ds"
			elseif chaos == all then
				endround = true
				why = "there are only chaos insurgency members"
			elseif goc == all then
				endround = true
				why = "there are only goc members"
			elseif (mtfs + res) == all then
				endround = true
				why = "there are only mtfs and researchers"
			elseif (chaos + ds) == all then
				endround = true
				why = "there are only chaos insurgency members and class ds"
			end
		end,
	},

}