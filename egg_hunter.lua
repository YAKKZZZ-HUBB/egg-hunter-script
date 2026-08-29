-- =========================================================
-- 🥚 ULTIMATE EGG HUNTER - UI PRO (BAGIAN 1/4) 🥚
-- =========================================================

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- =========================================================
-- KONFIGURASI
-- =========================================================
local config = {
    autoSteal = true,
    stealRadius = 250,
    antiHit = true,
    antiDrop = true,
    autoTreadmill = true,
    targetSpeed = 200,
    bestEggMode = true,
    autoTakeBestEgg = true,
    notifyBestEgg = true,
    autoReturn = true,
    returnRadius = 80,
    autoHeal = true,
    healThreshold = 30,
}

local isRunning = false
local hasEgg = false
local currentEgg = nil
local currentEggRarity = nil
local isReturning = false
local isStealing = false
local isOnTreadmill = false
local currentSpeed = 16

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

local bestEggPriority = {"Divine", "Eternal", "Secret", "Cosmic", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common"}

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

function teleportTo(pos)
    if not pos then return end
    rootPart.CFrame = CFrame.new(pos)
    task.wait(0.3)
end

function applySpeed(speed)
    local target = speed or 200
    target = math.min(target, 200)
    if humanoid then
        humanoid.WalkSpeed = target
        currentSpeed = target
    end
end

function resetSpeed()
    if humanoid then
        humanoid.WalkSpeed = 16
        currentSpeed = 16
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

-- =========================================================
-- 🥚 ULTIMATE EGG HUNTER - UI PRO (BAGIAN 2/4) 🥚
-- =========================================================

function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = player.PlayerGui
    screenGui.Name = "EggHunterPro"
    screenGui.ResetOnSpawn = false

    -- MAIN FRAME
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -260)
    mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 30)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.Parent = screenGui
    mainFrame.Active = true
    mainFrame.Draggable = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 200, 50)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    stroke.Parent = mainFrame

    -- HEADER
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 55)
    header.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
    header.BackgroundTransparency = 0.15
    header.Parent = mainFrame
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.Text = "🥚 EGG HUNTER PRO"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.Bold
    title.TextSize = 22
    title.BackgroundTransparency = 1
    title.Parent = header
    
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 18)
    sub.Position = UDim2.new(0, 0, 0, 38)
    sub.Text = "⚡ Auto Steal • Anti Hit • Best Egg"
    sub.TextColor3 = Color3.fromRGB(255, 255, 255)
    sub.TextTransparency = 0.5
    sub.Font = Enum.Font.SourceSans
    sub.TextSize = 11
    sub.BackgroundTransparency = 1
    sub.Parent = mainFrame

    -- STATUS
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(0.9, 0, 0, 55)
    statusFrame.Position = UDim2.new(0.05, 0, 0, 68)
    statusFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 50)
    statusFrame.BackgroundTransparency = 0.5
    statusFrame.Parent = mainFrame
    Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 10)
    
    local sIcon = Instance.new("TextLabel")
    sIcon.Size = UDim2.new(0, 35, 0, 35)
    sIcon.Position = UDim2.new(0.05, 0, 0.1, 0)
    sIcon.Text = "🟢"
    sIcon.TextSize = 28
    sIcon.BackgroundTransparency = 1
    sIcon.Parent = statusFrame
    
    local sTitle = Instance.new("TextLabel")
    sTitle.Size = UDim2.new(0.6, 0, 0, 20)
    sTitle.Position = UDim2.new(0.2, 0, 0.05, 0)
    sTitle.Text = "Status"
    sTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    sTitle.TextTransparency = 0.5
    sTitle.Font = Enum.Font.SourceSans
    sTitle.TextSize = 11
    sTitle.BackgroundTransparency = 1
    sTitle.Parent = statusFrame
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(0.6, 0, 0, 28)
    statusText.Position = UDim2.new(0.2, 0, 0.35, 0)
    statusText.Text = "🔴 BELUM AKTIF"
    statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusText.Font = Enum.Font.Bold
    statusText.TextSize = 15
    statusText.BackgroundTransparency = 1
    statusText.Parent = statusFrame

    -- STATS
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(0.9, 0, 0, 75)
    statsFrame.Position = UDim2.new(0.05, 0, 0, 132)
    statsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 50)
    statsFrame.BackgroundTransparency = 0.5
    statsFrame.Parent = mainFrame
    Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0, 10)
    
    -- Speed
    local spBox = Instance.new("Frame")
    spBox.Size = UDim2.new(0.45, 0, 1, 0)
    spBox.BackgroundTransparency = 1
    spBox.Parent = statsFrame
    
    local spLabel = Instance.new("TextLabel")
    spLabel.Size = UDim2.new(1, 0, 0, 22)
    spLabel.Position = UDim2.new(0, 0, 0.05, 0)
    spLabel.Text = "⚡ Speed"
    spLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    spLabel.TextTransparency = 0.5
    spLabel.Font = Enum.Font.SourceSans
    spLabel.TextSize = 11
    spLabel.BackgroundTransparency = 1
    spLabel.Parent = spBox
    
    local speedVal = Instance.new("TextLabel")
    speedVal.Name = "SpeedValue"
    speedVal.Size = UDim2.new(1, 0, 0, 35)
    speedVal.Position = UDim2.new(0, 0, 0.45, 0)
    speedVal.Text = "16"
    speedVal.TextColor3 = Color3.fromRGB(100, 255, 100)
    speedVal.Font = Enum.Font.Bold
    speedVal.TextSize = 30
    speedVal.BackgroundTransparency = 1
    speedVal.Parent = spBox
    
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(0.002, 0, 0.8, 0)
    divider.Position = UDim2.new(0.48, 0, 0.1, 0)
    divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    divider.BackgroundTransparency = 0.8
    divider.Parent = statsFrame
    
    -- Egg
    local egBox = Instance.new("Frame")
    egBox.Size = UDim2.new(0.45, 0, 1, 0)
    egBox.Position = UDim2.new(0.52, 0, 0, 0)
    egBox.BackgroundTransparency = 1
    egBox.Parent = statsFrame
    
    local egLabel = Instance.new("TextLabel")
    egLabel.Size = UDim2.new(1, 0, 0, 22)
    egLabel.Position = UDim2.new(0, 0, 0.05, 0)
    egLabel.Text = "🥚 Best Egg"
    egLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    egLabel.TextTransparency = 0.5
    egLabel.Font = Enum.Font.SourceSans
    egLabel.TextSize = 11
    egLabel.BackgroundTransparency = 1
    egLabel.Parent = egBox
    
    local eggVal = Instance.new("TextLabel")
    eggVal.Name = "EggValue"
    eggVal.Size = UDim2.new(1, 0, 0, 35)
    eggVal.Position = UDim2.new(0, 0, 0.45, 0)
    eggVal.Text = "❌ Tidak ada"
    eggVal.TextColor3 = Color3.fromRGB(200, 200, 200)
    eggVal.Font = Enum.Font.SourceSans
    eggVal.TextSize = 16
    eggVal.BackgroundTransparency = 1
    eggVal.Parent = egBox

-- =========================================================
-- 🥚 ULTIMATE EGG HUNTER - UI PRO (BAGIAN 3/4) 🥚
-- =========================================================

    -- BUTTONS
    local btnFrame = Instance.new("Frame")
    btnFrame.Size = UDim2.new(0.9, 0, 0, 120)
    btnFrame.Position = UDim2.new(0.05, 0, 0, 218)
    btnFrame.BackgroundTransparency = 1
    btnFrame.Parent = mainFrame
    
    local startBtn = Instance.new("TextButton")
    startBtn.Name = "StartBtn"
    startBtn.Size = UDim2.new(1, 0, 0, 48)
    startBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    startBtn.Text = "🚀 START HUNTING"
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.Font = Enum.Font.Bold
    startBtn.TextSize = 18
    startBtn.Parent = btnFrame
    Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)
    
    local sGlow = Instance.new("UIStroke")
    sGlow.Color = Color3.fromRGB(100, 255, 100)
    sGlow.Thickness = 2
    sGlow.Transparency = 0.5
    sGlow.Parent = startBtn
    
    local togFrame = Instance.new("Frame")
    togFrame.Size = UDim2.new(1, 0, 0, 48)
    togFrame.Position = UDim2.new(0, 0, 0, 56)
    togFrame.BackgroundTransparency = 1
    togFrame.Parent = btnFrame
    
    local toggles = {
        {name = "🛡️ Anti Hit", key = "antiHit"},
        {name = "🏃 Treadmill", key = "autoTreadmill"},
        {name = "⭐ Best Egg", key = "bestEggMode"},
    }
    
    for i, t in ipairs(toggles) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.3, 0, 1, -4)
        btn.Position = UDim2.new(0.03 + (i-1) * 0.34, 0, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        btn.Text = "✅ " .. t.name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 11
        btn.Parent = togFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        local state = true
        btn.MouseButton1Click:Connect(function()
            state = not state
            config[t.key] = state
            btn.BackgroundColor3 = state and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(60, 40, 40)
            btn.Text = (state and "✅ " or "❌ ") .. t.name
        end)
    end

    -- LOG
    local logFrame = Instance.new("Frame")
    logFrame.Size = UDim2.new(0.9, 0, 0, 70)
    logFrame.Position = UDim2.new(0.05, 0, 0, 355)
    logFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    logFrame.BackgroundTransparency = 0.5
    logFrame.Parent = mainFrame
    Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0, 8)
    
    local logText = Instance.new("TextLabel")
    logText.Name = "LogText"
    logText.Size = UDim2.new(0.95, 0, 1, -8)
    logText.Position = UDim2.new(0.025, 0, 0, 4)
    logText.Text = "📌 Siap berburu telur..."
    logText.TextColor3 = Color3.fromRGB(200, 200, 200)
    logText.Font = Enum.Font.SourceSans
    logText.TextSize = 12
    logText.TextXAlignment = Enum.TextXAlignment.Left
    logText.TextWrapped = true
    logText.BackgroundTransparency = 1
    logText.Parent = logFrame

    -- FOOTER
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, 0, 0, 18)
    footer.Position = UDim2.new(0, 0, 0, 498)
    footer.Text = "⚡ YAKKZZZ-HUBB © 2026"
    footer.TextColor3 = Color3.fromRGB(255, 255, 255)
    footer.TextTransparency = 0.5
    footer.Font = Enum.Font.SourceSans
    footer.TextSize = 10
    footer.BackgroundTransparency = 1
    footer.Parent = mainFrame

    return {
        mainFrame = mainFrame,
        statusText = statusText,
        speedValue = speedVal,
        eggValue = eggVal,
        logText = logText,
        startBtn = startBtn,
    }
end

local ui = createUI()

function updateStatus(text, color)
    if ui.statusText then
        ui.statusText.Text = text
        ui.statusText.TextColor3 = color or Color3.fromRGB(100, 255, 100)
    end
end

function updateSpeed(speed)
    if ui.speedValue then
        ui.speedValue.Text = tostring(speed)
        ui.speedValue.TextColor3 = speed >= 200 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 50)
    end
end

function updateEgg(text, color)
    if ui.eggValue then
        ui.eggValue.Text = text
        ui.eggValue.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    end
end

function addLog(text, color)
    if ui.logText then
        ui.logText.Text = text
        ui.logText.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    end
end

-- =========================================================
-- 🥚 ULTIMATE EGG HUNTER - UI PRO (BAGIAN 4/4) 🥚
-- =========================================================

-- =========================================================
-- FUNGSI UTAMA
-- =========================================================
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
-- AUTO STEAL LOOP
-- =========================================================
function autoStealLoop()
    addLog("🥚 Auto Steal AKTIF!", Color3.fromRGB(100, 255, 100))
    
    while isRunning and config.autoSteal do
        task.wait(0.5)
        
        local eggs = findEggs()
        if #eggs > 0 then
            local bestEgg = getBestEgg(eggs)
            if bestEgg then
                local label = rarityData[bestEgg.rarity] and rarityData[bestEgg.rarity].label or bestEgg.rarity
                addLog("🥚 Menuju: " .. label, Color3.fromRGB(255, 200, 100))
                updateEgg(label, rarityData[bestEgg.rarity] and rarityData[bestEgg.rarity].color)
                
                teleportTo(bestEgg.position)
                task.wait(0.3)
                
                hasEgg = true
                currentEgg = bestEgg
                currentEggRarity = bestEgg.rarity
                addLog("✅ " .. label .. " berhasil diambil!", Color3.fromRGB(100, 255, 100))
                
                local basePos = findBase()
                if basePos then
                    addLog("🏠 Return ke base...", Color3.fromRGB(100, 200, 255))
                    teleportTo(basePos)
                    task.wait(0.5)
                    hasEgg = false
                    currentEgg = nil
                    currentEggRarity = nil
                    addLog("✅ Telur disimpan!", Color3.fromRGB(100, 255, 100))
                    updateEgg("✅ Tersimpan!", Color3.fromRGB(100, 255, 100))
                end
            end
        else
            updateEgg("🔍 Mencari telur...", Color3.fromRGB(200, 200, 200))
        end
    end
end

-- =========================================================
-- AUTO TREADMILL LOOP
-- =========================================================
function autoTreadmillLoop()
    addLog("🏃 Auto Treadmill AKTIF!", Color3.fromRGB(100, 200, 255))
    
    while isRunning and config.autoTreadmill do
        task.wait(2)
        
        if hasEgg then 
            if isOnTreadmill then
                isOnTreadmill = false
                jumpFromTreadmill()
                addLog("🦘 Loncat!", Color3.fromRGB(255, 200, 100))
            end
            continue
        end
        
        local currentWalkSpeed = humanoid and humanoid.WalkSpeed or 16
        
        if currentWalkSpeed < 200 then
            local treadPos = findTreadmill()
            if treadPos then
                teleportTo(treadPos.Position)
                task.wait(0.5)
                isOnTreadmill = true
                addLog("🏃 Naik treadmill... Speed: " .. math.floor(currentWalkSpeed), Color3.fromRGB(100, 200, 255))
                
                for speed = currentWalkSpeed, 200, 10 do
                    if hasEgg or not isRunning then break end
                    applySpeed(speed)
                    updateSpeed(speed)
                    task.wait(0.3)
                end
                
                if currentSpeed >= 200 then
                    addLog("✅ Speed 200!", Color3.fromRGB(100, 255, 100))
                    isOnTreadmill = false
                    jumpFromTreadmill()
                end
            else
                addLog("⚠️ Treadmill tidak ditemukan!", Color3.fromRGB(255, 200, 100))
            end
        else
            if isOnTreadmill then
                isOnTreadmill = false
                jumpFromTreadmill()
            end
        end
    end
end

-- =========================================================
-- BEST EGG DETECTION
-- =========================================================
function checkBestEggSpawn()
    while isRunning and config.bestEggMode do
        task.wait(2)
        local eggs = findEggs()
        for _, egg in ipairs(eggs) do
            if egg.rarity == "Divine" or egg.rarity == "Eternal" or egg.rarity == "Secret" then
                local label = rarityData[egg.rarity] and rarityData[egg.rarity].label or egg.rarity
                addLog("🎉 " .. label .. " SPAWN!", Color3.fromRGB(255, 215, 0))
                updateEgg(label .. " ⭐", Color3.fromRGB(255, 215, 0))
                break
            end
        end
    end
end

-- =========================================================
-- ANTI HIT
-- =========================================================
function antiHitLoop()
    if not config.antiHit then return end
    addLog("🛡️ Anti Hit AKTIF!", Color3.fromRGB(100, 200, 255))
    
    humanoid.HealthChanged:Connect(function(health)
        if hasEgg and health < 20 then
            humanoid.Health = 80
            humanoid.BreakJointsOnDeath = false
        end
    end)
end

-- =========================================================
-- START SCRIPT
-- =========================================================
function startScript()
    if isRunning then return end
    isRunning = true
    
    updateStatus("🟢 SCRIPT AKTIF!", Color3.fromRGB(100, 255, 100))
    addLog("🔥 Script mulai!", Color3.fromRGB(255, 200, 50))
    
    task.spawn(autoTreadmillLoop)
    task.spawn(autoStealLoop)
    task.spawn(checkBestEggSpawn)
    task.spawn(antiHitLoop)
    
    ui.startBtn.Text = "⏳ RUNNING..."
    ui.startBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    ui.startBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
end

-- =========================================================
-- BUTTON START
-- =========================================================
ui.startBtn.MouseButton1Click:Connect(function()
    startScript()
end)

-- =========================================================
-- READY
-- =========================================================
updateStatus("🟡 TEKAN START!", Color3.fromRGB(255, 200, 50))
addLog("📌 Siap berburu telur!", Color3.fromRGB(200, 200, 200))
updateSpeed(16)
updateEgg("❌ Tidak ada", Color3.fromRGB(200, 200, 200))

print("🥚 EGG HUNTER PRO - READY!")
