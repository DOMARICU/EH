local CheatLib = {}

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = game:GetService("Players").LocalPlayer

local flightEnabled = false
local flingStartTime = 0
local FLING_DELAY = 0.6
CheatLib.vehicleFlingEnabled = false
local straightFlightStartTime = nil
local STRAIGHT_FLIGHT_DURATION = 1
local SHIFT_DISTANCE = 10
local POSITION_LERP_ALPHA = 0.3
local ROTATION_LERP_ALPHA = 0.2
local kmhToSpeed = 7.77
local flightSpeed = 25 * kmhToSpeed

local lastGroundCheck = 0
local GROUND_CHECK_INTERVAL = 20
local MAX_SAFE_HEIGHT = 50

local function turncaroff()
	local vehiclesFolder = workspace:FindFirstChild("Vehicles")
	if vehiclesFolder then
		local playerVehicle = vehiclesFolder:FindFirstChild(player.Name)
		if playerVehicle and playerVehicle:IsA("Model") then
			playerVehicle:SetAttribute("IsOn", false)
			local humanoid = playerVehicle:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.MaxHealth = 500
				humanoid.Health = 500
			end
		end
	end
end

local function checkHeightAndCorrect(vehicle)
	if not vehicle or not vehicle.PrimaryPart then return end
	
	local currentTime = tick()
	
	if currentTime - lastGroundCheck >= GROUND_CHECK_INTERVAL then
		lastGroundCheck = currentTime
		
		for _, part in pairs(vehicle:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
				part.Velocity = Vector3.zero
				part.RotVelocity = Vector3.zero
			end
		end
	end
	
	if vehicle.PrimaryPart.Position.Y > MAX_SAFE_HEIGHT then
		local downVector = Vector3.new(0, -10, 0)
		vehicle:SetPrimaryPartCFrame(vehicle.PrimaryPart.CFrame + downVector)
	end
end

RunService.RenderStepped:Connect(function(deltaTime)
	local character = player.Character
	if CheatLib.vehicleFlingEnabled then flightEnabled = true end

	if flightEnabled and character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.SeatPart and humanoid.SeatPart.Name == "DriveSeat" then
			local seat = humanoid.SeatPart
			local vehicle = seat.Parent
			if not vehicle.PrimaryPart then vehicle.PrimaryPart = seat end
			local lookVector = workspace.CurrentCamera.CFrame.LookVector
			if not lastPosition then lastPosition = vehicle.PrimaryPart.Position end
			if not lastLookVector then lastLookVector = lookVector end

			checkHeightAndCorrect(vehicle)

			local moveY = 0
			local moveZ = 0
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveZ = 1
			elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then moveZ = -1 end
			if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveY = 1
			elseif UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveY = -1 end

			local isFlyingStraight = UserInputService:IsKeyDown(Enum.KeyCode.W)
				and not UserInputService:IsKeyDown(Enum.KeyCode.S)
				and not UserInputService:IsKeyDown(Enum.KeyCode.E)
				and not UserInputService:IsKeyDown(Enum.KeyCode.Q)
				and not UserInputService:IsKeyDown(Enum.KeyCode.A)
				and not UserInputService:IsKeyDown(Enum.KeyCode.D)

			local currentTime = tick()
			if isFlyingStraight then
				if not straightFlightStartTime then straightFlightStartTime = currentTime end
				if not hasShiftedRight and (currentTime - straightFlightStartTime) >= STRAIGHT_FLIGHT_DURATION then
					local rightVector = lookVector:Cross(Vector3.new(0, 1, 0)).Unit
					local shiftPosition = vehicle.PrimaryPart.Position + (rightVector * SHIFT_DISTANCE)
					local shiftCFrame = CFrame.new(shiftPosition, shiftPosition + lookVector)
					vehicle:SetPrimaryPartCFrame(shiftCFrame)
					lastPosition = shiftPosition
					hasShiftedRight = true
				end
			else
				straightFlightStartTime = nil
				hasShiftedRight = false
			end

			local speedMultiplier = flightSpeed / 100
			local targetPosition = vehicle.PrimaryPart.Position + (lookVector * moveZ * speedMultiplier) + (Vector3.new(0, 1, 0) * moveY * speedMultiplier)
			local newPosition = lastPosition:Lerp(targetPosition, POSITION_LERP_ALPHA)
			local smoothLookVector = lastLookVector:Lerp(lookVector, ROTATION_LERP_ALPHA)

			if moveZ ~= 0 or moveY ~= 0 then
				local targetCFrame = CFrame.new(newPosition, newPosition + smoothLookVector)
				vehicle:SetPrimaryPartCFrame(targetCFrame)
			else
				local targetCFrame = CFrame.new(vehicle.PrimaryPart.Position, vehicle.PrimaryPart.Position + smoothLookVector)
				vehicle:SetPrimaryPartCFrame(targetCFrame)
			end

			lastPosition = newPosition
			lastLookVector = smoothLookVector

			for _, part in pairs(vehicle:GetDescendants()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
					part.Velocity = Vector3.zero
					part.RotVelocity = Vector3.zero
				end
			end
		else
			lastPosition = nil
			lastLookVector = nil
			straightFlightStartTime = nil
			hasShiftedRight = false
		end
	else
		lastPosition = nil
		lastLookVector = nil
		straightFlightStartTime = nil
		hasShiftedRight = false
	end
end)

RunService.Heartbeat:Connect(function()
	if CheatLib.vehicleFlingEnabled then
		local player = game.Players.LocalPlayer
		local c = player.Character
		if c then
			local h = c:FindFirstChildOfClass("Humanoid")
			if h and h.SeatPart and h:GetState() == Enum.HumanoidStateType.Seated then
				flingActive = true

				local currentTime = tick()
				if (currentTime - flingStartTime) >= FLING_DELAY then
					local hrp = c:FindFirstChild("HumanoidRootPart")
					if hrp then
						for _, part in pairs(hrp:GetTouchingParts()) do
							if part:IsA("BasePart") and part:IsDescendantOf(workspace) and not part:IsDescendantOf(player) then
								hrp.AssemblyLinearVelocity = -(part.Position - hrp.Position).Unit * 9999999
								turncaroff()
								break
							end
						end
					end
				end
			else
				flingActive = false
			end
		else
			flingActive = false
		end
	else
		flingActive = false
	end
end)

RunService.Heartbeat:Connect(function()
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.SeatPart then
			local vehicle = humanoid.SeatPart.Parent
			if vehicle and vehicle.PrimaryPart then
				if vehicle.PrimaryPart.Position.Y > MAX_SAFE_HEIGHT then
					local currentCF = vehicle.PrimaryPart.CFrame
					local newY = math.max(vehicle.PrimaryPart.Position.Y - 5, MAX_SAFE_HEIGHT - 100)
					local newPosition = Vector3.new(currentCF.X, newY, currentCF.Z)
					vehicle:SetPrimaryPartCFrame(CFrame.new(newPosition, newPosition + currentCF.LookVector))
				end
			end
		end
	end
end)

return CheatLib
