function EFFECT:Init(data)
    local pos = data:GetOrigin()
    local scale = data:GetScale() or 1
    
    self.StartTime = CurTime()
    self.LifeTime = 2
    
    -- Stwórz cząsteczki pary
    local emitter = ParticleEmitter(pos, false)
    
    for i = 1, 20 * scale do
        local particle = emitter:Add("effects/splash2", pos + VectorRand() * 10)
        if particle then
            particle:SetVelocity(VectorRand() * 50 + Vector(0, 0, 50))
            particle:SetLifeTime(0)
            particle:SetDieTime(math.Rand(1, 2))
            particle:SetStartAlpha(255)
            particle:SetEndAlpha(0)
            particle:SetStartSize(math.Rand(2, 5) * scale)
            particle:SetEndSize(math.Rand(8, 12) * scale)
            particle:SetRoll(math.Rand(-180, 180))
            particle:SetRollDelta(math.Rand(-0.2, 0.2))
            particle:SetColor(255, 255, 255)
            particle:SetGravity(Vector(0, 0, -100))
            particle:SetAirResistance(5)
        end
    end
    
    -- Cząsteczki dymu/pary
    for i = 1, 10 * scale do
        local particle = emitter:Add("particle/smokesprites_0001", pos + Vector(0, 0, 10) + VectorRand() * 5)
        if particle then
            particle:SetVelocity(VectorRand() * 20 + Vector(0, 0, 30))
            particle:SetLifeTime(0)
            particle:SetDieTime(math.Rand(2, 3))
            particle:SetStartAlpha(100)
            particle:SetEndAlpha(0)
            particle:SetStartSize(math.Rand(5, 8) * scale)
            particle:SetEndSize(math.Rand(15, 20) * scale)
            particle:SetRoll(math.Rand(-180, 180))
            particle:SetRollDelta(math.Rand(-0.1, 0.1))
            particle:SetColor(200, 200, 255)
            particle:SetGravity(Vector(0, 0, -50))
            particle:SetAirResistance(10)
        end
    end
    
    emitter:Finish()
end

function EFFECT:Think()
    if CurTime() > self.StartTime + self.LifeTime then
        return false
    end
    return true
end

function EFFECT:Render()
    -- Efekt już renderowany przez cząsteczki
end 