hook.Add("KeyPress", "keypress_throw_canebar", function(ply, key)
    local throwlist = {
        "weapon_house_canebar",
    }
    throw = ply:GetActiveWeapon()
    if (ply:Alive())
    and ply:KeyPressed(IN_RELOAD)
    and table.HasValue(throwlist, throw:GetClass()) then

        ply:ViewPunch(Angle(math.random(1, 0), math.random(-0.5, -0.5), 0))

        if SERVER then
            ply:StripWeapon("weapon_house_canebar")
            t_canebar = ents.Create("canebar")
            if (IsValid(t_canebar)) then
                ang = ply:EyeAngles() + Angle(math.random(-2, -3), math.random(1.8, -0.9), 25)
                t_canebar:SetPos(ply:GetShootPos() + ang:Forward() * 1 + ang:Right() * 1.5 - ang:Up() * 0)
            end

            t_canebar:SetAngles(ang)
            t_canebar:Spawn()
            t_canebar:SetOwner(ply)
            local phys = t_canebar:GetPhysicsObject()
            if (IsValid(phys)) then
                phys:Wake()
                phys:AddVelocity(t_canebar:GetForward() * 800)
                phys:AddAngleVelocity(Vector(0, 1500, 0))
                ply:EmitSound(Sound("Weapon_Crowbar.Single"))
            end
        end
    end
end) 