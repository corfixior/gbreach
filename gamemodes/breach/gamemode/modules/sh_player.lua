local mply = FindMetaTable( "Player" )

/*function mply:CLevelGlobal()
	local biggest = 1
	for k,wep in pairs(self:GetWeapons()) do
		if IsValid(wep) then
			if wep.clevel then
				if wep.clevel > biggest then
					biggest =  wep.clevel
				end
			end
		end
	end
	return biggest
end 

function mply:CLevel()
	local wep = self:GetActiveWeapon()
	if IsValid(wep) then
		if wep.clevel then
			return wep.clevel
		end
	end
	return 1
end*/

function mply:GetExp()
	if not self.GetNEXP then
		player_manager.RunClass( self, "SetupDataTables" )
	end
	if self.GetNEXP and self.SetNEXP then
		return self:GetNEXP()
	else
		ErrorNoHalt( "Cannot get the exp, GetNEXP invalid" )
		return 0
	end
end

function mply:GetLevel()
	if not self.GetNLevel then
		player_manager.RunClass( self, "SetupDataTables" )
	end
	if self.GetNLevel and self.SetNLevel then
		return self:GetNLevel()
	else
		ErrorNoHalt( "Cannot get the exp, GetNLevel invalid" )
		return 0
	end
end

function Sprint( ply )

end

if CLIENT then
	function mply:DropWeapon( class )
		net.Start( "DropWeapon" )
			net.WriteString( class )
		net.SendToServer()
	end

	function mply:SelectWeapon( class )
		if ( !self:HasWeapon( class ) ) then return end
		self.DoWeaponSwitch = self:GetWeapon( class )
	end
	
	hook.Add( "CreateMove", "WeaponSwitch", function( cmd )
		if !IsValid( LocalPlayer().DoWeaponSwitch ) then return end

		cmd:SelectWeapon( LocalPlayer().DoWeaponSwitch )

		if LocalPlayer():GetActiveWeapon() == LocalPlayer().DoWeaponSwitch then
			LocalPlayer().DoWeaponSwitch = nil
		end
	end )
end

function OnTick()
	if CLIENT then
		Sprint( LocalPlayer() )
	elseif SERVER then
		for k, v in pairs( player.GetAll() ) do
			Sprint( v )
		end
	end
end
