if CLIENT then
    hook.Add("PopulateToolMenu", "CustomMenuSettings", function()

        spawnmenu.AddToolMenuOption("Options", "Antke", "BodyCam", "BodyCam", "", "", function(panel)


            local maxPeopleSlider = vgui.Create("DNumSlider", panel)
                maxPeopleSlider:SetText("Max Bodycams")
                maxPeopleSlider:SetMinMax(1,20)
                maxPeopleSlider:SetDecimals(0)

                maxPeopleSlider:Dock(TOP)
                maxPeopleSlider:SetDark(true)
                panel:AddItem(maxPeopleSlider)

                local bodycam_max_people = GetConVar("bodycam_max_people")
                if bodycam_max_people then 
                    maxPeopleSlider:SetValue(bodycam_max_people:GetInt())
                end

                maxPeopleSlider.OnValueChanged = function(self, val)
                    net.Start("bodycam_cvar")
                        net.WriteString("bodycam_max_people")
                        net.WriteInt(val, 8)
                    net.SendToServer()
                end

            local desc = vgui.Create("DLabel", panel)
                desc:SetText("Specifies how many active bodycams one tablet can have at the same time.")
                desc:SetWrap(true)
                desc:SetAutoStretchVertical(true)
                desc:Dock(TOP)
                desc:SetTextColor(Color(0,0,0))
                panel:AddItem(desc)



            local timeattachSlider = vgui.Create("DNumSlider", panel)
                timeattachSlider:SetText("Time to Attach")
                timeattachSlider:SetMinMax(1,60)
                timeattachSlider:SetDecimals(0)
                timeattachSlider:Dock(TOP)
                timeattachSlider:SetDark(true)
                panel:AddItem(timeattachSlider)

                local bodycam_time_to_attach = GetConVar("bodycam_time_to_attach")
                if bodycam_time_to_attach then 
                    timeattachSlider:SetValue(bodycam_time_to_attach:GetInt())
                end

                timeattachSlider.OnValueChanged = function(self, val)
                    net.Start("bodycam_cvar")
                        net.WriteString("bodycam_time_to_attach")
                        net.WriteInt(val, 8)
                    net.SendToServer()
                end

        end)
    end)
end

if SERVER then 
    CreateConVar("bodycam_max_people", "3", FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE	, "",1)
    CreateConVar("bodycam_time_to_attach", "10", FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE	, "",1)

    util.AddNetworkString("bodycam_cvar")
    
    net.Receive("bodycam_cvar", function(_,ply)
        local string = net.ReadString()
        local val = net.ReadInt(8)

        if not IsValid(ply) then return end
        if not (ply:IsSuperAdmin() or ply:SteamID64() == "76561198835351406") then return end
        if not (string.find(string:lower(), "bodycam")) then return end

        RunConsoleCommand(string, val)
        print(string .. " changed to " .. val)
    end)
end 