-- Bomber Lottery Client-side Animation
local bomberLotteryActive = false
local lotteryPlayers = {}
local selectedPlayer = nil
local lotteryStartTime = 0
local animationDuration = 5 -- 5 seconds
local lotteryFrame = nil

-- Create the lottery animation window
local function CreateLotteryWindow()
    if IsValid(lotteryFrame) then
        lotteryFrame:Remove()
    end
    
    local scrW = ScrW()
    
    lotteryFrame = vgui.Create("DPanel")
    lotteryFrame:SetSize(400, 80) -- Wider and shorter for a more cinematic/HUD feel
    lotteryFrame:SetPos(scrW / 2 - 200, 150)
    lotteryFrame:SetDrawBackground(false)
    
    -- Sleek, modern HUD background
    lotteryFrame.Paint = function(self, w, h)
        -- Main background (dark, semi-transparent)
        surface.SetDrawColor(20, 20, 20, 230)
        surface.DrawRect(0, 0, w, h)
        
        -- Glowing top/bottom borders
        surface.SetDrawColor(255, 50, 50, 80)
        surface.DrawRect(0, 0, w, 2)
        surface.DrawRect(0, h - 2, w, 2)
        
        -- Corner brackets for a "tech" look
        surface.SetDrawColor(255, 50, 50, 200)
        -- Top-left
        surface.DrawRect(0, 0, 20, 2)
        surface.DrawRect(0, 0, 2, 20)
        -- Top-right
        surface.DrawRect(w - 20, 0, 20, 2)
        surface.DrawRect(w - 2, 0, 2, 20)
        -- Bottom-left
        surface.DrawRect(0, h - 2, 20, 2)
        surface.DrawRect(0, h - 20, 2, 20)
        -- Bottom-right
        surface.DrawRect(w - 20, h - 2, 20, 2)
        surface.DrawRect(w - 2, h - 20, 2, 20)
    end
    
    -- Panel to clip the text animation
    local clipPanel = vgui.Create("DPanel", lotteryFrame)
    clipPanel:SetPos(10, 10)
    clipPanel:SetSize(380, 60)
    clipPanel:SetPaintBackground(false)
    clipPanel.PaintOver = function(self, w, h)
        -- This will clip children that go outside bounds
        local x, y = self:LocalToScreen(0, 0)
        render.SetScissorRect(x, y, x + w, y + h, true)
    end
    clipPanel.PaintOverEnd = function()
        render.SetScissorRect(0, 0, 0, 0, false)
    end
    
    -- Labels for scrolling animation
    local currentLabel = vgui.Create("DLabel", clipPanel)
    currentLabel:SetFont("DermaLarge")
    currentLabel:SetTextColor(Color(255, 255, 255))
    currentLabel:SetContentAlignment(5) -- Center
    currentLabel:SetSize(380, 60)
    
    local nextLabel = vgui.Create("DLabel", clipPanel)
    nextLabel:SetFont("DermaLarge")
    nextLabel:SetTextColor(Color(255, 255, 255))
    nextLabel:SetContentAlignment(5) -- Center
    nextLabel:SetSize(380, 60)
    
    -- Animation state
    local animY = 0
    local animSpeed = 0.05 -- Time per scroll
    local lastUpdate = CurTime()
    local currentIndex = math.random(1, #lotteryPlayers)
    
    currentLabel:SetText(lotteryPlayers[currentIndex]:Nick())
    nextLabel:SetText(lotteryPlayers[(currentIndex % #lotteryPlayers) + 1]:Nick())
    
    lotteryFrame.Think = function()
        if not bomberLotteryActive then return end
        
        local timeLeft = math.max(0, animationDuration - (CurTime() - lotteryStartTime))
        local progress = 1 - (timeLeft / animationDuration)
        
        -- Update animation speed based on progress
        if progress < 0.7 then
            animSpeed = 0.05
        else
            animSpeed = 0.05 + (progress - 0.7) * 2
        end
        
        if CurTime() > lastUpdate + animSpeed then
            currentIndex = (currentIndex % #lotteryPlayers) + 1
            
            local tempLabel = currentLabel
            currentLabel = nextLabel
            nextLabel = tempLabel
            
            local nextIndex = (currentIndex % #lotteryPlayers) + 1
            if lotteryPlayers[nextIndex] and IsValid(lotteryPlayers[nextIndex]) then
                nextLabel:SetText(lotteryPlayers[nextIndex]:Nick())
            end
            
            -- Reset animation
            animY = 80
            lastUpdate = CurTime()
            
            -- Sound
            surface.PlaySound("buttons/lightswitch2.wav")
        end
        
        -- Interpolate Y position for smooth scrolling
        animY = Lerp(FrameTime() * 15, animY, 0)
        currentLabel:SetPos(0, animY - 60)
        nextLabel:SetPos(0, animY)
        
        -- Stop animation and show result
        if timeLeft <= 0 then
            bomberLotteryActive = false
            if IsValid(selectedPlayer) then
                -- Final display
                currentLabel:SetText(selectedPlayer:Nick())
                currentLabel:SetTextColor(Color(255, 25, 25))
                currentLabel:SetPos(0, 0)
                nextLabel:SetVisible(false)
                
                -- Change frame paint for result
                lotteryFrame.Paint = function(self, w, h)
                    local flash = math.abs(math.sin(CurTime() * 10))
                    local borderColor = Color(255, 50, 50, 200 + flash * 55)
                    
                    surface.SetDrawColor(20, 20, 20, 230)
                    surface.DrawRect(0, 0, w, h)
                    
                    surface.SetDrawColor(borderColor)
                    surface.DrawOutlinedRect(0, 0, w, h)
                end
                
                -- Result sequence with 5 second countdown
                surface.PlaySound("buttons/button10.wav")
                
                -- 5 second countdown
                for i = 1, 5 do
                    timer.Simple(i, function()
                        if IsValid(currentLabel) then
                            currentLabel:SetText(selectedPlayer:Nick() .. " - " .. (6 - i))
                            surface.PlaySound("buttons/blip1.wav")
                        end
                    end)
                end
                
                timer.Simple(6, function()
                    if IsValid(currentLabel) then
                        currentLabel:SetText("💥 BOOM! 💥")
                        currentLabel:SetTextColor(Color(255, 255, 0))
                    end
                end)
                timer.Simple(6.5, function()
                    if IsValid(lotteryFrame) then lotteryFrame:Remove() end
                end)
            end
        end
    end
end

-- Network message receiver
net.Receive("BomberLottery", function()
    lotteryPlayers = net.ReadTable()
    selectedPlayer = net.ReadEntity()
    
    if #lotteryPlayers > 0 and IsValid(selectedPlayer) then
        bomberLotteryActive = true
        lotteryStartTime = CurTime()
        CreateLotteryWindow()
        surface.PlaySound("ui/buttonrollover.wav")
    end
end)

-- Chat message for explosion notification
hook.Add("OnPlayerChat", "BomberExplosionNotification", function(ply, strText, bTeam, bDead)
    if string.find(strText, "exploded!") then
        -- Add special formatting to explosion messages
        return true -- Let the default chat handle it
    end
end) 