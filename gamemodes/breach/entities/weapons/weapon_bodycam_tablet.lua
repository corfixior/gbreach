SWEP.PrintName = "Tactical Bodycam Tablet"
SWEP.Author = "Antek"
SWEP.Category = "[Antke] Bodycam Tablet"
SWEP.Purpose = "RMB – Attach camera | R – Open tablet"

SWEP.Spawnable = true

SWEP.UseHands = true
SWEP.ViewModel = "models/v_item_pda.mdl"
SWEP.WorldModel = "models/v_item_pda.mdl"
SWEP.ViewModelFOV = 80
SWEP.SwayScale = 0.1
SWEP.BobScale = 0.1

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

local lastAngles = Angle(0, 0, 0)

function SWEP:Initialize()
    self:SetHoldType("camera")
    self.BodyCamPeople = {}
    self.PDAOpen = false
    
    -- Zabezpieczenie dla ConVars - tworzenie jeśli nie istnieją
    if SERVER and not GetConVar("bodycam_max_people") then
        CreateConVar("bodycam_max_people", "3", FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "", 1)
        CreateConVar("bodycam_time_to_attach", "10", FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "", 1)
    end
end


function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_HOLSTER)
    self:ResetSequence(self:LookupSequence("Holster"))
    self:EmitSound("Stalker2.PDAEquip")
    self.PDAOpen = false
    self:SetNWBool("PDAOpen", false)
    return true
end

function SWEP:OpenAnim()
    self:SendWeaponAnim(ACT_VM_DRAW)
    self:ResetSequence(self:LookupSequence("Draw"))
    self:EmitSound("Stalker2.PDAEquip")
end

function SWEP:Reload()
    if self:GetNextPrimaryFire() > CurTime() then return end
    self:SetNextPrimaryFire(CurTime() + 2)
    self.PDAOpen = not self.PDAOpen

    if self.PDAOpen then
        self:OpenAnim()
    else
        self:Deploy()
    end

    for i = #self.BodyCamPeople, 1, -1 do
        local ent = self.BodyCamPeople[i]
        if not IsValid(ent) then
            table.remove(self.BodyCamPeople, i)
        end
    end

    net.Start("BodycamPlayers")
        net.WriteTable(self.BodyCamPeople)
    net.Send(self.Owner)

    self.Owner:Freeze(true)
    self:SetNWBool("PDAOpen", self.PDAOpen)
    self.Owner:SetNWBool("BodycamTabletOpen", self.PDAOpen)

    timer.Simple(1, function()
        self.Owner:Freeze(false)
    end)
end

if SERVER then 
    util.AddNetworkString("BodycamPlayers")
    util.AddNetworkString("Bodycam_Voice")
    util.AddNetworkString("Bodycam_Micro")
    util.AddNetworkString("Bodycam_SelectedTarget")
    util.AddNetworkString("Frame_Remove")
end

function SWEP:Holster()
    if self.PDAOpen and IsValid(self.Owner) and self.Owner:Alive() then
        timer.Simple(1, function()
            self.PDAOpen = false
            self:Holster()
        end)
        self:SendWeaponAnim(ACT_VM_HOLSTER)
        self:EmitSound("Stalker2.PDAUnequip")
        return false
    end
    return true
end

function SWEP:SecondaryAttack()
    if self:GetNextSecondaryFire() > CurTime() then return end
    self:SetNextSecondaryFire(CurTime() + 2)

    local trace = util.QuickTrace(self.Owner:EyePos(), self.Owner:GetAimVector() * 80, self.Owner)
    local tr = trace.Entity

    if not IsValid(tr) or (not tr:IsPlayer() and not tr:IsNPC()) then return end

    for _,v in ipairs(self.BodyCamPeople) do
        if v == tr then
                self.Owner:ChatPrint("You have already set up a Bodycam") 
            return 
        end 
    end

    if IsValid(tr:GetNWEntity("BodyCam")) then self.Owner:ChatPrint("Already has a Bodycam") return end

    for i = #self.BodyCamPeople, 1, -1 do
        local ent = self.BodyCamPeople[i]
        if not IsValid(ent) then
            table.remove(self.BodyCamPeople, i)
        end
    end



    local attname = "eyes"
    local head = tr:LookupAttachment(attname)

        if head == 0 then
            attname = "Eye"
            head = tr:LookupAttachment(attname)
        end
    
    if head == 0 then self.Owner:ChatPrint("This target can't have bodycam") return end

    local maxPeople = GetConVar("bodycam_max_people")
    local attachTime = GetConVar("bodycam_time_to_attach")
    
    if not maxPeople or not attachTime then
        self.Owner:ChatPrint("Bodycam ConVars not loaded")
        return
    end
    
    if table.Count(self.BodyCamPeople) >= maxPeople:GetInt() then self.Owner:ChatPrint("All Bodycams is in use") return end

    self:SetNWEntity("HoldingTarget", tr)
    self:SetNWFloat("HoldingTime", CurTime() + attachTime:GetInt())
    self:SetNWInt("bodycam_time_to_attach_cl", attachTime:GetInt())

    timer.Create("SWEPHOLDING" .. self:EntIndex(), attachTime:GetInt(), 1, function()
        if not IsValid(self) or not IsValid(self.Owner) then return end
        local ent = self:GetNWEntity("HoldingTarget")
        if not IsValid(ent) then return end

        if self:GetNWFloat("HoldingTime") > CurTime() then return end

        table.insert(self.BodyCamPeople,ent)
        ent:SetNWEntity("BodyCam", self)
    end)
end



function SWEP:Think()
    local owner = self:GetOwner()
    local target = self:GetNWEntity("HoldingTarget")

    if self:GetNWFloat("HoldingTime") > CurTime() then
        if not owner:KeyDown(IN_ATTACK2) or not IsValid(target) or owner:GetEyeTrace().Entity ~= target then 
            self:SetNWEntity("HoldingTarget", NULL)
            self:SetNWFloat("HoldingTime", CurTime())
            timer.Remove("SWEPHOLDING" .. self:EntIndex())
            return
        end
    end
end

function SWEP:PrimaryAttack()
end

if CLIENT then
    function SWEP:DrawHUD()
        local target = self:GetNWEntity("HoldingTarget")
        if not IsValid(target) then return end

        local endTime = self:GetNWFloat("HoldingTime")
        local timeLeft = endTime - CurTime()
        if timeLeft <= 0 then return end

        local bodycam_time_to_attach_cl = self:GetNWInt("bodycam_time_to_attach_cl")
        local maxTime = bodycam_time_to_attach_cl
        local progress = 1 - (timeLeft / maxTime)
        progress = math.Clamp(progress, 0, 1)

        local x, y = ScrW(), ScrH()

        local r = 255 * (1 - progress)
        local g = 255 * progress
        local b = 0
        local barColor = Color(r, g, b)

        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawOutlinedRect(x * 0.4, y * 0.5 + 206, 400, 40, 2)

        surface.SetDrawColor(68, 68, 68, 200)
        surface.DrawRect(x * 0.4 + 1, y * 0.5 + 207, 398, 38)

        surface.SetDrawColor(barColor)
        surface.DrawRect(x * 0.4 + 1, y * 0.5 + 208, 398 * progress, 36)
    end
end




if SERVER then
    hook.Add("SetupPlayerVisibility", "AddRTCamera", function(ply, viewEntity)
        local wpn = ply:GetActiveWeapon()
        if not IsValid(wpn) or wpn:GetClass() ~= "weapon_bodycam_tablet" then return end
        local target = wpn:GetNWEntity("BodyCam")
        if not IsValid(target) then return end
        if ply:TestPVS(target:GetPos()) then return end

        AddOriginToPVS(target:GetPos())
    end)
end

hook.Add("PlayerDeath", "bodycam_target_death", function(target, wpn, ply)
    if not IsValid(target) then return end
    local watcher_wpn = target:GetNWEntity("BodyCam")
    if not IsValid(watcher_wpn) then return end
    
    -- Usuń gracza z listy kamer
    table.RemoveByValue(watcher_wpn.BodyCamPeople, target)
    target:SetNWEntity("BodyCam", NULL)
    
    -- Wyślij zaktualizowaną listę do klienta
    if IsValid(watcher_wpn.Owner) then
        net.Start("BodycamPlayers")
            net.WriteTable(watcher_wpn.BodyCamPeople)
        net.Send(watcher_wpn.Owner)
    end

    -- Zamknij tablet jeśli był otwarty, aby odświeżyć UI
    if watcher_wpn.PDAOpen then
        watcher_wpn:Deploy()
    end
end)

function SWEP:CalcView(player, pos, viewAngles, fov)
    local VModel = self:GetOwner():GetViewModel()
    local attachmentID = self:LookupAttachment("1")
    local attachment = self:GetAttachment(attachmentID)

    if attachment then
        local seqAct = VModel:GetSequenceActivity(VModel:GetSequence())
        if seqAct == ACT_VM_DRAW then
            local newAngle = attachment.Ang - self:GetAngles()
            lastAngles = LerpAngle(0.1, lastAngles, newAngle)
            viewAngles:Add(lastAngles)
        elseif seqAct == ACT_VM_HOLSTER then
            local newAngle = Angle(0, 0, 0)
            lastAngles = LerpAngle(0.1, lastAngles, newAngle)
            viewAngles:Add(lastAngles)
        end
    end

    return pos, viewAngles, fov
end

if CLIENT then
    local WorldModel = ClientsideModel(SWEP.WorldModel)
    WorldModel:SetNoDraw(true)

    function SWEP:DrawWorldModel()
        local _Owner = self:GetOwner()

        if IsValid(_Owner) then
            local offsetVec = Vector(-1, -4, -1.6)
            local offsetAng = Angle(15, -10, -165)
            local boneid = _Owner:LookupBone("ValveBiped.Bip01_R_Hand")
            if not boneid then return end

            local matrix = _Owner:GetBoneMatrix(boneid)
            if not matrix then return end

            local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
            WorldModel:SetPos(newPos)
            WorldModel:SetAngles(newAng)
            WorldModel:SetupBones()
        else
            WorldModel:SetPos(self:GetPos())
            WorldModel:SetAngles(self:GetAngles())
        end

        WorldModel:DrawModel()
    end
end

net.Receive("Frame_Remove", function(len, ply)
    if IsValid(ply) and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "weapon_bodycam_tablet" then
        ply:GetActiveWeapon():Reload()
    end
end)

-- Zabezpieczenie dla net receivers
if SERVER then
    net.Receive("Bodycam_Voice", function(_, ply)
        if IsValid(ply) then
            ply:SetNWBool("Bodycam_AllowVoice", net.ReadBool())
        end
    end)

    net.Receive("Bodycam_Micro", function(_, ply)
        if IsValid(ply) then
            ply:SetNWBool("Bodycam_AllowMic", net.ReadBool())
        end
    end)

    net.Receive("Bodycam_SelectedTarget", function(_, ply)
        if IsValid(ply) then
            ply:SetNWEntity("Bodycam_SelectedTarget", net.ReadEntity())
        end
    end)
end

if CLIENT then
    frejmus = frejmus or {}
    target_index = 1

    ffff_b = Color(30,30,30,200)
    fff_b  = Color(35,35,35,255)
    ff_b   = Color(40,40,40,255)
    f_b    = Color(47,47,47,255)
    w_f_b  = Color(52,52,52,255)
    white_col = Color(255,255,255,255)
    ww_f_b = Color(60,60,60)

    surface.CreateFont("Antek4", {
        font      = "Tahoma",
        extended  = true,
        size      = ScreenScale(35)
    })

    surface.CreateFont("CameraFont", {
        font      = "Monaspace Krypton",
        extended  = true,
        size      = 25,
        weight    = 500,
        blursize  = 0,
        scanlines = 0,
        antialias = true,
    })

    function GetName(target)
        if not IsValid(target) then return "ERROR" end
            if target:IsNPC() then
                local class = target:GetClass()
                local info = list.Get("NPC")[class]
                    return info and info.Name or class or "ERROR"
                elseif target:IsPlayer() then
                    return target:GetName()
            end
    end

    net.Receive("BodycamPlayers",function()
        target_tbl = net.ReadTable()
    end)

    -- Inicjalizuj target_tbl jako pustą tabelę
    target_tbl = target_tbl or {}

        function Dermas()
            if IsValid(frejmus.frame) then return end

                -- Zabezpieczenie dla target_tbl
                target_tbl = target_tbl or {}
                local max_index = table.Count(target_tbl)
                
                -- Popraw indeks jeśli wykracza poza zakres lub lista jest pusta
                if max_index == 0 then
                    target_index = 1
                elseif target_index > max_index then
                    target_index = math.max(1, max_index)
                end
                
                -- Sprawdź czy target_tbl istnieje i nie jest puste
                local target = nil
                if target_tbl and max_index > 0 then
                    target = target_tbl[target_index]
                end

                -- Wyślij informację o wybranym celu tylko jeśli istnieje
                if IsValid(target) then
                    net.Start("Bodycam_SelectedTarget")
                        net.WriteEntity(target)
                    net.SendToServer()
                end

            frejmus.frame = vgui.Create("DPanel")
            local frame = frejmus.frame
            local x, y = ScrW()/1920, ScrH()/1080
            frame:SetSize(x*1570, y*865)
            frame:SetPos(x*180, y*100)
            frame:MakePopup()
            frame:SetZPos(-1000)
            frame:SetPopupStayAtBack(true)
            frame:SetDrawOnTop(false)
            frame:SetKeyboardInputEnabled(false) 
            frame:SetMouseInputEnabled(true)

            frame.Paint = function(self, w, h)
                draw.RoundedBox(8, 0, 0, w, h, ffff_b)
                draw.SimpleText( target and IsValid(target) and "" or "No Connection..", "Antek4", w * 0.5, h * 0.5, Color(228,228,228), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            LocalPlayer():SetNWBool("BodycamTabletOpen", true)


            if IsValid(target) then

                local shouldDrawPlayer = false

                hook.Add("ShouldDrawLocalPlayer", "drawplayer_tablet", function()
                    return shouldDrawPlayer
                end)

                local render_vi = vgui.Create("DFrame", frame)
                render_vi:SetPos(0, 0)
                render_vi:SetSize(frame:GetWide(), frame:GetTall())
                render_vi:ShowCloseButton(false)
                render_vi:SetZPos(-50)
                render_vi:SetTitle("")
                render_vi:SetDraggable(false)

                local light = false

                render_vi.Paint = function(me, w, h)

                    if not target.LookupAttachment then return end

                    local attname = "eyes"
                    local head = target:LookupAttachment(attname)

                    if head == 0 then
                        attname = "Eye"
                        head = target:LookupAttachment(attname)
                    end

                    if not IsValid(target) or not target:Alive() or not LocalPlayer():Alive() or not IsValid(LocalPlayer()) or (head == 0) then
                        if head == 0 then 
                            LocalPlayer():ChatPrint("This target can't have bodycam")
                        end
                        frame:Remove()
                        if IsValid(LocalPlayer()) then
                            local wep = LocalPlayer():GetActiveWeapon()
                            if IsValid(wep) then
                                wep:SetNWEntity("BodyCam", nil)
                                LocalPlayer():SetNWBool("BodycamTabletOpen", false)
                            end
                        end

                        return
                    end

                    shouldDrawPlayer = true
                    draw.RoundedBox(8, 0, 0, w, h, Color(0,0,0,100))

                    local posx, posy = me:GetX() + frame:GetX(), me:GetY() + frame:GetY()

                    if not target.GetAttachment then return end
                    local attachment = target:GetAttachment(head)
                    if not attachment or not attachment.Pos or not attachment.Ang then
                        return
                    end

                    if w <= 0 or h <= 0 then return end

                    local old = DisableClipping( true )

                    render.RenderView({
                        origin = attachment.Pos,
                        angles = attachment.Ang,
                        x = posx, y = posy,
                        w = w, h = h,
                        fov = 125,
                        drawviewmodel = false,
                        drawhud = true,
                    })

                    DisableClipping( old )

                    shouldDrawPlayer = false

                    local time = os.date("%Y-%m-%d %H:%M:%S")
                    draw.SimpleText("CAM-0".. target_index .. " " .. time, "CameraFont", w * 0.97, h * 0.03, Color(255,255,255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT)
                    draw.SimpleText(GetName(target), "CameraFont", w * 0.97, h * 0.07, Color(255,255,255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT)

                    local dlight = DynamicLight(target:EntIndex())
                    if dlight and light then
                        dlight.pos = target:EyePos()
                        dlight.r, dlight.g, dlight.b = 0, 10, 0
                        dlight.brightness = 5
                        dlight.Decay = 1000
                        dlight.Size = 10000
                        dlight.DieTime = CurTime() + 0.1
                        dlight.noworld = false
                    end

                end

                local nightBtn = vgui.Create("DButton", render_vi)
                nightBtn:SetText("")
                nightBtn:SetPos(render_vi:GetWide() * 0.93, render_vi:GetTall() * 0.9)
                nightBtn:SetSize(render_vi:GetWide() * 0.06, render_vi:GetTall() * 0.1)
                nightBtn:SetZPos(100)

                    local nightIcon = Material("materials/vgui/night.png")
                    nightBtn.Paint = function(me, w, h)
                        local col = me:IsHovered() and Color(39, 57, 138) or Color(255,255,255)
                        surface.SetMaterial(nightIcon)
                        surface.SetDrawColor(light and Color(0,0,0) or col)
                        surface.DrawTexturedRect(10, 10, w - 20, h - 20)
                    end
                    nightBtn.DoClick = function() light = not light end
                    
                local voiceBtn = vgui.Create("DButton", render_vi)
                voiceBtn:SetText("")
                voiceBtn:SetPos(render_vi:GetWide() * 0.87, render_vi:GetTall() * 0.9)
                voiceBtn:SetSize(render_vi:GetWide() * 0.06, render_vi:GetTall() * 0.1)
                voiceBtn:SetZPos(100)

                    local voice = true

                        local voicephicon = Material("materials/vgui/voice.png")
                        local voicephicon_muted = Material("materials/vgui/voice_muted.png")

                    voiceBtn.Paint = function(me, w, h)
                        surface.SetMaterial(voice and voicephicon or voicephicon_muted)
                        surface.SetDrawColor(voice and Color(255,255,255) or Color(237, 66, 69))
                        surface.DrawTexturedRect(10, 10, w - 20, h - 20)
                    end

                    voiceBtn.DoClick = function() 
                        voice = not voice
                        net.Start("Bodycam_Voice")
                            net.WriteBool(voice)
                        net.SendToServer()
                    end

                if not target:IsNPC() then
                    local microphBtn = vgui.Create("DButton", render_vi)
                    microphBtn:SetText("")
                    microphBtn:SetPos(render_vi:GetWide() * 0.81, render_vi:GetTall() * 0.9)
                    microphBtn:SetSize(render_vi:GetWide() * 0.06, render_vi:GetTall() * 0.1)
                    microphBtn:SetZPos(100)

                        local micro = false

                            local microphicon = Material("materials/vgui/microphone.png")
                            local microphicon_muted = Material("materials/vgui/microphone_muted.png")

                        microphBtn.Paint = function(me, w, h)
                            surface.SetMaterial(micro and microphicon or microphicon_muted)
                            surface.SetDrawColor(micro and Color(255,255,255) or Color(237, 66, 69))
                            surface.DrawTexturedRect(10, 10, w - 20, h - 20)
                        end

                        microphBtn.DoClick = function() 
                            micro = not micro
                            net.Start("Bodycam_Micro")
                                net.WriteBool(micro)
                            net.SendToServer()
                        end
                end

                local last_index = #target_tbl

                local function CreateArrowButton(dir, xPos, iconPath)
                    local btn = vgui.Create("DButton", render_vi)
                    btn:SetText("")
                    btn:SetPos(xPos, render_vi:GetTall() * 0.375)
                    btn:SetSize(render_vi:GetWide() * 0.1, render_vi:GetTall() * 0.25)
                    btn:SetZPos(100)

                    local icon = Material(iconPath)
                    btn.Paint = function(self, w, h)
                        surface.SetMaterial(icon)
                        surface.SetDrawColor(self:IsHovered() and Color(255, 255, 255) or Color(255, 255, 255, 50))
                        surface.DrawTexturedRect(10, 10, w - 20, h - 20)
                    end

                    btn.DoClick = function()
                        -- Zabezpieczenie dla aktualnej liczby celów
                        local current_max = table.Count(target_tbl or {})
                        if current_max > 0 then
                            target_index = math.Clamp(target_index + (dir == "right" and 1 or -1), 1, current_max)
                            frame:Remove()
                            timer.Simple(0.05, Dermas)
                        end
                    end
                end

                -- Twórz przyciski tylko jeśli są dostępne cele
                if last_index > 1 then
                    if target_index == 1 then
                        CreateArrowButton("right", render_vi:GetWide() * 0.92, "materials/vgui/rightarrow.png")
                    elseif target_index == last_index then
                        CreateArrowButton("left", -33, "materials/vgui/leftarrow.png")
                    else
                        CreateArrowButton("left", -33, "materials/vgui/leftarrow.png")
                        CreateArrowButton("right", render_vi:GetWide() * 0.92, "materials/vgui/rightarrow.png")
                    end
                end



            end

            local btn = vgui.Create("DButton", frame)
            btn:SetText("")
            btn:SetPos(frame:GetWide()*0.007, frame:GetTall()*0.01)
            btn:SetSize(frame:GetWide()*0.075, frame:GetTall()*0.12)
            btn:SetZPos(1)
            local turnIcon = Material("materials/vgui/icon_turn.png")
            btn.Paint = function(me, w, h)
                local col = me:IsHovered() and Color(255,0,0) or Color(255,255,255,100)
                surface.SetMaterial(turnIcon)
                surface.SetDrawColor(col)
                surface.DrawTexturedRect(10, 10, w - 20, h - 20)
            end
            btn.DoClick = function()
                net.Start("Frame_Remove")
                net.SendToServer()
                LocalPlayer():SetNWBool("BodycamTabletOpen", false)
            end


            local comp_name = vgui.Create( "DLabel", frame)
            comp_name:SetPos( 0,0 )
            comp_name:SetSize(frame:GetWide(),frame:GetTall())
            comp_name:SetText( "" )
            comp_name.Paint = function(me,w,h) 
                draw.SimpleText("Antke Inc. Version 1.7.10", "CameraFont", 10, h - 10, Color(200, 200, 200, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
            end

            
        end



    function SWEP:PostDrawViewModel(vm, ply, weapon)
        local bone = vm:LookupBone("jnt_root")
        if not bone then return end

        local opened = self:GetNWBool("PDAOpen")

        if opened and vm:GetCycle() > 0.9 then
            if not IsValid(frejmus.frame) then
                Dermas()

            end
        else
            if IsValid(frejmus.frame) then
                frejmus.frame:Remove()
            end
        end
    end

    function SWEP:PrimaryAttack() end
    function SWEP:SecondaryAttack() end
    function SWEP:Reload() end

    local model = ClientsideModel("models/almodels/items/actioncam.mdl")
    model:SetNoDraw(true)

    hook.Add("PostDrawOpaqueRenderables", "manual_model_draw_example", function()
        for _, ent in ipairs(ents.GetAll()) do
            if not IsValid(ent) then continue end
            if not ent:IsPlayer() and not ent:IsNPC() then continue end
            if ent:IsPlayer() and not ent:Alive() then continue end
            if ent == LocalPlayer() then continue end
            if not IsValid(ent:GetNWEntity("BodyCam")) then continue end

            local attach_id = ent:LookupBone("ValveBiped.Bip01_Spine2")
            if not attach_id then continue end

            local pos, ang = ent:GetBonePosition(attach_id)
            if not pos or not ang then continue end

            model:SetModelScale(0.8, 0)
            pos = pos + (ang:Right() * -9)
            ang:RotateAroundAxis(ang:Right(), -90)
            ang:RotateAroundAxis(ang:Up(), 90)

            model:SetPos(pos)
            model:SetAngles(ang)
            model:SetupBones()
            model:DrawModel()
        end
    end)
end 