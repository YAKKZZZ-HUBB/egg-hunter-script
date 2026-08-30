-- =========================================================
-- 🥚 EGG HUNTER - FINAL
-- BAGIAN 1/5: CONFIG + STATE + CHARACTER + SPEED
-- =========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =========================================================
-- CONFIG
-- =========================================================

local Config = {
    AutoSteal = false,
    AutoTreadmill = false,
    AntiHit = false,
    BestEgg = false,
    AutoReturn = false,

    ScanInterval = 0.5,
    ReturnDistance = 6,
    TreadmillHeight = 3,
}

-- =========================================================
-- STATE
-- =========================================================

local State = {
    Character = nil,
    Humanoid = nil,
    RootPart = nil,

    HasEgg = false,
    OnTreadmill = false,

    CurrentTarget = nil,
    LastDetectedEgg = nil,
    LastPosition = nil,

    Connections = {},
    Threads = {},
}

-- =========================================================
-- BEST EGG PRIORITY
-- =========================================================

local BestEggPriority = {
    "Divine", "Eternal", "Secret", "Cosmic", "Mythic",
    "Legendary", "Epic", "Rare", "Uncommon", "Common"
}

local RarityLabel = {
    Common = "⬜ Common",
    Uncommon = "🟩 Uncommon",
    Rare = "🟦 Rare",
    Epic = "🟪 Epic",
    Legendary = "🟧 Legendary",
    Mythic = "🟣 Mythic",
    Cosmic = "🌌 Cosmic",
    Secret = "🔴 Secret",
    Eternal = "♾️ Eternal",
    Divine = "👼 Divine",
}

local function detectRarity(name)
    name = tostring(name or ""):lower()
    for _, rarity in ipairs(BestEggPriority) do
        if string.find(name, rarity:lower(), 1, true) then
            return rarity
        end
    end
    return "Common"
end

-- =========================================================
-- CHARACTER
-- =========================================================

local function updateCharacter(character)
    State.Character = character
    State.Humanoid = nil
    State.RootPart = nil
    State.LastPosition = nil

    if not character then return end

    local hum = character:FindFirstChild("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if hum then State.Humanoid = hum end
    if root then
        State.RootPart = root
        State.LastPosition = root.Position
    end

    State.HasEgg = false
    State.OnTreadmill = false
    State.CurrentTarget = nil
end

updateCharacter(player.Character)

State.Connections.CharacterAdded = player.CharacterAdded:Connect(function(character)
    for key in pairs(State.Threads) do
        State.Threads[key] = nil
    end

    State.HasEgg = false
    State.OnTreadmill = false
    State.CurrentTarget = nil
    State.LastPosition = nil

    updateCharacter(character)
    task.wait(0.5)

    if Config.AntiHit and startAntiHit then
        startAntiHit()
    end
end)

-- =========================================================
-- SPEED (DISPLAY ONLY)
-- =========================================================

local function getSpeed()
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local speed = leaderstats:FindFirstChild("Speed")
        if speed and (speed:IsA("NumberValue") or speed:IsA("IntValue")) then
            return tonumber(speed.Value) or 0
        end
    end

    local data = player:FindFirstChild("Data")
    if data then
        local speed = data:FindFirstChild("Speed")
        if speed and (speed:IsA("NumberValue") or speed:IsA("IntValue")) then
            return tonumber(speed.Value) or 0
        end
    end

    return 0
end

local function formatNumber(number)
    number = tonumber(number) or 0
    if number >= 1e12 then return string.format("%.2fT", number / 1e12) end
    if number >= 1e9 then return string.format("%.2fB", number / 1e9) end
    if number >= 1e6 then return string.format("%.2fM", number / 1e6) end
    if number >= 1e3 then return string.format("%.2fK", number / 1e3) end
    return tostring(math.floor(number))
end

print("✅ BAGIAN 1/5 LOADED - Config + State + Character + Speed")

-- =========================================================
-- 🥚 EGG HUNTER - FINAL
-- BAGIAN 2/5: WORKSPACE + EGG DETECTION + MOVEMENT
-- =========================================================

-- =========================================================
-- WORKSPACE
-- =========================================================

local function getTreadmill()
    local treadmill = workspace:FindFirstChild("Treadmill")
    if not treadmill then return nil end

    local part = treadmill:FindFirstChild("TreadmillPart")
    if part and part:IsA("BasePart") then return part end

    for _, child in pairs(treadmill:GetChildren()) do
        if child:IsA("BasePart") then return child end
    end
    return nil
end

local function getSafeZone()
    local safe = workspace:FindFirstChild("SafeZone")
    if not safe then safe = workspace:FindFirstChild("Base") end
    if not safe then return nil end

    for _, child in pairs(safe:GetChildren()) do
        if child:IsA("BasePart") then return child end
    end
    return nil
end

-- =========================================================
-- EGG DETECTION
-- =========================================================

local function buildEgg(model)
    if not model or not model:IsA("Model") then return nil end

    local part = nil
    for _, child in pairs(model:GetChildren()) do
        if child:IsA("BasePart") then
            part = child
            break
        end
    end
    if not part then return nil end

    local prompt = nil
    local click = nil
    for _, child in pairs(model:GetChildren()) do
        if child:IsA("ProximityPrompt") then prompt = child end
        if child:IsA("ClickDetector") then click = child end
    end

    return {
        Model = model,
        Part = part,
        Name = model.Name,
        Rarity = detectRarity(model.Name),
        Position = part.Position,
        Prompt = prompt,
        Click = click,
    }
end

local function getEggs()
    local result = {}
    local eggsFolder = workspace:FindFirstChild("Eggs")

    if eggsFolder then
        for _, object in pairs(eggsFolder:GetChildren()) do
            if object:IsA("Model") then
                local egg = buildEgg(object)
                if egg then table.insert(result, egg) end
            end
        end
    else
        for _, object in pairs(workspace:GetDescendants()) do
            if object:IsA("Model") and string.find(object.Name:lower(), "egg", 1, true) then
                local egg = buildEgg(object)
                if egg then table.insert(result, egg) end
            end
        end
    end

    return result
end

local function getBestEgg(eggs)
    if type(eggs) ~= "table" or #eggs == 0 then return nil end

    for _, rarity in ipairs(BestEggPriority) do
        for _, egg in ipairs(eggs) do
            if egg.Rarity == rarity then return egg end
        end
    end
    return eggs[1]
end

-- =========================================================
-- EGG IN HAND CHECK
-- =========================================================

local function hasEggInHand()
    local character = State.Character
    if not character or not character.Parent then return false end

    for _, object in pairs(character:GetChildren()) do
        if string.find(object.Name:lower(), "egg", 1, true) then
            return true
        end
    end
    return false
end

-- =========================================================
-- MOVEMENT
-- =========================================================

local activeTween = nil

local function stopMove()
    if activeTween then
        pcall(function() activeTween:Cancel() end)
        activeTween = nil
    end
end

local function moveTo(position)
    local root = State.RootPart
    if not root or not root.Parent or not position then return false end

    local distance = (root.Position - position).Magnitude
    if distance <= 3 then return true end

    stopMove()
    local duration = math.clamp(distance / 60, 0.1, 3)
    root.CFrame = CFrame.lookAt(root.Position, position)

    activeTween = TweenService:Create(
        root,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { CFrame = CFrame.new(position) }
    )

    activeTween:Play()

    local finished = false
    local connection = activeTween.Completed:Connect(function() finished = true end)

    while not finished and activeTween do
        task.wait()
    end

    connection:Disconnect()
    activeTween = nil
    return true
end

print("✅ BAGIAN 2/5 LOADED - Workspace + Egg Detection + Movement")

-- =========================================================
-- 🥚 EGG HUNTER - FINAL
-- BAGIAN 3/5: AUTO TREADMILL + AUTO STEAL
-- =========================================================

-- =========================================================
-- AUTO TREADMILL
-- =========================================================

local function startTreadmill()
    if State.Threads.Treadmill then return end

    State.Threads.Treadmill = task.spawn(function()
        while Config.AutoTreadmill do
            local root = State.RootPart

            if not root or not root.Parent then
                task.wait(1)
                continue
            end

            if State.HasEgg then
                State.OnTreadmill = false
                task.wait(1)
                continue
            end

            local treadmill = getTreadmill()
            if not treadmill then
                updateLog("⚠️ Treadmill tidak ditemukan")
                task.wait(2)
                continue
            end

            local targetPosition = treadmill.Position + Vector3.new(0, Config.TreadmillHeight, 0)
            if (root.Position - targetPosition).Magnitude > 4 then
                updateLog("🏃 Menuju treadmill...")
                moveTo(targetPosition)
            end

            State.OnTreadmill = true
            updateLog("🏃 Berlatih di treadmill...")
            task.wait(3)
        end

        State.OnTreadmill = false
        State.Threads.Treadmill = nil
    end)
end

-- =========================================================
-- AUTO STEAL
-- =========================================================

local function startSteal()
    if State.Threads.Steal then return end

    State.Threads.Steal = task.spawn(function()
        while Config.AutoSteal do
            local root = State.RootPart

            if not root or not root.Parent then
                task.wait(1)
                continue
            end

            if hasEggInHand() then
                State.HasEgg = true
            end

            if State.HasEgg then
                State.OnTreadmill = false

                if Config.AutoReturn then
                    local safe = getSafeZone()

                    if safe then
                        updateLog("🏠 Membawa telur ke Base...")
                        moveTo(safe.Position + Vector3.new(0, 3, 0))
                        task.wait(0.5)

                        if not hasEggInHand() then
                            State.HasEgg = false
                            updateLog("✅ Telur tersimpan")
                        else
                            updateLog("⚠️ Telur masih dibawa")
                        end
                    else
                        updateLog("⚠️ Base tidak ditemukan")
                    end
                end

                task.wait(1)
                continue
            end

            local eggs = getEggs()

            if #eggs == 0 then
                updateLog("🔎 Tidak ada telur")
                task.wait(Config.ScanInterval)
                continue
            end

            local target = getBestEgg(eggs)

            if not target or not target.Part or not target.Part.Parent then
                task.wait(0.5)
                continue
            end

            State.CurrentTarget = target

            local label = RarityLabel[target.Rarity] or target.Rarity
            updateLog("🎯 Target: " .. label)

            local position = target.Part.Position
            if (root.Position - position).Magnitude > 4 then
                moveTo(position + Vector3.new(0, 2, 0))
            end

            local prompt = target.Prompt

            if prompt and prompt.Parent and prompt.Enabled then
                updateLog("🥚 Mengambil " .. label .. "...")

                pcall(function()
                    prompt:InputHoldBegin()
                end)

                task.wait(math.max(prompt.HoldDuration or 0.3, 0.1))

                pcall(function()
                    prompt:InputHoldEnd()
                end)

                task.wait(0.7)

                if hasEggInHand() then
                    State.HasEgg = true
                    updateLog("✅ " .. label .. " berhasil diambil!")
                else
                    updateLog("⚠️ Telur belum terdeteksi")
                end
            else
                local click = target.Click
                if click and click.Parent then
                    updateLog("🥚 Mengambil " .. label .. " (ClickDetector)...")
                    fireclickdetector(click)
                    task.wait(0.7)

                    if hasEggInHand() then
                        State.HasEgg = true
                        updateLog("✅ " .. label .. " berhasil diambil!")
                    else
                        updateLog("⚠️ Telur belum terdeteksi")
                    end
                else
                    updateLog("⚠️ Tidak ada Prompt atau ClickDetector")
                end
            end

            task.wait(Config.ScanInterval)
        end

        State.Threads.Steal = nil
    end)
end

print("✅ BAGIAN 3/5 LOADED - Auto Treadmill + Auto Steal")

-- =========================================================
-- 🥚 EGG HUNTER - FINAL
-- BAGIAN 4/5: BEST EGG + ANTI HIT
-- =========================================================

-- =========================================================
-- BEST EGG DETECTION
-- =========================================================

local function startBestEgg()
    if State.Threads.BestEgg then return end

    State.Threads.BestEgg = task.spawn(function()
        while Config.BestEgg do
            local eggs = getEggs()
            local target = getBestEgg(eggs)

            if target then
                local important = target.Rarity == "Divine"
                    or target.Rarity == "Eternal"
                    or target.Rarity == "Secret"

                if important then
                    local id = target.Model:GetDebugId()

                    if id ~= State.LastDetectedEgg then
                        State.LastDetectedEgg = id
                        updateLog("🎉 " .. (RarityLabel[target.Rarity] or target.Rarity) .. " SPAWN!")
                    end
                end
            end

            task.wait(2)
        end

        State.Threads.BestEgg = nil
    end)
end

-- =========================================================
-- ANTI HIT
-- =========================================================

local function startAntiHit()
    if State.Threads.AntiHit then return end

    State.Threads.AntiHit = task.spawn(function()
        while Config.AntiHit do
            if State.Humanoid then
                local health = State.Humanoid.Health

                if health <= 0 then
                    State.HasEgg = false
                    State.OnTreadmill = false
                    State.CurrentTarget = nil
                end

                if State.HasEgg and health < 20 and health > 0 then
                    pcall(function()
                        State.Humanoid.Health = 100
                    end)
                end
            end

            if State.HasEgg and State.RootPart then
                local currentPos = State.RootPart.Position

                if State.LastPosition then
                    local distance = (currentPos - State.LastPosition).Magnitude

                    if distance > 10 then
                        pcall(function()
                            State.RootPart.CFrame = CFrame.new(State.LastPosition)
                            local bv = State.RootPart:FindFirstChild("BodyVelocity")
                            if bv then bv:Destroy() end
                        end)
                    end
                end

                State.LastPosition = State.RootPart.Position
            end

            task.wait(0.05)
        end

        State.Threads.AntiHit = nil
    end)
end

print("✅ BAGIAN 4/5 LOADED - Best Egg + Anti Hit")

-- =========================================================
-- 🥚 EGG HUNTER - FINAL
-- BAGIAN 5/5: GUI + MONITOR + INITIALIZATION
-- =========================================================

-- =========================================================
-- GUI
-- =========================================================

local oldGui = playerGui:FindFirstChild("EggHunter")
if oldGui then
    oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggHunter"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 330)
frame.Position = UDim2.new(0.5, -140, 0.5, -165)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Transparency = 0.35
stroke.Parent = frame

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 38)
header.Text = "🥚 EGG HUNTER"
header.TextColor3 = Color3.fromRGB(255, 255, 255)
header.Font = Enum.Font.GothamBold
header.TextSize = 16
header.BackgroundTransparency = 1
header.Parent = frame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -30, 0, 25)
speedLabel.Position = UDim2.new(0, 15, 0, 38)
speedLabel.Text = "⚡ Speed: 0"
speedLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 13
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.BackgroundTransparency = 1
speedLabel.Parent = frame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -30, 0, 30)
logLabel.Position = UDim2.new(0, 15, 0, 65)
logLabel.Text = "📌 Ready"
logLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
logLabel.Font = Enum.Font.Gotham
logLabel.TextSize = 11
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextWrapped = true
logLabel.BackgroundTransparency = 1
logLabel.Parent = frame

updateLog = function(text)
    if logLabel and logLabel.Parent then
        logLabel.Text = "📌 " .. tostring(text)
    end
end

local function createToggle(name, key, y, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -30, 0, 32)
    button.Position = UDim2.new(0, 15, 0, y)
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
    button.TextColor3 = Color3.fromRGB(220, 220, 220)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.Text = "❌ " .. name
    button.Parent = frame

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)

    local enabled = false

    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        Config[key] = enabled

        if enabled then
            button.BackgroundColor3 = Color3.fromRGB(45, 180, 80)
            button.Text = "✅ " .. name
        else
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
            button.Text = "❌ " .. name
        end

        updateLog(name .. " " .. (enabled and "ON" or "OFF"))

        if callback then
            callback(enabled)
        end
    end)
end

createToggle("🥚 Auto Steal", "AutoSteal", 100, function(enabled)
    if enabled then startSteal() end
end)

createToggle("🏃 Treadmill", "AutoTreadmill", 138, function(enabled)
    if enabled then startTreadmill() end
end)

createToggle("🛡️ Anti Hit", "AntiHit", 176, function(enabled)
    if enabled then startAntiHit() end
end)

createToggle("⭐ Best Egg", "BestEgg", 214, function(enabled)
    if enabled then startBestEgg() end
end)

createToggle("🏠 Auto Return", "AutoReturn", 252)

local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, 0, 0, 20)
footer.Position = UDim2.new(0, 0, 1, -24)
footer.Text = "⚡ Speed Monitor Only"
footer.TextColor3 = Color3.fromRGB(160, 160, 160)
footer.Font = Enum.Font.Gotham
footer.TextSize = 9
footer.BackgroundTransparency = 1
footer.Parent = frame

-- =========================================================
-- MONITOR
-- =========================================================

State.Threads.SpeedMonitor = task.spawn(function()
    while screenGui and screenGui.Parent do
        local speed = getSpeed()
        if speedLabel and speedLabel.Parent then
            speedLabel.Text = "⚡ Speed: " .. formatNumber(speed)
        end
        task.wait(0.5)
    end
end)

State.Threads.StateMonitor = task.spawn(function()
    while screenGui and screenGui.Parent do
        if hasEggInHand() then
            State.HasEgg = true
        end
        task.wait(0.5)
    end
end)

-- =========================================================
-- CLEANUP
-- =========================================================

screenGui.AncestryChanged:Connect(function(_, parent)
    if parent then return end

    Config.AutoSteal = false
    Config.AutoTreadmill = false
    Config.AntiHit = false
    Config.BestEgg = false
    Config.AutoReturn = false

    stopMove()

    for _, connection in pairs(State.Connections) do
        pcall(function() connection:Disconnect() end)
    end

    State.Connections = {}
    State.Threads = {}
end)

-- =========================================================
-- START
-- =========================================================

updateLog("🥚 EGG HUNTER siap digunakan")

print("========================================")
print("🥚 EGG HUNTER FINAL LOADED")
print("⚡ Speed = Monitor Only")
print("🏃 Treadmill = Berdiri di atas treadmill")
print("🥚 Auto Steal = Prioritas rarity terbaik")
print("🛡️ Anti Hit = Cegah terpental + reset state")
print("========================================")
