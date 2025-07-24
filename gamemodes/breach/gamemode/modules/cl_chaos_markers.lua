-- System oznaczania CI Spy i Agent CI
-- Wyświetla oznaczenie "Ally" nad głową CI Spy i Agent CI

hook.Add("HUDPaint", "DrawChaosMarkers", function()
    local localPlayer = LocalPlayer()
    
    if not IsValid(localPlayer) then return end
    
    local canSeeMarkers = false
    local isClassD = localPlayer:GTeam() == TEAM_CLASSD
    local isChaos = localPlayer:GTeam() == TEAM_CHAOS
    
    -- Klasa D może widzieć oznaczenia
    if isClassD then
        canSeeMarkers = true
    -- Wszyscy członkowie Chaos mogą widzieć oznaczenia
    elseif isChaos then
        canSeeMarkers = true
    end
    
    if not canSeeMarkers then
        return
    end
    
    -- Przejdź przez wszystkich graczy
    for _, ply in pairs(player.GetAll()) do
        if not IsValid(ply) or ply == localPlayer or not ply:Alive() then
            continue
        end
        
        -- Określ kogo pokazywać na podstawie obserwującego
        local shouldShowMarker = false
        
        if isClassD then
            -- Klasa D widzi tylko CI Spy i Agent CI (nie CI Soldier)
            if ply:GTeam() == TEAM_CHAOS and (ply:GetNClass() == ROLES.ROLE_CHAOSSPY or ply:GetNClass() == ROLES.ROLE_CIC) then
                shouldShowMarker = true
            end
        elseif isChaos then
            -- Wszyscy Chaos widzą CI Spy i Agent CI
            if ply:GTeam() == TEAM_CHAOS and (ply:GetNClass() == ROLES.ROLE_CHAOSSPY or ply:GetNClass() == ROLES.ROLE_CIC) then
                shouldShowMarker = true
            end
        end
        
        if shouldShowMarker then
            local headPos = ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Head1") or 0)
            if headPos == Vector(0,0,0) then
                headPos = ply:GetPos() + Vector(0, 0, 75)
            else
                headPos = headPos + Vector(0, 0, 15)
            end
            
            -- Sprawdź czy gracz jest widoczny (nie za ścianą)
            local trace = util.TraceLine({
                start = localPlayer:GetShootPos(),
                endpos = ply:GetShootPos(),
                filter = {localPlayer, ply},
                mask = MASK_SOLID_BRUSHONLY
            })
            
            -- Jeśli trace trafił w ścianę, nie pokazuj oznaczenia
            if trace.Hit then
                continue
            end
            
            local screenPos = headPos:ToScreen()
            
            -- Sprawdź czy pozycja jest na ekranie
            if screenPos.visible then
                -- Rozmiar ikony
                local iconSize = 40
                
                -- Ustaw material ikony CI
                surface.SetMaterial(Material("breach/ci.png"))
                surface.SetDrawColor(255, 255, 255, 255)
                
                -- Narysuj ikonkę CI
                surface.DrawTexturedRect(
                    screenPos.x - iconSize/2,
                    screenPos.y - iconSize/2,
                    iconSize,
                    iconSize
                )
            end
        end
    end
end)