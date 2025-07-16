local DripESP = {}
local connections = {}
local all_settings = {}
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local rootPart = char:WaitForChild("HumanoidRootPart")

-- ESP统一文件夹
local ESPFolder = workspace:FindFirstChild("ESP_Objects")
if not ESPFolder then
    ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "ESP_Objects"
    ESPFolder.Parent = workspace
end

function DripESP.SetOptions(ESP_ID, opts)
    all_settings[ESP_ID] = {
        TargetName = opts.TargetName or opts.ModelName or "Model", 
        CustomText = opts.CustomText or "Target",
        TextColor = opts.TextColor or Color3.fromRGB(255, 255, 255),
        OutlineColor = opts.OutlineColor or Color3.fromRGB(0, 0, 0),
        FillColor = opts.FillColor or Color3.fromRGB(0, 0, 0),
        FillTransparency = opts.FillTransparency or 0.5,
        OutlineTransparency = opts.OutlineTransparency or 0,
        TextSize = opts.TextSize or 15,
        CheckForHumanoid = opts.CheckForHumanoid or false,
        TargetType = opts.TargetType or "Both",
        HighlightName = "ESP_Highlight_" .. ESP_ID,
        BillboardName = "ESP_Billboard_" .. ESP_ID,
    }
end

local function applyESP(target, ESP_ID, settings)
    local isValidType = (settings.TargetType == "Both") or
                      (settings.TargetType == "Model" and target:IsA("Model")) or
                      (settings.TargetType == "Part" and target:IsA("BasePart"))
    if not isValidType then return end
    if target.Name ~= settings.TargetName then return end
    if target:IsA("Model") and settings.CheckForHumanoid and not target:FindFirstChild("Humanoid") then return end

    local targetPart
    if target:IsA("Model") then
        targetPart = target:FindFirstChild("HumanoidRootPart") or
                     target:FindFirstChild("Torso") or
                     target:FindFirstChild("Head") or
                     target:FindFirstChildWhichIsA("BasePart")
    else
        targetPart = target
    end
    if not targetPart then return end

    local bbName = settings.BillboardName .. "_" .. target:GetDebugId()
    local billboard = ESPFolder:FindFirstChild(bbName)
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = bbName
        billboard.Parent = ESPFolder
        billboard.Adornee = targetPart
        billboard.Size = UDim2.new(0, 100, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 0, 0)
        billboard.AlwaysOnTop = true
    end

    local label = billboard:FindFirstChild("ESP_Text")
    if not label then
        label = Instance.new("TextLabel")
        label.Name = "ESP_Text"
        label.Parent = billboard
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = settings.TextColor
        label.TextStrokeColor3 = settings.OutlineColor
        label.TextStrokeTransparency = settings.OutlineTransparency
        label.TextSize = settings.TextSize
        label.Font = Enum.Font.SourceSans
        label.TextWrapped = true
        label.TextYAlignment = Enum.TextYAlignment.Center

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 2
        stroke.Color = settings.OutlineColor
        stroke.Transparency = settings.OutlineTransparency
        stroke.Parent = label
    end

    local function updateDistance()
        if label and label.Parent and targetPart and rootPart and rootPart.Parent then
            local distance = (rootPart.Position - targetPart.Position).Magnitude
            label.Text = string.format("%s\n[%.1f]", settings.CustomText, distance)
        end
    end

    updateDistance()

    local runService = game:GetService("RunService")
    local conn = runService.RenderStepped:Connect(updateDistance)

    if not connections[ESP_ID] then connections[ESP_ID] = {} end
    table.insert(connections[ESP_ID], conn)

    -- Highlight
    local hlName = settings.HighlightName .. "_" .. target:GetDebugId()
    if not ESPFolder:FindFirstChild(hlName) then
        local highlight = Instance.new("Highlight")
        highlight.Name = hlName
        highlight.Parent = ESPFolder
        highlight.Adornee = target
        highlight.FillColor = settings.FillColor
        highlight.FillTransparency = settings.FillTransparency
        highlight.OutlineColor = settings.OutlineColor
        highlight.OutlineTransparency = settings.OutlineTransparency
    end
end

function DripESP.Enable(ESP_ID)
    local settings = all_settings[ESP_ID]
    if not settings then return end

    for _, item in ipairs(workspace:GetDescendants()) do
        if (item:IsA("Model") or item:IsA("BasePart")) and item.Name == settings.TargetName then
            applyESP(item, ESP_ID, settings)
        end
    end

    local conn = workspace.DescendantAdded:Connect(function(v)
        if (v:IsA("Model") or v:IsA("BasePart")) and v.Name == settings.TargetName then
            task.wait(0.5)
            applyESP(v, ESP_ID, settings)
        end
    end)

    if not connections[ESP_ID] then connections[ESP_ID] = {} end
    table.insert(connections[ESP_ID], conn)
end

function DripESP.Disable(ESP_ID)
    local settings = all_settings[ESP_ID]
    if not settings then return end

    if connections[ESP_ID] then
        for _, conn in ipairs(connections[ESP_ID]) do
            if conn and conn.Disconnect then conn:Disconnect() end
        end
        connections[ESP_ID] = nil
    end

    for _, item in ipairs(ESPFolder:GetChildren()) do
        if item.Name:match(settings.BillboardName) or item.Name:match(settings.HighlightName) then
            item:Destroy()
        end
    end

    all_settings[ESP_ID] = nil
end

return DripESP
