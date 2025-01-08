local ESP_SETTINGS = {
    Enabled = true,
    ShowBoxes = true,
    ShowNames = true,
    ShowSkeletons = true,
    SkeletonsColor = Color3.new(1, 1, 1), -- White
    BoxColor = Color3.new(1, 0, 0), -- Red
    NameColor = Color3.new(0, 1, 0), -- Green
    Thickness = 2,
    Range = 1000,
}

local camera = workspace.CurrentCamera
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer

local function create(class, properties)
    local object = Drawing.new(class)
    for property, value in pairs(properties) do
        object[property] = value
    end
    return object
end

local bones = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"RightLowerArm", "RightHand"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"RightLowerLeg", "RightFoot"},
}

local function getDistanceFromCamera(position)
    local cameraPosition = camera.CFrame.Position
    return (position - cameraPosition).Magnitude
end

local function isOnScreen(position)
    local _, onScreen = camera:WorldToViewportPoint(position)
    return onScreen
end

local function createEsp(character)
    local esp = {
        box = create("Square", {
            Thickness = ESP_SETTINGS.Thickness,
            Color = ESP_SETTINGS.BoxColor,
            Transparency = 1,
            Filled = false,
            Visible = false,
        }),
        name = create("Text", {
            Color = ESP_SETTINGS.NameColor,
            Size = 18,
            Center = true,
            Outline = true,
            Visible = false,
        }),
        skeletonlines = {}
    }
    return esp
end

local function updateEsp(esp, character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")

    if rootPart and humanoid and humanoid.Health > 0 then
        local rootPosition, onScreen = camera:WorldToViewportPoint(rootPart.Position)
        local distance = getDistanceFromCamera(rootPart.Position)

        if onScreen and distance <= ESP_SETTINGS.Range then
            -- Update Box
            if ESP_SETTINGS.ShowBoxes and ESP_SETTINGS.Enabled then
                local size = Vector2.new(4, 6) * (camera.ViewportSize.Y / distance)
                esp.box.Size = size
                esp.box.Position = Vector2.new(rootPosition.X - size.X / 2, rootPosition.Y - size.Y / 2)
                esp.box.Color = ESP_SETTINGS.BoxColor
                esp.box.Visible = true
            else
                esp.box.Visible = false
            end

            -- Update Name
            if ESP_SETTINGS.ShowNames and ESP_SETTINGS.Enabled then
                esp.name.Text = character.Name .. " [" .. math.floor(distance) .. "m]"
                esp.name.Position = Vector2.new(rootPosition.X, rootPosition.Y - 30)
                esp.name.Color = ESP_SETTINGS.NameColor
                esp.name.Visible = true
            else
                esp.name.Visible = false
            end

            -- Update Skeleton
            if ESP_SETTINGS.ShowSkeletons and ESP_SETTINGS.Enabled then
                if #esp.skeletonlines == 0 then
                    -- Create skeleton lines for all bone pairs
                    for _, bonePair in ipairs(bones) do
                        local parentBone, childBone = bonePair[1], bonePair[2]
                        local skeletonLine = create("Line", {
                            Thickness = 1,
                            Color = ESP_SETTINGS.SkeletonsColor,
                            Transparency = 1,
                            Visible = false
                        })
                        esp.skeletonlines[#esp.skeletonlines + 1] = {skeletonLine, parentBone, childBone}
                    end
                end

                -- Update skeleton lines
                for _, lineData in ipairs(esp.skeletonlines) do
                    local skeletonLine = lineData[1]
                    local parentBone, childBone = lineData[2], lineData[3]

                    -- Check if the character and bones exist
                    if character:FindFirstChild(parentBone) and character:FindFirstChild(childBone) then
                        local parentPosition = camera:WorldToViewportPoint(character[parentBone].Position)
                        local childPosition = camera:WorldToViewportPoint(character[childBone].Position)

                        -- Update skeleton line positions
                        skeletonLine.From = Vector2.new(parentPosition.X, parentPosition.Y)
                        skeletonLine.To = Vector2.new(childPosition.X, childPosition.Y)
                        skeletonLine.Color = ESP_SETTINGS.SkeletonsColor
                        skeletonLine.Visible = true
                    else
                        skeletonLine.Visible = false
                    end
                end
            else
                -- Hide all skeleton lines if disabled
                for _, lineData in ipairs(esp.skeletonlines) do
                    local skeletonLine = lineData[1]
                    skeletonLine.Visible = false
                end
            end
        else
            -- Hide ESP if character is off-screen or out of range
            esp.box.Visible = false
            esp.name.Visible = false
            for _, lineData in ipairs(esp.skeletonlines) do
                local skeletonLine = lineData[1]
                skeletonLine.Visible = false
            end
        end
    else
        -- Hide ESP if character is dead or missing
        esp.box.Visible = false
        esp.name.Visible = false
        for _, lineData in ipairs(esp.skeletonlines) do
            local skeletonLine = lineData[1]
            skeletonLine.Visible = false
        end
    end
end

local function removeEsp(esp)
    esp.box:Remove()
    esp.name:Remove()
    for _, lineData in ipairs(esp.skeletonlines) do
        local skeletonLine = lineData[1]
        skeletonLine:Remove()
    end
end

local espCache = {}

runService.RenderStepped:Connect(function()
    if ESP_SETTINGS.Enabled then
        for _, player in ipairs(players:GetPlayers()) do
            if player ~= localPlayer then
                local character = player.Character
                if character then
                    if not espCache[player] then
                        espCache[player] = createEsp(character)
                    end
                    updateEsp(espCache[player], character)
                elseif espCache[player] then
                    removeEsp(espCache[player])
                    espCache[player] = nil
                end
            end
        end
    else
        for _, esp in pairs(espCache) do
            removeEsp(esp)
        end
        espCache = {}
    end
end)
