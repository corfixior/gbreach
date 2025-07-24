AddCSLuaFile()

SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-3199"

local BiteSounds = {
    "SCP3199Bite1",
    "SCP3199Bite2",
    "SCP3199Bite3",
    "SCP3199Bite4"
}

local VomitSound = Sound("SCP3199Vomit")
local RoarSound = Sound("SCP3199scream")
local XplodeSound = Sound("SCP3199Corrosion")

SWEP.Category = "SCP Sweps"
SWEP.Instructions = "Primary: Bite\nSecondary: Corrosive Spit \nReload: Roar"
SWEP.Author = "PapuMaster and Bombón Asesino"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Slot = 3
SWEP.SlotPos = 1

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = "" 
SWEP.WorldModel = ""
SWEP.HoldType = "knife"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Range = 72

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
    self:InitializeLanguage("SCP_3199")
    self:SetHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()
    if CurTime() < self:GetNextPrimaryFire() then return end
    self:SetNextPrimaryFire(CurTime() + 0.8)
    
    local ply = self.Owner
    if not IsValid(ply) then return end
    
    ply:DoAnimationEvent(ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE)
    ply:EmitSound(BiteSounds[math.random(#BiteSounds)])

    local tr = util.TraceHull({
        start = ply:GetShootPos(),
        endpos = ply:GetShootPos() + ply:GetAimVector() * self.Primary.Range,
        filter = ply,
        mins = Vector(-15, -15, -15),
        maxs = Vector(15, 15, 15)
    })

    local HitSounds = {
        "npc/fast_zombie/claw_strike1.wav",
        "npc/fast_zombie/claw_strike2.wav",
        "npc/fast_zombie/claw_strike3.wav",
    }
    
    if tr.Hit and IsValid(tr.Entity) then
        if SERVER then
            -- Don't damage other SCPs
            if tr.Entity:IsPlayer() then
                		if tr.Entity:GTeam() ~= TEAM_SCP or tr.Entity:GetNClass() == ROLES.ROLE_SCP035 then
                    local dmg = DamageInfo()
                    dmg:SetDamage(math.random(54, 62))
                    dmg:SetAttacker(ply)
                    dmg:SetInflictor(self)
                    dmg:SetDamageType(DMG_SLASH)
                    tr.Entity:TakeDamageInfo(dmg)
                    ply:ViewPunch(Angle(math.random(-3, 1), math.random(-3, 2), 0))
                end
            else
                -- Use standard SCP damage system for non-players
                self:SCPDamageEvent(tr.Entity, math.random(54, 62))
                ply:ViewPunch(Angle(math.random(-3, 1), math.random(-3, 2), 0))
            end
            
            if tr.Entity:IsPlayer() or tr.Entity:IsNPC() then
                self.Owner:EmitSound(HitSounds[math.random(#HitSounds)], 75, math.random(115, 120), 0.5)
            end
        end
    end
end

function SWEP:DealAoeDamage(dmgtype, dmgamt, src, range)
    local dmg = DamageInfo()
    dmg:SetDamageType(dmgtype)
    dmg:SetAttacker(self.Owner)
    dmg:SetInflictor(self)
    dmg:SetDamage(dmgamt)

    if SERVER then
        for _, ent in pairs(ents.FindInSphere(src, range)) do
            if ent ~= self.Owner then
                -- Don't damage other SCPs
                if ent:IsPlayer() then
                    		if ent:GTeam() ~= TEAM_SCP or ent:GetNClass() == ROLES.ROLE_SCP035 then
                        ent:TakeDamageInfo(dmg)
                        ent:ScreenFade( SCREENFADE.IN, Color( 125, 145, 50, 128 ), 1, 0 )
                    end
                else
                    -- Use standard SCP damage system for non-players
                    self:SCPDamageEvent(ent, dmgamt)
                end
            end
        end
    end
end

function SWEP:CorroSpit(dmg, decay, acc)
    if SERVER then
        local ent = ents.Create("prop_physics")
        if not IsValid(ent) then return end
        ent:SetModel("models/grub_nugget_large.mdl")
        ent:SetMaterial("models/spitball/spitball")
        ent:SetModelScale(1.2)
        ent:SetPos(self.Owner:EyePos() + self.Owner:GetAimVector() * 20)
        ent:SetAngles(self.Owner:EyeAngles())
        ent:Spawn()

        local phys = ent:GetPhysicsObject()
        if not IsValid(phys) then ent:Remove() return end
        phys:ApplyForceCenter(self.Owner:GetAimVector() * 3000 + VectorRand() * acc)
       
        ParticleEffectAttach("corro_blob", 1, ent, 1)

        ent:AddCallback("PhysicsCollide", function()
            if not IsValid(self) or not IsValid(self.Owner) then return end
            local pos = ent:GetPos()
            self:DealAoeDamage(DMG_NERVEGAS, math.random(22, 24), pos, 60)
            ParticleEffect("eml_generic_crsv", pos, Angle(0, 0, 0), self.Owner)
            ent:EmitSound(XplodeSound)
            ent:Fire("break", "", 0.01)
        end)

        timer.Simple(3, function()
            if IsValid(ent) then
                if not IsValid(self) or not IsValid(self.Owner) then return end
                local pos = ent:GetPos()
                self:DealAoeDamage(DMG_NERVEGAS, math.random(22, 24), pos, 60)
                ParticleEffect("eml_generic_crsv", pos, Angle(0, 0, 0), self.Owner)
                ent:EmitSound(XplodeSound)
                ent:Fire("break", "", 0.01)
            end
        end)
        ent:SetPhysicsAttacker(self.Owner, decay)
        SafeRemoveEntityDelayed(ent, decay)
    end
end

function SWEP:SecondaryAttack()
    if CurTime() < self:GetNextSecondaryFire() then return end
    self:SetNextSecondaryFire(CurTime() + 30)
    self:SetNextPrimaryFire(CurTime() + 1)

    local ply = self.Owner
    if not IsValid(ply) then return end

    ply:EmitSound(VomitSound)
    ply:DoAnimationEvent(ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE)
    ply:ViewPunch(Angle(math.random(-2, 2), 0, 0))

    if SERVER then
        self:CorroSpit(25, 10, 1)
    end
end

function SWEP:Reload()
    if CurTime() < (self.NextRoar or 0) then return end
    self.NextRoar = CurTime() + 60 

    local ply = self.Owner

    if not IsValid(ply) then return end

    ply:DoAnimationEvent(ACT_GMOD_TAUNT_LAUGH)

    if SERVER then
        ply:ViewPunch(Angle(math.random(-1.5, -2), 0, 0))

        ply:Freeze(true)
        ply:EmitSound(RoarSound)
        self.IsSCREAMING  = true 

        -- Find closest non-SCP player and damage them
        local closestPlayer = nil
        local closestDistance = math.huge
        
        for _, target in pairs(player.GetAll()) do
            		if IsValid(target) and target:Alive() and target ~= ply and (target:GTeam() ~= TEAM_SCP or target:GetNClass() == ROLES.ROLE_SCP035) and target:GTeam() ~= TEAM_SPEC then
                local distance = ply:GetPos():DistToSqr(target:GetPos())
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = target
                end
            end
        end
        
        if IsValid(closestPlayer) then
            local dmg = DamageInfo()
            dmg:SetDamage(1)
            dmg:SetAttacker(ply)
            dmg:SetInflictor(self)
            dmg:SetDamageType(DMG_SONIC)
            closestPlayer:TakeDamageInfo(dmg)
        end

        timer.Simple(2.2, function()
                ply:Freeze(false)
                ply:ViewPunch(Angle(math.random(1, 1.5), 0, 0))
                self.IsSCREAMING = false
        end)
    end
end

-- HUD w stylu SCP-069
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
    
    -- Tło HUD
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
    local titleW, titleH = surface.GetTextSize("SCP-3199")
    surface.SetTextPos(centerX - titleW / 2, hudY + 10)
    surface.DrawText("SCP-3199")
    
    -- Cooldowny
    local cooldownY = hudY + 60
    local barWidth = 140
    local barHeight = 8
    local spacing = 20
    local totalWidth = barWidth * 3 + spacing * 2
    local startX = centerX - totalWidth / 2
    
    -- LMB (Bite) Cooldown
    local lmbBarX = startX
    surface.SetTextColor(200, 200, 200, 255)
    surface.SetFont("DermaDefaultBold")
    surface.SetTextPos(lmbBarX, cooldownY - 15)
    surface.DrawText("LMB - Bite")
    
    surface.SetDrawColor(150, 150, 150, 255)
    surface.DrawOutlinedRect(lmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
    
    surface.SetDrawColor(40, 40, 40, 200)
    surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
    
    local biteCooldown = 0
    if self:GetNextPrimaryFire() > CurTime() then
        biteCooldown = self:GetNextPrimaryFire() - CurTime()
    end
    
    if biteCooldown > 0 then
        local progress = 1 - (biteCooldown / 0.8)
        surface.SetDrawColor(255, 100, 100, 255)
        surface.DrawRect(lmbBarX, cooldownY, barWidth * progress, barHeight)
        
        surface.SetFont("DermaDefault")
        surface.SetTextColor(255, 150, 150, 255)
        surface.SetTextPos(lmbBarX, cooldownY + 10)
        surface.DrawText(string.format("%.1fs", biteCooldown))
    else
        surface.SetDrawColor(100, 255, 100, 255)
        surface.DrawRect(lmbBarX, cooldownY, barWidth, barHeight)
        
        surface.SetFont("DermaDefault")
        surface.SetTextColor(150, 255, 150, 255)
        surface.SetTextPos(lmbBarX, cooldownY + 10)
        surface.DrawText("READY")
    end
    
    -- RMB (Corrosive Spit) Cooldown
    local rmbBarX = startX + barWidth + spacing
    surface.SetTextColor(200, 200, 200, 255)
    surface.SetFont("DermaDefaultBold")
    surface.SetTextPos(rmbBarX, cooldownY - 15)
    surface.DrawText("RMB - Spit")
    
    surface.SetDrawColor(150, 150, 150, 255)
    surface.DrawOutlinedRect(rmbBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
    
    surface.SetDrawColor(40, 40, 40, 200)
    surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
    
    local spitCooldown = 0
    if self:GetNextSecondaryFire() > CurTime() then
        spitCooldown = self:GetNextSecondaryFire() - CurTime()
    end
    
    if spitCooldown > 0 then
        local progress = 1 - (spitCooldown / 30)
        surface.SetDrawColor(125, 145, 50, 255)
        surface.DrawRect(rmbBarX, cooldownY, barWidth * progress, barHeight)
        
        surface.SetFont("DermaDefault")
        surface.SetTextColor(150, 200, 100, 255)
        surface.SetTextPos(rmbBarX, cooldownY + 10)
        surface.DrawText(string.format("%.0fs", spitCooldown))
    else
        surface.SetDrawColor(100, 255, 100, 255)
        surface.DrawRect(rmbBarX, cooldownY, barWidth, barHeight)
        
        surface.SetFont("DermaDefault")
        surface.SetTextColor(150, 255, 150, 255)
        surface.SetTextPos(rmbBarX, cooldownY + 10)
        surface.DrawText("READY")
    end
    
    -- R (Roar) Cooldown
    local roarBarX = startX + (barWidth + spacing) * 2
    surface.SetTextColor(200, 200, 200, 255)
    surface.SetFont("DermaDefaultBold")
    surface.SetTextPos(roarBarX, cooldownY - 15)
    surface.DrawText("R - Roar")
    
    surface.SetDrawColor(150, 150, 150, 255)
    surface.DrawOutlinedRect(roarBarX - 2, cooldownY - 2, barWidth + 4, barHeight + 4)
    
    surface.SetDrawColor(40, 40, 40, 200)
    surface.DrawRect(roarBarX, cooldownY, barWidth, barHeight)
    
    local roarCooldown = 0
    if self.NextRoar and self.NextRoar > CurTime() then
        roarCooldown = self.NextRoar - CurTime()
    end
    
    if roarCooldown > 0 then
        local progress = 1 - (roarCooldown / 6)
        surface.SetDrawColor(255, 165, 0, 255)
        surface.DrawRect(roarBarX, cooldownY, barWidth * progress, barHeight)
        
        surface.SetFont("DermaDefault")
        surface.SetTextColor(255, 200, 100, 255)
        surface.SetTextPos(roarBarX, cooldownY + 10)
        surface.DrawText(string.format("%.0fs", roarCooldown))
    else
        surface.SetDrawColor(100, 255, 100, 255)
        surface.DrawRect(roarBarX, cooldownY, barWidth, barHeight)
        
        surface.SetFont("DermaDefault")
        surface.SetTextColor(150, 255, 150, 255)
        surface.SetTextPos(roarBarX, cooldownY + 10)
        surface.DrawText("READY")
    end
end

function SWEP:Holster()
    if SERVER and IsValid(self.Owner) then
        if self.IsSCREAMING then return end
    end
    return true
end

function SWEP:OnRemove()
    -- Cleanup jeśli potrzebny
end