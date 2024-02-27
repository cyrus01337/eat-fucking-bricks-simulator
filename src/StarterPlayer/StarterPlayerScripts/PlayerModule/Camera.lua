--!strict
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")
local UserInputService = game:GetService("UserInputService")

local CustomPlayer = require(ReplicatedStorage.CustomPlayer)

local player = CustomPlayer.get()
local playerCamera = workspace.CurrentCamera
local Camera = {}

type Context = {
    PanDelta: Vector2,
}

local function trackPlayerCharacter(context: Context)
    local orientation = CFrame.fromOrientation(
        -math.rad(context.PanDelta.Y * UserGameSettings.MouseSensitivity),
        -math.rad(context.PanDelta.X * UserGameSettings.MouseSensitivity),
        0
    )
    local positionalOffset = CFrame.new(0, player.Character.Torso.Size.Y + 2, 5)
    local origin = CFrame.new(player.Character.HumanoidRootPart.Position) * orientation * positionalOffset
    playerCamera.CFrame = CFrame.new(origin.Position, player.Character.HumanoidRootPart.Position)
end

local function togglePanning(state: Enum.UserInputState)
    if state == Enum.UserInputState.Begin then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    elseif state == Enum.UserInputState.End then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end

-- TODO: See if possible to move callback elsewhere and still transfer context
local function bindCameraToPlayerCharacter(context: Context)
    local function pan(action: string, state: Enum.UserInputState, input: InputObject)
        if
            state ~= Enum.UserInputState.Begin
            and state ~= Enum.UserInputState.Change
            and state ~= Enum.UserInputState.End
        then
            return Enum.ContextActionResult.Pass
        end

        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            togglePanning(state)
        elseif
            input.UserInputType == Enum.UserInputType.MouseMovement
            and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCurrentPosition
        then
            context.PanDelta += UserInputService:GetMouseDelta()
        end

        return Enum.ContextActionResult.Pass
    end

    RunService.RenderStepped:Connect(function()
        trackPlayerCharacter(context)
    end)
    ContextActionService:BindAction(
        "pan",
        pan,
        false,
        Enum.UserInputType.MouseButton2,
        Enum.UserInputType.MouseMovement
    )
end

function Camera.init()
    local context: Context = {
        PanDelta = Vector2.zero,
    }

    if player.Character then
        bindCameraToPlayerCharacter(context)
    end

    player.CharacterAdded:Connect(function()
        bindCameraToPlayerCharacter(context)
    end)
end

return Camera
