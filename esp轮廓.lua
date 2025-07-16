local DripESP = {}
local connections = {}
local updaters = {}
local all_settings = {}
local renderStepped = game:GetService("RunService").RenderStepped
local player = game.Players.LocalPlayer

-- ESP 显示文件夹
local ESPFolder = workspace:FindFirstChild("ESP_Objects")
if not ESPFolder then
    ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "ESP_Objects"
    ESPFolder.Parent = workspace
end

-- 获取当前角色的 HumanoidRootPart（重生也能适配）
local function getRootPart()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- 设置 ESP 配置
function DripESP.SetOptions(ESP_ID, opts)
    all_settings[ESP_ID] = {
        TargetName = opts.TargetName or "Model",
        CustomText = opts.CustomText or "Target",
        TextColor = opts.TextColor or Color3.fromRGB(255, 255, 255),
        FillTransparency = opts.FillTransparency or 0.5,
        OutlineTransparency = opts.OutlineTransparency or 0,
        TextSize = opts.TextSize or 15,
        CheckForHumanoid = opts.CheckForHumanoid or false,
        TargetType = opts.TargetType or "Both",
        HighlightName = "ESP_Highlight_" .. ESP_ID,
        BillboardName = "ESP_Billboard_" .. ESP_ID,
    }
end

-- 应用 ESP 到指定目标
local function applyESP(target, ESP_ID, settings)
    local isValid = (settings.TargetType == "Both") or
        (settings.TargetType == "Model" and target:IsA("Model")) or
        (settings.TargetType == "Part" and target:IsA("BasePart"))
    if not isValid then return end
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

    -- Billboard 显示标签
    local bbName = settings.BillboardName .. "_" .. target:GetDebugId()
    if not ESPFolder:FindFirstChild(bbName) then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = bbName
        billboard.Parent = ESPFolder
        billboard.Adornee = targetPart
        billboard.Size = UDim2.new(0, 100, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true

        local label = Instance.new("TextLabel")
        label.Name = "ESP_Text"
        label.Parent = billboard
        label.Size = UDim2.new(1, 0, 2, 0) -- 增加高度支持两行
        label.BackgroundTransparency = 1
        label.TextColor3 = settings.TextColor
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.TextStrokeTransparency = 0
        label.TextSize = settings.TextSize
        label.Font = Enum.Font.SourceSans
        label.TextWrapped = true
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Text = settings.CustomText .. "\n[0]"

        -- 实时更新距离（防止引用失效，动态获取 rootPart）
        updaters[bbName] = renderStepped:Connect(function()
            pcall(function()
                local root = getRootPart()
                local dist = root and targetPart and (root.Position - targetPart.Position).Magnitude
                if dist and label and label.Parent then
                    label.Text = settings.CustomText .. "\n[" .. math.floor(dist) .. "]"
                end
            end)
        end)
    end

    -- Highlight 高亮
    local hlName = settings.HighlightName .. "_" .. target:GetDebugId()
    if not ESPFolder:FindFirstChild(hlName) then
        local highlight = Instance.new("Highlight")
        highlight.Name = hlName
        highlight.Parent = ESPFolder
        highlight.Adornee = target
        highlight.FillColor = settings.TextColor
        highlight.FillTransparency = settings.FillTransparency
        highlight.OutlineColor = settings.TextColor
        highlight.OutlineTransparency = settings.OutlineTransparency
    end
end

-- 启用 ESP
function DripESP.Enable(ESP_ID)
    local settings = all_settings[ESP_ID]
    if not settings then return end

    for _, item in ipairs(workspace:GetDescendants()) do
        if (item:IsA("Model") or item:IsA("BasePart")) and item.Name == settings.TargetName then
            applyESP(item, ESP_ID, settings)
        end
    end

    connections[ESP_ID] = workspace.DescendantAdded:Connect(function(v)
        if (v:IsA("Model") or v:IsA("BasePart")) and v.Name == settings.TargetName then
            task.wait(0.5)
            applyESP(v, ESP_ID, settings)
        end
    end)
end

-- 禁用 ESP
function DripESP.Disable(ESP_ID)
    local settings = all_settings[ESP_ID]
    if not settings then return end

    if connections[ESP_ID] then
        connections[ESP_ID]:Disconnect()
        connections[ESP_ID] = nil
    end

    for _, item in ipairs(ESPFolder:GetChildren()) do
        if item.Name:match(settings.BillboardName) or item.Name:match(settings.HighlightName) then
            item:Destroy()
        end
    end

    for name, conn in pairs(updaters) do
        if name:match(settings.BillboardName) then
            conn:Disconnect()
            updaters[name] = nil
        end
    end

    all_settings[ESP_ID] = nil
end

return DripESP
