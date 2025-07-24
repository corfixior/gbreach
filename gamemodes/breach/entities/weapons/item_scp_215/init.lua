AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
include("sv_hooks.lua")

-- Network strings dla komunikacji client-server
util.AddNetworkString("SCP215_ToggleDetection")
util.AddNetworkString("SCP215_SyncState")

function SWEP:Deploy()
	if not IsFirstTimePredicted() then return end
	
	-- Sprawdź czy gracz może używać SCP-215
	if self.Owner:GTeam() == TEAM_SCP or self.Owner:GTeam() == TEAM_SPEC then
		if SERVER then
			timer.Simple(0.1, function()
				if IsValid(self.Owner) then
					self.Owner:StripWeapon("item_scp_215")
				end
			end)
		end
		return
	end
	
	self.Owner:DrawViewModel(false)

	if SERVER then
		-- Upewnij się, że broń zna aktualny stan wykrywania gracza
		self.IsActive = self.Owner:GetNWBool("SCP215_Active", false)
		-- Synchronizuj z klientem
		self:SyncToClient()
	end
	
	return true
end

function SWEP:Holster()
	if not IsFirstTimePredicted() then return end
	
	-- Wyłącz wykrywanie gdy chowamy broń
	if SERVER and self.IsActive then
		self:SetDetection(false)
	end
	
	return true
end

function SWEP:OnRemove()
	if SERVER and IsValid(self.Owner) then
		-- Wyłącz wykrywanie
		self:SetDetection(false)
		
		-- Wyczyść network vars
		self.Owner:SetNWBool("SCP215_Active", false)
	end
end

function SWEP:PrimaryAttack()
	if not IsFirstTimePredicted() then return end
	if preparing or postround then return end
	
	-- Toggle wykrywania
	self:ToggleDetection()
end

function SWEP:SecondaryAttack()
	-- Brak secondary attack
end

function SWEP:ToggleDetection()
	if SERVER then
		if self.IsActive then
			-- Wyłącz wykrywanie
			self:SetDetection(false)
			
			-- Sprawdź czy okulary pękną (20% szansy)
			if math.random(1, 100) <= 20 then
				self:BreakGlasses()
				return
			end
		else
			-- Włącz wykrywanie
			self:SetDetection(true)
			
			-- Sprawdź czy okulary pękną (12% szansy przy włączaniu)
			if math.random(1, 100) <= 12 then
				self:BreakGlasses()
				return
			end
		end
	end
end

if SERVER then
	function SWEP:SetDetection(active)
		if not IsValid(self.Owner) then return end
		
		self.IsActive = active
		
		-- Sync z klientem
		self:SyncToClient()
	end
	
	function SWEP:BreakGlasses()
		if not IsValid(self.Owner) then return end
		
		-- Zapisz referencję do gracza przed usunięciem broni
		local owner = self.Owner
		
		-- Wyłącz wykrywanie
		self:SetDetection(false)
		
		-- Wyczyść network vars przed usunięciem broni
		owner:SetNWBool("SCP215_Active", false)
		
		-- Efekt dźwiękowy pękania szkła
		owner:EmitSound("physics/glass/glass_impact_break" .. math.random(1, 4) .. ".wav")
		
		-- Usuń broń z gracza (na końcu)
		owner:StripWeapon("item_scp_215")
	end
	
	function SWEP:SyncToClient()
		if not IsValid(self.Owner) then return end
		
		self.Owner:SetNWBool("SCP215_Active", self.IsActive)
	end
end

function SWEP:Think()
	if not IsFirstTimePredicted() then return end
	
	-- Sync z serwerem
	if CLIENT then
		self.IsActive = self.Owner:GetNWBool("SCP215_Active", false)
	end
	
	-- Sprawdź czy gracz nadal trzyma okulary
	if SERVER and self.IsActive then
		local activeWep = self.Owner:GetActiveWeapon()
		if not IsValid(activeWep) or activeWep ~= self then
			-- Gracz przestał trzymać okulary - wyłącz wykrywanie
			self:SetDetection(false)
		end
	end
end

function SWEP:DrawWorldModel()
	if not IsValid(self.Owner) then
		self:DrawModel()
	else
		-- Zawsze rysuj world model
		self:DrawModel()
	end
end