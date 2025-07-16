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

-- 获取当前角色的 HumanoidRootPart
local function getRootPart()
    local character = player.Character
    return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart"))
end

-- 设置 ESP 配置
function DripESP.SetOptions(ESP_ID, opts)
    all_settings[ESP_ID] = {
        TargetName = opts.TargetName or "Model",
        CustomText = opts.CustomText or "Target",
        TextColor = opts.TextColor or Color3.fromRGB(255, 255, 255),
        OutlineColor = opts.OutlineColor or Color3.fromRGB(0, 0, 0), -- 轮廓颜色
        FillTransparency = opts.FillTransparency or 0.5,
        OutlineTransparency = opts.OutlineTransparency or 0, -- 轮廓透明度
        TextSize = opts.TextSize or 15,
        CheckForHumanoid = opts.CheckForHumanoid or false,
        TargetType = opts.TargetType or "Both",
        HighlightName = "ESP_Highlight_" .. ESP_ID,
        BillboardName = "ESP_Billboard_" .. ESP_ID,
    }
end

-- 应用 ESP 到目标（轮廓大小固定为1）
local function applyESP(target, ESP_ID, settings)
    -- 检查目标类型和名称
    local isValid = (settings.TargetType == "Both") or
                  (settings.TargetType == "Model" and target:IsA("Model")) or
                  (settings.TargetType == "Part" and target:IsA("BasePart"))
    if not isValid or target.Name ~= settings.TargetName then return end
    if target:IsA("Model") and settings.CheckForHumanoid and not target:FindFirstChild("Humanoid") then return end

    -- 获取目标的有效部件
    local targetPart = target:IsA("Model") and 
                     (target:FindFirstChild("HumanoidRootPart") or
                      target:FindFirstChild("Torso") or
                      target:FindFirstChild("Head") or
                      target:FindFirstChildWhichIsA("BasePart")) or target
    if not targetPart then return end

    -- 创建 BillboardGui
    local bbName = settings.BillboardName .. "_" .. target:GetDebugId()
    if not ESPFolder:FindFirstChild(bbName) then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = bbName
        billboard.Parent = ESPFolder
        billboard.Adornee = targetPart
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true

        -- 创建文本标签
        local label = Instance.new("TextLabel")
        label.Name = "ESP_Text"
        label.Parent = billboard
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = settings.TextColor
        label.TextSize = settings.TextSize
        label.Font = Enum.Font.SourceSansBold
        label.TextWrapped = true
        label.TextYAlignment = Enum.TextYAlignment.Center

        -- 固定文本描边粗细为1
        local stroke = Instance.new("UIStroke")
        stroke.Color = settings.OutlineColor
        stroke.Thickness = 1 -- 固定轮廓大小
        stroke.Transparency = settings.OutlineTransparency
        stroke.Parent = label

        -- 实时更新距离
        updaters[bbName] = renderStepped:Connect(function()
            local root = getRootPart()
            if root and targetPart and label.Parent then
                local distance = (root.Position - targetPart.Position).Magnitude
                label.Text = string.format("%s\n[%.1f]", settings.CustomText, distance)
            end
        end)
    end

    -- 创建高光效果（使用默认轮廓）
    local hlName = settings.HighlightName .. "_" .. target:GetDebugId()
    if not ESPFolder:FindFirstChild(hlName) then
        local highlight = Instance.new("Highlight")
        highlight.Name = hlName
        highlight.Parent = ESPFolder
        highlight.Adornee = target
        highlight.FillColor = settings.TextColor
        highlight.FillTransparency = settings.FillTransparency
        highlight.OutlineColor = settings.OutlineColor
        highlight.OutlineTransparency = settings.OutlineTransparency
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end
end

-- 启用/禁用 ESP
function DripESP.Enable(ESP_ID)
    local settings = all_settings[ESP_ID]
    if not settings then return end

    for _, item in ipairs(workspace:GetDescendants()) do
        if (item:IsA("Model") or item:IsA("BasePart")) and item.Name == settings.TargetName then
            applyESP(item, ESP_ID, settings)
        end
    end

    connections[ESP_ID] = workspace.DescendantAdded:Connect(function(item)
        if (item:IsA("Model") or item:IsA("BasePart")) and item.Name == settings.TargetName then
            task.wait(0.5)
            applyESP(item, ESP_ID, settings)
        end
    end)
end

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
