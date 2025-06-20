local HttpService = cloneref(game:GetService("HttpService"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local Players = cloneref(game:GetService("Players"))
local TextChatService = cloneref(game:GetService("TextChatService"))
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChatSpyGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local ChatFrame = Instance.new("ScrollingFrame")
ChatFrame.Size = UDim2.new(0, 400, 0, 300)
ChatFrame.Position = UDim2.new(1, -410, 1, -310)
ChatFrame.BackgroundTransparency = 0.3
ChatFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ChatFrame.BorderSizePixel = 0
ChatFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ChatFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ChatFrame.ScrollBarThickness = 6
ChatFrame.Parent = ScreenGui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ChatFrame

local function AddMessage(playerName, messageText)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Code
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "[" .. playerName .. "]: " .. messageText
    label.Parent = ChatFrame

    task.delay(0.05, function()
        ChatFrame.CanvasPosition = Vector2.new(0, ChatFrame.AbsoluteCanvasSize.Y)
    end)
end
TextChatService.OnIncomingMessage = function(message)
    if message.TextSource then
        local player = game.Players:GetPlayerByUserId(message.TextSource.UserId)
        if player and player ~= game.Players.LocalPlayer then
            AddMessage(player.Name, message.Text)
        end
    end
end

local QueuedScript = [[
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xectray1/what/refs/heads/main/ok.lua"))()
]]
if queue_on_teleport then
    queue_on_teleport(QueuedScript)
end

local VisitedServers = {}

local function SaveVisitedServers()
    if writefile then
        writefile("VisitedServers.json", HttpService:JSONEncode(VisitedServers))
    end
end

local function LoadVisitedServers()
    if readfile and isfile("VisitedServers.json") then
        local data = readfile("VisitedServers.json")
        local success, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if success then
            VisitedServers = decoded
        end
    end
end

local function CleanWorkspace()
    task.spawn(function()
        while true do
            local booths = workspace:WaitForChild("Booths")
            for _, booth in pairs(booths:GetChildren()) do
                if booth:IsA("Model") then
                    local BlockCheck = booth:FindFirstChild("BlockCheck")
                    if BlockCheck then
                        BlockCheck:Destroy()
                    end
                end
            end

            local GroupWall = workspace:FindFirstChild("GroupWall")
            if GroupWall then
                GroupWall:Destroy()
            end

            for _, child in pairs(workspace:GetChildren()) do
                if child:IsA("TouchInterest") then
                    child:Destroy()
                end
            end

            task.wait(1)
        end
    end)
end

local function HookNamecall()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)

    local oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if method == "FireServer" and self.Name == "KillEvent" then
            return nil
        end

        if method == "FireServer" and self.Name == "IsAFK" then
            if args[1] == true then
                return nil
            end
        end

        return oldNamecall(self, ...)
    end)
end

local function PlayerOwnsBooth()
    local BoothsFolder = workspace:WaitForChild("Booths")
    for _, booth in pairs(BoothsFolder:GetChildren()) do
        if booth:IsA("Model") then
            local OwnerValue = booth:FindFirstChild("Owner")
            if OwnerValue and OwnerValue:IsA("StringValue") and OwnerValue.Value == LocalPlayer.Name then
                return true
            end
        end
    end
    return false
end

local function ClickAllAvailableBooths()
    local BoothsFolder = workspace:WaitForChild("Booths")
    local clicked = false
    for _, booth in pairs(BoothsFolder:GetChildren()) do
        if booth:IsA("Model") then
            local OwnerValue = booth:FindFirstChild("Owner")
            if not (OwnerValue and OwnerValue:IsA("StringValue") and OwnerValue.Value == LocalPlayer.Name) then
                local banner = booth:FindFirstChild("Banner")
                if banner then
                    local ClickDetector = banner:FindFirstChildOfClass("ClickDetector")
                    if ClickDetector then
                        fireclickdetector(ClickDetector)
                        clicked = true
                    end
                end
            end
        end
    end
    return clicked
end

local function UpdateBooth()
    task.delay(1, function()
        local args = {
            {
                desc = "gg, | yk9Y6nAW for chill friends (probably afk)",
                image = ""
            }
        }
        cloneref(game:GetService("ReplicatedStorage")):WaitForChild("Remotes"):WaitForChild("UpdateBooth"):FireServer(unpack(args))
    end)
end

local function IsAllowedColor(color)
    local isBlack = color.R < 0.1 and color.G < 0.1 and color.B < 0.1
    local isWhite = color.R > 0.9 and color.G > 0.9 and color.B > 0.9
    local isBrown = color.R > 0.3 and color.R < 0.6 and color.G > 0.2 and color.G < 0.4 and color.B < 0.2
    return isBlack or isWhite or isBrown
end

local function CheckPlayerForAllowedColors(player)
    local character = player.Character
    if not character then return false end

    local PartsToCheck = {"Head", "Torso", "UpperTorso", "LowerTorso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}

    for _, partName in ipairs(PartsToCheck) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            if IsAllowedColor(part.Color) then
                return true
            end
        end
    end
    return false
end

local function BlockUsers()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if CheckPlayerForAllowedColors(player) then
                local args = {
                    {player.Name}
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("BlockedUser"):FireServer(unpack(args))
            end
        end
    end
end

local function GetServers()
    local servers = {}
    local cursor = nil

    repeat
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PlaceId)
        if cursor then
            url = url .. "&cursor=" .. cursor
        end

        local success, response = pcall(function()
            return game:HttpGet(url)
        end)

        if not success then
            break
        end

        local data = HttpService:JSONDecode(response)
        for _, server in ipairs(data.data) do
            if server.playing < server.maxPlayers then
                table.insert(servers, server)
            end
        end

        cursor = data.nextPageCursor
    until not cursor

    return servers
end

local function ServerHop()
    local servers = GetServers()
    if #servers == 0 then
        return
    end

    local filtered = {}
    for _, server in pairs(servers) do
        if not VisitedServers[server.id] and server.id ~= game.JobId then
            table.insert(filtered, server)
        end
    end

    if #filtered == 0 then
        VisitedServers = {}
        SaveVisitedServers()
        filtered = servers
    end

    local chosen = filtered[math.random(1, #filtered)]

    VisitedServers[chosen.id] = true
    SaveVisitedServers()

    if queue_on_teleport then
        queue_on_teleport([[
            loadstring(game:HttpGet("https://raw.githubusercontent.com/xectray1/what/refs/heads/main/ok.lua"))()
        ]])
    end

    TeleportService:TeleportToPlaceInstance(PlaceId, chosen.id, LocalPlayer)
end

local function main()
    LoadVisitedServers()
    HookNamecall()
    CleanWorkspace()

    if not PlayerOwnsBooth() then
        local clicked = ClickAllAvailableBooths()
        if not clicked then
        end
    end

    UpdateBooth()
    BlockUsers()

    task.wait(600)

    while true do
        ServerHop()
        task.wait(600)
    end
end

main()
