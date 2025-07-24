-- SCP UPGRADER - Shared Configuration
-- Advanced rarity system with weights and enhanced features

if not BR then BR = {} end
if not BR.Upgrader then BR.Upgrader = {} end

-- Enhanced 7-tier rarity system with weights
BR.Upgrader.Rarities = {
    {
        name = "Consumer Grade",
        color = Color(176, 195, 217), -- Light gray-blue
        weight = 100,
        glowIntensity = 0.2,
        soundEffect = "buttons/button15.wav",
        tier = 1
    },
    {
        name = "Industrial Grade", 
        color = Color(94, 152, 217), -- Light blue
        weight = 60,
        glowIntensity = 0.4,
        soundEffect = "buttons/button9.wav",
        tier = 2
    },
    {
        name = "Mil-Spec Grade",
        color = Color(75, 105, 255), -- Blue
        weight = 30,
        glowIntensity = 0.6,
        soundEffect = "buttons/button3.wav",
        tier = 3
    },
    {
        name = "Restricted",
        color = Color(136, 71, 255), -- Purple
        weight = 15,
        glowIntensity = 0.8,
        soundEffect = "ambient/levels/labs/electric_explosion1.wav",
        tier = 4
    },
    {
        name = "Classified", 
        color = Color(211, 44, 230), -- Pink-purple
        weight = 6,
        glowIntensity = 1.0,
        soundEffect = "ambient/energy/zap1.wav",
        tier = 5
    },
    {
        name = "Covert",
        color = Color(235, 75, 75), -- Red
        weight = 2,
        glowIntensity = 1.2,
        soundEffect = "ambient/alarms/klaxon1.wav",
        tier = 6
    },
    {
        name = "Extraordinary",
        color = Color(255, 215, 0), -- Gold
        weight = 1,
        glowIntensity = 1.5,
        soundEffect = "vo/npc/male01/fantastic01.wav",
        tier = 7
    }
}

-- Enhanced item pools with tier progression
BR.Upgrader.ItemPools = {
    ["Consumer Grade"] = {
        "item_medkit", "item_radio", "weapon_pocket_knife", "br_keycard", "weapon_crowbar"
    },
    ["Industrial Grade"] = {
        "item_nvg", "item_eyedrops", "item_cameraview", "item_snav_300", "item_cctv"
    },
    ["Mil-Spec Grade"] = {
        "item_ultramedkit", "cw_deagle", "weapon_zeus", "item_snav_ultimate"
    },
    ["Restricted"] = {
        "cw_mp5", "cw_ar15", "item_scp_420j"
    },
    ["Classified"] = {
        "cw_ak74", "cw_l115", "item_scp_714"
    },
    ["Covert"] = {
        "weapon_scp_500", "weapon_scp_1499", "weapon_scp_018"
    },
    ["Extraordinary"] = {
        "weapon_scp_500", "weapon_scp_1499", "item_scp_714" -- Premium duplicates with higher chance
    }
}

-- All upgradeable items (any item that has value)
BR.Upgrader.UpgradeableItems = {
    "item_medkit", "item_radio", "weapon_pocket_knife", "br_keycard", "weapon_crowbar",
    "item_nvg", "item_eyedrops", "item_cameraview", "item_snav_300", "item_ultramedkit",
    "cw_deagle", "weapon_zeus", "cw_mp5", "item_snav_ultimate", "item_cctv",
    "cw_ar15", "cw_ak74", "cw_l115",
    "weapon_scp_500", "weapon_scp_1499", "item_scp_714", "item_scp_420j", "weapon_scp_018"
}

-- UI Themes for different factions
BR.Upgrader.Themes = {
    ["MTF"] = {
        primary = Color(30, 144, 255),
        secondary = Color(0, 100, 200),
        accent = Color(100, 200, 255),
        background = Color(20, 30, 50, 240)
    },
    ["CI"] = {
        primary = Color(34, 139, 34),
        secondary = Color(0, 100, 0),
        accent = Color(144, 238, 144),
        background = Color(20, 40, 20, 240)
    },
    ["Class-D"] = {
        primary = Color(255, 140, 0),
        secondary = Color(200, 100, 0),
        accent = Color(255, 215, 0),
        background = Color(50, 30, 10, 240)
    },
    ["Default"] = {
        primary = Color(163, 53, 238),
        secondary = Color(100, 30, 180),
        accent = Color(255, 215, 0),
        background = Color(40, 40, 40, 240)
    }
}

-- Fail-safe system configuration
BR.Upgrader.FailSafe = {
    enabled = true,
    guaranteedTier = 3, -- Mil-Spec Grade
    rollsRequired = 10, -- After 10 rolls without tier 3+
    message = "Gwarancja! Otrzymujesz Mil-Spec lub lepszy!"
}

-- API Functions
function BR.Upgrader:GetCompatibleItems(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return {} end
    
    local compatibleItems = {}
    
    for _, weapon in pairs(ply:GetWeapons()) do
        local weaponClass = weapon:GetClass()
        if table.HasValue(self.UpgradeableItems, weaponClass) then
            table.insert(compatibleItems, {
                class = weaponClass,
                name = weapon.PrintName or weaponClass,
                tier = self:GetItemTier(weaponClass)
            })
        end
    end
    
    return compatibleItems
end

function BR.Upgrader:GetItemTier(itemClass)
    for tierName, items in pairs(self.ItemPools) do
        if table.HasValue(items, itemClass) then
            for _, rarity in ipairs(self.Rarities) do
                if rarity.name == tierName then
                    return rarity.tier
                end
            end
        end
    end
    return 1 -- Default to Consumer Grade
end

function BR.Upgrader:Roll(playerFailSafeCount)
    playerFailSafeCount = playerFailSafeCount or 0
    
    -- Check fail-safe
    if self.FailSafe.enabled and playerFailSafeCount >= self.FailSafe.rollsRequired then
        -- Force at least Mil-Spec Grade
        local availableRarities = {}
        for _, rarity in ipairs(self.Rarities) do
            if rarity.tier >= self.FailSafe.guaranteedTier then
                table.insert(availableRarities, rarity)
            end
        end
        
        local selectedRarity = table.Random(availableRarities)
        local pool = self.ItemPools[selectedRarity.name]
        local item = table.Random(pool)
        
        return item, selectedRarity, true -- true = was fail-safe
    end
    
    -- Normal weighted roll
    local totalWeight = 0
    for _, rarity in ipairs(self.Rarities) do
        totalWeight = totalWeight + rarity.weight
    end
    
    local rand = math.random(1, totalWeight)
    local cumulative = 0
    
    for _, rarity in ipairs(self.Rarities) do
        cumulative = cumulative + rarity.weight
        if rand <= cumulative then
            local pool = self.ItemPools[rarity.name]
            local item = table.Random(pool)
            return item, rarity, false -- false = normal roll
        end
    end
    
    -- Fallback to Consumer Grade
    local pool = self.ItemPools["Consumer Grade"]
    return table.Random(pool), self.Rarities[1], false
end

function BR.Upgrader:GetPlayerTheme(ply)
    if not IsValid(ply) then return self.Themes["Default"] end
    
    local team = ply:GTeam()
    if team == TEAM_GUARD then
        return self.Themes["MTF"]
    elseif team == TEAM_CHAOS then
        return self.Themes["CI"]
    elseif team == TEAM_CLASSD then
        return self.Themes["Class-D"]
    else
        return self.Themes["Default"]
    end
end

-- Pre-calculate item tier map for performance
function BR.Upgrader:InitializeTierMap()
    self.ItemTierMap = self.ItemTierMap or {}
    
    for tierName, items in pairs(self.ItemPools) do
        local tier = 1
        for _, rarity in ipairs(self.Rarities) do
            if rarity.name == tierName then
                tier = rarity.tier
                break
            end
        end
        
        for _, itemClass in ipairs(items) do
            self.ItemTierMap[itemClass] = tier
        end
    end
    
    -- Override the GetItemTier function with a faster one
    self.GetItemTier = function(self, itemClass)
        return self.ItemTierMap[itemClass] or 1
    end
    
    print("[SCP-UPGRADER] Item Tier Map initialized for fast lookups.")
end

-- Initialize the map on load
BR.Upgrader:InitializeTierMap()

-- Hooks for addons
hook.Add("UpgraderPreRoll", "BR_Upgrader_PreRoll", function(ply, itemClass)
    -- Other addons can modify roll chances here
end)

hook.Add("UpgraderPostRoll", "BR_Upgrader_PostRoll", function(ply, itemClass, rewardItem, rarity, wasFailSafe)
    -- Other addons can react to rolls here
    if wasFailSafe then
        ply:PrintMessage(HUD_PRINTTALK, BR.Upgrader.FailSafe.message)
    end
end) 