-- DripESP_Library | BY du78
local DripESP = {}
local connections = {}
local all_settings = {}
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local rootPart = char:WaitForChild("HumanoidRootPart")

function DripESP.SetOptions(ESP_ID, opts)
    all_settings[ESP_ID] = {
        TargetName = opts.TargetName or opts.ModelName or "Model", 
        CustomText = opts.CustomText or "目标",
        TextColor = opts.TextColor or Color3.fromRGB(0, 255, 255),
        OutlineColor = opts.OutlineColor or Color3.fromRGB(255, 0, 0),
        TextSize = opts.TextSize or 15,
        HighlightName = "ESP_Highlight_" .. ESP_ID,
        BillboardName = "ESP_Billboard_" .. ESP_ID,
        CheckForHumanoid = opts.CheckForHumanoid or false,
        TargetType = opts.TargetType or "Both" 
    }
end

local function applyESP(target, ESP_ID, settings)   
    local isValidType = (settings.TargetType == "Both") or
                      (settings.TargetType == "Model" and target:IsA("Model")) or
                      (settings.TargetType == "Part" and target:IsA("BasePart"))
    
    if not isValidType then return end
    
    if target.Name ~= settings.TargetName then return end
     
    if target:IsA("Model") and settings.CheckForHumanoid and not target:FindFirstChild("Humanoid") then 
        return 
    end
    
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

    if not target:FindFirstChild(settings.BillboardName) then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = settings.BillboardName
        billboard.Parent = target
        billboard.Adornee = targetPart
        billboard.Size = UDim2.new(0, 100, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 2, 0) -- 文字悬浮高度
        billboard.AlwaysOnTop = true

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
        label.Text = settings.CustomText

        -- 固定轮廓粗细（这里设为 3，不再让用户自定义）
        local stroke = Instance.new("UIStroke")
        stroke.Parent = label
        stroke.Color = settings.OutlineColor
        stroke.Thickness = 3  -- 固定加粗轮廓
        stroke.Transparency = 0
    end

    if not target:FindFirstChild(settings.HighlightName) then
        local highlight = Instance.new("Highlight")
        highlight.Name = settings.HighlightName
        highlight.Parent = target
        highlight.OutlineColor = settings.OutlineColor
        highlight.FillTransparency = 0.8
        highlight.OutlineTransparency = 0
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

    connections[ESP_ID] = workspace.DescendantAdded:Connect(function(v)
        if (v:IsA("Model") or v:IsA("BasePart")) and v.Name == settings.TargetName then
            task.wait(0.1)
            applyESP(v, ESP_ID, settings)
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

    for _, item in ipairs(workspace:GetDescendants()) do
        if (item:IsA("Model") or item:IsA("BasePart")) and item.Name == settings.TargetName then
            local gui = item:FindFirstChild(settings.BillboardName)
            if gui then gui:Destroy() end

            local hl = item:FindFirstChild(settings.HighlightName)
            if hl then hl:Destroy() end
        end
    end

    all_settings[ESP_ID] = nil
end

return DripESP