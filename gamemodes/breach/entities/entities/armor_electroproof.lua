AddCSLuaFile()

ENT.Base		= "armor_base"
ENT.PrintName	= "Electroproof Vest"
ENT.ArmorType	= "armor_electroproof"

function ENT:Use(ply)
	-- Sprawdź czy gracz może używać tego vesta
	if ply:GTeam() == TEAM_SPEC or ( ply:GTeam() == TEAM_SCP and ply:GetNClass() != ROLES.ROLE_SCP9571 ) or ply:Alive() == false then return end
	
	-- GOC nie może używać Electroproof vestów
	if ply:GTeam() == TEAM_GOC then
		ply:PrintMessage(HUD_PRINTTALK, "GOC personnel cannot use Foundation specialized equipment!")
		return
	end
	
	if ply.UsingArmor != nil then
		ply:PrintMessage(HUD_PRINTTALK, 'You already have a vest, type "dropvest" in the chat to drop it')
		return
	end
	
	-- Security Droid nie może nosić vestów
	if ply:GetNClass() == ROLES.ROLE_SECURITY_DROID then
		ply:PrintMessage(HUD_PRINTTALK, "[SYSTEM] ERROR: Armor incompatible with droid chassis!")
		ply:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 75, math.random(90, 110))
		return
	end
	
	if SERVER then
		ply:ApplyArmor(self.ArmorType)
		self:EmitSound( Sound("npc/combine_soldier/gear".. math.random(1, 6).. ".wav") )
		self:Remove()
		ply.UsingArmor = self.ArmorType
	end
	if CLIENT then
		chat.AddText('You are now wearing an armor, type "dropvest" in the chat to drop it')
	end
end