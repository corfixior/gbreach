AddCSLuaFile()

if SERVER then
	util.AddNetworkString( "BreachBroomSweep" )
	util.AddNetworkString( "BreachBroomCleanEXP" )
	
	-- Handle EXP for cleaning
	net.Receive("BreachBroomCleanEXP", function(len, ply)
		if not IsValid(ply) or not ply:Alive() then return end
		if not ply:HasWeapon("weapon_broom") then return end
		
		-- Give EXP for cleaning
		if ply.AddExp then
			ply:AddExp(1) -- 1 EXP per cleaning action
		end
	end)
else -- CLIENT
	net.Receive("BreachBroomSweep",function()
		local ply = LocalPlayer()
		local wep = ply:GetActiveWeapon()
		if IsValid( wep ) and wep:GetClass() == "weapon_broom" then
			wep:PrimaryAttack(true)
		end
	end)
end

if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID("breach/wep_broom")
	SWEP.BounceWeaponIcon = false
end

SWEP.Base = "weapon_base"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.PrintName = "Broom"
SWEP.Author = "Breach Team"
SWEP.Instructions = "Hold left click to sweep decals and clean the facility."
SWEP.ViewModel = "models/props_c17/pushbroom.mdl"
SWEP.WorldModel = "models/props_c17/pushbroom.mdl"
SWEP.HoldType = "passive"

SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.Ammo = "none"

SWEP.Slot = 0
SWEP.SlotPos = 6

-- Breach gamemode integration
SWEP.droppable = true
SWEP.teams = {TEAM_SCI}

SWEP.ViewModelDefPos = Vector(2,25,30) -- viewmodel
SWEP.ViewModelDefAng = Vector(22,12,140)
SWEP.MoveToPos = Vector(2,25,30)
SWEP.MoveToAng = Vector(45,20,150)

SWEP.Pos = Vector(-3,-3,3) -- worldmodel
SWEP.Ang = Angle(70, 180, 0)

CreateConVar("broom_clearamount", 2, FCVAR_ARCHIVE, "The amount of decals to wipe for Breach Broom SWEP" )

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	self:SetWeaponHoldType(self.HoldType)
	
	self.mul = 1
	self.sweepmul = 0.1
	self.sweep = false
	self.raise = false
	self.flip = false
end

function SWEP:PrimaryAttack(bool)
	if math.sin(CurTime()*5) > math.Rand(0.5,0.7) or bool then

		if SERVER then
			net.Start( "BreachBroomSweep" )
			net.Send( self.Owner )
		end
	
		local tr = self.Owner:GetEyeTrace()
		if self:GetOwner():GetPos():Distance(tr.HitPos) > 100 then return end
		
		-- Check if we hit a player for damage
		if SERVER and IsValid(tr.Entity) and tr.Entity:IsPlayer() then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage(1)
			dmginfo:SetAttacker(self.Owner)
			dmginfo:SetInflictor(self)
			dmginfo:SetDamageType(DMG_CLUB)
			dmginfo:SetDamageForce(self.Owner:GetAimVector() * 100)
			tr.Entity:TakeDamageInfo(dmginfo)
		end
		
		if CLIENT then
			-- Check if there are decals to clean (for EXP)
			local decalsFound = false
			local decalTrace = util.TraceLine({
				start = tr.HitPos + tr.HitNormal * 5,
				endpos = tr.HitPos - tr.HitNormal * 5,
				filter = self.Owner
			})
			
			-- Simple check if there might be decals (not perfect but works)
			if decalTrace.Hit then
				decalsFound = true
			end
			
			util.RemoveDecalsAt( tr.HitPos, 16, GetConVar("broom_clearamount"):GetInt(), false)
		
			if self.sweep ~= true then
				self.mul = self.mul - 0.5
				self.sweep = true
			else
				self.mul = self.mul + 0.5
				self.sweep = false
			end
			
			-- Send to server that we cleaned something (for EXP)
			if decalsFound then
				net.Start("BreachBroomCleanEXP")
				net.SendToServer()
			end
		end

		if IsValid(tr.Entity) then
			tr.Entity:RemoveAllDecals()
		end
		
		local info = EffectData();
		info:SetNormal( tr.HitNormal );
		for i=0, 4 do
			info:SetOrigin( tr.HitPos + VectorRand()*10 )
			info:SetScale(math.random( 0.01, 0.5))
			util.Effect( "WheelDust", info );
		end
		
		for k, v in pairs(ents.FindInSphere(tr.HitPos,math.random(45,64))) do 
			local phys = v:GetPhysicsObject()
			if IsValid(phys) then
				phys:ApplyForceCenter(self.Owner:GetForward()*math.random(20,50)*10)
			end
		end
	end
	self:SetNextPrimaryFire( CurTime() + 0.7 )
end

function SWEP:SecondaryAttack()
	-- No secondary attack
end

function SWEP:Deploy()
	self.mul = 0.7
	self.sweepmul = 0.1
	self.sweep = false
	self.raise = true
	
	self:SetNextPrimaryFire( CurTime() + 1 )
	self:SetNextSecondaryFire( CurTime() + 1 )
	return true
end

function SWEP:GetViewModelPosition(pos, ang)
	local vel = math.Clamp(self.Owner:GetVelocity():Length()/500000,0,100)
	
	if self.flip == true then
		if self.raise == true then
			self.mul = self.mul + 0.01*math.Rand(0.1,1)+vel
		else
			self.mul = self.mul + 0.000005*math.Rand(0.1,1)+vel
		end
		
		if self.mul > 1.05 then
			self.flip = false
			self.raise = false
		end
	else
		self.mul = self.mul - 0.000005*math.Rand(0.1,1)-vel
		if self.mul < 1 then
			self.flip = true
		end
	end
    
    --this is always applied
    local DefPos = self.ViewModelDefPos
    local DefAng = self.ViewModelDefAng
    
    if DefAng then
        ang = ang * 1
        ang:RotateAroundAxis (ang:Right(),         DefAng.x)
        ang:RotateAroundAxis (ang:Up(),         DefAng.y)
        ang:RotateAroundAxis (ang:Forward(),     DefAng.z)
    end

    if DefPos then
        local Right     = ang:Right()
        local Up         = ang:Up()
        local Forward     = ang:Forward()
    
        pos = pos + DefPos.x * Right
        pos = pos + DefPos.y * Forward
        pos = pos + DefPos.z * Up
    end
    
    --and some more
    local AddPos = self.MoveToPos - self.ViewModelDefPos
    local AddAng = self.MoveToAng - self.ViewModelDefAng
    
    if AddAng then
        ang = ang * 1
        ang:RotateAroundAxis (ang:Right(),         AddAng.x * self.mul)
        ang:RotateAroundAxis (ang:Up(),         AddAng.y * self.mul)
        ang:RotateAroundAxis (ang:Forward(),     AddAng.z * self.mul)
    end

    if AddPos then
        local Right     = ang:Right()
        local Up         = ang:Up()
        local Forward     = ang:Forward()
    
        pos = pos + AddPos.x * Right * self.mul
        pos = pos + AddPos.y * Forward * self.mul
        pos = pos + AddPos.z * Up * self.mul
    end
    
    return pos, ang
end

function SWEP:CreateWorldModel()
	if !self.WModel then
		self.WModel = ClientsideModel(self.WorldModel, RENDERGROUP_OPAQUE)
		self.WModel:SetNoDraw(true)
		self.WModel:SetBodygroup(1, 1)
	end
	return self.WModel
end

function SWEP:DrawWorldModel()
	local wm = self:CreateWorldModel()
	if self.Owner != NULL then
		local bone = self.Owner:LookupBone("ValveBiped.Bip01_L_Hand")
		local pos, ang = self.Owner:GetBonePosition(bone)
			
		if bone then
			ang:RotateAroundAxis(ang:Right(), self.Ang.p)
			ang:RotateAroundAxis(ang:Forward(), self.Ang.y)
			ang:RotateAroundAxis(ang:Up(), self.Ang.r)
			wm:SetRenderOrigin(pos + ang:Right() * self.Pos.x + ang:Forward() * self.Pos.y + ang:Up() * self.Pos.z)
			wm:SetRenderAngles(ang)
			wm:DrawModel()
			wm:SetModelScale( 0.8, 0 )
		end
	else
		wm:DrawModel()
	end
end

-- Dodaj do systemu językowego
if CLIENT then
	local function AddBroomLanguage()
		if LANG and LANG.english then
			LANG.english.WEAPON_BROOM = {
				name = "Broom",
				desc = "A janitor's trusty broom for cleaning the facility"
			}
		end
	end
	
	hook.Add("InitPostEntity", "BroomLanguage", AddBroomLanguage)
end 