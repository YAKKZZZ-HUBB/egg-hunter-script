-- =========================================================
-- 🥚 ULTIMATE EGG HUNTER - ALL IN ONE 🥚
-- Fitur: Auto Steal | Anti Hit | Auto Treadmill | Best Egg Detection
-- =========================================================

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- =========================================================
-- 1. KONFIGURASI
-- =========================================================
local config = {
    autoSteal = true,
    stealRadius = 250,
    antiHit = true,
    antiDrop = true,
    autoTreadmill = true,
    targetSpeed = 200,
    treadmillCheckInterval = 2,
    bestEggMode = true,
    autoTakeBestEgg = true,
    notifyBestEgg = true,
    autoReturn = true,
    basePosition = nil,
    returnRadius = 80,
    showESP = true,
    autoHeal = true,
    healThreshold = 30,
    delay = 0.3,
}

-- =========================================================
-- 2. RARITY DATA
-- =========================================================
local rarityData = {
    ["Common"] = { color = Color3.fromRGB(128, 128, 128), priority = 9, score = 1, label = "⬜ Common" },
    ["Uncommon"] = { color = Color3.fromRGB(0, 255, 0), priority = 8, score = 2, label = "🟩 Uncommon" },
    ["Rare"] = { color = Color3.fromRGB(0, 150, 255), priority = 7, score = 3, label = "🟦 Rare" },
    ["Epic"] = { color = Color3.fromRGB(128, 0, 255), priority = 6, score = 4, label = "🟪 Epic" },
    ["Legendary"] = { color = Color3.fromRGB(255, 150, 0), priority = 5, score = 5, label = "🟧 Legendary" },
    ["Mythic"] = { color = Color3.fromRGB(255, 0, 150), priority = 4, score = 6, label = "🟣 Mythic" },
    ["Cosmic"] = { color = Color3.fromRGB(0, 255, 255), priority = 3, score = 7, label = "🌌 Cosmic" },
    ["Secret"] = { color = Color3.fromRGB(255, 0, 0), priority = 1, score = 8, label = "🔴 Secret" },
    ["Eternal"] = { color = Color3.fromRGB(255, 215, 0), priority = 2, score = 9, label = "♾️ Eternal" },
    ["Divine"] = { color = Color3.fromRGB(255, 50, 50), priority = 1, score = 10, label = "👼 Divine" },
}

-- =========================================================
-- 3. VARIABEL
-- =========================================================
local hasEgg = false
local currentEgg = nil
local currentEggRarity = nil
local isReturning = false
local isStealing = false
local isOnTreadmill = false
local currentSpeed = 16
local bestEggFound = false
local bestEggData = nil
local spawnedEggs = {}

-- =========================================================
-- 4. FUNGSI DASAR
-- =========================================================
function getPlayerMoney()
    local data = player:FindFirstChild("Data")
    if data then
        local money = data:FindFirstChild("Money") or data:FindFirstChild("Coins") or data:FindFirstChild("Cash")
        if money then return money.Value or 0 end
    end
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local money = leaderstats:FindFirstChild("Money") or leaderstats:FindFirstChild("Coins") or leaderstats:FindFirstChild("Cash")
        if money then return money.Value or 0 end
    end
    return 0
end

function getCurrentSpeed()
    return humanoid and humanoid.WalkSpeed or 16
end

function getServerId()
    return game.JobId
end

-- =========================================================
-- 5. FUNGSI SPEED
-- =========================================================
function applySpeed(speed)
    local targetSpeed = speed or config.targetSpeed
    targetSpeed = math.min(targetSpeed, 200)
    targetSpeed = math.max(targetSpeed, 16)
    if humanoid then
        humanoid.WalkSpeed = targetSpeed
        currentSpeed = targetSpeed
    end
    return targetSpeed
end

function resetSpeed()
    if humanoid then
        humanoid.WalkSpeed = 16
        currentSpeed = 16
    end
end

-- =========================================================
-- 6. FIND TREADMILL
-- =========================================================
function findTreadmill()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if string.find(name, "treadmill") or string.find(name, "tread") or 
               string.find(name, "mill") or string.find(name, "trainer") or string.find(name, "gym") then
                if obj:FindFirstChild("HumanoidRootPart") then return obj.HumanoidRootPart
                elseif obj:IsA("BasePart") then return obj end
            end
        end
    end
    return nil
end

function getTreadmillPosition()
    local tread = findTreadmill()
    if tread then return tread.Position end
    return nil
end

function jumpFromTreadmill()
    if humanoid then
        humanoid.Jump = true
        task.wait(0.2)
        humanoid.Jump = false
        local velocity = Instance.new("BodyVelocity")
        velocity.Velocity = rootPart.CFrame.LookVector * 30 + Vector3.new(0, 15, 0)
        velocity.MaxForce = Vector3.new(4000, 4000, 4000)
        velocity.Parent = rootPart
        task.wait(0.3)
        velocity:Destroy()
    end
end

-- =========================================================
-- 7. AUTO TREADMILL
-- =========================================================
function autoTreadmill()
    if not config.autoTreadmill then return end
    print("🏃 Auto Treadmill AKTIF! Target Speed: 200")
    
    while task.wait(config.treadmillCheckInterval) do
        if hasEgg then 
            if isOnTreadmill then isOnTreadmill = false; jumpFromTreadmill() end
            continue 
        end
        if isStealing or isReturning then continue end
        
        local eggs = findEggs()
        local hasTarget = false
        for _, egg in ipairs(eggs) do
            if isRarityTargeted(egg.rarity) or (config.bestEggMode and isBestEgg(egg.rarity)) then
                if (rootPart.Position - egg.position).Magnitude < config.stealRadius then
                    hasTarget = true; break
                end
            end
        end
        
        if hasTarget then
            if isOnTreadmill then
                print("🥚 TELUR DITEMUKAN! LONCAT!")
                jumpFromTreadmill(); isOnTreadmill = false
            end
            continue
        end
        
        local currentSpeed = getCurrentSpeed()
        if currentSpeed < config.targetSpeed then
            local treadPos = getTreadmillPosition()
            if treadPos then
                if (rootPart.Position - treadPos).Magnitude > 20 then
                    teleportTo(treadPos)
                    task.wait(0.5)
                end
                
                if (rootPart.Position - treadPos).Magnitude < 20 then
                    isOnTreadmill = true
                    for speed = currentSpeed, config.targetSpeed, 5 do
                        if hasEgg or isStealing or isReturning then break end
                        
                        local eggs2 = findEggs()
                        local found = false
                        for _, egg in ipairs(eggs2) do
                            if isRarityTargeted(egg.rarity) or (config.bestEggMode and isBestEgg(egg.rarity)) then
                                if (rootPart.Position - egg.position).Magnitude < config.stealRadius then
                                    found = true; break
                                end
                            end
                        end
                        if found then
                            print("🥚 TELUR SPAWN! LONCAT!")
                            jumpFromTreadmill(); isOnTreadmill = false
                            break
                        end
                        
                        applySpeed(speed)
                        task.wait(0.3)
                        if speed >= config.targetSpeed then
                            print("✅ Speed 200 tercapai!")
                            isOnTreadmill = false
                            jumpFromTreadmill()
                            break
                        end
                    end
                end
            end
        elseif isOnTreadmill then
            isOnTreadmill = false
            jumpFromTreadmill()
        end
    end
end

-- =========================================================
-- 8. BEST EGG DETECTION
-- =========================================================
local bestEggPriority = {"Divine", "Eternal", "Secret", "Cosmic", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common"}

function isBestEgg(rarity)
    if not config.bestEggMode then return false end
    for _, r in ipairs(bestEggPriority) do
        if r == rarity then return true end
    end
    return false
end

function getRanking(rarity)
    for i, r in ipairs(bestEggPriority) do
        if r == rarity then return i end
    end
    return 999
end

function findBestEgg(eggs)
    if #eggs == 0 then return nil end
    local best = nil
    local bestRank = 999
    for _, egg in ipairs(eggs) do
        local rank = getRanking(egg.rarity)
        if rank < bestRank then bestRank = rank; best = egg end
    end
    return best
end

function getBestEggInServer()
    return findBestEgg(findEggs())
end

function detectBestEggByVisual(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    
    local size = obj.Size
    local volume = size.X * size.Y * size.Z
    if volume > 50 then return true end
    
    for _, child in pairs(obj:GetChildren()) do
        if child:IsA("PointLight") or child:IsA("SpotLight") then
            return true
        end
    end
    
    for _, child in pairs(obj.Parent and obj.Parent:GetChildren() or {}) do
        if child:IsA("ParticleEmitter") or child:IsA("Fire") or child:IsA("Sparkles") then
            return true
        end
    end
    
    return false
end

-- =========================================================
-- 9. NOTIFIKASI BEST EGG
-- =========================================================
function checkBestEggSpawn()
    if not config.bestEggMode or not config.notifyBestEgg then return end
    
    print("👁️ Best Egg Detection AKTIF!")
    
    while task.wait(1) do
        if not config.autoSteal then continue end
        
        local eggs = findEggs()
        local bestEgg = nil
        
        for _, egg in ipairs(eggs) do
            local isBestByRarity = isBestEgg(egg.rarity)
            local isBestByVisual = detectBestEggByVisual(egg.object)
            
            if isBestByRarity or isBestByVisual then
                if not bestEgg then
                    bestEgg = egg
                else
                    local currentRank = getRanking(egg.rarity)
                    local bestRank = getRanking(bestEgg.rarity)
                    if currentRank < bestRank then
                        bestEgg = egg
                    end
                end
            end
        end
        
        if bestEgg then
            local rarity = bestEgg.rarity
            local label = rarityData[rarity] and rarityData[rarity].label or rarity
            local eggId = bestEgg.object and bestEgg.object.Name or ""
            
            local isNew = true
            for _, seen in ipairs(spawnedEggs) do
                if seen == eggId then isNew = false; break end
            end
            
            if isNew then
                table.insert(spawnedEggs, eggId)
                local dist = (rootPart.Position - bestEgg.position).Magnitude
                
                print("=" .. string.rep("=", 60))
                print("🎉🎉🎉 TELUR TERBAIK SPAWN! 🎉🎉🎉")
                print("📌 Rarity: " .. label)
                print("📌 Jarak: " .. math.floor(dist) .. " stud")
                print("📌 Server: " .. string.sub(getServerId(), 1, 12) .. "...")
                print("=" .. string.rep("=", 60))
                
                spawnVisualNotif(label, rarity)
                
                bestEggFound = true
                bestEggData = bestEgg
                
                if config.autoTakeBestEgg then
                    takeBestEgg(bestEgg)
                end
            end
        else
            bestEggFound = false
            bestEggData = nil
        end
        
        if #spawnedEggs > 100 then table.remove(spawnedEggs, 1) end
    end
end

-- =========================================================
-- 10. NOTIFIKASI VISUAL DI LAYAR
-- =========================================================
function spawnVisualNotif(label, rarity)
    local data = rarityData[rarity]
    local color = data and data.color or Color3.fromRGB(255, 215, 0)
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = player.PlayerGui
    screenGui.Name = "BestEggNotif"
    screenGui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 120)
    frame.Position = UDim2.new(0.5, -200, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.2
    frame.Parent = screenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    
    local glow = Instance.new("UIStroke")
    glow.Color = color
    glow.Thickness = 3
    glow.Transparency = 0.3
    glow.Parent = frame
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 60, 0, 60)
    icon.Position = UDim2.new(0.05, 0, 0.5, -30)
    icon.Text = "🥚"
    icon.TextSize = 50
    icon.BackgroundTransparency = 1
    icon.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0.7, 0, 0, 30)
    titleLabel.Position = UDim2.new(0.25, 0, 0.15, 0)
    titleLabel.Text = "🎉 TELUR TERBAIK SPAWN!"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.Font = Enum.Font.Bold
    titleLabel.TextSize = 18
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = frame
    
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(0.7, 0, 0, 30)
    rarityLabel.Position = UDim2.new(0.25, 0, 0.45, 0)
    rarityLabel.Text = label
    rarityLabel.TextColor3 = color
    rarityLabel.Font = Enum.Font.Bold
    rarityLabel.TextSize = 16
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Parent = frame
    
    task.wait(5)
    for i = 1, 20 do
        frame.BackgroundTransparency = 0.2 + (i / 20) * 0.8
        task.wait(0.05)
    end
    screenGui:Destroy()
end

-- =========================================================
-- 11. TAKE BEST EGG
-- =========================================================
function takeBestEgg(bestEgg)
    if not bestEgg or hasEgg or isStealing or isReturning then return end
    
    print("🎯 Mengambil telur terbaik!")
    isStealing = true
    
    if isOnTreadmill then
        jumpFromTreadmill()
        isOnTreadmill = false
        task.wait(0.3)
    end
    
    local pos = bestEgg.position
    if pos then
        applySpeed(config.targetSpeed)
        if (rootPart.Position - pos).Magnitude > 50 then
            teleportTo(pos)
        else
            walkTo(pos)
        end
        task.wait(0.3)
        
        hasEgg = true
        currentEgg = bestEgg
        currentEggRarity = bestEgg.rarity
        local label = rarityData[currentEggRarity] and rarityData[currentEggRarity].label or currentEggRarity
        print("✅ " .. label .. " berhasil diambil!")
        
        if config.autoReturn then autoReturnToBase() end
        isStealing = false
        bestEggFound = false
    end
end

-- =========================================================
-- 12. FIND EGGS
-- =========================================================
function findEggs()
    local eggs = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Parent then
            local name = obj.Name:lower()
            local parentName = obj.Parent.Name:lower()
            local fullName = (parentName .. " " .. name):lower()
            
            local isEgg = string.find(fullName, "egg") or string.find(fullName, "telur") or string.find(fullName, "nest")
            local isHuge = string.find(fullName, "huge") or string.find(fullName, "raksasa")
            local isCosmic = string.find(fullName, "cosmic") or string.find(fullName, "abyss")
            local isEternal = string.find(fullName, "eternal")
            local isDivine = string.find(fullName, "divine")
            local isSecret = string.find(fullName, "secret") or string.find(fullName, "kitsune")
            
            if isEgg or isHuge or isCosmic or isEternal or isDivine or isSecret then
                local rarity = getEggRarity(obj, fullName, isHuge, isCosmic, isEternal, isDivine, isSecret)
                if rarity then
                    table.insert(eggs, {
                        object = obj,
                        position = obj.Position,
                        rarity = rarity,
                        name = obj.Parent.Name or obj.Name,
                        distance = (rootPart.Position - obj.Position).Magnitude,
                        size = obj.Size,
                    })
                end
            end
        end
    end
    return eggs
end

function getEggRarity(obj, fullName, isHuge, isCosmic, isEternal, isDivine, isSecret)
    if isSecret or string.find(fullName, "secret") or string.find(fullName, "kitsune") then return "Secret" end
    if isDivine or string.find(fullName, "divine") or string.find(fullName, "ilahi") then return "Divine" end
    if isEternal or string.find(fullName, "eternal") or string.find(fullName, "abadi") then return "Eternal" end
    if isCosmic or string.find(fullName, "cosmic") or string.find(fullName, "kosmik") then return "Cosmic" end
    
    if isHuge or (obj:IsA("BasePart") and obj.Size and obj.Size.Magnitude > 5) then
        local volume = obj.Size.X * obj.Size.Y * obj.Size.Z
        if volume > 200 then return "Divine"
        elseif volume > 100 then return "Eternal"
        elseif volume > 50 then return "Cosmic" end
    end
    
    if detectBestEggByVisual(obj) then
        local size = obj.Size
        local volume = size.X * size.Y * size.Z
        if volume > 30 then return "Eternal"
        elseif volume > 15 then return "Cosmic"
        else return "Mythic" end
    end
    
    if string.find(fullName, "mythic") then return "Mythic" end
    if string.find(fullName, "legend") then return "Legendary" end
    if string.find(fullName, "epic") then return "Epic" end
    if string.find(fullName, "rare") then return "Rare" end
    if string.find(fullName, "uncommon") then return "Uncommon" end
    return "Common"
end

function isRarityTargeted(rarity)
    return true
end

-- =========================================================
-- 13. AUTO STEAL
-- =========================================================
function autoStealEgg()
    if not config.autoSteal then return end
    print("🥚 Auto Steal AKTIF!")
    
    while task.wait(0.3) do
        if isReturning or hasEgg then continue end
        
        local eggs = findEggs()
        if #eggs == 0 then
            if config.bestEggMode then
                local bestEgg = getBestEggInServer()
                if bestEgg then takeBestEgg(bestEgg) end
            end
            continue
        end
        
        local targetEgg = nil
        if config.bestEggMode then
            targetEgg = findBestEgg(eggs)
        end
        
        if not targetEgg and #eggs > 0 then
            local bestScore = 0
            for _, egg in ipairs(eggs) do
                local score = rarityData[egg.rarity] and rarityData[egg.rarity].score or 0
                if score > bestScore then
                    bestScore = score
                    targetEgg = egg
                end
            end
        end
        
        if targetEgg then
            isStealing = true = true
            
            if isOnTreadmill then
                print("🥚 TELUR DITEMUKAN! LONCAT!")
                jumpFromTreadmill()
                isOnTreadmill = false
                task.wait(0.3)
            end
            
            local pos = targetEgg.position
            local rarity = targetEgg.rarity
            local label = rarityData[rarity] and rarityData[rarity].label or rarity
            
            if pos then
                applySpeed(config.targetSpeed)
                if (rootPart.Position - pos).Magnitude > 50 then
                    teleportTo(pos)
                else
                    walkTo(pos)
                end
                task.wait(0.3)
                
                hasEgg = true
                currentEgg = targetEgg
                currentEggRarity = rarity
                print("✅ " .. label .. " berhasil diambil!")
                
                if config.autoReturn then 
                    autoReturnToBase() 
                end
                isStealing = false
            end
        end
    end
end


-- =========================================================
-- 14. AUTO RETURN BASE
-- =========================================================
function autoReturnToBase()
    if not config.autoReturn or isReturning then return end
    
    if not config.basePosition then
        config.basePosition = findBase()
        if not config.basePosition then 
            config.basePosition = Vector3.new(0, 5, 0) 
        end
    end
    
    isReturning = true
    local label = rarityData[currentEggRarity] and rarityData[currentEggRarity].label or currentEggRarity
    print("🏠 Return Base... (" .. label .. ")")
    applySpeed(config.targetSpeed)
    
    local basePos = config.basePosition
    while (rootPart.Position - basePos).Magnitude > config.returnRadius and hasEgg do
        if (rootPart.Position - basePos).Magnitude < 100 then
            teleportTo(basePos)
        else
            walkTo(basePos)
        end
        task.wait(0.3)
    end
    
    if hasEgg then
        print("🏠 Base! 🥚 " .. label)
        hasEgg = false
        isReturning = false
        currentEgg = nil
        currentEggRarity = nil
        resetSpeed()
        print("✅ Telur " .. label .. " disimpan!")
        
        if currentEggRarity == "Divine" or currentEggRarity == "Eternal" or currentEggRarity == "Secret" then
            print("=" .. string.rep("=", 40))
            print("🎉🎉🎉 SELAMAT! DAPAT " .. label .. " 🎉🎉🎉")
            print("=" .. string.rep("=", 40))
        end
    else
        print("⚠️ Telur hilang!")
        isReturning = false
    end
end

-- =========================================================
-- 15. ANTI HIT & DROP
-- =========================================================
function antiHitAndDrop()
    if not config.antiHit and not config.antiDrop then return end
    print("🛡️ Anti Hit & Drop AKTIF!")
    
    humanoid.HealthChanged:Connect(function(health)
        if hasEgg then
            if config.antiDrop then
                task.spawn(function()
                    wait(0.1)
                    local has, _ = hasEggInHand()
                    if not has and currentEgg and currentEgg.position then
                        teleportTo(currentEgg.position)
                        task.wait(0.2)
                        firetouchinterest(rootPart, currentEgg.object, 0)
                        task.wait(0.1)
                        firetouchinterest(rootPart, currentEgg.object, 1)
                        hasEgg = true
                        print("🥚 Telur diambil lagi!")
                    end
                end)
            end
            if config.antiHit and health < 20 then
                humanoid.Health = 80
                humanoid.BreakJointsOnDeath = false
            end
        end
    end)
end

function hasEggInHand()
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("BasePart") and string.find(child.Name:lower(), "egg") then 
            return true, child 
        end
        if child:IsA("Tool") and string.find(child.Name:lower(), "egg") then 
            return true, child 
        end
    end
    return false, nil
end

-- =========================================================
-- 16. AUTO HEAL
-- =========================================================
function autoHeal()
    if not config.autoHeal then return end
    while task.wait(1) do
        if humanoid and humanoid.Health < config.healThreshold then
            print("💚 Heal... HP: " .. math.floor(humanoid.Health))
            humanoid:SetHealth(math.min(humanoid.Health + 10, humanoid.MaxHealth))
        end
    end
end

-- =========================================================
-- 17. TELEPORT FUNCTIONS
-- =========================================================
function teleportTo(position)
    if not position then return end
    rootPart.CFrame = CFrame.new(position)
    task.wait(config.delay)
end

function walkTo(position)
    if not position then return end
    local dist = (rootPart.Position - position).Magnitude
    if dist > 10 then
        local tween = game:GetService("TweenService"):Create(
            rootPart,
            TweenInfo.new(math.min(dist / currentSpeed * 2, 3), Enum.EasingStyle.Linear),
            {CFrame = CFrame.new(position)}
        )
        tween:Play()
        tween.Completed:Wait()
    else
        teleportTo(position)
    end
end

function findBase()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if string.find(name, "base") or string.find(name, "spawn") or 
               string.find(name, "home") or string.find(name, "hub") then
                if obj:FindFirstChild("HumanoidRootPart") then 
                    return obj.HumanoidRootPart.Position
                elseif obj:IsA("BasePart") then 
                    return obj.Position 
                end
            end
        end
    end
    return nil
end

-- =========================================================
-- 18. ESP
-- =========================================================
function eggESP()
    if not config.showESP then return end
    print("👁️ ESP AKTIF!")
    
    game:GetService("RunService").RenderStepped:Connect(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "EggESP" or obj.Name == "EggESPLabel" then 
                obj:Destroy() 
            end
        end
        
        local eggs = findEggs()
        for _, egg in ipairs(eggs) do
            local isBest = config.bestEggMode and isBestEgg(egg.rarity)
            local isVisualBest = detectBestEggByVisual(egg.object)
            
            if isBest or isVisualBest then
                local data = rarityData[egg.rarity]
                local color = data and data.color or Color3.fromRGB(255, 215, 0)
                local label = data and data.label or egg.rarity
                local dist = (rootPart.Position - egg.position).Magnitude
                
                if dist < 500 then
                    local box = Instance.new("BoxHandleAdornment")
                    box.Name = "EggESP"
                    box.Adornee = egg.object
                    box.Size = egg.size * 1.3 or Vector3.new(3, 3, 3)
                    box.Color3 = isBest and Color3.fromRGB(255, 215, 0) or color
                    box.Transparency = isBest and 0.1 or 0.3
                    box.ZIndex = 10
                    box.Parent = egg.object
                    
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "EggESPLabel"
                    billboard.Size = UDim2.new(0, 150, 0, 35)
                    billboard.Adornee = egg.object
                    billboard.StudsOffset = Vector3.new(0, egg.size.Y + 2 or 4, 0)
                    billboard.Parent = egg.object
                    
                    local labelText = Instance.new("TextLabel")
                    labelText.Size = UDim2.new(1, 0, 1, 0)
                    labelText.BackgroundTransparency = 0.5
                    labelText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    labelText.Text = "⭐ " .. label .. " | " .. math.floor(dist) .. "s"
                    labelText.TextColor3 = color
                    labelText.TextScaled = true
                    labelText.Font = Enum.Font.Bold
                    labelText.Parent = billboard
                end
            end
        end
    end)
end

-- =========================================================
-- 19. START SCRIPT
-- =========================================================
function startScript()
    print("=" .. string.rep("=", 60))
    print("🥚 ULTIMATE EGG HUNTER - ALL IN ONE 🥚")
    print("=" .. string.rep("=", 60))
    print("📌 Fitur:")
    print("   ✅ Auto Steal - Ambil telur otomatis")
    print("   ✅ Anti Hit & Drop - Kebal damage & telur aman")
    print("   ✅ Auto Treadmill - Naik speed ke 200")
    print("   ✅ Best Egg Detection - Deteksi telur terbaik")
    print("   ✅ Auto Take Best Egg - Langsung ambil")
    print("   ✅ Notifikasi Visual - Notif di layar")
    print("=" .. string.rep("=", 60))
    
    config.basePosition = findBase()
    if config.basePosition then
        print("🏠 Base ditemukan!")
    else
        config.basePosition = Vector3.new(0, 5, 0)
        print("⚠️ Base tidak ditemukan!")
    end
    
    applySpeed(config.targetSpeed)
    
    task.spawn(autoTreadmill)
    task.spawn(autoStealEgg)
    task.spawn(checkBestEggSpawn)
    task.spawn(antiHitAndDrop)
    task.spawn(autoHeal)
    if config.showESP then 
        task.spawn(eggESP) 
    end
    
    print("=" .. string.rep("=", 60))
    print("✅ SCRIPT READY!")
    print("📌 Speed: 200 (MAX SAFE!)")
    print("📌 Best Egg Detection: ON")
    print("=" .. string.rep("=", 60))
end

-- =========================================================
-- 20. JALANKAN SCRIPT
-- =========================================================
startScript()            

