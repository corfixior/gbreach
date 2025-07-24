-- SCP 313, A representation of a paranormal object on a fictional series on the game Garry's Mod.
-- Copyright (C) 2023  MrMarrant aka BIBI.
-- Adapted for SCP: Breach gamemode

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

SCP_313 = {}
SCP_313_CONFIG = {}

-- Configuration
SCP_313_CONFIG.PercentEffect = CreateConVar("scp_313_percent_effect", 1.5, {FCVAR_PROTECTED, FCVAR_ARCHIVE}, "Percentage chance to trigger the effect of SCP-313.", 0, 100)
SCP_313_CONFIG.DisplayEffectClientSide = "SCP_313_CONFIG.DisplayEffectClientSide"

-- Network strings
if SERVER then
    util.AddNetworkString(SCP_313_CONFIG.DisplayEffectClientSide)
end

-- Functions
function SCP_313.IsArmed()
    local percent = SCP_313_CONFIG.PercentEffect:GetInt()
    assert(percent >= 0 and percent <= 100)
    return percent >= math.Rand(1, 100)
end

if SERVER then
    function SCP_313.DisplayEffectClientSide(effectName, pos)
        local effectdata = EffectData()
        effectdata:SetOrigin(pos)
        util.Effect(effectName, effectdata)
        net.Start(SCP_313_CONFIG.DisplayEffectClientSide)
            net.WriteVector(pos)
            net.WriteString(effectName)
        net.Broadcast()
    end
end

if CLIENT then
    net.Receive(SCP_313_CONFIG.DisplayEffectClientSide, function()
        local pos = net.ReadVector()
        local effectName = net.ReadString()
        local effectdata = EffectData()
        effectdata:SetOrigin(pos)
        util.Effect(effectName, effectdata)
    end)
end

-- Print initialization message
print("[BREACH] SCP-313 module loaded successfully") 