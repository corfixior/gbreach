AddCSLuaFile()

SWEP.Base 			= "weapon_scp_base"
SWEP.PrintName		= "SCP-957"

SWEP.Primary.Delay 	= 8

SWEP.DrawCrosshair	= true
SWEP.HoldType 		= "normal"

-- Nowe zmienne dla slowa
SWEP.Secondary.Delay = 90 -- Cooldown dla slowa
SWEP.SlowRange = 500 -- Zasięg slowa
SWEP.SlowDuration = 2 -- Czas trwania slowa w sekundach
SWEP.SlowAmount = 0.1 -- 90% slow = 10% prędkości

function SWEP:SetupDataTables()
	self:NetworkVar( "Entity", 0, "SCPInstance" )
	-- Nowe zmienne sieciowe dla slowa
	self:NetworkVar("Float", 1, "NextSecondaryFire")
	-- Zmienna dla wyboru podczas preparing
	self:NetworkVar("Bool", 1, "CanSelect")
	-- Zmienna dla wybranego gracza (przed przemianą)
	self:NetworkVar("Entity", 1, "PendingServant")
	-- Zmienna dla drugiego wybranego gracza (backup)
	self:NetworkVar("Entity", 2, "BackupServant")
	-- Flaga dla timera przemiany
	self:NetworkVar("Bool", 2, "TransformationScheduled")
end

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_957" )

	self:SetHoldType(self.HoldType)
	
	-- Inicjalizacja zmiennych slowa
	self:SetNextSecondaryFire(0)
	-- Ustaw możliwość wyboru podczas preparing
	self:SetCanSelect(preparing or false)
	-- Wyczyść wybranych graczy
	self:SetPendingServant(NULL)
	self:SetBackupServant(NULL)
	-- Inicjalizacja flagi dla automatycznego wyboru
	self.CanSelectPrevious = false
end

function SWEP:Think()
	self:PlayerFreeze()
	
	-- Aktualizuj status wyboru podczas preparing
	if SERVER then
		self:SetCanSelect(preparing == true)
		
		-- Automatyczny wybór jeśli preparing się kończy i nie wybrano sług
		if self.CanSelectPrevious and !preparing then
			-- Sprawdź czy nie mamy już wybranych sług
			local pendingServant = self:GetPendingServant()
			local backupServant = self:GetBackupServant()
			
			if (!IsValid(pendingServant) or pendingServant == NULL) and (!IsValid(backupServant) or backupServant == NULL) then
				-- Wybierz losowo dwóch graczy
				local availablePlayers = {}
				for _, ply in pairs(player.GetAll()) do
					-- Sprawdź czy gracz jest ważny, żywy, nie jest właścicielem i nie jest spektatorem
					if IsValid(ply) and ply != self.Owner and ply:Alive() and ply:GTeam() != TEAM_SPEC then
						if ply:GTeam() != TEAM_SCP and !ply.Using714 then
							-- Dodatkowe sprawdzenie - czy gracz rzeczywiście żyje (nie jest obserwatorem)
							if ply:GetObserverMode() == OBS_MODE_NONE then
								table.insert(availablePlayers, ply)
							end
						end
					end
				end
				
				if #availablePlayers >= 2 then
					-- Wybierz dwóch losowych graczy
					local first = table.remove(availablePlayers, math.random(#availablePlayers))
					local second = availablePlayers[math.random(#availablePlayers)]
					
					self:SetPendingServant(first)
					self:SetBackupServant(second)
					
					self.Owner:PrintMessage(HUD_PRINTTALK, "[AUTO] Selected servants: " .. first:Nick() .. " (first) and " .. second:Nick() .. " (backup)")
				elseif #availablePlayers == 1 then
					-- Tylko jeden gracz dostępny
					local first = availablePlayers[1]
					self:SetPendingServant(first)
					
					self.Owner:PrintMessage(HUD_PRINTTALK, "[AUTO] Selected servant: " .. first:Nick() .. " (only one available)")
				else
					-- Brak dostępnych graczy
					self.Owner:PrintMessage(HUD_PRINTTALK, "[AUTO] No available players to select as servants!")
				end
			end
		end
		
		self.CanSelectPrevious = (preparing == true)
	end
	
	if preparing or postround then return end
	if SERVER and IsValid( self.Owner ) then
		-- Usuń automatyczny wybór - teraz tylko manualny podczas preparing

		if self.Instance and !IsValid( self.Instance ) then
			-- Pierwszy SCP-957-1 zginął, sprawdź czy mamy backup
			local backup = self:GetBackupServant()
			if IsValid(backup) and backup:Alive() and backup:GTeam() != TEAM_SCP and backup:GTeam() != TEAM_SPEC and backup:GetObserverMode() == OBS_MODE_NONE then
				-- Przemień backup w SCP-957-1
				local scp = GetSCP( "SCP9571" )
				if scp then
					scp:SetupPlayer( backup )
				end
				
				self.Instance = backup
				self:SetSCPInstance( backup )
				self:SetBackupServant(NULL) -- Wyczyść backup
				
				-- Informacje
				self.Owner:PrintMessage(HUD_PRINTTALK, "Your first servant died! " .. backup:Nick() .. " has been transformed into SCP-957-1!")
				backup:PrintMessage(HUD_PRINTTALK, "The first servant died! You have been transformed into SCP-957-1!")
				
				WinCheck()
			else
				-- Brak backup lub backup martwy/niedostępny - KONIEC, nie ma więcej SCP-957-1
				self.Instance = nil
				self:SetSCPInstance( nil )
				self:SetBackupServant(NULL)
				
				-- Informacja
				self.Owner:PrintMessage(HUD_PRINTTALK, "Both of your servants have died! You have no more SCP-957-1.")
			end
		end

		if IsValid( self.Instance ) then
			if self.Instance:GTeam() != TEAM_SCP then
				-- Sprawdź backup przed czyszczeniem
				local backup = self:GetBackupServant()
				if IsValid(backup) and backup:Alive() and backup:GTeam() != TEAM_SCP and backup:GTeam() != TEAM_SPEC and backup:GetObserverMode() == OBS_MODE_NONE then
					-- Przemień backup w SCP-957-1
					local scp = GetSCP( "SCP9571" )
					if scp then
						scp:SetupPlayer( backup )
					end
					
					self.Instance = backup
					self:SetSCPInstance( backup )
					self:SetBackupServant(NULL) -- Wyczyść backup
					
					-- Informacje o przemianie backup
					self.Owner:PrintMessage(HUD_PRINTTALK, "Your first servant died! " .. backup:Nick() .. " has been transformed into SCP-957-1!")
					backup:PrintMessage(HUD_PRINTTALK, "The first servant died! You have been transformed into SCP-957-1!")
					
					WinCheck()
				else
					-- KONIEC - nie ma więcej SCP-957-1
					self.Instance = nil
					self:SetSCPInstance( nil )
					self:SetBackupServant(NULL)
					
					-- Informacja
					self.Owner:PrintMessage(HUD_PRINTTALK, "Both of your servants have died! You have no more SCP-957-1.")
				end
			end
		end
		
		-- Sprawdź czy preparing się skończył i mamy wybranego gracza
		if self:GetPendingServant() and IsValid(self:GetPendingServant()) and !preparing and !self:GetTransformationScheduled() then
			-- Zaplanuj przemianę za 10 sekund
			self:SetTransformationScheduled(true)
			
			timer.Simple(10, function()
				if IsValid(self) and IsValid(self.Owner) and IsValid(self:GetPendingServant()) then
					local servant = self:GetPendingServant()
					
					-- Sprawdź czy gracz nadal żyje i nie jest spektatorem
					if servant:Alive() and servant:GTeam() != TEAM_SPEC and servant:GetObserverMode() == OBS_MODE_NONE then
												-- Wykonaj przemianę
						local scp = GetSCP( "SCP9571" )
						if scp then
							scp:SetupPlayer( servant )
						end
						
						self.Instance = servant
						self:SetSCPInstance( servant )
						
						-- Informacje o przemianie
						self.Owner:PrintMessage(HUD_PRINTTALK, servant:Nick() .. " has been transformed into SCP-957-1!")
						servant:PrintMessage(HUD_PRINTTALK, "You have been transformed into SCP-957-1!")
						
						-- Wyczyść wybranego gracza
						self:SetPendingServant(NULL)
						self:SetTransformationScheduled(false)
						
						WinCheck()
					else
						-- Gracz już nie żyje lub jest spektatorem
						self.Owner:PrintMessage(HUD_PRINTTALK, "Cannot transform " .. servant:Nick() .. " - player is dead or spectating!")
						self:SetPendingServant(NULL)
						self:SetTransformationScheduled(false)
					end
				else
					-- Coś poszło nie tak, resetuj flagę
					if IsValid(self) then
						self:SetTransformationScheduled(false)
					end
				end
			end)
			
			-- Informacja o opóźnieniu
			self.Owner:PrintMessage(HUD_PRINTTALK, "Transformation will occur in 10 seconds...")
		end
	end

	if CLIENT then
		self.Instance = self:GetSCPInstance()
	end
end

SWEP.NextPrimary = 0
function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if CurTime() < self.NextPrimary then return end
	self.NextPrimary = CurTime() + self.Primary.Delay

	-- Podczas preparing, LPM służy do wyboru SCP-957-1
	if self:GetCanSelect() and SERVER and IsValid( self.Owner ) then
		local tr = util.TraceLine({
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 200,
			filter = self.Owner,
			mask = MASK_SHOT
		})
		
		local ent = tr.Entity
		if IsValid(ent) and ent:IsPlayer() then
			-- Sprawdź czy gracz nie jest spektatorem, SCP, nie używa 714 i rzeczywiście żyje
			if ent:GTeam() != TEAM_SPEC and ent:GTeam() != TEAM_SCP and !ent.Using714 and ent:Alive() and ent:GetObserverMode() == OBS_MODE_NONE then
				-- Zaznacz tego gracza jako przyszłego SCP-957-1 (przemiana po preparing)
				self:SetPendingServant(ent)
				
				-- Informacja tylko dla SCP-957
				self.Owner:PrintMessage(HUD_PRINTTALK, "You have chosen " .. ent:Nick() .. " as SCP-957-1! Transformation will occur after preparing phase.")
			else
				-- Informacja o tym, dlaczego nie można wybrać tego gracza
				if ent:GTeam() == TEAM_SPEC then
					self.Owner:PrintMessage(HUD_PRINTTALK, "Cannot select " .. ent:Nick() .. " - player is a spectator!")
				elseif ent:GTeam() == TEAM_SCP then
					self.Owner:PrintMessage(HUD_PRINTTALK, "Cannot select " .. ent:Nick() .. " - player is already an SCP!")
				elseif ent.Using714 then
					self.Owner:PrintMessage(HUD_PRINTTALK, "Cannot select " .. ent:Nick() .. " - player is using SCP-714!")
				elseif !ent:Alive() or ent:GetObserverMode() != OBS_MODE_NONE then
					self.Owner:PrintMessage(HUD_PRINTTALK, "Cannot select " .. ent:Nick() .. " - player is dead or observing!")
				end
			end
		end
	elseif !self:GetCanSelect() and SERVER and IsValid( self.Owner ) then
		-- Normalny atak AOE po rundzie
		local fent = ents.FindInSphere( self.Owner:GetPos(), 1000 )
		local plys = {}
		for k, v in pairs( fent ) do
			if IsValid( v ) and v:IsPlayer() then
				if v:GTeam() != TEAM_SPEC and v:GTeam() != TEAM_SCP and !v.Using714 and v:Alive() and v:GetObserverMode() == OBS_MODE_NONE then
					table.insert( plys, v )
					v.scp173allow = true
					Timer( "957Timer_"..v:SteamID64(), 1, 5, function( s, n )
						if !IsValid( self ) or !IsValid( self.Owner ) or !IsValid( v ) or v:GTeam() == TEAM_SPEC or v:GTeam() == TEAM_SCP or v.Using714 then
							s:Destroy()
							net.Start( "957Effect" )
								net.WriteBool( false )
							net.Send( plys )
							v.scp173allow = false
							return
						end


						if self:BuffEnabled() then
							local shp = math.Clamp( self.Owner:Health() + 2, 0, self.Owner:GetMaxHealth() )
							self.Owner:SetHealth( shp )
							if IsValid( self.Instance ) then
								local hp = math.Clamp( self.Instance:Health() + 2, 0, self.Instance:GetMaxHealth() )
								self.Instance:SetHealth( hp )
							end
						end

						v:TakeDamage( 3, self.Owner, self )
					end, function()
						v.scp173allow = false
					end )
				end
			end
		end
		if #plys > 0 then
			net.Start( "957Effect" )
				net.WriteBool( true )
			net.Send( plys )
		end
	end
end

-- Nowa funkcja SecondaryAttack - slow
function SWEP:SecondaryAttack()
	if preparing or postround then return end
	
	local nextFire = self:GetNextSecondaryFire()
	if nextFire > CurTime() then return end
	
	if !SERVER then return end
	
	-- Znajdź cel w zasięgu
	local target = nil
	local nearestDist = self.SlowRange
	
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) and ply:Alive() and ply != self.Owner then
			if ply:GTeam() != TEAM_SPEC and ply:GTeam() != TEAM_SCP and !ply.Using714 then
				local dist = self.Owner:GetPos():Distance(ply:GetPos())
				if dist < nearestDist then
					-- Sprawdź czy gracz jest widoczny
					local tr = util.TraceLine({
						start = self.Owner:GetShootPos(),
						endpos = ply:GetShootPos(),
						filter = {self.Owner, self},
						mask = MASK_SHOT
					})
					
					if tr.Entity == ply then
						nearestDist = dist
						target = ply
					end
				end
			end
		end
	end
	
	if IsValid(target) then
		-- Zastosuj slow
		self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
		

		
		-- Spowolnienie celu (90% slow)
		if not target.SCP957_OriginalWalkSpeed then
			target.SCP957_OriginalWalkSpeed = target:GetWalkSpeed()
			target.SCP957_OriginalRunSpeed = target:GetRunSpeed()
		end
		target:SetWalkSpeed(target.SCP957_OriginalWalkSpeed * self.SlowAmount)
		target:SetRunSpeed(target.SCP957_OriginalRunSpeed * self.SlowAmount)
		
		-- Timer do zakończenia slowa
		timer.Create("SCP957_Slow_" .. target:SteamID64(), self.SlowDuration, 1, function()
			if IsValid(target) and target.SCP957_OriginalWalkSpeed then
				target:SetWalkSpeed(target.SCP957_OriginalWalkSpeed)
				target:SetRunSpeed(target.SCP957_OriginalRunSpeed)
				target.SCP957_OriginalWalkSpeed = nil
				target.SCP957_OriginalRunSpeed = nil
			end
		end)
		
		-- Komunikat dla celu
		target:PrintMessage(HUD_PRINTCENTER, "You have been slowed by SCP-957!")
	else
		-- Brak celu - krótszy cooldown
		self:SetNextSecondaryFire(CurTime() + 5)
		self.Owner:EmitSound("buttons/button10.wav")
	end
end


function SWEP:BuffEnabled()
	if IsValid( self.Owner ) and IsValid( self.Instance ) then
		if self.Owner:GetPos():DistToSqr( self.Instance:GetPos() ) < 62500 then
			return true
		end
	end
end

-- Klawisz R - otwiera menu wyboru SCP-957-1 podczas preparing
function SWEP:Reload()
	if CLIENT and self:GetCanSelect() and !IsValid(self.Instance) then
		-- Sprawdź czy mamy już wybranych obu
		local pending = self:GetPendingServant()
		local backup = self:GetBackupServant()
		if IsValid(pending) and IsValid(backup) then
			-- Już wybrano obu
			return
		end
		self:OpenSelectionMenu()
	end
end

-- CLIENT SIDE - Menu wyboru
if CLIENT then
	function SWEP:OpenSelectionMenu()
		if IsValid(self.SelectionMenu) then
			self.SelectionMenu:Remove()
		end
		
		-- Sprawdź co wybieramy
		local pending = self:GetPendingServant()
		local backup = self:GetBackupServant()
		local selectingFirst = !IsValid(pending)
		local titleText = selectingFirst and "SCP-957 - Select Your FIRST Servant" or "SCP-957 - Select Your BACKUP Servant"
		
		self.SelectionMenu = vgui.Create("DFrame")
		self.SelectionMenu:SetSize(650, 550)
		self.SelectionMenu:Center()
		self.SelectionMenu:SetTitle(titleText)
		self.SelectionMenu:SetDraggable(true)
		self.SelectionMenu:ShowCloseButton(true)
		self.SelectionMenu:MakePopup()
		
		-- Panel główny
		local mainPanel = vgui.Create("DPanel", self.SelectionMenu)
		mainPanel:Dock(FILL)
		mainPanel.Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 255))
		end
		
		-- Nagłówek
		local header = vgui.Create("DLabel", mainPanel)
		local headerText = selectingFirst and "Choose your FIRST servant (will transform after preparing)" or "Choose your BACKUP servant (will transform if first dies)"
		header:SetText(headerText)
		header:SetFont("DermaLarge")
		header:SetTextColor(selectingFirst and Color(200, 200, 200, 255) or Color(255, 255, 100, 255))
		header:Dock(TOP)
		header:DockMargin(10, 10, 10, 10)
		header:SetContentAlignment(5)
		
		-- Lista graczy
		local playerScroll = vgui.Create("DScrollPanel", mainPanel)
		playerScroll:Dock(FILL)
		playerScroll:DockMargin(5, 5, 5, 5)
		
		-- Zbierz graczy którzy mogą być wybrani
		local availablePlayers = {}
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) and ply != self.Owner then
				if ply:GTeam() != TEAM_SPEC and ply:GTeam() != TEAM_SCP and !ply.Using714 then
					-- Nie pokazuj gracza który już został wybrany
					if ply != pending and ply != backup then
						table.insert(availablePlayers, ply)
					end
				end
			end
		end
		
		-- Sortuj po nazwie
		table.sort(availablePlayers, function(a, b)
			return a:Nick() < b:Nick()
		end)
		
		-- Utwórz panele dla każdego gracza
		for i, ply in ipairs(availablePlayers) do
			local playerPanel = vgui.Create("DPanel", playerScroll)
			playerPanel:SetSize(620, 100)
			playerPanel:Dock(TOP)
			playerPanel:DockMargin(5, 5, 5, 5)
			playerPanel.Paint = function(self, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60, 255))
				if self:IsHovered() then
					draw.RoundedBox(4, 0, 0, w, h, Color(80, 80, 80, 255))
				end
			end
			
			-- Model gracza
			local modelPanel = vgui.Create("DModelPanel", playerPanel)
			modelPanel:SetSize(100, 100)
			modelPanel:Dock(LEFT)
			modelPanel:SetModel(ply:GetModel())
			modelPanel:SetFOV(45)
			modelPanel:SetCamPos(Vector(50, 50, 50))
			modelPanel:SetLookAt(Vector(0, 0, 40))
			
			function modelPanel:LayoutEntity(Entity) return end
			
			-- Informacje o graczu
			local infoPanel = vgui.Create("DPanel", playerPanel)
			infoPanel:Dock(FILL)
			infoPanel:DockMargin(10, 10, 10, 10)
			infoPanel.Paint = function() end
			
			-- Nazwa gracza
			local nameLabel = vgui.Create("DLabel", infoPanel)
			nameLabel:SetText(ply:Nick())
			nameLabel:SetFont("DermaLarge")
			nameLabel:SetTextColor(Color(255, 255, 255, 255))
			nameLabel:Dock(TOP)
			
			-- Rola gracza
			local roleLabel = vgui.Create("DLabel", infoPanel)
			roleLabel:SetText("Current Role: " .. GetLangRole(ply:GetNClass()))
			roleLabel:SetFont("DermaDefault")
			roleLabel:SetTextColor(Color(180, 180, 180, 255))
			roleLabel:Dock(TOP)
			roleLabel:DockMargin(0, 5, 0, 0)
			
			-- Przycisk wyboru
			local selectBtn = vgui.Create("DButton", playerPanel)
			selectBtn:SetText("SELECT")
			selectBtn:SetSize(100, 80)
			selectBtn:Dock(RIGHT)
			selectBtn:DockMargin(10, 10, 10, 10)
			selectBtn:SetFont("DermaDefaultBold")
			selectBtn.DoClick = function()
				net.Start("SCP957_SelectServant")
					net.WriteEntity(ply)
					net.WriteBool(selectingFirst) -- Czy wybieramy pierwszego
				net.SendToServer()
				self.SelectionMenu:Close()
				-- Dźwięk wyboru
				surface.PlaySound("buttons/button14.wav")
				
				-- Jeśli wybraliśmy pierwszego, otwórz menu dla drugiego
				if selectingFirst then
					timer.Simple(0.1, function()
						if IsValid(self) then
							self:OpenSelectionMenu()
						end
					end)
				end
			end
			selectBtn.Paint = function(self, w, h)
				local col = Color(100, 200, 100, 255)
				if self:IsHovered() then
					col = Color(150, 255, 150, 255)
				end
				draw.RoundedBox(4, 0, 0, w, h, col)
			end
		end
		
		-- Jeśli brak graczy
		if #availablePlayers == 0 then
			local noPlayersLabel = vgui.Create("DLabel", playerScroll)
			noPlayersLabel:SetText("No available players to select")
			noPlayersLabel:SetFont("DermaLarge")
			noPlayersLabel:SetTextColor(Color(255, 100, 100, 255))
			noPlayersLabel:SetContentAlignment(5)
			noPlayersLabel:Dock(TOP)
			noPlayersLabel:SetTall(100)
		end
	end
end

-- SERVER SIDE - Net messages
if SERVER then
	util.AddNetworkString("SCP957_SelectServant")
	
	net.Receive("SCP957_SelectServant", function(len, ply)
		if !IsValid(ply) then return end
		
		local wep = ply:GetActiveWeapon()
		if !IsValid(wep) or wep:GetClass() != "weapon_scp_957" then return end
		if !wep:GetCanSelect() then return end
		if IsValid(wep.Instance) then return end
		
		local target = net.ReadEntity()
		local isFirst = net.ReadBool()
		
		if !IsValid(target) or !target:IsPlayer() then return end
					if target:GTeam() == TEAM_SPEC or (target:GTeam() == TEAM_SCP and target:GetNClass() != ROLES.ROLE_SCP035) or target.Using714 then return end
		
		if isFirst then
			-- Zaznacz gracza jako pierwszego sługę
			wep:SetPendingServant(target)
			
			-- Informacja tylko dla SCP-957
			ply:PrintMessage(HUD_PRINTTALK, "You have chosen " .. target:Nick() .. " as your FIRST servant! They will transform after preparing phase.")
		else
			-- Zaznacz gracza jako backup
			wep:SetBackupServant(target)
			
			-- Informacja tylko dla SCP-957
			ply:PrintMessage(HUD_PRINTTALK, "You have chosen " .. target:Nick() .. " as your BACKUP servant! They will transform if the first one dies.")
		end
	end)
end

function SWEP:Holster()
	if CLIENT and IsValid(self.ModelPanel) then
		self.ModelPanel:Remove()
		self.ModelPanel = nil
	end
	
	return true
end

function SWEP:OnRemove()
	-- Hook do resetowania prędkości graczy
	if SERVER then
		hook.Add("PlayerSpawn", "SCP957_ResetSpeed", function(ply)
			if ply.SCP957_OriginalWalkSpeed then
				ply:SetWalkSpeed(ply.SCP957_OriginalWalkSpeed)
				ply:SetRunSpeed(ply.SCP957_OriginalRunSpeed)
				ply.SCP957_OriginalWalkSpeed = nil
				ply.SCP957_OriginalRunSpeed = nil
			end
		end)
	end
	
	if CLIENT and IsValid(self.ModelPanel) then
		self.ModelPanel:Remove()
		self.ModelPanel = nil
	end
end

-- HUD dokładnie w stylu SCP-069
function SWEP:DrawHUD()
	if disablehud == true then return end
	
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	local centerX = ScrW() / 2
	local centerY = ScrH() / 2
	local hudY = ScrH() - 150
	
	local hudWidth = 500
	local hudHeight = 120
	local hudX = centerX - hudWidth / 2
	
	-- Tło HUD
	surface.SetDrawColor(20, 20, 20, 180)
	surface.DrawRect(hudX, hudY, hudWidth, hudHeight)
	
	-- Obramowanie
	surface.SetDrawColor(100, 100, 100, 200)
	surface.DrawOutlinedRect(hudX, hudY, hudWidth, hudHeight)
	
	-- Linia dekoracyjna
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawRect(hudX + 10, hudY + 5, hudWidth - 20, 2)
	
	-- Tytuł SCP
	surface.SetFont("DermaLarge")
	surface.SetTextColor(200, 200, 200, 255)
	local titleW, titleH = surface.GetTextSize("SCP-957")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-957")
	
	-- Jeśli preparing - pokaż info o wyborze
	if self:GetCanSelect() then
		local pendingServant = self:GetPendingServant()
		local backupServant = self:GetBackupServant()
		
		if !IsValid(pendingServant) then
			-- Nie wybrano jeszcze pierwszego
			surface.SetFont("DermaLarge")
			surface.SetTextColor(255, 255, 100, 255)
			local selectText = "Press R to select your FIRST servant"
			local tw, th = surface.GetTextSize(selectText)
			surface.SetTextPos(centerX - tw/2, hudY + 45)
			surface.DrawText(selectText)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(200, 200, 200, 255)
			local instructText = "Choose two players - first will transform, second is backup"
			tw, th = surface.GetTextSize(instructText)
			surface.SetTextPos(centerX - tw/2, hudY + 75)
			surface.DrawText(instructText)
		elseif !IsValid(backupServant) then
			-- Wybrano pierwszego, czeka na drugiego
			surface.SetFont("DermaDefault")
			surface.SetTextColor(100, 255, 100, 255)
			local selectText = "First: " .. pendingServant:Nick()
			local tw, th = surface.GetTextSize(selectText)
			surface.SetTextPos(centerX - tw/2, hudY + 40)
			surface.DrawText(selectText)
			
			surface.SetFont("DermaLarge")
			surface.SetTextColor(255, 255, 100, 255)
			selectText = "Press R to select BACKUP servant"
			tw, th = surface.GetTextSize(selectText)
			surface.SetTextPos(centerX - tw/2, hudY + 60)
			surface.DrawText(selectText)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(200, 200, 200, 255)
			local instructText = "Backup will transform if first servant dies"
			tw, th = surface.GetTextSize(instructText)
			surface.SetTextPos(centerX - tw/2, hudY + 90)
			surface.DrawText(instructText)
		else
			-- Wybrano obu
			surface.SetFont("DermaDefault")
			surface.SetTextColor(100, 255, 100, 255)
			local selectText = "First: " .. pendingServant:Nick()
			local tw, th = surface.GetTextSize(selectText)
			surface.SetTextPos(centerX - tw/2, hudY + 40)
			surface.DrawText(selectText)
			
			surface.SetTextColor(255, 255, 100, 255)
			selectText = "Backup: " .. backupServant:Nick()
			tw, th = surface.GetTextSize(selectText)
			surface.SetTextPos(centerX - tw/2, hudY + 60)
			surface.DrawText(selectText)
			
			surface.SetFont("DermaDefault")
			surface.SetTextColor(200, 200, 200, 255)
			local instructText = "Transformation will occur after preparing phase"
			tw, th = surface.GetTextSize(instructText)
			surface.SetTextPos(centerX - tw/2, hudY + 85)
			surface.DrawText(instructText)
		end
		return
	end
	
	-- Cooldowny
	local lpmCooldown = 0
	local ppmCooldown = 0
	
	if self.NextPrimary and self.NextPrimary > CurTime() then
		lpmCooldown = self.NextPrimary - CurTime()
	end
	
	local nextSecondary = self:GetNextSecondaryFire()
	if nextSecondary > CurTime() then
		ppmCooldown = nextSecondary - CurTime()
	end
	
	local cooldownY = hudY + 60
	local barWidth = 120
	local barHeight = 8
	local barSpacing = 20
	
	-- LMB Cooldown
	local lpmBarX = centerX - barWidth - barSpacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(lpmBarX, cooldownY - 15)
	surface.DrawText("LMB - AOE")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(lpmBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(lpmBarX, cooldownY, barWidth, barHeight)
	
	if lpmCooldown > 0 then
		local progress = 1 - (lpmCooldown / self.Primary.Delay)
		surface.SetDrawColor(255, 100, 100, 255)
		surface.DrawRect(lpmBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 150, 150, 255)
		surface.SetTextPos(lpmBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", lpmCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(lpmBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(lpmBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- RMB Cooldown
	local ppmBarX = centerX + barSpacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(ppmBarX, cooldownY - 15)
	surface.DrawText("RMB - Slow")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(ppmBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(ppmBarX, cooldownY, barWidth, barHeight)
	
	if ppmCooldown > 0 then
		local progress = 1 - (ppmCooldown / self.Secondary.Delay)
		surface.SetDrawColor(100, 150, 255, 255)
		surface.DrawRect(ppmBarX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 200, 255, 255)
		surface.SetTextPos(ppmBarX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", ppmCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(ppmBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(ppmBarX, cooldownY + 10)
		surface.DrawText("READY")
	end
	
	-- Box SCP-957-1 po prawej stronie
	if IsValid(self.Instance) then
		local boxX = ScrW() - 240
		local boxY = ScrH() / 2 - 150
		local boxW = 220
		local boxH = 300
		
		-- Tło
		surface.SetDrawColor(20, 20, 20, 180)
		surface.DrawRect(boxX - 5, boxY - 5, boxW + 10, boxH + 10)
		
		surface.SetDrawColor(100, 100, 100, 200)
		surface.DrawOutlinedRect(boxX - 5, boxY - 5, boxW + 10, boxH + 10)
		
		-- 1. DISTANCE (na górze)
		local playerPos = ply:GetPos()
		local servantPos = self.Instance:GetPos()
		local distance = math.Round(playerPos:Distance(servantPos))
		surface.SetFont("DermaDefaultBold")
		surface.SetTextColor(255, 255, 255, 255)
		local distText = distance .. "m"
		local tw, th = surface.GetTextSize(distText)
		surface.SetTextPos(boxX + boxW/2 - tw/2, boxY + 10)
		surface.DrawText(distText)
		
		-- 2. MODEL RENDER
		if !IsValid(self.ModelPanel) then
			self.ModelPanel = vgui.Create("DModelPanel")
			self.ModelPanel:SetSize(150, 150)
			self.ModelPanel:SetPos(boxX + boxW/2 - 75, boxY + 35)
			self.ModelPanel:SetModel(self.Instance:GetModel())
			self.ModelPanel:SetFOV(35)
			self.ModelPanel:SetCamPos(Vector(80, 0, 60))
			self.ModelPanel:SetLookAt(Vector(0, 0, 40))
			self.ModelPanel:SetAmbientLight(Color(50, 50, 50))
			self.ModelPanel:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
			self.ModelPanel.LayoutEntity = function(panel, ent)
				ent:SetAngles(Angle(0, RealTime() * 30, 0))
			end
		else
			-- Aktualizuj model jeśli się zmienił
			if self.ModelPanel:GetModel() != self.Instance:GetModel() then
				self.ModelPanel:SetModel(self.Instance:GetModel())
			end
		end
		
		-- 3. HEALTHBAR (bezpośrednio pod modelem)
		local healthY = boxY + 190
		local healthPercent = self.Instance:Health() / self.Instance:GetMaxHealth()
		local healthBarWidth = 180
		local healthBarHeight = 6
		local healthBarX = boxX + 20
		
		-- Tło paska
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(healthBarX, healthY, healthBarWidth, healthBarHeight)
		
		-- Pasek życia
		local healthColor = Color(255 * (1 - healthPercent), 255 * healthPercent, 0, 255)
		surface.SetDrawColor(healthColor)
		surface.DrawRect(healthBarX, healthY, healthBarWidth * healthPercent, healthBarHeight)
		
		-- Obramowanie
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawOutlinedRect(healthBarX, healthY, healthBarWidth, healthBarHeight)
		
		-- 4. NICK - ROLA
		surface.SetFont("DermaDefaultBold")
		surface.SetTextColor(255, 255, 255, 255)
		local nick = self.Instance:Nick()
		if string.len(nick) > 18 then
			nick = string.sub(nick, 1, 15) .. "..."
		end
		local nameText = nick .. " - " .. GetLangRole(self.Instance:GetLastRole())
		tw, th = surface.GetTextSize(nameText)
		surface.SetTextPos(boxX + boxW/2 - tw/2, healthY + 15)
		surface.DrawText(nameText)
		
		-- 5. BUFF STATUS
		surface.SetFont("DermaDefault")
		if self:BuffEnabled() then
			surface.SetTextColor(0, 255, 0, 255)
			text = "BUFF ACTIVE"
		else
			surface.SetTextColor(255, 100, 100, 255)
			text = "BUFF INACTIVE"
		end
		tw, th = surface.GetTextSize(text)
		surface.SetTextPos(boxX + boxW/2 - tw/2, healthY + 35)
		surface.DrawText(text)
		
		-- 6. BACKUP ALIVE OR NOT
		local backupServant = self:GetBackupServant()
		if IsValid(backupServant) and backupServant != NULL then
			surface.SetFont("DermaDefaultBold")
			surface.SetTextColor(255, 255, 100, 255)
			
			-- Sprawdzamy status backup
			local backupText = "Backup: "
			if backupServant:Alive() and backupServant:GTeam() != TEAM_SPEC then
				surface.SetTextColor(100, 255, 100, 255)
				backupText = backupText .. "ALIVE"
			else
				surface.SetTextColor(255, 100, 100, 255)
				backupText = backupText .. "DEAD"
			end
			
			tw, th = surface.GetTextSize(backupText)
			surface.SetTextPos(boxX + boxW/2 - tw/2, healthY + 95)
			surface.DrawText(backupText)
		end
		
	else
		-- Usuń panel modelu jeśli istnieje
		if IsValid(self.ModelPanel) then
			self.ModelPanel:Remove()
			self.ModelPanel = nil
		end
		
		-- Nie ma SCP-957-1 i nie ma już backup
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 100, 100, 255)
		local noServantText = "No SCP-957-1 available"
		local tw, th = surface.GetTextSize(noServantText)
		surface.SetTextPos(centerX - tw/2, hudY + 95)
		surface.DrawText(noServantText)
	end
end