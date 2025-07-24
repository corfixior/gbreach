AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Napoje i ich efekty
ENT.DrinkTypes = {
    ["full_heal"] = {
        name = "Full Health Restoration",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(255, 100, 100),
        price = 1,
        effects = function(ply)
            ply:SetHealth(ply:GetMaxHealth())
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] Full health restored!")
        end
    },
    ["random_heal"] = {
        name = "Random Health Potion",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(200, 150, 150),
        price = 1,
        effects = function(ply)
            local heal = math.random(1, 150)
            ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + heal))
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] Healed for " .. heal .. " HP!")
        end
    },
    ["invisibility"] = {
        name = "Invisibility Serum",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(100, 100, 255, 100),
        price = 1,
        effects = function(ply)
            ply:SetRenderMode(RENDERMODE_TRANSALPHA)
            ply:SetColor(Color(255, 255, 255, 0))
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] You are invisible for 60 seconds!")
            timer.Simple(60, function()
                if IsValid(ply) then
                    ply:SetRenderMode(RENDERMODE_NORMAL)
                    ply:SetColor(Color(255, 255, 255, 255))
                    ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] Invisibility wore off")
                end
            end)
        end
    },
    ["slowness"] = {
        name = "Heavy Liquid",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(50, 50, 50),
        price = 1,
        effects = function(ply)
            local oldRun = ply:GetRunSpeed()
            local oldWalk = ply:GetWalkSpeed()
            ply:SetRunSpeed(oldRun * 0.5)
            ply:SetWalkSpeed(oldWalk * 0.5)
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] You feel very heavy... -50% speed for 60 seconds")
            timer.Simple(60, function()
                if IsValid(ply) then
                    ply:SetRunSpeed(oldRun)
                    ply:SetWalkSpeed(oldWalk)
                    ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] You feel normal again")
                end
            end)
        end
    },
    ["near_death"] = {
        name = "Near Death Experience",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(255, 0, 0),
        price = 1,
        effects = function(ply)
            local newHP = math.max(1, math.floor(ply:GetMaxHealth() * 0.01))
            ply:SetHealth(newHP)
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] You barely survive! Health reduced to 1%")
        end
    },
    ["explosion"] = {
        name = "Explosive Compound",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(255, 150, 0),
        price = 1,
        effects = function(ply)
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] You feel unstable...")
            timer.Simple(2, function()
                if IsValid(ply) then
                    local effectdata = EffectData()
                    effectdata:SetOrigin(ply:GetPos())
                    util.Effect("Explosion", effectdata)
                    ply:EmitSound("BaseExplosionEffect.Sound")
                    util.BlastDamage(ply, ply, ply:GetPos(), 300, 200)
                end
            end)
        end
    },
    ["instant_death"] = {
        name = "Death Serum",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(0, 0, 0),
        price = 1,
        effects = function(ply)
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] This was a mistake...")
            timer.Simple(1, function()
                if IsValid(ply) and ply:Alive() then
                    ply:Kill()
                end
            end)
        end
    },
    ["poison_dot"] = {
        name = "Toxic Waste",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(0, 255, 0),
        price = 1,
        effects = function(ply)
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] You've been poisoned! -5 HP every 2 seconds for 30 seconds")
            local ticks = 0
            timer.Create("Poison_" .. ply:SteamID64(), 2, 15, function()
                if IsValid(ply) and ply:Alive() then
                    ply:TakeDamage(5, ply, ply)
                    ticks = ticks + 1
                else
                    timer.Remove("Poison_" .. ply:SteamID64())
                end
            end)
        end
    },
    ["super_speed"] = {
        name = "Hyper Accelerant",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(0, 255, 255),
        price = 1,
        effects = function(ply)
            local oldRun = ply:GetRunSpeed()
            local oldWalk = ply:GetWalkSpeed()
            ply:SetRunSpeed(oldRun * 3)
            ply:SetWalkSpeed(oldWalk * 3)
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] SUPER SPEED! 3x speed for 60 seconds!")
            timer.Simple(60, function()
                if IsValid(ply) then
                    ply:SetRunSpeed(oldRun)
                    ply:SetWalkSpeed(oldWalk)
                    ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] Speed boost ended")
                end
            end)
        end
    },
    ["shrink"] = {
        name = "Shrinking Formula",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(255, 255, 0),
        price = 1,
        effects = function(ply)
            ply:SetModelScale(0.5, 0)
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] You shrink to half size for 2 seconds!")
            timer.Simple(2, function()
                if IsValid(ply) then
                    ply:SetModelScale(1, 0)
                    ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] You return to normal size")
                end
            end)
        end
    },
    ["teleport_scp"] = {
        name = "SCP Attraction Serum",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(100, 0, 100),
        price = 1,
        effects = function(ply)
            local scps = {}
            for _, p in pairs(player.GetAll()) do
                if IsValid(p) and p:Alive() and p:GTeam() == TEAM_SCP and p != ply then
                    table.insert(scps, p)
                end
            end
            
            if #scps > 0 then
                local target = table.Random(scps)
                ply:SetPos(target:GetPos() + Vector(math.random(-100, 100), math.random(-100, 100), 0))
                ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] You've been teleported to " .. target:Nick() .. "!")
            else
                ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] No living SCPs found... Lucky you!")
            end
        end
    },
    ["delayed_death"] = {
        name = "Delayed Death Serum",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(50, 0, 50),
        price = 1,
        effects = function(ply)
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] You have 60 seconds to live...")
            timer.Create("DelayedDeath_" .. ply:SteamID64(), 60, 1, function()
                if IsValid(ply) and ply:Alive() then
                    ply:Kill()
                    ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] Your time is up...")
                end
            end)
        end
    },
    ["zombie_transform"] = {
        name = "SCP-049-2 Virus",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(100, 150, 50),
        price = 1,
        effects = function(ply)
            if ply:GTeam() != TEAM_SCP then
                ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] You feel... different...")
                timer.Simple(3, function()
                    if IsValid(ply) and ply:Alive() then
                        ply:SetNClass(ROLES.ROLE_SCP0492)
                        ply:SetGTeam(TEAM_SCP)
                        ply:SetModel("models/player/zombie_classic.mdl")
                        ply:SetHealth(1200)
                        ply:SetMaxHealth(1200)
                        ply:SetRunSpeed(135)
                        ply:SetWalkSpeed(135)
                        ply:StripWeapons()
                        ply:Give("weapon_scp_0492")
                        ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] You have become SCP-049-2!")
                    end
                end)
            else
                ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] No effect... You're already an SCP")
            end
        end
    },
    ["perm_speed"] = {
        name = "Permanent Enhancement",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(255, 200, 100),
        price = 1,
        effects = function(ply)
            local boost = math.random(10, 30) / 100
            local oldRun = ply:GetRunSpeed()
            local oldWalk = ply:GetWalkSpeed()
            ply:SetRunSpeed(oldRun * (1 + boost))
            ply:SetWalkSpeed(oldWalk * (1 + boost))
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] Permanent +" .. math.floor(boost * 100) .. "% speed boost!")
        end
    },
    ["bonus_credits"] = {
        name = "Lucky Coins",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(255, 215, 0),
        price = 1,
        effects = function(ply)
            ply:AddCredits(3, "SCP-294 Lucky Drink")
            ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] You found 3 credits in the can!")
        end
    },
    ["swap_places"] = {
        name = "Quantum Entanglement Drink",
        model = "models/props_junk/PopCan01a.mdl",
        color = Color(150, 150, 255),
        price = 1,
        effects = function(ply)
            local players = {}
            for _, p in pairs(player.GetAll()) do
                if IsValid(p) and p:Alive() and p != ply and p:GTeam() != TEAM_SPEC then
                    table.insert(players, p)
                end
            end
            
            if #players > 0 then
                local target = table.Random(players)
                local myPos = ply:GetPos()
                local targetPos = target:GetPos()
                
                ply:SetPos(targetPos)
                target:SetPos(myPos)
                
                ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] You swapped places with " .. target:Nick() .. "!")
                target:PrintMessage(HUD_PRINTTALK, "[SCP-294] You were swapped with " .. ply:Nick() .. "!")
            else
                ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] No valid targets for swap...")
            end
        end
    }
}

function ENT:Initialize()
    self:SetModel("models/vinrax/scp294/scp294.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
    end
    
    -- Inicjalizacja zmiennych
    self.UsesLeft = 10 -- Zmienione z 50 na 10
    self.LastUse = {}  -- Cooldown dla graczy
    
    -- Upewnij się że model jest widoczny
    self:SetRenderMode(RENDERMODE_NORMAL)
    self:SetColor(Color(255, 255, 255, 255))
    self:DrawShadow(true)
    
    print("[SCP-294] Coffee Machine initialized!")
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    -- Blokuj użycie dla SCP (oprócz SCP-035)
    if activator:GTeam() == TEAM_SCP and activator:GetNClass() != ROLES.ROLE_SCP035 then
        self:EmitSound("buttons/button10.wav", 60, 80)
        return
    end
    
    -- Sprawdź cooldown gracza (5 sekund między użyciami)
    local steamID = activator:SteamID64()
    if self.LastUse[steamID] and CurTime() - self.LastUse[steamID] < 5 then
        activator:PrintMessage(HUD_PRINTTALK, "[SCP-294] Please wait " .. math.ceil(5 - (CurTime() - self.LastUse[steamID])) .. " seconds...")
        return
    end
    
    -- Sprawdź czy maszyna ma jeszcze użycia
    if self.UsesLeft <= 0 then
        self:EmitSound("buttons/button10.wav", 60, 80)
        return
    end
    
    -- Losowo wybierz napój i go wydaj
    self:DispenseRandomDrink(activator)
end

function ENT:DispenseRandomDrink(ply)
    -- Stwórz listę dostępnych napojów
    local availableDrinks = {}
    for drinkID, drinkData in pairs(self.DrinkTypes) do
        table.insert(availableDrinks, drinkID)
    end
    
    -- Losowo wybierz napój
    local randomDrink = table.Random(availableDrinks)
    
    -- Wydaj wylosowany napój
    self:DispenseDrink(ply, randomDrink)
end

function ENT:DispenseDrink(ply, drinkType)
    if not self.DrinkTypes[drinkType] then return end
    
    local drink = self.DrinkTypes[drinkType]
    local steamID = ply:SteamID64()
    
    -- Sprawdź ponownie cooldown i użycia
    if self.LastUse[steamID] and CurTime() - self.LastUse[steamID] < 5 then return end
    if self.UsesLeft <= 0 then return end
    
    -- Sprawdź czy gracz ma wystarczająco kredytów (stały koszt 1 kredyt)
    local cost = 1
    if not ply:CanAfford(cost) then
        ply:PrintMessage(HUD_PRINTTALK, "[SCP-294] Insufficient credits! You need " .. cost .. " credit. (You have: " .. ply:GetCredits() .. ")")
        self:EmitSound("buttons/button2.wav", 60, 80)
        return
    end
    
    -- Pobierz kredyty
    ply:SpendCredits(cost, "SCP-294: " .. drink.name)
    
    -- Aktualizuj dane
    self.LastUse[steamID] = CurTime()
    self.UsesLeft = self.UsesLeft - 1
    
    -- Efekty dźwiękowe i wizualne
    self:EmitSound("ambient/machines/vending_machine_hum_loop1.wav", 75, 100)
    timer.Simple(1, function()
        if IsValid(self) then
            self:EmitSound("physics/metal/metal_canister_impact_hard2.wav", 80, 120)
        end
    end)
    
    -- Stwórz napój
    timer.Simple(1.5, function()
        if IsValid(self) and IsValid(ply) then
            self:CreateDrink(ply, drink)
            
            -- Efekt cząsteczek dispensowania
            local effectdata = EffectData()
            effectdata:SetOrigin(self:GetPos() + self:GetForward() * 20 + Vector(0,0,30))
            effectdata:SetScale(1.5)
            util.Effect("scp294_dispense", effectdata)
            

        end
    end)
end

function ENT:CreateDrink(ply, drinkData)
    local drinkEnt = ents.Create("scp_294_drink")
    if IsValid(drinkEnt) then
        drinkEnt:SetPos(self:GetPos() + self:GetForward() * 25 + Vector(0,0,20))
        drinkEnt:SetAngles(self:GetAngles())
        drinkEnt:Spawn()
        drinkEnt:Activate()
        
        -- Ustaw właściwości napoju
        drinkEnt:SetModel(drinkData.model)
        drinkEnt:SetColor(drinkData.color)
        drinkEnt.DrinkName = drinkData.name
        drinkEnt.DrinkEffects = drinkData.effects
        drinkEnt.Owner = ply
        
        -- Dodaj małą siłę wyrzutu
        local phys = drinkEnt:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetVelocity(self:GetForward() * 50 + Vector(0,0,100))
        end
    end
end

-- Network strings moved to sv_module.lua
-- Menu system removed - now uses random drink selection

-- Reset użyć na początku rundy
hook.Add("BreachPreround", "SCP294_Reset", function()
    for _, ent in pairs(ents.FindByClass("scp_294")) do
        ent.UsesLeft = 10
        ent.LastUse = {}
    end
    
    -- Menu system removed - no flags to clear
end)

-- Menu system removed - no player flags to manage