-- =========================================================
-- 🥚 EGG HUNTER - BAGIAN 1/5: CONFIG, ZONE, SPEED
-- =========================================================

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- =========================================================
-- KONFIGURASI
-- =========================================================
local config = {
    autoSteal = false,
    autoTreadmill = false,
    antiHit = false,
    bestEggMode = false,
    autoReturn = false,
    targetSpeed = 50000000000,
}

local hasEgg = false
local isOnTreadmill = false
local isRunning = false
local currentSpeed = 0
local lastDetectedEgg = nil

-- =========================================================
-- ZONA LIST
-- =========================================================
local zones = {
    {name = "Forest", speedReq = 0, rarities = {"Common", "Uncommon"}},
    {name = "Lake", speedReq = 900, rarities = {"Uncommon", "Rare"}},
    {name = "Desert", speedReq = 10000, rarities = {"Rare", "Epic"}},
    {name = "Jungle", speedReq = 40000, rarities = {"Epic", "Legendary"}},
    {name = "Snow", speedReq = 170000, rarities = {"Legendary", "Mythic"}},
    {name = "Volcano", speedReq = 700000, rarities = {"Mythic", "Cosmic"}},
    {name = "Abyss Ocean", speedReq = 2500000, rarities = {"Cosmic", "Secret"}},
    {name = "Prehistoric", speedReq = 18000000, rarities = {"Secret", "Eternal"}},
    {name = "Cosmic", speedReq = 700000000, rarities = {"Eternal", "Divine"}},
    {name = "Cherry Blossom", speedReq = 2500000000, rarities = {"Divine"}},
    {name = "Titan Temple", speedReq = 40000000000, rarities = {"Divine"}},
    {name = "Final Zone", speedReq = 7000000000, rarities = {"Divine"}, safeSpeed = 50000000000},
}

local bestEggPriority = {"Divine", "Eternal", "Secret", "Cosmic", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common"}
local rarityData = {
    Common = "⬜ Common", Uncommon = "🟩 Uncommon", Rare = "🟦 Rare",
    Epic = "🟪 Epic", Legendary = "🟧 Legendary", Mythic = "🟣 Mythic",
    Cosmic = "🌌 Cosmic", Secret = "🔴 Secret", Eternal = "♾️ Eternal", Divine = "👼 Divine",
}

-- =========================================================
-- BACA SPEED
-- =========================================================
local function getSpeed()
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        local spd = ls:FindFirstChild("Speed")
        if spd then return spd.Value or 0 end
    end
    local data = player:FindFirstChild("Data")
    if data then
        local spd = data:FindFirstChild("Speed")
        if spd then return spd.Value or 0 end
    end
    return humanoid and humanoid.WalkSpeed or 16
end

local function formatNumber(num)
    if num >= 1e9 then return string.format("%.1fB", num / 1e9) end
    if num >= 1e6 then return string.format("%.1fM", num / 1e6) end
    if num >= 1e3 then return string.format("%.1fK", num / 1e3) end
    return tostring(num)
end

-- =========================================================
-- 🥚 EGG HUNTER - BAGIAN 2/5: WORKSPACE + MOVEMENT
-- =========================================================

-- =========================================================
-- FUNGSI TARGET WORKSPACE
-- =========================================================
local function getTreadmill()
    local tread = workspace:FindFirstChild("Treadmill")
    if not tread then return nil end
    return tread:FindFirstChild("TreadmillPart") or tread:FindFirstChildWhichIsA("BasePart")
end

local function getSafeZone()
    local safe = workspace:FindFirstChild("SafeZone") or workspace:FindFirstChild("Base")
    if not safe then return nil end
    return safe:FindFirstChildWhichIsA("BasePart")
end

local function getEggs()
    local eggs = {}
    local eggsFolder = workspace:FindFirstChild("Eggs")
    if not eggsFolder then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and string.find(obj.Name:lower(), "egg") then
                local part = obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    table.insert(eggs, {
                        model = obj,
                        part = part,
                        position = part.Position,
                        name = obj.Name,
                        rarity = "Common",
                        prompt = obj:FindFirstChildWhichIsA("ProximityPrompt"),
                        click = obj:FindFirstChildWhichIsA("ClickDetector"),
                    })
                end
            end
        end
        return eggs
    end
    
    for _, egg in pairs(eggsFolder:GetChildren()) do
        if egg:IsA("Model") then
            local part = egg:FindFirstChildWhichIsA("BasePart")
            if part then
                local rarity = "Common"
                for _, r in ipairs(bestEggPriority) do
                    if string.find(egg.Name, r) then
                        rarity = r
                        break
                    end
                end
                table.insert(eggs, {
                    model = egg,
                    part = part,
                    position = part.Position,
                    name = egg.Name,
                    rarity = rarity,
                    prompt = egg:FindFirstChildWhichIsA("ProximityPrompt"),
                    click = egg:FindFirstChildWhichIsA("ClickDetector"),
                })
            end
        end
    end
    return eggs
end

local function getBestEgg(eggs)
    if #eggs == 0 then return nil end
    for _, rarity in ipairs(bestEggPriority) do
        for _, egg in ipairs(eggs) do
            if egg.rarity == rarity then
                return egg
            end
        end
    end
    return eggs[1]
end

local function getGuardian()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and string.find(obj.Name:lower(), "guardian") then
            local part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                return {
                    model = obj,
                    part = part,
                    position = part.Position,
                }
            end
        end
    end
    return nil
end

local function hasEggInHand()
    if not character then return false end
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("BasePart") and string.find(child.Name:lower(), "egg") then
            return true, child
        end
        if child:IsA("Tool") and string.find(child.Name:lower(), "egg") then
            return true, child
        end
    end
    return false
end

-- =========================================================
-- FUNGSI GERAK
-- =========================================================
local function walkTo(position)
    if not position or not rootPart then return end
    local dist = (rootPart.Position - position).Magnitude
    if dist < 5 then return end
    rootPart.CFrame = CFrame.lookAt(rootPart.Position, position)
    local tween = game:GetService("TweenService"):Create(
        rootPart,
        TweenInfo.new(math.min(dist / 60, 3), Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(position)}
    )
    tween:Play()
    tween.Completed:Wait()
end

local function jumpFromTreadmill()
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

local function runToSafeZone()
    local safe = getSafeZone()
    if not safe then return end
    
    isRunning = true
    if humanoid then
        humanoid.WalkSpeed = math.min(humanoid.WalkSpeed + 50, 250)
    end
    
    walkTo(safe.Position + Vector3.new(0, 3, 0))
    
    if humanoid then
        humanoid.WalkSpeed = 16
    end
    
    hasEgg = false
    isRunning = false
end

local function interactWithEgg(egg)
    if not egg then return false end
    if egg.prompt then
        egg.prompt:InputHoldBegin(player)
        task.wait(0.3)
        egg.prompt:InputHoldEnd(player)
        return true
    end
    if egg.click then
        fireclickdetector(egg.click)
        return true
    end
    if egg.part then
        firetouchinterest(rootPart, egg.part, 0)
        task.wait(0.2)
        firetouchinterest(rootPart, egg.part, 1)
        return true
    end
    return false
end

-- =========================================================
-- 🥚 EGG HUNTER - BAGIAN 3/5: ANTI HIT + TREADMILL
-- =========================================================

-- =========================================================
-- ANTI HIT
-- =========================================================
local function startAntiHit()
    if not config.antiHit then return end
    
    humanoid.HealthChanged:Connect(function(health)
        if hasEgg and health < 20 then
            humanoid.Health = 100
        end
    end)
    
    local lastPosition = rootPart.Position
    task.spawn(function()
        while true do
            task.wait(0.05)
            if hasEgg then
                local currentPos = rootPart.Position
                if (currentPos - lastPosition).Magnitude > 10 then
                    rootPart.CFrame = CFrame.new(lastPosition)
                    if rootPart:FindFirstChild("BodyVelocity") then
                        rootPart.BodyVelocity:Destroy()
                    end
                end
                lastPosition = rootPart.Position
            end
        end
    end)
end

-- =========================================================
-- AUTO TREADMILL
-- =========================================================
local function startTreadmillLoop()
    while config.autoTreadmill do
        if hasEgg then
            if isOnTreadmill then
                isOnTreadmill = false
                jumpFromTreadmill()
            end
            task.wait(1)
            continue
        end
        
        local speed = getSpeed()
        if speed >= config.targetSpeed then
            if isOnTreadmill then
                isOnTreadmill = false
                jumpFromTreadmill()
            end
            task.wait(2)
            continue
        end
        
        local tread = getTreadmill()
        if tread then
            walkTo(tread.Position + Vector3.new(0, 3, 0))
            task.wait(0.5)
            isOnTreadmill = true
            task.wait(3)
        else
            task.wait(2)
        end
    end
end

-- =========================================================
-- 🥚 EGG HUNTER - BAGIAN 4/5: STEAL + BEST EGG + RESPAWN
-- =========================================================

-- =========================================================
-- AUTO STEAL
-- =========================================================
local function startStealLoop()
    while config.autoSteal do
        if not rootPart or not rootPart.Parent then
            task.wait(1)
            continue
        end
        
        local has, _ = hasEggInHand()
        if has then
            hasEgg = true
            
            local guard = getGuardian()
            if guard then
                local dist = (rootPart.Position - guard.position).Magnitude
                if dist < 50 then
                    runToSafeZone()
                end
            end
            
            task.wait(1)
            continue
        end
        
        local eggs = getEggs()
        if #eggs > 0 then
            local target = getBestEgg(eggs)
            if target then
                if (rootPart.Position - target.position).Magnitude > 5 then
                    walkTo(target.position)
                end
                
                if interactWithEgg(target) then
                    -- telur diambil
                end
                
                task.wait(0.5)
            end
        end
        
        task.wait(0.5)
    end
end

-- =========================================================
-- BEST EGG DETECTION
-- =========================================================
local function startBestEggLoop()
    while config.bestEggMode do
        local eggs = getEggs()
        for _, egg in ipairs(eggs) do
            if egg.rarity == "Divine" or egg.rarity == "Eternal" or egg.rarity == "Secret" then
                local id = tostring(egg.model)
                if id ~= lastDetectedEgg then
                    lastDetectedEgg = id
                end
                break
            end
        end
        task.wait(2)
    end
end

-- =========================================================
-- RESPAWN HANDLER
-- =========================================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
end)

-- =========================================================
-- 🥚 EGG HUNTER - BAGIAN 5/5: GUI + SPEED MONITOR
-- =========================================================

-- =========================================================
-- GUI
-- =========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player.PlayerGui
screenGui.Name = "EggHunter"
screenGui.ResetOnSpawn = false

for _, v in pairs(player.PlayerGui:GetChildren()) do
    if v.Name == "EggHunter" and v ~= screenGui then
        v:Destroy()
    end
end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 300)
frame.Position = UDim2.new(0.5, -130, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 35)
frame.BackgroundTransparency = 0.05
frame.Parent = screenGui
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 200, 50)
stroke.Thickness = 1.5
stroke.Transparency = 0.4
stroke.Parent = frame

-- HEADER
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
header.BackgroundTransparency = 0.15
header.Parent = frame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.Text = "🥚 EGG HUNTER"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.Bold
title.TextSize = 14
title.BackgroundTransparency = 1
title.Parent = header

-- SPEED
local speedDisplay = Instance.new("TextLabel")
speedDisplay.Size = UDim2.new(0.9, 0, 0, 16)
speedDisplay.Position = UDim2.new(0.05, 0, 0, 35)
speedDisplay.Text = "⚡ Speed: 0"
speedDisplay.TextColor3 = Color3.fromRGB(100, 255, 100)
speedDisplay.Font = Enum.Font.SourceSansBold
speedDisplay.TextSize = 12
speedDisplay.BackgroundTransparency = 1
speedDisplay.Parent = frame

-- TOGGLES
local toggles = {
    {name = "🥚 Auto Steal", key = "autoSteal"},
    {name = "🏃 Treadmill", key = "autoTreadmill"},
    {name = "🛡️ Anti Hit", key = "antiHit"},
    {name = "⭐ Best Egg", key = "bestEggMode"},
    {name = "🏠 Auto Return", key = "autoReturn"},
}

for i, t in ipairs(toggles) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 26)
    btn.Position = UDim2.new(0.05, 0, 0, 56 + (i-1) * 30)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
    btn.Text = "❌ " .. t.name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 11
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        config[t.key] = state
        btn.BackgroundColor3 = state and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(40, 40, 70)
        btn.Text = (state and "✅ " or "❌ ") .. t.name
        
        if state then
            if t.key == "antiHit" then
                task.spawn(startAntiHit)
            elseif t.key == "autoTreadmill" then
                task.spawn(startTreadmillLoop)
            elseif t.key == "autoSteal" then
                task.spawn(startStealLoop)
            elseif t.key == "bestEggMode" then
                task.spawn(startBestEggLoop)
            end
        end
    end)
end

-- LOG
local logFrame = Instance.new("Frame")
logFrame.Size = UDim2.new(0.9, 0, 0, 28)
logFrame.Position = UDim2.new(0.05, 0, 0, 215)
logFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
logFrame.BackgroundTransparency = 0.5
logFrame.Parent = frame
Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0, 6)

local logText = Instance.new("TextLabel")
logText.Name = "LogText"
logText.Size = UDim2.new(0.95, 0, 1, -4)
logText.Position = UDim2.new(0.025, 0, 0, 2)
logText.Text = "📌 Toggle ON/OFF"
logText.TextColor3 = Color3.fromRGB(200, 200, 200)
logText.Font = Enum.Font.SourceSans
logText.TextSize = 10
logText.TextXAlignment = Enum.TextXAlignment.Left
logText.TextWrapped = true
logText.BackgroundTransparency = 1
logText.Parent = logFrame

local function updateLog(text)
    if logText then
        logText.Text = "📌 " .. text
    end
end

-- FOOTER
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, 0, 0, 12)
footer.Position = UDim2.new(0, 0, 0, 285)
footer.Text = "⚡ Target: 50B"
footer.TextColor3 = Color3.fromRGB(255, 255, 255)
footer.TextTransparency = 0.5
footer.Font = Enum.Font.SourceSans
footer.TextSize = 9
footer.BackgroundTransparency = 1
footer.Parent = frame

-- =========================================================
-- SPEED MONITOR
-- =========================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        local speed = getSpeed()
        speedDisplay.Text = "⚡ Speed: " .. formatNumber(speed)
    end
end)

updateLog("📌 Aktifkan fitur di atas")
