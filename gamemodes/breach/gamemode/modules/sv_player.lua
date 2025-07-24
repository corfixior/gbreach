local mply = FindMetaTable( "Player" )

-- Network string dla vest HUD
util.AddNetworkString("BR_UpdateVest")

-- Network string dla NVG
util.AddNetworkString("NVG_Toggle")

-- Clear NVG when player dies
hook.Add("PlayerDeath", "ClearNVGOnDeath", function(victim, inflictor, attacker)
	if IsValid(victim) then
		victim.NVGActive = false
		net.Start("NVG_Toggle")
			net.WriteBool(false)
		net.Send(victim)
	end
end)

-- Clear NVG when player spawns
hook.Add("PlayerSpawn", "ClearNVGOnSpawn", function(ply)
	if IsValid(ply) then
		ply.NVGActive = false
		net.Start("NVG_Toggle")
			net.WriteBool(false)
		net.Send(ply)
	end
end)

function mply:PrintTranslatedMessage( string )
	net.Start( "TranslatedMessage" )
		net.WriteString( string )
		//net.WriteBool( center or false )
	net.Send( self )
end

function mply:ForceDropWeapon( class )
	if self:HasWeapon( class ) then
		local wep = self:GetWeapon( class )
		if IsValid( wep ) and IsValid( self ) then
			if self:GTeam() == TEAM_SPEC then return end
			local atype = wep:GetPrimaryAmmoType()
			if atype > 0 then
				wep.SavedAmmo = wep:Clip1()
			end	
			if wep:GetClass() == nil then return end
			if wep.droppable != nil and !wep.droppable then return end
			self:DropWeapon( wep )
			self:ConCommand( "lastinv" )
		end
	end
end

function mply:DropAllWeapons( strip )
	if GetConVar( "br_dropvestondeath" ):GetInt() != 0 then
		self:UnUseArmor()
	end
	if #self:GetWeapons() > 0 then
		local pos = self:GetPos()
		for k, v in pairs( self:GetWeapons() ) do
			local candrop = true
			if v.droppable != nil then
				if v.droppable == false then
					candrop = false
				end
			end
			if candrop then
				local class = v:GetClass()
				local wep = ents.Create( class )
				if IsValid( wep ) then
					wep:SetPos( pos )
					wep:Spawn()
					if class == "br_keycard" then
						local cardtype = v.KeycardType or v:GetNWString( "K_TYPE", "safe" )
						wep:SetKeycardType( cardtype )
					end
					local atype = v:GetPrimaryAmmoType()
					if atype > 0 then
						wep.SavedAmmo = v:Clip1()
					end
				end
			end
			if strip then
				v:Remove()
			end
		end
	end
end

// just for finding a bad spawns :p
function mply:FindClosest(tab, num)
	local allradiuses = {}
	for k,v in pairs(tab) do
		table.ForceInsert(allradiuses, {v:Distance(self:GetPos()), v})
	end
	table.sort( allradiuses, function( a, b ) return a[1] < b[1] end )
	local rtab = {}
	for i=1, num do
		if i <= #allradiuses then
			table.ForceInsert(rtab, allradiuses[i])
		end
	end
	return rtab
end

function mply:GiveRandomWep(tab)
	local mainwep = table.Random(tab)
	self:Give(mainwep)
	local getwep = self:GetWeapon(mainwep)
	if getwep.Primary == nil then
		print("ERROR: weapon: " .. mainwep)
		print(getwep)
		return
	end
	getwep:SetClip1(getwep.Primary.ClipSize)
	self:SelectWeapon(mainwep)
	self:GiveAmmo((getwep.Primary.ClipSize * 4), getwep.Primary.Ammo, false)
end

function mply:GiveNTFwep()
	self:GiveRandomWep({"cw_ump45", "cw_mp5"})
end

function mply:GiveMTFwep()
	self:GiveRandomWep({"cw_ar15", "cw_ump45", "cw_mp5"})
end

function mply:GiveCIwep()
	self:GiveRandomWep({"cw_ak74", "cw_scarh", "cw_g36c"})
end

function mply:DeleteItems()
	for k,v in pairs(ents.FindInSphere( self:GetPos(), 150 )) do
		if v:IsWeapon() then
			if !IsValid(v.Owner) then
				v:Remove()
			end
		end
	end
end

function mply:ApplyArmor(name)
	-- Security Droid nie może nosić vestów
	if self:GetNClass() == ROLES.ROLE_SECURITY_DROID then
		self:PrintMessage(HUD_PRINTTALK, "[SYSTEM] ERROR: Armor incompatible with droid chassis!")
		self:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 75, math.random(90, 110))
		return
	end
	
	-- SCP-035 system vestów
	if self:GetNClass() == ROLES.ROLE_SCP035 then
		if self.LockedArmor == true then
			-- Miał vest przed transformacją - nie może go zmienić
			self:PrintMessage(HUD_PRINTTALK, "[SCP-035] Your vest is fused with your body and cannot be changed!")
			print("[SCP-035 DEBUG] " .. self:Nick() .. " tried to change locked vest")
			return
		elseif self.LockedArmor == false then
			-- Nie miał vesta przed transformacją - nie może założyć żadnego
			self:PrintMessage(HUD_PRINTTALK, "[SCP-035] The vest phases through your corrupted body...")
			print("[SCP-035 DEBUG] " .. self:Nick() .. " tried to equip vest but had none before transformation")
			return
		else
			-- LockedArmor nie jest ustawione - gracz nie był SCP-035 od początku
			self:PrintMessage(HUD_PRINTTALK, "[SCP-035] ERROR: Invalid vest state for SCP-035!")
			print("[SCP-035 ERROR] " .. self:Nick() .. " has undefined LockedArmor state")
			return
		end
	end
	
	self.BaseStats = {
		wspeed = self:GetWalkSpeed(),
		rspeed = self:GetRunSpeed(),
		jpower = self:GetJumpPower(),
		model = self:GetModel(),
		bodygroups = {}
	}
	
	-- Zapisz obecne bodygroups
	for i = 0, 14 do
		self.BaseStats.bodygroups[i] = self:GetBodygroup(i)
	end

	local stats = 0.9
	if name == "armor_ntf" then
		self:SetModel("models/kyo/reyes_deadofnight_pm.mdl")
		stats = 0.8
	elseif name == "armor_mtfguard" then
		self:SetModel("models/scp/guard_noob.mdl")
		stats = 0.85
	elseif name == "armor_mtfcom" then
		self:SetModel("models/scp/captain.mdl")
		stats = 0.9
	elseif name == "armor_mtfl" then
		self:SetModel("models/scp/guard_left.mdl")
		stats = 0.85
	elseif name == "armor_mtfmedic" then
		self:SetModel("models/scp/guard_med.mdl")
		stats = 0.9
	elseif name == "armor_security" then
		self:SetModel("models/scp/guard_sci.mdl")
		stats = 0.92
	elseif name == "armor_fireproof" then
		self:SetModel("models/player/kerry/class_securety.mdl")
		stats = 0.9
	elseif name == "armor_chaosins" then
		self:SetModel("models/chaos_insurgency_trooper/chaos_insurgency_trooper.mdl")
		stats = 0.85
	elseif name == "armor_chaosjugg" then
		self:SetModel("models/arty/codmw2022/mp/dmz/alqatala/juggernaut/juggernaut_pm.mdl")
		-- Set bodygroups for the juggernaut armor
		for i = 0, 14 do
			self:SetBodygroup(i, 0)
		end
		stats = 0.25 -- 75% reduction in movement speed
	elseif name == "armor_hazmat" then
		self:SetModel("models/che_pm.mdl")
		stats = 0.93
	elseif name == "armor_electroproof" then
		self:SetModel("models/scp/soldier_2.mdl")
		stats = 0.8
	elseif name == "armor_csecurity" then
		self:SetModel("models/scp/soldier_1.mdl")
		stats = 0.91
	elseif name == "armor_goc" then
		self:SetModel("models/arty/codmw2022/mp/shadow company/velikan/standard/velikan_pm.mdl")
		-- Ustaw wszystkie bodygroups na 0 (z vestem/pancerzem)
		for i = 0, 14 do
			self:SetBodygroup(i, 0)
		end
		stats = 0.88
	elseif name == "armor_heavysupport" then
		self:SetModel("models/scp_mtf_russian/mtf_rus_02.mdl")
		-- Ustaw bodygroups dla Heavy Support
		timer.Simple(0.5, function()
			if IsValid(self) then
				print("[DEBUG] Heavy Support - ustawiam bodygroups dla: " .. self:Nick())
				self:SetBodygroup(0, 0) -- Vest (remove) = 0 (vest visible)
				self:SetBodygroup(1, 0) -- Vest emblem = 0 (emblem visible)
				self:SetBodygroup(2, 0) -- Group = 0
				self:SetBodygroup(3, 0) -- Headgear = 1
				self:SetBodygroup(4, 1) -- Face Protection = 0
				self:SetBodygroup(5, 0) -- Może vest? - spróbuj różne wartości 0-4
				self:SetBodygroup(6, 0) -- Może emblem? - spróbuj 0 lub 1
				self:SetBodygroup(7, 1) -- Może grupa? - spróbuj 0, 1 lub 2
				
				-- Debug - sprawdź czy bodygroups się ustawiły
				print("[DEBUG] Bodygroups po ustawieniu:")
				for i = 0, 4 do
					print("  Bodygroup " .. i .. " = " .. self:GetBodygroup(i))
				end
				print("[DEBUG] Model ma " .. self:GetNumBodyGroups() .. " bodygroups")
				for i = 0, self:GetNumBodyGroups()-1 do
					print("  Bodygroup " .. i .. " ma " .. self:GetBodygroupCount(i) .. " opcji")
				end
			end
		end)
		stats = 0.75 -- Najcięższy vest, najlepsza ochrona (25% spowolnienie)
	end
	
	self:SetWalkSpeed(self.BaseStats.wspeed * stats)
	self:SetRunSpeed(self.BaseStats.rspeed * stats)
	self:SetJumpPower(self.BaseStats.jpower * stats)
	self.UsingArmor = name
	
	-- Przywróć fat belly dla Fat D po założeniu vesta
	if self:GetNClass() == ROLES.ROLE_FAT_D then
		timer.Simple(0.2, function()
			if IsValid(self) then
				local bones = {"ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Spine2", "ValveBiped.Bip01_Pelvis"}
				for _, boneName in pairs(bones) do
					local boneID = self:LookupBone(boneName)
					if boneID then
						self:ManipulateBoneScale(boneID, Vector(1.4, 1.0, 1.6))
					end
				end
			end
		end)
	end
	
	-- Wyślij informację o kamizelce do klienta
	net.Start("BR_UpdateVest")
		net.WriteString(name)
	net.Send(self)
end

function mply:UnUseArmor()
	if self.UsingArmor == nil then return end
	
	-- SCP-035 nie może zdjąć vesta jeśli ma zablokowany
	if self:GetNClass() == ROLES.ROLE_SCP035 and self.LockedArmor then
		self:PrintMessage(HUD_PRINTTALK, "[SCP-035] Your vest is fused with your body and cannot be removed!")
		return
	end
	
	-- Sprawdź czy BaseStats istnieje
	if not self.BaseStats then return end
	
	self:SetWalkSpeed(self.BaseStats.wspeed)
	self:SetRunSpeed(self.BaseStats.rspeed)
	self:SetJumpPower(self.BaseStats.jpower)
	
	-- Jeśli to GOC lub Heavy Support, zostaw ten sam model ale zmień bodygroups na bez vesta
	if self.UsingArmor == "armor_goc" then
		self:SetModel("models/player/cheddar/goc/goc_soldier2.mdl")
		timer.Simple(0.1, function()
			if IsValid(self) and self.BaseStats then
				for i = 0, 14 do
					self:SetBodygroup(i, 1)
				end
			end
		end)
	else
		self:SetModel(self.BaseStats.model)
		-- Przywróć zapisane bodygroups dla innych
		if self.BaseStats.bodygroups then
			timer.Simple(0.1, function()
				if IsValid(self) and self.BaseStats and self.BaseStats.bodygroups then
					for group, value in pairs(self.BaseStats.bodygroups) do
						self:SetBodygroup(group, value)
					end
					
					-- Przywróć fat belly dla Fat D po zdjęciu vesta
					if self:GetNClass() == ROLES.ROLE_FAT_D then
						local bones = {"ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Spine2", "ValveBiped.Bip01_Pelvis"}
						for _, boneName in pairs(bones) do
							local boneID = self:LookupBone(boneName)
							if boneID then
								self:ManipulateBoneScale(boneID, Vector(1.4, 1.0, 1.6))
							end
						end
					end
				end
			end)
		end
	end
	
	local item = ents.Create( self.UsingArmor )
	if IsValid( item ) then
		item:Spawn()
		item:SetPos( self:GetPos() )
		self:EmitSound( Sound("npc/combine_soldier/gear".. math.random(1, 6).. ".wav") )
	end
	self.UsingArmor = nil
	
	-- Wyślij informację o zdjęciu kamizelki do klienta
	net.Start("BR_UpdateVest")
		net.WriteString("")
	net.Send(self)
end

function mply:SetSpectator()
	self:Flashlight( false )
	self:AllowFlashlight( false )
	self.handsmodel = nil
	self:Spectate( OBS_MODE_CHASE )
	self:StripWeapons()
	self:RemoveAllAmmo()
	self:SetGTeam(TEAM_SPEC)
	self:SetNoDraw(true)
	if self.SetNClass then
		self:SetNClass(ROLES.ROLE_SPEC)
	end
	self.Active = true
	print("adding " .. self:Nick() .. " to spectators")
	self.canblink = false
	self:SetNoTarget( true )
	self.BaseStats = nil
	self.UsingArmor = nil
	
	-- Clear vest info on client
	net.Start("BR_UpdateVest")
		net.WriteString("")
	net.Send(self)
	
	//self:Spectate(OBS_MODE_IN_EYE)
end

function mply:SetSCP0082( hp, speed, spawn )
	self:Flashlight( false )
	self.handsmodel = nil
	self:UnSpectate()
	self:GodDisable()
	if spawn then
		self:Spawn()
	end
	self:DropAllWeapons( true )
	self:SetModel("models/player/zombie_classic.mdl")
	self:SetGTeam(TEAM_SCP)
	self:SetHealth(hp)
	self:SetMaxHealth(hp)
	self:SetArmor(0)
	self:SetWalkSpeed(speed)
	self:SetRunSpeed(speed)
	self:SetMaxSpeed(speed)
	self:SetJumpPower(200)
	self:SetNoDraw(false)
	self:SetNClass(ROLES.ROLE_SCP0082)
	self.Active = true
	print("adding " .. self:Nick() .. " to zombies")
	self:SetupHands()
	if !spawn then
		WinCheck()
	end
	self.canblink = false
	self.noragdoll = false
	self:AllowFlashlight( false )
	self.WasTeam = TEAM_SCP
	self:SetNoTarget( true )
	net.Start("RolesSelected")
	net.Send(self)
	self:Give("weapon_br_zombie_infect")
	self:SelectWeapon("weapon_br_zombie_infect")
	self.BaseStats = nil
	self.UsingArmor = nil
	
	-- Clear vest info on client
	net.Start("BR_UpdateVest")
		net.WriteString("")
	net.Send(self)
	
	self:SetupHands()
end

function mply:SetInfectD()
	self:Flashlight( false )
	self.handsmodel = nil
	self:UnSpectate()
	self:GodDisable()
	self:Spawn()
	self:StripWeapons()
	self:RemoveAllAmmo()
	self:SetGTeam(TEAM_CLASSD)
	self:SetNClass(ROLES.ROLE_INFECTD)
	self:SetModel( table.Random( CLASSDMODELS ) )
	self:SetHealth(100)
	self:SetMaxHealth(100)
	self:SetArmor(0)
	self:SetWalkSpeed(130)
	self:SetRunSpeed(250)
	self:SetMaxSpeed(250)
	self:SetJumpPower(200)
	self:SetNoDraw(false)
	self:SetupHands()
	self.canblink = true
	self.noragdoll = false
	self:AllowFlashlight( true )
	self.WasTeam = TEAM_CLASSD
	self:SetNoTarget( false )
	self:Give("br_holster")
	self:Give("br_id")

	local card = self:Give( "br_keycard" )
	if card then
		card:SetKeycardType( "safe" )
	end
	self:SelectWeapon( "br_keycard" )

	self.BaseStats = nil
	self.UsingArmor = nil
	
	-- Clear vest info on client
	net.Start("BR_UpdateVest")
		net.WriteString("")
	net.Send(self)
end

function mply:SetInfectMTF()
	self:Flashlight( false )
	self.handsmodel = nil
	self:UnSpectate()
	self:GodDisable()
	self:Spawn()
	self:StripWeapons()
	self:RemoveAllAmmo()
	self:SetGTeam(TEAM_GUARD)
	self:SetNClass(ROLES.ROLE_INFECTMTF)
	self:SetModel( table.Random( SECURITYMODELS ) )
	self:SetHealth(150)
	self:SetMaxHealth(150)
	self:SetArmor(0)
	self:SetWalkSpeed(140)
	self:SetRunSpeed(260)
	self:SetMaxSpeed(260)
	self:SetJumpPower(215)
	self:SetNoDraw(false)
	self:SetupHands()
	self.canblink = true
	self.noragdoll = false
	self:AllowFlashlight( true )
	self.WasTeam = TEAM_GUARD
	self:SetNoTarget( false )
	self:Give("br_holster")
	self:Give("br_id")
	self:Give("cw_ar15")
	self:GiveAmmo( 60, "5.56x45MM" )

	local card = self:Give( "br_keycard" )
	if card then
		card:SetKeycardType( "euclid" )
	end
	self:SelectWeapon( "br_keycard" )

	self.BaseStats = nil
	self.UsingArmor = nil
	-- Clear previous vest first
	net.Start("BR_UpdateVest")
		net.WriteString("")
	net.Send(self)
	
	self:ApplyArmor("armor_mtfcom")
end

function mply:SetupNormal()
	self.BaseStats = nil
	self.UsingArmor = nil
	
	-- Clear vest info on client
	net.Start("BR_UpdateVest")
		net.WriteString("")
	net.Send(self)
	
	-- RESET skali modelu i manipulacji kości używanych przez specjalne klasy
	self:SetModelScale(1.0, 0)
	timer.Simple(0.05, function()
		if IsValid(self) then
			local specialBones = {
				"ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Spine2", "ValveBiped.Bip01_Pelvis",
				"ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_Head1"
			}
			for _, boneName in pairs(specialBones) do
				local boneID = self:LookupBone(boneName)
				if boneID then
					self:ManipulateBoneScale(boneID, Vector(1, 1, 1))
				end
			end
		end
	end)
	
	self.handsmodel = nil
	self:UnSpectate()
	self:Spawn()
	self:GodDisable()
	self:SetNoDraw(false)
	self:SetNoTarget(false)
	self:SetupHands()
	self:RemoveAllAmmo()
	self:StripWeapons()
	self.canblink = true
	self.noragdoll = false
	self.scp1471stacks = 1
end

function mply:SetupAdmin()
	self:Flashlight( false )
	self:AllowFlashlight( true )
	self.handsmodel = nil
	self:UnSpectate()
	//self:Spectate(6)
	self:StripWeapons()
	self:RemoveAllAmmo()
	self:SetGTeam(TEAM_SPEC)
	self:SetNoDraw(true)
	if self.SetNClass then
		self:SetNClass(ROLES.ADMIN)
	end
	self.canblink = false
	self:SetNoTarget( false )
	self.BaseStats = nil
	self.UsingArmor = nil
	
	-- Clear vest info on client
	net.Start("BR_UpdateVest")
		net.WriteString("")
	net.Send(self)
	
	self:GodEnable()
	self:SetupHands()
	self:SetWalkSpeed(400)
	self:SetRunSpeed(400)
	self:SetMaxSpeed(300)
	self:ConCommand( "noclip" )
	self:Give( "br_holster" )
	self:Give( "br_entity_remover" )
	self:Give( "br_tool_teleporter" )
	self:Give( "weapon_physgun" )
end

function mply:ApplyRoleStats( role )
	self:SetNClass( role.name )
	self:SetGTeam( role.team )
	
	for k, v in pairs( role.weapons ) do
		-- Random weapon system for Scout D
		if role.name == ROLES.ROLE_SCOUT_D then
			if v == "item_radio" and math.random(1, 100) <= 50 then
				self:Give( v )
			elseif v == "weapon_pocket_knife" and math.random(1, 100) <= 25 then
				self:Give( v )
			elseif v != "item_radio" and v != "weapon_pocket_knife" then
				self:Give( v )
			end
		-- Standard weapon system for Clearance Technician
		elseif role.name == ROLES.ROLE_CLEARANCE_TECH then
			self:Give( v )
		-- Random weapon system for Veteran D
		elseif role.name == ROLES.ROLE_VETERAN then
			if v == "weapon_piss" and math.random(1, 100) <= 25 then
				self:Give( v )
			elseif v != "weapon_piss" then
				self:Give( v )
			end
		else
			self:Give( v )
		end
	end
	if role.keycard and role.keycard != "" then
		local card = self:Give( "br_keycard" )
		if IsValid(card) then
			card:SetKeycardType( role.keycard )
			self:SelectWeapon( "br_keycard" )
		end
	end

	for k, v in pairs( role.ammo ) do
		for _, wep in pairs( self:GetWeapons() ) do
			if v[1] == wep:GetClass() then
				local max_clip = wep:GetMaxClip1()
				local new_clip = math.min( v[2], max_clip )
				local reserve = v[2] - new_clip

				wep:SetClip1( new_clip )

				if reserve > 0 then
					self:GiveAmmo( reserve, wep:GetPrimaryAmmoType() )
				end

				break
			end
		end
	end

	self:SetHealth(role.health)
	self:SetMaxHealth(role.health)
	self:SetWalkSpeed(100 * role.walkspeed)
	self:SetRunSpeed(210 * role.runspeed)
	self:SetJumpPower(190 * role.jumppower)
	self:SetModel( table.Random(role.models) )
	self:Flashlight( false )
	self:AllowFlashlight( role.flashlight )
	
	-- RESET skali modelu i manipulacji kości używanych przez specjalne klasy przed zastosowaniem nowych
	self:SetModelScale(1.0, 0)
	
	local specialBones = {
		"ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Spine2", "ValveBiped.Bip01_Pelvis",
		"ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_Head1"
	}
	for _, boneName in pairs(specialBones) do
		local boneID = self:LookupBone(boneName)
		if boneID then
			self:ManipulateBoneScale(boneID, Vector(1, 1, 1))
		end
	end
	
	-- Fat belly system dla Fat D
	if role.fatbelly then
		timer.Simple(0.1, function()
			if IsValid(self) then
				-- Powiększ kości brzucha/tułowia
				local bones = {"ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Spine2", "ValveBiped.Bip01_Pelvis"}
				for _, boneName in pairs(bones) do
					local boneID = self:LookupBone(boneName)
					if boneID then
						-- Powiększ X (szerokość) i Z (głębokość) brzucha
						self:ManipulateBoneScale(boneID, Vector(1.4, 1.0, 1.6))
					end
				end
			end
		end)
	end
	
	-- Skinny body system dla Skinny D
	if role.skinnybody then
		timer.Simple(0.1, function()
			if IsValid(self) then
				-- Zmniejsz kości tułowia/ramion dla chudego efektu
				local bones = {"ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Spine2", "ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_Pelvis"}
				for _, boneName in pairs(bones) do
					local boneID = self:LookupBone(boneName)
					if boneID then
						-- Zmniejsz X (szerokość) i Z (głębokość) dla chudego efektu
						self:ManipulateBoneScale(boneID, Vector(0.7, 1.0, 0.8))
					end
				end
			end
		end)
	end
	

	
	-- SCP-527 bodygroups system
	if role.name == ROLES.ROLE_SCP527 then
		timer.Simple(0.1, function()
			if IsValid(self) then
				-- Ustaw bodygroups dla SCP-527
				local hatGroup = self:FindBodygroupByName("Hat")
				local clothesGroup = self:FindBodygroupByName("Clothes")
				
				if hatGroup != -1 then
					self:SetBodygroup(hatGroup, 1)
				end
				
				if clothesGroup != -1 then
					self:SetBodygroup(clothesGroup, 1)
				end
			end
		end)
	end
	
	-- General bodygroups system
	if role.bodygroups then
		timer.Simple(0.1, function()
			if IsValid(self) then
				for _, bg in pairs(role.bodygroups) do
					local groupID = bg[1]
					local value = bg[2]
					self:SetBodygroup(groupID, value)
				end
			end
		end)
	end
	
	-- Random bodygroups system
	if role.bodygroups_random then
		timer.Simple(0.1, function()
			if IsValid(self) then
				for _, bg in pairs(role.bodygroups_random) do
					local groupID = bg[1]
					local range = bg[2]
					local randomValue = math.random(range[1], range[2])
					self:SetBodygroup(groupID, randomValue)
				end
			end
		end)
	end
	if role.vest != nil then
		self:ApplyArmor(role.vest)
	end
	if role.pmcolor != nil then
		self:SetPlayerColor(Vector(role.pmcolor.r / 255, role.pmcolor.g / 255, role.pmcolor.b / 255))
	end
	net.Start("RolesSelected")
	net.Send(self)
	self:SetupHands()
end

function mply:SetSecurityI1()
	local thebestone = nil
	local usechaos = false
	if math.random(1,6) == 6 then usechaos = true end
	for k,v in pairs(ALLCLASSES["security"]["roles"]) do
		if v.importancelevel == 1 then
			local skip = false
			if usechaos == true then
				if v.team == TEAM_GUARD then
					skip = true
				end
			else
				if v.team == TEAM_CHAOS then
					skip = true
				end
			end
			if skip == false then
				local can = true
				if v.customcheck != nil then
					if v.customcheck(self) == false then
						can = false
					end
				end
				local using = 0
				for _,pl in pairs(player.GetAll()) do
					if pl:GetNClass() == v.name then
						using = using + 1
					end
				end
				if using >= v.max then can = false end
				if can == true then
					if self:GetLevel() >= v.level then
						if thebestone != nil then
							if thebestone.sorting < v.sorting then
								thebestone = v
							end
						else
							thebestone = v
						end
					end
				end
			end
		end
	end
	if thebestone == nil then
		thebestone = ALLCLASSES["security"]["roles"][1]
	end
	self:SetupNormal()
	self:ApplyRoleStats(thebestone)
end

function mply:SetClassD()
	self:SetRoleBestFrom("classds")
end

function mply:SetResearcher()
	self:SetRoleBestFrom("researchers")
end

function mply:SetRoleBestFrom(role)
	local thebestone = nil
	for k,v in pairs(ALLCLASSES[role]["roles"]) do
		local can = true
		if v.customcheck != nil then
			if v.customcheck(self) == false then
				can = false
			end
		end
		local using = 0
		for _,pl in pairs(player.GetAll()) do
			if pl:GetNClass() == v.name then
				using = using + 1
			end
		end
		if using >= v.max then can = false end
		if can == true then
			if self:GetLevel() >= v.level then
				if thebestone != nil then
					if thebestone.level < v.level then
						thebestone = v
					end
				else
					thebestone = v
				end
			end
		end
	end
	if thebestone == nil then
		thebestone = ALLCLASSES[role]["roles"][1]
	end
	if thebestone == ALLCLASSES["classds"]["roles"][4] and #player.GetAll() < 4 then
		thebestone = ALLCLASSES["classds"]["roles"][3]
	end
	if ( GetConVar("br_dclass_keycards"):GetInt() != 0 ) then
		if thebestone == ALLCLASSES["classds"]["roles"][1] then thebestone = ALLCLASSES["classds"]["roles"][2] end
	else
		if thebestone == ALLCLASSES["classds"]["roles"][2] then thebestone = ALLCLASSES["classds"]["roles"][1] end
	end
	self:SetupNormal()
	self:ApplyRoleStats(thebestone)
end

function mply:IsActivePlayer()
	return self.Active
end

hook.Add( "KeyPress", "keypress_spectating", function( ply, key )
	if ply:GTeam() != TEAM_SPEC or ply:GetNClass() == ROLES.ADMIN then return end
	if ( key == IN_ATTACK ) then
		ply:SpectatePlayerLeft()
	elseif ( key == IN_ATTACK2 ) then
		ply:SpectatePlayerRight()
	elseif ( key == IN_RELOAD ) then
		ply:ChangeSpecMode()
	end
end )

function mply:SpectatePlayerRight()
	if !self:Alive() then return end
	if self:GetObserverMode() != OBS_MODE_IN_EYE and
	   self:GetObserverMode() != OBS_MODE_CHASE 
	then return end
	self:SetNoDraw(true)
	local allply = GetAlivePlayers()
	if #allply == 1 then return end
	if not self.SpecPly then
		self.SpecPly = 0
	end
	self.SpecPly = self.SpecPly - 1
	if self.SpecPly < 1 then
		self.SpecPly = #allply 
	end
	for k,v in pairs(allply) do
		if k == self.SpecPly then
			self:SpectateEntity( v )
		end
	end
end

function mply:SpectatePlayerLeft()
	if !self:Alive() then return end
	if self:GetObserverMode() != OBS_MODE_IN_EYE and
	   self:GetObserverMode() != OBS_MODE_CHASE 
	then return end
	self:SetNoDraw(true)
	local allply = GetAlivePlayers()
	if #allply == 1 then return end
	if not self.SpecPly then
		self.SpecPly = 0
	end
	self.SpecPly = self.SpecPly + 1
	if self.SpecPly > #allply then
		self.SpecPly = 1
	end
	for k,v in pairs(allply) do
		if k == self.SpecPly then
			self:SpectateEntity( v )
		end
	end
end

function mply:ChangeSpecMode()
	if !self:Alive() then return end
	if !(self:GTeam() == TEAM_SPEC) then return end
	self:SetNoDraw(true)
	local m = self:GetObserverMode()
	local allply = #GetAlivePlayers()
	if allply < 2 then
		self:Spectate(OBS_MODE_ROAMING)
		return
	end
	/*
	if m == OBS_MODE_CHASE then
		self:Spectate(OBS_MODE_IN_EYE)
	else
		self:Spectate(OBS_MODE_CHASE)
	end
	*/
	
	if m == OBS_MODE_IN_EYE then
		self:Spectate(OBS_MODE_CHASE)	
	elseif m == OBS_MODE_CHASE then
		if GetConVar( "br_allow_roaming_spectate" ):GetInt() == 1 then
			self:Spectate(OBS_MODE_ROAMING)
		elseif GetConVar( "br_allow_ineye_spectate" ):GetInt() == 1 then
			self:Spectate(OBS_MODE_IN_EYE)
			self:SpectatePlayerLeft()
		else
			self:SpectatePlayerLeft()
		end	
	elseif m == OBS_MODE_ROAMING then
		if GetConVar( "br_allow_ineye_spectate" ):GetInt() == 1 then
			self:Spectate(OBS_MODE_IN_EYE)
			self:SpectatePlayerLeft()
		else
			self:Spectate(OBS_MODE_CHASE)
			self:SpectatePlayerLeft()
		end
	else
		self:Spectate(OBS_MODE_ROAMING)
	end
end

function mply:SaveExp()
	self:SetPData( "breach_exp", self:GetExp() )
end

function mply:SaveLevel()
	self:SetPData( "breach_level", self:GetLevel() )
end

function mply:AddExp(amount, msg)
	amount = amount * GetConVar("br_expscale"):GetInt()
	if self.Premium == true then
		amount = amount * GetConVar("br_premium_mult"):GetFloat()
	end
	amount = math.Round(amount)
	if not self.GetNEXP then
		player_manager.RunClass( self, "SetupDataTables" )
	end
	if self.GetNEXP and self.SetNEXP then
		self:SetNEXP( self:GetNEXP() + amount )
		local xp = self:GetNEXP()
		local lvl = self:GetNLevel()
		if lvl == 0 then
			if xp >= 3000 then
				self:AddLevel(1)
				self:SetNEXP(xp - 3000)
				self:SaveLevel()
				PrintMessage(HUD_PRINTTALK, self:Nick() .. " reached level 1! Congratulations!")
			end
		elseif lvl == 1 then
			if xp >= 5000 then
				self:AddLevel(1)
				self:SetNEXP(xp - 5000)
				self:SaveLevel()
				PrintMessage(HUD_PRINTTALK, self:Nick() .. " reached level 2! Congratulations!")
			end
		elseif lvl == 2 then
			if xp >= 7500 then
				self:AddLevel(1)
				self:SetNEXP(xp - 7500)
				self:SaveLevel()
				PrintMessage(HUD_PRINTTALK, self:Nick() .. " reached level 3! Congratulations!")
			end
		elseif lvl == 3 then
			if xp >= 11000 then
				self:AddLevel(1)
				self:SetNEXP(xp - 11000)
				self:SaveLevel()
				PrintMessage(HUD_PRINTTALK, self:Nick() .. " reached level 4! Congratulations!")
			end
		elseif lvl == 4 then
			if xp >= 14000 then
				self:AddLevel(1)
				self:SetNEXP(xp - 14000)
				self:SaveLevel()
				PrintMessage(HUD_PRINTTALK, self:Nick() .. " reached level 5! Congratulations!")
			end
		elseif lvl == 5 then
			if xp >= 25000 then
				self:AddLevel(1)
				self:SetNEXP(xp - 25000)
				self:SaveLevel()
				PrintMessage(HUD_PRINTTALK, self:Nick() .. " reached level OMNI! Congratulations!")
			end
		elseif lvl == 6 then
			if xp >= 100000 then
				self:AddLevel(1)
				self:SetNEXP(xp - 100000)
				self:SaveLevel()
				PrintMessage(HUD_PRINTTALK, self:Nick() .. " is a now a Veteran! Congratulations!")
			end
		elseif lvl > 6 then
			if xp >= 100000 then
				self:AddLevel(1)
				self:SetNEXP(xp - 100000)
				self:SaveLevel()
				PrintMessage(HUD_PRINTTALK, self:Nick() .. " reached level "..lvl.."! Congratulations!")
			end
		end
		self:SetPData( "breach_exp", self:GetExp() )
	else
		if self.SetNEXP then
			self:SetNEXP( 0 )
		else
			ErrorNoHalt( "Cannot set the exp, SetNEXP invalid" )
		end
	end
end

function mply:AddLevel(amount)
	if not self.GetNLevel then
		player_manager.RunClass( self, "SetupDataTables" )
	end
	if self.GetNLevel and self.SetNLevel then
		self:SetNLevel( self:GetNLevel() + amount )
		self:SetPData( "breach_level", self:GetNLevel() )
	else
		if self.SetNLevel then
			self:SetNLevel( 0 )
		else
			ErrorNoHalt( "Cannot set the exp, SetNLevel invalid" )
		end
	end
end

function mply:SetRoleName(name)
	local rl = nil
	for k,v in pairs(ALLCLASSES) do
		for _,role in pairs(v.roles) do
			if role.name == name then
				rl = role
			end
		end
	end
	if rl != nil then
		self:SetupNormal()
		self:ApplyRoleStats(rl)
	end
end

function mply:SetActive( active )
	self.ActivePlayer = active
	self:SetNActive( active )
	if !gamestarted then
		CheckStart()
	end
end

function mply:ToggleAdminModePref()
	if self.admpref == nil then self.admpref = false end
	if self.admpref then
		self.admpref = false
		if self.AdminMode then
			self:ToggleAdminMode()
			self:SetSpectator()
		end
	else
		self.admpref = true
		if self:GetNClass() == ROLES.ROLE_SPEC then
			self:ToggleAdminMode()
			self:SetupAdmin()
		end
	end
end

function mply:ToggleAdminMode()
	if self.AdminMode == nil then self.AdminMode = false end
	if self.AdminMode == true then
		self.AdminMode = false
		self:SetActive( true )
		self:DrawWorldModel( true ) 
	else
		self.AdminMode = true
		self:SetActive( false )
		self:DrawWorldModel( false )
	end
end

-- Synchronizacja kamizelki przy spawnie
hook.Add("PlayerSpawn", "BR_SyncVestOnSpawn", function(ply)
	-- Reset Security Droid variables
	ply.SecurityDroidStunHits = 0
	ply.SecurityDroidOverheated = false
	ply.SecurityDroidOriginalSpeeds = nil
	
	-- Usuń timer przegrzania jeśli istnieje
	timer.Remove("SecurityDroid_Overheat_" .. ply:EntIndex())
	
	-- Reset wszystkich manipulacji kości i bodygroups przy spawnie
	timer.Simple(0.1, function()
		if IsValid(ply) then
			-- Reset kości
			ply:SetModelScale(1.0, 0)
			for i = 0, ply:GetBoneCount() - 1 do
				ply:ManipulateBoneScale(i, Vector(1, 1, 1))
			end
			
			-- Reset bodygroups
			for i = 0, ply:GetNumBodyGroups() - 1 do
				ply:SetBodygroup(i, 0)
			end
			
			-- Reset przezroczystości (jeśli nie ma ochrony wsparcia)
			if not (ply.SupportSpawnProtection and CurTime() < ply.SupportSpawnProtection) then
				ply:SetColor(Color(255, 255, 255, 255))
				ply:SetRenderMode(RENDERMODE_NORMAL)
			end
		end
	end)
	
	timer.Simple(0.5, function()
		if IsValid(ply) and ply.UsingArmor then
			net.Start("BR_UpdateVest")
				net.WriteString(ply.UsingArmor)
			net.Send(ply)
		end
	end)
end)

-- Synchronizacja przy dołączeniu do serwera
hook.Add("PlayerInitialSpawn", "BR_SyncVestOnJoin", function(ply)
	timer.Simple(2, function()
		if IsValid(ply) and ply.UsingArmor then
			net.Start("BR_UpdateVest")
				net.WriteString(ply.UsingArmor)
			net.Send(ply)
		end
	end)
end)



-- D-CLASS INFECTED PASSIVE ABILITY
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
						if InfectedProximity[steamID] % 5 == 0 then
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

-- PSYCHOLOGIST PASSIVE ABILITIES
-- Network strings
util.AddNetworkString("Psychologist_AddFootstep")

-- Passive 1: Therapeutic Presence - Healing Aura
-- Use a timer instead of Think hook for precise 1-second intervals
timer.Create("Psychologist_TherapeuticPresence", 1, 0, function()
	for _, psychologist in pairs(player.GetAll()) do
		if IsValid(psychologist) and psychologist:Alive() and psychologist:GetNClass() == ROLES.ROLE_PSYCHOLOGIST then
			local nearbyPlayers = ents.FindInSphere(psychologist:GetPos(), 125) -- 125 unit radius (half of original)
			
			for _, ply in pairs(nearbyPlayers) do
				if IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply != psychologist then
					-- Check if player is from supported teams/roles
					local team = ply:GTeam()
					local class = ply:GetNClass()
					
					-- Heal: Scientists, MTF, and CI Spy only (not all Chaos)
					if team == TEAM_SCI or team == TEAM_GUARD or (team == TEAM_CHAOS and class == ROLES.ROLE_CHAOSSPY) then
						-- Check if player needs healing (below 50 HP)
						local currentHP = ply:Health()
						if currentHP < 50 and currentHP > 0 then
							-- Heal +1 HP (but don't exceed 50 HP)
							ply:SetHealth(math.min(currentHP + 1, 50))
						end
					end
				end
			end
		end
	end
end)

-- Passive 2: Psychological Insight - Footstep tracking for players in crisis
hook.Add("PlayerFootstep", "Psychologist_FootstepTracking", function(ply, pos, foot, sound, volume, rf)
	-- Only track footsteps from players with <30% HP (psychological crisis)
	if not ply:IsPlayer() or not ply:Alive() then return end
	
	local maxHP = ply:GetMaxHealth()
	local currentHP = ply:Health()
	
	-- Check if player is in crisis (<30% HP)
	if currentHP < (maxHP * 0.3) then
		-- Determine team identifier for footstep traces
		local teamIdentifier = ply:GTeam()
		
		-- CI Spy should be marked as ally (green), not enemy (red)
		if ply:GetNClass() == ROLES.ROLE_CHAOSSPY then
			teamIdentifier = 99 -- Special number for CI Spy (ally)
		end
		
		-- Send footstep data to all psychologists
		for _, psychologist in pairs(player.GetAll()) do
			if IsValid(psychologist) and psychologist:Alive() and psychologist:GetNClass() == ROLES.ROLE_PSYCHOLOGIST then
				net.Start("Psychologist_AddFootstep")
					net.WriteVector(pos)
					net.WriteInt(teamIdentifier, 8)
					net.WriteFloat(CurTime())
				net.Send(psychologist)
			end
		end
	end
end)

-- THIEF D PASSIVE ABILITY
-- Weapon Theft - steal active weapon from other players
hook.Add("PlayerUse", "ThiefD_WeaponTheft", function(ply, ent)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if not IsValid(ent) or not ent:IsPlayer() then return end
	if preparing or postround then return end
	
	-- Only Thief D can steal
	if ply:GetNClass() != ROLES.ROLE_THIEF_D then return end
	
	-- Check cooldown (60 seconds)
	if ply.ThiefNextSteal and ply.ThiefNextSteal > CurTime() then
		local timeLeft = math.ceil(ply.ThiefNextSteal - CurTime())
		ply:PrintMessage(HUD_PRINTCENTER, "Theft on cooldown: " .. timeLeft .. "s")
		return false
	end
	
	-- Cannot steal from SCPs
	if ent:GTeam() == TEAM_SCP then 
		return false
	end
	
	-- Cannot steal from yourself
	if ply == ent then return end
	
	-- Check distance (shorter range for theft - 50 units instead of default ~85)
	local distance = ply:GetPos():Distance(ent:GetPos())
	if distance > 50 then
		return false
	end
	
	-- Get target's active weapon
	local targetWeapon = ent:GetActiveWeapon()
	if not IsValid(targetWeapon) then 
		return false
	end
	
	local weaponClass = targetWeapon:GetClass()
	
	-- Blocked weapons: holster and br_tag (security tags)
	if weaponClass == "br_holster" or weaponClass == "br_tag" then
		return false
	end
	
	-- Check if thief already has this weapon
	if ply:HasWeapon(weaponClass) then
		return false
	end
	
	-- Get weapon info before removal
	local weaponAmmo = 0
	local ammoType = targetWeapon:GetPrimaryAmmoType()
	if ammoType and ammoType != -1 then
		weaponAmmo = ent:GetAmmoCount(ammoType)
	end
	
	-- Special handling for keycards - preserve access level
	local keycardType = nil
	if weaponClass == "br_keycard" then
		keycardType = targetWeapon:GetNWString("K_TYPE", "safe")
	end
	
	-- Remove weapon from target
	ent:StripWeapon(weaponClass)
	
	-- Give weapon to thief
	local newWeapon = ply:Give(weaponClass)
	if IsValid(newWeapon) then
		-- Set keycard type if it's a keycard
		if weaponClass == "br_keycard" and keycardType then
			newWeapon:SetKeycardType(keycardType)
		end
		
		-- Give ammo if applicable
		if ammoType and ammoType != -1 and weaponAmmo > 0 then
			ply:GiveAmmo(weaponAmmo, ammoType)
		end
	end
	
	-- Switch to stolen weapon
	ply:SelectWeapon(weaponClass)
	
	-- Set cooldown (60 seconds)
	ply.ThiefNextSteal = CurTime() + 60
	
	-- Visual effects
	ply:ScreenFade(SCREENFADE.IN, Color(255, 255, 0, 20), 0.3, 0)
	ent:ScreenFade(SCREENFADE.IN, Color(255, 0, 0, 30), 0.5, 0)
	
	-- Sound effects
	ply:EmitSound("buttons/button14.wav", 50, 120)
	ent:EmitSound("buttons/button10.wav", 50, 80)
	
	return false -- Prevent normal USE interaction
end)

-- Reset Thief cooldown on spawn
hook.Add("PlayerSpawn", "ThiefD_ResetCooldown", function(ply)
	if IsValid(ply) then
		ply.ThiefNextSteal = nil
	end
end)

-- DR. HOUSE PASSIVE ABILITY
-- Death Harvest - gains 10 HP when someone nearby dies
hook.Add("PostPlayerDeath", "DrHouse_DeathHarvest", function(victim, inflictor, attacker)
	if not IsValid(victim) or not victim:IsPlayer() then return end
	if preparing or postround then return end
	
	-- Find all Dr. House players nearby the death location
	for _, drhouse in pairs(player.GetAll()) do
		if IsValid(drhouse) and drhouse:Alive() and drhouse:GetNClass() == ROLES.ROLE_DRHOUSE then
			local distance = drhouse:GetPos():Distance(victim:GetPos())
			
			-- Check if Dr. House is within 300 units of the death
			if distance <= 300 then
				-- Heal Dr. House by 10 HP (but don't exceed max health)
				local currentHP = drhouse:Health()
				local maxHP = drhouse:GetMaxHealth()
				local newHP = math.min(currentHP + 10, maxHP)
				
				drhouse:SetHealth(newHP)
				
				-- Send notification to Dr. House
				drhouse:PrintMessage(HUD_PRINTTALK, "[DR. HOUSE] Death nearby healed you for " .. (newHP - currentHP) .. " HP!")
				
				-- Visual effect for healing
				drhouse:ScreenFade(SCREENFADE.IN, Color(0, 255, 0, 30), 0.5, 0)
			end
		end
	end
end)