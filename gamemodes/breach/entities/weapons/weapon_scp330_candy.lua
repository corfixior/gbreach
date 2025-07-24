-- SCP-330 Candy weapon dla gamemode Breach
-- Bazowany na oryginalnym kodzie candy_scp330 z kompatybilnością Breach

AddCSLuaFile()

SWEP.Base = "weapon_base"
SWEP.PrintName = "SCP-330 Candy"
SWEP.Author = "Breach Team"
SWEP.Category = "Breach SCP"
SWEP.Instructions = "Left click to eat candy, Right click to check your candies"

SWEP.Slot = 0
SWEP.SlotPos = 1
SWEP.Spawnable = false
SWEP.AdminOnly = true

SWEP.ViewModel = Model("models/weapons/scp_330/v_scp_330.mdl")
SWEP.WorldModel = Model("models/weapons/scp_330/w_scp_330.mdl")

SWEP.ViewModelFOV = 65
SWEP.HoldType = "slam"
SWEP.UseHands = true

-- Ammo settings
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false
SWEP.AutoSwitch = false

-- Cooldowns
SWEP.PrimaryCD = 1
SWEP.SecondaryCD = 2

-- Candy storage
SWEP.CandyPossessed = {}

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
    self:SetHoldType(self.HoldType)
    
    if not self.CandyPossessed then
        self.CandyPossessed = {}
    end
end

function SWEP:PrimaryAttack()
    if #self.CandyPossessed == 0 then return end
    
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    
    -- Get the last candy (newest)
    local candyIndex = #self.CandyPossessed
    local candyFlavor = self.CandyPossessed[candyIndex]
    
    -- Play animation
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    
    -- Calculate animation duration
    local viewModel = ply:GetViewModel()
    local animDuration = viewModel:SequenceDuration() / viewModel:GetPlaybackRate()
    
    -- Notify player
    if CLIENT then
        ply:ChatPrint("You eat the candy with the taste of " .. candyFlavor .. ".")
    end
    
    -- Set cooldown
    self:SetNextPrimaryFire(CurTime() + animDuration + self.PrimaryCD)
    
    -- Remove candy
    self.CandyPossessed[candyIndex] = nil
    
    -- Delay the removal/deploy animation
    timer.Simple(animDuration, function()
        if not IsValid(self) then return end
        
        if #self.CandyPossessed == 0 then
            -- No more candies, remove weapon
            if SERVER then
                self:Remove()
            end
        else
            -- Still have candies, play deploy animation
            self:PlayDeployAnimation()
        end
    end)
    
    -- Play eating sound
    ply:EmitSound("scp_330/consume_candy.mp3")
    
    -- Heal player by configured amount
    if SERVER then
        local healAmount = SCP330 and SCP330.Config and SCP330.Config.CandyHealAmount or 10
        local currentHP = ply:Health()
        local maxHP = ply:GetMaxHealth()
        local newHP = math.min(currentHP + healAmount, maxHP)
        local actualHeal = newHP - currentHP
        
        ply:SetHealth(newHP)
        
        -- Notify player about healing
        if actualHeal > 0 then
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-330] The candy healed you for " .. actualHeal .. " HP!")
        else
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-330] You are already at full health!")
        end
        
        SCP330:Log("Player " .. ply:Nick() .. " ate a " .. candyFlavor .. " candy and healed " .. actualHeal .. " HP (current: " .. newHP .. "/" .. maxHP .. ")")
    end
end

function SWEP:SecondaryAttack()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    
    if CLIENT then
        local candyCount = #self.CandyPossessed
        ply:ChatPrint("You have " .. candyCount .. " candies in your possession.")
        
        for i, flavor in ipairs(self.CandyPossessed) do
            ply:ChatPrint("Candy #" .. i .. ": " .. flavor)
        end
    end
    
    self:SetNextSecondaryFire(CurTime() + self.SecondaryCD)
end

function SWEP:OnDrop()
    -- Remove weapon when dropped (candies are consumed or lost)
    self:Remove()
end

function SWEP:Deploy()
    self:PlayDeployAnimation()
    return true
end

function SWEP:PlayDeployAnimation()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    
    local deploySpeed = GetConVarNumber("sv_defaultdeployspeed")
    
    -- Play deploy animation
    self:SendWeaponAnim(ACT_VM_DRAW)
    self:SetPlaybackRate(deploySpeed)
    
    -- Calculate animation duration
    local viewModel = ply:GetViewModel()
    local animDuration = viewModel:SequenceDuration() / viewModel:GetPlaybackRate()
    
    -- Set cooldowns
    self:SetNextPrimaryFire(CurTime() + animDuration + 0.1)
    self:SetNextSecondaryFire(CurTime() + animDuration)
    
    -- Play idle animation after deploy
    timer.Simple(animDuration, function()
        if not IsValid(self) then return end
        self:SendWeaponAnim(ACT_VM_IDLE)
    end)
end

function SWEP:Holster()
    -- Allow holstering
    return true
end

function SWEP:OnRemove()
    -- Clean up any timers or hooks if needed
end

-- Breach compatibility functions
if SERVER then
    function SWEP:AddCandy(flavor)
        if not self.CandyPossessed then
            self.CandyPossessed = {}
        end
        
        table.insert(self.CandyPossessed, flavor)
    end
    
    function SWEP:GetCandyCount()
        return #(self.CandyPossessed or {})
    end
    
    function SWEP:GetCandyFlavors()
        return self.CandyPossessed or {}
    end
end 