local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "The Walking Dead Online 3",
    SubTitle = "by OHM GG",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, 
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Settings = {
    Color1 = Color3.fromRGB(0, 0, 70),
    Color2 = Color3.fromRGB(0, 150, 255),

    ParticleColor = Color3.fromRGB(0, 100, 255),
    SpawnRate = 0.15,

    BoxThickness = 3.5, 
    PulseSpeed = 1.2,
    RotationSpeed = 3, 
    MaxDistance = 2500, 
}

local Players = game:GetService("Players") 
local RunService = game:GetService("RunService") 
local TweenService = game:GetService("TweenService") 
local LocalPlayer = Players.LocalPlayer 
local Camera = workspace.CurrentCamera 

local ParticleFolder = workspace:FindFirstChild("ESP_DarkBlue_Particles") or Instance.new("Folder", workspace)
ParticleFolder.Name = "ESP_DarkBlue_Particles"

local ESPEnabled = false
local ActiveESP = {} 
local GlobalConnections = {} 

local function RemoveVanillaName(char)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
end

local function SpawnNeonParticle(pos)
    if not ESPEnabled then return end
    
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.3, 0.3, 0.3)
    part.Position = pos + Vector3.new(
        math.random(-2,2),
        -3.5,
        math.random(-2,2)
    )
    part.Anchored = true 
    part.CanCollide = false 
    part.Shape = Enum.PartType.Ball
    part.Material = Enum.Material.Neon 
    part.Color = Settings.ParticleColor
    part.Parent = ParticleFolder

    local tween = TweenService:Create(part,
        TweenInfo.new(1.8, Enum.EasingStyle.Quart),
        {
            Position = part.Position + Vector3.new(0, 7, 0),
            Transparency = 1,
            Size = Vector3.new(0,0,0)
        }
    )
    tween:Play()
    tween.Completed:Connect(function()
        part:Destroy()
    end)
end
local function CleanupPlayerESP(player)
    if ActiveESP[player] then
        if ActiveESP[player].BoxGui then ActiveESP[player].BoxGui:Destroy() end
        if ActiveESP[player].NameGui then ActiveESP[player].NameGui:Destroy() end
        if ActiveESP[player].Connections then
            for _, conn in pairs(ActiveESP[player].Connections) do
                conn:Disconnect()
            end
        end
        ActiveESP[player] = nil
    end
end
local function ApplyESP(player)
    if player == LocalPlayer then return end
    local function OnChar(char)
        if not ESPEnabled then return end
        CleanupPlayerESP(player) -- ล้างของเก่าก่อนสร้างใหม่
        RemoveVanillaName(char)
        local root = char:WaitForChild("HumanoidRootPart", 15)
        if not root or not ESPEnabled then return end
        local playerName = player.Name
        local userId = player.UserId
        local boxGui = Instance.new("BillboardGui")
        boxGui.Adornee = root 
        boxGui.Size = UDim2.new(4,0,5.5,0) 
        boxGui.AlwaysOnTop = true
        boxGui.MaxDistance = Settings.MaxDistance
        boxGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        local mainFrame = Instance.new("Frame")
        mainFrame.Size = UDim2.new(1,0,1,0)
        mainFrame.BackgroundTransparency = 1
        mainFrame.Parent = boxGui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.3, 0)
        corner.Parent = mainFrame
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = Settings.BoxThickness
        stroke.Color = Color3.new(1,1,1)
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = mainFrame
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Settings.Color1),
            ColorSequenceKeypoint.new(0.5, Settings.Color2),
            ColorSequenceKeypoint.new(1, Settings.Color1)
        })
        gradient.Parent = stroke
        task.spawn(function()
            while ESPEnabled and boxGui and boxGui.Parent do
                gradient.Rotation += Settings.RotationSpeed
                task.wait(0.02)
            end
        end)
        local nameGui = Instance.new("BillboardGui")
        nameGui.Adornee = root
        nameGui.Size = UDim2.new(4,0,1.5,0)
        nameGui.StudsOffset = Vector3.new(0, 3.5, 0) 
        nameGui.AlwaysOnTop = true
        nameGui.MaxDistance = Settings.MaxDistance
        nameGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1,0,1,0)
        container.BackgroundTransparency = 1
        container.Parent = nameGui
        local avatar = Instance.new("ImageLabel")
        avatar.Size = UDim2.new(0.25,0,1,0)
        avatar.BackgroundTransparency = 1
        avatar.Parent = container
        task.spawn(function()
            local ok, img = pcall(function()
                return Players:GetUserThumbnailAsync(
                    userId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size150x150
                )
            end)
            if ok and avatar then avatar.Image = img end
        end)
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.75,0,1,0)
        nameLabel.Position = UDim2.new(0.27,0,0,0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = playerName
        nameLabel.TextScaled = true
        nameLabel.TextColor3 = Color3.new(1,1,1)
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.Parent = container
        pcall(function()
            nameLabel.FontFace = Font.new("rbxassetid://11322590111")
        end)
        task.spawn(function()
            while ESPEnabled and boxGui and boxGui.Parent do
                if root and root.Parent then
                    local dist = (Camera.CFrame.Position - root.Position).Magnitude
                    if dist < 300 then
                        SpawnNeonParticle(root.Position)
                    end
                end
                task.wait(Settings.SpawnRate)
            end
        end)
        local renderConn
        renderConn = RunService.RenderStepped:Connect(function()
            if not char.Parent or not ESPEnabled then
                CleanupPlayerESP(player)
            end
        end)
        ActiveESP[player] = {
            BoxGui = boxGui,
            NameGui = nameGui,
            Connections = { renderConn }
        }
    end
    local charAddedConn = player.CharacterAdded:Connect(OnChar)
    if ActiveESP[player] then
        table.insert(ActiveESP[player].Connections, charAddedConn)
    else
        ActiveESP[player] = { Connections = { charAddedConn } }
    end
    if player.Character then
        task.spawn(OnChar, player.Character)
    end
end

local function EnableESP()
    ESPEnabled = true
    for _, p in pairs(Players:GetPlayers()) do
        ApplyESP(p)
    end
    local pAdded = Players.PlayerAdded:Connect(ApplyESP)
    local pRemoving = Players.PlayerRemoving:Connect(function(p)
        CleanupPlayerESP(p)
    end)
    table.insert(GlobalConnections, pAdded)
    table.insert(GlobalConnections, pRemoving)
end

local function DisableESP()
    ESPEnabled = false
    for _, conn in pairs(GlobalConnections) do
        conn:Disconnect()
    end
    table.clear(GlobalConnections)
    for player, _ in pairs(ActiveESP) do
        CleanupPlayerESP(player)
    end
    table.clear(ActiveESP)
    ParticleFolder:ClearAllChildren()
end


-- Find Cars
local function GetNearestCar()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local playerPos = character.HumanoidRootPart.Position
    local carsFolder = workspace:FindFirstChild("Cars")
    
    if not carsFolder then 
        warn("ไม่พบโฟลเดอร์ Cars ใน workspace")
        return nil 
    end

    local nearestCarPart = nil
    local shortestDistance = math.huge

    for _, carModel in ipairs(carsFolder:GetChildren()) do
        local carPart = carModel:FindFirstChild("Body") 
            or carModel.PrimaryPart 
            or carModel:FindFirstChildWhichIsA("BasePart")

        if carPart then
            local distance = (playerPos - carPart.Position).Magnitude
            
            if distance < shortestDistance then
                shortestDistance = distance
                nearestCarPart = carPart
            end
        end
    end

    return nearestCarPart, shortestDistance
end

local function TeleportToNearestCar()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local targetPart, distance = GetNearestCar()

    if targetPart then
        character.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 3, 0)
        print("วาร์ปไปยังรถแล้ว! ระยะห่างเดิม:", math.floor(distance), "Studs")
    else
        warn("ไม่พบรถรอบๆ ตัว")
    end
end

-- Teleport
local TeleportValue = {
    "notSelect",
    "farm_01",
    "bunker",
}
local TeleportList = {
    ['farm_01'] = game:GetService("Workspace").Lootables.Loot_MilitaryCrate.Loot_MilitaryCrate,
    ['bunker'] = game:GetService("Workspace").Model.Trap,
}

local Options = Fluent.Options

do

    local Dropdown = Tabs.Main:AddDropdown("Dropdown", {
        Title = "Teleport",
        Values = TeleportValue,
        Multi = false,
        Default = 1,
    })
    Dropdown:SetValue("notSelect")
    Dropdown:OnChanged(function(Value)
        local target = TeleportList[Value]
        if target then
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")
            hrp.CFrame = target.CFrame + Vector3.new(0, 5, 0)
        end
    end)

    local Toggle = Tabs.Main:AddToggle("ESPToggle", { Title = "DarkBlue Neon ESP", Default = false })
    Toggle:OnChanged(function()
        local state = Options.ESPToggle.Value
        if state then
            EnableESP()
        else
            DisableESP()
        end
    end)
    Options.ESPToggle:SetValue(false)

    Tabs.Main:AddButton({
        Title = "Teleport To Nearest Car",
        Description = "วาร์ปไปยังรถที่อยู่ใกล้",
        Callback = function()
            TeleportToNearestCar()
        end
    })

end

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

SaveManager:LoadAutoloadConfig()