AddCSLuaFile()

SWEP.Base = "weapon_base"
SWEP.PrintName = "Döner Kebab Knife"
SWEP.Instructions = [[Professional chef's knife used for cutting döner kebab.
Sharp blade excellent for food preparation and self-defense.

LMB - Light cut (15-20 dmg)
RMB - Heavy stab (45 dmg, 80 backstab)
R - Inspect]]

SWEP.Spawnable = false
SWEP.AdminSpawnable = true

-- Breach specific settings
SWEP.droppable = true
SWEP.teams = {2,3,5,6,7} -- Scientists, Class D, MTF, etc

SWEP.ViewModel = "models/weapons/v_donerkebabknife.mdl"
SWEP.WorldModel = "models/weapons/w_donerkebabknife.mdl"
SWEP.ViewModelFOV = 77
SWEP.UseHands = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 2
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 1
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

-- Animation sequences
SWEP.StabAnim = "stab"
SWEP.SlashAnim = "midslash1"
SWEP.InspectAnim = "inspect"
SWEP.DrawAnim = "draw"

-- Attack settings (balanced for gamemode)
SWEP.Distance = 80
SWEP.LightDamageMin = 15
SWEP.LightDamageMax = 20
SWEP.HeavyDamage = 45
SWEP.BackstabDamage = 80 -- reduced from 195

SWEP.Lang = nil

function SWEP:Initialize()
    if CLIENT then
        self.Lang = GetWeaponLang().DONER_KNIFE
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
    
    local attackCD = self:PlayAnim(self.SlashAnim) - 0.2
    self.AnimCD = CurTime() + attackCD
    self:SetNextPrimaryFire(CurTime() + attackCD)
    self:SetNextSecondaryFire(CurTime() + attackCD)
    
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
    
    timer.Simple(0.1, function()
        if IsValid(self) then
            local damage = math.random(self.LightDamageMin, self.LightDamageMax)
            self:SendDamage(damage, DMG_SLASH)
        end
    end)
end

function SWEP:SecondaryAttack()
    if self.AnimCD > CurTime() then return end
    
    local attackCD = self:PlayAnim(self.StabAnim) - 0.2
    self.AnimCD = CurTime() + attackCD
    self:SetNextPrimaryFire(CurTime() + attackCD)
    self:SetNextSecondaryFire(CurTime() + attackCD)
    
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
    
    timer.Simple(0.1, function()
        if IsValid(self) then
            self:SendHeavyDamage()
        end
    end)
end

function SWEP:Reload()
    if self.AnimCD > CurTime() then return end
    
    local cd = self:PlayAnim(self.InspectAnim)
    self.AnimCD = CurTime() + cd
end

function SWEP:EntityFaceBack(ent)
    if not IsValid(ent) then return false end
    if not ent:IsPlayer() then return false end
    
    local angle = self:GetOwner():GetAngles().y - ent:GetAngles().y
    if angle < -180 then angle = 360 + angle end
    if angle > 180 then angle = angle - 360 end
    return math.abs(angle) <= 90
end

function SWEP:IsSoftEnt(ent)
    return ent:GetMaterialType() == MAT_FLESH
end

function SWEP:SendDamage(dmg, dmgType)
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
            dmginfo:SetDamageType(dmgType or DMG_SLASH)
            dmginfo:SetDamageForce(owner:GetAimVector() * 200)
            dmginfo:SetDamagePosition(hitPos)
            
            ent:TakeDamageInfo(dmginfo)
            
            if SERVER then
                if self:IsSoftEnt(ent) or ent:IsNPC() or ent:IsPlayer() or ent:IsRagdoll() then
                    owner:EmitSound("Weapon_Knife.Hit", 65, math.random(90, 110))
                else
                    owner:EmitSound("Weapon_Knife.HitWall", 65, math.random(90, 110))
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

function SWEP:SendHeavyDamage()
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
            local damage = self.HeavyDamage
            
            -- Check for backstab bonus
            if ent:IsPlayer() and self:EntityFaceBack(ent) then
                damage = self.BackstabDamage
            end
            
            local dmginfo = DamageInfo()
            dmginfo:SetDamage(damage)
            dmginfo:SetAttacker(owner)
            dmginfo:SetInflictor(self)
            dmginfo:SetDamageType(DMG_SLASH)
            dmginfo:SetDamageForce(owner:GetAimVector() * 300)
            dmginfo:SetDamagePosition(hitPos)
            
            ent:TakeDamageInfo(dmginfo)
            
            if SERVER then
                if self:IsSoftEnt(ent) or ent:IsNPC() or ent:IsPlayer() or ent:IsRagdoll() then
                    owner:EmitSound("Weapon_Knife.Stab", 65, math.random(90, 110))
                else
                    owner:EmitSound("Weapon_Knife.HitWall", 65, math.random(90, 110))
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
    
    -- Try to find sequence by name, fallback to basic animations
    local seq = vm:LookupSequence(seqName)
    if seq == -1 then
        -- Fallback animations
        if seqName == self.StabAnim then
            seq = vm:LookupSequence("stab") or ACT_VM_HITCENTER
        elseif seqName == self.SlashAnim then
            seq = vm:LookupSequence("slash") or ACT_VM_MISSCENTER
        elseif seqName == self.InspectAnim then
            seq = vm:LookupSequence("inspect") or ACT_VM_IDLE
        elseif seqName == self.DrawAnim then
            seq = vm:LookupSequence("draw") or ACT_VM_DRAW
        end
    end
    
    if seq and seq > -1 then
        vm:SendViewModelMatchingSequence(seq)
        return vm:SequenceDuration(seq)
    else
        -- Final fallback to basic weapon anims
        if seqName == self.StabAnim then
            self:SendWeaponAnim(ACT_VM_HITCENTER)
        elseif seqName == self.SlashAnim then
            self:SendWeaponAnim(ACT_VM_MISSCENTER)
        elseif seqName == self.DrawAnim then
            self:SendWeaponAnim(ACT_VM_DRAW)
        else
            self:SendWeaponAnim(ACT_VM_IDLE)
        end
        return 1.0
    end
end

function SWEP:Holster()
    return true
end

function SWEP:OnRemove()
    return true
end