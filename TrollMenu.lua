-- ╔══════════════════════════════════════════════╗
-- ║         TROLL MENU v2 - by Script            ║
-- ║   Spin | Fly | TP | Sarrar | SpeedHack       ║
-- ╚══════════════════════════════════════════════╝

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer  = Players.LocalPlayer
local Character    = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Camera       = workspace.CurrentCamera

-- ══════════════════════════════════════════
--  VARIAVEIS DE CONTROLE
-- ══════════════════════════════════════════
local target         = nil
local spinEnabled    = false
local flyEnabled     = false
local tpEnabled      = false
local sarrarEnabled  = false
local speedEnabled   = false

local spinSpeed      = 8       -- velocidade do spin (graus por frame)
local flySpeed       = 50      -- velocidade do fly
local studs          = 1       -- distancia do sarrar (studs)
local speedValue     = 50      -- walkspeed

local flyBodyVel     = nil
local flyBodyGyro    = nil
local connections    = {}

-- ══════════════════════════════════════════
--  HELPER: pega HumanoidRootPart seguro
-- ══════════════════════════════════════════
local function getRoot(player)
    local char = player and player.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
    return nil
end

local function getHum(player)
    local char = player and player.Character
    if char then return char:FindFirstChildOfClass("Humanoid") end
    return nil
end

local function myRoot()
    return getRoot(LocalPlayer)
end

-- ══════════════════════════════════════════
--  GUI PRINCIPAL
-- ══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TrollMenuV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

-- Frame principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 310, 0, 540)
MainFrame.Position = UDim2.new(0, 20, 0.5, -270)
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Borda vermelha
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(220, 0, 60)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Corner
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 4)
MainCorner.Parent = MainFrame

-- ── HEADER ───────────────────────────────
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 46)
Header.BackgroundColor3 = Color3.fromRGB(14, 8, 30)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 4)
HeaderCorner.Parent = Header

-- linha topo vermelha
local TopLine = Instance.new("Frame")
TopLine.Size = UDim2.new(1, 0, 0, 2)
TopLine.BackgroundColor3 = Color3.fromRGB(220, 0, 60)
TopLine.BorderSizePixel = 0
TopLine.Parent = Header

local TopGrad = Instance.new("UIGradient")
TopGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(220,0,60)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,80,0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(220,0,60)),
})
TopGrad.Parent = TopLine

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "💀 TROLL.EXE"
TitleLabel.TextColor3 = Color3.fromRGB(220, 0, 60)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(1, -60, 0, 14)
SubLabel.Position = UDim2.new(0, 14, 0, 28)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = "MOD MENU  •  JJSPLOIT"
SubLabel.TextColor3 = Color3.fromRGB(80, 40, 80)
SubLabel.TextSize = 9
SubLabel.Font = Enum.Font.Code
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.Parent = Header

-- Botão fechar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(180, 0, 40)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ── SCROLL CONTENT ───────────────────────
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, 0, 1, -46)
ScrollFrame.Position = UDim2.new(0, 0, 0, 46)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(220, 0, 60)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 4)
ContentLayout.Parent = ScrollFrame

local ContentPad = Instance.new("UIPadding")
ContentPad.PaddingLeft  = UDim.new(0, 8)
ContentPad.PaddingRight = UDim.new(0, 8)
ContentPad.PaddingTop   = UDim.new(0, 8)
ContentPad.PaddingBottom= UDim.new(0, 8)
ContentPad.Parent = ScrollFrame

-- ══════════════════════════════════════════
--  FACTORY FUNCTIONS
-- ══════════════════════════════════════════

-- Rótulo de seção
local function makeSection(text)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 20)
    f.BackgroundTransparency = 1
    f.Parent = ScrollFrame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "── " .. text .. " ──"
    lbl.TextColor3 = Color3.fromRGB(150, 0, 40)
    lbl.TextSize = 9
    lbl.Font = Enum.Font.Code
    lbl.Parent = f
    return f
end

-- Botão toggle
local function makeToggle(icon, label, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(14, 6, 20)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = ScrollFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 0, 30)
    stroke.Thickness = 1
    stroke.Parent = btn

    local iconL = Instance.new("TextLabel")
    iconL.Size = UDim2.new(0, 30, 1, 0)
    iconL.Position = UDim2.new(0, 6, 0, 0)
    iconL.BackgroundTransparency = 1
    iconL.Text = icon
    iconL.TextSize = 16
    iconL.Font = Enum.Font.GothamBold
    iconL.TextColor3 = Color3.fromRGB(200, 200, 200)
    iconL.Parent = btn

    local textL = Instance.new("TextLabel")
    textL.Size = UDim2.new(1, -90, 1, 0)
    textL.Position = UDim2.new(0, 40, 0, 0)
    textL.BackgroundTransparency = 1
    textL.Text = label
    textL.TextColor3 = Color3.fromRGB(180, 180, 180)
    textL.TextSize = 11
    textL.Font = Enum.Font.GothamBold
    textL.TextXAlignment = Enum.TextXAlignment.Left
    textL.Parent = btn

    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 40, 0, 18)
    badge.Position = UDim2.new(1, -48, 0.5, -9)
    badge.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    badge.Text = "OFF"
    badge.TextColor3 = Color3.fromRGB(80, 80, 80)
    badge.TextSize = 9
    badge.Font = Enum.Font.GothamBold
    badge.BorderSizePixel = 0
    badge.Parent = btn
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 3)

    local active = false

    local function setActive(val)
        active = val
        if val then
            btn.BackgroundColor3  = Color3.fromRGB(30, 5, 20)
            stroke.Color          = Color3.fromRGB(220, 0, 60)
            textL.TextColor3      = Color3.fromRGB(255, 60, 100)
            badge.Text            = "ON"
            badge.TextColor3      = Color3.fromRGB(0, 220, 100)
            badge.BackgroundColor3= Color3.fromRGB(0, 40, 15)
        else
            btn.BackgroundColor3  = Color3.fromRGB(14, 6, 20)
            stroke.Color          = Color3.fromRGB(60, 0, 30)
            textL.TextColor3      = Color3.fromRGB(180, 180, 180)
            badge.Text            = "OFF"
            badge.TextColor3      = Color3.fromRGB(80, 80, 80)
            badge.BackgroundColor3= Color3.fromRGB(20, 20, 20)
        end
    end

    btn.MouseButton1Click:Connect(function()
        active = not active
        setActive(active)
        callback(active)
    end)

    return btn, setActive
end

-- Slider
local function makeSlider(icon, label, minV, maxV, defaultV, step, onChange)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundColor3 = Color3.fromRGB(6, 14, 20)
    frame.BorderSizePixel = 0
    frame.Parent = ScrollFrame
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(0, 60, 80)
    st.Thickness = 1
    st.Parent = frame

    local topRow = Instance.new("Frame")
    topRow.Size = UDim2.new(1, -12, 0, 22)
    topRow.Position = UDim2.new(0, 6, 0, 4)
    topRow.BackgroundTransparency = 1
    topRow.Parent = frame

    local iconL = Instance.new("TextLabel")
    iconL.Size = UDim2.new(0, 22, 1, 0)
    iconL.BackgroundTransparency = 1
    iconL.Text = icon
    iconL.TextSize = 13
    iconL.Font = Enum.Font.GothamBold
    iconL.TextColor3 = Color3.fromRGB(0, 200, 220)
    iconL.Parent = topRow

    local labelL = Instance.new("TextLabel")
    labelL.Size = UDim2.new(1, -60, 1, 0)
    labelL.Position = UDim2.new(0, 26, 0, 0)
    labelL.BackgroundTransparency = 1
    labelL.Text = label
    labelL.TextColor3 = Color3.fromRGB(0, 200, 220)
    labelL.TextSize = 10
    labelL.Font = Enum.Font.GothamBold
    labelL.TextXAlignment = Enum.TextXAlignment.Left
    labelL.Parent = topRow

    local valL = Instance.new("TextLabel")
    valL.Size = UDim2.new(0, 50, 1, 0)
    valL.Position = UDim2.new(1, -50, 0, 0)
    valL.BackgroundTransparency = 1
    valL.Text = tostring(defaultV)
    valL.TextColor3 = Color3.fromRGB(0, 255, 200)
    valL.TextSize = 11
    valL.Font = Enum.Font.GothamBold
    valL.TextXAlignment = Enum.TextXAlignment.Right
    valL.Parent = topRow

    -- Track
    local trackBg = Instance.new("Frame")
    trackBg.Size = UDim2.new(1, -12, 0, 6)
    trackBg.Position = UDim2.new(0, 6, 0, 32)
    trackBg.BackgroundColor3 = Color3.fromRGB(20, 40, 50)
    trackBg.BorderSizePixel = 0
    trackBg.Parent = frame
    Instance.new("UICorner", trackBg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultV - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 220)
    fill.BorderSizePixel = 0
    fill.Parent = trackBg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,200,220)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,100,255)),
    })
    fillGrad.Parent = fill

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.Position = UDim2.new((defaultV - minV)/(maxV - minV), 0, 0.5, 0)
    thumb.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
    thumb.BorderSizePixel = 0
    thumb.Parent = trackBg
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    local currentVal = defaultV
    local dragging = false

    local function updateSlider(x)
        local abs = trackBg.AbsolutePosition.X
        local w   = trackBg.AbsoluteSize.X
        local t   = math.clamp((x - abs) / w, 0, 1)
        local raw = minV + t * (maxV - minV)
        -- snap to step
        local snapped = math.round(raw / step) * step
        snapped = math.clamp(snapped, minV, maxV)
        currentVal = snapped
        local pct = (snapped - minV) / (maxV - minV)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, 0, 0.5, 0)
        valL.Text = tostring(snapped)
        onChange(snapped)
    end

    trackBg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(inp.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(inp.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return frame
end

-- Label target
local function makeTargetDisplay()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 36)
    f.BackgroundColor3 = Color3.fromRGB(25, 5, 10)
    f.BorderSizePixel = 0
    f.Parent = ScrollFrame
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(120, 0, 40)
    st.Thickness = 1
    st.Parent = f

    local lbl = Instance.new("TextLabel")
    lbl.Name = "TargetLabel"
    lbl.Size = UDim2.new(1, -10, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "🎯 TARGET: NENHUM"
    lbl.TextColor3 = Color3.fromRGB(220, 0, 60)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f
    return f, lbl
end

-- Player list
local function makePlayerList()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 160)
    f.BackgroundColor3 = Color3.fromRGB(6, 8, 20)
    f.BorderSizePixel = 0
    f.Parent = ScrollFrame
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(0, 40, 80)
    st.Thickness = 1
    st.Parent = f

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 20)
    header.BackgroundColor3 = Color3.fromRGB(0, 10, 30)
    header.BorderSizePixel = 0
    header.Text = "  👥 JOGADORES ONLINE"
    header.TextColor3 = Color3.fromRGB(0, 180, 255)
    header.TextSize = 9
    header.Font = Enum.Font.GothamBold
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = f
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 4)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -4, 1, -24)
    scroll.Position = UDim2.new(0, 2, 0, 22)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 120, 200)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = f

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 4)
    pad.PaddingTop = UDim.new(0, 2)
    pad.Parent = scroll

    return f, scroll
end

-- Log box
local function makeLogBox()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 70)
    f.BackgroundColor3 = Color3.fromRGB(4, 4, 8)
    f.BorderSizePixel = 0
    f.Parent = ScrollFrame
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(40, 0, 20)
    st.Thickness = 1
    st.Parent = f

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -4, 1, -4)
    scroll.Position = UDim2.new(0, 2, 0, 2)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 0, 30)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = f

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 1)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Parent = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 5)
    pad.PaddingBottom = UDim.new(0, 2)
    pad.Parent = scroll

    return f, scroll
end

-- ══════════════════════════════════════════
--  CONSTRUIR INTERFACE
-- ══════════════════════════════════════════

-- Target display
makeSection("TARGET")
local _, targetLabel = makeTargetDisplay()

-- Players
makeSection("JOGADORES")
local _, playerScroll = makePlayerList()

-- Movement
makeSection("MOVEMENT")

local _, setSpinActive = makeToggle("🌀", "SPIN", function(on)
    spinEnabled = on
    log(on and "Spin ATIVADO" or "Spin desativado", on and "ok" or "info")
end)

local _, setFlyActive = makeToggle("🚀", "FLY", function(on)
    flyEnabled = on
    if on then
        enableFly()
        log("Fly ATIVADO", "ok")
    else
        disableFly()
        log("Fly desativado", "info")
    end
end)

makeSlider("⚡", "FLY SPEED", 10, 200, 50, 5, function(v)
    flySpeed = v
end)

-- Speed
makeSection("SPEED")

local _, setSpeedActive = makeToggle("🏃", "SPEED HACK", function(on)
    speedEnabled = on
    local hum = getHum(LocalPlayer)
    if hum then
        hum.WalkSpeed = on and speedValue or 16
    end
    log(on and ("SpeedHack ON → " .. speedValue) or "SpeedHack OFF → 16", on and "ok" or "info")
end)

makeSlider("💨", "WALK SPEED", 16, 500, 50, 1, function(v)
    speedValue = v
    if speedEnabled then
        local hum = getHum(LocalPlayer)
        if hum then hum.WalkSpeed = v end
    end
end)

-- Teleport
makeSection("TELEPORT")

local _, setTpActive = makeToggle("⚡", "TP TO TARGET", function(on)
    tpEnabled = on
    if on then
        if not target then
            log("Selecione um target primeiro!", "err")
            tpEnabled = false
            setTpActive(false)
            return
        end
        local root = myRoot()
        local tRoot = getRoot(target)
        if root and tRoot then
            root.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0)
            log("TP → " .. target.Name, "ok")
        end
        tpEnabled = false
        setTpActive(false)
    end
end)

-- Troll
makeSection("TROLL")

local _, setSarrarActive = makeToggle("🍑", "SARRAR ATRÁS", function(on)
    sarrarEnabled = on
    if on then
        if not target then
            log("Selecione um target primeiro!", "err")
            sarrarEnabled = false
            setSarrarActive(false)
            return
        end
        log("Sarrando " .. target.Name .. " @ " .. studs .. " stud(s) 🍑", "warn")
    else
        log("Sarrar desativado", "info")
    end
end)

makeSlider("📏", "STUD DISTANCE", 0, 10, 1, 0.5, function(v)
    studs = v
end)

-- Log
makeSection("LOG")
local _, logScroll = makeLogBox()

-- ══════════════════════════════════════════
--  LOG FUNCTION
-- ══════════════════════════════════════════
local logColors = {
    info = Color3.fromRGB(0, 160, 220),
    ok   = Color3.fromRGB(0, 200, 80),
    warn = Color3.fromRGB(255, 130, 0),
    err  = Color3.fromRGB(220, 40, 60),
}

function log(msg, tipo)
    tipo = tipo or "info"
    local prefix = { info="[INFO]", ok="[ OK ]", warn="[TROL]", err="[ERR ]" }
    local line = Instance.new("TextLabel")
    line.Size = UDim2.new(1, 0, 0, 12)
    line.BackgroundTransparency = 1
    line.Text = prefix[tipo] .. " " .. msg
    line.TextColor3 = logColors[tipo]
    line.TextSize = 8
    line.Font = Enum.Font.Code
    line.TextXAlignment = Enum.TextXAlignment.Left
    line.Parent = logScroll

    -- máximo 40 linhas
    local children = logScroll:GetChildren()
    local lbls = {}
    for _, c in ipairs(children) do
        if c:IsA("TextLabel") then table.insert(lbls, c) end
    end
    if #lbls > 40 then lbls[1]:Destroy() end

    -- auto scroll
    task.defer(function()
        logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y)
    end)
end

-- ══════════════════════════════════════════
--  RENDERIZAR JOGADORES
-- ══════════════════════════════════════════
local function renderPlayers()
    -- limpar lista
    for _, c in ipairs(playerScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    local list = Players:GetPlayers()
    for _, p in ipairs(list) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = (target == p)
                and Color3.fromRGB(40, 5, 20)
                or  Color3.fromRGB(10, 10, 25)
            btn.BorderSizePixel = 0
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.Parent = playerScroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)

            local stroke = Instance.new("UIStroke")
            stroke.Color = (target == p)
                and Color3.fromRGB(220, 0, 60)
                or  Color3.fromRGB(30, 30, 60)
            stroke.Thickness = 1
            stroke.Parent = btn

            local nameL = Instance.new("TextLabel")
            nameL.Size = UDim2.new(1, -50, 1, 0)
            nameL.Position = UDim2.new(0, 8, 0, 0)
            nameL.BackgroundTransparency = 1
            nameL.Text = "👤 " .. p.Name
            nameL.TextColor3 = (target == p)
                and Color3.fromRGB(255, 60, 100)
                or  Color3.fromRGB(180, 180, 180)
            nameL.TextSize = 10
            nameL.Font = Enum.Font.GothamBold
            nameL.TextXAlignment = Enum.TextXAlignment.Left
            nameL.Parent = btn

            local selL = Instance.new("TextLabel")
            selL.Size = UDim2.new(0, 40, 1, 0)
            selL.Position = UDim2.new(1, -44, 0, 0)
            selL.BackgroundTransparency = 1
            selL.Text = (target == p) and "◀ SEL" or "SELECT"
            selL.TextColor3 = (target == p)
                and Color3.fromRGB(220, 0, 60)
                or  Color3.fromRGB(60, 60, 80)
            selL.TextSize = 8
            selL.Font = Enum.Font.Code
            selL.Parent = btn

            btn.MouseButton1Click:Connect(function()
                target = p
                targetLabel.Text = "🎯 TARGET: " .. p.Name
                log("Target → " .. p.Name, "warn")
                renderPlayers()
            end)
        end
    end
end

-- Atualizar quando jogadores entram/saem
Players.PlayerAdded:Connect(function(p)
    log(p.Name .. " entrou no servidor", "ok")
    renderPlayers()
end)

Players.PlayerRemoving:Connect(function(p)
    log(p.Name .. " saiu do servidor", "info")
    if target == p then
        target = nil
        targetLabel.Text = "🎯 TARGET: NENHUM"
        sarrarEnabled = false
        setSarrarActive(false)
        log("Target " .. p.Name .. " desconectou!", "err")
    end
    renderPlayers()
end)

-- ══════════════════════════════════════════
--  FLY
-- ══════════════════════════════════════════
function enableFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    hum.PlatformStand = true

    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.Velocity = Vector3.zero
    flyBodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBodyVel.Parent = root

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBodyGyro.P = 1e4
    flyBodyGyro.CFrame = root.CFrame
    flyBodyGyro.Parent = root
end

function disableFly()
    if flyBodyVel  then flyBodyVel:Destroy();  flyBodyVel  = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    local hum = getHum(LocalPlayer)
    if hum then hum.PlatformStand = false end
end

-- ══════════════════════════════════════════
--  RESPAWN HANDLER
-- ══════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    task.wait(1)
    if speedEnabled then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = speedValue end
    end
    if flyEnabled then enableFly() end
    log("Personagem respawnado", "info")
end)

-- ══════════════════════════════════════════
--  LOOP PRINCIPAL (RunService)
-- ══════════════════════════════════════════
local spinAngle = 0

local conn = RunService.Heartbeat:Connect(function(dt)
    local root = myRoot()

    -- SPIN
    if spinEnabled and root then
        spinAngle = spinAngle + spinSpeed
        if spinAngle >= 360 then spinAngle = spinAngle - 360 end
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
    end

    -- FLY
    if flyEnabled and flyBodyVel and flyBodyGyro then
        local camCF = Camera.CFrame
        local vel   = Vector3.zero
        local spd   = flySpeed

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            vel = vel + camCF.LookVector * spd
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            vel = vel - camCF.LookVector * spd
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            vel = vel - camCF.RightVector * spd
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            vel = vel + camCF.RightVector * spd
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            vel = vel + Vector3.new(0, spd, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            vel = vel - Vector3.new(0, spd, 0)
        end

        flyBodyVel.Velocity  = vel
        flyBodyGyro.CFrame   = camCF
    end

    -- SARRAR
    if sarrarEnabled and target and root then
        local tRoot = getRoot(target)
        if tRoot then
            local behind = tRoot.CFrame * CFrame.new(0, 0, studs)
            root.CFrame = CFrame.new(behind.Position, tRoot.Position)
        end
    end
end)

table.insert(connections, conn)

-- ══════════════════════════════════════════
--  INIT
-- ══════════════════════════════════════════
renderPlayers()
log("Troll.exe iniciado com sucesso!", "ok")
log("Selecione um player na lista", "info")
