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
	
	--// Events //--
	local activeCameraSettingsChangedEvent = Instance.new("BindableEvent")
	local characterAlignmentChangedEvent = Instance.new("BindableEvent")
	local mouseStepChangedEvent = Instance.new("BindableEvent")
	local shoulderDirectionChangedEvent = Instance.new("BindableEvent")
	local enabledEvent = Instance.new("BindableEvent")
	local disabledEvent = Instance.new("BindableEvent")
	----
	
	local dataTable = setmetatable(
		{
			
			--// Properties //--
			SavedCameraSettings = nil,
			SavedMouseBehavior = nil,
			ActiveCameraSettings = nil,
			HorizontalAngle = 0,
			VerticalAngle = 0,
			ShoulderDirection = 1,
			----
			
			--// Flags //--
			IsCharacterAligned = false,
			IsMouseSteppedIn = false,
			IsEnabled = false,
			----
			
			--// Events //--
			ActiveCameraSettingsChangedEvent = activeCameraSettingsChangedEvent,
			ActiveCameraSettingsChanged = activeCameraSettingsChangedEvent.Event,
			CharacterAlignmentChangedEvent = characterAlignmentChangedEvent,
			CharacterAlignmentChanged = characterAlignmentChangedEvent.Event,
			MouseStepChangedEvent = mouseStepChangedEvent,
			MouseStepChanged = mouseStepChangedEvent.Event,
			ShoulderDirectionChangedEvent = shoulderDirectionChangedEvent,
			ShoulderDirectionChanged = shoulderDirectionChangedEvent.Event,
			EnabledEvent = enabledEvent,
			Enabled = enabledEvent.Event,
			DisabledEvent = disabledEvent,
			Disabled = disabledEvent.Event,
			----
			
			--// Configurations //--
			VerticalAngleLimits = NumberRange.new(-45, 45),
			----
			
			--// Camera Settings //--
			CameraSettings = {
				
				DefaultShoulder = {
					FieldOfView = 70,
					Offset = Vector3.new(2.5, 2.5, 8),
					Sensitivity = 3,
					LerpSpeed = 0.5
				},
				
				ZoomedShoulder = {
					FieldOfView = 40,
					Offset = Vector3.new(1.5, 1.5, 6),
					Sensitivity = 1.5,
					LerpSpeed = 0.5
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

--// //--
function CLASS:SetActiveCameraSettings(cameraSettings)
	assert(cameraSettings ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
	assert(typeof(cameraSettings) == "string", "OTS Camera System Argument Error: string expected, got " .. typeof(cameraSettings))
	assert(self.CameraSettings[cameraSettings] ~= nil, "OTS Camera System Argument Error: Attempt to set unrecognized camera settings " .. cameraSettings)
	if (self.IsEnabled == false) then
		warn("OTS Camera System Logic Warning: Attempt to change active camera settings without enabling OTS camera system")
		return
	end

	self.ActiveCameraSettings = cameraSettings
	self.ActiveCameraSettingsChangedEvent:Fire(cameraSettings)
end

function CLASS:SetCharacterAlignment(aligned)
	assert(aligned ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
	assert(typeof(aligned) == "boolean", "OTS Camera System Argument Error: boolean expected, got " .. typeof(aligned))
	if (self.IsEnabled == false) then
		warn("OTS Camera System Logic Warning: Attempt to change character alignment without enabling OTS camera system")
		return
	end
	
	self.IsCharacterAligned = aligned
	self.CharacterAlignmentChangedEvent:Fire(aligned)
end

function CLASS:SetMouseStep(steppedIn)
	assert(steppedIn ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
	assert(typeof(steppedIn) == "boolean", "OTS Camera System Argument Error: boolean expected, got " .. typeof(steppedIn))
	if (self.IsEnabled == false) then
		warn("OTS Camera System Logic Warning: Attempt to change mouse step without enabling OTS camera system")
		return
	end
	
	self.IsMouseSteppedIn = steppedIn
	self.MouseStepChangedEvent:Fire(steppedIn)
	if (steppedIn == true) then
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default
	end
end

function CLASS:SetShoulderDirection(shoulderDirection)
	assert(shoulderDirection ~= nil, "OTS Camera System Argument Error: Argument 1 nil or missing")
	assert(typeof(shoulderDirection) == "number", "OTS Camera System Argument Error: number expected, got " .. typeof(shoulderDirection))
	assert(math.abs(shoulderDirection) == 1, "OTS Camera System Argument Error: Attempt to set unrecognized shoulder direction " .. shoulderDirection)
	if (self.IsEnabled == false) then
		warn("OTS Camera System Logic Warning: Attempt to change shoulder direction without enabling OTS camera system")
		return
	end
	
	self.ShoulderDirection = shoulderDirection
	self.ShoulderDirectionChangedEvent:Fire(shoulderDirection)
end
----

--// //--
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
----

--// //--
function CLASS:Update()
	local currentCamera = workspace.CurrentCamera
	local activeCameraSettings = self.CameraSettings[self.ActiveCameraSettings]
	
	--// Address mouse behavior and camera type //--
	if (self.IsMouseSteppedIn == true) then
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default
	end
	currentCamera.CameraType = Enum.CameraType.Scriptable
	---
	
	--// Address mouse input //--
	local mouseDelta = USER_INPUT_SERVICE:GetMouseDelta() * activeCameraSettings.Sensitivity
	self.HorizontalAngle -= mouseDelta.X/currentCamera.ViewportSize.X
	self.VerticalAngle -= mouseDelta.Y/currentCamera.ViewportSize.Y
	self.VerticalAngle = math.rad(math.clamp(math.deg(self.VerticalAngle), self.VerticalAngleLimits.Min, self.VerticalAngleLimits.Max))
	----
	
	local character = LOCAL_PLAYER.Character
	local humanoidRootPart = (character ~= nil) and (character:FindFirstChild("HumanoidRootPart"))
	if (humanoidRootPart ~= nil) then
		
		--// Lerp field of view //--
		currentCamera.FieldOfView = Lerp(
			currentCamera.FieldOfView, 
			activeCameraSettings.FieldOfView, 
			activeCameraSettings.LerpSpeed
		)
		----
		
		--// Address shoulder direction //--
		local offset = activeCameraSettings.Offset
		offset = Vector3.new(offset.X * self.ShoulderDirection, offset.Y, offset.Z)
		----
		
		--// Calculate new camera cframe //--
		local newCameraCFrame = CFrame.new(humanoidRootPart.Position) *
			CFrame.Angles(0, self.HorizontalAngle, 0) *
			CFrame.Angles(self.VerticalAngle, 0, 0) *
			CFrame.new(offset)
		
		newCameraCFrame = currentCamera.CFrame:Lerp(newCameraCFrame, activeCameraSettings.LerpSpeed)
		----
		
		--// Raycast for obstructions //--
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {character}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		local raycastResult = workspace:Raycast(
			humanoidRootPart.Position,
			newCameraCFrame.p - humanoidRootPart.Position,
			raycastParams
		)
		----
		
		--// Address obstructions if any //--
		if (raycastResult ~= nil) then
			local obstructionDisplacement = (raycastResult.Position - humanoidRootPart.Position)
			local obstructionPosition = humanoidRootPart.Position + (obstructionDisplacement.Unit * (obstructionDisplacement.Magnitude - 0.1))
			local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = newCameraCFrame:components()
			newCameraCFrame = CFrame.new(obstructionPosition.x, obstructionPosition.y, obstructionPosition.z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
		end
		----
		
		--// Address character alignment //--
		if (self.IsCharacterAligned == true) then
			local newHumanoidRootPartCFrame = CFrame.new(humanoidRootPart.Position) *
				CFrame.Angles(0, self.HorizontalAngle, 0)
			humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(newHumanoidRootPartCFrame, activeCameraSettings.LerpSpeed/2)
		end
		----
		
		currentCamera.CFrame = newCameraCFrame
		
	else
		self:Disable()
	end
end

function CLASS:ConfigureStateForEnabled()
	self:SaveCameraSettings()
	self.SavedMouseBehavior = USER_INPUT_SERVICE.MouseBehavior
	self:SetActiveCameraSettings("DefaultShoulder")
	self:SetCharacterAlignment(false)
	self:SetMouseStep(true)
	self:SetShoulderDirection(1)
	
	--// Calculate angles //--
	local defaultCFrame = CFrame.new()
	local cameraCFrame = workspace.CurrentCamera.CFrame
	local horizontalAngle = -math.acos(defaultCFrame.RightVector:Dot(cameraCFrame.RightVector))
	local verticalAngle = math.acos(defaultCFrame.UpVector:Dot(cameraCFrame.UpVector))
	----
	
	self.HorizontalAngle = horizontalAngle
	self.VerticalAngle = verticalAngle
end

function CLASS:ConfigureStateForDisabled()
	self:LoadCameraSettings()
	USER_INPUT_SERVICE.MouseBehavior = self.SavedMouseBehavior
	self:SetActiveCameraSettings("DefaultShoulder")
	self:SetCharacterAlignment(false)
	self:SetMouseStep(false)
	self:SetShoulderDirection(1)
	self.HorizontalAngle = 0
	self.VerticalAngle = 0
end

function CLASS:Enable()
	assert(self.IsEnabled == false, "OTS Camera System Logic Error: Attempt to enable without disabling")
	
	self.IsEnabled = true
	self.EnabledEvent:Fire()
	self:ConfigureStateForEnabled()
	
	RUN_SERVICE:BindToRenderStep(
		UPDATE_UNIQUE_KEY,
		Enum.RenderPriority.Camera.Value - 10,
		function()
			if (self.IsEnabled == true) then
				self:Update()
			end
		end
	)
end

function CLASS:Disable()
	assert(self.IsEnabled == true, "OTS Camera System Logic Error: Attempt to disable without enabling")
	
	self:ConfigureStateForDisabled()
	self.IsEnabled = false
	self.DisabledEvent:Fire()
	
	RUN_SERVICE:UnbindFromRenderStep(UPDATE_UNIQUE_KEY)
end
----

--// INSTRUCTIONS //--

CLASS.__index = CLASS

local singleton = CLASS.new()

USER_INPUT_SERVICE.InputBegan:Connect(function(inputObject, gameProcessedEvent)
	if (gameProcessedEvent == false) and (singleton.IsEnabled == true) then
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
				singleton:SetMouseStep(not singleton.IsMouseSteppedIn)
			end
		end
	end
end)

USER_INPUT_SERVICE.InputEnded:Connect(function(inputObject, gameProcessedEvent)
	if (gameProcessedEvent == false) and (singleton.IsEnabled == true) then
		if (inputObject.UserInputType == Enum.UserInputType.MouseButton2) then
			singleton:SetActiveCameraSettings("DefaultShoulder")
		end
	end
end)


return singleton
