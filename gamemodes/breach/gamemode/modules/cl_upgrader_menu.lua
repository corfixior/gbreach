-- SCP UPGRADER - Advanced Client Menu
-- AAA Quality animations and CS2-style interface

if not BR then BR = {} end
if not BR.UpgraderUI then BR.UpgraderUI = {} end

-- UI State Management
local upgraderMenu = nil
local roulettePanel = nil
local currentTheme = nil
local isAnimating = false

-- Animation variables
local wheelRotation = 0
local wheelSpeed = 0
local targetRotation = 0
local glowPulse = 0
local resultDisplayTime = 0

-- Cached materials for performance
local glowMaterial = Material("effects/yellowflare")
local gradientMaterial = Material("gui/gradient_up")

-- Sound precaching
local function PrecacheSounds()
    for _, rarity in ipairs(BR.Upgrader.Rarities) do
        if rarity.soundEffect then
            sound.Add({
                name = "upgrader_" .. rarity.tier,
                channel = CHAN_AUTO,
                volume = 0.8,
                level = 75,
                sound = rarity.soundEffect
            })
        end
    end
    
    -- Additional UI sounds
    sound.Add({
        name = "upgrader_tick",
        channel = CHAN_AUTO,
        volume = 0.3,
        level = 50,
        sound = "buttons/lightswitch2.wav"
    })
    
    sound.Add({
        name = "upgrader_open",
        channel = CHAN_AUTO,
        volume = 0.6,
        level = 75,
        sound = "ambient/machines/keyboard1_clicks.wav"
    })
end

-- Initialize sounds
timer.Simple(1, PrecacheSounds)

-- Easing functions for smooth animations
local function EaseOutCubic(t)
    return 1 - math.pow(1 - t, 3)
end

local function EaseInOutQuad(t)
    return t < 0.5 and 2 * t * t or 1 - math.pow(-2 * t + 2, 2) / 2
end

-- Advanced drawing functions
local function DrawGlowingBox(x, y, w, h, color, glowIntensity)
    glowIntensity = glowIntensity or 1
    
    -- Base box
    draw.RoundedBox(8, x, y, w, h, color)
    
    -- Glow effect layers
    for i = 1, 3 do
        local alpha = math.max(0, (color.a * glowIntensity * (4 - i)) / 3)
        local expandedColor = Color(color.r, color.g, color.b, alpha)
        draw.RoundedBox(8, x - i * 2, y - i * 2, w + i * 4, h + i * 4, expandedColor)
    end
end

local function DrawProgressRing(centerX, centerY, radius, progress, color, thickness)
    thickness = thickness or 8
    local segments = 64
    local angleStep = 360 / segments
    local totalAngle = 360 * progress
    
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    
    for i = 0, segments do
        local angle = i * angleStep
        if angle <= totalAngle then
            local x1 = centerX + math.cos(math.rad(angle)) * (radius - thickness/2)
            local y1 = centerY + math.sin(math.rad(angle)) * (radius - thickness/2)
            local x2 = centerX + math.cos(math.rad(angle)) * (radius + thickness/2)
            local y2 = centerY + math.sin(math.rad(angle)) * (radius + thickness/2)
            
            surface.DrawLine(x1, y1, x2, y2)
        end
    end
end

local function DrawCustomCircle(x, y, radius, color)
    local segments = 32
    local points = {}
    
    for i = 0, segments do
        local angle = (i / segments) * math.pi * 2
        local px = x + math.cos(angle) * radius
        local py = y + math.sin(angle) * radius
        table.insert(points, {x = px, y = py})
    end
    
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    surface.DrawPoly(points)
end

-- Main menu creation function
function BR.UpgraderUI:CreateUpgraderMenu(items, rarities, theme, upgrader)
    if IsValid(upgraderMenu) then
        upgraderMenu:Remove()
    end
    
    currentTheme = theme or BR.Upgrader:GetPlayerTheme(LocalPlayer())
    
    upgraderMenu = vgui.Create("DFrame")
    upgraderMenu:SetSize(700, 600)
    upgraderMenu:Center()
    upgraderMenu:SetTitle("")
    upgraderMenu:SetDraggable(false)
    upgraderMenu:ShowCloseButton(false)
    upgraderMenu:MakePopup()
    
    -- Play open sound
    surface.PlaySound("upgrader_open")
    
    -- Custom paint function with theme support
    upgraderMenu.Paint = function(self, w, h)
        -- Animated background
        local pulseAlpha = math.sin(CurTime() * 2) * 20 + 220
        local bgColor = Color(currentTheme.background.r, currentTheme.background.g, currentTheme.background.b, pulseAlpha)
        
        DrawGlowingBox(0, 0, w, h, bgColor, 0.5)
        
        -- Header with gradient
        surface.SetMaterial(gradientMaterial)
        surface.SetDrawColor(currentTheme.primary.r, currentTheme.primary.g, currentTheme.primary.b, 180)
        surface.DrawTexturedRect(0, 0, w, 60)
        
        -- Title with glow effect
        draw.SimpleText("SCP UPGRADER", "DermaLarge", w/2, 30, currentTheme.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("SCP UPGRADER", "DermaLarge", w/2 + 1, 31, Color(0, 0, 0, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Version info
        draw.SimpleText("v2.0 Advanced", "DermaDefault", w - 10, h - 15, Color(150, 150, 150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    
    -- Close button with custom styling
    local closeBtn = vgui.Create("DButton", upgraderMenu)
    closeBtn:SetPos(upgraderMenu:GetWide() - 40, 10)
    closeBtn:SetSize(30, 30)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w, h)
        local color = self:IsHovered() and Color(255, 100, 100) or Color(200, 200, 200)
        DrawGlowingBox(0, 0, w, h, color, self:IsHovered() and 1.2 or 0.8)
        draw.SimpleText("✕", "DermaDefaultBold", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function()
        upgraderMenu:Remove()
    end
    
    -- Subtitle
    local subtitle = vgui.Create("DLabel", upgraderMenu)
    subtitle:SetPos(0, 70)
    subtitle:SetSize(700, 25)
    subtitle:SetText("Wybierz przedmiot do ulepszenia • Gwarancja Mil-Spec co 10 rolli")
    subtitle:SetFont("DermaDefaultBold")
    subtitle:SetTextColor(currentTheme.accent)
    subtitle:SetContentAlignment(5)
    
    -- Items scroll panel with custom styling
    local scroll = vgui.Create("DScrollPanel", upgraderMenu)
    scroll:SetPos(20, 105)
    scroll:SetSize(660, 350)
    
    -- Custom scrollbar
    local sbar = scroll:GetVBar()
    sbar:SetWide(12)
    sbar.Paint = function(self, w, h)
        DrawGlowingBox(0, 0, w, h, Color(30, 30, 30, 200), 0.3)
    end
    sbar.btnGrip.Paint = function(self, w, h)
        local color = self:IsHovered() and currentTheme.accent or currentTheme.primary
        DrawGlowingBox(2, 0, w-4, h, color, 0.8)
    end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    
    if #items == 0 then
        local noItems = vgui.Create("DLabel", scroll)
        noItems:SetPos(0, 150)
        noItems:SetSize(660, 40)
        noItems:SetText("🚫 Nie masz kompatybilnych przedmiotów!")
        noItems:SetFont("DermaLarge")
        noItems:SetTextColor(Color(255, 100, 100))
        noItems:SetContentAlignment(5)
    else
        for i, item in ipairs(items) do
            local itemPanel = vgui.Create("DButton", scroll)
            itemPanel:SetPos(10, (i-1) * 70 + 10)
            itemPanel:SetSize(640, 60)
            itemPanel:SetText("")
            
            -- Get item tier info
            local tier = item.tier or 1
            local tierColor = rarities[tier] and rarities[tier].color or Color(150, 150, 150)
            local glowIntensity = rarities[tier] and rarities[tier].glowIntensity or 0.3
            
            itemPanel.Paint = function(self, w, h)
                local baseColor = self:IsHovered() and Color(60, 60, 60, 240) or Color(40, 40, 40, 200)
                local finalGlow = self:IsHovered() and glowIntensity * 1.5 or glowIntensity
                
                DrawGlowingBox(0, 0, w, h, baseColor, 0.5)
                
                -- Tier indicator bar
                DrawGlowingBox(0, 0, 6, h, tierColor, finalGlow)
                
                -- Item name with tier info
                draw.SimpleText(item.name, "DermaDefaultBold", 20, h/2 - 8, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                
                -- Tier name
                local tierName = rarities[tier] and rarities[tier].name or "Consumer Grade"
                draw.SimpleText("Tier: " .. tierName, "DermaDefault", 20, h/2 + 10, tierColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                
                -- Action text
                local actionColor = self:IsHovered() and currentTheme.accent or Color(180, 180, 180)
                draw.SimpleText("KLIKNIJ ABY ULEPSZYĆ ►", "DermaDefaultBold", w-20, h/2, actionColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            
            itemPanel.DoClick = function()
                -- Find the upgrader entity
                local upgrader = nil
                for _, ent in pairs(ents.FindByClass("scp_wall_hole")) do
                    if IsValid(ent) and LocalPlayer():GetPos():Distance(ent:GetPos()) < 150 then
                        upgrader = ent
                        break
                    end
                end
                
                if IsValid(upgrader) then
                    net.Start("UpgradeItem")
                    net.WriteString(item.class)
                    net.WriteEntity(upgrader)
                    net.SendToServer()
                    
                    upgraderMenu:Remove()
                end
            end
        end
    end
    
    -- Rarity info panel with enhanced design
    local rarityPanel = vgui.Create("DPanel", upgraderMenu)
    rarityPanel:SetPos(20, 470)
    rarityPanel:SetSize(660, 120)
    
    rarityPanel.Paint = function(self, w, h)
        DrawGlowingBox(0, 0, w, h, Color(20, 20, 20, 220), 0.6)
        
        draw.SimpleText("🎲 SZANSE NA RZADKOŚĆ", "DermaDefaultBold", 15, 15, currentTheme.accent)
        
        -- Calculate total weight dynamically
        local totalWeight = 0
        for _, r in ipairs(rarities) do totalWeight = totalWeight + r.weight end
        
        -- Draw rarity bars
        local startY = 40
        local barHeight = 12
        local spacing = 12
        
        for i, rarity in ipairs(rarities) do
            local y = startY + (i-1) * spacing
            local percentage = math.Round((rarity.weight / totalWeight) * 100, 1)
            
            -- Background bar
            draw.RoundedBox(4, 15, y, 200, barHeight, Color(30, 30, 30))
            
            -- Filled bar with glow
            local fillWidth = (percentage / 100) * 200
            DrawGlowingBox(15, y, fillWidth, barHeight, rarity.color, rarity.glowIntensity)
            
            -- Text
            draw.SimpleText(rarity.name, "DermaDefault", 225, y + barHeight/2, rarity.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(percentage .. "%", "DermaDefault", w - 15, y + barHeight/2, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
end

-- Advanced roulette wheel
function BR.UpgraderUI:CreateRouletteMenu(rewardItem, rarityName, rarityColor, rarities, wasFailSafe)
    if IsValid(roulettePanel) then
        roulettePanel:Remove()
    end
    
    roulettePanel = vgui.Create("DFrame")
    roulettePanel:SetSize(1000, 700)
    roulettePanel:Center()
    roulettePanel:SetTitle("")
    roulettePanel:SetDraggable(false)
    roulettePanel:ShowCloseButton(false)
    roulettePanel:MakePopup()
    
    -- Animation setup
    wheelRotation = 0
    wheelSpeed = 20
    targetRotation = math.random(720, 1080) -- 2-3 full rotations
    isAnimating = true
    glowPulse = 0
    resultDisplayTime = 0
    
    local animationStartTime = CurTime()
    local animationDuration = 4 -- 4 seconds
    local lastSegment = -1
    
    roulettePanel.Paint = function(self, w, h)
        -- Background with particles effect
        draw.RoundedBox(0, 0, 0, w, h, Color(10, 10, 10, 250))
        
        -- Title
        draw.SimpleText("SCP UPGRADER ROULETTE", "DermaLarge", w/2, 50, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        if wasFailSafe then
            draw.SimpleText("🎯 GWARANCJA AKTYWNA!", "DermaDefaultBold", w/2, 85, Color(255, 215, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- Roulette wheel center
        local centerX, centerY = w/2, h/2 + 50
        local radius = 180
        
        -- Update animation
        if isAnimating then
            local elapsed = CurTime() - animationStartTime
            local progress = math.min(elapsed / animationDuration, 1)
            
            -- Smooth deceleration
            local easedProgress = EaseOutCubic(progress)
            wheelRotation = targetRotation * easedProgress
            
            if progress >= 1 then
                isAnimating = false
                resultDisplayTime = CurTime()
                
                -- Play result sound
                for _, rarity in ipairs(rarities) do
                    if rarity.name == rarityName then
                        surface.PlaySound("upgrader_" .. rarity.tier)
                        break
                    end
                end
            else
                -- Play tick sounds during spin
                local currentSegment = math.floor((wheelRotation % 360) / (360 / #rarities))
                if currentSegment ~= lastSegment then
                    surface.PlaySound("upgrader_tick")
                    lastSegment = currentSegment
                end
            end
        end
        
        -- Draw wheel segments
        local segmentAngle = 360 / #rarities
        for i, rarity in ipairs(rarities) do
            local startAngle = (i-1) * segmentAngle + wheelRotation
            local midAngle = startAngle + segmentAngle/2
            
            -- Calculate segment position
            local segX = centerX + math.cos(math.rad(midAngle)) * radius * 0.6
            local segY = centerY + math.sin(math.rad(midAngle)) * radius * 0.6
            
            -- Enhanced glow for current result
            local glowMult = 1
            if not isAnimating and rarity.name == rarityName then
                glowMult = 2 + math.sin(CurTime() * 8) * 0.5
            end
            
            DrawGlowingBox(segX - 80, segY - 20, 160, 40, rarity.color, rarity.glowIntensity * glowMult)
            draw.SimpleText(rarity.name, "DermaDefaultBold", segX, segY, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- Wheel border with multiple rings
        for i = 0, 4 do
            DrawCustomCircle(centerX, centerY, radius - i * 2, Color(255, 255, 255, 60 - i * 10))
        end
        
        -- Progress ring during animation
        if isAnimating then
            local elapsed = CurTime() - animationStartTime
            local progress = elapsed / animationDuration
            DrawProgressRing(centerX, centerY, radius + 20, progress, Color(255, 215, 0), 8)
        end
        
        -- Pointer with enhanced design
        surface.SetDrawColor(255, 50, 50)
        local points = {
            {x = centerX, y = centerY - radius - 25},
            {x = centerX - 12, y = centerY - radius - 5},
            {x = centerX + 12, y = centerY - radius - 5}
        }
        surface.DrawPoly(points)
        
        -- Result display with 3D model preview
        if not isAnimating and CurTime() - resultDisplayTime > 0.5 then
            local resultY = h - 150
            
            -- Result background
            DrawGlowingBox(w/2 - 250, resultY - 50, 500, 120, Color(20, 20, 20, 240), 1.0)
            
            -- Result text with pulsing effect
            local pulse = 1 + math.sin(CurTime() * 6) * 0.2
            draw.SimpleText("WYGRAŁEŚ:", "DermaLarge", w/2, resultY - 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            local scaledColor = Color(rarityColor.r * pulse, rarityColor.g * pulse, rarityColor.b * pulse)
            draw.SimpleText(rewardItem, "DermaLarge", w/2, resultY + 15, scaledColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Auto close after 4 seconds
            if CurTime() - resultDisplayTime > 4 then
                roulettePanel:Remove()
            end
        end
        
        -- Skip button
        if isAnimating then
            local skipBtn = "Naciśnij SPACE aby pominąć animację"
            draw.SimpleText(skipBtn, "DermaDefault", w/2, h - 30, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    
    roulettePanel.OnKeyCodePressed = function(self, key)
        if key == KEY_SPACE and isAnimating then
            isAnimating = false
            wheelRotation = targetRotation
            resultDisplayTime = CurTime()
            
            -- Play result sound immediately
            for _, rarity in ipairs(rarities) do
                if rarity.name == rarityName then
                    surface.PlaySound("upgrader_" .. rarity.tier)
                    break
                end
            end
            
            -- Create the model panel once the animation is skipped/finished
            self:CreateModelPreview(rewardItem)
        end
    end
    
    roulettePanel.CreateModelPreview = function(self, itemClass)
        local wep = weapons.Get(itemClass)
        if not wep or not wep.ViewModel then return end

        local modelPanel = vgui.Create("DModelPanel", self)
        modelPanel:SetSize(100, 100)
        local resultY = self:GetTall() - 150
        modelPanel:SetPos(self:GetWide()/2 - 220, resultY - 25)
        modelPanel:SetModel(wep.ViewModel)
        
        -- Animation and lookat
        modelPanel:SetAnimated(true)
        local sequence = modelPanel.Entity:LookupSequence("idle")
        if sequence and sequence > 0 then
            modelPanel.Entity:SetSequence(sequence)
        end
        
        modelPanel.LayoutEntity = function(ent)
            ent:SetAngles(Angle(0, CurTime() * 50, 0))
        end
    end
    
    -- Override the on-finish logic to create the model panel
    local originalPaint = roulettePanel.Paint
    roulettePanel.Paint = function(self, w, h)
        originalPaint(self, w, h)
        
        if not isAnimating and not self.ModelPanelCreated and CurTime() - resultDisplayTime > 0.5 then
            self:CreateModelPreview(rewardItem)
            self.ModelPanelCreated = true
        end
    end
end

-- Network receivers
net.Receive("OpenUpgraderMenu", function()
    local items = net.ReadTable()
    local rarities = net.ReadTable()
    local upgrader = net.ReadEntity()
    local theme = BR.Upgrader:GetPlayerTheme(LocalPlayer())
    
    BR.UpgraderUI:CreateUpgraderMenu(items, rarities, theme, upgrader)
end)

net.Receive("SpinRoulette", function()
    local rewardItem = net.ReadString()
    local rarityName = net.ReadString()
    local rarityColor = net.ReadColor()
    local rarities = net.ReadTable()
    local wasFailSafe = net.ReadBool()
    
    BR.UpgraderUI:CreateRouletteMenu(rewardItem, rarityName, rarityColor, rarities, wasFailSafe)
end) 