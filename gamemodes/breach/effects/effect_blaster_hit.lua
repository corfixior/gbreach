function EFFECT:Init(data)		
	local Startpos = data:GetOrigin()
			
		self.Emitter = ParticleEmitter(Startpos)
	
		for i = 30, 40 do
			local p = self.Emitter:Add("effects/blueflare1", Startpos)
			
			p:SetDieTime(math.Rand(0.5, 2))
			p:SetStartAlpha(255)
			p:SetEndAlpha(0)
			p:SetStartSize(math.Rand(5, 10))
			p:SetEndSize(1)
			p:SetRoll(math.random(-60, 60))
			p:SetRollDelta(math.random(-60, 60))	
			p:SetVelocity(VectorRand() * 100)
			p:SetGravity(Vector(0, 0, math.random(-150, 0)))
			p:SetCollide(true)
			p:SetColor(30, 175, 255)
		end
		
		self.Emitter:Finish()
end
		
function EFFECT:Think()
	return false
end

function EFFECT:Render()
end