-- ESP + Aimbot + Skeleton + Triggerbot + Fly + NoClip (отдельно) + Меню
-- Управление: Правый Ctrl (меню), Левый Alt (Aimbot), Fly: WASD/Space/Shift, NoClip: проходить сквозь стены

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local VIM = game:GetService("VirtualInputManager")

-- ===== НАСТРОЙКИ =====
local ESP_ENABLED = true
local AIMBOT_ENABLED = true
local SKELETON_ENABLED = true
local TRIGGERBOT_ENABLED = false
local FLY_ENABLED = false
local NOCLIP_ENABLED = false
local FOV_RADIUS = 250
local AIM_SMOOTHNESS = 1
local SKELETON_HEAD_RADIUS = 8
local TRIGGERBOT_DELAY = 0.2
local FLY_SPEED = 50
local _AIM = false -- зажата ли клавиша Aimbot

-- ===== ПРОВЕРКА БИБЛИОТЕКИ DRAWING =====
if not Drawing then
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)
    task.wait(0.5)
end
local DrawingAvailable = pcall(function() return Drawing.new end) and true or false

-- ===== МЕНЮ =====
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "CheatMenu"
gui.Enabled = true

local function makeButton(name, y, state, callback)
    local btn = Instance.new("TextButton", gui)
    btn.Size = UDim2.new(0, 180, 0, 30)
    btn.Position = UDim2.new(1, -190, 0, y)
    btn.BackgroundColor3 = state and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Text = name .. ": " .. (state and "ВКЛ" or "ВЫКЛ")
    btn.AutoButtonColor = false
    local active = state
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.BackgroundColor3 = active and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
        btn.Text = name .. ": " .. (active and "ВКЛ" or "ВЫКЛ")
        callback(active)
    end)
    return btn
end

local yPos = 10
makeButton("ESP", yPos, ESP_ENABLED, function(v) ESP_ENABLED = v end)
yPos += 35; makeButton("Skeleton", yPos, SKELETON_ENABLED, function(v) SKELETON_ENABLED = v end)
yPos += 35; makeButton("Aimbot", yPos, AIMBOT_ENABLED, function(v) AIMBOT_ENABLED = v end)
yPos += 35; makeButton("Triggerbot", yPos, TRIGGERBOT_ENABLED, function(v) TRIGGERBOT_ENABLED = v end)
yPos += 35; makeButton("Fly", yPos, FLY_ENABLED, function(v) FLY_ENABLED = v end)
yPos += 35; makeButton("NoClip", yPos, NOCLIP_ENABLED, function(v) NOCLIP_ENABLED = v end)
yPos += 40

local hint = Instance.new("TextLabel", gui)
hint.Size = UDim2.new(0, 180, 0, 80)
hint.Position = UDim2.new(1, -190, 0, yPos)
hint.BackgroundTransparency = 1
hint.TextColor3 = Color3.new(1,1,1)
hint.Font = Enum.Font.SourceSans
hint.TextSize = 12
hint.Text = "Aimbot: Alt | Trigger: задержка " .. (TRIGGERBOT_DELAY * 1000) .. " мс\nFly: " .. FLY_SPEED .. " (WASD/Space/Shift)\nNoClip: проходить сквозь стены\nМеню: Правый Ctrl"
hint.TextWrapped = true

local menuVisible = true
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        menuVisible = not menuVisible
        gui.Enabled = menuVisible
    elseif input.KeyCode == Enum.KeyCode.LeftAlt then
        _AIM = true
    end
end)
UserInputService.InputEnded:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        _AIM = false
    end
end)

-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====
local function isEnemy(player)
    if not LocalPlayer.Team then return true end
    if not player.Team then return true end
    return player.Team ~= LocalPlayer.Team
end

local function isVisible(head)
    local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 500)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    return hit and hit:IsDescendantOf(head.Parent)
end

-- ===== FOV КРУГ =====
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

-- ===== ХРАНИЛИЩА РИСУНКОВ =====
local playerDrawings = {}   -- [player] = {tracer, box, tag}
local playerSkeleton = {}    -- [player] = {lines, head}
local connections = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},
    {"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},
    {"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}
}

local function removeDrawings(player)
    local dw = playerDrawings[player]
    if dw then
        for _, d in pairs(dw) do pcall(d.Remove, d) end
        playerDrawings[player] = nil
    end
    local sk = playerSkeleton[player]
    if sk then
        for _, l in ipairs(sk.lines) do pcall(l.Remove, l) end
        if sk.head then pcall(sk.head.Remove, sk.head) end
        playerSkeleton[player] = nil
    end
end

Players.PlayerRemoving:Connect(removeDrawings)

-- ===== ESP И СКЕЛЕТ =====
local function updateESP()
    if not DrawingAvailable or not ESP_ENABLED then
        for _, plr in ipairs(Players:GetPlayers()) do
            if playerDrawings[plr] then
                for _, d in pairs(playerDrawings[plr]) do d.Visible = false end
            end
            if playerSkeleton[plr] then
                for _, l in ipairs(playerSkeleton[plr].lines) do l.Visible = false end
                if playerSkeleton[plr].head then playerSkeleton[plr].head.Visible = false end
            end
        end
        return
    end

    local camPos = Camera.CFrame.Position
    local viewSize = Camera.ViewportSize
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not isEnemy(player) then
            if playerDrawings[player] then
                for _, d in pairs(playerDrawings[player]) do d.Visible = false end
            end
            if playerSkeleton[player] then
                for _, l in ipairs(playerSkeleton[player].lines) do l.Visible = false end
                if playerSkeleton[player].head then playerSkeleton[player].head.Visible = false end
            end
            continue
        end

        local char = player.Character
        if not char then
            if playerDrawings[player] then
                for _, d in pairs(playerDrawings[player]) do d.Visible = false end
            end
            if playerSkeleton[player] then
                for _, l in ipairs(playerSkeleton[player].lines) do l.Visible = false end
                if playerSkeleton[player].head then playerSkeleton[player].head.Visible = false end
            end
            continue
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not hrp or not head then
            if playerDrawings[player] then
                for _, d in pairs(playerDrawings[player]) do d.Visible = false end
            end
            if playerSkeleton[player] then
                for _, l in ipairs(playerSkeleton[player].lines) do l.Visible = false end
                if playerSkeleton[player].head then playerSkeleton[player].head.Visible = false end
            end
            continue
        end

        local headScreenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then
            if playerDrawings[player] then
                for _, d in pairs(playerDrawings[player]) do d.Visible = false end
            end
            if playerSkeleton[player] then
                for _, l in ipairs(playerSkeleton[player].lines) do l.Visible = false end
                if playerSkeleton[player].head then playerSkeleton[player].head.Visible = false end
            end
            continue
        end

        -- Создание рисунков при первом появлении
        if not playerDrawings[player] then
            playerDrawings[player] = {
                tracer = DrawingAvailable and Drawing.new("Line") or nil,
                box = DrawingAvailable and Drawing.new("Square") or nil,
                tag = DrawingAvailable and Drawing.new("Text") or nil
            }
            if playerDrawings[player].tracer then
                playerDrawings[player].tracer.Color = Color3.fromRGB(255,0,0)
                playerDrawings[player].tracer.Thickness = 1
            end
            if playerDrawings[player].box then
                playerDrawings[player].box.Color = Color3.fromRGB(255,0,0)
                playerDrawings[player].box.Thickness = 2
                playerDrawings[player].box.Filled = false
            end
            if playerDrawings[player].tag then
                playerDrawings[player].tag.Color = Color3.fromRGB(255,255,255)
                playerDrawings[player].tag.Size = 13
                playerDrawings[player].tag.Center = true
                playerDrawings[player].tag.Outline = true
            end
        end

        local dw = playerDrawings[player]
        local rootScreenPos = Camera:WorldToViewportPoint(hrp.Position)
        local footScreenPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))
        local distance = (camPos - hrp.Position).Magnitude

        if dw.tracer then
            dw.tracer.From = Vector2.new(viewSize.X/2, viewSize.Y)
            dw.tracer.To = Vector2.new(rootScreenPos.X, rootScreenPos.Y)
            dw.tracer.Visible = true
        end
        if dw.box and dw.tag then
            local boxHeight = math.abs(headScreenPos.Y - footScreenPos.Y)
            local boxWidth = boxHeight * 0.5
            dw.box.Size = Vector2.new(boxWidth, boxHeight)
            dw.box.Position = Vector2.new(rootScreenPos.X - boxWidth/2, headScreenPos.Y)
            dw.box.Visible = true
            dw.tag.Text = player.Name .. " [" .. math.floor(distance) .. "m]"
            dw.tag.Position = Vector2.new(rootScreenPos.X, headScreenPos.Y - 15)
            dw.tag.Visible = true
        end

        -- Скелет
        if SKELETON_ENABLED then
            local parts = {}
            for _, partName in ipairs({"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}) do
                parts[partName] = char:FindFirstChild(partName)
            end

            if not playerSkeleton[player] then
                playerSkeleton[player] = {lines = {}, head = nil}
                if DrawingAvailable then
                    for i = 1, #connections do
                        playerSkeleton[player].lines[i] = Drawing.new("Line")
                        playerSkeleton[player].lines[i].Color = Color3.fromRGB(255,255,255)
                        playerSkeleton[player].lines[i].Thickness = 1
                    end
                    playerSkeleton[player].head = Drawing.new("Circle")
                    playerSkeleton[player].head.Color = Color3.fromRGB(255,255,255)
                    playerSkeleton[player].head.Thickness = 1.5
                    playerSkeleton[player].head.Filled = false
                    playerSkeleton[player].head.Radius = SKELETON_HEAD_RADIUS
                end
            end

            local sk = playerSkeleton[player]
            for i, conn in ipairs(connections) do
                local a = parts[conn[1]]
                local b = parts[conn[2]]
                if a and b then
                    local pa, onScreenA = Camera:WorldToViewportPoint(a.Position)
                    local pb, onScreenB = Camera:WorldToViewportPoint(b.Position)
                    if onScreenA and onScreenB and sk.lines[i] then
                        sk.lines[i].From = Vector2.new(pa.X, pa.Y)
                        sk.lines[i].To = Vector2.new(pb.X, pb.Y)
                        sk.lines[i].Visible = true
                    elseif sk.lines[i] then
                        sk.lines[i].Visible = false
                    end
                elseif sk.lines[i] then
                    sk.lines[i].Visible = false
                end
            end
            if parts["Head"] and sk.head then
                local hp, onScreenH = Camera:WorldToViewportPoint(parts["Head"].Position)
                if onScreenH then
                    sk.head.Position = Vector2.new(hp.X, hp.Y)
                    sk.head.Visible = true
                else
                    sk.head.Visible = false
                end
            elseif sk.head then
                sk.head.Visible = false
            end
        else
            if playerSkeleton[player] then
                for _, l in ipairs(playerSkeleton[player].lines) do l.Visible = false end
                if playerSkeleton[player].head then playerSkeleton[player].head.Visible = false end
            end
        end
    end
end

-- ===== AIMBOT =====
local function getClosestInFOV()
    local mousePos = UserInputService:GetMouseLocation()
    local closestPlayer = nil
    local closestDistance = FOV_RADIUS
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not isEnemy(player) then continue end
        local head = player.Character and player.Character:FindFirstChild("Head")
        if not head then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if dist < closestDistance then
            closestPlayer = player
            closestDistance = dist
        end
    end
    return closestPlayer
end

local function aimAt(player)
    if not player then return end
    local head = player.Character and player.Character:FindFirstChild("Head")
    if not head then return end
    local targetCFrame = CFrame.new(Camera.CFrame.Position, head.Position)
    if AIM_SMOOTHNESS >= 1 then
        Camera.CFrame = targetCFrame
    else
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, AIM_SMOOTHNESS)
    end
end

-- ===== TRIGGERBOT =====
local lastShot = 0
local sightStart = nil
local mouseHeld = false
local lastTarget = nil

local function updateTriggerbot()
    if not TRIGGERBOT_ENABLED then
        if mouseHeld then
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, false)
            mouseHeld = false
        end
        sightStart = nil
        lastTarget = nil
        return
    end

    local center = Camera.ViewportSize / 2
    local target = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not isEnemy(player) then continue end
        local head = player.Character and player.Character:FindFirstChild("Head")
        if not head then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        if (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude < FOV_RADIUS and isVisible(head) then
            target = player
            break
        end
    end

    if not target then
        if mouseHeld then
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, false)
            mouseHeld = false
        end
        sightStart = nil
        lastTarget = nil
        return
    end

    if target ~= lastTarget then
        sightStart = tick()
        lastTarget = target
        if mouseHeld then
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, false)
            mouseHeld = false
        end
    end

    if sightStart and tick() - sightStart < TRIGGERBOT_DELAY then return end
    if tick() - lastShot < TRIGGERBOT_DELAY then return end

    VIM:SendMouseButtonEvent(0, 0, 0, true, game, false)
    mouseHeld = true
    lastShot = tick()

    task.delay(0.05, function()
        if mouseHeld then
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, false)
            mouseHeld = false
        end
    end)
end

-- ===== FLY (отдельная механика) =====
local flyVelocity = nil

local function updateFly()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        if flyVelocity then
            flyVelocity:Destroy()
            flyVelocity = nil
        end
        return
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char.HumanoidRootPart

    if FLY_ENABLED then
        if humanoid then humanoid.PlatformStand = true end
        if not flyVelocity or flyVelocity.Parent ~= hrp then
            if flyVelocity then flyVelocity:Destroy() end
            flyVelocity = Instance.new("BodyVelocity", hrp)
            flyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
            flyVelocity.Velocity = Vector3.zero
            flyVelocity.P = 1000
        end

        local moveDirection = Vector3.zero
        local camCF = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection += camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection -= camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection -= camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection += camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection -= Vector3.new(0, 1, 0) end

        if moveDirection.Magnitude > 0 then
            flyVelocity.Velocity = moveDirection.Unit * FLY_SPEED
        else
            flyVelocity.Velocity = Vector3.zero
        end
    else
        if humanoid then humanoid.PlatformStand = false end
        if flyVelocity then
            flyVelocity:Destroy()
            flyVelocity = nil
        end
    end
end

-- ===== NOCLIP (независимый) =====
local function updateNoClip()
    local char = LocalPlayer.Character
    if not char then return end
    local collidable = not NOCLIP_ENABLED
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = collidable
        end
    end
end

-- Применяем NoClip сразу при появлении персонажа, если активен
LocalPlayer.CharacterAdded:Connect(function(char)
    if NOCLIP_ENABLED then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- ===== ГЛАВНЫЙ ЦИКЛ =====
RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = Camera.ViewportSize / 2
        fovCircle.Radius = FOV_RADIUS
        fovCircle.Visible = AIMBOT_ENABLED
    end

    if DrawingAvailable then updateESP() end

    if _AIM and AIMBOT_ENABLED then
        local closest = getClosestInFOV()
        if closest then aimAt(closest) end
    end

    updateTriggerbot()
    updateFly()
    updateNoClip()
end)

print("Чит-скрипт активирован. Все модули работают независимо. Удачной игры!")