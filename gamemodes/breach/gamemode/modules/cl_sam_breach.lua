-- SAM Breach Client Integration
if SERVER then return end

-- Sprawdź czy SAM jest dostępny
if not sam or not sam.netstream then 
	print("[SAM Breach Client] SAM netstream not available")
	return 
end

print("[SAM Breach Client] Loading client-side functions...")

-- Hook dla kolorowego tsay
sam.netstream.Hook("breach_tsay_display", function(data)
	local message = data.message
	local admin = data.admin
	
	-- Wyświetl kolorową wiadomość na środku ekranu
	local function DisplayTsayMessage()
		local scrW, scrH = ScrW(), ScrH()
		
		-- Tło wiadomości
		local bgColor = Color(0, 0, 0, 200)
		local textColor = Color(255, 255, 255, 255)
		local adminColor = Color(255, 100, 100, 255)
		
		-- Panel dla wiadomości
		local panel = vgui.Create("DPanel")
		panel:SetSize(scrW * 0.6, 120)
		panel:SetPos(scrW * 0.2, scrH * 0.3)
		panel:SetBackgroundColor(bgColor)
		
		-- Tytuł
		local titleLabel = vgui.Create("DLabel", panel)
		titleLabel:SetText("ADMIN MESSAGE")
		titleLabel:SetFont("DermaLarge")
		titleLabel:SetTextColor(adminColor)
		titleLabel:SizeToContents()
		titleLabel:SetPos(10, 10)
		
		-- Wiadomość
		local messageLabel = vgui.Create("DLabel", panel)
		messageLabel:SetText(message)
		messageLabel:SetFont("DermaDefaultBold")
		messageLabel:SetTextColor(textColor)
		messageLabel:SetWrap(true)
		messageLabel:SetAutoStretchVertical(true)
		messageLabel:SetPos(10, 40)
		messageLabel:SetWide(panel:GetWide() - 20)
		
		-- Admin info
		if admin then
			local adminLabel = vgui.Create("DLabel", panel)
			adminLabel:SetText("- " .. admin)
			adminLabel:SetFont("DermaDefault")
			adminLabel:SetTextColor(adminColor)
			adminLabel:SizeToContents()
			adminLabel:SetPos(panel:GetWide() - adminLabel:GetWide() - 10, panel:GetTall() - 25)
		end
		
		-- Animacja pojawiania się
		panel:SetAlpha(0)
		panel:AlphaTo(255, 0.5, 0, function()
			-- Automatyczne znikanie po 8 sekundach
			timer.Simple(8, function()
				if IsValid(panel) then
					panel:AlphaTo(0, 1, 0, function()
						if IsValid(panel) then
							panel:Remove()
						end
					end)
				end
			end)
		end)
		
		-- Dźwięk powiadomienia
		surface.PlaySound("buttons/button15.wav")
	end
	
	DisplayTsayMessage()
end)

print("[SAM Breach Client] Client functions loaded successfully")