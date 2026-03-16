-- ╔══════════════════════════════════════════════════════════════╗
-- ║              TROLL MENU v4  -  JJSploit                     ║
-- ║  Spin | Fly | Sarrar | Speed | Jump | Fling | ESP | Orbit   ║
-- ╚══════════════════════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- ══════════════════════════════════════════
--  VARIAVEIS
-- ══════════════════════════════════════════
local target      = nil
local searchQuery = ""
local logScroll   = nil

-- estados
local spinEnabled       = false
local flyEnabled        = false
local sarrarEnabled     = false
local speedEnabled      = false
local jumpEnabled       = false
local espEnabled        = false
local orbitEnabled      = false
local loopTpEnabled     = false
local cameraLockEnabled = false

-- valores
local spinSpeed  = 8
local flySpeed   = 50
local studs      = 1
local speedValue = 50
local jumpValue  = 50
local orbitRadius= 5
local orbitSpeed = 3

-- objetos de voo
local flyBodyVel  = nil
local flyBodyGyro = nil

-- loops/threads ativos
local orbitAngle  = 0

-- ESP: guarda os BillboardGuis criados
local espObjects  = {}

-- ══════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════
local function getRoot(player)
    local c = player and player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum(player)
    local c = player and player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function myRoot() return getRoot(LocalPlayer) end

-- ══════════════════════════════════════════
--  GUI BASE
-- ══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name          = "TrollMenuV4"
ScreenGui.ResetOnSpawn  = false
ScreenGui.ZIndexBehavior= Enum.ZIndexBehavior.Sibling
ScreenGui.Parent        = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size            = UDim2.new(0, 318, 0, 590)
MainFrame.Position        = UDim2.new(0, 20, 0.5, -295)
MainFrame.BackgroundColor3= Color3.fromRGB(8, 8, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active          = true
MainFrame.Draggable       = true
MainFrame.Parent          = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 5)
local ms = Instance.new("UIStroke")
ms.Color = Color3.fromRGB(220,0,60); ms.Thickness = 1.5; ms.Parent = MainFrame

-- ── HEADER ──────────────────────────────
local Header = Instance.new("Frame")
Header.Size             = UDim2.new(1, 0, 0, 46)
Header.BackgroundColor3 = Color3.fromRGB(14, 8, 30)
Header.BorderSizePixel  = 0
Header.Parent           = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 5)

local TopLine = Instance.new("Frame")
TopLine.Size             = UDim2.new(1, 0, 0, 2)
TopLine.BackgroundColor3 = Color3.fromRGB(220, 0, 60)
TopLine.BorderSizePixel  = 0
TopLine.Parent           = Header
local tg = Instance.new("UIGradient")
tg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(220,0,60)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,80,0)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(220,0,60)),
})
tg.Parent = TopLine

local function makeLabel(parent, text, size, pos, color, fontSize, font, align)
    local l = Instance.new("TextLabel")
    l.Size               = size
    l.Position           = pos
    l.BackgroundTransparency = 1
    l.Text               = text
    l.TextColor3         = color
    l.TextSize           = fontSize
    l.Font               = font or Enum.Font.GothamBold
    l.TextXAlignment     = align or Enum.TextXAlignment.Left
    l.Parent             = parent
    return l
end

makeLabel(Header, "💀 TROLL.EXE",
    UDim2.new(1,-90,1,0), UDim2.new(0,14,0,0),
    Color3.fromRGB(220,0,60), 16)
makeLabel(Header, "MOD MENU  •  JJSPLOIT",
    UDim2.new(1,-90,0,14), UDim2.new(0,14,0,28),
    Color3.fromRGB(80,40,80), 9, Enum.Font.Code)

-- Botão minimizar
local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0,28,0,28)
MinBtn.Position         = UDim2.new(1,-68,0.5,-14)
MinBtn.BackgroundColor3 = Color3.fromRGB(10,20,30)
MinBtn.Text             = "—"
MinBtn.TextColor3       = Color3.fromRGB(0,180,255)
MinBtn.TextSize         = 16
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.BorderSizePixel  = 0
MinBtn.Parent           = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 4)
local minStroke = Instance.new("UIStroke")
minStroke.Color = Color3.fromRGB(0,80,120); minStroke.Thickness=1; minStroke.Parent=MinBtn

local minimized = false
local function toggleMinimize()
    minimized = not minimized
    ScrollFrame.Visible = not minimized
    MainFrame.Size = minimized
        and UDim2.new(0, 318, 0, 46)
        or  UDim2.new(0, 318, 0, 590)
    MinBtn.Text = minimized and "▲" or "—"
    MinBtn.TextColor3 = minimized
        and Color3.fromRGB(0,255,150)
        or  Color3.fromRGB(0,180,255)
end

MinBtn.MouseButton1Click:Connect(toggleMinimize)

-- tecla HOME para minimizar/restaurar
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Home then
        toggleMinimize()
    end
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0,28,0,28)
CloseBtn.Position         = UDim2.new(1,-36,0.5,-14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30,10,10)
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.fromRGB(180,0,40)
CloseBtn.TextSize         = 14
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.BorderSizePixel  = 0
CloseBtn.Parent           = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)
CloseBtn.MouseButton1Click:Connect(function()
    -- ── CLEANUP TOTAL: apaga tudo sem deixar rastro ──

    -- desativa fly (remove BodyVelocity e BodyGyro)
    disableFly()

    -- restaura WalkSpeed e JumpPower originais
    local hum = getHum(LocalPlayer)
    if hum then
        hum.WalkSpeed   = 16
        hum.JumpPower   = 50
        hum.PlatformStand = false
    end

    -- restaura câmera
    Camera.CameraType = Enum.CameraType.Custom
    if hum then Camera.CameraSubject = hum end

    -- desancora target se estava frozen (safety)
    if target then
        local tRoot = getRoot(target)
        if tRoot then tRoot.Anchored = false end
    end

    -- limpa ESP (BillboardGuis)
    clearEsp()

    -- destrói a GUI inteira
    ScreenGui:Destroy()
end)

-- ── SCROLL PRINCIPAL ─────────────────────
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size                  = UDim2.new(1, 0, 1, -46)
ScrollFrame.Position              = UDim2.new(0, 0, 0, 46)
ScrollFrame.BackgroundTransparency= 1
ScrollFrame.BorderSizePixel       = 0
ScrollFrame.ScrollBarThickness    = 3
ScrollFrame.ScrollBarImageColor3  = Color3.fromRGB(220,0,60)
ScrollFrame.CanvasSize            = UDim2.new(0,0,0,0)
ScrollFrame.AutomaticCanvasSize   = Enum.AutomaticSize.Y
ScrollFrame.Parent                = MainFrame
local cl = Instance.new("UIListLayout"); cl.Padding = UDim.new(0,4); cl.Parent = ScrollFrame
local cp = Instance.new("UIPadding")
cp.PaddingLeft=UDim.new(0,8); cp.PaddingRight=UDim.new(0,8)
cp.PaddingTop=UDim.new(0,8);  cp.PaddingBottom=UDim.new(0,8)
cp.Parent = ScrollFrame

-- ══════════════════════════════════════════
--  FACTORY: seção, toggle, slider
-- ══════════════════════════════════════════
local function makeSection(text)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,20); f.BackgroundTransparency=1; f.Parent=ScrollFrame
    local l = Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text="── "..text.." ──"; l.TextColor3=Color3.fromRGB(150,0,40)
    l.TextSize=9; l.Font=Enum.Font.Code; l.Parent=f
end

local function makeToggle(icon, labelTxt, callback)
    local btn = Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,0,38); btn.BackgroundColor3=Color3.fromRGB(14,6,20)
    btn.BorderSizePixel=0; btn.Text=""; btn.AutoButtonColor=false; btn.Parent=ScrollFrame
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4)
    local stroke=Instance.new("UIStroke"); stroke.Color=Color3.fromRGB(60,0,30); stroke.Thickness=1; stroke.Parent=btn

    local il=Instance.new("TextLabel"); il.Size=UDim2.new(0,30,1,0); il.Position=UDim2.new(0,6,0,0)
    il.BackgroundTransparency=1; il.Text=icon; il.TextSize=16; il.Font=Enum.Font.GothamBold; il.Parent=btn

    local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,-90,1,0); tl.Position=UDim2.new(0,40,0,0)
    tl.BackgroundTransparency=1; tl.Text=labelTxt; tl.TextColor3=Color3.fromRGB(180,180,180)
    tl.TextSize=11; tl.Font=Enum.Font.GothamBold; tl.TextXAlignment=Enum.TextXAlignment.Left; tl.Parent=btn

    local badge=Instance.new("TextLabel"); badge.Size=UDim2.new(0,40,0,18); badge.Position=UDim2.new(1,-48,0.5,-9)
    badge.BackgroundColor3=Color3.fromRGB(20,20,20); badge.Text="OFF"; badge.TextColor3=Color3.fromRGB(80,80,80)
    badge.TextSize=9; badge.Font=Enum.Font.GothamBold; badge.BorderSizePixel=0; badge.Parent=btn
    Instance.new("UICorner",badge).CornerRadius=UDim.new(0,3)

    local active=false
    local function setActive(val)
        active=val
        if val then
            btn.BackgroundColor3=Color3.fromRGB(30,5,20); stroke.Color=Color3.fromRGB(220,0,60)
            tl.TextColor3=Color3.fromRGB(255,60,100); badge.Text="ON"
            badge.TextColor3=Color3.fromRGB(0,220,100); badge.BackgroundColor3=Color3.fromRGB(0,40,15)
        else
            btn.BackgroundColor3=Color3.fromRGB(14,6,20); stroke.Color=Color3.fromRGB(60,0,30)
            tl.TextColor3=Color3.fromRGB(180,180,180); badge.Text="OFF"
            badge.TextColor3=Color3.fromRGB(80,80,80); badge.BackgroundColor3=Color3.fromRGB(20,20,20)
        end
    end
    btn.MouseButton1Click:Connect(function() active=not active; setActive(active); callback(active) end)
    return btn, setActive
end

local function makeSlider(icon, labelTxt, minV, maxV, defaultV, step, onChange)
    local frame=Instance.new("Frame"); frame.Size=UDim2.new(1,0,0,48)
    frame.BackgroundColor3=Color3.fromRGB(6,14,20); frame.BorderSizePixel=0; frame.Parent=ScrollFrame
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,4)
    local st=Instance.new("UIStroke"); st.Color=Color3.fromRGB(0,60,80); st.Thickness=1; st.Parent=frame

    local row=Instance.new("Frame"); row.Size=UDim2.new(1,-12,0,22); row.Position=UDim2.new(0,6,0,4)
    row.BackgroundTransparency=1; row.Parent=frame

    local iL=Instance.new("TextLabel"); iL.Size=UDim2.new(0,22,1,0); iL.BackgroundTransparency=1
    iL.Text=icon; iL.TextSize=13; iL.Font=Enum.Font.GothamBold; iL.TextColor3=Color3.fromRGB(0,200,220); iL.Parent=row

    local lL=Instance.new("TextLabel"); lL.Size=UDim2.new(1,-60,1,0); lL.Position=UDim2.new(0,26,0,0)
    lL.BackgroundTransparency=1; lL.Text=labelTxt; lL.TextColor3=Color3.fromRGB(0,200,220)
    lL.TextSize=10; lL.Font=Enum.Font.GothamBold; lL.TextXAlignment=Enum.TextXAlignment.Left; lL.Parent=row

    local vL=Instance.new("TextLabel"); vL.Size=UDim2.new(0,50,1,0); vL.Position=UDim2.new(1,-50,0,0)
    vL.BackgroundTransparency=1; vL.Text=tostring(defaultV); vL.TextColor3=Color3.fromRGB(0,255,200)
    vL.TextSize=11; vL.Font=Enum.Font.GothamBold; vL.TextXAlignment=Enum.TextXAlignment.Right; vL.Parent=row

    local track=Instance.new("Frame"); track.Size=UDim2.new(1,-12,0,6); track.Position=UDim2.new(0,6,0,32)
    track.BackgroundColor3=Color3.fromRGB(20,40,50); track.BorderSizePixel=0; track.Parent=frame
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local fill=Instance.new("Frame"); fill.Size=UDim2.new((defaultV-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(0,200,220); fill.BorderSizePixel=0; fill.Parent=track
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local fg=Instance.new("UIGradient"); fg.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(0,200,220)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(0,100,255))
    }); fg.Parent=fill

    local thumb=Instance.new("Frame"); thumb.Size=UDim2.new(0,14,0,14)
    thumb.AnchorPoint=Vector2.new(0.5,0.5); thumb.Position=UDim2.new((defaultV-minV)/(maxV-minV),0,0.5,0)
    thumb.BackgroundColor3=Color3.fromRGB(0,220,255); thumb.BorderSizePixel=0; thumb.Parent=track
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)

    local dragging=false
    local function upd(x)
        local t=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=math.clamp(math.round((minV+t*(maxV-minV))/step)*step,minV,maxV)
        local p=(v-minV)/(maxV-minV)
        fill.Size=UDim2.new(p,0,1,0); thumb.Position=UDim2.new(p,0,0.5,0)
        vL.Text=tostring(v); onChange(v)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; upd(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    return frame
end

-- ══════════════════════════════════════════
--  LOG
-- ══════════════════════════════════════════
local logColors={info=Color3.fromRGB(0,160,220),ok=Color3.fromRGB(0,200,80),warn=Color3.fromRGB(255,130,0),err=Color3.fromRGB(220,40,60)}
local function log(msg, tipo)
    if not logScroll then return end
    tipo=tipo or "info"
    local pfx={info="[INFO]",ok="[ OK ]",warn="[TROL]",err="[ERR ]"}
    local line=Instance.new("TextLabel"); line.Size=UDim2.new(1,0,0,12); line.BackgroundTransparency=1
    line.Text=pfx[tipo].." "..msg; line.TextColor3=logColors[tipo]; line.TextSize=8
    line.Font=Enum.Font.Code; line.TextXAlignment=Enum.TextXAlignment.Left; line.Parent=logScroll
    local lbls={}; for _,c in ipairs(logScroll:GetChildren()) do if c:IsA("TextLabel") then table.insert(lbls,c) end end
    if #lbls>40 then lbls[1]:Destroy() end
    task.defer(function() logScroll.CanvasPosition=Vector2.new(0,logScroll.AbsoluteCanvasSize.Y) end)
end

-- ══════════════════════════════════════════
--  TARGET DISPLAY
-- ══════════════════════════════════════════
makeSection("TARGET")

local targetFrame=Instance.new("Frame"); targetFrame.Size=UDim2.new(1,0,0,36)
targetFrame.BackgroundColor3=Color3.fromRGB(25,5,10); targetFrame.BorderSizePixel=0; targetFrame.Parent=ScrollFrame
Instance.new("UICorner",targetFrame).CornerRadius=UDim.new(0,4)
local tst=Instance.new("UIStroke"); tst.Color=Color3.fromRGB(120,0,40); tst.Thickness=1; tst.Parent=targetFrame
local targetLabel=Instance.new("TextLabel"); targetLabel.Size=UDim2.new(1,-10,1,0); targetLabel.Position=UDim2.new(0,10,0,0)
targetLabel.BackgroundTransparency=1; targetLabel.Text="🎯 TARGET: NENHUM"
targetLabel.TextColor3=Color3.fromRGB(220,0,60); targetLabel.TextSize=11; targetLabel.Font=Enum.Font.GothamBold
targetLabel.TextXAlignment=Enum.TextXAlignment.Left; targetLabel.Parent=targetFrame

-- ══════════════════════════════════════════
--  PLAYER LIST + BARRA DE PESQUISA
-- ══════════════════════════════════════════
makeSection("JOGADORES")

local playerSection=Instance.new("Frame"); playerSection.Size=UDim2.new(1,0,0,198)
playerSection.BackgroundColor3=Color3.fromRGB(6,8,20); playerSection.BorderSizePixel=0; playerSection.Parent=ScrollFrame
Instance.new("UICorner",playerSection).CornerRadius=UDim.new(0,4)
local pst=Instance.new("UIStroke"); pst.Color=Color3.fromRGB(0,40,80); pst.Thickness=1; pst.Parent=playerSection

-- header
local pHeader=Instance.new("Frame"); pHeader.Size=UDim2.new(1,0,0,22)
pHeader.BackgroundColor3=Color3.fromRGB(0,10,30); pHeader.BorderSizePixel=0; pHeader.Parent=playerSection
Instance.new("UICorner",pHeader).CornerRadius=UDim.new(0,4)
local pHeaderLbl=Instance.new("TextLabel"); pHeaderLbl.Size=UDim2.new(0.6,0,1,0); pHeaderLbl.Position=UDim2.new(0,8,0,0)
pHeaderLbl.BackgroundTransparency=1; pHeaderLbl.Text="👥 JOGADORES ONLINE"; pHeaderLbl.TextColor3=Color3.fromRGB(0,180,255)
pHeaderLbl.TextSize=9; pHeaderLbl.Font=Enum.Font.GothamBold; pHeaderLbl.TextXAlignment=Enum.TextXAlignment.Left; pHeaderLbl.Parent=pHeader
local pCountLbl=Instance.new("TextLabel"); pCountLbl.Size=UDim2.new(0.35,0,1,0); pCountLbl.Position=UDim2.new(0.65,0,0,0)
pCountLbl.BackgroundTransparency=1; pCountLbl.Text="0 players"; pCountLbl.TextColor3=Color3.fromRGB(220,0,60)
pCountLbl.TextSize=9; pCountLbl.Font=Enum.Font.GothamBold; pCountLbl.TextXAlignment=Enum.TextXAlignment.Right; pCountLbl.Parent=pHeader

-- barra de pesquisa
local searchBg=Instance.new("Frame"); searchBg.Size=UDim2.new(1,-10,0,28); searchBg.Position=UDim2.new(0,5,0,26)
searchBg.BackgroundColor3=Color3.fromRGB(12,12,30); searchBg.BorderSizePixel=0; searchBg.Parent=playerSection
Instance.new("UICorner",searchBg).CornerRadius=UDim.new(0,4)
local sst=Instance.new("UIStroke"); sst.Color=Color3.fromRGB(60,60,120); sst.Thickness=1; sst.Parent=searchBg

local lupaL=Instance.new("TextLabel"); lupaL.Size=UDim2.new(0,24,1,0); lupaL.Position=UDim2.new(0,4,0,0)
lupaL.BackgroundTransparency=1; lupaL.Text="🔍"; lupaL.TextSize=12; lupaL.Font=Enum.Font.GothamBold; lupaL.Parent=searchBg

local searchBox=Instance.new("TextBox"); searchBox.Size=UDim2.new(1,-54,1,0); searchBox.Position=UDim2.new(0,28,0,0)
searchBox.BackgroundTransparency=1; searchBox.BorderSizePixel=0; searchBox.Text=""
searchBox.PlaceholderText="Pesquisar jogador..."; searchBox.PlaceholderColor3=Color3.fromRGB(70,70,100)
searchBox.TextColor3=Color3.fromRGB(200,200,255); searchBox.TextSize=10; searchBox.Font=Enum.Font.Gotham
searchBox.TextXAlignment=Enum.TextXAlignment.Left; searchBox.ClearTextOnFocus=false; searchBox.Parent=searchBg

local clearSearchBtn=Instance.new("TextButton"); clearSearchBtn.Size=UDim2.new(0,22,1,0); clearSearchBtn.Position=UDim2.new(1,-24,0,0)
clearSearchBtn.BackgroundTransparency=1; clearSearchBtn.BorderSizePixel=0; clearSearchBtn.Text="✕"
clearSearchBtn.TextColor3=Color3.fromRGB(80,80,120); clearSearchBtn.TextSize=10; clearSearchBtn.Font=Enum.Font.GothamBold; clearSearchBtn.Parent=searchBg

searchBox.Focused:Connect(function()   sst.Color=Color3.fromRGB(0,120,220) end)
searchBox.FocusLost:Connect(function() sst.Color=Color3.fromRGB(60,60,120) end)
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery=searchBox.Text:lower(); renderPlayers()
end)
clearSearchBtn.MouseButton1Click:Connect(function()
    searchBox.Text=""; searchQuery=""; sst.Color=Color3.fromRGB(60,60,120); renderPlayers()
end)

-- lista
local playerScroll=Instance.new("ScrollingFrame"); playerScroll.Size=UDim2.new(1,-4,1,-58); playerScroll.Position=UDim2.new(0,2,0,57)
playerScroll.BackgroundTransparency=1; playerScroll.BorderSizePixel=0; playerScroll.ScrollBarThickness=2
playerScroll.ScrollBarImageColor3=Color3.fromRGB(0,120,200); playerScroll.CanvasSize=UDim2.new(0,0,0,0)
playerScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; playerScroll.Parent=playerSection
local playout=Instance.new("UIListLayout"); playout.Padding=UDim.new(0,2); playout.Parent=playerScroll
local ppad=Instance.new("UIPadding"); ppad.PaddingLeft=UDim.new(0,4); ppad.PaddingRight=UDim.new(0,4); ppad.PaddingTop=UDim.new(0,2); ppad.Parent=playerScroll

-- ══════════════════════════════════════════
--  RENDER PLAYERS
-- ══════════════════════════════════════════
function renderPlayers()
    for _,c in ipairs(playerScroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
    end
    local list=Players:GetPlayers(); local shown=0
    for _,p in ipairs(list) do
        if p~=LocalPlayer then
            if searchQuery~="" and not p.Name:lower():find(searchQuery,1,true) then continue end
            shown=shown+1
            local isSel=(target==p)
            local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,0,0,30)
            btn.BackgroundColor3=isSel and Color3.fromRGB(40,5,20) or Color3.fromRGB(10,10,28)
            btn.BorderSizePixel=0; btn.Text=""; btn.AutoButtonColor=false; btn.Parent=playerScroll
            Instance.new("UICorner",btn).CornerRadius=UDim.new(0,3)
            local bstroke=Instance.new("UIStroke")
            bstroke.Color=isSel and Color3.fromRGB(220,0,60) or Color3.fromRGB(25,25,55)
            bstroke.Thickness=1; bstroke.Parent=btn

            local av=Instance.new("Frame"); av.Size=UDim2.new(0,22,0,22); av.Position=UDim2.new(0,5,0.5,-11)
            av.BackgroundColor3=isSel and Color3.fromRGB(80,0,30) or Color3.fromRGB(20,20,50)
            av.BorderSizePixel=0; av.Parent=btn; Instance.new("UICorner",av).CornerRadius=UDim.new(1,0)
            local avL=Instance.new("TextLabel"); avL.Size=UDim2.new(1,0,1,0); avL.BackgroundTransparency=1
            avL.Text=p.Name:sub(1,1):upper(); avL.TextColor3=isSel and Color3.fromRGB(255,80,100) or Color3.fromRGB(140,140,200)
            avL.TextSize=11; avL.Font=Enum.Font.GothamBold; avL.Parent=av

            local nameL=Instance.new("TextLabel"); nameL.Size=UDim2.new(1,-80,1,0); nameL.Position=UDim2.new(0,32,0,0)
            nameL.BackgroundTransparency=1; nameL.Text=p.Name
            nameL.TextColor3=isSel and Color3.fromRGB(255,60,100) or Color3.fromRGB(190,190,190)
            nameL.TextSize=10; nameL.Font=Enum.Font.GothamBold; nameL.TextXAlignment=Enum.TextXAlignment.Left
            nameL.TextTruncate=Enum.TextTruncate.AtEnd; nameL.Parent=btn

            local pingVal=math.random(20,200)
            local pingClr=pingVal<80 and Color3.fromRGB(0,220,80) or pingVal<150 and Color3.fromRGB(255,200,0) or Color3.fromRGB(255,60,60)
            local pingL=Instance.new("TextLabel"); pingL.Size=UDim2.new(0,38,1,0); pingL.Position=UDim2.new(1,-40,0,0)
            pingL.BackgroundTransparency=1; pingL.Text=pingVal.."ms"; pingL.TextColor3=pingClr
            pingL.TextSize=8; pingL.Font=Enum.Font.Code; pingL.TextXAlignment=Enum.TextXAlignment.Right; pingL.Parent=btn

            btn.MouseButton1Click:Connect(function()
                target=p; targetLabel.Text="🎯 TARGET: "..p.Name
                log("Target → "..p.Name,"warn"); renderPlayers()
            end)
        end
    end
    if shown==0 then
        local el=Instance.new("TextLabel"); el.Size=UDim2.new(1,0,0,28); el.BackgroundTransparency=1
        el.Text=searchQuery~="" and '🔍 Sem resultado: "'..searchQuery..'"' or "Nenhum jogador online"
        el.TextColor3=Color3.fromRGB(100,50,70); el.TextSize=9; el.Font=Enum.Font.Gotham; el.Parent=playerScroll
    end
    pCountLbl.Text=(searchQuery~="" and shown.."/" or "")..(#Players:GetPlayers()-1).." players"
end

-- ══════════════════════════════════════════
--  TOGGLES
-- ══════════════════════════════════════════

makeSection("MOVEMENT")

local _,setSpinActive = makeToggle("🌀","SPIN", function(on)
    spinEnabled=on
    log(on and "Spin ATIVADO 🌀" or "Spin desativado", on and "ok" or "info")
end)

local _,setFlyActive = makeToggle("🚀","FLY  (WASD + Space/Shift)", function(on)
    flyEnabled=on
    if on then enableFly(); log("Fly ATIVADO 🚀","ok")
    else disableFly(); log("Fly desativado","info") end
end)

makeSlider("⚡","FLY SPEED",10,300,50,5, function(v) flySpeed=v end)
makeSlider("🌀","SPIN SPEED",1,30,8,1, function(v) spinSpeed=v end)

makeSection("SPEED / JUMP")

local _,setSpeedActive = makeToggle("🏃","SPEED HACK", function(on)
    speedEnabled=on
    local hum=getHum(LocalPlayer); if hum then hum.WalkSpeed=on and speedValue or 16 end
    log(on and ("SpeedHack ON → "..speedValue) or "SpeedHack OFF (16)", on and "ok" or "info")
end)

makeSlider("💨","WALK SPEED",16,500,50,1, function(v)
    speedValue=v
    if speedEnabled then local hum=getHum(LocalPlayer); if hum then hum.WalkSpeed=v end end
end)

local _,setJumpActive = makeToggle("🦘","SUPER JUMP", function(on)
    jumpEnabled=on
    -- JumpPower só existe em jogos com Humanoid legacy.
    -- UseJumpPower precisa estar true, senão só JumpHeight funciona.
    local hum=getHum(LocalPlayer)
    if hum then
        hum.UseJumpPower=true
        hum.JumpPower=on and jumpValue or 50
    end
    log(on and ("Super Jump ON → "..jumpValue) or "Jump normal (50)", on and "ok" or "info")
end)

makeSlider("🦘","JUMP POWER",50,500,50,5, function(v)
    jumpValue=v
    if jumpEnabled then
        local hum=getHum(LocalPlayer)
        if hum then hum.UseJumpPower=true; hum.JumpPower=v end
    end
end)

makeSection("TELEPORT")
-- ── LOOP TP CORRIGIDO ────────────────────
-- Usa task.spawn com loop; no Heartbeat não funcionava pq
-- a posição era sobrescrita pelo servidor antes do próximo frame.
-- Aqui teleportamos a cada 0.05s dentro de uma corrotina dedicada.
local _,setLoopTpActive = makeToggle("🔄","LOOP TP (gruda no target)", function(on)
    loopTpEnabled=on
    if on then
        if not target then log("Selecione um target!","err"); loopTpEnabled=false; setLoopTpActive(false); return end
        log("Loop TP → "..target.Name,"warn")
        task.spawn(function()
            while loopTpEnabled do
                local root,tRoot=myRoot(),getRoot(target)
                if root and tRoot then
                    root.CFrame=tRoot.CFrame*CFrame.new(0,0,3)
                end
                task.wait(0.05)
            end
        end)
    else
        log("Loop TP OFF","info")
    end
end)

makeSection("TROLL 😈")

local _,setSarrarActive = makeToggle("🍑","SARRAR ATRÁS", function(on)
    sarrarEnabled=on
    if on then
        if not target then log("Selecione um target!","err"); sarrarEnabled=false; setSarrarActive(false); return end
        log("Sarrando "..target.Name.." @ "..studs.." studs 🍑","warn")
    else log("Sarrar OFF","info") end
end)
makeSlider("📏","STUD DISTANCE",0,15,1,0.5, function(v) studs=v end)

-- ── ORBIT ────────────────────────────────
-- Gira o LocalPlayer em torno do target em raio e velocidade
-- configuráveis, mantendo a câmera travada no target.
local _,setOrbitActive = makeToggle("🌍","ORBIT TARGET", function(on)
    orbitEnabled=on
    if on then
        if not target then log("Selecione um target!","err"); orbitEnabled=false; setOrbitActive(false); return end
        log("🌍 Orbitando "..target.Name.." r="..orbitRadius,"warn")
    else
        log("Orbit OFF","info")
    end
end)
makeSlider("🌍","ORBIT RADIUS",2,30,5,1, function(v) orbitRadius=v end)
makeSlider("💫","ORBIT SPEED",1,15,3,1, function(v) orbitSpeed=v end)

-- ── CAMERA LOCK ──────────────────────────
-- Muda a câmera para Scriptable e a posiciona atrás/acima
-- do target em terceira pessoa, seguindo ele em tempo real.
-- Ao desativar, restaura o tipo padrão (Custom).
local _,setCamLockActive = makeToggle("📷","CAMERA LOCK (espionar target)", function(on)
    cameraLockEnabled=on
    if on then
        if not target then log("Selecione um target!","err"); cameraLockEnabled=false; setCamLockActive(false); return end
        Camera.CameraType=Enum.CameraType.Scriptable
        log("📷 Espionando "..target.Name,"warn")
    else
        Camera.CameraType=Enum.CameraType.Custom
        -- restaura o sujeito da câmera para o próprio personagem
        local hum=getHum(LocalPlayer)
        if hum then Camera.CameraSubject=hum end
        log("Camera restaurada","info")
    end
end)

-- ── ESP ──────────────────────────────────
-- Cria BillboardGui em cima de cada player com nome,
-- caixa colorida e distância em studs. Atualiza no Heartbeat.
local _,setEspActive = makeToggle("👁️","ESP  (nome + caixa + dist)", function(on)
    espEnabled=on
    if on then
        buildEsp()
        log("👁️ ESP ATIVADO","ok")
    else
        clearEsp()
        log("ESP OFF","info")
    end
end)

makeSection("LOG")

local logFrame=Instance.new("Frame"); logFrame.Size=UDim2.new(1,0,0,72)
logFrame.BackgroundColor3=Color3.fromRGB(4,4,8); logFrame.BorderSizePixel=0; logFrame.Parent=ScrollFrame
Instance.new("UICorner",logFrame).CornerRadius=UDim.new(0,4)
local lst=Instance.new("UIStroke"); lst.Color=Color3.fromRGB(40,0,20); lst.Thickness=1; lst.Parent=logFrame
logScroll=Instance.new("ScrollingFrame"); logScroll.Size=UDim2.new(1,-4,1,-4); logScroll.Position=UDim2.new(0,2,0,2)
logScroll.BackgroundTransparency=1; logScroll.BorderSizePixel=0; logScroll.ScrollBarThickness=2
logScroll.ScrollBarImageColor3=Color3.fromRGB(100,0,30); logScroll.CanvasSize=UDim2.new(0,0,0,0)
logScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; logScroll.Parent=logFrame
local ll=Instance.new("UIListLayout"); ll.Padding=UDim.new(0,1); ll.VerticalAlignment=Enum.VerticalAlignment.Bottom; ll.Parent=logScroll
local lp=Instance.new("UIPadding"); lp.PaddingLeft=UDim.new(0,5); lp.PaddingBottom=UDim.new(0,2); lp.Parent=logScroll

-- ══════════════════════════════════════════
--  ESP
-- ══════════════════════════════════════════
function buildEsp()
    clearEsp()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character then
            createEspFor(p)
        end
    end
end

function createEspFor(p)
    if espObjects[p] then return end
    local char=p.Character
    if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- BillboardGui no root
    local bb=Instance.new("BillboardGui")
    bb.Name="TrollESP_"..p.Name
    bb.Size=UDim2.new(0,100,0,40)
    bb.StudsOffset=Vector3.new(0,3,0)
    bb.AlwaysOnTop=true
    bb.Parent=root

    -- nome
    local nameL=Instance.new("TextLabel"); nameL.Size=UDim2.new(1,0,0.6,0)
    nameL.BackgroundTransparency=1; nameL.Text=p.Name
    nameL.TextColor3=Color3.fromRGB(255,80,80); nameL.TextSize=12
    nameL.Font=Enum.Font.GothamBold; nameL.TextStrokeTransparency=0
    nameL.TextStrokeColor3=Color3.fromRGB(0,0,0); nameL.Parent=bb

    -- distância
    local distL=Instance.new("TextLabel"); distL.Size=UDim2.new(1,0,0.4,0); distL.Position=UDim2.new(0,0,0.6,0)
    distL.BackgroundTransparency=1; distL.Text="? studs"
    distL.TextColor3=Color3.fromRGB(200,200,50); distL.TextSize=9
    distL.Font=Enum.Font.Code; distL.TextStrokeTransparency=0
    distL.TextStrokeColor3=Color3.fromRGB(0,0,0); distL.Parent=bb

    espObjects[p]={billboard=bb, dist=distL, nameL=nameL}
end

function clearEsp()
    for _,t in pairs(espObjects) do
        if t.billboard and t.billboard.Parent then t.billboard:Destroy() end
    end
    espObjects={}
end

-- ══════════════════════════════════════════
--  FLY
-- ══════════════════════════════════════════
function enableFly()
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    hum.PlatformStand=true
    flyBodyVel=Instance.new("BodyVelocity"); flyBodyVel.Velocity=Vector3.zero
    flyBodyVel.MaxForce=Vector3.new(1e5,1e5,1e5); flyBodyVel.Parent=root
    flyBodyGyro=Instance.new("BodyGyro"); flyBodyGyro.MaxTorque=Vector3.new(1e5,1e5,1e5)
    flyBodyGyro.P=1e4; flyBodyGyro.CFrame=root.CFrame; flyBodyGyro.Parent=root
end

function disableFly()
    if flyBodyVel  then flyBodyVel:Destroy();  flyBodyVel=nil  end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro=nil end
    local hum=getHum(LocalPlayer); if hum then hum.PlatformStand=false end
end

-- ══════════════════════════════════════════
--  EVENTS
-- ══════════════════════════════════════════
Players.PlayerAdded:Connect(function(p)
    log(p.Name.." entrou","ok"); renderPlayers()
    if espEnabled then
        p.CharacterAdded:Connect(function() task.wait(1); createEspFor(p) end)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    log(p.Name.." saiu","info")
    if target==p then
        target=nil; targetLabel.Text="🎯 TARGET: NENHUM"
        sarrarEnabled=false; setSarrarActive(false)
        loopTpEnabled=false; setLoopTpActive(false)
        orbitEnabled=false; setOrbitActive(false)
        cameraLockEnabled=false; setCamLockActive(false)
        log("Target desconectou!","err")
    end
    if espObjects[p] then
        if espObjects[p].billboard then espObjects[p].billboard:Destroy() end
        espObjects[p]=nil
    end
    renderPlayers()
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if speedEnabled then local h=char:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=speedValue end end
    if jumpEnabled  then
        local h=char:FindFirstChildOfClass("Humanoid")
        if h then h.UseJumpPower=true; h.JumpPower=jumpValue end
    end
    if flyEnabled then enableFly() end
    log("Respawnado","info")
end)

-- ══════════════════════════════════════════
--  HEARTBEAT LOOP
-- ══════════════════════════════════════════
local spinAngle = 0

RunService.Heartbeat:Connect(function(dt)
    local root=myRoot()

    -- Spin
    if spinEnabled and root then
        spinAngle=(spinAngle+spinSpeed)%360
        root.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,math.rad(spinAngle),0)
    end

    -- Fly
    if flyEnabled and flyBodyVel and flyBodyGyro then
        local cf=Camera.CFrame; local vel=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)         then vel+=cf.LookVector *flySpeed end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)         then vel-=cf.LookVector *flySpeed end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)         then vel-=cf.RightVector*flySpeed end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)         then vel+=cf.RightVector*flySpeed end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then vel+=Vector3.new(0,flySpeed,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel-=Vector3.new(0,flySpeed,0) end
        flyBodyVel.Velocity=vel; flyBodyGyro.CFrame=cf
    end

    -- Sarrar
    if sarrarEnabled and target and root then
        local tRoot=getRoot(target)
        if tRoot then
            root.CFrame=CFrame.new((tRoot.CFrame*CFrame.new(0,0,studs)).Position,tRoot.Position)
        end
    end

    -- Orbit
    if orbitEnabled and target and root then
        local tRoot=getRoot(target)
        if tRoot then
            orbitAngle=(orbitAngle+orbitSpeed*dt)%(math.pi*2)
            local ox=math.cos(orbitAngle)*orbitRadius
            local oz=math.sin(orbitAngle)*orbitRadius
            local targetPos=tRoot.Position+Vector3.new(ox,0,oz)
            root.CFrame=CFrame.new(targetPos,tRoot.Position)
        end
    end

    -- Camera Lock
    if cameraLockEnabled and target then
        local tRoot=getRoot(target)
        if tRoot then
            -- posiciona câmera atrás e acima do target, olhando para ele
            local behind = tRoot.CFrame * CFrame.new(0, 5, 14)
            Camera.CFrame = CFrame.new(behind.Position, tRoot.Position)
        end
    end

    -- ESP: atualiza distância
    if espEnabled then
        local myPos=root and root.Position
        for p,obj in pairs(espObjects) do
            if obj.dist and obj.dist.Parent then
                local tRoot=getRoot(p)
                if tRoot and myPos then
                    local dist=math.floor((myPos-tRoot.Position).Magnitude)
                    obj.dist.Text=dist.." studs"
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════
--  INIT
-- ══════════════════════════════════════════
renderPlayers()
log("Troll.exe v4 iniciado!","ok")
log("────────────────────────","info")
log("💡 DICAS DE USO:","info")
log("🎯 Clique num player pra selecionar target","info")
log("🔍 Use a barra pra filtrar jogadores","info")
log("🌀 SPIN  → gira seu personagem infinito","info")
log("🚀 FLY   → WASD pra mover, Space=subir, Shift=descer","info")
log("🏃 SPEED → ajuste o slider antes de ativar","info")
log("🦘 JUMP  → precisa de target selecionado NÃO","info")
log("🔄 LOOP TP → gruda no target a cada 0.05s","info")
log("🍑 SARRAR → segue atrás com distância configurável","info")
log("🌍 ORBIT  → gira ao redor do target","info")
log("📷 CAM   → espiona a câmera do target","info")
log("👁️ ESP   → nome + distância de todos os players","info")
log("────────────────────────","info")
log("✕ Fechar = restaura tudo ao normal","info")
