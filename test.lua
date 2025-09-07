--переменные
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

---гуишка
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Adrenaline Defusal FPS",
    LoadingTitle = "Adrenaline.CC",
    LoadingSubtitle = "by kyoukidevs",
    ConfigurationSaving = {
       Enabled = true,
       FolderName = nil,
       FileName = "Adrenaline"
    }
})

local LegitTab = Window:CreateTab("Legit", "mouse")
local RageTab = Window:CreateTab("Rage", "crosshair")
local VisualsTab = Window:CreateTab("Visuals", "eye")
local LocalTab = Window:CreateTab("Local", "user-round")

-- Silent Aim переменные
local silentAimEnabled = false
local silentAimFOV = 100
local silentAimTargetPart = "Head"
local silentAimHitChance = 100
local autoShootEnabled = false
local autoShootDelay = 0.1

-- Создаем FOV круг для silent aim
local silentAimFovCircle = Drawing.new("Circle")
silentAimFovCircle.Visible = false
silentAimFovCircle.Thickness = 2
silentAimFovCircle.NumSides = 64
silentAimFovCircle.Radius = silentAimFOV
silentAimFovCircle.Filled = false
silentAimFovCircle.Color = Color3.fromRGB(255, 0, 0)
silentAimFovCircle.Transparency = 1

-- Индикатор цели
local silentAimTargetDot = Drawing.new("Circle")
silentAimTargetDot.Visible = false
silentAimTargetDot.Thickness = 2
silentAimTargetDot.NumSides = 12
silentAimTargetDot.Radius = 6
silentAimTargetDot.Filled = true
silentAimTargetDot.Color = Color3.fromRGB(255, 0, 0)
silentAimTargetDot.Transparency = 1

-- Функции silent aim
local function CalculateChance(Percentage)
    return math.random(1, 100) <= Percentage
end

local function getCrosshairPosition()
    local camera = workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
end

local function IsVisible(targetPart)
    if not LocalPlayer.Character then return false end
    
    local camera = workspace.CurrentCamera
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit
    local distance = (targetPart.Position - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    
    local raycastResult = workspace:Raycast(origin, direction * distance, raycastParams)
    return raycastResult == nil
end

local function getClosestPlayer()
    if not silentAimEnabled then return nil end
    
    local closestTarget = nil
    local closestDistance = silentAimFOV
    local crosshairPos = getCrosshairPosition() -- ЗДЕСЬ ИЗМЕНЕНИЕ
    local camera = workspace.CurrentCamera
    
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer == LocalPlayer then continue end

        local character = targetPlayer.Character
        if not character then continue end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local targetPart = character:FindFirstChild(silentAimTargetPart)
        
        if not humanoid or humanoid.Health <= 0 or not targetPart then continue end
        
        if not IsVisible(targetPart) then continue end
        
        local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end
        
        local targetPos = Vector2.new(screenPos.X, screenPos.Y)
        local distance = (crosshairPos - targetPos).Magnitude -- ЗДЕСЬ ИЗМЕНЕНИЕ
        
        if distance <= closestDistance then
            closestTarget = targetPart
            closestDistance = distance
        end
    end
    
    return closestTarget
end


-- Функция авто-стрельбы (РАБОЧАЯ)
local function autoShoot()
    while true do
        if autoShootEnabled and silentAimEnabled and silentAimTarget then
            -- Прямая эмуляция клика мыши
            mouse1press()
            wait(0.01)
            mouse1release()
        end
        wait(autoShootDelay)
    end
end

-- Альтернативный метод через инжекцию события
local function injectMouseClick()
    if autoShootEnabled and silentAimEnabled and silentAimTarget then
        -- Создаем и отправляем mouse event
        local mouseEvent = Instance.new("RemoteEvent")
        mouseEvent.Name = "MouseClickEvent"
        mouseEvent.Parent = game:GetService("ReplicatedStorage")
        
        -- Пытаемся найти оружие и вызвать его fire функцию
        if LocalPlayer.Character then
            for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
                if tool:IsA("Tool") then
                    local fireScript = tool:FindFirstChildWhichIsA("LocalScript")
                    if fireScript then
                        fireScript:FireServer("Fire")
                    end
                end
            end
        end
    end
end

-- Silent Aim hook
local silentAimTarget = nil
local oldNamecall

oldNamecall = hookmetamethod(game, "__namecall", function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    
    if silentAimEnabled and Method == "Raycast" then
        if CalculateChance(silentAimHitChance) and silentAimTarget and silentAimTarget.Parent then
            local self = Arguments[1]
            if self == workspace then
                local origin = Arguments[2]
                local direction = Arguments[3]
                
                -- Меняем направление raycast на цель
                local newDirection = (silentAimTarget.Position - origin).Unit * direction.Magnitude
                Arguments[3] = newDirection
                
                return oldNamecall(unpack(Arguments))
            end
        end
    end
    
    return oldNamecall(...)
end)

RunService.RenderStepped:Connect(function()
    -- Обновление FOV круга (ТОЧНО ПО ЦЕНТРУ)
    silentAimFovCircle.Position = getCrosshairPosition() -- ЗДЕСЬ ИЗМЕНЕНИЕ
    silentAimFovCircle.Visible = silentAimEnabled
    silentAimFovCircle.Radius = silentAimFOV
    
    -- Поиск цели
    silentAimTarget = getClosestPlayer()
    
    -- Обновление индикатора цели
    if silentAimEnabled and silentAimTarget and silentAimTarget.Parent then
        local camera = workspace.CurrentCamera
        local screenPos, onScreen = camera:WorldToViewportPoint(silentAimTarget.Position)
        if onScreen then
            silentAimTargetDot.Visible = true
            silentAimTargetDot.Position = Vector2.new(screenPos.X, screenPos.Y)
        else
            silentAimTargetDot.Visible = false
        end
    else
        silentAimTargetDot.Visible = false
    end
    
    -- Авто-стрельба в RenderStepped для большей отзывчивости
    if autoShootEnabled and silentAimEnabled and silentAimTarget then
        injectMouseClick()
    end
end)

-- Добавляем Silent Aim во вкладку Rage
local SilentAimToggle = RageTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "SilentAimToggle",
    Callback = function(Value)
        silentAimEnabled = Value
        print("Silent Aim: " .. (Value and "ON" or "OFF"))
    end,
})

local AutoShootToggle = RageTab:CreateToggle({
    Name = "Auto Shoot",
    CurrentValue = false,
    Flag = "AutoShootToggle",
    Callback = function(Value)
        autoShootEnabled = Value
        if Value then
            spawn(autoShoot) -- Запускаем авто-стрельбу
        end
        print("Auto Shoot: " .. (Value and "ON" or "OFF"))
    end,
})

local SilentAimFOVSlider = RageTab:CreateSlider({
    Name = "Silent Aim FOV",
    Range = {50, 300},
    Increment = 10,
    Suffix = "Units",
    CurrentValue = silentAimFOV,
    Flag = "SilentAimFOV",
    Callback = function(Value)
        silentAimFOV = Value
        silentAimFovCircle.Radius = Value
    end,
})

local SilentAimHitChanceSlider = RageTab:CreateSlider({
    Name = "Hit Chance",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = silentAimHitChance,
    Flag = "SilentAimHitChance",
    Callback = function(Value)
        silentAimHitChance = Value
    end,
})

local AutoShootDelaySlider = RageTab:CreateSlider({
    Name = "Auto Shoot Delay",
    Range = {0.05, 0.5},
    Increment = 0.01,
    Suffix = "sec",
    CurrentValue = autoShootDelay,
    Flag = "AutoShootDelay",
    Callback = function(Value)
        autoShootDelay = Value
    end,
})

local TargetPartDropdown = RageTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = silentAimTargetPart,
    Flag = "TargetPartDropdown",
    Callback = function(Option)
        silentAimTargetPart = Option
    end,
})

-- Запускаем авто-стрельбу в отдельном потоке
spawn(autoShoot)


-- rage | hitbox
local hitboxExpanderEnabled = false
local hitboxSize = 1.5
local originalSizes = {}
local hitboxParts = {"Head", "HumanoidRootPart"}

-- Функция для изменения размера хитбокса
local function updateHitboxes()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local character = player.Character
        if not character then continue end
        
        for _, partName in pairs(hitboxParts) do
            local part = character:FindFirstChild(partName)
            if part then
                if hitboxExpanderEnabled then
                    -- Сохраняем оригинальный размер если еще не сохранили
                    if not originalSizes[player.Name..partName] then
                        originalSizes[player.Name..partName] = part.Size
                    end
                    
                    -- Увеличиваем размер части
                    part.Size = originalSizes[player.Name..partName] * hitboxSize
                    part.CanCollide = false
                else
                    -- Восстанавливаем оригинальный размер
                    if originalSizes[player.Name..partName] then
                        part.Size = originalSizes[player.Name..partName]
                    end
                end
            end
        end
    end
end

-- Функция для сброса хитбоксов при выходе игрока
local function resetPlayerHitboxes(player)
    for _, partName in pairs(hitboxParts) do
        if originalSizes[player.Name..partName] then
            originalSizes[player.Name..partName] = nil
        end
    end
end

-- Добавляем этот код в секцию RageTab (после AutoShootDelaySlider)

local HitboxExpanderToggle = RageTab:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = false,
    Flag = "HitboxExpanderToggle",
    Callback = function(Value)
        hitboxExpanderEnabled = Value
        updateHitboxes()
        print("Hitbox Expander: " .. (Value and "ON" or "OFF"))
    end,
})

local HitboxSizeSlider = RageTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {1.0, 10.0},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = hitboxSize,
    Flag = "HitboxSizeSlider",
    Callback = function(Value)
        hitboxSize = Value
        if hitboxExpanderEnabled then
            updateHitboxes()
        end
    end,
})

local HitboxPartsDropdown = RageTab:CreateDropdown({
    Name = "Hitbox Parts",
    Options = {"Head", "HumanoidRootPart", "Both"},
    CurrentOption = "Head",
    Flag = "HitboxPartsDropdown",
    Callback = function(Option)
        if Option == "Both" then
            hitboxParts = {"Head", "HumanoidRootPart"}
        else
            hitboxParts = {Option}
        end
        
        if hitboxExpanderEnabled then
            updateHitboxes()
        end
    end,
})

-- Добавляем обновление хитбоксов в RenderStepped
RunService.RenderStepped:Connect(function()
    if hitboxExpanderEnabled then
        updateHitboxes()
    end
end)

-- Обработчики для игроков
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if hitboxExpanderEnabled then
            wait(0.5) -- Ждем немного пока персонаж полностью загрузится
            updateHitboxes()
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    resetPlayerHitboxes(player)
end)

-- Сбрасываем хитбоксы при выключении скрипта
game:GetService("UserInputService").WindowFocused:Connect(function()
    if not hitboxExpanderEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                if character then
                    for _, partName in pairs(hitboxParts) do
                        local part = character:FindFirstChild(partName)
                        if part and originalSizes[player.Name..partName] then
                            part.Size = originalSizes[player.Name..partName]
                        end
                    end
                end
            end
        end
    end
end)

-- legit | aimbot
local aimbotEnabled = false

local function getClosestTarget()
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local targetPosition = player.Character.Head.Position
            local screenPosition, onScreen = workspace.CurrentCamera:WorldToScreenPoint(targetPosition)

            if onScreen then
                local distance = (Mouse.X - screenPosition.X)^2 + (Mouse.Y - screenPosition.Y)^2
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

local function aimAtTarget(target)
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local targetPosition = target.Character.Head.Position
        local camera = workspace.CurrentCamera
        local direction = (targetPosition - camera.CFrame.Position).unit
        camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + direction)
    end
end

RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local target = getClosestTarget()
        aimAtTarget(target)
    end
end)

Mouse.Button2Down:Connect(function()
    aimbotEnabled = true
end)

Mouse.Button2Up:Connect(function()
    aimbotEnabled = false
end)

local AimToggle = LegitTab:CreateToggle({
    Name = "Toggle Aimbot",
    Callback = function()
        aimbotEnabled = not aimbotEnabled
    end,
})

-- Заменяем всю секцию Visuals | Chams на этот исправленный код:

--- Visuals | Chams
local espEnabled = false
local espHighlights = {}

-- Улучшенная функция создания хайлайта
local function createHighlight(player)
    if player == LocalPlayer then return nil end
    if not player.Character then return nil end
    
    local character = player.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end

    -- Удаляем старый хайлайт если есть
    if espHighlights[player.Name] then
        espHighlights[player.Name]:Destroy()
        espHighlights[player.Name] = nil
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_" .. player.Name
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    -- Добавляем метку с ником
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Name_" .. player.Name
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = character
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    return highlight
end

-- Функция для обновления всех ESP
local function updateAllESP()
    if not espEnabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not espHighlights[player.Name] then
                -- Создаем новый хайлайт
                espHighlights[player.Name] = createHighlight(player)
            else
                -- Проверяем если хайлайт еще существует
                if not espHighlights[player.Name] or not espHighlights[player.Name].Parent then
                    espHighlights[player.Name] = createHighlight(player)
                end
            end
        end
    end
end

-- Функция для удаления ESP игрока
local function removePlayerESP(playerName)
    if espHighlights[playerName] then
        espHighlights[playerName]:Destroy()
        espHighlights[playerName] = nil
    end
end

-- Основной цикл обновления ESP
local espUpdateConnection
local function startESPUpdate()
    if espUpdateConnection then
        espUpdateConnection:Disconnect()
    end
    
    espUpdateConnection = RunService.Heartbeat:Connect(function()
        if espEnabled then
            updateAllESP()
        end
    end)
end

local function stopESPUpdate()
    if espUpdateConnection then
        espUpdateConnection:Disconnect()
        espUpdateConnection = nil
    end
    
    -- Очищаем все хайлайты
    for playerName, highlight in pairs(espHighlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    espHighlights = {}
end

local ESPToggle = VisualsTab:CreateToggle({
    Name = "Toggle Chams",
    Callback = function(Value)
        espEnabled = Value
        if Value then
            startESPUpdate()
            print("ESP: ON")
        else
            stopESPUpdate()
            print("ESP: OFF")
        end
    end,
})

-- Обработчики для игроков
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if espEnabled then
            wait(0.5) -- Ждем пока персонаж полностью загрузится
            espHighlights[player.Name] = createHighlight(player)
        end
    end)
    
    player.CharacterRemoving:Connect(function()
        removePlayerESP(player.Name)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removePlayerESP(player.Name)
end)

-- Автоматическое обновление при респавне
local function setupRespawnDetection()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local function trackCharacter()
                local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Died:Connect(function()
                        -- При смерти удаляем ESP
                        removePlayerESP(player.Name)
                        
                        -- При возрождении создаем заново
                        player.CharacterAdded:Wait()
                        wait(1) -- Ждем пока персонаж появится
                        if espEnabled then
                            espHighlights[player.Name] = createHighlight(player)
                        end
                    end)
                end
            end
            
            if player.Character then
                trackCharacter()
            end
            player.CharacterAdded:Connect(trackCharacter)
        end
    end
end

-- Запускаем детекцию респавна
setupRespawnDetection()

-- Обновляем ESP при запуске если включено
if espEnabled then
    startESPUpdate()
end

---local | speedhack
local speedHackEnabled = false
local speedHackConnection = nil
local currentSpeed = 16

local SpeedSlider = LocalTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "SpeedSlider",
    Callback = function(Value)
        local player = game:GetService("Players").LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        currentSpeed = Value
        
        if speedHackConnection then
            speedHackConnection:Disconnect()
            speedHackConnection = nil
        end
        
        speedHackEnabled = true
        speedHackConnection = game:GetService("RunService").Stepped:Connect(function()
            if humanoid and humanoid.Parent then
                humanoid.WalkSpeed = currentSpeed
            end
        end)
    end,
})

local thirdPersonEnabled = false
local defaultZoom = 12.5
local thirdPersonConnection = nil

local ThirdPersonButton = LocalTab:CreateButton({
    Name = "ThirdPerson (Stable)",
    Callback = function()
        thirdPersonEnabled = not thirdPersonEnabled
        local player = game:GetService("Players").LocalPlayer
        
        if thirdPersonEnabled then
            if thirdPersonConnection then
                thirdPersonConnection:Disconnect()
            end
            
            thirdPersonConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if player then
                    player.CameraMode = Enum.CameraMode.Classic
                    player.CameraMaxZoomDistance = defaultZoom
                    player.CameraMinZoomDistance = defaultZoom
                end
            end)
        else
            if thirdPersonConnection then
                thirdPersonConnection:Disconnect()
                thirdPersonConnection = nil
            end
            player.CameraMode = Enum.CameraMode.LockFirstPerson
            player.CameraMaxZoomDistance = 0.5
            player.CameraMinZoomDistance = 0.5
        end
    end,
})

local CameraZoomSlider = LocalTab:CreateSlider({
    Name = "Camera Distance (Stable)",
    Range = {5, 25},
    Increment = 0.5,
    Suffix = "Studs",
    CurrentValue = 12.5,
    Flag = "CameraZoomSlider",
    Callback = function(Value)
        local player = game:GetService("Players").LocalPlayer
        defaultZoom = Value
        
        if thirdPersonEnabled then
            player.CameraMaxZoomDistance = Value
            player.CameraMinZoomDistance = Value
        end
    end,
})

local transparencyEnabled = false
local transparencyValue = 0.7
local transparencyConnection = nil

local TransparencyButton = LocalTab:CreateButton({
    Name = "Local Transparency (Stable)",
    Callback = function()
        transparencyEnabled = not transparencyEnabled
        local player = game:GetService("Players").LocalPlayer
        
        local function setTransparency(model, value)
            for _, part in pairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = value
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    part.Transparency = value
                elseif part:IsA("ParticleEmitter") then
                    part.Transparency = NumberSequence.new(value)
                end
            end
            
            for _, cloth in pairs(model:GetChildren()) do
                if cloth:IsA("Shirt") or cloth:IsA("Pants") or 
                   cloth:IsA("ShirtGraphic") or cloth:IsA("Accessory") or
                   cloth:IsA("Hat") then
                    for _, part in pairs(cloth:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = value
                        elseif part:IsA("Decal") or part:IsA("Texture") then
                            part.Transparency = value
                        end
                    end
                end
            end
        end
        
        if transparencyEnabled then
            if transparencyConnection then
                transparencyConnection:Disconnect()
            end
            
            transparencyConnection = game:GetService("RunService").Heartbeat:Connect(function()
                local character = player.Character
                if character then
                    setTransparency(character, transparencyValue)
                end
            end)
        else
            if transparencyConnection then
                transparencyConnection:Disconnect()
                transparencyConnection = nil
            end
            local character = player.Character
            if character then
                setTransparency(character, 0)
            end
        end
    end,
})

local TransparencySlider = LocalTab:CreateSlider({
    Name = "Transparency (Stable)",
    Range = {0, 1},
    Increment = 0.1,
    Suffix = "Alpha",
    CurrentValue = 0.7,
    Flag = "TransparencySlider",
    Callback = function(Value)
        transparencyValue = Value
    end,
})

local spinEnabled = false
local spinConnection = nil
local spinSpeed = 10

local SpinButton = LocalTab:CreateButton({
    Name = "Spin (Stable)",
    Callback = function()
        spinEnabled = not spinEnabled
        local player = game:GetService("Players").LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        
        humanoid.AutoRotate = not spinEnabled
        
        if spinEnabled then
            local spinForce = Instance.new("BodyAngularVelocity")
            spinForce.Name = "SpinForce"
            spinForce.AngularVelocity = Vector3.new(0, spinSpeed, 0)
            spinForce.MaxTorque = Vector3.new(0, math.huge, 0)
            spinForce.Parent = character.HumanoidRootPart
            
            if spinConnection then spinConnection:Disconnect() end
            
            spinConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local spinForce = character.HumanoidRootPart:FindFirstChild("SpinForce")
                    if spinForce then
                        spinForce.AngularVelocity = Vector3.new(0, spinSpeed, 0)
                    end
                end
            end)
            
            character.Humanoid.Died:Connect(function()
                if spinEnabled then
                    spinEnabled = false
                    if spinConnection then
                        spinConnection:Disconnect()
                        spinConnection = nil
                    end
                end
            end)
        else
            if spinConnection then
                spinConnection:Disconnect()
                spinConnection = nil
            end
            
            local spinForce = character.HumanoidRootPart:FindFirstChild("SpinForce")
            if spinForce then spinForce:Destroy() end
            
            humanoid.AutoRotate = true
        end
    end,
})

local SpinSpeedSlider = LocalTab:CreateSlider({
    Name = "Spin Speed",
    Range = {1, 50},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 10,
    Flag = "SpinSpeedSlider",
    Callback = function(Value)
        spinSpeed = Value
    end,
})
