-- ESP + Skeleton + Aimbot + Triggerbot + Fly (удержание Левого Ctrl) + NoClip (вкл) + Перетаскиваемое меню с серым фоном
-- Меню: перетаскивается за заголовок, Правый Ctrl – скрыть/показать
-- Aimbot: Левый Alt | Fly: удерживать Левый Ctrl или включить в меню навсегда

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
local FLY_ENABLED = false          -- постоянное вкл через меню
local FLY_KEY_HELD = false        -- удержание Левого Ctrl
local NOCLIP_ENABLED = true
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

-- ===== МЕНЮ (перетаскиваемое, с серым фоном) =====
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "CheatMenu"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Enabled = true

-- Основной фрейм меню
local menuFrame = Instance.new("Frame", gui)
menuFrame.Size = UDim2.new(0, 190, 0, 300)  -- ширина и высота (под кнопки)
menuFrame.Position = UDim2.new(1, -200, 0.5, -150)  -- справа по центру
menuFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)  -- серый фон
menuFrame.BackgroundTransparency = 0.3  -- полупрозрачность
menuFrame.Active = true
menuFrame.Draggable = true  -- можно перетаскивать
menuFrame.BorderSizePixel = 0
menuFrame.ZIndex = 10

-- Заголовок (для красоты и индикации перетаскивания)
local title = Instance.new("TextLabel", menuFrame)
title.Size = UDim2.new(1, 0, 0, 25)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.Text = "Меню (перетащи)"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.ZIndex = 11

-- Кнопки будем создавать внутри menuFrame с отступом от заголовка
local buttonStartY = 30
local currentY = buttonStartY

local function makeButton(name, state, cb)
    local btn = Instance.new("TextButton", menuFrame)
    btn.Size = UDim2.new(1, -10, 0, 28)
    btn.Position = UDim2.new(0, 5, 0, currentY)
    btn.BackgroundColor3 = state and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.Text = name..": "..(state and "ВКЛ" or "ВЫКЛ")
    btn.AutoButtonColor = false
    btn.ZIndex = 11
    local active = state
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.BackgroundColor3 = active and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
        btn.Text = name..": "..(active and "ВКЛ" or "ВЫКЛ")
        cb(active)
    end)
    currentY = currentY + 32
    return btn
end

makeButton("ESP", ESP_ENABLED, function(v) ESP_ENABLED = v end)
makeButton("Skeleton", SKELETON_ENABLED, function(v) SKELETON_ENABLED = v end)
makeButton("Aimbot", AIMBOT_ENABLED, function(v) AIMBOT_ENABLED = v end)
makeButton("Triggerbot", TRIGGERBOT_ENABLED, function(v) TRIGGERBOT_ENABLED = v end)
makeButton("Fly", FLY_ENABLED, function(v) FLY_ENABLED = v end)
makeButton("NoClip", NOCLIP_ENABLED, function(v) NOCLIP_ENABLED = v end)

-- Подсказка внизу меню
local hint = Instance.new("TextLabel", menuFrame)
hint.Size = UDim2.new(1, -10, 0, 50)
hint.Position = UDim2.new(0, 5, 0, currentY + 5)
hint.BackgroundTransparency = 1
hint.TextColor3 = Color3.new(1,1,1)
hint.Font = Enum.Font.SourceSans
hint.TextSize = 11
hint.Text = "Fly: удерживать Левый Ctrl\nAimbot: Alt | Trigger: задержка "..(TRIGGERBOT_DELAY*1000).." мс\nNoClip: сквозь стены"
hint.ZIndex = 11
hint.TextWrapped = true

-- Обновим размер фрейма под содержимое
menuFrame.Size = UDim2.new(0, 190, 0, currentY + 60)

-- Управление видимостью меню (Правый Ctrl)
local menuVisible = true
UserInputService.InputBegan:Connect(function(input, _)
    if input.KeyCode == Enum.KeyCode.RightControl then
        menuVisible = not menuVisible
        menuFrame.Visible = menuVisible
    end
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        _AIM = true
    end
    -- Fly по удержанию левого Ctrl
    if input.KeyCode == Enum.KeyCode.LeftControl then
        FLY_KEY_HELD = true
    end
end)
UserInputService.InputEnded:Connect(function(input, _)
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        _AIM = false
    end
    if input.KeyCode == Enum.KeyCode.LeftControl then
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
        local humanoid = char:FindFirstChildOfClass("Humanoid")
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

        if humanoid then
            local maxHealth = humanoid.MaxHealth
            local health = humanoid.Health
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

        -- Скелет
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

-- ===== ЗАПАСНОЙ ESP (BillboardGui) =====
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
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if hrp and Camera then
                local dist = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
                local hpText = ""
                if humanoid then
                    hpText = string.format(" [%d%%]", math.floor(humanoid.Health / humanoid.MaxHealth * 100))
                end
                label.Text = player.Name.." ["..dist.."m]"..hpText
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
        local head = p.Character and p.Character:FindFirstChild("Head")
        if not head then continue end
        local hp, onS = Camera:WorldToViewportPoint(head.Position)
        if not onS then continue end
        local d = (Vector2.new(hp.X,hp.Y)-mp).Magnitude
        if d<bestD then best=p; bestD=d end
    end
    return best
end
local function aimAt(p)
    local head = p and p.Character and p.Character:FindFirstChild("Head")
    if not head then return end
    local cf = CFrame.new(Camera.CFrame.Position, head.Position)
    if AIM_SMOOTHNESS>=1 then Camera.CFrame=cf
    else Camera.CFrame = Camera.CFrame:Lerp(cf, AIM_SMOOTHNESS) end
end

-- ===== TRIGGERBOT =====
local lastShot = 0
local sightStart = nil
local mousePressed = false
local lastTarget = nil
local function triggerbot()
    if not TRIGGERBOT_ENABLED then
        if mousePressed then
            VIM:SendMouseButtonEvent(0,0,0,false,game,false)
            mousePressed = false
        end
        sightStart = nil; lastTarget = nil
        return
    end
    local target = nil
    local sc = Camera.ViewportSize/2
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LocalPlayer or not isEnemy(p) then continue end
        local head = p.Character and p.Character:FindFirstChild("Head")
        if not head then continue end
        local hp, onS = Camera:WorldToViewportPoint(head.Position)
        if not onS then continue end
        if (Vector2.new(hp.X,hp.Y)-sc).Magnitude < FOV_RADIUS and visible(p) then
            target = p
            break
        end
    end
    if not target then
        if mousePressed then VIM:SendMouseButtonEvent(0,0,0,false,game,false); mousePressed = false end
        sightStart = nil; lastTarget = nil
        return
    end
    if target ~= lastTarget then
        sightStart = tick(); lastTarget = target
        if mousePressed then VIM:SendMouseButtonEvent(0,0,0,false,game,false); mousePressed = false end
    end
    if sightStart and tick()-sightStart < TRIGGERBOT_DELAY then return end
    if tick()-lastShot < TRIGGERBOT_DELAY then return end
    VIM:SendMouseButtonEvent(0,0,0,true,game,false)
    mousePressed = true
    lastShot = tick()
    task.delay(0.05, function()
        if mousePressed then VIM:SendMouseButtonEvent(0,0,0,false,game,false); mousePressed = false end
    end)
end

-- ===== FLY (удержание Левого Ctrl или постоянное вкл в меню) =====
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
        if flyBody then
            flyBody.Velocity = Vector3.zero
            flyBody:Destroy()
            flyBody = nil
        end
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
    if FLY_ENABLED then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = true end
    end
end)

-- ===== ГЛАВНЫЙ ЦИКЛ =====
RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = Camera.ViewportSize/2
        fovCircle.Radius = FOV_RADIUS
        fovCircle.Visible = AIMBOT_ENABLED
    end
    if DrawingAvailable then
        updateDrawingESP()
    end
    if _AIM and AIMBOT_ENABLED then
        local t = closestInFOV()
        if t then aimAt(t) end
    end
    triggerbot()
    updateFly()
    updateNoClip()
end)

print("Меню теперь с серым фоном и перетаскивается. Fly на Левом Ctrl.")