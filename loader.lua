if not game:IsLoaded() then
    game.Loaded:Wait()
end

local BASE = 'https://raw.githubusercontent.com/YAKKZZZ-HUBB/egg-hunter-script/main/'

local games = {
    [107778070777162] = 'egg_hunter.lua',
}

local file = games[game.PlaceId]

if file then
    loadstring(game:HttpGet(BASE .. file))()
else
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "🥚 EGG HUNTER",
        Text = "❌ Game tidak didukung!",
        Duration = 3,
    })
    print("❌ Game tidak didukung! PlaceId: " .. game.PlaceId)
end
