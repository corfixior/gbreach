AddCSLuaFile()

SWEP.Base 			= "weapon_scp_base"
SWEP.PrintName		= "SCP-1048-A"

SWEP.DrawCrosshair	= true
SWEP.HoldType 		= "melee"


function SWEP:Initialize()
	self:InitializeLanguage( "SCP_1048A" )

	self:SetHoldType( self.HoldType )

	sound.Add( {
		name = "attack",
		channel = CHAN_STATIC,
		volume = 1.0,
		level = 150,
		pitch = 100,
		sound = "scp/1048A/attack.ogg"	
	} )
end

SWEP.NextPrimary = 0

function SWEP:PrimaryAttack()
	if preparing or postround then return end
	if not IsFirstTimePredicted() then return end
	if self.NextPrimary > CurTime() then return end
	self.NextPrimary = CurTime() + 8
	if SERVER then
		self.Owner:EmitSound( "attack" )
		timer.Create( "Attack1048A", 0.4, 15, function()
			if !IsValid( self ) or !IsValid( self.Owner ) then
				timer.Destroy( "Attack1048A" )
				return
			end
			fent = ents.FindInSphere( self.Owner:GetPos(), 200 )
			for k, v in pairs( fent ) do
				if IsValid( v ) then
					if v:IsPlayer() then
						if v:GTeam() != TEAM_SPEC and (v:GTeam() != TEAM_SCP or v:GetNClass() == ROLES.ROLE_SCP035) then
							local oldHP = v:Health()
							v:TakeDamage( 2, self.Owner, self.Owner )
							-- Sprawdź czy gracz został zabity
							if oldHP > 0 and v:Health() <= 0 then
								-- Daj 150 HP za zabicie
								self.Owner:SetHealth( math.min( self.Owner:Health() + 150, self.Owner:GetMaxHealth() ) )
							end
						end
					else
						self:SCPDamageEvent( v, 5 )
					end
				end
			end
		end )
	end
end

function SWEP:DrawHUD()
	if disablehud == true then return end
	
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	local centerX = ScrW() / 2
	local centerY = ScrH() / 2
	local hudY = ScrH() - 150
	
	local hudWidth = 500
	local hudHeight = 120
	local hudX = centerX - hudWidth / 2
	
	-- Tło HUD (tak jak w SCP-069 i SCP-049)
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
	local titleW, titleH = surface.GetTextSize("SCP-1048-A")
	surface.SetTextPos(centerX - titleW / 2, hudY + 10)
	surface.DrawText("SCP-1048-A")
	
	-- Cooldown ataku
	local cooldownY = hudY + 60
	local barWidth = 200
	local barHeight = 8
	local barX = centerX - barWidth / 2
	
	-- LMB (Attack) Cooldown
	surface.SetTextColor(200, 200, 200, 255)
	surface.SetFont("DermaDefaultBold")
	surface.SetTextPos(barX, cooldownY - 15)
	surface.DrawText("LMB - Attack")
	
	surface.SetDrawColor(150, 150, 150, 255)
	surface.DrawOutlinedRect(barX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
	
	surface.SetDrawColor(40, 40, 40, 200)
	surface.DrawRect(barX, cooldownY, barWidth, barHeight)
	
	local attackCooldown = 0
	if self.NextPrimary and self.NextPrimary > CurTime() then
		attackCooldown = self.NextPrimary - CurTime()
	end
	
	if attackCooldown > 0 then
		local progress = 1 - (attackCooldown / 8)
		surface.SetDrawColor(255, 100, 100, 255)
		surface.DrawRect(barX, cooldownY, barWidth * progress, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 150, 150, 255)
		surface.SetTextPos(barX, cooldownY + 10)
		surface.DrawText(string.format("%.1fs", attackCooldown))
	else
		surface.SetDrawColor(100, 255, 100, 255)
		surface.DrawRect(barX, cooldownY, barWidth, barHeight)
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor(150, 255, 150, 255)
		surface.SetTextPos(barX, cooldownY + 10)
		surface.DrawText("READY")
	end
end