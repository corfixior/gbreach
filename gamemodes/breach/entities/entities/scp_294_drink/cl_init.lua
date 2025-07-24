include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    -- Efekt świecenia napoju
    if LocalPlayer():GetPos():DistToSqr(self:GetPos()) < 40000 then -- 200 jednostek
        local pos = self:GetPos() + Vector(0, 0, 15)
        local ang = LocalPlayer():EyeAngles()
        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), 90)
        
        cam.Start3D2D(pos, ang, 0.05)
            local drinkName = self.DrinkName or "Unknown Drink"
            draw.SimpleText(drinkName, "DermaDefault", 0, -10, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER)
            draw.SimpleText("Press E to drink", "DermaDefault", 0, 5, Color(200, 200, 200, 150), TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
    
    -- Małe cząsteczki unoszące się z napoju
    if math.random(1, 10) == 1 then
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos() + Vector(0, 0, 8) + VectorRand() * 3)
        effectdata:SetScale(0.5)
        effectdata:SetMagnitude(1)
        util.Effect("balloon_pop", effectdata)
    end
end

function ENT:Initialize()
    self.DrinkName = "Unknown Drink"
end 