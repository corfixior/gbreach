-- Visual attachment of SCP-035 mask on player faces

local MASK_MODEL = "models/scp_035_real/scp_035_real.mdl"

-- Tabela przechowująca modele klienckie
local maskModels = {}

hook.Add("PostPlayerDraw", "BR_SCP035_RenderMask", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    -- Sprawdź czy gracz jest SCP-035
    local is035 = false
    if ply.GetNClass then
        is035 = (ply:GetNClass() == ROLES.ROLE_SCP035)
    end
    if not is035 then
        -- Usuń ewentualny model gdy gracz przestał być 035
        if maskModels[ply] and IsValid(maskModels[ply]) then
            maskModels[ply]:Remove()
            maskModels[ply] = nil
        end
        return
    end

    -- Utwórz model jeśli nie istnieje
    if not IsValid(maskModels[ply]) then
        local mdl = ClientsideModel(MASK_MODEL, RENDERGROUP_OPAQUE)
        mdl:SetNoDraw(true)
        maskModels[ply] = mdl
    end

    local mdl = maskModels[ply]
    if not IsValid(mdl) then return end

    -- Pobierz attachment "eyes" (fallback do głowy)
    local id = ply:LookupAttachment("eyes")
    local pos, ang
    if id and id > 0 then
        local att = ply:GetAttachment(id)
        if att then
            pos = att.Pos
            ang = att.Ang
        end
    end
    if not pos then -- fallback to head bone
        local boneId = ply:LookupBone("ValveBiped.Bip01_Head1")
        if boneId then
            local matrix = ply:GetBoneMatrix(boneId)
            if matrix then
                pos = matrix:GetTranslation()
                ang = matrix:GetAngles()
            end
        end
    end
    if not pos then return end

    -- Pozycjonowanie – lekkie odsunięcie do przodu
    local forward = ang:Forward()
    pos = pos + forward * 4 -- dystans od twarzy

    mdl:SetPos(pos)
    mdl:SetAngles(ang)
    mdl:DrawModel()
end)

-- Sprzątanie po disconnect / zmianie mapy
hook.Add("EntityRemoved", "BR_SCP035_CleanupMask", function(ent)
    if maskModels[ent] and IsValid(maskModels[ent]) then
        maskModels[ent]:Remove()
        maskModels[ent] = nil
    end
end)

hook.Add("PostCleanupMap", "BR_SCP035_CleanupAll", function()
    for ply, mdl in pairs(maskModels) do
        if IsValid(mdl) then mdl:Remove() end
    end
    maskModels = {}
end) 