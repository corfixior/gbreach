-- Shared file for rules system
if SERVER then
	util.AddNetworkString("BR_OpenRulesMenu")
	util.AddNetworkString("BR_UpdateRules")
	util.AddNetworkString("BR_SendRules")
	
	-- Pliki z regulaminami
	local rulesFilePL = "breach/rules_pl.txt"
	local rulesFileEN = "breach/rules_en.txt"
	local rulesTextPL = ""
	local rulesTextEN = ""
	
	-- Wczytaj regulaminy z plików
	local function LoadRules()
		-- Polski regulamin
		if file.Exists(rulesFilePL, "DATA") then
			rulesTextPL = file.Read(rulesFilePL, "DATA")
		else
			rulesTextPL = "Regulamin serwera:\n\n1. Szanuj innych graczy\n2. Nie używaj cheatów\n3. Nie spamuj\n4. Graj zgodnie z rolą\n5. Słuchaj administracji"
			file.CreateDir("breach")
			file.Write(rulesFilePL, rulesTextPL)
		end
		
		-- Angielski regulamin
		if file.Exists(rulesFileEN, "DATA") then
			rulesTextEN = file.Read(rulesFileEN, "DATA")
		else
			rulesTextEN = "Server Rules:\n\n1. Respect other players\n2. Don't use cheats\n3. Don't spam\n4. Play according to your role\n5. Listen to administration"
			file.Write(rulesFileEN, rulesTextEN)
		end
	end
	
	-- Zapisz regulamin do pliku
	local function SaveRules(text, lang)
		if lang == "pl" then
			rulesTextPL = text
			file.Write(rulesFilePL, rulesTextPL)
		else
			rulesTextEN = text
			file.Write(rulesFileEN, rulesTextEN)
		end
	end
	
	-- Inicjalizacja
	LoadRules()
	
	-- Hook na komendy czatu
	hook.Add("PlayerSay", "BR_RulesCommand", function(ply, text, public)
		text = string.lower(text)
		
		if text == "!regulamin" or text == "!rules" or text == "/regulamin" or text == "/rules" then
			net.Start("BR_OpenRulesMenu")
				net.WriteString(rulesTextPL)
				net.WriteString(rulesTextEN)
				net.WriteBool(ply:IsSuperAdmin())
			net.Send(ply)
			
			return ""
		end
	end)
	
	-- Odbieranie aktualizacji regulaminu
	net.Receive("BR_UpdateRules", function(len, ply)
		if not ply:IsSuperAdmin() then return end
		
		local newRulesPL = net.ReadString()
		local newRulesEN = net.ReadString()
		
		SaveRules(newRulesPL, "pl")
		SaveRules(newRulesEN, "en")
		
		-- Powiadom wszystkich graczy
		for _, p in pairs(player.GetAll()) do
			p:PrintMessage(HUD_PRINTTALK, "[RULES] Rules have been updated by " .. ply:Nick())
		end
	end)
	
	-- Żądanie regulaminu
	net.Receive("BR_SendRules", function(len, ply)
		net.Start("BR_OpenRulesMenu")
			net.WriteString(rulesTextPL)
			net.WriteString(rulesTextEN)
			net.WriteBool(ply:IsSuperAdmin())
		net.Send(ply)
	end)
end

if CLIENT then
	local rulesFrame = nil
	
	net.Receive("BR_OpenRulesMenu", function()
		local rulesTextPL = net.ReadString()
		local rulesTextEN = net.ReadString()
		local canEdit = net.ReadBool()
		
		-- Zamknij poprzednie okno jeśli istnieje
		if IsValid(rulesFrame) then
			rulesFrame:Remove()
		end
		
		-- Główne okno
		rulesFrame = vgui.Create("DFrame")
		rulesFrame:SetSize(800, 600)
		rulesFrame:Center()
		rulesFrame:SetTitle("Regulamin Serwera / Server Rules")
		rulesFrame:SetDraggable(true)
		rulesFrame:ShowCloseButton(true)
		rulesFrame:MakePopup()
		
		-- Panel tła
		rulesFrame.Paint = function(self, w, h)
			draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 30, 250))
			draw.RoundedBoxEx(8, 0, 0, w, 24, Color(50, 50, 50, 255), true, true, false, false)
		end
		
		-- Przycisk odśwież na dole na środku
		local refreshBtn = vgui.Create("DButton", rulesFrame)
		refreshBtn:SetText("Odśwież / Refresh")
		refreshBtn:SetSize(150, 30)
		refreshBtn:SetPos(rulesFrame:GetWide() / 2 - 75, rulesFrame:GetTall() - 40)
		refreshBtn.DoClick = function()
			net.Start("BR_SendRules")
			net.SendToServer()
			surface.PlaySound("buttons/button15.wav")
		end
		
		refreshBtn.Paint = function(self, w, h)
			local col = Color(70, 70, 70)
			if self:IsHovered() then
				col = Color(90, 90, 90)
			end
			draw.RoundedBox(4, 0, 0, w, h, col)
		end
		
		-- Panel z zakładkami
		local sheet = vgui.Create("DPropertySheet", rulesFrame)
		sheet:Dock(FILL)
		sheet:DockMargin(10, 10, 10, 50)
		
		if canEdit then
			-- Tryb edycji dla superadminów
			
			-- Panel polski
			local panelPL = vgui.Create("DPanel", sheet)
			panelPL.Paint = function(self, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 35, 255))
			end
			
			local textEntryPL = vgui.Create("DTextEntry", panelPL)
			textEntryPL:Dock(FILL)
			textEntryPL:DockMargin(5, 5, 5, 5)
			textEntryPL:SetMultiline(true)
			textEntryPL:SetText(rulesTextPL)
			textEntryPL:SetFont("DermaDefault")
			textEntryPL:SetTextColor(Color(255, 255, 255))
			textEntryPL:SetPaintBackground(false)
			
			textEntryPL.Paint = function(self, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 255))
				self:DrawTextEntryText(Color(255, 255, 255), Color(100, 100, 255), Color(255, 255, 255))
			end
			
			-- Panel angielski
			local panelEN = vgui.Create("DPanel", sheet)
			panelEN.Paint = function(self, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 35, 255))
			end
			
			local textEntryEN = vgui.Create("DTextEntry", panelEN)
			textEntryEN:Dock(FILL)
			textEntryEN:DockMargin(5, 5, 5, 5)
			textEntryEN:SetMultiline(true)
			textEntryEN:SetText(rulesTextEN)
			textEntryEN:SetFont("DermaDefault")
			textEntryEN:SetTextColor(Color(255, 255, 255))
			textEntryEN:SetPaintBackground(false)
			
			textEntryEN.Paint = function(self, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 255))
				self:DrawTextEntryText(Color(255, 255, 255), Color(100, 100, 255), Color(255, 255, 255))
			end
			
			-- Dodaj zakładki
			sheet:AddSheet("Polski", panelPL, "icon16/flag_red.png")
			sheet:AddSheet("English", panelEN, "icon16/flag_blue.png")
			
			-- Przycisk zapisz
			local saveBtn = vgui.Create("DButton", rulesFrame)
			saveBtn:SetText("Zapisz zmiany / Save changes")
			saveBtn:SetSize(200, 30)
			saveBtn:SetPos(rulesFrame:GetWide() - 220, rulesFrame:GetTall() - 40)
			saveBtn.DoClick = function()
				net.Start("BR_UpdateRules")
					net.WriteString(textEntryPL:GetText())
					net.WriteString(textEntryEN:GetText())
				net.SendToServer()
				
				rulesFrame:Close()
				surface.PlaySound("buttons/button15.wav")
			end
			
			saveBtn.Paint = function(self, w, h)
				local col = Color(100, 200, 100)
				if self:IsHovered() then
					col = Color(120, 220, 120)
				end
				draw.RoundedBox(4, 0, 0, w, h, col)
			end
			
			-- Info o edycji
			local infoLabel = vgui.Create("DLabel", rulesFrame)
			infoLabel:SetText("TRYB EDYCJI / EDIT MODE")
			infoLabel:SetFont("DermaDefaultBold")
			infoLabel:SetTextColor(Color(255, 200, 0))
			infoLabel:SizeToContents()
			infoLabel:SetPos(10, rulesFrame:GetTall() - 35)
		else
			-- Tryb tylko do odczytu
			
			-- Panel polski
			local panelPL = vgui.Create("DPanel", sheet)
			panelPL.Paint = function(self, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 35, 255))
			end
			
			local richTextPL = vgui.Create("RichText", panelPL)
			richTextPL:Dock(FILL)
			richTextPL:DockMargin(10, 10, 10, 10)
			richTextPL:SetFontInternal("DermaLarge")
			
			-- Formatowanie tekstu polskiego
			local linesPL = string.Explode("\n", rulesTextPL)
			for _, line in ipairs(linesPL) do
				if string.find(line, "^%d+%.") or string.find(line, "^-") or string.find(line, "^•") then
					richTextPL:InsertColorChange(255, 255, 255, 255)
					richTextPL:AppendText(line .. "\n")
				elseif string.len(string.Trim(line)) > 0 then
					richTextPL:InsertColorChange(255, 200, 0, 255)
					richTextPL:AppendText(line .. "\n")
					richTextPL:InsertColorChange(255, 255, 255, 255)
				else
					richTextPL:AppendText("\n")
				end
			end
			
			-- Panel angielski
			local panelEN = vgui.Create("DPanel", sheet)
			panelEN.Paint = function(self, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 35, 255))
			end
			
			local richTextEN = vgui.Create("RichText", panelEN)
			richTextEN:Dock(FILL)
			richTextEN:DockMargin(10, 10, 10, 10)
			richTextEN:SetFontInternal("DermaLarge")
			
			-- Formatowanie tekstu angielskiego
			local linesEN = string.Explode("\n", rulesTextEN)
			for _, line in ipairs(linesEN) do
				if string.find(line, "^%d+%.") or string.find(line, "^-") or string.find(line, "^•") then
					richTextEN:InsertColorChange(255, 255, 255, 255)
					richTextEN:AppendText(line .. "\n")
				elseif string.len(string.Trim(line)) > 0 then
					richTextEN:InsertColorChange(255, 200, 0, 255)
					richTextEN:AppendText(line .. "\n")
					richTextEN:InsertColorChange(255, 255, 255, 255)
				else
					richTextEN:AppendText("\n")
				end
			end
			
			-- Dodaj zakładki
			sheet:AddSheet("Polski", panelPL, "icon16/flag_red.png")
			sheet:AddSheet("English", panelEN, "icon16/flag_blue.png")
		end
	end)
end