ENT.Type 			= "anim"
ENT.Base 			= "base_anim"
ENT.PrintName		= "C4"
ENT.Author			= "Hoff, zintegrowane przez SCP: Breach Team"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

-- Precache modeli i materiałów dla C4
if SERVER then
	util.PrecacheModel("models/hoff/weapons/c4/w_c4.mdl")
	util.PrecacheModel("models/hoff/weapons/c4/c_c4.mdl")
end

if CLIENT then
	-- Precache materiałów po stronie klienta
	Material("models/hoff/weapons/c4/c4_reticle.png")
end

hook.Add("Initialize","CreateBRC4Convars",function()
    if !ConVarExists("BR_C4_DoorSearchRadius") then
        CreateConVar("BR_C4_Infinite", 0, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Czy C4 powinno być nieskończone? 1 = nieskończone")
        CreateConVar("BR_C4_ThrowSpeed", 1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Jak długi jest czas pomiędzy rzutami C4?")
        CreateConVar("BR_C4_Magnitude", 175, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Jak silna jest eksplozja C4?")
        CreateConVar("BR_C4_KnockDoors", 0, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Czy C4 powinno wyważać drzwi?")
        CreateConVar("BR_C4_DoorKnockStrength", 500, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Jak mocno drzwi powinny być wyważone?")
        CreateConVar("BR_C4_DoorSearchRadius", 75, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Jak daleko powinny być wykrywane drzwi?")
    end
    if CLIENT then
        if !ConVarExists("BR_C4_RedLight") then
            CreateClientConVar("BR_C4_RedLight", 1, true)
        end
        local function funcCallback(CVar, PreviousValue, NewValue)
            net.Start("BR_C4_Convars_Change", true)
            net.WriteString(CVar)
            net.WriteFloat(tonumber(NewValue))
            net.SendToServer()
        end
        cvars.AddChangeCallback("BR_C4_Infinite", funcCallback)
        cvars.AddChangeCallback("BR_C4_ThrowSpeed", funcCallback)
        cvars.AddChangeCallback("BR_C4_Magnitude", funcCallback)
        cvars.AddChangeCallback("BR_C4_KnockDoors", funcCallback)
        cvars.AddChangeCallback("BR_C4_DoorKnockStrength", funcCallback)
        cvars.AddChangeCallback("BR_C4_DoorSearchRadius", funcCallback)
    end
end)

if SERVER then
    util.AddNetworkString("BR_C4_Convars_Change")

    net.Receive("BR_C4_Convars_Change", function(len, ply)
        if !ply:IsAdmin() then
            return
        end
        local cvar_name = net.ReadString()
        local cvar_val = net.ReadFloat()
        RunConsoleCommand(cvar_name, cvar_val)
    end)

elseif CLIENT then
    hook.Add("PopulateToolMenu", "AddBRC4SettingsPanel", function()
        spawnmenu.AddToolMenuOption("Utilities", "SCP: Breach", "BRC4SettingsPanel", "C4 Setup", "", "", function(cpanel)

            if !game.SinglePlayer() and !LocalPlayer():IsAdmin() then
                cpanel:CheckBox("C4 Red Light", "BR_C4_RedLight")
                return
            end

            cpanel:CheckBox("Infinite C4", "BR_C4_Infinite")
            cpanel:NumSlider("C4 Magnitude", "BR_C4_Magnitude", 1, 500, 0)
            cpanel:NumSlider("C4 Throw Speed", "BR_C4_ThrowSpeed", 0.1, 10, 2)
            cpanel:CheckBox("Knock Down Doors", "BR_C4_KnockDoors")
            cpanel:NumSlider("Door Knock Strength", "BR_C4_DoorKnockStrength", 100, 2500, 0)
            cpanel:NumSlider("Door Search Radius", "BR_C4_DoorSearchRadius", 1, 500, 0)
            cpanel:CheckBox("C4 Red Light", "BR_C4_RedLight")
        end)
    end)
end