AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "SCP-297"
ENT.Author = "AI Assistant"
ENT.Category = "SCP"
ENT.Spawnable = true
ENT.AdminSpawnable = true

-- Brak modelu - używamy niewidzialnego entity
ENT.Model = "models/hunter/blocks/cube025x025x025.mdl" -- Mały niewidzialny model

-- Wish-granting effects with their probabilities
local WISH_EFFECTS = {
    -- Positive effects (60% total)
    {
        name = "Health Boost",
        chance = 20,
        effect = function(player)
            player:SetHealth(math.min(player:GetMaxHealth(), player:Health() + 30))
            return "Twoje życzenie o lepszym zdrowiu zostało spełnione (+30 HP)."
        end
    },
    {
        name = "Speed Boost",
        chance = 10,
        effect = function(player)
            player:SetRunSpeed(player:GetRunSpeed() * 1.3)
            player:SetWalkSpeed(player:GetWalkSpeed() * 1.3)
            
            timer.Simple(30, function()
                if IsValid(player) then
                    player:SetRunSpeed(player:GetRunSpeed() / 1.3)
                    player:SetWalkSpeed(player:GetWalkSpeed() / 1.3)
                end
            end)
            
            return "Twoje życzenie o większej szybkości zostało spełnione (+30% prędkości na 30 sekund)."
        end
    },
    {
        name = "Armor Boost",
        chance = 10,
        effect = function(player)
            player:SetArmor(math.min(100, player:Armor() + 35))
            return "Twoje życzenie o lepszej ochronie zostało spełnione (+35 pancerza)."
        end
    },
    {
        name = "Ammo Refill",
        chance = 10,
        effect = function(player)
            local weapon = player:GetActiveWeapon()
            if IsValid(weapon) and weapon.Primary and weapon.Primary.Ammo then
                player:GiveAmmo(50, weapon.Primary.Ammo)
                return "Twoje życzenie o większej ilości amunicji zostało spełnione (+50 amunicji)."
            else
                player:SetHealth(math.min(player:GetMaxHealth(), player:Health() + 15))
                return "Nie masz broni, więc otrzymujesz zdrowie (+15 HP)."
            end
        end
    },
    {
        name = "Invisibility",
        chance = 10,
        effect = function(player)
            player:SetRenderMode(RENDERMODE_TRANSALPHA)
            player:SetColor(Color(255, 255, 255, 50))
            
            timer.Simple(15, function()
                if IsValid(player) then
                    player:SetRenderMode(RENDERMODE_NORMAL)
                    player:SetColor(Color(255, 255, 255, 255))
                end
            end)
            
            return "Twoje życzenie o niewidzialności zostało spełnione (15 sekund niewidzialności)."
        end
    },
    
    -- Negative effects (30% total)
    {
        name = "Health Drain",
        chance = 10,
        effect = function(player)
            local newHealth = math.max(5, player:Health() - 30)
            player:SetHealth(newHealth)
            return "Uważaj czego sobie życzysz... (-30 HP)."
        end
    },
    {
        name = "Slow Effect",
        chance = 10,
        effect = function(player)
            player:SetRunSpeed(player:GetRunSpeed() * 0.7)
            player:SetWalkSpeed(player:GetWalkSpeed() * 0.7)
            
            timer.Simple(20, function()
                if IsValid(player) then
                    player:SetRunSpeed(player:GetRunSpeed() / 0.7)
                    player:SetWalkSpeed(player:GetWalkSpeed() / 0.7)
                end
            end)
            
            return "Twoje życzenie obróciło się przeciwko tobie (-30% prędkości na 20 sekund)."
        end
    },
    {
        name = "Confusion",
        chance = 10,
        effect = function(player)
            player:ConCommand("pp_motionblur 1")
            player:ConCommand("pp_motionblur_addalpha 0.2")
            player:ConCommand("pp_motionblur_delay 0.05")
            player:ConCommand("pp_motionblur_drawalpha 0.4")
            
            timer.Simple(15, function()
                if IsValid(player) then
                    player:ConCommand("pp_motionblur 0")
                end
            end)
            
            return "Twoje życzenie wywołało dezorientację (15 sekund zawrotów głowy)."
        end
    },
    
    -- Neutral effects (10% total)
    {
        name = "Nothing",
        chance = 5,
        effect = function(player)
            return "Maszyna wydaje się nie reagować na twoje życzenie."
        end
    },
    {
        name = "Random Teleport",
        chance = 5,
        effect = function(player)
            -- Find random spawn point
            local spawnPoints = {}
            for _, ent in pairs(ents.FindByClass("info_player_*")) do
                table.insert(spawnPoints, ent:GetPos())
            end
            
            if #spawnPoints > 0 then
                local randomPos = spawnPoints[math.random(#spawnPoints)]
                player:SetPos(randomPos)
                return "Twoje życzenie o zmianie miejsca zostało spełnione (teleportacja)."
            else
                return "Maszyna próbowała cię teleportować, ale coś poszło nie tak."
            end
        end
    }
}

function ENT:Initialize()
    self:SetModel(self.Model)
    
    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        
        -- Make it immovable
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(false)
            phys:Sleep()
        end
        
        self.NextUse = 0
        self.UsesLeft = 10 -- Machine has limited uses per round
        
        print("[SCP-297] Wish-granting machine initialized!")
    end
end

function ENT:Use(activator, caller, type, value)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if activator:GTeam() == TEAM_SPEC or not activator:Alive() then return end
    
    if SERVER then
        if self.NextUse > CurTime() then
            activator:PrintMessage(HUD_PRINTTALK, "SCP-297: Maszyna się regeneruje. Spróbuj za " .. math.ceil(self.NextUse - CurTime()) .. " sekund.")
            return
        end
        
        if self.UsesLeft <= 0 then
            activator:PrintMessage(HUD_PRINTTALK, "SCP-297: Maszyna wydaje się być pusta i nie reaguje.")
            return
        end
        
        self:GrantWish(activator)
    end
end

function ENT:GrantWish(player)
    -- Set cooldown
    self.NextUse = CurTime() + 60 -- 1 minute cooldown
    self.UsesLeft = self.UsesLeft - 1
    
    -- Sound effect
    self:EmitSound("ambient/machines/vending_machine_hum_loop1.wav", 70, 100)
    timer.Simple(1.5, function()
        if IsValid(self) then
            self:EmitSound("buttons/button4.wav", 70, 100)
        end
    end)
    
    -- Select effect based on probabilities
    local totalChance = 0
    for _, effect in pairs(WISH_EFFECTS) do
        totalChance = totalChance + effect.chance
    end
    
    local roll = math.random(1, totalChance)
    local currentChance = 0
    local selectedEffect = nil
    
    for _, effect in pairs(WISH_EFFECTS) do
        currentChance = currentChance + effect.chance
        if roll <= currentChance then
            selectedEffect = effect
            break
        end
    end
    
    -- Apply effect
    timer.Simple(2, function()
        if IsValid(player) and IsValid(self) and selectedEffect then
            local message = selectedEffect.effect(player)
            player:PrintMessage(HUD_PRINTTALK, "SCP-297: " .. message)
            
            -- Play appropriate sound based on effect type
            if string.find(selectedEffect.name, "Health Boost") or 
               string.find(selectedEffect.name, "Speed Boost") or 
               string.find(selectedEffect.name, "Armor Boost") then
                player:EmitSound("items/medshot4.wav", 70, 100)
            elseif string.find(selectedEffect.name, "Health Drain") or
                   string.find(selectedEffect.name, "Slow Effect") or
                   string.find(selectedEffect.name, "Confusion") then
                player:EmitSound("ambient/energy/zap9.wav", 70, 100)
            end
            
            -- Visual effect
            local effectData = EffectData()
            effectData:SetOrigin(player:GetPos() + Vector(0, 0, 30))
            effectData:SetScale(1)
            util.Effect("cball_bounce", effectData)
        end
    end)
end

-- Client rendering
if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
    
    function ENT:DrawTranslucent()
        local pos = self:GetPos()
        local plyPos = LocalPlayer():GetPos()
        local distance = plyPos:Distance(pos)
        
        if distance < 200 then
            local screenPos = pos:ToScreen()
            if screenPos.visible then
                -- Enhanced holographic effect
                local pulse = math.sin(CurTime() * 3) * 0.3 + 0.7
                local glowColor = Color(0, 200, 255, 255 * pulse)
                
                -- Main title with enhanced glow
                draw.SimpleTextOutlined(
                    "SCP-297",
                    "DermaLarge",
                    screenPos.x,
                    screenPos.y - 100,
                    glowColor,
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER,
                    3,
                    Color(0, 0, 0, 200)
                )
                
                -- Simple instruction text
                local alpha = math.max(0, 255 - (distance * 1.5))
                
                draw.SimpleTextOutlined(
                    "Maszyna spełniająca życzenia",
                    "DermaDefaultBold",
                    screenPos.x,
                    screenPos.y - 75,
                    Color(255, 255, 255, alpha),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER,
                    2,
                    Color(0, 0, 0, alpha * 0.8)
                )
                
                draw.SimpleTextOutlined(
                    "Naciśnij E aby wypowiedzieć życzenie",
                    "DermaDefault",
                    screenPos.x,
                    screenPos.y - 55,
                    Color(255, 255, 255, alpha),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER,
                    1,
                    Color(0, 0, 0, alpha * 0.6)
                )
                
                -- Status indicator
                local statusText = "• GOTOWA •"
                local statusColor = Color(100, 255, 100, alpha)
                
                if self.NextUse and self.NextUse > CurTime() then
                    statusText = "• REGENERACJA •"
                    statusColor = Color(255, 100, 100, alpha)
                end
                
                draw.SimpleTextOutlined(
                    statusText,
                    "DermaDefault",
                    screenPos.x,
                    screenPos.y - 35,
                    statusColor,
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER,
                    1,
                    Color(0, 0, 0, alpha * 0.6)
                )
            end
        end
    end
end

-- Sound effects on spawn
function ENT:PostEntityPaste()
    if SERVER then
        self:EmitSound("ambient/machines/vending_machine_hum_loop1.wav", 60, 100)
    end
end 