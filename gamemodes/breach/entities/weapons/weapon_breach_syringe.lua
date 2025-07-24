AddCSLuaFile()

SWEP.DrawAmmo = true
SWEP.DrawCrosshair = false
SWEP.ViewModelFOV = 60
SWEP.UseHands = true

SWEP.PrintName = "Medical Syringe"
SWEP.Slot = 5
SWEP.SlotPos = 2
SWEP.Author = "Darky (Modified for Breach)"
SWEP.Instructions = "LMB - Heal yourself/others (+15 HP + regen). RMB - Inject deadly poison (10 DMG + poison)"

-- Breach specific settings
SWEP.droppable = true
SWEP.teams = {2,3,5,6,7,8} -- Scientists, Class D, MTF, CI, GOC, but not SCP

SWEP.Spawnable = false
SWEP.AdminSpawnable = true
SWEP.Category = "Breach Medical"

SWEP.ViewModel = "models/weapons/darky_m/c_syringe_v2.mdl"
SWEP.WorldModel = "models/weapons/darky_m/w_syringe_v2.mdl"

SWEP.HealAmount = 15
SWEP.RegenAmount = 20
SWEP.InitialDamage = 10 -- Initial damage on injection
SWEP.PoisonDamage = 1   -- Damage per tick

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 1  -- Only 1 use total
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Syringes"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "slam"

SWEP.Insert = 0
SWEP.IdleTimer = CurTime()
SWEP.InsertTimer = CurTime()

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_DRAW)
    self.IdleTimer = CurTime() + self:GetOwner():GetViewModel():SequenceDuration()
    return true
end

function SWEP:Holster()
    self.Insert = 0
    self.IdleTimer = CurTime()
    self.InsertTimer = CurTime()
    return true
end

function SWEP:PrimaryAttack()
    local Owner = self:GetOwner()
    if Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then return end
    if self.Insert != 0 then return end

    Owner:DoAnimationEvent(ACT_HL2MP_GESTURE_RELOAD_PISTOL)
    if CLIENT then return end
    local CT = CurTime()

    self:SendWeaponAnim(ACT_VM_THROW)
    self.Insert = 1
    self.InsertTimer = CT + Owner:GetViewModel():SequenceDuration()
    self.SoundTimer = CT + 0.3
end

function SWEP:SecondaryAttack()
    local Owner = self:GetOwner()
    if Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then return end
    if self.Insert != 0 then return end

    local Traced = self:CheckTrace()

    if IsValid(Traced) and Traced:IsPlayer() then
        -- Block Security Droid from being poisoned
        if Traced:GetNClass() == ROLES.ROLE_SECURITY_DROID then
            if SERVER then
                Owner:PrintMessage(HUD_PRINTTALK, "[SYRINGE] ERROR: Biological agents incompatible with android systems!")
                Owner:EmitSound("buttons/button10.wav", 50, 50)
            end
            return
        end

        -- RMB ONLY DAMAGES - inject deadly poison IMMEDIATELY!
        Owner:DoAnimationEvent(ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND)
        if CLIENT then return end
        
        -- Poison immediately without waiting for animation
        self:Poison(Traced)
        
        -- Still play animation and sound
        self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
        Owner:EmitSound("npc/headcrab_poison/ph_hiss1.wav")
        
        self.IdleTimer = CurTime() + Owner:GetViewModel():SequenceDuration()
    end
end

function SWEP:CheckTrace()
    local Owner = self:GetOwner()
    Owner:LagCompensation(true)

    local Trace = util.TraceLine({
        start = Owner:GetShootPos(),
        endpos = Owner:GetShootPos() + Owner:GetAimVector() * 64,
        filter = Owner
    })

    Owner:LagCompensation(false)

    return Trace.Entity
end

function SWEP:Heal(target)
    local Owner = self:GetOwner()
    self.Insert = 0
    self.IdleTimer = CurTime()
    Owner:RemoveAmmo(1, self.Primary.Ammo)
    target:SetHealth(math.min(target:GetMaxHealth(), target:Health() + self.HealAmount))

    target.DHPRegen = (target.DHPRegen and target.DHPRegen or 0) + self.RegenAmount
    target.LastDHPRegen = CurTime()
    if not DHPRegenList then DHPRegenList = {} end
    DHPRegenList[target] = true

    if IsValid(target) and target:IsPlayer() then
        target:PrintMessage(HUD_PRINTTALK, "[MEDICAL] You received healing injection (+15 HP + regen)")
    end

    if Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
        Owner:StripWeapon("weapon_breach_syringe")
    end
end

function SWEP:Poison(target)
    local Owner = self:GetOwner()
    self.Insert = 0
    self.IdleTimer = CurTime()
    Owner:RemoveAmmo(1, self.Primary.Ammo)
    
    -- Initial damage
    local dmginfo = DamageInfo()
    dmginfo:SetDamage(self.InitialDamage)
    dmginfo:SetAttacker(Owner)
    dmginfo:SetInflictor(self)
    dmginfo:SetDamageType(DMG_DIRECT)
    
    target:TakeDamageInfo(dmginfo)

    -- Apply poison effect
    if not SyringePoisonList then SyringePoisonList = {} end
    target.SyringePoison = true
    target.SyringePoisonNext = CurTime() + 2 -- First tick in 2 seconds
    target.SyringePoisonAttacker = Owner
    SyringePoisonList[target] = true

    if IsValid(target) and target:IsPlayer() then
        target:PrintMessage(HUD_PRINTTALK, "[POISON] You were injected with deadly poison! (-10 HP + poison effect)")
    end
    
    if IsValid(Owner) and Owner:IsPlayer() then
        Owner:PrintMessage(HUD_PRINTTALK, "[SYRINGE] Deadly poison injected into " .. target:Nick())
    end

    if Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
        Owner:StripWeapon("weapon_breach_syringe")
    end
end

function SWEP:CancelHeal()
    self.Insert = 0
    self.IdleTimer = CurTime()
end

function SWEP:Think()
    local CT = CurTime()
    local Owner = self:GetOwner()

    if self.IdleTimer <= CT then
        self:IdleAnimation()
    end

    if CLIENT then return end

    if self.SoundTimer and self.SoundTimer <= CT then
        if self.Insert == 1 then
            Owner:EmitSound("items/medshot4.wav")  -- Heal sound
            self.SoundTimer = nil
        end
    end

    if self.Insert == 1 and self.InsertTimer <= CT then
        self:Heal(Owner)
    end
end

function SWEP:IdleAnimation()
    if SERVER and self.Insert == 0 then
        self:SendWeaponAnim(ACT_VM_IDLE)
        self.IdleTimer = CurTime() + self:GetOwner():GetViewModel():SequenceDuration()
    end
end 