include("shared.lua")

-- Podstawowe funkcje klienckie dla SCP-294
-- Menu system został usunięty - maszyna automatycznie losuje napój po użyciu

-- Funkcja efektu dispensowania (opcjonalna)
function ENT:CreateDispenseEffect()
    local pos = self:GetPos() + self:GetUp() * 50
    
    -- Prosty efekt cząsteczek
    local emitter = ParticleEmitter(pos)
    if emitter then
        for i = 1, 5 do
            local particle = emitter:Add("effects/splash2", pos + Vector(math.random(-3,3), math.random(-3,3), 0))
            if particle then
                particle:SetVelocity(Vector(math.random(-10,10), math.random(-10,10), math.random(5,15)))
                particle:SetLifeTime(0)
                particle:SetDieTime(0.8)
                particle:SetStartAlpha(200)
                particle:SetEndAlpha(0)
                particle:SetStartSize(1)
                particle:SetEndSize(0)
                particle:SetColor(100, 150, 255)
            end
        end
        emitter:Finish()
    end
end