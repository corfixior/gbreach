AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "SCP Wall Hole"
ENT.Author = "AI Assistant"
ENT.Category = "SCP"
ENT.Spawnable = true
ENT.AdminSpawnable = true

ENT.Model = "models/hunter/blocks/cube075x075x075.mdl"

-- Exchangeable items with tier system and TRUE PERCENTAGE CHANCES
-- RZECZYWISTE SZANSE WYMIAN:
-- Tier 1: 1% szans (najrzadsze)
-- Tier 2: 3% szans  
-- Tier 3: 8% szans
-- Tier 4: 15% szans
-- Tier 5: 25% szans (common)
local EXCHANGE_ITEMS = {
    -- Tier 1 - Rarest (1% szans każdy)
    ["br_keycard"] = 1, -- keycards handled separately
    ["weapon_scp_500"] = 1,
    
    -- Tier 2 - Very Rare (3% szans każdy)
    ["item_scp_714"] = 2,
    ["weapon_scp_1499"] = 2,
    
    -- Tier 3 - Rare (8% szans każdy)
    ["item_ultramedkit"] = 3,
    ["weapon_crowbar"] = 3,
    
    -- Tier 4 - Uncommon (15% szans każdy)
    ["item_medkit"] = 4,
    ["weapon_zeus"] = 4,
    ["item_snav_ultimate"] = 4,
    
    -- Tier 5 - Common (25% szans każdy)
    ["item_snav_300"] = 5,
    ["item_radio"] = 5,
    ["item_nvg"] = 5,
    ["item_eyedrops"] = 5
}

-- Tier chances (true percentages)
local TIER_CHANCES = {
    [1] = 1,   -- 1% for tier 1 items
    [2] = 3,   -- 3% for tier 2 items  
    [3] = 8,   -- 8% for tier 3 items
    [4] = 15,  -- 15% for tier 4 items
    [5] = 25   -- 25% for tier 5 items
}

-- Keycard tier system - specific types with TRUE PERCENTAGES
local KEYCARD_TIERS = {
    ["omni"] = 1,      -- najrzadszy (1% szans)
    ["com"] = 2,       -- commander (3% szans)
    ["mtf"] = 2,       -- MTF (8% szans)  
    ["cps"] = 3,       -- checkpoint (15% szans)
    ["keter"] = 4,     -- poziom 3 (15% szans)
    ["res"] = 4,       -- researcher (15% szans)
    ["euclid"] = 5,    -- poziom 2 (25% szans)
    ["safe"] = 5       -- poziom 1 najczęstszy (25% szans)
}

-- Keycard chances (true percentages) 
local KEYCARD_CHANCES = {
    [1] = 1,   -- 1% for omni
    [2] = 3,   -- 3% for com
    [3] = 8,   -- 8% for mtf
    [4] = 15,  -- 15% for cps, keter, res
    [5] = 25   -- 25% for euclid, safe
}

function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetModelScale(0.01)
    self:SetColor(Color(0, 0, 0, 0))
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    
    if SERVER then
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_BBOX)
        self:SetCollisionGroup(COLLISION_GROUP_WORLD)
        self:SetUseType(SIMPLE_USE)
        self:SetCollisionBounds(Vector(-24, -24, -24), Vector(24, 24, 24))
        
        self.NextUse = 0
        
        print("[SCP-WALL-HOLE] Simple exchange system initialized!")
    end
end

function ENT:Use(activator, caller, type, value)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if activator:GTeam() == TEAM_SPEC or activator:GTeam() == TEAM_SCP then return end
    if not activator:Alive() then return end
    
    if self.NextUse > CurTime() then
        return
    end
    
    if SERVER then
        self:PerformExchange(activator)
    end
end

function ENT:PerformExchange(player)
    local exchangeableItem, keycardType = self:GetPlayerExchangeableItem(player)
    
    if not exchangeableItem then
        return
    end
    
    -- First determine what we would get BEFORE removing current item
    local newItem, newKeycardType = self:GetRandomExchangeItem(exchangeableItem, keycardType, player)
    
    if newItem then
        -- CRITICAL FIX: Check if player already has the item we would give
        -- If so, try to get a different item from next tier or different item
        local attempts = 0
        while self:PlayerHasItem(player, newItem, newKeycardType) and attempts < 10 do
            attempts = attempts + 1
            newItem, newKeycardType = self:GetRandomExchangeItem(exchangeableItem, keycardType, player)
            if not newItem then break end
        end
        
        -- If after attempts we still would give duplicate, try upgrading to higher tier
        if newItem and self:PlayerHasItem(player, newItem, newKeycardType) then
            newItem, newKeycardType = self:GetUpgradedItem(newItem, newKeycardType, player)
        end
        
        -- Only proceed if we have a valid new item that player doesn't have
        if newItem and not self:PlayerHasItem(player, newItem, newKeycardType) then
            -- Remove old item
            player:StripWeapon(exchangeableItem)
            
            -- Remove conflicting items of the same category before giving new item
            self:RemoveConflictingItems(player, newItem)
            
            -- Give new item
            local weapon = player:Give(newItem)
            if IsValid(weapon) then
                -- Special handling for keycards
                if newItem == "br_keycard" and newKeycardType then
                    weapon:SetKeycardType(newKeycardType)
                end
                player:SelectWeapon(newItem)
            end
            
            -- DAMAGE PLAYER BY 1 HP FOR EACH EXCHANGE
            local currentHP = player:Health()
            player:SetHealth(math.max(1, currentHP - 1))  -- Never kill player, minimum 1 HP
            
            -- Console log only
            local itemName = newItem
            if newItem == "br_keycard" and newKeycardType then
                itemName = "br_keycard (" .. newKeycardType .. ")"
            end
            
            local oldItemName = exchangeableItem
            if exchangeableItem == "br_keycard" and keycardType then
                oldItemName = "br_keycard (" .. keycardType .. ")"
            end
            
            print(string.format("[SCP-WALL-HOLE] %s exchanged %s → %s (-1 HP)", player:Nick(), oldItemName, itemName))
            
            -- Set cooldown
            self.NextUse = CurTime() + 1.5
            
            -- Sound effect
            player:EmitSound("items/ammo_pickup.wav", 60, 100)
        end
    end
end

function ENT:RemoveConflictingItems(player, newItem)
    -- Item categories that should replace each other
    local itemCategories = {
        keycards = {
            "br_keycard"
        },
        medkits = {
            "item_medkit",
            "item_ultramedkit"
        },
        snav = {
            "item_snav_300",
            "item_snav_ultimate"
        },
        scps = {
            "weapon_scp_500",
            "item_scp_714",
            "weapon_scp_1499"
        }
    }
    
    -- Find which category the new item belongs to
    local newItemCategory = nil
    for category, items in pairs(itemCategories) do
        if table.HasValue(items, newItem) then
            newItemCategory = category
            break
        end
    end
    
    -- If new item has a category, remove all other items from that category
    if newItemCategory then
        local weapons = player:GetWeapons()
        for _, weapon in pairs(weapons) do
            local weaponClass = weapon:GetClass()
            if table.HasValue(itemCategories[newItemCategory], weaponClass) and weaponClass ~= newItem then
                player:StripWeapon(weaponClass)
            end
        end
    end
end

function ENT:GetPlayerExchangeableItem(player)
    -- Check only the currently held weapon
    local activeWeapon = player:GetActiveWeapon()
    
    if not IsValid(activeWeapon) then
        return nil, nil
    end
    
    local class = activeWeapon:GetClass()
    if EXCHANGE_ITEMS[class] then
        -- Special handling for keycards - return both class and type
        if class == "br_keycard" then
            local keycardType = activeWeapon:GetNWString("K_TYPE", "safe")
            return class, keycardType
        end
        return class, nil
    end
    
    return nil, nil
end

function ENT:GetRandomExchangeItem(currentItem, currentKeycardType, player)
    local attempts = 0
    local maxAttempts = 20 -- Prevent infinite loops
    
    while attempts < maxAttempts do
        attempts = attempts + 1
        
        -- Roll percentage for each item type using TRUE PERCENTAGES
        local allPossibleItems = {}
        
        -- Add regular items with their tier chances
        for item, tier in pairs(EXCHANGE_ITEMS) do
            if item ~= currentItem then
                local chance = TIER_CHANCES[tier] or 1
                local roll = math.random(1, 100)
                
                if roll <= chance then
                    table.insert(allPossibleItems, {item, nil})
                end
            end
        end
        
        -- Add keycard types with their specific chances  
        if currentItem ~= "br_keycard" then -- Only if not currently holding keycard
            for keycardType, tier in pairs(KEYCARD_TIERS) do
                local chance = KEYCARD_CHANCES[tier] or 1
                local roll = math.random(1, 100)
                
                if roll <= chance then
                    table.insert(allPossibleItems, {"br_keycard", keycardType})
                end
            end
        else
            -- If holding keycard, can get other keycard types
            for keycardType, tier in pairs(KEYCARD_TIERS) do
                if keycardType ~= currentKeycardType then
                    local chance = KEYCARD_CHANCES[tier] or 1
                    local roll = math.random(1, 100)
                    
                    if roll <= chance then
                        table.insert(allPossibleItems, {"br_keycard", keycardType})
                    end
                end
            end
        end
        
        -- If we got some items, pick one randomly
        if #allPossibleItems > 0 then
            local chosen = allPossibleItems[math.random(1, #allPossibleItems)]
            local chosenItem = chosen[1]
            local chosenKeycardType = chosen[2]
            
            -- Check if player already has this item (avoid duplicates)
            local hasItem = self:PlayerHasItem(player, chosenItem, chosenKeycardType)
            
            if not hasItem then
                return chosenItem, chosenKeycardType
            end
            -- If player has item, try again with next iteration
        end
        -- If no items rolled successfully, try again
    end
    
    -- If we couldn't find a unique item after many attempts, give fallback
    return "item_radio", nil -- fallback to common item
end

function ENT:PlayerHasItem(player, itemClass, keycardType)
    local weapons = player:GetWeapons()
    
    for _, weapon in pairs(weapons) do
        local weaponClass = weapon:GetClass()
        
        if weaponClass == itemClass then
            -- Special check for keycards - must match type too
            if itemClass == "br_keycard" and keycardType then
                local playerKeycardType = weapon:GetNWString("K_TYPE", "safe")
                if playerKeycardType == keycardType then
                    return true -- Player has same keycard type
                end
            else
                return true -- Player has this item
            end
        end
    end
    
    return false
end

function ENT:GetUpgradedItem(currentItem, currentKeycardType, player)
    -- Try to get item from higher tier (lower tier number = higher rarity)
    local currentTier = nil
    
    if currentItem == "br_keycard" and currentKeycardType then
        currentTier = KEYCARD_TIERS[currentKeycardType]
    else
        currentTier = EXCHANGE_ITEMS[currentItem]
    end
    
    if not currentTier then return nil, nil end
    
    -- Try tiers from highest rarity (1) to current tier
    for tier = 1, currentTier do
        -- Try regular items from this tier
        for item, itemTier in pairs(EXCHANGE_ITEMS) do
            if itemTier == tier and not self:PlayerHasItem(player, item, nil) then
                return item, nil
            end
        end
        
        -- Try keycards from this tier
        for keycardType, keyTier in pairs(KEYCARD_TIERS) do
            if keyTier == tier and not self:PlayerHasItem(player, "br_keycard", keycardType) then
                return "br_keycard", keycardType
            end
        end
    end
    
    -- If no upgrade found, return fallback that player doesn't have
    local fallbacks = {"item_radio", "item_eyedrops", "item_nvg"}
    for _, fallback in pairs(fallbacks) do
        if not self:PlayerHasItem(player, fallback, nil) then
            return fallback, nil
        end
    end
    
    return nil, nil -- No item available
end

-- Client rendering
if CLIENT then
    function ENT:Draw()
        -- Entity is invisible, don't draw the model
    end
    
    function ENT:DrawTranslucent()
        local pos = self:GetPos()
        local plyPos = LocalPlayer():GetPos()
        local distance = plyPos:Distance(pos)
        
        if distance < 150 then
            local screenPos = pos:ToScreen()
            if screenPos.visible then
                -- Enhanced holographic effect
                local pulse = math.sin(CurTime() * 3) * 0.3 + 0.7
                local glowColor = Color(255, 100, 100, 255 * pulse)
                
                -- Main title with enhanced glow
                draw.SimpleTextOutlined(
                    "SCP WALL HOLE",
                    "DermaLarge",
                    screenPos.x,
                    screenPos.y - 40,
                    glowColor,
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER,
                    3,
                    Color(0, 0, 0, 200)
                )
                
                -- Simple instruction text
                local alpha = math.max(0, 255 - (distance * 2))
                
                draw.SimpleTextOutlined(
                    "Press E to exchange",
                    "DermaDefaultBold",
                    screenPos.x,
                    screenPos.y - 10,
                    Color(255, 255, 255, alpha),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER,
                    2,
                    Color(0, 0, 0, alpha * 0.8)
                )
                
                -- Status indicator
                local statusText = "• READY •"
                local statusColor = Color(255, 255, 100, alpha)
                
                draw.SimpleTextOutlined(
                    statusText,
                    "DermaDefault",
                    screenPos.x,
                    screenPos.y + 15,
                    statusColor,
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER,
                    1,
                    Color(0, 0, 0, alpha * 0.6)
                )
                
                -- Floating particles effect
                for i = 1, 3 do
                    local particleX = screenPos.x + math.sin(CurTime() * 2 + i) * 20
                    local particleY = screenPos.y + 30 + math.cos(CurTime() * 1.5 + i) * 10
                    local particleAlpha = (math.sin(CurTime() * 4 + i) + 1) * 50
                    
                    draw.SimpleText("•", "DermaDefault", particleX, particleY, 
                        Color(255, 100, 100, particleAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
        end
    end
end

-- Sound effects on spawn
function ENT:PostEntityPaste()
    if SERVER then
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        util.Effect("Explosion", effectdata)
        
        self:EmitSound("ambient/levels/citadel/strange_talk" .. math.random(1,11) .. ".wav", 70, 100)
    end
end 