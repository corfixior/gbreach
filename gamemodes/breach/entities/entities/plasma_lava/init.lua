-- SCP 313, A representation of a paranormal object on a fictional series on the game Garry's Mod.
-- Copyright (C) 2023  MrMarrant aka BIBI.

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

AddCSLuaFile("shared.lua")
include("shared.lua")

--TODO : Certains ne sont pas enflammer, j'ai pas vraiment trouver la raison qui provoquait ça, hormis quand on en spawn vraiment beaucoup à la suite.
local WaterLevelList = {
	1,
	2,
	3
}

function ENT:Initialize()
	self:SetModel( "models/hunter/tubes/circle2x2.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS ) 
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMaterial( "models/props_lab/Tank_Glass001" )
	self:Ignite(999)
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	timer.Simple( 0.5, function() if (self:IsValid()) then self:SetMoveType(MOVETYPE_NONE) end end )
	timer.Simple( 30, function() if (self:IsValid()) then self:Remove() end end )
end

function ENT:Think()
	if (!self:IsOnGround() and self:GetMoveType() == MOVETYPE_NONE) then -- TODO : A revoir pour ceux qui ne sont pas sur le sol
		--self:Remove()
	end
	if (table.HasValue( WaterLevelList, self:WaterLevel() )) then
		self:Extinguish()
	end
end

hook.Add( "ShouldCollide", "ShouldCollide.PlasmaLava", function( ent1, ent2 )
	if ((ent1:GetClass() == "plasma_lava" and ent2:GetClass() == "plasma_lava") ) then return false end
end ) 