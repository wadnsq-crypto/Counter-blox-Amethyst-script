-- ESP + Skeleton + Aimbot (Head/Torso) + Triggerbot (на Alt) + Fly (C) + NoClip + Меню с ползунком FOV (аметистовый фон)
-- Меню: перетаскивается за заголовок, Правый Ctrl – скрыть/показать
-- Ползунок FOV не двигает меню при перетаскивании

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")

-- ===== НАСТРОЙКИ =====
local ESP_ENABLED = true
local SKELETON_ENABLED = true
local AIMBOT_ENABLED = true
local TRIGGERBOT_ENABLED = false
local FLY_ENABLED = false
local FLY_KEY_HELD = false
local NOCLIP_ENABLED = true
local AIM_PART = "Head"
local FOV_RADIUS = 250
local AIM_SMOOTHNESS = 1
local SKELETON_HEAD_RADIUS = 8
local TRIGGERBOT_DELAY = 0.2
local FLY_SPEED = 50

-- ===== ЗАГРУЗКА DRAWING =====
if not Drawing then
    local urls = {
        "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
        "https://raw.githubusercontent.com/MarsQQ/ScriptHub/master/Drawing.lua"
    }
    for _, url in ipairs(urls) do
        pcall(function() loadstring(game:HttpGet(url))() end)
    end
    wait(0.5)
end
local DrawingAvailable = pcall(function() return Drawing.new end) and true or false
print("Drawing " .. (DrawingAvailable and "работает" or "НЕ загружен, используется запасной ESP"))

-- ===== МЕНЮ (аметистовый фон) =====
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "CheatMenu"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Enabled = true

local menuFrame = Instance.new("Frame", gui)
menuFrame.Size = UDim2.new(0, 300, 0, 420)
menuFrame.Position = UDim2.new(1, -310, 0.5, -210)
menuFrame.BackgroundColor3 = Color3.fromRGB(153, 102, 204)  -- аметистовый (фиолетовый)
menuFrame.BackgroundTransparency = 0.15
menuFrame.Active = true
menuFrame.Draggable = true
menuFrame.BorderSizePixel = 1
menuFrame.BorderColor3 = Color3.fromRGB(180, 130, 230)
menuFrame.ZIndex = 10
pcall(function()
    local corner = Instance.new("UICorner", menuFrame)
    corner.CornerRadius = UDim.new(0, 8)
end)

local title = Instance.new("TextLabel", menuFrame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(120, 70, 170)
title.Text = "Меню"
title.TextColor3 = Color3.fromRGB(255, 230, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.ZIndex = 11

local currentY = 35

local function makeButton(name, state, cb)
    local btn = Instance.new("TextButton", menuFrame)
    btn.Size = UDim2.new(1, -16, 0, 30)
    btn.Position = UDim2.new(0, 8, 0, currentY)
    btn.BackgroundColor3 = state and Color3.fromRGB(60, 140, 60) or Color3.fromRGB(140, 60, 60)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.Text = name..": "..(state and "ВКЛ" or "ВЫКЛ")
    btn.AutoButtonColor = false
    btn.ZIndex = 11
    pcall(function()
        local corner = Instance.new("UICorner", btn)
        corner.CornerRadius = UDim.new(0, 5)
    end)
    local active = state
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.BackgroundColor3 = active and Color3.fromRGB(60, 140, 60) or Color3.fromRGB(140, 60, 60)
        btn.Text = name..": "..(active and "ВКЛ" or "ВЫКЛ")
        cb(active)
    end)
    currentY = currentY + 34
    return btn
end

makeButton("ESP", ESP_ENABLED, function(v) ESP_ENABLED = v end)
makeButton("Skeleton", SKELETON_ENABLED, function(v) SKELETON_ENABLED = v end)
makeButton("Aimbot", AIMBOT_ENABLED, function(v) AIMBOT_ENABLED = v end)

-- FOV ползунок + ввод
local fovLabel = Instance.new("TextLabel", menuFrame)
fovLabel.Size = UDim2.new(0, 40, 0, 20)
fovLabel.Position = UDim2.new(0, 12, 0, currentY + 4)
fovLabel.BackgroundTransparency = 1
fovLabel.Text = "FOV:"
fovLabel.TextColor3 = Color3.new(1,1,1)
fovLabel.Font = Enum.Font.SourceSans
fovLabel.TextSize = 13
fovLabel.ZIndex = 11

local fovSlider = Instance.new("Frame", menuFrame)
fovSlider.Size = UDim2.new(0, 140, 0, 20)
fovSlider.Position = UDim2.new(0, 55, 0, currentY + 4)
fovSlider.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
fovSlider.BorderSizePixel = 0
fovSlider.ZIndex = 11
pcall(function()
    local corner = Instance.new("UICorner", fovSlider)
    corner.CornerRadius = UDim.new(0, 4)
end)

local fovFill = Instance.new("Frame", fovSlider)
fovFill.Size = UDim2.new((FOV_RADIUS - 50) / 450, 0, 1, 0)
fovFill.Position = UDim2.new(0, 0, 0, 0)
fovFill.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
fovFill.BorderSizePixel = 0
fovFill.ZIndex = 12
pcall(function()
    local corner = Instance.new("UICorner", fovFill)
    corner.CornerRadius = UDim.new(0, 4)
end)

local fovInput = Instance.new("TextBox", menuFrame)
fovInput.Size = UDim2.new(0, 60, 0, 24)
fovInput.Position = UDim2.new(0, 210, 0, currentY + 2)
fovInput.BackgroundColor3 = Color3.fromRGB(120, 80, 160)
fovInput.TextColor3 = Color3.new(1,1,1)
fovInput.Font = Enum.Font.SourceSans
fovInput.TextSize = 13
fovInput.Text = tostring(FOV_RADIUS)
fovInput.ZIndex = 11
fovInput.PlaceholderText = "50-500"
pcall(function()
    local corner = Instance.new("UICorner", fovInput)
    corner.CornerRadius = UDim.new(0, 4)
end)

local function updateFOV(newValue)
    FOV_RADIUS = math.clamp(newValue, 50, 500)
    fovFill.Size = UDim2.new((FOV_RADIUS - 50) / 450, 0, 1, 0)
    fovInput.Text = tostring(FOV_RADIUS)
end

-- Перетаскивание ползунка без смещения меню
local draggingSlider = false
fovSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
        menuFrame.Draggable = false
        local mousePos = UserInputService:GetMouseLocation()
        local sliderAbsPos = fovSlider.AbsolutePosition
        local sliderWidth = fovSlider.AbsoluteSize.X
        local relativeX = math.clamp(mousePos.X - sliderAbsPos.X, 0, sliderWidth)
        local percent = relativeX / sliderWidth
        updateFOV(math.floor(50 + percent * 450))
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        local mousePos = UserInputService:GetMouseLocation()
        local sliderAbsPos = fovSlider.AbsolutePosition
        local sliderWidth = fovSlider.AbsoluteSize.X
        local relativeX = math.clamp(mousePos.X - sliderAbsPos.X, 0, sliderWidth)
        local percent = relativeX / sliderWidth
        updateFOV(math.floor(50 + percent * 450))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and draggingSlider then
        draggingSlider = false
        menuFrame.Draggable = true
    end
end)

fovInput.FocusLost:Connect(function()
    local num = tonumber(fovInput.Text)
    if num then
        updateFOV(num)
    else
        fovInput.Text = tostring(FOV_RADIUS)
    end
end)

currentY = currentY + 28

makeButton("Triggerbot", TRIGGERBOT_ENABLED, function(v) TRIGGERBOT_ENABLED = v end)
makeButton("Fly", FLY_ENABLED, function(v) FLY_ENABLED = v end)
makeButton("NoClip", NOCLIP_ENABLED, function(v) NOCLIP_ENABLED = v end)

-- Кнопка переключения точки аима
local aimPartBtn = Instance.new("TextButton", menuFrame)
aimPartBtn.Size = UDim2.new(1, -16, 0, 30)
aimPartBtn.Position = UDim2.new(0, 8, 0, currentY)
aimPartBtn.BackgroundColor3 = Color3.fromRGB(120, 100, 180)
aimPartBtn.TextColor3 = Color3.new(1,1,1)
aimPartBtn.Font = Enum.Font.SourceSansBold
aimPartBtn.TextSize = 13
aimPartBtn.Text = "Aim Part: Head"
aimPartBtn.AutoButtonColor = false
aimPartBtn.ZIndex = 11
pcall(function()
    local corner = Instance.new("UICorner", aimPartBtn)
    corner.CornerRadius = UDim.new(0, 5)
end)
aimPartBtn.MouseButton1Click:Connect(function()
    if AIM_PART == "Head" then
        AIM_PART = "Torso"
        aimPartBtn.Text = "Aim Part: Torso"
    else
        AIM_PART = "Head"
        aimPartBtn.Text = "Aim Part: Head"
    end
end)
currentY = currentY + 34

local hint = Instance.new("TextLabel", menuFrame)
hint.Size = UDim2.new(1, -16, 0, 80)
hint.Position = UDim2.new(0, 8, 0, currentY + 5)
hint.BackgroundTransparency = 1
hint.TextColor3 = Color3.fromRGB(255, 230, 255)
hint.Font = Enum.Font.SourceSans
hint.TextSize = 11
hint.Text = "Правый Ctrl – скрыть/показать меню\nFly: удерживать C (BodyVelocity)\nAimbot: Alt | Trigger: на Alt\nNoClip: сквозь стены"
hint.ZIndex = 11
hint.TextWrapped = true

menuFrame.Size = UDim2.new(0, 300, 0, currentY + 85)

-- Управление меню и клавишами
local menuVisible = true
UserInputService.InputBegan:Connect(function(input, _)
    if input.KeyCode == Enum.KeyCode.RightControl then
        menuVisible = not menuVisible
        menuFrame.Visible = menuVisible
    end
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        _AIM = true
    end
    if input.KeyCode == Enum.KeyCode.C then
        FLY_KEY_HELD = true
    end
end)
UserInputService.InputEnded:Connect(function(input, _)
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        _AIM = false
    end
    if input.KeyCode == Enum.KeyCode.C then
        FLY_KEY_HELD = false
    end
end)

-- ===== ВСПОМОГАТЕЛЬНЫЕ =====
local function isEnemy(p)
    if not LocalPlayer.Team then return true end
    if not p.Team then return true end
    return p.Team ~= LocalPlayer.Team
end

local function visible(player)
    local head = player.Character and player.Character:FindFirstChild("Head")
    if not head then return false end
    local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 500)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    return hit and hit:IsDescendantOf(player.Character)
end

-- ===== FOV-КРУГ =====
local fovCircle
if DrawingAvailable then
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = true
    fovCircle.Thickness = 2
    fovCircle.Color = Color3.fromRGB(255,255,255)
    fovCircle.Radius = FOV_RADIUS
    fovCircle.Filled = false
    fovCircle.Position = Camera.ViewportSize / 2
end

-- ===== DRAWING ESP =====
local pDrawings = {}
local skLines = {}
local skHeads = {}

local function newDrawing(class, props)
    if not DrawingAvailable then return nil end
    local d = Drawing.new(class)
    for k,v in pairs(props) do d[k]=v end
    return d
end

local function removeAllDrawings(player)
    if pDrawings[player] then
        for _, d in pairs(pDrawings[player]) do pcall(function() d:Remove() end) end
        pDrawings[player] = nil
    end
    if skLines[player] then
        for _, l in ipairs(skLines[player]) do pcall(function() l:Remove() end) end
        skLines[player] = nil
    end
    if skHeads[player] then
        pcall(function() skHeads[player]:Remove() end)
        skHeads[player] = nil
    end
end
Players.PlayerRemoving:Connect(removeAllDrawings)

local function hideAllDrawings(player)
    if pDrawings[player] then for _, d in pairs(pDrawings[player]) do d.Visible = false end end
    if skLines[player] then for _, l in ipairs(skLines[player]) do l.Visible = false end end
    if skHeads[player] then skHeads[player].Visible = false end
end

local function removeSkeleton(player)
    if skLines[player] then
        for _, l in ipairs(skLines[player]) do l.Visible = false; pcall(function() l:Remove() end) end
        skLines[player] = nil
    end
    if skHeads[player] then
        skHeads[player].Visible = false
        pcall(function() skHeads[player]:Remove() end)
        skHeads[player] = nil
    end
end

local function getHealth(player)
    local char = player.Character
    if not char then return nil, nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then return humanoid.Health, humanoid.MaxHealth end
    for _, child in ipairs(char:GetChildren()) do
        if (child:IsA("NumberValue") or child:IsA("IntValue")) and child.Name:lower() == "health" then
            local health = child.Value
            local maxHealth = 100
            local maxHealthObj = char:FindFirstChild("MaxHealth") or char:FindFirstChild("maxHealth")
            if maxHealthObj and (maxHealthObj:IsA("NumberValue") or maxHealthObj:IsA("IntValue")) then
                maxHealth = maxHealthObj.Value
            end
            return health, maxHealth
        end
    end
    local stats = char:FindFirstChild("Stats") or char:FindFirstChild("stats")
    if stats then
        for _, child in ipairs(stats:GetChildren()) do
            if (child:IsA("NumberValue") or child:IsA("IntValue")) and child.Name:lower() == "health" then
                local health = child.Value
                local maxHealth = 100
                local maxHealthObj = stats:FindFirstChild("MaxHealth") or stats:FindFirstChild("maxHealth")
                if maxHealthObj and (maxHealthObj:IsA("NumberValue") or maxHealthObj:IsA("IntValue")) then
                    maxHealth = maxHealthObj.Value
                end
                return health, maxHealth
            end
        end
    end
    return nil, nil
end

local function updateDrawingESP()
    if not DrawingAvailable or not ESP_ENABLED then
        for _, p in ipairs(Players:GetPlayers()) do
            hideAllDrawings(p)
            if not SKELETON_ENABLED then removeSkeleton(p) end
        end
        return
    end

    local cp = Camera.CFrame.Position
    local sz = Camera.ViewportSize
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not isEnemy(p) then
            hideAllDrawings(p)
            removeSkeleton(p)
            continue
        end
        local char = p.Character
        if not char then
            hideAllDrawings(p)
            removeSkeleton(p)
            continue
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not hrp or not head then
            hideAllDrawings(p)
            removeSkeleton(p)
            continue
        end
        local hp, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then
            hideAllDrawings(p)
            removeSkeleton(p)
            continue
        end

        if not pDrawings[p] then
            pDrawings[p] = {
                tracer = newDrawing("Line", {Color=Color3.fromRGB(255,0,0), Thickness=1}),
                box = newDrawing("Square", {Color=Color3.fromRGB(255,0,0), Thickness=2, Filled=false}),
                nameTag = newDrawing("Text", {Color=Color3.fromRGB(255,255,255), Size=13, Center=true, Outline=true}),
                hpBg = newDrawing("Square", {Color=Color3.fromRGB(50,50,50), Thickness=1, Filled=true}),
                hpBar = newDrawing("Square", {Color=Color3.fromRGB(0,255,0), Thickness=1, Filled=true})
            }
        end

        local dw = pDrawings[p]
        local rootVP = Camera:WorldToViewportPoint(hrp.Position)
        local footVP = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))
        local dist = (cp - hrp.Position).Magnitude

        dw.tracer.From = Vector2.new(sz.X/2, sz.Y)
        dw.tracer.To = Vector2.new(rootVP.X, rootVP.Y)
        dw.tracer.Visible = true

        local boxH = math.abs(hp.Y - footVP.Y)
        local boxW = boxH * 0.5
        dw.box.Size = Vector2.new(boxW, boxH)
        dw.box.Position = Vector2.new(rootVP.X - boxW/2, hp.Y)
        dw.box.Visible = true

        dw.nameTag.Text = p.Name.." ["..math.floor(dist).."m]"
        dw.nameTag.Position = Vector2.new(rootVP.X, hp.Y - 15)
        dw.nameTag.Visible = true

        local health, maxHealth = getHealth(p)
        if health and maxHealth then
            local barWidth = boxW
            local barHeight = 3
            local hpPercent = math.clamp(health / maxHealth, 0, 1)
            dw.hpBg.Size = Vector2.new(barWidth, barHeight)
            dw.hpBg.Position = Vector2.new(rootVP.X - barWidth/2, hp.Y + boxH + 1)
            dw.hpBg.Visible = true
            dw.hpBar.Size = Vector2.new(barWidth * hpPercent, barHeight)
            dw.hpBar.Position = dw.hpBg.Position
            dw.hpBar.Visible = true
        else
            dw.hpBg.Visible = false
            dw.hpBar.Visible = false
        end

        if SKELETON_ENABLED then
            local parts = {}
            for _,n in ipairs({"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}) do
                parts[n] = char:FindFirstChild(n)
            end
            if not skLines[p] then
                skLines[p] = {}
                for i=1,14 do
                    skLines[p][i] = newDrawing("Line", {Color=Color3.fromRGB(255,255,255), Thickness=1})
                end
            end
            if not skHeads[p] then
                skHeads[p] = newDrawing("Circle", {Color=Color3.fromRGB(255,255,255), Thickness=1.5, Filled=false, Radius=SKELETON_HEAD_RADIUS})
            end
            local connections = {
                {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},
                {"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},
                {"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},
                {"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},
                {"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}
            }
            for i,conn in ipairs(connections) do
                local a,b = parts[conn[1]], parts[conn[2]]
                local line = skLines[p][i]
                if a and b then
                    local pa,sa = Camera:WorldToViewportPoint(a.Position)
                    local pb,sb = Camera:WorldToViewportPoint(b.Position)
                    if sa and sb then
                        line.From = Vector2.new(pa.X, pa.Y)
                        line.To = Vector2.new(pb.X, pb.Y)
                        line.Visible = true
                    else line.Visible = false end
                else line.Visible = false end
            end
            if parts["Head"] then
                local hp2, onS = Camera:WorldToViewportPoint(parts["Head"].Position)
                if onS then
                    skHeads[p].Position = Vector2.new(hp2.X, hp2.Y)
                    skHeads[p].Visible = true
                else skHeads[p].Visible = false end
            else skHeads[p].Visible = false end
        else
            removeSkeleton(p)
        end
    end
end

-- ===== ЗАПАСНОЙ ESP =====
local billboards = {}
local function createFallbackESP(player)
    if not isEnemy(player) then return end
    local function setup()
        local char = player.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        if head:FindFirstChild("FallbackESP") then return end

        local bb = Instance.new("BillboardGui")
        bb.Name = "FallbackESP"
        bb.Adornee = head
        bb.Size = UDim2.new(0,200,0,50)
        bb.StudsOffset = Vector3.new(0,2.5,0)
        bb.AlwaysOnTop = true
        bb.Enabled = false
        bb.Parent = head

        local label = Instance.new("TextLabel", bb)
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1,0,0)
        label.TextStrokeTransparency = 0
        label.TextScaled = true
        label.Text = ""

        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not ESP_ENABLED or not player.Character or not player.Character:FindFirstChild("Head") then
                if conn then conn:Disconnect() end
                if bb and bb.Parent then bb:Destroy() end
                billboards[player] = nil
                return
            end
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and Camera then
                local dist = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
                local healthText = ""
                local health, maxHealth = getHealth(player)
                if health and maxHealth then
                    local hpPercent = math.floor(health / maxHealth * 100)
                    healthText = " [" .. hpPercent .. "%]"
                end
                label.Text = player.Name.." ["..dist.."m]"..healthText
                local headPos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
                bb.Enabled = onScreen
            end
        end)
        billboards[player] = bb
    end

    if player.Character then setup() end
    player.CharacterAdded:Connect(function() wait(0.3) setup() end)
end

if not DrawingAvailable then
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then createFallbackESP(p) end
    end
    Players.PlayerAdded:Connect(function(p)
        if p ~= LocalPlayer then createFallbackESP(p) end
    end)
end

-- ===== AIMBOT =====
local function closestInFOV()
    local mp = UserInputService:GetMouseLocation()
    local best, bestD = nil, FOV_RADIUS
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LocalPlayer or not isEnemy(p) then continue end
        local char = p.Character
        if not char then continue end
        local targetPart = nil
        if AIM_PART == "Head" then
            targetPart = char:FindFirstChild("Head")
        else
            targetPart = char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
        end
        if not targetPart then continue end
        local hp, onS = Camera:WorldToViewportPoint(targetPart.Position)
        if not onS then continue end
        local d = (Vector2.new(hp.X,hp.Y)-mp).Magnitude
        if d<bestD then best=p; bestD=d end
    end
    return best
end

local function aimAt(p)
    if not p or not p.Character then return end
    local char = p.Character
    local targetPart = nil
    if AIM_PART == "Head" then
        targetPart = char:FindFirstChild("Head")
    else
        targetPart = char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    end
    if not targetPart then return end
    local cf = CFrame.new(Camera.CFrame.Position, targetPart.Position)
    if AIM_SMOOTHNESS>=1 then Camera.CFrame=cf
    else Camera.CFrame = Camera.CFrame:Lerp(cf, AIM_SMOOTHNESS) end
end

-- ===== TRIGGERBOT =====
local lastShot = 0
local mousePressed = false
local function triggerbot()
    if not TRIGGERBOT_ENABLED or not _AIM then
        if mousePressed then
            VIM:SendMouseButtonEvent(0,0,0,false,game,false)
            mousePressed = false
        end
        return
    end

    local target = nil
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LocalPlayer or not isEnemy(p) then continue end
        local head = p.Character and p.Character:FindFirstChild("Head")
        if not head then continue end
        local hp, onS = Camera:WorldToViewportPoint(head.Position)
        if not onS then continue end
        local sc = Camera.ViewportSize/2
        if (Vector2.new(hp.X,hp.Y)-sc).Magnitude < FOV_RADIUS and visible(p) then
            target = p
            break
        end
    end

    if not target then
        if mousePressed then
            VIM:SendMouseButtonEvent(0,0,0,false,game,false)
            mousePressed = false
        end
        return
    end

    if tick()-lastShot < TRIGGERBOT_DELAY then return end

    VIM:SendMouseButtonEvent(0,0,0,true,game,false)
    mousePressed = true
    lastShot = tick()
    task.delay(0.05, function()
        if mousePressed then
            VIM:SendMouseButtonEvent(0,0,0,false,game,false)
            mousePressed = false
        end
    end)
end

-- ===== FLY =====
local flyBody = nil
local function updateFly()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        if flyBody then flyBody:Destroy(); flyBody = nil end
        return
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char.HumanoidRootPart
    if not humanoid then return end

    local active = FLY_ENABLED or FLY_KEY_HELD
    if active then
        humanoid.PlatformStand = true
        if not flyBody or flyBody.Parent ~= hrp then
            if flyBody then flyBody:Destroy() end
            flyBody = Instance.new("BodyVelocity", hrp)
            flyBody.MaxForce = Vector3.new(40000,40000,40000)
            flyBody.P = 1000
        end
        local moveDir = Vector3.zero
        local camCF = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0,1,0) end
        flyBody.Velocity = moveDir.Magnitude > 0 and moveDir.Unit * FLY_SPEED or Vector3.zero
    else
        humanoid.PlatformStand = false
        if flyBody then flyBody:Destroy(); flyBody = nil end
    end
end

-- ===== NOCLIP =====
local function updateNoClip()
    if not LocalPlayer.Character then return end
    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = not NOCLIP_ENABLED end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if NOCLIP_ENABLED then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- ===== ГЛАВНЫЙ ЦИКЛ =====
RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = Camera.ViewportSize/2
        fovCircle.Radius = FOV_RADIUS
        fovCircle.Visible = AIMBOT_ENABLED
    end
    if DrawingAvailable then updateDrawingESP() end
    if _AIM and AIMBOT_ENABLED then
        local t = closestInFOV()
        if t then aimAt(t) end
    end
    triggerbot()
    updateFly()
    updateNoClip()
end)

print("Меню с аметистовым фоном готово. Правый Ctrl – свернуть/развернуть.")
