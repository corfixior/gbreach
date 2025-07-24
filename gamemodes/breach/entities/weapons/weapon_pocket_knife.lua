AddCSLuaFile()

SWEP.Base = "weapon_base"
SWEP.PrintName = "Pocket Knife"
SWEP.Instructions = [[Compact folding knife for Scout D personnel.
Useful for cutting tape or self-defense.

LMB - Stab attack
RMB - Slash attack
R - Inspect]]

SWEP.Spawnable = false
SWEP.AdminSpawnable = true

-- Breach specific settings
SWEP.droppable = true
SWEP.teams = {2,3,5,6,7}

SWEP.ViewModel = "models/weapons/salat/reanim/c_s&wch0014.mdl"
SWEP.WorldModel = "models/weapons/w_knife_t.mdl"
SWEP.ViewModelFOV = 60
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 1
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

-- Animation sequences
SWEP.StabAnim = "stab"
SWEP.SlashAnim = "midslash1"
SWEP.InspectAnim = "inspect"
SWEP.DrawAnim = "draw"

-- Attack settings
SWEP.Distance = 50
SWEP.StabDamage = 10
SWEP.SlashDamage = 7

SWEP.Lang = nil

function SWEP:Initialize()
    if CLIENT then
        self.Lang = GetWeaponLang().POCKET_KNIFE
        if self.Lang then
            self.Author = self.Lang.author
            self.Contact = self.Lang.contact
            self.Purpose = self.Lang.purpose
            self.Instructions = self.Lang.instructions
        end
    end
    self:SetHoldType("knife")
    self.AnimCD = 0
end

function SWEP:Deploy()
    self:PlayAnim(self.DrawAnim)
    timer.Simple(0.45, function()
        if IsValid(self) then
            self:EmitSound("Weapon_Knife.Deploy")
        end
    end)
    return true
end

function SWEP:PrimaryAttack()
    if self.AnimCD > CurTime() then return end
    
    local attackCD = self:PlayAnim(self.StabAnim) - 0.2
    self.AnimCD = CurTime() + attackCD
    self:SetNextPrimaryFire(CurTime() + attackCD)
    self:SetNextSecondaryFire(CurTime() + attackCD)
    
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
    
    timer.Simple(0.1, function()
        if IsValid(self) then
            self:SendDamage(self.StabDamage)
        end
    end)
end

function SWEP:SecondaryAttack()
    if self.AnimCD > CurTime() then return end
    
    local attackCD = self:PlayAnim(self.SlashAnim) - 0.2
    self.AnimCD = CurTime() + attackCD
    self:SetNextPrimaryFire(CurTime() + attackCD)
    self:SetNextSecondaryFire(CurTime() + attackCD)
    
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
    
    timer.Simple(0.1, function()
        if IsValid(self) then
            self:SendDamage(self.SlashDamage)
        end
    end)
end

function SWEP:Reload()
    if self.AnimCD > CurTime() then return end
    
    local cd = self:PlayAnim(self.InspectAnim)
    self.AnimCD = CurTime() + cd
end

function SWEP:IsSoftEnt(ent)
    return ent:GetMaterialType() == MAT_FLESH
end

function SWEP:SendDamage(dmg)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    owner:LagCompensation(true)
    
    local trace = owner:GetEyeTrace()
    local hitPos = trace.HitPos
    local attackPos = owner:GetShootPos()
    local distance = hitPos:Distance(attackPos)
    
    if distance <= self.Distance then
        local ent = trace.Entity
        
        if IsValid(ent) and ent.TakeDamageInfo then
            local dmginfo = DamageInfo()
            dmginfo:SetDamage(dmg)
            dmginfo:SetAttacker(owner)
            dmginfo:SetInflictor(self)
            dmginfo:SetDamageType(DMG_SLASH)
            dmginfo:SetDamageForce(owner:GetAimVector() * 100)
            dmginfo:SetDamagePosition(hitPos)
            
            ent:TakeDamageInfo(dmginfo)
            
            if SERVER then
                if self:IsSoftEnt(ent) or ent:IsNPC() or ent:IsPlayer() or ent:IsRagdoll() then
                    owner:EmitSound("weapons/knife/knife_stab.wav", 65, math.random(90, 110))
                else
                    owner:EmitSound("weapons/knife/knife_hitwall1.wav", 65, math.random(90, 110))
                end
            end
        end
    else
        if SERVER then
            owner:EmitSound("Weapon_Knife.Slash", 65, math.random(90, 110))
        end
    end
    
    owner:LagCompensation(false)
end

function SWEP:PlayAnim(seqName)
    local vm = self:GetOwner():GetViewModel()
    if not IsValid(vm) then return 0 end
    
    local seq = vm:LookupSequence(seqName)
    if seq and seq > -1 then
        vm:SendViewModelMatchingSequence(seq)
        return vm:SequenceDuration(seq)
    else
        return 0
    end
end

function SWEP:Holster()
    return true
end

function SWEP:OnRemove()
    return true
end 