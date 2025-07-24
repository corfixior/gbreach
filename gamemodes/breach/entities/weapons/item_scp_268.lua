AddCSLuaFile()

SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.ViewModel = ""
SWEP.WorldModel = "models/thenextscp/scp268/berret.mdl"
SWEP.PrintName = "SCP-268"
SWEP.Slot = 3
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.HoldType = "normal"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.droppable = true
SWEP.teams = {2,3,5,6,7} -- Wszystkie zespoły poza SCPs

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"
SWEP.Primary.Automatic = false

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = false

-- Zmienne SCP-268
SWEP.IsInvisible = false
SWEP.InvisibilityTime = 0
SWEP.CooldownTime = 0
SWEP.MaxInvisibilityTime = 60 -- 60 sekund max niewidzialności
SWEP.CooldownDuration = 30 -- 30 sekund cooldown

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
	if not IsFirstTimePredicted() then return end
	
	-- Sprawdź czy gracz może używać SCP-268
	if self.Owner:GTeam() == TEAM_SCP or self.Owner:GTeam() == TEAM_SPEC then
		if SERVER then
			self.Owner:PrintMessage(HUD_PRINTTALK, "SCP entities cannot use SCP-268!")
			timer.Simple(0.1, function()
				if IsValid(self.Owner) then
					self.Owner:StripWeapon("item_scp_268")
				end
			end)
		end
		return
	end
	
	self.Owner:DrawViewModel(false)

	if SERVER then
		-- Pobierz ewentualny trwający cooldown zapisany na graczu
		self.CooldownTime = self.Owner:GetNWFloat("SCP268_Cooldown", 0)
		-- Upewnij się, że broń zna aktualny stan niewidzialności gracza (powinien być FALSE po rzuceniu)
		self.IsInvisible = self.Owner:GetNWBool("SCP268_Invisible", false)
		-- Synchronizuj z klientem – to odświeży HUD na nowo wybranym egzemplarzu
		self:SyncToClient()
	end
	
	return true
end

function SWEP:Holster()
	if not IsFirstTimePredicted() then return end
	
	-- Wyłącz niewidzialność gdy chowamy broń
	if SERVER and self.IsInvisible then
		self:SetInvisibility(false)
		self:StartCooldown()
	end
	
	return true
end

function SWEP:OnRemove()
	if SERVER and IsValid(self.Owner) then
		-- Wyłącz niewidzialność
		self:SetInvisibility(false)
		
		-- Wyczyść timery
		timer.Remove("SCP268_Invisibility_" .. self.Owner:SteamID64())
		timer.Remove("SCP268_Death_" .. self.Owner:SteamID64())
		
		-- Wyczyść network vars
		self.Owner:SetNWBool("SCP268_Invisible", false)
		self.Owner:SetNWFloat("SCP268_InvisTime", 0)
		self.Owner:SetNWFloat("SCP268_Cooldown", 0)
	end
end

function SWEP:PrimaryAttack()
	if not IsFirstTimePredicted() then return end
	if preparing or postround then return end
	
	-- Sprawdź cooldown
	if self.CooldownTime > CurTime() then
		if CLIENT then
			local timeLeft = math.ceil(self.CooldownTime - CurTime())
			LocalPlayer():PrintMessage(HUD_PRINTCENTER, "SCP-268 on cooldown: " .. timeLeft .. "s")
		end
		return
	end
	
	-- Toggle niewidzialności
	self:ToggleInvisibility()
end

function SWEP:SecondaryAttack()
	-- Brak secondary attack
end

function SWEP:ToggleInvisibility()
	if SERVER then
		if self.IsInvisible then
			-- Wyłącz niewidzialność
			self:SetInvisibility(false)
			self:StartCooldown()
		else
			-- Włącz niewidzialność
			self:SetInvisibility(true)
			self:StartInvisibilityTimer()
		end
	end
end

if SERVER then
	function SWEP:SetInvisibility(invisible)
		if not IsValid(self.Owner) then return end
		
		self.IsInvisible = invisible
		
		if invisible then
			-- Włącz niewidzialność
			self.InvisibilityTime = CurTime()
			self.Owner:PrintMessage(HUD_PRINTTALK, "SCP-268 ACTIVATED - You are now invisible!")
			
			-- Efekt wizualny - zrób gracza przezroczystego
			self.Owner:SetColor(Color(255, 255, 255, 0))
			self.Owner:SetRenderMode(RENDERMODE_TRANSALPHA)
			
			-- Ukryj wszystkie bronie (włącznie z SCP-268)
			for _, wep in pairs(self.Owner:GetWeapons()) do
				if IsValid(wep) then
					wep:SetColor(Color(255, 255, 255, 0))
					wep:SetRenderMode(RENDERMODE_TRANSALPHA)
				end
			end
			
		else
			-- Wyłącz niewidzialność
			self.Owner:PrintMessage(HUD_PRINTTALK, "SCP-268 DEACTIVATED - You are visible again!")
			
			-- Przywróć normalną widoczność
			self.Owner:SetColor(Color(255, 255, 255, 255))
			self.Owner:SetRenderMode(RENDERMODE_NORMAL)
			
			-- Pokaż broń
			for _, wep in pairs(self.Owner:GetWeapons()) do
				if IsValid(wep) then
					wep:SetColor(Color(255, 255, 255, 255))
					wep:SetRenderMode(RENDERMODE_NORMAL)
				end
			end
			
			-- Usuń timer śmierci
			timer.Remove("SCP268_Death_" .. self.Owner:SteamID64())
		end
		
		-- Sync z klientem
		self:SyncToClient()
	end
	
	function SWEP:StartInvisibilityTimer()
		if not IsValid(self.Owner) then return end
		
		-- Timer śmierci po 60 sekundach
		timer.Create("SCP268_Death_" .. self.Owner:SteamID64(), self.MaxInvisibilityTime, 1, function()
			if IsValid(self.Owner) and self.IsInvisible then
				-- Zabij gracza po 60s niewidzialności
				self.Owner:PrintMessage(HUD_PRINTTALK, "SCP-268 overload! The berret's anomalous properties have overwhelmed your mind!")
				
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(self.Owner:Health() + 100)
				dmginfo:SetDamageType(DMG_DIRECT)
				dmginfo:SetAttacker(self.Owner)
				dmginfo:SetInflictor(self)
				
				self.Owner:TakeDamageInfo(dmginfo)
			end
		end)
	end
	
	function SWEP:StartCooldown()
		self.CooldownTime = CurTime() + self.CooldownDuration
		self:SyncToClient()
	end
	
	function SWEP:SyncToClient()
		if not IsValid(self.Owner) then return end
		
		self.Owner:SetNWBool("SCP268_Invisible", self.IsInvisible)
		self.Owner:SetNWFloat("SCP268_InvisTime", self.InvisibilityTime)
		self.Owner:SetNWFloat("SCP268_Cooldown", self.CooldownTime)
	end
end

function SWEP:Think()
	if not IsFirstTimePredicted() then return end
	
	-- Sync z serwerem
	if CLIENT then
		self.IsInvisible = self.Owner:GetNWBool("SCP268_Invisible", false)
		self.InvisibilityTime = self.Owner:GetNWFloat("SCP268_InvisTime", 0)
		self.CooldownTime = self.Owner:GetNWFloat("SCP268_Cooldown", 0)
	end
	
	-- Sprawdź czy gracz nadal trzyma berret
	if SERVER and self.IsInvisible then
		local activeWep = self.Owner:GetActiveWeapon()
		if not IsValid(activeWep) or activeWep ~= self then
			-- Gracz przestał trzymać berret - wyłącz niewidzialność
			self:SetInvisibility(false)
			self:StartCooldown()
		end
	end
end

function SWEP:DrawWorldModel()
	if not IsValid(self.Owner) then
		self:DrawModel()
	else
		-- Nie rysuj world model gdy gracz jest niewidzialny
		local isInvisible = self.Owner:GetNWBool("SCP268_Invisible", false)
		if not isInvisible then
			self:DrawModel()
		end
	end
end

-- Font dla HUD
if CLIENT then
	surface.CreateFont("SCP268_Small", {
		font = "Trebuchet24", 
		size = 18,
		weight = 500,
		antialias = true,
		shadow = true
	})
end

-- HUD dla SCP-268 (w stylu SCP-714/SCP-1499)
function SWEP:DrawHUD()
	if disablehud == true then return end
	
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	-- Pozycja HUD prosto nad celownikiem (jak w SCP-1499)
	local x = ScrW() / 2
	local y = ScrH() / 2 - 50 -- 50 pikseli nad środkiem ekranu
	
	local isInvisible = ply:GetNWBool("SCP268_Invisible", false)
	local invisTime = ply:GetNWFloat("SCP268_InvisTime", 0)
	local cooldownTime = ply:GetNWFloat("SCP268_Cooldown", 0)
	
	-- Pasek postępu - ustawienia (jak w SCP-1499)
	local barWidth = 100
	local barHeight = 4
	
	-- Jeśli jest niewidzialny
	if isInvisible then
		local timeActive = CurTime() - invisTime
		local timeLeft = math.max(0, self.MaxInvisibilityTime - timeActive)
		
		-- Tekst
		local timeText = string.format("INVISIBLE: %.1fs", timeLeft)
		local color = Color(100, 255, 100)
		
		-- Zmień kolor na ostrzeżenie gdy zostało mało czasu
		if timeLeft <= 10 then
			color = Color(255, 100, 100)
		elseif timeLeft <= 20 then
			color = Color(255, 255, 100)
		end
		
		draw.SimpleText(timeText, "SCP268_Small", x, y - 20, color, TEXT_ALIGN_CENTER)
		
		-- Pasek postępu
		local progress = timeLeft / self.MaxInvisibilityTime
		progress = math.max(0, math.min(1, progress))
		
		-- Tło paska
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(x - barWidth/2, y, barWidth, barHeight)
		
		-- Wypełnienie paska
		surface.SetDrawColor(color.r, color.g, color.b, 255)
		surface.DrawRect(x - barWidth/2, y, barWidth * progress, barHeight)
		
	-- Jeśli jest cooldown
	elseif cooldownTime > CurTime() then
		local timeLeft = cooldownTime - CurTime()
		
		-- Tekst
		draw.SimpleText("CD: " .. math.ceil(timeLeft) .. "s", "SCP268_Small", x, y - 20, Color(255, 100, 100), TEXT_ALIGN_CENTER)
		
		-- Pasek postępu
		local progress = 1 - (timeLeft / self.CooldownDuration)
		
		-- Tło paska
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(x - barWidth/2, y, barWidth, barHeight)
		
		-- Wypełnienie paska
		surface.SetDrawColor(255, 100, 100, 255)
		surface.DrawRect(x - barWidth/2, y, barWidth * progress, barHeight)
		
	else
		-- Gotowy do użycia
		draw.SimpleText("READY", "SCP268_Small", x, y - 20, Color(100, 255, 100), TEXT_ALIGN_CENTER)
		
		-- Pasek pełny
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(x - barWidth/2, y, barWidth, barHeight)
		
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(x - barWidth/2, y, barWidth, barHeight)
	end
end

-- Hook dla działania w tle (globalny status) + szary efekt niewidzialności
if CLIENT then
	hook.Add("HUDPaint", "SCP268_GlobalStatus", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		
		-- Szary efekt na ekranie gdy niewidzialny
		local isInvisible = ply:GetNWBool("SCP268_Invisible", false)
		if isInvisible then
			-- Rysuj szary overlay na całym ekranie
			surface.SetDrawColor(128, 128, 128, 80) -- Szary z przezroczystością
			surface.DrawRect(0, 0, ScrW(), ScrH())
		end
		
		-- Sprawdź czy ma SCP-268 ale nie trzyma go aktualnie
		if ply:HasWeapon("item_scp_268") then
			local currentWep = ply:GetActiveWeapon()
			if not IsValid(currentWep) or currentWep:GetClass() ~= "item_scp_268" then
				-- Ma SCP-268 ale nie trzyma go - pokaż status (w stylu SCP-714)
				local cooldownTime = ply:GetNWFloat("SCP268_Cooldown", 0)
				
				if isInvisible then
					-- Pokaż ostrzeżenie że jest niewidzialny ale nie trzyma berreta
					local x = ScrW() / 2
					local y = 30
					
					local warningText = "WARNING: SCP-268 effect ending - take berret to maintain invisibility!"
					draw.SimpleText(warningText, "SCP268_Small", x, y, Color(255, 100, 100), TEXT_ALIGN_CENTER)
				elseif cooldownTime > CurTime() then
					-- Pokaż cooldown (w stylu SCP-714)
					local x = ScrW() / 2
					local y = 30
					
					local timeLeft = math.ceil(cooldownTime - CurTime())
					local text = "SCP-268: " .. timeLeft .. "s [COOLDOWN]"
					draw.SimpleText(text, "SCP268_Small", x, y, Color(255, 150, 150), TEXT_ALIGN_CENTER)
					
					-- Pasek postępu
					local barWidth = 100
					local barHeight = 4
					local progress = 1 - (timeLeft / 30)
					
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
	
	-- Hook do ukrywania TargetID podczas niewidzialności
	hook.Add("HUDShouldDraw", "SCP268_HideTargetID", function(name)
		if name == "CHudTargetID" then
			local ply = LocalPlayer()
			if IsValid(ply) and ply:GetNWBool("SCP268_Invisible", false) then
				return false -- Ukryj TargetID gdy niewidzialny
			end
		end
	end)
end

-- Hook serwerowy dla czyszczenia po śmierci gracza
if SERVER then
	hook.Add("PlayerDeath", "SCP268_CleanupOnDeath", function(victim, inflictor, attacker)
		if IsValid(victim) and victim:HasWeapon("item_scp_268") then
			-- Wyłącz niewidzialność
			victim:SetColor(Color(255, 255, 255, 255))
			victim:SetRenderMode(RENDERMODE_NORMAL)
			
			-- Wyczyść network variables
			victim:SetNWBool("SCP268_Invisible", false)
			victim:SetNWFloat("SCP268_InvisTime", 0)
			victim:SetNWFloat("SCP268_Cooldown", 0)
			
			-- Usuń timery
			timer.Remove("SCP268_Death_" .. victim:SteamID64())
		end
	end)
	
	-- Hook dla disconnectu gracza
	hook.Add("PlayerDisconnected", "SCP268_CleanupOnDisconnect", function(ply)
		if IsValid(ply) then
			timer.Remove("SCP268_Death_" .. ply:SteamID64())
		end
	end)
	
	function SWEP:OnDrop()
		-- Pozostaw pustą – faktyczne wyłączenie niewidzialności obsługujemy w hooku PlayerDroppedWeapon
	end

	-- Gwarancja wyłączenia niewidzialności i włączenia cooldownu przy wyrzuceniu beretu
	hook.Add("PlayerDroppedWeapon", "SCP268_HandleDrop", function(ply, wep)
		if not IsValid(ply) or not IsValid(wep) then return end

		if wep:GetClass() ~= "item_scp_268" then return end

		if ply:GetNWBool("SCP268_Invisible", false) then
			-- Wyłącz niewidzialność wizualnie
			ply:SetColor(Color(255, 255, 255, 255))
			ply:SetRenderMode(RENDERMODE_NORMAL)

			for _, w in pairs(ply:GetWeapons()) do
				if IsValid(w) then
					w:SetColor(Color(255, 255, 255, 255))
					w:SetRenderMode(RENDERMODE_NORMAL)
				end
			end

			-- Aktualizuj network vars
			ply:SetNWBool("SCP268_Invisible", false)

			local cdEnd = CurTime() + (wep.CooldownDuration or 30)
			ply:SetNWFloat("SCP268_Cooldown", cdEnd)

			-- Usuń timer śmierci
			timer.Remove("SCP268_Death_" .. ply:SteamID64())

			-- Poinformuj gracza
			ply:PrintMessage(HUD_PRINTTALK, "SCP-268 dropped - invisibility effect ended! (Cooldown engaged)")
		end
	end)
end 