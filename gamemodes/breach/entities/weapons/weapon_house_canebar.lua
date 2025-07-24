AddCSLuaFile()

SWEP.Category			= "Other"
SWEP.IconOverride 		= "vgui/hud/killicon/greg_icon"
SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true
SWEP.PrintName			= "House Canebar"	
SWEP.Base				= "weapon_base"
SWEP.Author				= "Opal, Bunny"
SWEP.Instructions		= "Left click, right click, reload."

SWEP.ViewModel			= "models/canebar/v_house_canebar.mdl"
SWEP.WorldModel			= "models/canebar/w_house_canebar.mdl"
SWEP.ViewModelFOV 		= 65
SWEP.HoldType 			= "melee"
SWEP.UseHands 			= true
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair		= true

SWEP.Slot					= 0
SWEP.SlotPos				= 1
SWEP.FiresUnderwater 		= true

SWEP.Primary.Ammo			= -1
SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Delay 			= 0.4
SWEP.Primary.Damage 		= 25

SWEP.Secondary.Ammo			= "none"
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
	
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false
SWEP.droppable			= false

SWEP.Holstered = false  -- Track holster state
SWEP.NextToggleTime = 0 -- Cooldown to prevent input issues

-- list.Add( "NPCUsableWeapons", { class = "weapon_house_canebar", title = SWEP.PrintName } )

function SWEP:Initialize()
	self:SetHoldType(self.HoldType) -- SetWeaponHoldType
end


function SWEP:PlayWeaponSound(snd)
	if (CLIENT) then return end
	self.Owner:EmitSound(snd)
end


function SWEP:Deploy()
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
	self:SetHoldType(self.HoldType) -- SetWeaponHoldType
end


function SWEP:PrimaryAttack()
	
	if self.Holstered then return end -- Prevent attacking while holstered

	local tr = {}
	tr.start = self.Owner:GetShootPos()
	tr.endpos = self.Owner:GetShootPos() + (self.Owner:GetAimVector() * 100) -- Increase range from 75 to 100
	tr.filter = self.Owner
	tr.mask = MASK_SHOT
	local trace = util.TraceLine(tr)
	
		-- Hit
		if (trace.Hit) then
			self.Weapon:SendWeaponAnim(ACT_VM_HITCENTER)
			bullet = {}
			bullet.Num    = 1
			bullet.Src    = self.Owner:GetShootPos()
			bullet.Dir    = self.Owner:GetAimVector()
			bullet.Spread = Vector(0, 0, 0)
			bullet.Tracer = 0
			bullet.Force  = 8
			bullet.Damage = self.Primary.Damage
			self.Owner:FireBullets( bullet )
			self.Weapon:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
			self.Owner:SetAnimation(PLAYER_ATTACK1)
				
		-- Miss
		else
			self.Weapon:EmitSound(Sound("weapons/iceaxe/iceaxe_swing1.wav"))
			self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
			self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
			timer.Simple(0, function()
			self.Owner:SetAnimation(PLAYER_ATTACK1)
			end)	
		end
		
	timer.Create("Idle", self:SequenceDuration(), 1, function() 
	if (!IsValid(self)) then 
		return 
	end 
			self:SendWeaponAnim( ACT_VM_IDLE ) 
	end )
end


function SWEP:SecondaryAttack()
	self:EmitSound(Sound("weapons/canebar/canebar_emit-0"..math.random(1,7)..".mp3"), 75, 100, 1, CHAN_VOICE)
end


if CLIENT then
    killicon.Add("weapon_house_canebar", "vgui/hud/killicon/greg_icon", Color(255, 255, 255, 255))
end


function SWEP:Think()
    if self.Owner:KeyPressed(IN_ZOOM) and CurTime() > self.NextToggleTime then
        self:ToggleHolster()
        self.NextToggleTime = CurTime() + 0.2 -- Add a short delay to prevent input issues
    end
end


function SWEP:ToggleHolster()
    self.Holstered = not self.Holstered

    if self.Holstered then
        self:SetHoldType("normal")
        if IsValid(self.Owner) and IsValid(self.Owner:GetViewModel()) then
            self.Owner:GetViewModel():SetNoDraw(true) -- Hide hands when holstered
        end
    else
        self:SetHoldType("melee") -- Arm raised when unholstered
        if IsValid(self.Owner) and IsValid(self.Owner:GetViewModel()) then
            self.Owner:GetViewModel():SetNoDraw(false) -- Show hands
        end
    end
end

function SWEP:Kill(victim, attacker, inflictor)
	local math_stuff = math.random(1,10)
	if math_stuff >= 7 then
    	attacker:EmitSound(Sound("weapons/canebar/ax_cane.mp3"), 75, 100, 1, CHAN_VOICE)
    end
end

hook.Add("OnNPCKilled", "WeaponKill_NPC", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end -- Ensure attacker is valid and a player

    local weapon = inflictor -- Assume inflictor is the weapon

    -- Check if the inflictor is our SWEP
    if IsValid(weapon) and weapon:GetClass() == "weapon_house_canebar" then
        weapon:Kill(victim, attacker, weapon)
        --print("[DEBUG] Kill registered with correct SWEP: " .. weapon:GetClass())

    -- If the inflictor isn't our SWEP, check the attacker's active weapon
    elseif IsValid(attacker:GetActiveWeapon()) and attacker:GetActiveWeapon():GetClass() == "weapon_house_canebar" then
        weapon = attacker:GetActiveWeapon()
        weapon:Kill(victim, attacker, weapon)
        --print("[DEBUG] Kill registered with active SWEP: " .. weapon:GetClass())
    else
        --print("[DEBUG] Kill ignored: Inflictor not our SWEP.")
    end
end)

hook.Add("PlayerDeath", "WeaponKill_Player", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end -- Ensure attacker is valid and a player

    local weapon = inflictor -- Assume inflictor is the weapon

    -- Check if the inflictor is our SWEP
    if IsValid(weapon) and weapon:GetClass() == "weapon_house_canebar" then
        weapon:Kill(victim, attacker, weapon)
        --print("[DEBUG] Kill registered with correct SWEP: " .. weapon:GetClass())

    -- If the inflictor isn't our SWEP, check the attacker's active weapon
    elseif IsValid(attacker:GetActiveWeapon()) and attacker:GetActiveWeapon():GetClass() == "weapon_house_canebar" then
        weapon = attacker:GetActiveWeapon()
        weapon:Kill(victim, attacker, weapon)
        --print("[DEBUG] Kill registered with active SWEP: " .. weapon:GetClass())
    else
        --print("[DEBUG] Kill ignored: Inflictor not our SWEP.")
    end
end) 