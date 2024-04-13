local shared = getrenv().shared
local localPlayer = game:GetService("Players").LocalPlayer
local replication = shared.require("ReplicationInterface")

local esp = {
    enabled = true,
    maxfps = 60,

    box = false,
    boxthickness = 1,
    boxcolor = Color3.new(1, 1, 1),

    boxoutline = true,
    boxoutlinethickness = 1,
    boxoutlinecolor = Color3.new(0, 0, 0),
    
    name = false,
    namesize = 13,
    nameoffset = 9,
    namecolor = Color3.new(1, 1, 1),

    nameoutline = true,
    
    weapon = true,
    weaponsize = 13,
    weaponoffset = -6,
    weaponcolor = Color3.new(1, 1, 1),

    weaponoutline = true,
    
    distance = false,
    distancesize = 13,
    distanceoffset = -18,
    distancecolor = Color3.new(1, 1, 1),

    distanceoutline = true,
    
    skeleton = false,
    skeletoncolor = Color3.new(1, 1, 1),
    skeletonthickness = 1,
    
    healthbar = false,
    healthbaroffset = -3.5,
    healthbarthickness = 1.5,
    healthbarcolor = Color3.new(0.15, 0.15, 0.15),
    
    healthbaroutline = false,
    healthbaroutlinethickness = 1,
    healthbaroutlinecolor = Color3.new(0, 0, 0),
    
    healthtext = false,
    healthtextsize = 13,
    healthtextoffset = 3,
    healthtextcolor = Color3.new(1, 1, 1),
    
    healthtextoutline = true,

}
local espData = {}

pcall(getgenv().unload)

local healthbarData = game:HttpGet("https://i.imgur.com/FpnD6XG.png")
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local camera = workspace.CurrentCamera
local ignore = workspace.Ignore
local defaultProperties = {
    Thickness = 1,
    Filled = false,
    Transparency = 1,
    Outline = false,
    Center = true,
    Visible = false
}

function draw(shape)
    local drawing = Drawing.new(shape)

    for i, v in pairs(defaultProperties) do
        pcall(function()
            drawing[i] = v
        end)
    end

    return drawing
end

function getSquarePositions(character)
    local top = camera:WorldToViewportPoint(character.Head.Position + Vector3.yAxis)
    local middle = camera:WorldToViewportPoint(character.Torso.Position)
    local left = camera:WorldToViewportPoint(character["Left Arm"].Position)
    local right = camera:WorldToViewportPoint(character["Right Arm"].Position)

    local leftSize, rightSize
    if left.X < right.X then
        leftSize = "Left Arm"
        rightSize = "Right Arm"
    else
        leftSize = "Left Arm"
        rightSize = "Right Arm"
    end

    left = camera:WorldToViewportPoint(character[leftSize].Position - camera.CFrame.RightVector)
    right = camera:WorldToViewportPoint(character[leftSize].Position + camera.CFrame.RightVector)

    local size = Vector2.new(math.abs(left.X - right.X) * 2, (middle.Y - top.Y) * 2.2)

    return Vector2.new(middle.X - size.X * 0.5, top.Y), size
end

local lastRender = 0
local heartbeatConnection = runService.Heartbeat:Connect(function()
    local time = os.clock()

    if esp.enabled and time - lastRender > 1 / esp.maxfps then
        local alive = ignore:FindFirstChild("RefPlayer")
        lastRender = time

        replication.operateOnAllEntries(function(player, entry)
            local data = espData[player]

            if not data then
                data = {}
                data.visible = false
                data.entry = entry
                data.drawings = {
                    boxoutline = draw("Square"),
                    box = draw("Square"),

                    name = draw("Text"),

                    weapon = draw("Text"),

                    distance = draw("Text"),

                    skeletonhead = draw("Line"),
                    skeletonlarm = draw("Line"),
                    skeletonrarm = draw("Line"),
                    skeletonlleg = draw("Line"),
                    skeletonrleg = draw("Line"),

                    healthbaroutline = draw("Square"),
                    healthbarimage = draw("Image"),
                    healthbarsquare = draw("Square"),
                }
                data.drawings.name.Text = player.Name
                data.drawings.healthbarsquare.Filled = true
                data.drawings.healthbaroutline.Filled = true
                data.drawings.healthbarimage.Data = healthbarData
                data.setVisibility = function(visible)
                    data.drawings.boxoutline.Visible = visible and esp.box and esp.boxoutline
                    data.drawings.box.Visible = visible and esp.box
                    data.drawings.name.Visible = visible and esp.name
                    data.drawings.name.Font = 3
                    data.drawings.weapon.Visible = visible and esp.weapon
                    data.drawings.weapon.Font = 3
                    data.drawings.distance.Visible = visible and esp.distance
                    data.drawings.skeletonhead.Visible = visible and esp.skeleton
                    data.drawings.skeletonlarm.Visible = visible and esp.skeleton
                    data.drawings.skeletonrarm.Visible = visible and esp.skeleton
                    data.drawings.skeletonlleg.Visible = visible and esp.skeleton
                    data.drawings.skeletonrleg.Visible = visible and esp.skeleton
                    data.drawings.healthbaroutline.Visible = visible and esp.healthbar and esp.healthbaroutline
                    data.drawings.healthbarimage.Transparency = visible and esp.healthbar and 1 or 0
                    data.drawings.healthbarsquare.Visible = visible and esp.healthbar
                    data.visible = visible
                end

                espData[player] = data
            end

            if (not entry._alive and data.visible) or not alive then
                data.setVisibility(false)
            end
        end)

        if alive and alive:FindFirstChild("HumanoidRootPart") then
            for player, data in next, espData do
                if data.entry._alive and data.entry._player.Team ~= players.LocalPlayer.Team then
                    local character = data.entry._thirdPersonObject and data.entry._thirdPersonObject._characterHash

                    if character then
                        local screenPosition, onScreen = camera:WorldToViewportPoint(character.Head.Position)

                        if onScreen and screenPosition.Z > 0 then
                            if not data.visible then
                                data.setVisibility(true)
                            end
                            
                            local boxPosition, boxSize, middle

                            if esp.box or esp.name or esp.weapon or esp.distance or esp.healthbar then
                                boxPosition, boxSize = getSquarePositions(character)
                                middle = boxPosition + boxSize * 0.5
                            end

                            if esp.box then
                                local box = data.drawings.box
                                box.Position = boxPosition
                                box.Size = boxSize
                                box.Color = esp.boxcolor
                                box.Thickness = esp.boxthickness
                            end

                            if data.drawings.boxoutline.Visible then
                                local boxoutline = data.drawings.boxoutline
                                boxoutline.Position = boxPosition
                                boxoutline.Size = boxSize
                                boxoutline.Color = esp.boxoutlinecolor
                                boxoutline.Thickness = esp.boxthickness + esp.boxoutlinethickness * 2
                            end

                            if esp.name then
                                local name = data.drawings.name
                                name.Position = Vector2.new(middle.X, boxPosition.Y + (esp.nameoffset < 0 and boxSize.Y or 0) - esp.nameoffset - esp.namesize * 0.5)
                                name.Size = esp.namesize
                                name.Color = esp.namecolor
                                name.Outline = esp.nameoutline
                            end

                            if esp.weapon then
                                local weapon = data.drawings.weapon
                                weapon.Position = Vector2.new(middle.X, boxPosition.Y + (esp.weaponoffset < 0 and boxSize.Y or 0) - esp.weaponoffset - esp.weaponsize * 0.5)
                                weapon.Size = esp.weaponsize
                                weapon.Color = esp.weaponcolor
                                weapon.Outline = esp.weaponoutline
                                
                                local weaponName
                                if data.entry._thirdPersonObject and data.entry._thirdPersonObject._character then
                                    for _, weaponObject in next, data.entry._thirdPersonObject._character:GetChildren() do
                                        if string.find(weaponObject.Name, " External") then
                                            weaponName = string.gsub(weaponObject.Name, " External", "")
                                        end
                                    end
                                end

                                weapon.Text = weaponName or "KNIFE"
                            end

                            if esp.distance then
                                local distance = data.drawings.distance
                                distance.Position = Vector2.new(middle.X, boxPosition.Y + (esp.distanceoffset < 0 and boxSize.Y or 0) - esp.distanceoffset - esp.distancesize * 0.5)
                                distance.Size = esp.distancesize
                                distance.Color = esp.distancecolor
                                distance.Outline = esp.distanceoutline
                                distance.Text = tostring(math.floor((alive.HumanoidRootPart.Position - character.Head.Position).Magnitude + 0.5)) .. " studs"
                            end

                            if esp.healthbar then
                                local healthbarimage = data.drawings.healthbarimage
                                local healthbarsquare = data.drawings.healthbarsquare
                                local squareSize = boxSize.Y * (1 - (data.entry._healthstate.health0 ~= 0 and data.entry._alive and data.entry._healthstate.health0 or 100) * 0.01)
                                healthbarimage.Position = Vector2.new(boxPosition.X + (esp.distanceoffset > 0 and boxSize.X or 0) + esp.healthbaroffset - esp.healthbarthickness * 0.5, boxPosition.Y)
                                healthbarimage.Size = Vector2.new(esp.healthbarthickness, boxSize.Y)
                                healthbarsquare.Position = healthbarimage.Position + Vector2.new(0, boxSize.Y - squareSize)
                                healthbarsquare.Size = Vector2.new(esp.healthbarthickness, squareSize)
                            end

                            if data.drawings.healthbaroutline.Visible then
                                local healthbaroutline = data.drawings.healthbaroutline
                                healthbaroutline.Position = data.drawings.healthbarimage.Position - Vector2.new(esp.healthbarthickness, esp.healthbarthickness)
                                healthbaroutline.Size = data.drawings.healthbarimage.Size + Vector2.new(esp.healthbaroutlinethickness, esp.healthbaroutlinethickness) * 2
                                healthbaroutline.Color = esp.healthbaroutlinecolor
                            end

                            if esp.skeleton then
                                local rootPos = camera:WorldToViewportPoint(character.Torso.Position)
                                local larmPos = camera:WorldToViewportPoint(character["Left Arm"].Position)
                                local rarmPos = camera:WorldToViewportPoint(character["Right Arm"].Position)
                                local llegPos = camera:WorldToViewportPoint(character["Left Leg"].Position)
                                local rlegPos = camera:WorldToViewportPoint(character["Right Leg"].Position)
                                
                                local drawings = data.drawings
                                drawings.skeletonhead.To = Vector2.new(screenPosition.X, screenPosition.Y)
                                drawings.skeletonlarm.To = Vector2.new(larmPos.X, larmPos.Y)
                                drawings.skeletonrarm.To = Vector2.new(rarmPos.X, rarmPos.Y)
                                drawings.skeletonlleg.To = Vector2.new(llegPos.X, llegPos.Y)
                                drawings.skeletonrleg.To = Vector2.new(rlegPos.X, rlegPos.Y)

                                local fromPos = Vector2.new(rootPos.X, rootPos.Y)
                                for drawingName, drawing in next, drawings do
                                    if string.find(drawingName, "skeleton") then
                                        drawing.Thickness = esp.skeletonthickness
                                        drawing.Color = esp.skeletoncolor
                                        drawing.From = fromPos
                                    end
                                end
                            end
                        elseif data.visible then
                            data.setVisibility(false)
                        end
                    end
                end
            end
        end
    end
end)

local removeConnection = players.PlayerRemoving:Connect(function(player)
    player = espData[player]

    if player then
        player.setVisibility(false)

        for _, drawing in next, player.drawings do
            drawing:Remove()
        end

        espData[player] = nil
    end
end)