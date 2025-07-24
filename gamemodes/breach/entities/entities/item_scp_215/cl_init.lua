include("shared.lua")

function ENT:Draw()
	self:DrawModel()
	
	-- Efekt świecenia dla lepszej widoczności
	local glow = math.sin(CurTime() * 3) * 0.2 + 0.8
	render.SetBlend(glow)
	self:DrawModel()
	render.SetBlend(1)
	
	-- Dodaj subtelny efekt cząsteczek
	if math.random(1, 10) == 1 then
		local effectdata = EffectData()
		effectdata:SetOrigin(self:GetPos() + Vector(0, 0, 5))
		effectdata:SetMagnitude(0.5)
		effectdata:SetScale(0.5)
		util.Effect("sparks", effectdata)
	end
end

-- TargetID usunięte zgodnie z żądaniem