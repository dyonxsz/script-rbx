-- ║      RefinaryTPDX - Teleport Menu        ║
-- ║        by dxtp | JJSploit Edition        ║
-- ║        Refinery Caves 2 Edition          ║

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
local LP               = Players.LocalPlayer

--         SAVE / LOAD  (TPs)
local SAVE_FILE = "DXTP_" .. tostring(game.PlaceId) .. ".json"
local HK_FILE   = "DXTP_hotkeys.json"   -- keybinds separadas (não dependem do jogo)

local function saveData(data)
    pcall(function() writefile(SAVE_FILE, HttpService:JSONEncode(data)) end)
end
local function loadData()
    local ok, raw = pcall(readfile, SAVE_FILE)
    if ok and raw and raw ~= "" then
        local ok2, t = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok2 and t then
            if not t.perma     then t.perma     = {} end
            if not t.temp      then t.temp      = {} end
            if not t.favoritos then t.favoritos = {} end
            if not t.pastas    then t.pastas    = {} end
            return t
        end
    end
    return {perma={}, temp={}, favoritos={}, pastas={}}
end

-- ── Keybinds persistentes ──────────────────
-- salva: { slots=[{name,x,y,z},{...},...], keys=["KeyCode.Name",...] }
local function saveHotkeys()
    local hkSave = {slots={}, keys={}, flyKey=nil}
    for i = 1, 9 do
        hkSave.slots[i] = slotAssigned and slotAssigned[i] or nil
        hkSave.keys[i]  = (activeHotkeys and activeHotkeys[i])
            and activeHotkeys[i].Name or nil
    end
    hkSave.flyKey = flyHotkey and flyHotkey.Name or nil
    pcall(function() writefile(HK_FILE, HttpService:JSONEncode(hkSave)) end)
end
local function loadHotkeys()
    local ok, raw = pcall(readfile, HK_FILE)
    if ok and raw and raw ~= "" then
        local ok2, t = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok2 and t then return t end
    end
    return {slots={}, keys={}}
end

local tpData   = loadData()
local hkData   = loadHotkeys()

--         VARIÁVEIS GLOBAIS
local tpMode        = "Direto"
local minimized     = false
-- slots: restaurados do arquivo
local slotAssigned  = {}
local activeHotkeys = {}
local slotFrames    = {}
local selectedSlot  = 1

-- restaurar slots salvos
for i = 1, 9 do
    if hkData.slots and hkData.slots[i] then
        slotAssigned[i] = hkData.slots[i]
    end
    if hkData.keys and hkData.keys[i] then
        local kc = Enum.KeyCode[hkData.keys[i]]
        if kc then activeHotkeys[i] = kc end
    end
end
-- restaurar hotkey do fly
if hkData.flyKey then
    local kc = Enum.KeyCode[hkData.flyKey]
    if kc then flyHotkey = kc end
end

local quickTps    = {}
local quickIndex  = 1
local quickLabels = {}
local flyEnabled  = false
local flyConn     = nil
local flyBodyVel  = nil
local flyBodyGyro = nil
local flySpeed    = 50
local flyHotkey   = nil  -- KeyCode para ativar/desativar fly
local fullbrightOn   = false
local origAmbient    = Lighting.Ambient
local origBrightness = Lighting.Brightness
local origClock      = Lighting.ClockTime
local searchQuery    = ""
local pastaOpen      = {}   -- [nomePasta]=bool
local pastaSelected  = nil  -- pasta para novo TP

--     RC2 CLOCK
local sessionStart      = tick()
local RC2_DAY_REAL_SECS = 24 * 60

local function getRCTime()
    local ct   = Lighting.ClockTime
    local h    = math.floor(ct) % 24
    local m    = math.floor((ct % 1) * 60)
    local ampm = h >= 12 and "PM" or "AM"
    local h12  = h % 12; if h12 == 0 then h12 = 12 end
    return string.format("%02d:%02d %s", h12, m, ampm), h
end
local function getTimeIcon(h)
    if h >= 5  and h < 7  then return "🌅" end
    if h >= 7  and h < 18 then return "☀"  end
    if h >= 18 and h < 20 then return "🌇" end
    return "🌙"
end
local function getTimeColor(h, C)
    if h >= 5 and h < 7   then return C.dawn
    elseif h >= 7 and h < 18  then return C.day
    elseif h >= 18 and h < 20 then return C.dawn
    else return C.night end
end

--         HELPERS
local function getRoot()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function sortedEntries(tbl)
    local arr = {}
    for _, v in pairs(tbl) do table.insert(arr, v) end
    table.sort(arr, function(a,b) return string.lower(a.name) < string.lower(b.name) end)
    return arr
end

--   TELEPORTE DE VEÍCULO (SEM MEXER ITENS)
-- Encontra o modelo raiz do veículo que o jogador está pilotando.
-- Move o modelo inteiro usando SetPrimaryPartCFrame, preservando
-- o CFrame relativo de todas as peças (weld/motor6D mantém tudo no lugar).
local function getVehicleModel()
    local char = LP.Character
    if not char then return nil end
    -- verifica se está sentado em VehicleSeat
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.SeatPart == nil then return nil end
    local seat = hum.SeatPart
    if not seat:IsA("VehicleSeat") then return nil end
    -- sobe até o modelo raiz do veículo
    local model = seat:FindFirstAncestorOfClass("Model")
    return model
end

-- Move veículo inteiro para targetPos mantendo orientação.
-- Usa a diferença de offset entre o HRP e o PrimaryPart do veículo
-- para que o JOGADOR chegue exatamente onde pediu.
local function teleportVehicle(targetPos)
    local root  = getRoot()
    local vModel = getVehicleModel()
    if not vModel then
        -- sem veículo: TP normal
        return false
    end
    local pp = vModel.PrimaryPart
    if not pp then
        -- sem PrimaryPart: tenta usar BasePart com nome "Body" ou o primeiro BasePart
        for _, p in pairs(vModel:GetDescendants()) do
            if p:IsA("BasePart") then pp = p break end
        end
        if not pp then return false end
    end

    -- Offset do PrimaryPart em relação ao HRP
    local offset = pp.CFrame:ToObjectSpace(root.CFrame)
    -- Nova posição do PP: coloca o HRP em targetPos+3Y, ajusta o PP
    local newPPCFrame = CFrame.new(targetPos + Vector3.new(0,3,0)) * offset:Inverse()

    -- SetPrimaryPartCFrame move todo o modelo de uma vez
    -- TODOS os weld/Motor6D são preservados → itens não caem
    pcall(function()
        vModel:SetPrimaryPartCFrame(newPPCFrame)
    end)
    return true
end

--        MODOS DE TELEPORTE
local function tpDireto(pos)
    local root = getRoot()
    if not root then return end
    local target = pos + Vector3.new(0, 3, 0)
    local dist   = (target - root.Position).Magnitude
    if dist <= 200 then
        task.wait(0.05)
        root.CFrame = CFrame.new(target)
    else
        local steps = math.ceil(dist / 150)
        local s = root.Position
        for i = 1, steps do
            local r = getRoot(); if not r then break end
            r.CFrame = CFrame.new(s:Lerp(target, i/steps))
            task.wait(0.03)
        end
    end
end

local flyActive = false
local function tpVoar(pos)
    if flyActive then return end
    local root = getRoot(); local hum = getHum()
    if not root or not hum then return end
    flyActive = true; hum.PlatformStand = true
    local bv = Instance.new("BodyVelocity", root)
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    local target = pos + Vector3.new(0,3,0)
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local r = getRoot()
        if not r then pcall(function() bv:Destroy() end) flyActive=false conn:Disconnect() return end
        local dir = target - r.Position
        if dir.Magnitude < 4 then
            bv:Destroy(); r.CFrame = CFrame.new(target)
            hum.PlatformStand = false; flyActive = false; conn:Disconnect()
            return
        end
        bv.Velocity = dir.Unit * math.min(80, dir.Magnitude * 5)
    end)
end

local function tpAndar(pos)
    local hum = getHum(); local root = getRoot()
    if not hum or not root then return end
    local dist = (pos - root.Position).Magnitude
    if dist > 500 then tpDireto(pos) return end
    hum:MoveTo(pos + Vector3.new(0,3,0))
    local t0 = tick()
    repeat task.wait(0.1)
    until (getRoot() and (getRoot().Position-pos).Magnitude < 5) or (tick()-t0 > dist/16+5)
end

local noclipConn
local function tpNoclip(pos)
    local root = getRoot(); if not root then return end
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RunService.Stepped:Connect(function()
        local c = LP.Character
        if c then for _, p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end end
    end)
    tpDireto(pos)
    task.wait(0.5)
    noclipConn:Disconnect(); noclipConn = nil
    local c = LP.Character
    if c then for _, p in pairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = true end
    end end
end

local function doTp(pos)
    -- Tenta teleportar veículo primeiro (se estiver pilotando)
    if teleportVehicle(pos) then return end
    if     tpMode=="Voar"   then task.spawn(tpVoar,   pos)
    elseif tpMode=="Andar"  then task.spawn(tpAndar,  pos)
    elseif tpMode=="Noclip" then task.spawn(tpNoclip, pos)
    else                         task.spawn(tpDireto,  pos) end
end

--              FLY
local function toggleFly()
    flyEnabled = not flyEnabled
    local root = getRoot(); local hum = getHum()
    if flyEnabled then
        if not root or not hum then flyEnabled=false return end
        hum.PlatformStand = true
        pcall(function()
            if flyBodyVel  then flyBodyVel:Destroy()  flyBodyVel=nil  end
            if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro=nil end
        end)
        flyBodyVel = Instance.new("BodyVelocity", root)
        flyBodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
        flyBodyVel.Velocity = Vector3.new(0,0,0)
        flyBodyGyro = Instance.new("BodyGyro", root)
        flyBodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
        flyBodyGyro.P = 1e4
        local cam = workspace.CurrentCamera
        if flyConn then flyConn:Disconnect() flyConn=nil end
        flyConn = RunService.Heartbeat:Connect(function()
            local r = getRoot()
            if not r or not flyEnabled then
                pcall(function()
                    if flyBodyVel  then flyBodyVel:Destroy()  flyBodyVel=nil  end
                    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro=nil end
                end)
                local h2=getHum(); if h2 then h2.PlatformStand=false end
                if flyConn then flyConn:Disconnect() flyConn=nil end
                return
            end
            local dir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir=dir+Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir=dir-Vector3.new(0,1,0) end
            flyBodyVel.Velocity = dir.Magnitude>0 and dir.Unit*flySpeed or Vector3.new(0,0,0)
            flyBodyGyro.CFrame  = cam.CFrame
        end)
    else
        pcall(function()
            if flyBodyVel  then flyBodyVel:Destroy()  flyBodyVel=nil  end
            if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro=nil end
            if flyConn     then flyConn:Disconnect()  flyConn=nil     end
        end)
        if hum then hum.PlatformStand=false end
    end
    return flyEnabled
end

--           FULLBRIGHT
-- Loop Heartbeat mantém os valores contra o RC2
-- que reescreve Lighting a cada frame.
-- Remove fog, blur, DOF, SunRays, Bloom, Atmosphere.
local origFogEnd      = Lighting.FogEnd
local origFogStart    = Lighting.FogStart
local origShadows     = Lighting.GlobalShadows
local origOutdoor     = Lighting.OutdoorAmbient
local fbLoop          = nil
local fbDisabled      = {}   -- efeitos desativados para restaurar

local function fbApply()
    Lighting.Ambient        = Color3.new(1,1,1)
    Lighting.Brightness     = 2
    Lighting.FogEnd         = 1e9
    Lighting.FogStart       = 1e9
    Lighting.GlobalShadows  = false
    Lighting.OutdoorAmbient = Color3.new(1,1,1)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then
        pcall(function()
            atm.Density = 0; atm.Haze = 0
            atm.Glare   = 0; atm.Offset = 0
        end)
    end
end

local function fbDisableEffects()
    fbDisabled = {}
    for _, e in pairs(Lighting:GetDescendants()) do
        local ok = e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect")
            or e:IsA("SunRaysEffect") or e:IsA("DepthOfFieldEffect")
            or e:IsA("BloomEffect")   or e:IsA("PostEffect")
        if ok and e.Enabled then
            e.Enabled = false
            table.insert(fbDisabled, e)
        end
    end
end

local function fbRestoreEffects()
    for _, e in ipairs(fbDisabled) do
        pcall(function() e.Enabled = true end)
    end
    fbDisabled = {}
end

local function toggleFullbright()
    fullbrightOn = not fullbrightOn
    if fullbrightOn then
        origAmbient    = Lighting.Ambient
        origBrightness = Lighting.Brightness
        origFogEnd     = Lighting.FogEnd
        origFogStart   = Lighting.FogStart
        origShadows    = Lighting.GlobalShadows
        origOutdoor    = Lighting.OutdoorAmbient
        fbDisableEffects()
        fbApply()
        -- Loop que reaaplica se o RC2 reverter
        if fbLoop then fbLoop:Disconnect() end
        fbLoop = RunService.Heartbeat:Connect(function()
            if not fullbrightOn then fbLoop:Disconnect(); fbLoop=nil; return end
            if Lighting.Ambient ~= Color3.new(1,1,1) then fbApply() end
            -- Mantém efeitos off (RC2 pode reativar)
            for _, e in ipairs(fbDisabled) do
                if e and e.Parent and e.Enabled then
                    pcall(function() e.Enabled = false end)
                end
            end
        end)
    else
        if fbLoop then fbLoop:Disconnect(); fbLoop=nil end
        Lighting.Ambient        = origAmbient
        Lighting.Brightness     = origBrightness
        Lighting.FogEnd         = origFogEnd
        Lighting.FogStart       = origFogStart
        Lighting.GlobalShadows  = origShadows
        Lighting.OutdoorAmbient = origOutdoor
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then
            pcall(function()
                atm.Density = 0.3; atm.Haze = 0
                atm.Glare   = 0;   atm.Offset = 0.25
            end)
        end
        fbRestoreEffects()
    end
    return fullbrightOn
end

--           WALKSPEED (loop fix)
local wsConn    = nil
local currentWS = 16
local function applyWalkSpeed(v)
    currentWS = v
    if wsConn then wsConn:Disconnect() wsConn=nil end
    if v == 16 then local hum=getHum(); if hum then hum.WalkSpeed=16 end return end
    wsConn = RunService.Heartbeat:Connect(function()
        local hum=getHum(); if hum then hum.WalkSpeed=currentWS end
    end)
end

--           QUICK TP
local function quickSave()
    local root=getRoot(); if not root then return end
    local pos=root.Position
    if #quickTps < 2 then
        table.insert(quickTps,{x=pos.X,y=pos.Y,z=pos.Z})
    else
        table.remove(quickTps,1); table.insert(quickTps,{x=pos.X,y=pos.Y,z=pos.Z})
    end
    if quickLabels.update then quickLabels.update() end
end
local function quickGo()
    if #quickTps==0 then return end
    if quickIndex>#quickTps then quickIndex=1 end
    local e=quickTps[quickIndex]
    if e then doTp(Vector3.new(e.x,e.y,e.z)) end
    quickIndex=quickIndex%#quickTps+1
    if quickLabels.update then quickLabels.update() end
end

--                  GUI
if LP.PlayerGui:FindFirstChild("RefinaryTPDX") then
    LP.PlayerGui:FindFirstChild("RefinaryTPDX"):Destroy()
end
local Gui = Instance.new("ScreenGui")
Gui.Name="RefinaryTPDX"; Gui.ResetOnSpawn=false
Gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; Gui.Parent=LP.PlayerGui

local C = {
    bg     = Color3.fromRGB(8,  14, 32),
    panel  = Color3.fromRGB(14, 24, 56),
    card   = Color3.fromRGB(10, 18, 42),
    accent = Color3.fromRGB(40, 110,255),
    acc2   = Color3.fromRGB(0,  190,255),
    text   = Color3.fromRGB(220,235,255),
    sub    = Color3.fromRGB(110,150,210),
    border = Color3.fromRGB(30, 60, 150),
    danger = Color3.fromRGB(255,55, 80),
    perma  = Color3.fromRGB(35, 210,130),
    temp   = Color3.fromRGB(255,165,30),
    fav    = Color3.fromRGB(255,210,30),
    hk     = Color3.fromRGB(20, 55, 140),
    fly    = Color3.fromRGB(80, 30, 200),
    fb     = Color3.fromRGB(255,200,0),
    spd    = Color3.fromRGB(0,  180,80),
    pasta  = Color3.fromRGB(60, 120,255),
    clock  = Color3.fromRGB(180,220,255),
    night  = Color3.fromRGB(100,130,255),
    dawn   = Color3.fromRGB(255,180,80),
    day    = Color3.fromRGB(255,230,100),
    veh    = Color3.fromRGB(0,  210,180),
}

-- ─── Bolinha ───
local Ball = Instance.new("TextButton",Gui)
Ball.Size=UDim2.new(0,50,0,50); Ball.Position=UDim2.new(0,20,0.5,-25)
Ball.BackgroundColor3=C.accent; Ball.BorderSizePixel=0
Ball.Text="RC"; Ball.TextColor3=Color3.new(1,1,1)
Ball.Font=Enum.Font.GothamBold; Ball.TextSize=15
Ball.Visible=false; Ball.ZIndex=200
Instance.new("UICorner",Ball).CornerRadius=UDim.new(1,0)
local ballGlow=Instance.new("UIStroke",Ball)
ballGlow.Color=C.acc2; ballGlow.Thickness=2

-- ─── Janela ───
local Win=Instance.new("Frame",Gui)
Win.Size=UDim2.new(0,425,0,625); Win.Position=UDim2.new(0.5,-212,0.5,-312)
Win.BackgroundColor3=C.bg; Win.BorderSizePixel=0; Win.ZIndex=10
Instance.new("UICorner",Win).CornerRadius=UDim.new(0,12)
local winStroke=Instance.new("UIStroke",Win)
winStroke.Color=C.border; winStroke.Thickness=1.5

-- ─── Header ───
local Hdr=Instance.new("Frame",Win)
Hdr.Size=UDim2.new(1,0,0,46); Hdr.BackgroundColor3=C.panel
Hdr.BorderSizePixel=0; Hdr.ZIndex=11
Instance.new("UICorner",Hdr).CornerRadius=UDim.new(0,12)
local HFix=Instance.new("Frame",Hdr)
HFix.Size=UDim2.new(1,0,0.5,0); HFix.Position=UDim2.new(0,0,0.5,0)
HFix.BackgroundColor3=C.panel; HFix.BorderSizePixel=0; HFix.ZIndex=11

local function tlbl(par,text,x,y,w,h,font,sz,col,ax)
    local l=Instance.new("TextLabel",par)
    l.Position=UDim2.new(0,x,0,y); l.Size=UDim2.new(0,w,0,h)
    l.BackgroundTransparency=1; l.Text=text
    l.Font=font or Enum.Font.Gotham; l.TextSize=sz or 12
    l.TextColor3=col or C.text
    l.TextXAlignment=ax or Enum.TextXAlignment.Left
    l.ZIndex=13; return l
end

tlbl(Hdr,"⬡ RefinaryTPDX",14,3,180,20,Enum.Font.GothamBold,16,C.acc2)
tlbl(Hdr,"AntiBan · RC2 · Fly Hotkey",14,24,200,13,Enum.Font.Gotham,9,C.sub)
local clockLbl=tlbl(Hdr,"🌙 00:00 AM",155,3,150,20,Enum.Font.GothamBold,14,C.clock)
local dateLbl =tlbl(Hdr,"Dia 1  Ano 1",155,24,150,13,Enum.Font.Gotham,9,C.sub)
tlbl(Hdr,"[Home]",312,26,56,13,Enum.Font.Gotham,9,C.sub)

local MinBtn=Instance.new("TextButton",Hdr)
MinBtn.Size=UDim2.new(0,30,0,30); MinBtn.Position=UDim2.new(1,-38,0,8)
MinBtn.BackgroundColor3=C.accent; MinBtn.BorderSizePixel=0
MinBtn.Text="—"; MinBtn.TextColor3=Color3.new(1,1,1)
MinBtn.Font=Enum.Font.GothamBold; MinBtn.TextSize=13; MinBtn.ZIndex=14
Instance.new("UICorner",MinBtn).CornerRadius=UDim.new(0,7)

-- ─── Scroll ───
local Scr=Instance.new("ScrollingFrame",Win)
Scr.Size=UDim2.new(1,-8,1,-52); Scr.Position=UDim2.new(0,4,0,48)
Scr.BackgroundTransparency=1; Scr.BorderSizePixel=0
Scr.ScrollBarThickness=4; Scr.ScrollBarImageColor3=C.accent
Scr.AutomaticCanvasSize=Enum.AutomaticSize.Y
Scr.CanvasSize=UDim2.new(0,0,0,0); Scr.ZIndex=11
local ScrL=Instance.new("UIListLayout",Scr)
ScrL.Padding=UDim.new(0,7); ScrL.SortOrder=Enum.SortOrder.LayoutOrder
local ScrP=Instance.new("UIPadding",Scr)
ScrP.PaddingLeft=UDim.new(0,5); ScrP.PaddingRight=UDim.new(0,5)
ScrP.PaddingTop=UDim.new(0,5);  ScrP.PaddingBottom=UDim.new(0,8)

local lo=0
local function mkCard(h)
    lo=lo+1
    local f=Instance.new("Frame",Scr)
    f.Size=UDim2.new(1,0,0,h); f.BackgroundColor3=C.panel
    f.BorderSizePixel=0; f.LayoutOrder=lo; f.ZIndex=12
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
    return f
end
local function mkBtn(par,text,x,y,w,h,col)
    local b=Instance.new("TextButton",par)
    b.Size=UDim2.new(0,w,0,h); b.Position=UDim2.new(0,x,0,y)
    b.BackgroundColor3=col or C.accent; b.BorderSizePixel=0
    b.Text=text; b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamSemibold; b.TextSize=11; b.ZIndex=14
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    return b
end

--  CARD 1: RC2 RELÓGIO
local clockCard=mkCard(65)
tlbl(clockCard,"🕐  HORA DO SERVIDOR (Refinery Caves 2)",10,5,380,14,Enum.Font.GothamBold,11,C.acc2)
local bigClock=tlbl(clockCard,"🌙 00:00 AM",10,22,200,22,Enum.Font.GothamBold,20,C.clock)
local bigDate =tlbl(clockCard,"Dia 1  ·  Ano 1",10,46,200,14,Enum.Font.Gotham,10,C.sub)

local progressBg=Instance.new("Frame",clockCard)
progressBg.Size=UDim2.new(0,182,0,8); progressBg.Position=UDim2.new(0,224,0,30)
progressBg.BackgroundColor3=C.card; progressBg.BorderSizePixel=0; progressBg.ZIndex=13
Instance.new("UICorner",progressBg).CornerRadius=UDim.new(0,4)
local progressFill=Instance.new("Frame",progressBg)
progressFill.Size=UDim2.new(0,0,1,0); progressFill.BackgroundColor3=C.day
progressFill.BorderSizePixel=0; progressFill.ZIndex=14
Instance.new("UICorner",progressFill).CornerRadius=UDim.new(0,4)
local progressLbl=tlbl(clockCard,"0%",224,40,182,12,Enum.Font.Gotham,9,C.sub,Enum.TextXAlignment.Center)
tlbl(clockCard,"🌅",220,22,16,14,Enum.Font.Gotham,10,C.dawn,Enum.TextXAlignment.Center)
tlbl(clockCard,"☀",296,22,16,14,Enum.Font.Gotham,10,C.day, Enum.TextXAlignment.Center)
tlbl(clockCard,"🌙",392,22,16,14,Enum.Font.Gotham,10,C.night,Enum.TextXAlignment.Center)

local function updateBigClock()
    local timeStr,h=getRCTime()
    local icon=getTimeIcon(h)
    local col=getTimeColor(h,C)
    bigClock.Text=icon.." "..timeStr; bigClock.TextColor3=col
    local elapsed=tick()-sessionStart
    local totalDays=math.floor(elapsed/RC2_DAY_REAL_SECS)
    local dayOfYear=(totalDays%365)+1
    local year=math.floor(totalDays/365)+1
    bigDate.Text=string.format("Dia %d  ·  Ano %d",dayOfYear,year)
    local pct=(Lighting.ClockTime%24)/24
    progressFill.Size=UDim2.new(pct,0,1,0); progressFill.BackgroundColor3=col
    progressLbl.Text=string.format("%.0f%%",pct*100)
    clockLbl.Text=icon.." "..timeStr; clockLbl.TextColor3=col
    dateLbl.Text=string.format("Dia %d  Ano %d",dayOfYear,year)
end

--  CARD 2: MODO DE TP
local modeCard=mkCard(80)
tlbl(modeCard,"⚡  MODO DE TELEPORTE",10,6,300,16,Enum.Font.GothamBold,12,C.acc2)
local modeDescs={
    Direto ="Instantaneo com anti-kick por steps",
    Voar   ="Personagem voa suavemente ate o destino",
    Andar  ="Personagem caminha naturalmente ate la",
    Noclip ="Atravessa paredes para chegar ao destino",
}
local modeBtns={}
local modeDescL=tlbl(modeCard,"",10,58,405,14,Enum.Font.Gotham,10,C.sub)
for i,m in ipairs({"Direto","Voar","Andar","Noclip"}) do
    local b=mkBtn(modeCard,m,6+(i-1)*99,28,93,26,C.hk)
    modeBtns[m]=b
    b.MouseButton1Click:Connect(function()
        tpMode=m
        for _,bb in pairs(modeBtns) do bb.BackgroundColor3=C.hk end
        b.BackgroundColor3=C.accent
        modeDescL.Text="▸ "..modeDescs[m]
    end)
end
modeBtns["Direto"].BackgroundColor3=C.accent
modeDescL.Text="▸ "..modeDescs["Direto"]

--  CARD 3: UTILIDADES
local utilCard=mkCard(142)
tlbl(utilCard,"🛠  UTILIDADES",10,5,200,16,Enum.Font.GothamBold,12,C.acc2)

local flyBtn=mkBtn(utilCard,"🚀 Fly: OFF",6,24,118,26,C.fly)
local fbBtn =mkBtn(utilCard,"☀ Fullbright: OFF",130,24,166,26,C.hk)

flyBtn.MouseButton1Click:Connect(function()
    local on=toggleFly()
    flyBtn.Text=on and "🚀 Fly: ON" or "🚀 Fly: OFF"
    flyBtn.BackgroundColor3=on and C.acc2 or C.fly
end)
fbBtn.MouseButton1Click:Connect(function()
    local on=toggleFullbright()
    fbBtn.Text=on and "☀ Fullbright: ON" or "☀ Fullbright: OFF"
    fbBtn.BackgroundColor3=on and C.fb or C.hk
end)

-- Fly speed
tlbl(utilCard,"Fly Spd:",6,58,58,16,Enum.Font.Gotham,11,C.sub)
local flySpeedBox=Instance.new("TextBox",utilCard)
flySpeedBox.Size=UDim2.new(0,46,0,22); flySpeedBox.Position=UDim2.new(0,64,0,56)
flySpeedBox.BackgroundColor3=C.card; flySpeedBox.BorderSizePixel=0
flySpeedBox.Text="50"; flySpeedBox.TextColor3=C.text
flySpeedBox.Font=Enum.Font.Gotham; flySpeedBox.TextSize=12
flySpeedBox.ClearTextOnFocus=false; flySpeedBox.ZIndex=14
Instance.new("UICorner",flySpeedBox).CornerRadius=UDim.new(0,5)
local setFlyBtn=mkBtn(utilCard,"✔",114,56,28,22,C.spd)
setFlyBtn.TextSize=12
setFlyBtn.MouseButton1Click:Connect(function()
    local v=tonumber(flySpeedBox.Text)
    if v and v>0 and v<=500 then flySpeed=v end
end)

-- WalkSpeed
tlbl(utilCard,"WalkSpd:",148,58,62,16,Enum.Font.Gotham,11,C.sub)
local speedBox=Instance.new("TextBox",utilCard)
speedBox.Size=UDim2.new(0,46,0,22); speedBox.Position=UDim2.new(0,214,0,56)
speedBox.BackgroundColor3=C.card; speedBox.BorderSizePixel=0
speedBox.Text="16"; speedBox.TextColor3=C.text
speedBox.Font=Enum.Font.Gotham; speedBox.TextSize=12
speedBox.ClearTextOnFocus=false; speedBox.ZIndex=14
Instance.new("UICorner",speedBox).CornerRadius=UDim.new(0,5)
local setSpeedBtn=mkBtn(utilCard,"✔",264,56,28,22,C.spd)
local rstSpeedBtn=mkBtn(utilCard,"↺",296,56,28,22,C.hk)
setSpeedBtn.TextSize=12; rstSpeedBtn.TextSize=12
setSpeedBtn.MouseButton1Click:Connect(function()
    local v=tonumber(speedBox.Text)
    if v and v>=0 and v<=500 then applyWalkSpeed(v) end
end)
rstSpeedBtn.MouseButton1Click:Connect(function() applyWalkSpeed(16); speedBox.Text="16" end)

-- Fly Hotkey bind
tlbl(utilCard,"Fly Hotkey:",6,86,72,16,Enum.Font.Gotham,11,C.sub)
local flyKeyLbl=tlbl(utilCard,
    flyHotkey and flyHotkey.Name or "Nenhuma",
    82,86,130,16,Enum.Font.Gotham,11,C.acc2)
local flyBindBtn=mkBtn(utilCard,"Bind Tecla",216,84,96,20,C.fly)
flyBindBtn.TextSize=10
local flyClearBtn=mkBtn(utilCard,"✕",316,84,28,20,C.danger)
flyClearBtn.TextSize=10

flyBindBtn.MouseButton1Click:Connect(function()
    flyBindBtn.Text="..."; flyBindBtn.BackgroundColor3=C.acc2
    local c2
    c2=UserInputService.InputBegan:Connect(function(inp2,gp2)
        if inp2.UserInputType==Enum.UserInputType.Keyboard then
            flyHotkey=inp2.KeyCode
            flyKeyLbl.Text=inp2.KeyCode.Name; flyKeyLbl.TextColor3=C.acc2
            flyBindBtn.Text="Bind Tecla"; flyBindBtn.BackgroundColor3=C.fly
            saveHotkeys(); c2:Disconnect()
        end
    end)
end)
flyClearBtn.MouseButton1Click:Connect(function()
    flyHotkey=nil
    flyKeyLbl.Text="Nenhuma"; flyKeyLbl.TextColor3=C.sub
    saveHotkeys()
end)

-- Veículo info
local vehInfoLbl=tlbl(utilCard,"🚗 Veículo: não detectado",8,108,400,14,Enum.Font.Gotham,10,C.sub)
tlbl(utilCard,"TP com veículo: automático ao teleportar se estiver num VehicleSeat",8,122,410,12,Enum.Font.Gotham,9,C.sub)

-- atualiza status do veículo
task.spawn(function()
    while true do
        pcall(function()
            local vm=getVehicleModel()
            if vm then
                vehInfoLbl.Text="🚗 Veículo: "..vm.Name.."  (TP automático ativo)"
                vehInfoLbl.TextColor3=C.veh
            else
                vehInfoLbl.Text="🚗 Veículo: não detectado"
                vehInfoLbl.TextColor3=C.sub
            end
        end)
        task.wait(1)
    end
end)
local quickCard=mkCard(84)
tlbl(quickCard,"⚡  QUICK TP",10,4,200,16,Enum.Font.GothamBold,12,C.acc2)
tlbl(quickCard,"[PageUp]=Salvar · [PageDown]=Ir/Ciclar · Máx:2 · PageUp c/2 apaga o + antigo",8,20,410,12,Enum.Font.Gotham,9,C.sub)
local qLbl1  =tlbl(quickCard,"Ponto 1: —",  8,36,196,14,Enum.Font.Gotham,11,C.acc2)
local qLbl2  =tlbl(quickCard,"Ponto 2: —",212,36,196,14,Enum.Font.Gotham,11,C.temp)
local qIdxLbl=tlbl(quickCard,"Próximo: —",  8,52,200,14,Enum.Font.Gotham,10,C.sub)
local qClearBtn=mkBtn(quickCard,"🗑 Limpar",312,50,88,22,C.danger)
qClearBtn.TextSize=10
qClearBtn.MouseButton1Click:Connect(function()
    quickTps={}; quickIndex=1
    if quickLabels.update then quickLabels.update() end
end)
quickLabels.update=function()
    qLbl1.Text=quickTps[1] and ("P1: "..math.floor(quickTps[1].x)..","..math.floor(quickTps[1].z)) or "Ponto 1: —"
    qLbl2.Text=quickTps[2] and ("P2: "..math.floor(quickTps[2].x)..","..math.floor(quickTps[2].z)) or "Ponto 2: —"
    qIdxLbl.Text=#quickTps>0 and ("Próximo: Ponto "..quickIndex) or "Próximo: —"
end

--  CARD 6: CRIAR TP
local createCard=mkCard(112)
tlbl(createCard,"➕  CRIAR TELEPORTE",10,5,300,16,Enum.Font.GothamBold,12,C.acc2)

local nameBox=Instance.new("TextBox",createCard)
nameBox.Size=UDim2.new(1,-14,0,26); nameBox.Position=UDim2.new(0,7,0,24)
nameBox.BackgroundColor3=C.card; nameBox.BorderSizePixel=0
nameBox.PlaceholderText="Nome do teleporte..."; nameBox.PlaceholderColor3=C.sub
nameBox.Text=""; nameBox.TextColor3=C.text
nameBox.Font=Enum.Font.Gotham; nameBox.TextSize=12
nameBox.ClearTextOnFocus=false; nameBox.ZIndex=14
Instance.new("UICorner",nameBox).CornerRadius=UDim.new(0,6)

local pastaDropLbl=tlbl(createCard,"📁 Pasta: Nenhuma",8,56,220,16,Enum.Font.Gotham,11,C.sub)
local clearPastaSelBtn=mkBtn(createCard,"✕ Pasta",300,54,102,18,C.hk)
clearPastaSelBtn.TextSize=10
clearPastaSelBtn.MouseButton1Click:Connect(function()
    pastaSelected=nil
    pastaDropLbl.Text="📁 Pasta: Nenhuma"; pastaDropLbl.TextColor3=C.sub
end)

local bPerma=mkBtn(createCard,"💾 Permanente",7,76,125,26,C.perma)
local bTemp =mkBtn(createCard,"⏱ Temporario",138,76,116,26,C.temp)
local statusL=tlbl(createCard,"",10,106,405,14,Enum.Font.Gotham,10,C.perma)

--  CARD 7: GERENCIAR PASTAS
local pastaMgmtCard=mkCard(130)
tlbl(pastaMgmtCard,"📁  PASTAS",10,5,200,16,Enum.Font.GothamBold,12,C.acc2)

local pastaNameBox=Instance.new("TextBox",pastaMgmtCard)
pastaNameBox.Size=UDim2.new(0,196,0,24); pastaNameBox.Position=UDim2.new(0,7,0,24)
pastaNameBox.BackgroundColor3=C.card; pastaNameBox.BorderSizePixel=0
pastaNameBox.PlaceholderText="Nome da pasta..."; pastaNameBox.PlaceholderColor3=C.sub
pastaNameBox.Text=""; pastaNameBox.TextColor3=C.text
pastaNameBox.Font=Enum.Font.Gotham; pastaNameBox.TextSize=12
pastaNameBox.ClearTextOnFocus=false; pastaNameBox.ZIndex=14
Instance.new("UICorner",pastaNameBox).CornerRadius=UDim.new(0,6)

local criarPastaBtn=mkBtn(pastaMgmtCard,"➕ Criar Pasta",208,24,196,24,C.pasta)

local sep=Instance.new("Frame",pastaMgmtCard)
sep.Size=UDim2.new(1,-14,0,1); sep.Position=UDim2.new(0,7,0,54)
sep.BackgroundColor3=C.border; sep.BorderSizePixel=0; sep.ZIndex=13

tlbl(pastaMgmtCard,"Adicionar TP existente a uma pasta:",8,60,300,14,Enum.Font.GothamBold,10,C.acc2)

local tpDropBtn=mkBtn(pastaMgmtCard,"Selecionar TP...",7,76,196,22,C.hk)
tpDropBtn.TextSize=10
local tpDropSelected=nil

local pastaDestBtn=mkBtn(pastaMgmtCard,"Selecionar Pasta...",208,76,196,22,C.hk)
pastaDestBtn.TextSize=10
local pastaDestSelected=nil

local addToPastaBtn=mkBtn(pastaMgmtCard,"➕ Adicionar à Pasta",7,104,200,22,C.pasta)
addToPastaBtn.TextSize=10
local pastaMsgL=tlbl(pastaMgmtCard,"",215,106,195,16,Enum.Font.Gotham,10,C.pasta)

-- ─── Popup flutuante ───
local popupFrame=Instance.new("Frame",Gui)
popupFrame.Size=UDim2.new(0,225,0,230); popupFrame.Position=UDim2.new(0.5,-112,0.5,-115)
popupFrame.BackgroundColor3=C.panel; popupFrame.BorderSizePixel=0
popupFrame.ZIndex=300; popupFrame.Visible=false
Instance.new("UICorner",popupFrame).CornerRadius=UDim.new(0,10)
local popupStroke=Instance.new("UIStroke",popupFrame)
popupStroke.Color=C.border; popupStroke.Thickness=1.5

local popupTitle=Instance.new("TextLabel",popupFrame)
popupTitle.Size=UDim2.new(1,-8,0,24); popupTitle.Position=UDim2.new(0,8,0,4)
popupTitle.BackgroundTransparency=1; popupTitle.Text="Selecionar"
popupTitle.TextColor3=C.acc2; popupTitle.Font=Enum.Font.GothamBold
popupTitle.TextSize=13; popupTitle.TextXAlignment=Enum.TextXAlignment.Left
popupTitle.ZIndex=301

local popupClose=Instance.new("TextButton",popupFrame)
popupClose.Size=UDim2.new(0,24,0,24); popupClose.Position=UDim2.new(1,-28,0,4)
popupClose.BackgroundColor3=C.danger; popupClose.BorderSizePixel=0
popupClose.Text="✕"; popupClose.TextColor3=Color3.new(1,1,1)
popupClose.Font=Enum.Font.GothamBold; popupClose.TextSize=12; popupClose.ZIndex=302
Instance.new("UICorner",popupClose).CornerRadius=UDim.new(0,6)
popupClose.MouseButton1Click:Connect(function() popupFrame.Visible=false end)

local popupScroll=Instance.new("ScrollingFrame",popupFrame)
popupScroll.Size=UDim2.new(1,-8,1,-32); popupScroll.Position=UDim2.new(0,4,0,30)
popupScroll.BackgroundTransparency=1; popupScroll.BorderSizePixel=0
popupScroll.ScrollBarThickness=4; popupScroll.ScrollBarImageColor3=C.accent
popupScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
popupScroll.CanvasSize=UDim2.new(0,0,0,0); popupScroll.ZIndex=301
local popupLayout=Instance.new("UIListLayout",popupScroll)
popupLayout.Padding=UDim.new(0,3); popupLayout.SortOrder=Enum.SortOrder.LayoutOrder
local popupPad=Instance.new("UIPadding",popupScroll)
popupPad.PaddingLeft=UDim.new(0,3); popupPad.PaddingRight=UDim.new(0,3)
popupPad.PaddingTop=UDim.new(0,3)

local popupCallback=nil
local function openPopup(title,items,callback)
    for _,c in pairs(popupScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    popupTitle.Text=title; popupCallback=callback
    for idx,item in ipairs(items) do
        local btn=Instance.new("TextButton",popupScroll)
        btn.Size=UDim2.new(1,0,0,26); btn.BackgroundColor3=C.card
        btn.BorderSizePixel=0; btn.Text=item; btn.TextColor3=C.text
        btn.Font=Enum.Font.Gotham; btn.TextSize=11
        btn.TextXAlignment=Enum.TextXAlignment.Left
        btn.LayoutOrder=idx; btn.ZIndex=302
        local pad=Instance.new("UIPadding",btn); pad.PaddingLeft=UDim.new(0,8)
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
        btn.MouseButton1Click:Connect(function()
            popupFrame.Visible=false
            if popupCallback then popupCallback(item) end
        end)
        btn.MouseEnter:Connect(function() btn.BackgroundColor3=C.hk end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3=C.card end)
    end
    popupFrame.Visible=true
end

tpDropBtn.MouseButton1Click:Connect(function()
    local all=sortedEntries(tpData.perma)
    for _,e in ipairs(sortedEntries(tpData.temp)) do table.insert(all,e) end
    local names={}; for _,e in ipairs(all) do table.insert(names,e.name) end
    if #names==0 then pastaMsgL.Text="⚠ Nenhum TP criado!" pastaMsgL.TextColor3=C.danger return end
    openPopup("Selecionar TP",names,function(name)
        tpDropSelected=name; tpDropBtn.Text=name; tpDropBtn.BackgroundColor3=C.accent
    end)
end)

pastaDestBtn.MouseButton1Click:Connect(function()
    local names={}
    for nome in pairs(tpData.pastas) do table.insert(names,nome) end
    table.sort(names,function(a,b) return string.lower(a)<string.lower(b) end)
    if #names==0 then pastaMsgL.Text="⚠ Nenhuma pasta!" pastaMsgL.TextColor3=C.danger return end
    openPopup("Selecionar Pasta",names,function(nome)
        pastaDestSelected=nome; pastaDestBtn.Text=nome; pastaDestBtn.BackgroundColor3=C.pasta
    end)
end)

addToPastaBtn.MouseButton1Click:Connect(function()
    if not tpDropSelected then pastaMsgL.Text="⚠ Selecione um TP!" pastaMsgL.TextColor3=C.danger return end
    if not pastaDestSelected then pastaMsgL.Text="⚠ Selecione uma pasta!" pastaMsgL.TextColor3=C.danger return end
    if not tpData.pastas[pastaDestSelected] then pastaMsgL.Text="⚠ Pasta nao existe!" pastaMsgL.TextColor3=C.danger return end
    tpData.pastas[pastaDestSelected][tpDropSelected]=true
    saveData(tpData)
    pastaMsgL.Text="✔ Adicionado!"; pastaMsgL.TextColor3=C.perma
    reloadList()
end)

criarPastaBtn.MouseButton1Click:Connect(function()
    local nome=pastaNameBox.Text
    if nome=="" then pastaMsgL.Text="⚠ Digite um nome!" pastaMsgL.TextColor3=C.danger return end
    if tpData.pastas[nome] then pastaMsgL.Text="⚠ Ja existe!" pastaMsgL.TextColor3=C.danger return end
    tpData.pastas[nome]={}; pastaOpen[nome]=true
    saveData(tpData); pastaNameBox.Text=""
    pastaMsgL.Text="✔ Pasta criada: "..nome; pastaMsgL.TextColor3=C.pasta
    reloadList()
end)

--  BARRA DE PESQUISA
local searchCard=mkCard(40)
tlbl(searchCard,"🔍",8,10,22,20,Enum.Font.Gotham,14,C.sub)
local searchBox=Instance.new("TextBox",searchCard)
searchBox.Size=UDim2.new(1,-38,0,26); searchBox.Position=UDim2.new(0,30,0,7)
searchBox.BackgroundColor3=C.card; searchBox.BorderSizePixel=0
searchBox.PlaceholderText="Pesquisar teleporte..."
searchBox.PlaceholderColor3=C.sub; searchBox.Text=""
searchBox.TextColor3=C.text; searchBox.Font=Enum.Font.Gotham
searchBox.TextSize=12; searchBox.ClearTextOnFocus=false; searchBox.ZIndex=14
Instance.new("UICorner",searchBox).CornerRadius=UDim.new(0,6)
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery=searchBox.Text; reloadList()
end)

--  SEÇÕES AUTO COLAPSÁVEIS (fav/perma/temp)
--  Clique no header para minimizar/expandir
local sectionOpen = {fav=true, perma=true, temp=true}  -- estado de cada seção

local function mkAutoSection(colorHdr, titleText, emoji, key)
    local sec=Instance.new("Frame",Scr)
    sec.BackgroundColor3=C.panel; sec.BorderSizePixel=0
    lo=lo+1; sec.LayoutOrder=lo; sec.ZIndex=12
    sec.AutomaticSize=Enum.AutomaticSize.Y
    Instance.new("UICorner",sec).CornerRadius=UDim.new(0,8)
    local ll=Instance.new("UIListLayout",sec)
    ll.Padding=UDim.new(0,3); ll.SortOrder=Enum.SortOrder.LayoutOrder
    local pad=Instance.new("UIPadding",sec)
    pad.PaddingLeft=UDim.new(0,6); pad.PaddingRight=UDim.new(0,6)
    pad.PaddingTop=UDim.new(0,5);  pad.PaddingBottom=UDim.new(0,5)

    -- Header clicável (toggle)
    local hdrBtn=Instance.new("TextButton",sec)
    hdrBtn.Size=UDim2.new(1,0,0,22)
    hdrBtn.BackgroundTransparency=1
    hdrBtn.BorderSizePixel=0
    hdrBtn.Text=""
    hdrBtn.ZIndex=13; hdrBtn.LayoutOrder=0

    local togIcon=Instance.new("TextLabel",hdrBtn)
    togIcon.Size=UDim2.new(0,16,1,0); togIcon.Position=UDim2.new(0,0,0,0)
    togIcon.BackgroundTransparency=1
    togIcon.Text=sectionOpen[key] and "▼" or "▶"
    togIcon.TextColor3=colorHdr; togIcon.Font=Enum.Font.GothamBold
    togIcon.TextSize=11; togIcon.ZIndex=14

    local titleLbl=Instance.new("TextLabel",hdrBtn)
    titleLbl.Size=UDim2.new(1,-16,1,0); titleLbl.Position=UDim2.new(0,18,0,0)
    titleLbl.BackgroundTransparency=1
    titleLbl.Text=emoji.."  "..titleText
    titleLbl.TextColor3=colorHdr; titleLbl.Font=Enum.Font.GothamBold
    titleLbl.TextSize=12; titleLbl.TextXAlignment=Enum.TextXAlignment.Left
    titleLbl.ZIndex=14

    hdrBtn.MouseButton1Click:Connect(function()
        sectionOpen[key]=not sectionOpen[key]
        togIcon.Text=sectionOpen[key] and "▼" or "▶"
        reloadList()
    end)

    return sec, hdrBtn, togIcon
end

local favCard,  favHdrBtn,  favTog   = mkAutoSection(C.fav,  "FAVORITOS",   "⭐",  "fav")
local permaCard,permaHdrBtn,permaTog = mkAutoSection(C.perma,"PERMANENTES", "📌", "perma")
local tempCard, tempHdrBtn, tempTog  = mkAutoSection(C.temp, "TEMPORÁRIOS", "⏱", "temp")

-- alias para compatibilidade com reloadList que usa favHdr/permaHdr/tempHdr
local favHdr   = favHdrBtn
local permaHdr = permaHdrBtn
local tempHdr  = tempHdrBtn

--  PASTAS CONTAINER
--  FIX: cada pasta é um Frame independente no Scr (não aninhado)
--  Isso elimina o problema de sobreposição e nomes sobrescrevendo
-- As pastas serão inseridas diretamente no Scr como frames separados.
-- Guardamos referências para poder destruí-las no reload.
local pastaFrames = {}  -- lista de Frames de pasta criados

--  HOTKEYS (9 slots) – com save
local hkCard=mkCard(10+9*21+30)
tlbl(hkCard,"⌨  ATALHOS  (9 slots) — salvo permanentemente",10,5,400,16,Enum.Font.GothamBold,11,C.acc2)
tlbl(hkCard,"Clique na linha do slot para selecioná-lo (azul = selecionado)",10,20,405,12,Enum.Font.Gotham,10,C.sub)

local slotHighlights={}
local function updateSlotHighlight()
    for i=1,9 do
        if slotHighlights[i] then
            slotHighlights[i].BackgroundColor3=(i==selectedSlot) and C.accent or C.card
        end
    end
end

for i=1,9 do
    local yy=36+(i-1)*21
    local row=Instance.new("Frame",hkCard)
    row.Size=UDim2.new(1,-12,0,19); row.Position=UDim2.new(0,6,0,yy)
    row.BackgroundColor3=(i==selectedSlot) and C.accent or C.card
    row.BorderSizePixel=0; row.ZIndex=13
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,4)
    slotHighlights[i]=row

    local numL=Instance.new("TextLabel",row)
    numL.Size=UDim2.new(0,16,1,0); numL.BackgroundTransparency=1
    numL.Text=tostring(i); numL.TextColor3=C.acc2
    numL.Font=Enum.Font.GothamBold; numL.TextSize=11; numL.ZIndex=14

    local tpL=Instance.new("TextLabel",row)
    tpL.Size=UDim2.new(0,138,1,0); tpL.Position=UDim2.new(0,18,0,0)
    tpL.BackgroundTransparency=1
    tpL.Text=slotAssigned[i] and slotAssigned[i].name or "— vazio —"
    tpL.TextColor3=slotAssigned[i] and C.text or C.sub
    tpL.Font=Enum.Font.Gotham; tpL.TextSize=11
    tpL.TextXAlignment=Enum.TextXAlignment.Left; tpL.ZIndex=14

    local keyL=Instance.new("TextLabel",row)
    keyL.Size=UDim2.new(0,65,1,0); keyL.Position=UDim2.new(0,160,0,0)
    keyL.BackgroundTransparency=1
    keyL.Text=activeHotkeys[i] and activeHotkeys[i].Name or "Sem tecla"
    keyL.TextColor3=activeHotkeys[i] and C.acc2 or C.sub
    keyL.Font=Enum.Font.Gotham; keyL.TextSize=10; keyL.ZIndex=14

    local bindB=mkBtn(row,"Bind",228,1,40,17,C.hk); bindB.TextSize=10
    local clrB =mkBtn(row,"✕",272,1,26,17,C.danger); clrB.TextSize=10

    row.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            selectedSlot=i; updateSlotHighlight()
        end
    end)

    slotFrames[i]={tpL=tpL,keyL=keyL}

    bindB.MouseButton1Click:Connect(function()
        bindB.Text="..."; bindB.BackgroundColor3=C.acc2
        local c2
        c2=UserInputService.InputBegan:Connect(function(inp2,gp2)
            if inp2.UserInputType==Enum.UserInputType.Keyboard then
                activeHotkeys[i]=inp2.KeyCode
                keyL.Text=inp2.KeyCode.Name; keyL.TextColor3=C.acc2
                bindB.Text="Bind"; bindB.BackgroundColor3=C.hk
                c2:Disconnect()
                saveHotkeys()  -- salva imediatamente
            end
        end)
    end)

    clrB.MouseButton1Click:Connect(function()
        slotAssigned[i]=nil; activeHotkeys[i]=nil
        tpL.Text="— vazio —"; tpL.TextColor3=C.sub
        keyL.Text="Sem tecla"; keyL.TextColor3=C.sub
        saveHotkeys()
    end)
end
updateSlotHighlight()

--   CRIAR LINHA DE TP
local function mkRow(parent,entry,tipo,order)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,28); row.BackgroundColor3=C.card
    row.BorderSizePixel=0; row.LayoutOrder=order; row.ZIndex=13
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local bar=Instance.new("Frame",row)
    bar.Size=UDim2.new(0,4,0.8,0); bar.Position=UDim2.new(0,0,0.1,0)
    bar.BackgroundColor3=tipo=="perma" and C.perma
        or tipo=="fav" and C.fav
        or tipo=="pasta" and C.pasta or C.temp
    bar.BorderSizePixel=0; bar.ZIndex=14
    Instance.new("UICorner",bar).CornerRadius=UDim.new(0,3)

    local nL=Instance.new("TextLabel",row)
    nL.Size=UDim2.new(0,138,1,0); nL.Position=UDim2.new(0,10,0,0)
    nL.BackgroundTransparency=1; nL.Text=entry.name
    nL.TextColor3=tipo=="fav" and C.fav or C.text
    nL.Font=Enum.Font.Gotham; nL.TextSize=12
    nL.TextXAlignment=Enum.TextXAlignment.Left; nL.ZIndex=14

    local goB  =mkBtn(row,"▶ IR", 152,3,42,22,C.accent)
    local slotB=mkBtn(row,"→Slot",198,3,44,22,C.hk)
    local favB
    if tipo~="fav" then
        local isFav=tpData.favoritos[entry.name]~=nil
        favB=mkBtn(row,isFav and "★" or "☆",246,3,22,22,isFav and C.fav or C.hk)
        favB.TextSize=13
    end
    local delX=tipo~="fav" and 272 or 246
    local delB=mkBtn(row,"🗑",delX,3,26,22,C.danger); delB.TextSize=12

    goB.MouseButton1Click:Connect(function() doTp(Vector3.new(entry.x,entry.y,entry.z)) end)

    slotB.MouseButton1Click:Connect(function()
        slotAssigned[selectedSlot]={name=entry.name,x=entry.x,y=entry.y,z=entry.z}
        if slotFrames[selectedSlot] then
            slotFrames[selectedSlot].tpL.Text=entry.name
            slotFrames[selectedSlot].tpL.TextColor3=C.text
        end
        if slotHighlights[selectedSlot] then
            slotHighlights[selectedSlot].BackgroundColor3=C.acc2
            task.delay(0.3,function() updateSlotHighlight() end)
        end
        saveHotkeys()
    end)

    if favB then
        favB.MouseButton1Click:Connect(function()
            local already=tpData.favoritos[entry.name]~=nil
            if already then
                tpData.favoritos[entry.name]=nil; favB.Text="☆"; favB.BackgroundColor3=C.hk
            else
                tpData.favoritos[entry.name]={name=entry.name,x=entry.x,y=entry.y,z=entry.z}
                favB.Text="★"; favB.BackgroundColor3=C.fav
            end
            saveData(tpData); reloadList()
        end)
    end

    delB.MouseButton1Click:Connect(function()
        if tipo=="perma" then
            tpData.perma[entry.name]=nil
            for _,ps in pairs(tpData.pastas) do ps[entry.name]=nil end
        elseif tipo=="temp" then
            tpData.temp[entry.name]=nil
            for _,ps in pairs(tpData.pastas) do ps[entry.name]=nil end
        elseif tipo=="fav" then
            tpData.favoritos[entry.name]=nil
        elseif tipo=="pasta" then
            for _,ps in pairs(tpData.pastas) do ps[entry.name]=nil end
        end
        saveData(tpData); reloadList()
    end)
    return row
end

--   RELOAD LISTA
--   FIX PASTAS: cada pasta é um Frame independente no Scr,
--   com LayoutOrder sequencial após as seções fixas.
--   Isso elimina sobreposição e labels sobrescrevendo.

-- LayoutOrder base para pastas (vem depois de todas as seções fixas)
local PASTA_LO_BASE = 100

function reloadList()
    -- limpa apenas os rows (Frame), preserva o hdrBtn (TextButton) e seus filhos
    for _,c in pairs(favCard:GetChildren())   do if c~=favHdr   and c:IsA("Frame") then c:Destroy() end end
    for _,c in pairs(permaCard:GetChildren()) do if c~=permaHdr and c:IsA("Frame") then c:Destroy() end end
    for _,c in pairs(tempCard:GetChildren())  do if c~=tempHdr  and c:IsA("Frame") then c:Destroy() end end

    -- destrói todos os frames de pasta anteriores
    for _,f in ipairs(pastaFrames) do
        pcall(function() f:Destroy() end)
    end
    pastaFrames={}

    -- atualiza ícones de toggle (caso sectionOpen tenha mudado externamente)
    favTog.Text   = sectionOpen.fav   and "▼" or "▶"
    permaTog.Text = sectionOpen.perma and "▼" or "▶"
    tempTog.Text  = sectionOpen.temp  and "▼" or "▶"

    local q=string.lower(searchQuery)
    local function match(name) return q=="" or string.find(string.lower(name),q,1,true) end

    -- Favoritos (só popula rows se aberto)
    if sectionOpen.fav then
        for idx,e in ipairs(sortedEntries(tpData.favoritos)) do
            if match(e.name) then mkRow(favCard,e,"fav",idx) end
        end
    end
    -- Permanentes
    if sectionOpen.perma then
        for idx,e in ipairs(sortedEntries(tpData.perma)) do
            if match(e.name) then mkRow(permaCard,e,"perma",idx) end
        end
    end
    -- Temporários
    if sectionOpen.temp then
        for idx,e in ipairs(sortedEntries(tpData.temp)) do
            if match(e.name) then mkRow(tempCard,e,"temp",idx) end
        end
    end

    -- Pastas (cada uma = Frame separado no Scr, LayoutOrder=PASTA_LO_BASE+i)
    local pastaNames={}
    for nome in pairs(tpData.pastas) do table.insert(pastaNames,nome) end
    table.sort(pastaNames,function(a,b) return string.lower(a)<string.lower(b) end)

    for pi,nomePasta in ipairs(pastaNames) do
        local tpSet=tpData.pastas[nomePasta]
        local isOpen=pastaOpen[nomePasta]; if isOpen==nil then isOpen=true end

        -- Frame raiz da pasta (direto no Scr)
        local pFrame=Instance.new("Frame",Scr)
        pFrame.BackgroundColor3=C.panel; pFrame.BorderSizePixel=0
        pFrame.LayoutOrder=PASTA_LO_BASE+pi; pFrame.ZIndex=12
        pFrame.AutomaticSize=Enum.AutomaticSize.Y
        Instance.new("UICorner",pFrame).CornerRadius=UDim.new(0,8)

        -- FIX: UIListLayout + UIPadding corretos
        local pLL=Instance.new("UIListLayout",pFrame)
        pLL.Padding=UDim.new(0,3); pLL.SortOrder=Enum.SortOrder.LayoutOrder
        local pPad=Instance.new("UIPadding",pFrame)
        pPad.PaddingLeft=UDim.new(0,6);  pPad.PaddingRight=UDim.new(0,6)
        pPad.PaddingTop=UDim.new(0,5);   pPad.PaddingBottom=UDim.new(0,5)

        table.insert(pastaFrames,pFrame)

        -- Header da pasta
        local phRow=Instance.new("Frame",pFrame)
        phRow.Size=UDim2.new(1,0,0,24); phRow.BackgroundColor3=C.card
        phRow.BorderSizePixel=0; phRow.ZIndex=13; phRow.LayoutOrder=0
        Instance.new("UICorner",phRow).CornerRadius=UDim.new(0,6)

        -- ícone toggle
        local togL=Instance.new("TextLabel",phRow)
        togL.Size=UDim2.new(0,18,1,0); togL.Position=UDim2.new(0,4,0,0)
        togL.BackgroundTransparency=1; togL.Text=isOpen and "▼" or "▶"
        togL.TextColor3=C.pasta; togL.Font=Enum.Font.GothamBold
        togL.TextSize=11; togL.ZIndex=14

        -- nome
        local pTitleL=Instance.new("TextLabel",phRow)
        pTitleL.Size=UDim2.new(0,200,1,0); pTitleL.Position=UDim2.new(0,22,0,0)
        pTitleL.BackgroundTransparency=1; pTitleL.Text="📁 "..nomePasta
        pTitleL.TextColor3=C.pasta; pTitleL.Font=Enum.Font.GothamBold
        pTitleL.TextSize=12; pTitleL.TextXAlignment=Enum.TextXAlignment.Left
        pTitleL.ZIndex=14

        -- contagem
        local count=0; for _ in pairs(tpSet) do count=count+1 end
        local cntL=Instance.new("TextLabel",phRow)
        cntL.Size=UDim2.new(0,30,1,0); cntL.Position=UDim2.new(0,224,0,0)
        cntL.BackgroundTransparency=1; cntL.Text="("..count..")"
        cntL.TextColor3=C.sub; cntL.Font=Enum.Font.Gotham
        cntL.TextSize=10; cntL.ZIndex=14

        local addBtn=mkBtn(phRow,"+ TP",258,2,46,20,C.hk); addBtn.TextSize=10
        local selBtn=mkBtn(phRow,"Usar",308,2,46,20,C.accent); selBtn.TextSize=10
        local delPBtn=mkBtn(phRow,"🗑",358,2,26,20,C.danger); delPBtn.TextSize=11

        -- Toggle abrir/fechar
        local function togPasta()
            pastaOpen[nomePasta]=not pastaOpen[nomePasta]; reloadList()
        end
        togL.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then togPasta() end
        end)
        pTitleL.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then togPasta() end
        end)

        -- + TP: popup com TPs não incluídos
        addBtn.MouseButton1Click:Connect(function()
            local all=sortedEntries(tpData.perma)
            for _,e in ipairs(sortedEntries(tpData.temp)) do table.insert(all,e) end
            local names={}
            for _,e in ipairs(all) do
                if not tpSet[e.name] then table.insert(names,e.name) end
            end
            if #names==0 then return end
            openPopup("Adicionar a: "..nomePasta,names,function(name)
                tpData.pastas[nomePasta][name]=true
                saveData(tpData); reloadList()
            end)
        end)

        -- "Usar": seleciona esta pasta para o próximo TP criado
        selBtn.MouseButton1Click:Connect(function()
            pastaSelected=nomePasta
            pastaDropLbl.Text="📁 Pasta: "..nomePasta
            pastaDropLbl.TextColor3=C.pasta
        end)

        -- Deletar pasta
        delPBtn.MouseButton1Click:Connect(function()
            tpData.pastas[nomePasta]=nil; pastaOpen[nomePasta]=nil
            saveData(tpData); reloadList()
        end)

        -- TPs dentro da pasta (se aberta)
        if isOpen then
            local inPasta={}
            for tpName in pairs(tpSet) do
                local entry=tpData.perma[tpName] or tpData.temp[tpName]
                if entry then table.insert(inPasta,entry) end
            end
            table.sort(inPasta,function(a,b) return string.lower(a.name)<string.lower(b.name) end)
            for idx,e in ipairs(inPasta) do
                if match(e.name) then
                    -- FIX: LayoutOrder começa em 1 (não conflita com o header que é 0)
                    mkRow(pFrame,e,"pasta",idx)
                end
            end
        end
    end

    -- Atualiza label de pasta selecionada
    if pastaSelected then
        pastaDropLbl.Text="📁 Pasta: "..pastaSelected
        pastaDropLbl.TextColor3=C.pasta
    else
        pastaDropLbl.Text="📁 Pasta: Nenhuma"
        pastaDropLbl.TextColor3=C.sub
    end
end

reloadList()

--   CRIAR TP
local function addTp(tipo)
    local name=nameBox.Text
    if name=="" then statusL.Text="⚠ Digite um nome!" statusL.TextColor3=C.danger return end
    local root=getRoot()
    if not root then statusL.Text="⚠ Personagem nao encontrado!" statusL.TextColor3=C.danger return end
    local p=root.Position
    local entry={name=name,x=p.X,y=p.Y,z=p.Z}
    if tipo=="perma" then tpData.perma[name]=entry else tpData.temp[name]=entry end
    if pastaSelected and tpData.pastas[pastaSelected] then
        tpData.pastas[pastaSelected][name]=true
    end
    saveData(tpData)
    statusL.Text="✔ Salvo: "..name; statusL.TextColor3=C.perma
    nameBox.Text=""; reloadList()
end

bPerma.MouseButton1Click:Connect(function() addTp("perma") end)
bTemp.MouseButton1Click:Connect(function()  addTp("temp")  end)

--   DRAG janela
do
    local drag,ds,sp=false
    Hdr.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true ds=i.Position sp=Win.Position end
    end)
    Hdr.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            Win.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

--   DRAG bolinha + abrir
do
    local drag,ds,sp=false; local clickOk=false
    Ball.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true ds=i.Position sp=Ball.Position clickOk=true
        end
    end)
    Ball.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement and drag then
            local d=i.Position-ds
            if d.Magnitude>4 then clickOk=false end
            Ball.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
    Ball.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=false
            if clickOk then minimized=false Ball.Visible=false Win.Visible=true end
            clickOk=false
        end
    end)
end

--   MINIMIZAR
local function openMenu()  minimized=false Win.Visible=true  Ball.Visible=false end
local function closeMenu() minimized=true  Win.Visible=false Ball.Visible=true  end
MinBtn.MouseButton1Click:Connect(closeMenu)

--   INPUT GLOBAL
UserInputService.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
    if inp.KeyCode==Enum.KeyCode.Home then
        if minimized then openMenu() else closeMenu() end return
    end
    if inp.KeyCode==Enum.KeyCode.PageUp   then quickSave() return end
    if inp.KeyCode==Enum.KeyCode.PageDown then quickGo()   return end
    -- Fly hotkey
    if flyHotkey and inp.KeyCode==flyHotkey then
        local on=toggleFly()
        flyBtn.Text=on and "🚀 Fly: ON" or "🚀 Fly: OFF"
        flyBtn.BackgroundColor3=on and C.acc2 or C.fly
        return
    end
    for i=1,9 do
        if activeHotkeys[i] and inp.KeyCode==activeHotkeys[i] then
            local s=slotAssigned[i]
            if s then doTp(Vector3.new(s.x,s.y,s.z)) end
        end
    end
end)

--   CLOCK LOOP
task.spawn(function()
    while true do
        pcall(updateBigClock)
        task.wait(1)
    end
end)

print("✔ RefinaryTPDX carregado | PlaceId: "..tostring(game.PlaceId))

-- ║   MÓDULO: MINERIOS — ESP + TP                        ║
-- ║   Aba separada, abre/fecha com [Insert]              ║

--  DADOS DOS MINERIOS (confirmados pelos scans)
local ORE_DATA = {
    -- Zona Spawn (scan 1)
    {name="Stone",      color=Color3.fromRGB(130,130,110), tier=1},
    {name="Dirt",       color=Color3.fromRGB(110,75,45),   tier=1},
    {name="Granite",    color=Color3.fromRGB(160,160,150), tier=1},
    {name="Iron",       color=Color3.fromRGB(190,110,60),  tier=2},
    {name="Copper",     color=Color3.fromRGB(210,100,50),  tier=2},
    {name="Bauxite",    color=Color3.fromRGB(210,140,80),  tier=2},
    {name="Amber",      color=Color3.fromRGB(230,170,30),  tier=2},
    {name="Cobalt",     color=Color3.fromRGB(60,110,230),  tier=3},
    {name="Sulfur",     color=Color3.fromRGB(220,220,40),  tier=3},
    -- Zona Vulcânica (scan 2)
    {name="Magma",      color=Color3.fromRGB(255,80,20),   tier=3},
    {name="Obsidian",   color=Color3.fromRGB(80,20,120),   tier=4},
    {name="Cloudnite",  color=Color3.fromRGB(180,220,255), tier=4},
    {name="Odd Stone",  color=Color3.fromRGB(140,200,140), tier=4},
    {name="Volcanium",  color=Color3.fromRGB(255,40,40),   tier=5},
}

-- Quais minérios estão ativos para ESP/TP
local oreActive = {}
for _, od in ipairs(ORE_DATA) do oreActive[od.name] = true end

--  ESP STATE
local oreESP       = {}   -- [model] = {hl=Highlight, bb=BillboardGui}
local oreESPOn     = true
local oreESPConn   = nil

local function getOresFolder2()
    local ws = workspace:FindFirstChild("WorldSpawn")
    if ws then local o = ws:FindFirstChild("Ores"); if o then return o end end
    return workspace:FindFirstChild("Ores")
end

local function getOreColor(name)
    for _, od in ipairs(ORE_DATA) do
        if od.name == name then return od.color end
    end
    return Color3.fromRGB(255,255,255)
end

local function refreshOreESP()
    if not oreESPOn then
        for m, data in pairs(oreESP) do
            pcall(function() data.hl:Destroy() end)
            pcall(function() data.bb:Destroy() end)
            oreESP[m] = nil
        end
        return
    end

    local folder = getOresFolder2()
    local active = {}

    if folder then
        for _, ore in pairs(folder:GetChildren()) do
            if oreActive[ore.Name] then
                active[ore] = true
                if not oreESP[ore] then
                    local col = getOreColor(ore.Name)

                    -- Highlight AlwaysOnTop (atravessa paredes)
                    local hl = Instance.new("Highlight")
                    hl.Adornee = ore
                    hl.FillColor = col
                    hl.OutlineColor = col
                    hl.FillTransparency = 0.7
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = workspace

                    -- Label com nome e distância
                    local pp = ore.PrimaryPart or ore:FindFirstChildOfClass("BasePart")
                    local bb
                    if pp then
                        bb = Instance.new("BillboardGui")
                        bb.Adornee = pp
                        bb.Size = UDim2.new(0,90,0,24)
                        bb.StudsOffset = Vector3.new(0,5,0)
                        bb.AlwaysOnTop = true
                        bb.MaxDistance = 500
                        bb.Parent = workspace
                        local lbl2 = Instance.new("TextLabel", bb)
                        lbl2.Size = UDim2.new(1,0,1,0)
                        lbl2.BackgroundTransparency = 1
                        lbl2.TextColor3 = col
                        lbl2.Font = Enum.Font.GothamBold
                        lbl2.TextSize = 13
                        lbl2.Text = ore.Name
                        lbl2.TextStrokeTransparency = 0
                        lbl2.TextStrokeColor3 = Color3.new(0,0,0)
                    end

                    oreESP[ore] = {hl=hl, bb=bb}
                end
            end
        end
    end

    -- Remove ESP de minérios que sumiram
    for m, data in pairs(oreESP) do
        if not active[m] or not m.Parent then
            pcall(function() data.hl:Destroy() end)
            pcall(function() if data.bb then data.bb:Destroy() end end)
            oreESP[m] = nil
        end
    end
end

-- Loop do ESP
local function startOreESPLoop()
    if oreESPConn then return end
    oreESPConn = true
    task.spawn(function()
        while oreESPConn do
            pcall(refreshOreESP)
            task.wait(1.5)
        end
    end)
end

local function stopOreESPLoop()
    oreESPConn = nil
    for m, data in pairs(oreESP) do
        pcall(function() data.hl:Destroy() end)
        pcall(function() if data.bb then data.bb:Destroy() end end)
        oreESP[m] = nil
    end
end

startOreESPLoop()

-- ESP DE DROPS (MaterialPart que aparece no chao apos quebrar pedra)
local dropESP    = {}   -- [part] = {hl, bb}
local dropESPOn  = true
local dropESPConn = nil

local function refreshDropESP()
    if not dropESPOn then
        for p, data in pairs(dropESP) do
            pcall(function() data.hl:Destroy() end)
            pcall(function() if data.bb then data.bb:Destroy() end end)
            dropESP[p] = nil
        end
        return
    end
    local active = {}
    -- MaterialPart aparece direto no workspace (filho imediato) após quebrar pedra
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "MaterialPart" and obj:IsA("BasePart") then
            active[obj] = true
            if not dropESP[obj] then
                -- Tenta ler nome do item dentro do MaterialPart
                local dropName = "Minerio"
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("StringValue") then
                        dropName = child.Value ~= "" and child.Value or child.Name
                        break
                    end
                    if child:IsA("BillboardGui") then
                        -- O jogo pode já colocar um BillboardGui com o nome
                        local tl = child:FindFirstChildOfClass("TextLabel")
                        if tl and tl.Text ~= "" then dropName = tl.Text; break end
                    end
                end

                -- Cor baseada no nome do drop
                local col = Color3.fromRGB(255,200,60)
                for _, od in ipairs(ORE_DATA) do
                    local dropLow = string.lower(od.drop or "")
                    local nameLow = string.lower(od.name)
                    local itemLow = string.lower(dropName)
                    if itemLow:find(nameLow,1,true) or (dropLow~="" and itemLow:find(dropLow,1,true)) then
                        col = od.color; break
                    end
                end

                local hl = Instance.new("Highlight")
                hl.Adornee = obj
                hl.FillColor = col
                hl.OutlineColor = col
                hl.FillTransparency = 0.35
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = workspace

                local bb = Instance.new("BillboardGui")
                bb.Adornee = obj
                bb.Size = UDim2.new(0,110,0,20)
                bb.StudsOffset = Vector3.new(0,3,0)
                bb.AlwaysOnTop = true
                bb.MaxDistance = 120
                bb.Parent = workspace
                local lbl3 = Instance.new("TextLabel", bb)
                lbl3.Size = UDim2.new(1,0,1,0)
                lbl3.BackgroundTransparency = 1
                lbl3.TextColor3 = col
                lbl3.Font = Enum.Font.GothamBold
                lbl3.TextSize = 12
                lbl3.Text = dropName
                lbl3.TextStrokeTransparency = 0
                lbl3.TextStrokeColor3 = Color3.new(0,0,0)

                dropESP[obj] = {hl=hl, bb=bb}
            end
        end
    end
    -- Remove drops coletados
    for obj, data in pairs(dropESP) do
        if not active[obj] or not obj.Parent then
            pcall(function() data.hl:Destroy() end)
            pcall(function() if data.bb then data.bb:Destroy() end end)
            dropESP[obj] = nil
        end
    end
end

local function startDropESP()
    if dropESPConn then return end
    dropESPConn = true
    task.spawn(function()
        while dropESPConn do
            pcall(refreshDropESP)
            task.wait(0.5)  -- rápido pois drops somem rápido
        end
    end)
end
local function stopDropESP()
    dropESPConn = nil
    for obj, data in pairs(dropESP) do
        pcall(function() data.hl:Destroy() end)
        pcall(function() if data.bb then data.bb:Destroy() end end)
        dropESP[obj] = nil
    end
end

startDropESP()
local function tpToNearestOre(oreName)
    local folder = getOresFolder2()
    if not folder then return end
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local myPos = root.Position
    local best, bestD = nil, math.huge
    for _, ore in pairs(folder:GetChildren()) do
        if ore.Name == oreName then
            local p = ore:FindFirstChild("Hitbox") or ore.PrimaryPart or ore:FindFirstChildOfClass("BasePart")
            if p then
                local d = (p.Position - myPos).Magnitude
                if d < bestD then bestD = d; best = p end
            end
        end
    end
    if best then
        doTp(best.Position)
    end
end

--  GUI DA ABA DE MINERIOS
local oreWinVisible = false

local OreGui = Instance.new("Frame", Gui)
OreGui.Size = UDim2.new(0,340,0,580)
OreGui.Position = UDim2.new(0.5,220,0.5,-290)  -- à direita do menu principal
OreGui.BackgroundColor3 = C.bg
OreGui.BorderSizePixel = 0
OreGui.ZIndex = 10
OreGui.Visible = false
Instance.new("UICorner", OreGui).CornerRadius = UDim.new(0,12)
local oreStroke = Instance.new("UIStroke", OreGui)
oreStroke.Color = C.border; oreStroke.Thickness = 1.5

-- Header da aba
local OreHdr = Instance.new("Frame", OreGui)
OreHdr.Size = UDim2.new(1,0,0,44)
OreHdr.BackgroundColor3 = C.panel
OreHdr.BorderSizePixel = 0; OreHdr.ZIndex = 11
Instance.new("UICorner", OreHdr).CornerRadius = UDim.new(0,12)
local ohFix = Instance.new("Frame", OreHdr)
ohFix.Size = UDim2.new(1,0,0.5,0); ohFix.Position = UDim2.new(0,0,0.5,0)
ohFix.BackgroundColor3 = C.panel; ohFix.BorderSizePixel = 0; ohFix.ZIndex = 11

local oreTitleL = Instance.new("TextLabel", OreHdr)
oreTitleL.Size = UDim2.new(1,-50,1,0); oreTitleL.Position = UDim2.new(0,12,0,0)
oreTitleL.BackgroundTransparency = 1
oreTitleL.Text = "⛏  Minerios — ESP + TP"
oreTitleL.TextColor3 = C.acc2; oreTitleL.Font = Enum.Font.GothamBold
oreTitleL.TextSize = 14; oreTitleL.TextXAlignment = Enum.TextXAlignment.Left
oreTitleL.ZIndex = 12

local oreCloseBtn = Instance.new("TextButton", OreHdr)
oreCloseBtn.Size = UDim2.new(0,28,0,28); oreCloseBtn.Position = UDim2.new(1,-36,0,8)
oreCloseBtn.BackgroundColor3 = C.danger; oreCloseBtn.BorderSizePixel = 0
oreCloseBtn.Text = "✕"; oreCloseBtn.TextColor3 = Color3.new(1,1,1)
oreCloseBtn.Font = Enum.Font.GothamBold; oreCloseBtn.TextSize = 13; oreCloseBtn.ZIndex = 14
Instance.new("UICorner", oreCloseBtn).CornerRadius = UDim.new(0,7)
oreCloseBtn.MouseButton1Click:Connect(function()
    oreWinVisible = false
    OreGui.Visible = false
end)

-- Controles ESP
local espCtrl = Instance.new("Frame", OreGui)
espCtrl.Size = UDim2.new(1,-12,0,58)
espCtrl.Position = UDim2.new(0,6,0,50)
espCtrl.BackgroundColor3 = C.panel
espCtrl.BorderSizePixel = 0; espCtrl.ZIndex = 11
Instance.new("UICorner", espCtrl).CornerRadius = UDim.new(0,7)

-- Linha 1: ESP Minérios
local espTogBtn = Instance.new("TextButton", espCtrl)
espTogBtn.Size = UDim2.new(0,120,0,22)
espTogBtn.Position = UDim2.new(0,4,0,4)
espTogBtn.BackgroundColor3 = C.accent
espTogBtn.BorderSizePixel = 0
espTogBtn.Text = "👁 ESP Minerios: ON"
espTogBtn.TextColor3 = Color3.new(1,1,1)
espTogBtn.Font = Enum.Font.GothamBold; espTogBtn.TextSize = 9; espTogBtn.ZIndex = 13
Instance.new("UICorner", espTogBtn).CornerRadius = UDim.new(0,6)

local oreCountLbl = Instance.new("TextLabel", espCtrl)
oreCountLbl.Size = UDim2.new(0,130,0,22)
oreCountLbl.Position = UDim2.new(0,128,0,4)
oreCountLbl.BackgroundTransparency = 1
oreCountLbl.Text = "Visiveis: 0"
oreCountLbl.TextColor3 = C.sub; oreCountLbl.Font = Enum.Font.Gotham
oreCountLbl.TextSize = 10; oreCountLbl.TextXAlignment = Enum.TextXAlignment.Left
oreCountLbl.ZIndex = 12

local insLbl = Instance.new("TextLabel", espCtrl)
insLbl.Size = UDim2.new(0,60,0,22)
insLbl.Position = UDim2.new(1,-64,0,4)
insLbl.BackgroundTransparency = 1
insLbl.Text = "[Insert]"
insLbl.TextColor3 = C.sub; insLbl.Font = Enum.Font.Gotham
insLbl.TextSize = 10; insLbl.TextXAlignment = Enum.TextXAlignment.Right
insLbl.ZIndex = 12

-- Linha 2: ESP Drops (MaterialPart)
local dropTogBtn = Instance.new("TextButton", espCtrl)
dropTogBtn.Size = UDim2.new(0,120,0,22)
dropTogBtn.Position = UDim2.new(0,4,0,32)
dropTogBtn.BackgroundColor3 = Color3.fromRGB(160,100,10)
dropTogBtn.BorderSizePixel = 0
dropTogBtn.Text = "📦 ESP Drops: ON"
dropTogBtn.TextColor3 = Color3.new(1,1,1)
dropTogBtn.Font = Enum.Font.GothamBold; dropTogBtn.TextSize = 9; dropTogBtn.ZIndex = 13
Instance.new("UICorner", dropTogBtn).CornerRadius = UDim.new(0,6)

local dropCountLbl = Instance.new("TextLabel", espCtrl)
dropCountLbl.Size = UDim2.new(0,200,0,22)
dropCountLbl.Position = UDim2.new(0,128,0,32)
dropCountLbl.BackgroundTransparency = 1
dropCountLbl.Text = "Drops no chao: 0"
dropCountLbl.TextColor3 = C.sub; dropCountLbl.Font = Enum.Font.Gotham
dropCountLbl.TextSize = 10; dropCountLbl.TextXAlignment = Enum.TextXAlignment.Left
dropCountLbl.ZIndex = 12

espTogBtn.MouseButton1Click:Connect(function()
    oreESPOn = not oreESPOn
    espTogBtn.Text = oreESPOn and "👁 ESP Minerios: ON" or "👁 ESP Minerios: OFF"
    espTogBtn.BackgroundColor3 = oreESPOn and C.accent or C.hk
    if not oreESPOn then stopOreESPLoop()
    else startOreESPLoop() end
end)

dropTogBtn.MouseButton1Click:Connect(function()
    dropESPOn = not dropESPOn
    dropTogBtn.Text = dropESPOn and "📦 ESP Drops: ON" or "📦 ESP Drops: OFF"
    dropTogBtn.BackgroundColor3 = dropESPOn and Color3.fromRGB(160,100,10) or C.hk
    if not dropESPOn then stopDropESP()
    else startDropESP() end
end)

-- Scroll com botões de cada minério
local oreScroll = Instance.new("ScrollingFrame", OreGui)
oreScroll.Size = UDim2.new(1,-12,1,-116)
oreScroll.Position = UDim2.new(0,6,0,114)
oreScroll.BackgroundTransparency = 1
oreScroll.BorderSizePixel = 0
oreScroll.ScrollBarThickness = 4
oreScroll.ScrollBarImageColor3 = C.accent
oreScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
oreScroll.CanvasSize = UDim2.new(0,0,0,0)
oreScroll.ZIndex = 11

local oreLL = Instance.new("UIListLayout", oreScroll)
oreLL.Padding = UDim.new(0,5)
oreLL.SortOrder = Enum.SortOrder.LayoutOrder

local orePad = Instance.new("UIPadding", oreScroll)
orePad.PaddingLeft = UDim.new(0,2); orePad.PaddingRight = UDim.new(0,2)
orePad.PaddingTop = UDim.new(0,4)

-- Tier labels
local tierNames = {[1]="Tier 1 — Comum", [2]="Tier 2 — Incomum",
    [3]="Tier 3 — Raro", [4]="Tier 4 — Épico", [5]="Tier 5 — Lendário"}
local tierColors = {
    [1]=Color3.fromRGB(160,160,160), [2]=Color3.fromRGB(80,200,80),
    [3]=Color3.fromRGB(80,120,255),  [4]=Color3.fromRGB(180,80,255),
    [5]=Color3.fromRGB(255,160,0)
}

local lastTier = 0
local rowOrder = 0

for _, od in ipairs(ORE_DATA) do
    -- Separador de tier
    if od.tier ~= lastTier then
        lastTier = od.tier
        rowOrder = rowOrder + 1
        local sep = Instance.new("Frame", oreScroll)
        sep.Size = UDim2.new(1,0,0,18)
        sep.BackgroundColor3 = C.panel
        sep.BorderSizePixel = 0; sep.LayoutOrder = rowOrder; sep.ZIndex = 12
        Instance.new("UICorner", sep).CornerRadius = UDim.new(0,5)
        local sepLbl = Instance.new("TextLabel", sep)
        sepLbl.Size = UDim2.new(1,-8,1,0); sepLbl.Position = UDim2.new(0,8,0,0)
        sepLbl.BackgroundTransparency = 1
        sepLbl.Text = tierNames[od.tier] or ("Tier "..od.tier)
        sepLbl.TextColor3 = tierColors[od.tier] or C.sub
        sepLbl.Font = Enum.Font.GothamBold; sepLbl.TextSize = 10
        sepLbl.TextXAlignment = Enum.TextXAlignment.Left; sepLbl.ZIndex = 13
    end

    -- Row do minério
    rowOrder = rowOrder + 1
    local row = Instance.new("Frame", oreScroll)
    row.Size = UDim2.new(1,0,0,30)
    row.BackgroundColor3 = C.card
    row.BorderSizePixel = 0; row.LayoutOrder = rowOrder; row.ZIndex = 12
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)

    -- Barra colorida lateral
    local bar = Instance.new("Frame", row)
    bar.Size = UDim2.new(0,4,0.8,0); bar.Position = UDim2.new(0,0,0.1,0)
    bar.BackgroundColor3 = od.color; bar.BorderSizePixel = 0; bar.ZIndex = 13
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,3)

    -- Toggle ESP deste minério
    local espDot = Instance.new("TextButton", row)
    espDot.Size = UDim2.new(0,22,0,22); espDot.Position = UDim2.new(0,8,0,4)
    espDot.BackgroundColor3 = oreActive[od.name] and od.color or C.card
    espDot.BorderSizePixel = 0
    espDot.Text = oreActive[od.name] and "●" or "○"
    espDot.TextColor3 = Color3.new(1,1,1)
    espDot.Font = Enum.Font.GothamBold; espDot.TextSize = 14; espDot.ZIndex = 14
    Instance.new("UICorner", espDot).CornerRadius = UDim.new(1,0)

    -- Nome
    local nameLbl = Instance.new("TextLabel", row)
    nameLbl.Size = UDim2.new(0,120,1,0); nameLbl.Position = UDim2.new(0,34,0,0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = od.name
    nameLbl.TextColor3 = od.color
    nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 12
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.ZIndex = 13

    -- Quantidade visível
    local qtyLbl = Instance.new("TextLabel", row)
    qtyLbl.Size = UDim2.new(0,50,1,0); qtyLbl.Position = UDim2.new(0,158,0,0)
    qtyLbl.BackgroundTransparency = 1
    qtyLbl.Text = "0 vis"
    qtyLbl.TextColor3 = C.sub
    qtyLbl.Font = Enum.Font.Gotham; qtyLbl.TextSize = 10
    qtyLbl.TextXAlignment = Enum.TextXAlignment.Left; qtyLbl.ZIndex = 13

    -- Botão TP (vai para o mais próximo deste tipo)
    local tpBtn = Instance.new("TextButton", row)
    tpBtn.Size = UDim2.new(0,70,0,22); tpBtn.Position = UDim2.new(0,210,0,4)
    tpBtn.BackgroundColor3 = C.accent; tpBtn.BorderSizePixel = 0
    tpBtn.Text = "▶ TP"
    tpBtn.TextColor3 = Color3.new(1,1,1)
    tpBtn.Font = Enum.Font.GothamBold; tpBtn.TextSize = 11; tpBtn.ZIndex = 14
    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0,6)

    -- Toggle ESP individual
    local oreNameCapture = od.name
    local oreColorCapture = od.color
    espDot.MouseButton1Click:Connect(function()
        oreActive[oreNameCapture] = not oreActive[oreNameCapture]
        if oreActive[oreNameCapture] then
            espDot.Text = "●"; espDot.BackgroundColor3 = oreColorCapture
        else
            espDot.Text = "○"; espDot.BackgroundColor3 = C.card
            -- Remove ESP deste minério imediatamente
            for m, data in pairs(oreESP) do
                if m.Name == oreNameCapture then
                    pcall(function() data.hl:Destroy() end)
                    pcall(function() if data.bb then data.bb:Destroy() end end)
                    oreESP[m] = nil
                end
            end
        end
    end)

    -- TP para o mais próximo deste tipo
    tpBtn.MouseButton1Click:Connect(function()
        tpToNearestOre(oreNameCapture)
    end)

    -- Guarda ref do qtyLbl para atualização
    od._qtyLbl = qtyLbl
end

-- Atualiza contadores de quantidade visível
task.spawn(function()
    while OreGui.Parent do
        pcall(function()
            if not oreWinVisible then task.wait(2); return end
            local folder = getOresFolder2()
            -- Conta por tipo
            local counts = {}
            if folder then
                for _, ore in pairs(folder:GetChildren()) do
                    counts[ore.Name] = (counts[ore.Name] or 0) + 1
                end
            end
            -- Atualiza labels
            for _, od in ipairs(ORE_DATA) do
                if od._qtyLbl then
                    local n = counts[od.name] or 0
                    od._qtyLbl.Text = n.."x"
                    od._qtyLbl.TextColor3 = n > 0 and C.green or C.sub
                end
            end
            -- Total visível no ESP de minerios
            local espCount = 0
            for _ in pairs(oreESP) do espCount = espCount + 1 end
            oreCountLbl.Text = "Visiveis: "..espCount
            -- Total drops no chao
            local dropCount = 0
            for _ in pairs(dropESP) do dropCount = dropCount + 1 end
            pcall(function() dropCountLbl.Text = "Drops no chao: "..dropCount end)
        end)
        task.wait(2)
    end
end)

-- ── Auto-descoberta de minerios novos ──
-- Quando PlayerMinedOre disparar com minerio desconhecido,
-- lê o Configuration da pedra, gera cor, adiciona na lista
-- e salva em arquivo para próximas sessões.
do
    local knownNames = {}
    for _, od in ipairs(ORE_DATA) do knownNames[od.name] = true end

    local DISC_FILE = "DXTP_ores_"..tostring(game.PlaceId)..".json"
    local HS = game:GetService("HttpService")

    -- Gera cor única pelo nome (hash HSV)
    local function autoColor(name)
        local h = 0
        for i = 1, #name do h = (h*31 + string.byte(name,i)) % 360 end
        local s,v = 0.65, 0.90
        local c2 = v*s; local x2 = c2*(1-math.abs((h/60)%2-1)); local m = v-c2
        local r,g,b = 0,0,0
        if h<60 then r,g,b=c2,x2,0 elseif h<120 then r,g,b=x2,c2,0
        elseif h<180 then r,g,b=0,c2,x2 elseif h<240 then r,g,b=0,x2,c2
        elseif h<300 then r,g,b=x2,0,c2 else r,g,b=c2,0,x2 end
        return Color3.new(r+m, g+m, b+m)
    end

    -- Cria a row na GUI para um novo minério
    local function addNewOreRow(od)
        -- Separador "Descoberto"
        local sep = Instance.new("Frame", oreScroll)
        sep.Size = UDim2.new(1,0,0,18)
        sep.BackgroundColor3 = Color3.fromRGB(20,60,40)
        sep.BorderSizePixel = 0; sep.ZIndex = 12
        Instance.new("UICorner",sep).CornerRadius = UDim.new(0,5)
        local sepL = Instance.new("TextLabel", sep)
        sepL.Size = UDim2.new(1,-8,1,0); sepL.Position = UDim2.new(0,8,0,0)
        sepL.BackgroundTransparency = 1
        sepL.Text = "✨ Descoberto: "..od.name
        sepL.TextColor3 = Color3.fromRGB(100,255,150)
        sepL.Font = Enum.Font.GothamBold; sepL.TextSize = 10
        sepL.TextXAlignment = Enum.TextXAlignment.Left; sepL.ZIndex = 13

        -- Row
        local row = Instance.new("Frame", oreScroll)
        row.Size = UDim2.new(1,0,0,30); row.BackgroundColor3 = C.card
        row.BorderSizePixel = 0; row.ZIndex = 12
        Instance.new("UICorner",row).CornerRadius = UDim.new(0,6)

        local bar = Instance.new("Frame",row)
        bar.Size=UDim2.new(0,4,0.8,0); bar.Position=UDim2.new(0,0,0.1,0)
        bar.BackgroundColor3=od.color; bar.BorderSizePixel=0; bar.ZIndex=13
        Instance.new("UICorner",bar).CornerRadius=UDim.new(0,3)

        local dot = Instance.new("TextButton",row)
        dot.Size=UDim2.new(0,22,0,22); dot.Position=UDim2.new(0,8,0,4)
        dot.BackgroundColor3=od.color; dot.BorderSizePixel=0
        dot.Text="●"; dot.TextColor3=Color3.new(1,1,1)
        dot.Font=Enum.Font.GothamBold; dot.TextSize=14; dot.ZIndex=14
        Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)

        local nL = Instance.new("TextLabel",row)
        nL.Size=UDim2.new(0,120,1,0); nL.Position=UDim2.new(0,34,0,0)
        nL.BackgroundTransparency=1; nL.Text=od.name
        nL.TextColor3=od.color; nL.Font=Enum.Font.GothamBold
        nL.TextSize=12; nL.TextXAlignment=Enum.TextXAlignment.Left; nL.ZIndex=13

        local qL = Instance.new("TextLabel",row)
        qL.Size=UDim2.new(0,50,1,0); qL.Position=UDim2.new(0,158,0,0)
        qL.BackgroundTransparency=1; qL.Text="1x"
        qL.TextColor3=C.perma; qL.Font=Enum.Font.Gotham
        qL.TextSize=10; qL.TextXAlignment=Enum.TextXAlignment.Left; qL.ZIndex=13

        local tpB = Instance.new("TextButton",row)
        tpB.Size=UDim2.new(0,70,0,22); tpB.Position=UDim2.new(0,210,0,4)
        tpB.BackgroundColor3=C.accent; tpB.BorderSizePixel=0
        tpB.Text="▶ TP"; tpB.TextColor3=Color3.new(1,1,1)
        tpB.Font=Enum.Font.GothamBold; tpB.TextSize=11; tpB.ZIndex=14
        Instance.new("UICorner",tpB).CornerRadius=UDim.new(0,6)

        local capName = od.name; local capCol = od.color
        dot.MouseButton1Click:Connect(function()
            oreActive[capName] = not oreActive[capName]
            dot.Text = oreActive[capName] and "●" or "○"
            dot.BackgroundColor3 = oreActive[capName] and capCol or C.card
            if not oreActive[capName] then
                for m, data in pairs(oreESP) do
                    if m.Name == capName then
                        pcall(function() data.hl:Destroy() end)
                        pcall(function() if data.bb then data.bb:Destroy() end end)
                        oreESP[m] = nil
                    end
                end
            end
        end)
        tpB.MouseButton1Click:Connect(function() tpToNearestOre(capName) end)
        od._qtyLbl = qL
    end

    -- Carrega minerios descobertos em sessões anteriores
    pcall(function()
        local ok,raw = pcall(readfile, DISC_FILE)
        if not ok or not raw or raw=="" then return end
        local ok2,t = pcall(function() return HS:JSONDecode(raw) end)
        if not ok2 or not t then return end
        for _, entry in ipairs(t) do
            if not knownNames[entry.name] then
                local col = Color3.fromRGB(
                    math.floor((entry.cr or 0.5)*255),
                    math.floor((entry.cg or 0.5)*255),
                    math.floor((entry.cb or 0.5)*255))
                local od = {name=entry.name, drop=entry.drop, tier=entry.tier or 0, color=col}
                table.insert(ORE_DATA, od)
                oreActive[od.name] = true
                knownNames[od.name] = true
                addNewOreRow(od)
            end
        end
    end)

    -- Salva todos os descobertos
    local function saveDiscovered()
        local t = {}
        for _, od in ipairs(ORE_DATA) do
            if od._discovered then
                table.insert(t, {
                    name=od.name, drop=od.drop or "", tier=od.tier,
                    cr=od.color.R, cg=od.color.G, cb=od.color.B
                })
            end
        end
        pcall(function() writefile(DISC_FILE, HS:JSONEncode(t)) end)
    end

    -- Notificação visual (frame simples no OreGui)
    local discNotif = Instance.new("Frame", OreGui)
    discNotif.Size = UDim2.new(1,-12,0,34); discNotif.Position = UDim2.new(0,6,1,-46)
    discNotif.BackgroundColor3 = Color3.fromRGB(15,70,35); discNotif.BorderSizePixel=0
    discNotif.ZIndex=20; discNotif.Visible=false
    Instance.new("UICorner",discNotif).CornerRadius=UDim.new(0,7)
    local discL = Instance.new("TextLabel",discNotif)
    discL.Size=UDim2.new(1,-8,1,0); discL.Position=UDim2.new(0,8,0,0)
    discL.BackgroundTransparency=1; discL.Text="Novo minerio!"
    discL.TextColor3=Color3.fromRGB(80,255,140); discL.Font=Enum.Font.GothamBold
    discL.TextSize=12; discL.TextXAlignment=Enum.TextXAlignment.Left; discL.ZIndex=21

    -- Listener
    local bindDisc = game.ReplicatedStorage:FindFirstChild("Events")
    if bindDisc then bindDisc = bindDisc:FindFirstChild("PlayerMinedOre") end
    if bindDisc then
        bindDisc.Event:Connect(function()
            task.wait(0.15)
            local folder = getOresFolder2()
            if not folder then return end
            for _, ore in pairs(folder:GetChildren()) do
                if ore.Name ~= "_Decoration" and not knownNames[ore.Name] then
                    local cfg  = ore:FindFirstChild("Configuration")
                    local dropV = cfg and cfg:FindFirstChild("Drop")
                    local tierV = cfg and cfg:FindFirstChild("Tier")
                    local dropName = dropV and dropV.Value or ore.Name
                    local tier     = tierV and math.clamp(math.floor(tierV.Value),1,5) or 0
                    local col      = autoColor(ore.Name)
                    local od = {name=ore.Name, drop=dropName, tier=tier, color=col, _discovered=true}
                    table.insert(ORE_DATA, od)
                    oreActive[ore.Name] = true
                    knownNames[ore.Name] = true
                    addNewOreRow(od)
                    saveDiscovered()
                    discL.Text = "✨ Novo: "..ore.Name.."  drop="..dropName.."  tier="..tier
                    discNotif.Visible = true
                    task.delay(4, function() pcall(function() discNotif.Visible=false end) end)
                    print("[RefinaryTPDX] Novo minerio: "..ore.Name.." | drop="..dropName.." | tier="..tier)
                end
            end
        end)
    end
end

-- ── Drag da janela de minerios ──
do
    local drag,ds,sp = false
    OreHdr.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; ds=i.Position; sp=OreGui.Position
        end
    end)
    OreHdr.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            OreGui.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

-- ── Tecla [Insert] abre/fecha aba de minerios ──
UserInputService.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.Insert then
        oreWinVisible = not oreWinVisible
        OreGui.Visible = oreWinVisible
    end
end)

-- ── Botão no header do menu principal para abrir aba de minerios ──
local oreTabBtn = Instance.new("TextButton", Hdr)
oreTabBtn.Size = UDim2.new(0,28,0,28)
oreTabBtn.Position = UDim2.new(1,-70,0,8)  -- à esquerda do botão minimizar
oreTabBtn.BackgroundColor3 = Color3.fromRGB(80,140,60)
oreTabBtn.BorderSizePixel = 0
oreTabBtn.Text = "⛏"
oreTabBtn.TextColor3 = Color3.new(1,1,1)
oreTabBtn.Font = Enum.Font.GothamBold; oreTabBtn.TextSize = 14; oreTabBtn.ZIndex = 14
Instance.new("UICorner", oreTabBtn).CornerRadius = UDim.new(0,7)
oreTabBtn.MouseButton1Click:Connect(function()
    oreWinVisible = not oreWinVisible
    OreGui.Visible = oreWinVisible
end)

print("✔ Modulo Minerios carregado | Insert = abre/fecha | ⛏ no header")
