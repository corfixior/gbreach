AddCSLuaFile()

SWEP.Base 		= "weapon_scp_base"
SWEP.PrintName 	= "SCP-069"

SWEP.Primary.Delay        = 1.5

SWEP.DrawCrosshair		= true
SWEP.HoldType 			= "none"

SWEP.KilledVictims = {}

function SWEP:Initialize()
	self:InitializeLanguage( "SCP_069" )
	self:SetHoldType("none")
	
	if SERVER then
		self.KilledVictims = {}
	end
end

function SWEP:DrawWorldModel()
	-- Nie rysuj modelu broni
end

function SWEP:DrawWorldModelTranslucent()
	-- Nie rysuj modelu broni
end

function SWEP:DrawViewModel()
	-- Nie rysuj viewmodelu
end

function SWEP:PreDrawViewModel()
	return true -- Zapobiega rysowaniu
end

function SWEP:ViewModelDrawn()
	-- Nic nie rób
end

function SWEP:GetViewModelPosition(pos, ang)
	return pos, ang
end

SWEP.ShowViewModel = false
SWEP.ShowWorldModel = false

SWEP.NextPrimary = 0
function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if self.NextPrimary > CurTime() then return end
	self.NextPrimary = CurTime() + self.Primary.Delay
	
	if !SERVER then return end
	
	local tr = util.TraceHull( {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 75,
		maxs = Vector( 10, 10, 10 ),
		mins = Vector( -10, -10, -10 ),
		filter = self.Owner,
		mask = MASK_SHOT
	} )
	
	local ent = tr.Entity
	if IsValid( ent ) then
		if ent:IsPlayer() then
			if ent:GTeam() == TEAM_SPEC then return end
			if ent:GTeam() == TEAM_SCP and ent:GetNClass() != ROLES.ROLE_SCP035 then return end
			
			-- Zapisz informacje o ofierze przed zabiciem
			local victimData = {
				name = ent:Nick(),
				model = ent:GetModel(),
				steamid = ent:SteamID()
			}
			
			-- Zabij ofiarę
			ent:TakeDamage( 9999, self.Owner, self.Owner )
			
			-- Dodaj do listy zabitych
			table.insert(self.KilledVictims, victimData)
			
			-- Wyślij aktualizację do klienta
			self:UpdateVictimList()
		else
			self:SCPDamageEvent( ent, 50 )
		end	
	end
end

function SWEP:SecondaryAttack()
	if preparing or postround then return end
	if CLIENT then
		self:OpenDisguiseMenu()
	end
end

function SWEP:UpdateVictimList()
	if !SERVER then return end
	
	net.Start("SCP069_UpdateVictims")
		net.WriteEntity(self)
		net.WriteUInt(#self.KilledVictims, 8)
		for i, victim in ipairs(self.KilledVictims) do
			net.WriteString(victim.name)
			net.WriteString(victim.model)
			net.WriteString(victim.steamid)
		end
	net.Send(self.Owner)
end

if CLIENT then
	function SWEP:OpenDisguiseMenu()
		if IsValid(self.DisguiseMenu) then
			self.DisguiseMenu:Remove()
		end
		
		self.DisguiseMenu = vgui.Create("DFrame")
		self.DisguiseMenu:SetSize(650, 550)
		self.DisguiseMenu:Center()
		self.DisguiseMenu:SetTitle("SCP-069 - Disguise Selection")
		self.DisguiseMenu:SetDraggable(true)
		self.DisguiseMenu:ShowCloseButton(true)
		self.DisguiseMenu:MakePopup()
		
		-- Zakładki
		local sheet = vgui.Create("DPropertySheet", self.DisguiseMenu)
		sheet:Dock(FILL)
		
		-- ZAKŁADKA 1: Zabici gracze
		local victimsPanel = vgui.Create("DPanel", sheet)
		victimsPanel.Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 255))
		end
		
		local victimsScroll = vgui.Create("DScrollPanel", victimsPanel)
		victimsScroll:Dock(FILL)
		
		-- Domyślny model SCP-069
		local defaultPanel = vgui.Create("DPanel", victimsScroll)
		defaultPanel:SetSize(580, 100)
		defaultPanel:Dock(TOP)
		defaultPanel:DockMargin(5, 5, 5, 5)
		defaultPanel.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60, 255))
		end
		
		-- Model preview dla domyślnego
		local defaultModel = vgui.Create("DModelPanel", defaultPanel)
		defaultModel:SetSize(100, 100)
		defaultModel:Dock(LEFT)
		defaultModel:SetModel("models/player/kerry/class_d_1.mdl")
		defaultModel:SetFOV(45)
		defaultModel:SetCamPos(Vector(50, 50, 50))
		defaultModel:SetLookAt(Vector(0, 0, 40))
		
		function defaultModel:LayoutEntity(Entity) return end
		
		local defaultBtn = vgui.Create("DButton", defaultPanel)
		defaultBtn:SetText("Default SCP-069 Form")
		defaultBtn:SetSize(460, 90)
		defaultBtn:Dock(FILL)
		defaultBtn:DockMargin(5, 5, 5, 5)
		defaultBtn:SetFont("DermaLarge")
		defaultBtn.DoClick = function()
			net.Start("SCP069_ChangeDisguise")
				net.WriteString("")
			net.SendToServer()
			self.DisguiseMenu:Close()
			-- Dźwięk tylko dla gracza
			surface.PlaySound("ambient/energy/weld1.wav")
		end
		
		-- Lista ofiar
		if self.VictimList then
			for i, victim in ipairs(self.VictimList) do
				local victimPanel = vgui.Create("DPanel", victimsScroll)
				victimPanel:SetSize(580, 100)
				victimPanel:Dock(TOP)
				victimPanel:DockMargin(5, 5, 5, 5)
				victimPanel.Paint = function(self, w, h)
					draw.RoundedBox(4, 0, 0, w, h, Color(80, 60, 60, 255))
				end
				
				-- Model preview
				local modelPanel = vgui.Create("DModelPanel", victimPanel)
				modelPanel:SetSize(100, 100)
				modelPanel:Dock(LEFT)
				modelPanel:SetModel(victim.model)
				modelPanel:SetFOV(45)
				modelPanel:SetCamPos(Vector(50, 50, 50))
				modelPanel:SetLookAt(Vector(0, 0, 40))
				
				function modelPanel:LayoutEntity(Entity) return end
				
				local btn = vgui.Create("DButton", victimPanel)
				btn:SetText(victim.name)
				btn:SetSize(460, 90)
				btn:Dock(FILL)
				btn:DockMargin(5, 5, 5, 5)
				btn:SetFont("DermaLarge")
				btn.DoClick = function()
					net.Start("SCP069_ChangeDisguise")
						net.WriteString(victim.model)
					net.SendToServer()
					self.DisguiseMenu:Close()
					-- Dźwięk tylko dla gracza
					surface.PlaySound("ambient/energy/weld1.wav")
				end
			end
		end
		
		-- ZAKŁADKA 2: Modele SCP
		local scpPanel = vgui.Create("DPanel", sheet)
		scpPanel.Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 255))
		end
		
		local scpScroll = vgui.Create("DScrollPanel", scpPanel)
		scpScroll:Dock(FILL)
		
		-- Lista modeli SCP
		local scpModels = {
			{name = "SCP-023", model = "models/Novux/023/Novux_SCP-023.mdl"},
			{name = "SCP-049", model = "models/vinrax/player/scp049_player.mdl"},
			{name = "SCP-049-2", model = "models/player/zombie_classic.mdl"},
			{name = "SCP-054", model = "models/xiali/scp_054/ctg/scp_054.mdl"},
			{name = "SCP-066", model = "models/player/mrsilver/scp_066pm/scp_066_pm.mdl"},
			{name = "SCP-076", model = "models/abel/abel.mdl"},
			{name = "SCP-082", model = "models/models/konnie/savini/savini.mdl"},
			{name = "SCP-096", model = "models/scp096anim/player/scp096pm_raf.mdl"},
			{name = "SCP-106", model = "models/scp/106/unity/unity_scp_106_player.mdl"},
			{name = "SCP-173", model = "models/jqueary/scp/unity/scp173/scp173unity.mdl"},
			{name = "SCP-239", model = "models/cultist/scp/scp_239.mdl"},
			{name = "SCP-457", model = "models/player/corpse1.mdl"},
			{name = "SCP-682", model = "models/danx91/scp/scp_682.mdl"},
			{name = "SCP-689", model = "models/dwdarksouls/models/darkwraith.mdl"},
			{name = "SCP-860-2", model = "models/props/forest_monster/forest_monster2.mdl"},
			{name = "SCP-939", model = "models/scp/939/unity/unity_scp_939.mdl"},
			{name = "SCP-957", model = "models/immigrant/outlast/walrider_pm.mdl"},
			{name = "SCP-966", model = "models/player/mishka/966_new.mdl"},
			{name = "SCP-999", model = "models/scp/999/jq/scp_999_pmjq.mdl"},
			{name = "SCP-1048-A", model = "models/1048/tdyear/tdybrownearpm.mdl"},
			{name = "SCP-1048-B", model = "models/player/teddy_bear/teddy_bear.mdl"},
			{name = "SCP-1316", model = "models/yevocore/cat/cat.mdl"},
			{name = "SCP-1471", model = "models/burd/scp1471/scp1471.mdl"},
			{name = "SCP-2137-J", model = "models/t37/papaj.mdl"},
			{name = "SCP-2521", model = "models/cultist/scp/scp_no1.mdl"},
			{name = "SCP-3166", model = "models/nickelodeon_all_stars/garfield/garfield.mdl"},
			{name = "SCP-3199", model = "models/washton/3199.mdl"},
			{name = "SCP-Doom Guy-J", model = "models/player/doom_fn_pm.mdl"},
			{name = "SCP-Steve-J", model = "models/minecraft/steve/steve.mdl"},
			{name = "SCP-TTT-SAHUR", model = "models/gacommissions/tungtungtungsahur.mdl"}
		}
		
		for i, scp in ipairs(scpModels) do
			local scpModelPanel = vgui.Create("DPanel", scpScroll)
			scpModelPanel:SetSize(580, 100)
			scpModelPanel:Dock(TOP)
			scpModelPanel:DockMargin(5, 5, 5, 5)
			scpModelPanel.Paint = function(self, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(60, 40, 40, 255))
			end
			
			-- Model preview
			local modelPanel = vgui.Create("DModelPanel", scpModelPanel)
			modelPanel:SetSize(100, 100)
			modelPanel:Dock(LEFT)
			modelPanel:SetModel(scp.model)
			modelPanel:SetFOV(45)
			modelPanel:SetCamPos(Vector(50, 50, 50))
			modelPanel:SetLookAt(Vector(0, 0, 40))
			
			function modelPanel:LayoutEntity(Entity) return end
			
			local btn = vgui.Create("DButton", scpModelPanel)
			btn:SetText(scp.name)
			btn:SetSize(460, 90)
			btn:Dock(FILL)
			btn:DockMargin(5, 5, 5, 5)
			btn:SetFont("DermaLarge")
			btn.DoClick = function()
				net.Start("SCP069_ChangeDisguise")
					net.WriteString(scp.model)
				net.SendToServer()
				self.DisguiseMenu:Close()
				-- Dźwięk tylko dla gracza
				surface.PlaySound("ambient/energy/weld1.wav")
			end
		end
		
		-- Dodaj zakładki
		sheet:AddSheet("Killed Players", victimsPanel, "icon16/user_delete.png")
		sheet:AddSheet("SCP Models", scpPanel, "icon16/bug.png")
	end
	
	net.Receive("SCP069_UpdateVictims", function()
		local wep = net.ReadEntity()
		if !IsValid(wep) then return end
		
		wep.VictimList = {}
		local count = net.ReadUInt(8)
		for i = 1, count do
			table.insert(wep.VictimList, {
				name = net.ReadString(),
				model = net.ReadString(),
				steamid = net.ReadString()
			})
		end
	end)
end

if SERVER then
	util.AddNetworkString("SCP069_UpdateVictims")
	util.AddNetworkString("SCP069_ChangeDisguise")
	
	net.Receive("SCP069_ChangeDisguise", function(len, ply)
		local model = net.ReadString()
		
		if IsValid(ply) and ply:GetActiveWeapon() and ply:GetActiveWeapon():GetClass() == "weapon_scp_069" then
			if model == "" then
				-- Przywróć domyślny model SCP-069
				ply:SetModel("models/player/kerry/class_d_1.mdl")
			else
				-- Zmień na model ofiary
				ply:SetModel(model)
			end
		end
	end)
end

function SWEP:DrawHUD()
	if disablehud == true then return end
	
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	local centerX = ScrW() / 2
	local centerY = ScrH() / 2
	local hudY = ScrH() - 150
	
	-- Pozycja HUD (dokładnie jak SCP-069)
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
	local titleW, titleH = surface.GetTextSize("SCP-069")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-069")
	
	-- Cooldowny
	local lpmCooldown = 0
	local ppmCooldown = 0
	
	if self.NextPrimary and self.NextPrimary > CurTime() then
		lpmCooldown = self.NextPrimary - CurTime()
	end
	
	local cooldownY = hudY + 60
	local barWidth = 120
	local barHeight = 8
	local barSpacing = 20
	
	-- LMB (Kill) Cooldown
	local lpmBarX = centerX - barWidth - barSpacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(lpmBarX, cooldownY - 15)
	surface.DrawText("LMB - Kill")
	
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
	
	-- RMB (Disguise) Status
	local ppmBarX = centerX + barSpacing
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(ppmBarX, cooldownY - 15)
	surface.DrawText("RMB - Disguise")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(ppmBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(ppmBarX, cooldownY, barWidth, barHeight)
	
	-- Liczba ofiar
	local victimCount = 0
	if self.VictimList then
		victimCount = #self.VictimList
	end
	
	if victimCount > 0 then
		surface.SetDrawColor(255, 215, 0, 255)
		surface.DrawRect(ppmBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 255, 150, 255)
		surface.SetTextPos(ppmBarX, cooldownY + 10)
		surface.DrawText("VICTIMS: " .. victimCount)
	else
		surface.SetDrawColor(100, 100, 100, 255)
		surface.DrawRect(ppmBarX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 150, 150, 255)
		surface.SetTextPos(ppmBarX, cooldownY + 10)
		surface.DrawText("NO VICTIMS")
	end
	
	-- Renderowanie aktualnego modelu po prawej stronie ekranu
	if not self.ModelPanel then
		self.ModelPanel = vgui.Create("DModelPanel")
		self.ModelPanel:SetSize(200, 300)
		self.ModelPanel:SetPos(ScrW() - 220, ScrH() / 2 - 150)
		self.ModelPanel:SetFOV(45)
		self.ModelPanel:SetCamPos(Vector(80, 80, 60))
		self.ModelPanel:SetLookAt(Vector(0, 0, 40))
		self.ModelPanel:SetAlpha(255)
		self.ModelPanel.LayoutEntity = function(self, ent)
			ent:SetAngles(Angle(0, RealTime() * 30, 0))
		end
	end
	
	-- Aktualizuj model jeśli się zmienił
	if self.ModelPanel then
		local currentModel = ply:GetModel()
		if self.ModelPanel.LastModel != currentModel then
			self.ModelPanel:SetModel(currentModel)
			self.ModelPanel.LastModel = currentModel
		end
		
		-- Rysuj tło dla panelu
		local x, y = self.ModelPanel:GetPos()
		local w, h = self.ModelPanel:GetSize()
		
		surface.SetDrawColor(20, 20, 20, 150)
		surface.DrawRect(x - 5, y - 5, w + 10, h + 10)
		
		surface.SetDrawColor(100, 100, 100, 200)
		surface.DrawOutlinedRect(x - 5, y - 5, w + 10, h + 10)
		
		-- Tytuł
		surface.SetFont("DermaDefault")
		surface.SetTextColor(200, 200, 200, 255)
		local text = "Current Form"
		local tw, th = surface.GetTextSize(text)
		surface.SetTextPos(x + w/2 - tw/2, y - 20)
		surface.DrawText(text)
		
		self.ModelPanel:SetVisible(true)
		self.ModelPanel:PaintManual()
	end
end

function SWEP:Holster()
	if CLIENT and IsValid(self.ModelPanel) then
		self.ModelPanel:Remove()
		self.ModelPanel = nil
	end
	return true
end

function SWEP:OnRemove()
	if CLIENT and IsValid(self.ModelPanel) then
		self.ModelPanel:Remove()
		self.ModelPanel = nil
	end
end