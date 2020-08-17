local CLASS = {}

--// SERVICES //--

local PLAYERS_SERVICE = game:GetService("Players")
local RUN_SERVICE = game:GetService("RunService")
local USER_INPUT_SERVICE = game:GetService("UserInputService")

--// CONSTANTS //--

local LOCAL_PLAYER = PLAYERS_SERVICE.LocalPlayer
local MOUSE = LOCAL_PLAYER:GetMouse()

local UPDATE_UNIQUE_KEY = "OTS_CAMERA_SYSTEM_UPDATE"

--// VARIABLES //--



--// CONSTRUCTOR //--

function CLASS.new()
	
	local enabledEvent = Instance.new("BindableEvent")
	local disabledEvent = Instance.new("BindableEvent")
	local steppedOutEvent = Instance.new("BindableEvent")
	local steppedInEvent = Instance.new("BindableEvent")
	local shoulderDirectionChangedEvent = Instance.new("BindableEvent")
	local activeCameraSettingsChangedEvent = Instance.new("BindableEvent")
	local cameraFollowChangedEvent = Instance.new("BindableEvent")
	
	local dataTable = setmetatable(
		{
			
			--// Configurations //--
			VerticalAngleLimits = NumberRange.new(-45, 45),
			----
			
			--// Properties //--
			IsEnabled = false,
			SavedCameraSettings = nil,
			SavedMouseBehavior = nil,
			HorizontalAngle = 0,
			VerticalAngle = 0,
			ActiveCameraSettings = nil,
			ShoulderDirection = 1,
			IsSteppedOut = true,
			CameraFollow = false,
			----
			
			--// Events //--
			EnabledEvent = enabledEvent,
			Enabled = enabledEvent.Event,
			DisabledEvent = disabledEvent,
			Disabled = disabledEvent.Event,
			SteppedOutEvent = steppedOutEvent,
			SteppedOut = steppedOutEvent.Event,
			SteppedInEvent = steppedInEvent,
			SteppedIn = steppedInEvent.Event,
			ShoulderDirectionChangedEvent = shoulderDirectionChangedEvent,
			ShoulderDirectionChanged = shoulderDirectionChangedEvent.Event,
			ActiveCameraSettingsChangedEvent = activeCameraSettingsChangedEvent,
			ActiveCameraSettingsChanged = activeCameraSettingsChangedEvent.Event,
			CameraFollowChangedEvent = cameraFollowChangedEvent,
			CameraFollowChanged = cameraFollowChangedEvent.Event,
			----
			
			--// Camera Settings //--
			CameraSettings = {
				
				DefaultShoulder = {
					FieldOfView = 70,
					Offset = Vector3.new(2.5, 2.5, 5),
					Sensitivity = 1/300,
					LerpingSpeed = 0.5
				},
				
				ZoomedShoulder = {
					FieldOfView = 40,
					Offset = Vector3.new(1.5, 1.5, 4),
					Sensitivity = 1/600,
					LerpingSpeed = 0.5
				}
				
			}
			----
		},
		CLASS
	)
	local proxyTable = setmetatable(
		{
			
		},
		{
			__index = function(self, index)
				return dataTable[index]
			end,
			__newindex = function(self, index, newValue)
				dataTable[index] = newValue
			end
		}
	)
	
	return proxyTable
end

--// FUNCTIONS //--

local function Lerp(x, y, a)
	return x + (y - x) * a
end

--// METHODS //--

function CLASS:SetCameraFollow(status)
	assert(status ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
	assert(typeof(status) == "boolean", "OTS Camera System Argument Error: boolean expected, got " .. typeof(status))
	
	self.CameraFollow = status
	self.CameraFollowChangedEvent:Fire(status)
end

function CLASS:SetActiveCameraSettings(cameraSettings)
	assert(cameraSettings ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
	assert(typeof(cameraSettings) == "string", "OTS Camera System Argument Error: string expected, got " .. typeof(cameraSettings))
	assert(self.CameraSettings[cameraSettings] ~= nil, "OTS Camera System Argument Error: Attempt to set unrecognized camera settings " .. cameraSettings)
	
	self.ActiveCameraSettings = cameraSettings
	self.ActiveCameraSettingsChangedEvent:Fire(cameraSettings)
end

function CLASS:SetShoulderDirection(shoulderDirection)
	assert(shoulderDirection ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
	assert(typeof(shoulderDirection) == "number", "OTS Camera System Argument Error: number expected, got " .. typeof(shoulderDirection))
	assert(math.abs(shoulderDirection) == 1, "OTS Camera System Argument Error: Attempt to set unrecognized shoulder direction " .. shoulderDirection)
	
	self.ShoulderDirection = shoulderDirection
	self.ShoulderDirectionChangedEvent:Fire(shoulderDirection)
end

function CLASS:StepOut()
	assert(self.IsEnabled == true, "OTS Camera System Logic Error: Attempt to step out without enabling")
	assert(self.IsSteppedOut == false, "OTS Camera System Logic Error: Attempt to step out without stepping in")
	
	self.IsSteppedOut = true
	self.SteppedOutEvent:Fire()
	USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default
end

function CLASS:StepIn()
	assert(self.IsEnabled == true, "OTS Camera System Logic Error: Attempt to step in without enabling")
	assert(self.IsSteppedOut == true, "OTS Camera System Logic Error: Attempt to step in without stepping out")
	
	self.IsSteppedOut = false
	self.SteppedInEvent:Fire()
	
	USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter
end

function CLASS:SaveCameraSettings()
	local currentCamera = workspace.CurrentCamera
	self.SavedCameraSettings = {
		FieldOfView = currentCamera.FieldOfView,
		CameraSubject = currentCamera.CameraSubject,
		CameraType = currentCamera.CameraType
	}
end

function CLASS:LoadCameraSettings()
	local currentCamera = workspace.CurrentCamera
	for setting, value in pairs(self.SavedCameraSettings) do
		currentCamera[setting] = value
	end
end

function CLASS:InitializeForEnable()
	self:SaveCameraSettings()
	self.SavedMouseBehavior = USER_INPUT_SERVICE.MouseBehavior
	
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	self:SetActiveCameraSettings("DefaultShoulder")
	self:StepIn()
	
	self.HorizontalAngle = 0
	self.VerticalAngle = 0
end

function CLASS:InitializeForDisable()
	self:LoadCameraSettings()
	self:SetCameraFollow(false)
	if (self.IsSteppedOut == false) then
		self:StepOut()
	end
	USER_INPUT_SERVICE.MouseBehavior = self.SavedMouseBehavior
end

function CLASS:Update()
	local currentCamera = workspace.CurrentCamera
	local activeCameraSettings = self.CameraSettings[self.ActiveCameraSettings]
	
	local mouseDelta = USER_INPUT_SERVICE:GetMouseDelta() * activeCameraSettings.Sensitivity
	self.HorizontalAngle = self.HorizontalAngle - mouseDelta.X
	self.VerticalAngle = self.VerticalAngle - mouseDelta.Y
	self.VerticalAngle = math.rad(math.clamp(math.deg(self.VerticalAngle), self.VerticalAngleLimits.Min, self.VerticalAngleLimits.Max))
	
	local character = LOCAL_PLAYER.Character
	local humanoidRootPart = (character ~= nil) and (character:FindFirstChild("HumanoidRootPart"))
	if (humanoidRootPart ~= nil) then
		
		-- Lerp field of view --
		currentCamera.FieldOfView = Lerp(currentCamera.FieldOfView, activeCameraSettings.FieldOfView, activeCameraSettings.LerpingSpeed)
		----
		
		-- Address shoulder direction --
		local offset = activeCameraSettings.Offset
		offset = Vector3.new(offset.X * self.ShoulderDirection, offset.Y, offset.Z)
		----
		
		-- Calculate new camera cframe --
		local newCameraCFrame = CFrame.new(humanoidRootPart.Position) *
			CFrame.Angles(0, self.HorizontalAngle, 0) *
			CFrame.Angles(self.VerticalAngle, 0, 0) *
			CFrame.new(offset)
		
		newCameraCFrame = currentCamera.CFrame:Lerp(newCameraCFrame, activeCameraSettings.LerpingSpeed)
		----
		
		-- Raycast for obstructions --
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {character}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		local raycastResult = workspace:Raycast(
			humanoidRootPart.Position,
			(newCameraCFrame.p - humanoidRootPart.Position).Unit * offset.Magnitude,
			raycastParams
		)
		----
		
		-- Address obstructions if any --
		if (raycastResult ~= nil) then
			local obstructionDisplacement = (raycastResult.Position - humanoidRootPart.Position)
			local obstructionPosition = humanoidRootPart.Position + (obstructionDisplacement.Unit * (obstructionDisplacement.Magnitude - 0.1))
			local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = newCameraCFrame:components()
			newCameraCFrame = CFrame.new(obstructionPosition.x, obstructionPosition.y, obstructionPosition.z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
		end
		----
		
		-- Address camera follow --
		if (self.CameraFollow == true) then
			local newHumanoidRootPartCFrame = CFrame.new(humanoidRootPart.Position) *
				CFrame.Angles(0, self.HorizontalAngle, 0)
			humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(newHumanoidRootPartCFrame, activeCameraSettings.LerpingSpeed/2)
		end
		----
		
		currentCamera.CFrame = newCameraCFrame
		
	else
		self:Disable()
	end
end

function CLASS:Enable()
	assert(self.IsEnabled == false, "OTS Camera System Logic Error: Attempt to enable without disabling")
	
	self.IsEnabled = true
	self.EnabledEvent:Fire()
	self:InitializeForEnable()
	RUN_SERVICE:BindToRenderStep(
		UPDATE_UNIQUE_KEY,
		Enum.RenderPriority.Camera.Value - 10,
		function()
			if (self.IsEnabled == true) then
				self:Update()
			else
				RUN_SERVICE:UnbindFromRenderStep(UPDATE_UNIQUE_KEY)
				self:InitializeForDisable()
			end
		end
	)
end

function CLASS:Disable()
	assert(self.IsEnabled == true, "OTS Camera System Logic Error: Attempt to disable without enabling")
	
	self.IsEnabled = false
	self.DisabledEvent:Fire()
end

--// INSTRUCTIONS //--

CLASS.__index = CLASS

local singleton = CLASS.new()

USER_INPUT_SERVICE.InputBegan:Connect(function(inputObject, gameProcessedEvent)
	if (gameProcessedEvent == false) then
		if (inputObject.KeyCode == Enum.KeyCode.Q) then
			singleton:SetShoulderDirection(-1)
		elseif (inputObject.KeyCode == Enum.KeyCode.E) then
			singleton:SetShoulderDirection(1)
		end
		if (inputObject.UserInputType == Enum.UserInputType.MouseButton2) then
			singleton:SetActiveCameraSettings("ZoomedShoulder")
		end
		
		if (inputObject.KeyCode == Enum.KeyCode.LeftControl) then
			if (singleton.IsEnabled == true) then
				if (singleton.IsSteppedOut == false) then
					singleton:StepOut()
				else
					singleton:StepIn()
				end
			end
		end
	end
end)

USER_INPUT_SERVICE.InputEnded:Connect(function(inputObject, gameProcessedEvent)
	if (gameProcessedEvent == false) then
		if (inputObject.UserInputType == Enum.UserInputType.MouseButton2) then
			singleton:SetActiveCameraSettings("DefaultShoulder")
		end
	end
end)


return singleton
