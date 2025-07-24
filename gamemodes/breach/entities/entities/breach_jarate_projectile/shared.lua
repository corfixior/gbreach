ENT.Type = "anim"

ENT.Spawnable = false
ENT.AdminOnly = false

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.slosh = "orange_blossom/piss/slosh.wav"
ENT.droplet = Material ( "models/orange_blossom/piss/piss_droplet" )
ENT.splash = Material ( "models/orange_blossom/piss/piss_splash" )
ENT.colPiss = Color( 222, 180, 44, 255 )
ENT.colNormal = Color( 255, 255, 255, 255 )

ENT.time = 0
ENT.myPos = nil
ENT.pissed = {}
ENT.collided = false --the moment when jar explodes
ENT.doPiss = false --true if at least one target was pissed on
ENT.piss_hook = 0
ENT.byeBye = 0
ENT.didOnce = false
ENT.performDelay = 999999
ENT.lightPwr = 0

ENT.duration = GetConVar and GetConVar("blossomJarateDuration") and GetConVar("blossomJarateDuration"):GetInt() or 10
ENT.range = GetConVar and GetConVar("blossomJarateRange") and GetConVar("blossomJarateRange"):GetInt() or 150
ENT.strenght = GetConVar and GetConVar("blossomJarateStrenght") and GetConVar("blossomJarateStrenght"):GetFloat() or 0.35

function ENT:SetupDataTables()
	self:NetworkVar( "Vector", 0, "DirVec" )
	self:NetworkVar( "Entity", 0, "MyParent" )
	self:NetworkVar( "Int", 0, "Force" )

	self:NetworkVar( "Bool", 0, "PerformPiss" )
	self:NetworkVar( "Vector", 1, "NetworkPos" )

	if SERVER then
		self:SetPerformPiss( false )
	end
end

--set these accordingly to the spawning entity
function ENT:MyInfo( dir, parent, force )
	self:SetDirVec( dir )
	self:SetMyParent( parent )
	self:SetForce( force )
end

function ENT:Initialize()
	self.time = CurTime()

	self.duration = GetConVar and GetConVar("blossomJarateDuration") and GetConVar("blossomJarateDuration"):GetInt() or 10
	self.range = GetConVar and GetConVar("blossomJarateRange") and GetConVar("blossomJarateRange"):GetInt() or 150
	self.strenght = GetConVar and GetConVar("blossomJarateStrenght") and GetConVar("blossomJarateStrenght"):GetFloat() or 0.35

	if SERVER then
		self.byeBye = self.time + 10 --safeguard if jarate gets out of world bounds

		self:SetModel( "models/orange_blossom/piss/piss_world.mdl" )
		self:ManipulateBoneScale( 0, Vector( 1.5, 1.5, 1.5 ) )
		self:DrawShadow( true )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetCollisionGroup( 1 )
		self:SetTrigger( true )
		self:UseTriggerBounds( true, 4 )

		self:PhysWake()
		self.phys = self:GetPhysicsObject()

		if !self.phys:IsValid() then
			self:Remove()
		else
			self.phys:AddGameFlag( FVPHYSICS_NO_IMPACT_DMG, FVPHYSICS_NO_PLAYER_PICKUP )
			--self.phys:EnableGravity(true)

			local force = Vector( self:GetForce() * self:GetDirVec(), 0, 0 )

			self.phys:AddAngleVelocity( Vector ( math.Rand( -180, 180 ), math.Rand( -180, 180 ), math.Rand( -180, 180 ) ) )
			self.phys:AddVelocity( force + Vector( math.Rand( -15, 15 ), math.Rand( -15, 15 ), 0 ) )
		end
	else
		self.emitter = ParticleEmitter( Vector( 0, 0, 0 ), false )
	end
end

function ENT:StartTouch( ent )
	self.myPos = self:GetPos()

	if !self.collided and IsValid(ent) and ent ~= self:GetMyParent() then
		self.collided = true
		self:SetPerformPiss( true )
		self:SetNetworkPos( self.myPos )
		self.performDelay = CurTime() + 0.1
	end
end

function ENT:PhysicsCollide( data, physobj )
	self.myPos = self:GetPos()

	if !self.collided and data.HitEntity ~= self:GetMyParent() then
		self.collided = true
		self:SetPerformPiss( true )
		self:SetNetworkPos( self.myPos )
		self.performDelay = CurTime() + 0.1
	end
end

function ENT:ParticleEmitExplode()
	local fx = self.emitter:Add( self.droplet, self.myPos )

	--piss
	fx:SetDieTime( 1 )
	fx:SetStartAlpha( 255 )
	fx:SetEndAlpha( 0 )

	fx:SetStartSize( 3 )
	fx:SetEndSize( 0 )
	local cc = Vector( 255, 222, 79 ) * self.lightPwr
	fx:SetColor( cc[1], cc[2], cc[3] )

	fx:SetAngles( Angle ( math.random( -180, 180 ), math.random( -180, 180 ), math.random( -180, 180 ) ) )
	fx:SetVelocity( Vector( math.random( -750, 750 ), math.random( -750, 750 ), math.random( -250, 250 ) ) )
	fx:SetGravity( Vector( 0, 0, -1000 ) )

	fx:SetCollide( true )

	--glass
	fx = self.emitter:Add( Material ( "effects/fleck_glass" .. tostring( math.random( 1, 3 ) ) ), self.myPos )

	fx:SetDieTime( 4 )
	fx:SetStartAlpha( 100 )
	fx:SetEndAlpha( 0 )

	fx:SetStartSize( 4 )
	fx:SetEndSize( 1 )
	local cc = Vector( 255, 255, 255 ) * self.lightPwr
	fx:SetColor( cc[1], cc[2], cc[3] )

	fx:SetAngles( Angle ( math.random( -180, 180 ), math.random( -180, 180 ), math.random( -180, 180 ) ) )
	fx:SetVelocity( Vector( math.random( -250, 250 ), math.random( -250, 250 ), math.random( 100, 500 ) ) )
	fx:SetGravity( Vector( 0, 0, -1000 ) )

	fx:SetCollide( true )
end

function ENT:PissExplosion()
	--print("splosion!")

	local targets = ents.FindInSphere( self.myPos, self.range )

	--PrintTable(targets)

	for _,v in pairs(targets) do
		if v:IsPlayer() or v:IsNPC() or v:IsNextBot() then
			local place = v:GetPos() --pos of the victim
			local trData = {
				start = self.myPos + Vector( 0, 0, 16 ),
				endpos = place + Vector( 0, 0, 32 ),
				filter = self,
				mask = 32827, --world + water
				--mask = 33570819,
				--collisiongroup = 0,
				--ignoreworld = false,
			}

			local tr = util.TraceLine( trData )

			/*
			if CLIENT then
			debugoverlay.Sphere( self.myPos, self.range, 2, Color( 255, 255, 255 ), false )

			debugoverlay.Line( self.myPos + Vector( 0, 0, 16 ), place + Vector( 0, 0, 32 ), 2, Color( 255, 255, 255 ), false )
			end
			*/

			--print(tr.Entity)

			if !tr.Hit then
			--if tr.Entity == v then --too many times it does not apply when it should
				--print("hit!")

				v.orange_blossom_pissed = self.time + self.duration --mark the entity as jarated until that time
				table.insert( self.pissed, v ) --table of all currently jarated players
				v:SetColor(self.colPiss)
				self:ManipulateBoneScale( 0, Vector( 0.01, 0.01, 0.01 ) )

				self.doPiss = true
			end
		end
	end

	if CLIENT then
		self:SetNoDraw( true ) --unreliable, especially in singleplayer

		--checking the color of the spawn pos
		local clr = render.GetLightColor( self:GetPos() )
		local R = math.Clamp( clr[1] * 1000 + 15, 1, 255 )
		local G = math.Clamp( clr[2] * 1000 + 15, 1, 255 )
		local B = math.Clamp( clr[3] * 1000 + 15, 1, 255 )

		self.lightPwr = math.Clamp( (R + G + B) / 255, 0, 1 )
		--print( self.lightPwr )

		for i = 1, 30 do
			self:ParticleEmitExplode()
		end

		local fx = self.emitter:Add( self.splash, self.myPos )

		--mega piss
		fx:SetDieTime( 0.2 )
		fx:SetStartAlpha( 255 )
		fx:SetEndAlpha( 0 )
		fx:SetLighting( false )

		fx:SetStartSize( 1 )
		fx:SetEndSize( 132 )
		local cc = Vector( 211, 170, 40 ) * self.lightPwr
		fx:SetColor( cc[1], cc[2], cc[3] )
	else
		sound.Play( "physics/glass/glass_pottery_break4.wav", self.myPos, 75, math.random( 90, 110 ), 1 )
		sound.Play( self.slosh, self.myPos, 75, math.random( 90, 110 ), 1 )
		--util.Decal( "BeerSplash", self.myPos, self.myPos - Vector(0,0,32) )

		if self.doPiss then
			self.byeBye = self.time + self.duration
			--self:ApplyJarateServer()
		else
			self:Remove()
		end
	end
end

function ENT:Think()
	--print(self:GetPos())

	self.time = CurTime()
	self.myPos = self:GetNetworkPos()

	if self.doPiss then
		for _,v in pairs(self.pissed) do --water washes off piss
			--if I do: if !IsValid(v) then return, then the whole function starts over and locks

			if IsValid(v) and v:WaterLevel() >= 2 then
				v.orange_blossom_pissed = 0
				v:SetColor(self.colNormal) --color is permanent for players unless restored
			end

			if IsValid(v) and v:IsPlayer() and !v:Alive() then --fix for effect remaining after death
				v.orange_blossom_pissed = 0
				v:SetColor(self.colNormal) --color is permanent for players unless restored
			end

			if CLIENT and IsValid(v) and v.orange_blossom_pissed ~= nil and v.orange_blossom_pissed > self.time then
				local dropPos = v:GetPos() + Vector( math.random( -8, 8 ), math.random( -8, 8 ), math.random( 32, 50 ) )

				local fx = self.emitter:Add( self.droplet, dropPos + Vector( math.random( -8, 8 ), math.random( -8, 8 ), 0 ) )

				local clr = render.GetLightColor( dropPos )
				local R = math.Clamp( clr[1] * 1000 + 15, 1, 255 )
				local G = math.Clamp( clr[2] * 1000 + 15, 1, 255 )
				local B = math.Clamp( clr[3] * 1000 + 15, 1, 255 )

				local lightPwr = math.Clamp( (R + G + B) / 255, 0, 1 )

				fx:SetDieTime( 1 )
				fx:SetStartAlpha( 255 )
				fx:SetEndAlpha( 0 )

				fx:SetStartSize( 1 )
				fx:SetEndSize( 0 )
				local cc = Vector( 255, 222, 79 ) * lightPwr
				fx:SetColor( cc[1], cc[2], cc[3] )
				--fx:SetColor( 255, 222, 79 )

				fx:SetGravity( Vector( 0, 0, -250 ) )

				fx:SetCollide( false )
			end
		end

		--piss overlay
		if CLIENT and LocalPlayer().orange_blossom_pissed ~= nil then
			hook.Remove( "RenderScreenspaceEffects", "Overlay_PissHook" )

			if LocalPlayer():Alive() and LocalPlayer().orange_blossom_pissed > self.time then
				hook.Add( "RenderScreenspaceEffects", "Overlay_PissHook", function()
					DrawMaterialOverlay( "models/orange_blossom/piss/piss_overlay", -0.05 )
				end )
			end
		end
	end

	--logic to execute after collided turns true
	--Gmod's networking is unpredictible so I had to manually implement a delay

	--self:SetPerformPiss( false ) --too slow

	if CLIENT and self:GetPerformPiss() and !self.didOnce then
		self:PissExplosion()
		self.didOnce = true
	end

	if SERVER and self.performDelay < self.time then
		self:PissExplosion()
		self.performDelay = 999999
	end

	if CLIENT then
		self:SetNextClientThink( CurTime() + 0.05 )
		return true
	else
		if self.byeBye < self.time then
			self:Remove()
		end

		self:NextThink( CurTime() + 0.1 )
		return true
	end
end

function ENT:OnRemove()
	self.time = CurTime()

	for _,v in pairs(self.pissed) do
		if IsValid(v) and v.orange_blossom_pissed ~= nil and v.orange_blossom_pissed <= self.time then
			v:SetColor(self.colNormal) --color is permanent for players unless restored

			if CLIENT and v == LocalPlayer() then
				hook.Remove( "RenderScreenspaceEffects", "Overlay_PissHook" ) --stupid safeguard
			end
		end
	end

	if CLIENT and IsValid( self.emitter ) then
		self.emitter:Finish()
	end
end 