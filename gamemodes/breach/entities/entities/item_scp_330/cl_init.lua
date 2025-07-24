-- SCP-330 client logic dla gamemode Breach
-- Bazowany na oryginalnym kodzie SCP-330 z kompatybilnością Breach

include("shared.lua")

-- Client effects configuration
local WARNING_RADIUS = 150
local WARNING_SHOWN = {}

function ENT:Draw()
    self:DrawModel()
end

function ENT:Think()
    self:ProximityWarning()
end

function ENT:ProximityWarning()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    local distance = ply:GetPos():Distance(self:GetPos())
    if distance > WARNING_RADIUS then return end
    
    -- Show warning only once per entity
    local entIndex = self:EntIndex()
    if WARNING_SHOWN[entIndex] then return end
    
    WARNING_SHOWN[entIndex] = true
    
    -- Play warning sound
    ply:EmitSound("scp_330/on_first_contact.mp3")
    
    -- Show warning text
    self:ShowProximityMessage()
end

function ENT:ShowProximityMessage()
    local startTime = CurTime()
    local duration = 4
    local maxAlpha = 255
    
    hook.Add("HUDPaint", "SCP330_ProximityWarning_" .. self:EntIndex(), function()
        local elapsed = CurTime() - startTime
        if elapsed >= duration then
            hook.Remove("HUDPaint", "SCP330_ProximityWarning_" .. self:EntIndex())
            return
        end
        
        local alpha = maxAlpha * (1 - (elapsed / duration))
        local size = 0.3 + (elapsed / duration) * 2
        
        local scrW, scrH = ScrW(), ScrH()
        local centerX, centerY = scrW * 0.5, scrH * 0.5
        
        -- Create scaling matrix
        local matrix = Matrix()
        matrix:Translate(Vector(centerX, centerY, 0))
        matrix:Scale(Vector(size, size, 1))
        matrix:Translate(Vector(-centerX, -centerY, 0))
        
        cam.PushModelMatrix(matrix)
        
        -- Draw warning text
        draw.DrawText("take no more than two,", "DermaLarge", centerX, centerY - 20, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
        draw.DrawText("please!!", "DermaLarge", centerX, centerY + 20, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER)
        
        cam.PopModelMatrix()
        
        -- Apply color modification
        local colorTab = {
            ["$pp_colour_contrast"] = math.Clamp(elapsed / duration + 0.3, 0, 1)
        }
        DrawColorModify(colorTab)
        
        -- Motion blur effect
        DrawMotionBlur(0.1, 0.2, 0.05)
    end)
end

-- Network message handlers
net.Receive("SCP330_PlaySound", function()
    local soundPath = net.ReadString()
    LocalPlayer():EmitSound(soundPath)
end)

net.Receive("SCP330_BloodEffect", function()
    local ply = LocalPlayer()
    
    -- Create blood overlay effect
    if not ply.SCP330_BloodOverlay then
        ply.SCP330_BloodOverlay = true
        
        local startTime = CurTime()
        local duration = 4
        local fadeInTime = duration * 0.5
        local fadeOutTime = duration * 0.5
        
        hook.Add("HUDPaint", "SCP330_BloodOverlay_" .. ply:EntIndex(), function()
            local elapsed = CurTime() - startTime
            if elapsed >= duration then
                hook.Remove("HUDPaint", "SCP330_BloodOverlay_" .. ply:EntIndex())
                ply.SCP330_BloodOverlay = nil
                return
            end
            
            local alpha
            if elapsed <= fadeInTime then
                alpha = 200 * (elapsed / fadeInTime)
            else
                alpha = 200 * (1 - ((elapsed - fadeInTime) / fadeOutTime))
            end
            
            -- Draw blood overlay
            surface.SetDrawColor(139, 0, 0, alpha) -- Dark red
            surface.DrawRect(0, 0, ScrW(), ScrH())
            
            -- Apply blur effect
            DrawMotionBlur(0.1, 0.5, 0.1)
        end)
        
        -- Play breathing sound
        local breathSounds = {
            "scp_330/heavy_breath_1.mp3",
            "scp_330/heavy_breath_2.mp3", 
            "scp_330/heavy_breath_3.mp3"
        }
        ply:EmitSound(breathSounds[math.random(#breathSounds)])
    end
end)

-- Clean up on entity removal
function ENT:OnRemove()
    hook.Remove("HUDPaint", "SCP330_ProximityWarning_" .. self:EntIndex())
    WARNING_SHOWN[self:EntIndex()] = nil
end 