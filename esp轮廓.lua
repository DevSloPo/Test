local DripESP = {}
local connections = {}
local all_settings = {}

-- 初始化玩家角色和根部件
local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local rootPart = char:WaitForChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChildWhichIsA("BasePart")

-- 创建 ESP 统一文件夹
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESP_Objects"
ESPFolder.Parent = workspace

-- 监听角色变化（防止角色重置后 rootPart 失效）
player.CharacterAdded:Connect(function(newChar)
    char = newChar
    rootPart = newChar:WaitForChild("HumanoidRootPart") or newChar:FindFirstChild("Torso") or newChar:FindFirstChildWhichIsA("BasePart")
end)

--- 设置 ESP 参数
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

--- 应用 ESP 到目标
local function applyESP(target, ESP_ID, settings)
    -- 检查目标类型是否符合
    local isValidType = (settings.TargetType == "Both") or
                      (settings.TargetType == "Model" and target:IsA("Model")) or
                      (settings.TargetType == "Part" and target:IsA("BasePart"))
    if not isValidType then return end

    -- 检查目标名称是否匹配
    if target.Name ~= settings.TargetName then return end

    -- 如果是 Model 且需要检查 Humanoid
    if target:IsA("Model") and settings.CheckForHumanoid and not target:FindFirstChild("Humanoid") then
        return
    end

    -- 获取目标的有效部件（用于计算距离）
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

    -- 创建 BillboardGui 显示文字
    local bbName = settings.BillboardName .. "_" .. target:GetDebugId()
    local billboard = ESPFolder:FindFirstChild(bbName)
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = bbName
        billboard.Parent = ESPFolder
        billboard.Adornee = targetPart
        billboard.Size = UDim2.new(0, 100, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 2, 0)  -- 提高显示位置
        billboard.AlwaysOnTop = true
    end

    -- 创建 TextLabel
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
        label.Font = Enum.Font.SourceSansBold
        label.TextWrapped = true
        label.TextYAlignment = Enum.TextYAlignment.Center

        -- 添加描边效果
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 2
        stroke.Color = settings.OutlineColor
        stroke.Transparency = settings.OutlineTransparency
        stroke.Parent = label
    end

    -- 更新距离显示
    local function updateDistance()
        if not label or not label.Parent then return end
        if not targetPart or not rootPart then return end

        local distance = (rootPart.Position - targetPart.Position).Magnitude
        label.Text = string.format("%s\n%.1f 米", settings.CustomText, distance)  -- 显示 "目标名称\n12.5 米"
    end

    -- 立即更新一次
    updateDistance()

    -- 连接 RenderStepped 持续更新
    local conn = game:GetService("RunService").RenderStepped:Connect(updateDistance)
    if not connections[ESP_ID] then connections[ESP_ID] = {} end
    table.insert(connections[ESP_ID], conn)

    -- 创建高亮效果
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

--- 启用 ESP
function DripESP.Enable(ESP_ID)
    local settings = all_settings[ESP_ID]
    if not settings then return end

    -- 遍历现有目标
    for _, item in ipairs(workspace:GetDescendants()) do
        if (item:IsA("Model") or item:IsA("BasePart")) and item.Name == settings.TargetName then
            applyESP(item, ESP_ID, settings)
        end
    end

    -- 监听新目标
    local conn = workspace.DescendantAdded:Connect(function(item)
        if (item:IsA("Model") or item:IsA("BasePart")) and item.Name == settings.TargetName then
            task.wait(0.5)  -- 等待目标完全加载
            applyESP(item, ESP_ID, settings)
        end
    end)

    if not connections[ESP_ID] then connections[ESP_ID] = {} end
    table.insert(connections[ESP_ID], conn)
end

--- 禁用 ESP
function DripESP.Disable(ESP_ID)
    local settings = all_settings[ESP_ID]
    if not settings then return end

    -- 断开所有连接
    if connections[ESP_ID] then
        for _, conn in ipairs(connections[ESP_ID]) do
            if conn and conn.Disconnect then conn:Disconnect() end
        end
        connections[ESP_ID] = nil
    end

    -- 删除所有相关实例
    for _, item in ipairs(ESPFolder:GetChildren()) do
        if item.Name:match(settings.BillboardName) or item.Name:match(settings.HighlightName) then
            item:Destroy()
        end
    end

    all_settings[ESP_ID] = nil
end

return DripESP
