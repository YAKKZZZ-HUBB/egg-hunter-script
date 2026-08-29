-- =========================================================
-- 🥚 EGG HUNTER PRO - ON/OFF PER FITUR 🥚
-- Setiap fitur punya toggle sendiri, auto jalan!
-- =========================================================

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- =========================================================
-- KONFIGURASI (SEMUA OFF DEFAULT)
-- =========================================================
local config = {
    antiHit = false,
    autoTreadmill = false,
    autoSteal = false,
    bestEggMode = false,
    autoReturn = false,
}

local isRunning = true
local hasEgg = false
local isOnTreadmill = false
local currentSpeed = 16
local loopsStarted = false

local bestEggPriority = {"Divine", "Eternal", "Secret", "Cosmic", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common"}
local rarityData = {
    ["Common"] = { color = Color3.fromRGB(128, 128, 128), label = "⬜ Common" },
    ["Uncommon"] = { color = Color3.fromRGB(0, 255, 0), label = "🟩 Uncommon" },
    ["Rare"] = { color = Color3.fromRGB(0, 150, 255), label = "🟦 Rare" },
    ["Epic"] = { color = Color3.fromRGB(128, 0, 255), label = "🟪 Epic" },
    ["Legendary"] = { color = Color3.fromRGB(255, 150, 0), label = "🟧 Legendary" },
    ["Mythic"] = { color = Color3.fromRGB(255, 0, 150), label = "🟣 Mythic" },
    ["Cosmic"] = { color = Color3.fromRGB(0, 255, 255), label = "🌌 Cosmic" },
    ["Secret"] = { color = Color3.fromRGB(255, 0, 0), label = "🔴 Secret" },
    ["Eternal"] = { color = Color3.fromRGB(255, 215, 0), label = "♾️ Eternal" },
    ["Divine"] = { color = Color3.fromRGB(255, 50, 50), label = "👼 Divine" },
}

-- =========================================================
-- FUNGSI DASAR
-- =========================================================
function getBestEgg(eggs)
    if #eggs == 0 then return nil end
    for _, target in ipairs(bestEggPriority) do
        for _, egg in ipairs(eggs) do
            if egg.rarity == target then return egg end
        end
    end
    return eggs[1]
end

function walkTo(position)
    if not position then return end
    local dist = (rootPart.Position - position).Magnitude
    if dist < 5 then return end
    rootPart.CFrame = CFrame.lookAt(rootPart.Position, position)
    local tween = game:GetService("TweenService"):Create(
        rootPart,
        TweenInfo.new(math.min(dist / 80, 3), Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(position)}
    )
    tween:Play()
    tween.Completed:Wait()
end

function applySpeed(speed)
    local target = speed or 200
    target = math.min(target, 200)
    if humanoid then
        humanoid.WalkSpeed = target
        currentSpeed = target
    end
end

function jumpFromTreadmill()
    if humanoid then
        humanoid.Jump = true
        task.wait(0.2)
        humanoid.Jump = false
        local v = Instance.new("BodyVelocity")
        v.Velocity = rootPart.CFrame.LookVector * 30 + Vector3.new(0, 15, 0)
        v.MaxForce = Vector3.new(4000, 4000, 4000)
        v.Parent = rootPart
        task.wait(0.3)
        v:Destroy()
    end
end

function findTreadmill()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if string.find(name, "treadmill") or string.find(name, "tread") or 
               string.find(name, "mill") or string.find(name, "trainer") then
                if obj:FindFirstChild("HumanoidRootPart") then return obj.HumanoidRootPart
                elseif obj:IsA("BasePart") then return obj end
            end
        end
    end
    return nil
end

function findEggs()
    local eggs = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Parent then
            local name = obj.Name:lower()
            local parentName = obj.Parent.Name:lower()
            local fullName = (parentName .. " " .. name):lower()
            if string.find(fullName, "egg") or string.find(fullName, "telur") or string.find(fullName, "nest") then
                local rarity = "Common"
                if string.find(fullName, "divine") then rarity = "Divine"
                elseif string.find(fullName, "eternal") then rarity = "Eternal"
                elseif string.find(fullName, "secret") then rarity = "Secret"
                elseif string.find(fullName, "cosmic") then rarity = "Cosmic"
                elseif string.find(fullName, "mythic") then rarity = "Mythic"
                elseif string.find(fullName, "legend") then rarity = "Legendary"
                end
                table.insert(eggs, {
                    object = obj,
                    position = obj.Position,
                    rarity = rarity,
                    distance = (rootPart.Position - obj.Position).Magnitude,
                })
            end
        end
    end
    return eggs
end

function findBase()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if string.find(name, "base") or string.find(name, "spawn") or 
               string.find(name, "home") or string.find(name, "hub") then
                if obj:FindFirstChild("HumanoidRootPart") then return obj.HumanoidRootPart.Position
                elseif obj:IsA("BasePart") then return obj.Position end
            end
        end
    end
    return nil
end

-- =========================================================
-- LOOP FUNCTIONS (DIPANGGIL SAAT TOGGLE ON)
-- =========================================================
function autoTreadmillLoop()
    while isRunning and config.autoTreadmill do
        task.wait(2)
        if hasEgg then 
            if isOnTreadmill then
                isOnTreadmill = false
                jumpFromTreadmill()
            end
            continue
        end
        local speed = humanoid and humanoid.WalkSpeed or 16
        if speed < 200 then
            local treadPos = findTreadmill()
            if treadPos then
                walkTo(treadPos.Position)
                task.wait(0.5)
                isOnTreadmill = true
                for s = speed, 200, 10 do
                    if hasEgg or not isRunning then break end
                    applySpeed(s)
                    task.wait(0.3)
                end
                if currentSpeed >= 200 then
                    isOnTreadmill = false
                    jumpFromTreadmill()
                    updateLog("✅ Speed 200!")
                end
            end
        else
            if isOnTreadmill then
                isOnTreadmill = false
                jumpFromTreadmill()
            end
        end
    end
end

function autoStealLoop()
    while isRunning and config.autoSteal do
        task.wait(1)
        local eggs = findEggs()
        if #eggs > 0 then
            local bestEgg = getBestEgg(eggs)
            if bestEgg then
                local label = rarityData[bestEgg.rarity] and rarityData[bestEgg.rarity].label or bestEgg.rarity
                if (rootPart.Position - bestEgg.position).Magnitude > 10 then
                    walkTo(bestEgg.position)
                end
                task.wait(0.5)
                if bestEgg.object then
                    firetouchinterest(rootPart, bestEgg.object, 0)
                    task.wait(0.2)
                    firetouchinterest(rootPart, bestEgg.object, 1)
                end
                hasEgg = true
                updateLog("🥚 " .. label .. " diambil!")
                if config.autoReturn then
                    local basePos = findBase()
                    if basePos then
                        walkTo(basePos)
                        task.wait(0.5)
                        hasEgg = false
                        updateLog("✅ Telur disimpan!")
                    end
                end
            end
        end
    end
end

function antiHitLoop()
    while isRunning and config.antiHit do
        task.wait(0.5)
        humanoid.HealthChanged:Connect(function(health)
            if hasEgg and health < 20 then
                humanoid.Health = 80
                humanoid.BreakJointsOnDeath = false
            end
        end)
    end
end

function bestEggDetectionLoop()
    while isRunning and config.bestEggMode do
        task.wait(3)
        local eggs = findEggs()
        for _, egg in ipairs(eggs) do
            if egg.rarity == "Divine" or egg.rarity == "Eternal" or egg.rarity == "Secret" then
                local label = rarityData[egg.rarity] and rarityData[egg.rarity].label or egg.rarity
                updateLog("🎉 " .. label .. " SPAWN!")
                break
            end
        end
    end
end

-- =========================================================
-- UI
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player.PlayerGui
screenGui.Name = "EggHunterPro"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 380, 0, 420)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 30)
mainFrame.BackgroundTransparency = 0.05
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 200, 50)
stroke.Thickness = 1.5
stroke.Transparency = 0.4
stroke.Parent = mainFrame

-- HEADER
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
header.BackgroundTransparency = 0.15
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.Text = "🥚 EGG HUNTER PRO"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.Bold
title.TextSize = 20
title.BackgroundTransparency = 1
title.Parent = header

-- SPEED DISPLAY
local speedDisplay = Instance.new("TextLabel")
speedDisplay.Size = UDim2.new(0.9, 0, 0, 20)
speedDisplay.Position = UDim2.new(0.05, 0, 0, 50)
speedDisplay.Text = "⚡ Speed: 16"
speedDisplay.TextColor3 = Color3.fromRGB(100, 255, 100)
speedDisplay.Font = Enum.Font.SourceSansBold
speedDisplay.TextSize = 14
speedDisplay.BackgroundTransparency = 1
speedDisplay.Parent = mainFrame

-- TOGGLES (ON/OFF PER FITUR)
local toggles = {
    {name = "🛡️ Anti Hit", key = "antiHit", color = Color3.fromRGB(100, 200, 255)},
    {name = "🏃 Treadmill", key = "autoTreadmill", color = Color3.fromRGB(255, 200, 100)},
    {name = "🥚 Auto Steal", key = "autoSteal", color = Color3.fromRGB(255, 150, 100)},
    {name = "⭐ Best Egg", key = "bestEggMode", color = Color3.fromRGB(255, 215, 0)},
    {name = "🏠 Auto Return", key = "autoReturn", color = Color3.fromRGB(100, 255, 200)},
}

for i, t in ipairs(toggles) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 38)
    btn.Position = UDim2.new(0.05, 0, 0, 80 + (i-1) * 44)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
    btn.Text = "❌ " .. t.name
    btn.TextColor3 = t.color
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Parent = mainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        config[t.key] = state
        btn.BackgroundColor3 = state and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(40, 40, 70)
        btn.Text = (state and "✅ " or "❌ ") .. t.name
        updateLog((state and "🟢 " or "🔴 ") .. t.name .. " " .. (state and "ON" or "OFF"))
        
        -- JALANKAN LOOP SAAT TOGGLE ON
        if state then
            if t.key == "antiHit" then
                task.spawn(antiHitLoop)
            elseif t.key == "autoTreadmill" then
                task.spawn(autoTreadmillLoop)
            elseif t.key == "autoSteal" then
                task.spawn(autoStealLoop)
            elseif t.key == "bestEggMode" then
                task.spawn(bestEggDetectionLoop)
            end
        end
    end)
end

-- LOG
local logFrame = Instance.new("Frame")
logFrame.Size = UDim2.new(0.9, 0, 0, 50)
logFrame.Position = UDim2.new(0.05, 0, 0, 315)
logFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
logFrame.BackgroundTransparency = 0.5
logFrame.Parent = mainFrame
Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0, 8)

local logText = Instance.new("TextLabel")
logText.Name = "LogText"
logText.Size = UDim2.new(0.95, 0, 1, -6)
logText.Position = UDim2.new(0.025, 0, 0, 3)
logText.Text = "📌 Aktifkan fitur dengan toggle ON/OFF"
logText.TextColor3 = Color3.fromRGB(200, 200, 200)
logText.Font = Enum.Font.SourceSans
logText.TextSize = 12
logText.TextXAlignment = Enum.TextXAlignment.Left
logText.TextWrapped = true
logText.BackgroundTransparency = 1
logText.Parent = logFrame

-- FOOTER
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, 0, 0, 16)
footer.Position = UDim2.new(0, 0, 0, 400)
footer.Text = "⚡ ON/OFF per fitur • Auto jalan"
footer.TextColor3 = Color3.fromRGB(255, 255, 255)
footer.TextTransparency = 0.5
footer.Font = Enum.Font.SourceSans
footer.TextSize = 10
footer.BackgroundTransparency = 1
footer.Parent = mainFrame

-- =========================================================
-- UPDATE FUNCTIONS
-- =========================================================
function updateLog(text)
    if logText then
        logText.Text = "📌 " .. text
    end
end

-- Update speed terus
task.spawn(function()
    while true do
        task.wait(0.5)
        local speed = humanoid and humanoid.WalkSpeed or 16
        speedDisplay.Text = "⚡ Speed: " .. math.floor(speed)
    end
end)

updateLog("📌 Aktifkan fitur dengan toggle ON/OFF")
print("✅ EGG HUNTER PRO - ON/OFF PER FITUR!")
print("📌 Klik tombol ON/OFF di GUI untuk mengaktifkan fitur")
