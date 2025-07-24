-- SCP-207 Client Module for SCP: Breach
-- Based on original SCP-207 addon by MrMarrant
-- Adapted for Breach gamemode

-- Global SCP-207 system
scp_207 = scp_207 or {}
SCP_207_CONFIG = SCP_207_CONFIG or {}

-- Screen resolution for overlay
SCP_207_CONFIG.ScrW = ScrW()
SCP_207_CONFIG.ScrH = ScrH()

-- Network strings (must match server)
SCP_207_CONFIG.TextToSendToServer = "SCP207_TextToServer"
SCP_207_CONFIG.StartOverlayEffect = "SCP207_StartOverlay"
SCP_207_CONFIG.RemoveOverlayEffect = "SCP207_RemoveOverlay"

-- Create the overlay for infected player
function scp_207.DisplayOverlay(ply)
    if (!IsValid(ply)) then return end
    if (ply.scp207_Overlay) then return end -- we don't want two overlay

    local OverlaySCP207 = vgui.Create("DImage")
    OverlaySCP207:SetImageColor(Color(60, 0, 0, 0))
    OverlaySCP207:SetSize(SCP_207_CONFIG.ScrW, SCP_207_CONFIG.ScrH)
    -- Use a simple red overlay since we might not have the original texture
    OverlaySCP207:SetImage("vgui/white")
    ply.scp207_Overlay = OverlaySCP207
end

-- Network receivers
net.Receive(SCP_207_CONFIG.TextToSendToServer, function ( )
    local TextToPrint = net.ReadString()
    LocalPlayer():ChatPrint( "[SCP-207] " .. TextToPrint )
end)

net.Receive(SCP_207_CONFIG.StartOverlayEffect, function ( )
    local ply = LocalPlayer()
    local IterationBySeconds = net.ReadUInt(12)

    scp_207.DisplayOverlay(ply)
    local saturation = 0
    local incrementSaturation = 250/IterationBySeconds

    timer.Create("Timer.scp207_StartOverlayEffect_"..ply:EntIndex(), 1, IterationBySeconds, function()
        if (!IsValid(ply)) then return end
        if (!ply.scp207_Overlay) then return end

        ply.scp207_Overlay:SetImageColor(Color(60, 0, 0, saturation))
        saturation = saturation + incrementSaturation
    end)
end)

net.Receive(SCP_207_CONFIG.RemoveOverlayEffect, function ( )
    local ply = LocalPlayer()
    if (timer.Exists("Timer.scp207_StartOverlayEffect_"..ply:EntIndex())) then
        timer.Remove("Timer.scp207_StartOverlayEffect_"..ply:EntIndex())
    end
    if (ply.scp207_Overlay) then
        ply.scp207_Overlay:Remove()
        ply.scp207_Overlay = nil
    end
end)

print("[BREACH] SCP-207 Client Module Loaded") 