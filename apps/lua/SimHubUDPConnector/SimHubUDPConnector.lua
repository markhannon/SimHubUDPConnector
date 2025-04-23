---@diagnostic disable: cast-local-type, duplicate-set-field, lowercase-global, need-check-nil
local socket = require('shared/socket')
local udp = socket.udp()
udp:settimeout(0)
udp:setpeername("127.0.0.1", 20777)
local DEBUG_ON = true
local sim = ac.getSim()
local customData
local carState = ac.getCar(0)
local wheelsState = carState.wheels -- required for the Road Rumble Effect
local carPhysics = ac.getCarPhysics(0)
local cspVersion = ac.getPatchVersion()

function checkHasCarConnection()
	local carPath, ret
	local success = false
	local carId = ac.getCarID(0)
	carPath = ac.dirname() .. "/cars/" .. carId
	if io.fileExists(carPath .. "/connection.lua") then
		try(
			function() --try
				ret = require("cars."..carId..".connection")
				if ret then
					success = true
				end
			end,
			function(err) --catch
				print("checkExtendedCar app ERROR: "..err.."\n"..carPath)
				success = false
			end
		)
	end
	return success
end

local hasCarConnection = checkHasCarConnection()

---Load car data INI file. Supports “data.acd” files as well. Returned files might be tweaked by
---things like custom physics virtual tyres. To get original file, use `ac.INIConfig.load()`.
---
---Returned file can’t be saved.
---@diagnostic disable-next-line: undefined-doc-param
---@param carIndex number @0-based car index.
---@diagnostic disable-next-line: undefined-doc-param
---@param fileName string @Car data file name, such as `'tyres.ini'`.
---@return ac.INIConfig
-- local carData = ac.INIConfig.carData(0, "tyres.ini")
-- ac.debug('Car Data', carData)

-- this function is required for the Road Rumble effect
local function getSurface(surfaceId)
	if (surfaceId == 0) then
		do return 'Base' end
	elseif (surfaceId == 1) then
		do return 'ExtraTurf' end
	elseif (surfaceId == 2) then
		do return 'Grass' end
	elseif (surfaceId == 3) then
		do return 'Gravel' end
	elseif (surfaceId == 4) then
		do return 'Kerb' end
	elseif (surfaceId == 5) then
		do return 'Old' end
	elseif (surfaceId == 6) then
		do return 'Sand' end
	elseif (surfaceId == 7) then
		do return 'Ice' end
	elseif (surfaceId == 8) then
		do return 'Snow' end
	else
		do return 'Unknown' end
	end
end
-- end

function addAllData(from, fields, prefix, to)
	for k, v in pairs(fields) do
		local name = prefix .. v:sub(1, 1):upper() .. v:sub(2)
		to[name] = from[v]
	end
end

local function debugData(data)
	for k, v in pairs(data) do
		ac.debug(k, v)
	end
end

function script.update(dt)
	if (carState == nil) then return end
	customData = {
		AmbientTemperature = sim.ambientTemperature,
		Autoclutch = carState.autoClutch,
		Brake = carState.brake,
		CarDirection = carState.compass,
		CarForceFeedback = carState.ffbMultiplier * 100,
		Clutch = (carState.autoClutch) and (carState.clutch) or (1 - carState.clutch),
		-- this part is required for the collisions detection
		CollisionPositionX = carState.collisionPosition.x,
		CollisionPositionY = carState.collisionPosition.y,
		CollisionPositionZ = carState.collisionPosition.z,
		CollidedWithId = carState.collidedWith,
		CollidedWith = (carState.collidedWith == 0) and 'Track' or
		((carState.collidedWith > 0) and ac.getDriverName(carState.collidedWith) or 'None'),
		-- end
		CSPVersion = cspVersion,
		DifferentialPreload = carState.differentialPreload,
		DifferenialCoast = carState.differentialCoast,
		DifferentialPower = carState.differentialPower,
		-- drift part
		DriftPoints = carState.driftPoints,
		DriftComboCounter = carState.driftComboCounter,
		DriftInstantPoints = carState.driftInstantPoints,
		IsDriftBonusOn = carState.isDriftBonusOn,
		IsDriftValid = carState.isDriftValid,
		-- end
		ExtraA = carState.extraA,
		ExtraB = carState.extraB,
		ExtraC = carState.extraC,
		ExtraD = carState.extraD,
		ExtraE = carState.extraE,
		ExtraF = carState.extraF,
		ExtraG = carState.extraG,
		FPS = sim.fps,
		FuelMap = carState.fuelMap,
		Handbrake = carState.handbrake,
		HazardLights = carState.hazardLights,
		HeadlightsActive = carState.headlightsActive,
		HighBeam = not carState.lowBeams,
		IngameHours = sim.timeHours,
		IngameMinutes = sim.timeMinutes,
		IsInPitlane = carState.isInPitlane,
		IsInPit	= carState.isInPit,
		KERSCharge = carState.kersCharge,
		KERSCharging = carState.kersCharging,
		KERSCurrentKJ = carState.kersCurrentKJ,
		KERSLoad = carState.kersLoad,
		KERSMaxKJ = carState.kersMaxKJ,
		KERSPresent = carState.kersPresent,
		LightOptions = carState.hasLowBeams,
		LimiterOn = carState.manualPitsSpeedLimiterEnabled,
		LimiterSpeed = carState.speedLimiter,
		MGUHChargingBatteries = carState.mguhChargingBatteries,
		MGUKDelivery = carState.mgukDelivery,
		MGUKDeliveryCount = carState.mgukDeliveryCount,
		MGUKDeliveryName = ac.getMGUKDeliveryName(0, -1),
		MGUKRecovery = carState.mgukRecovery, -- 0 to 10 (10 for 100%)		
		OilPressure = carState.oilPressure,
		OilTemperature = carState.oilTemperature,
		Steer = carState.steer,
		SteerLock = carState.steerLock,
		TC2 = carState.tractionControl2,
		Throttle = carState.gas,
		Turn = ac.getTrackSectorName(ac.worldCoordinateToTrackProgress(carState.position)),
		TurningLeftLights = carState.turningLeftLights,
		TurningRightLights = carState.turningRightLights,
		WaterTemperature = carState.waterTemperature,
		WindDirectionDeg = sim.windDirectionDeg,
		WindSpeedKmh = sim.windSpeedKmh,
		WiperModes = carState.wiperModes,
		WiperMode = carState.wiperMode,
		WiperSelectedMode = carState.wiperSelectedMode,
		WiperSpeed = carState.wiperSpeed,
		WiperProgress = carState.wiperProgress,
		-- Tyres
		FrontLeftTyreOptimumTemperature = wheelsState[0].tyreOptimumTemperature,
		FrontRightOptimumTemperature = wheelsState[1].tyreOptimumTemperature,
		RearLeftTyreOptimumTemperature = wheelsState[2].tyreOptimumTemperature,
		RearRightTyreOptimumTemperature = wheelsState[3].tyreOptimumTemperature,
		FrontLeftTyreCarcassTemperature = carPhysics.wheels[0].tyreCarcassTemperature,
		FrontRightTyreCarcassTemperature = carPhysics.wheels[1].tyreCarcassTemperature,
		RearLeftTyreCarcassTemperature = carPhysics.wheels[2].tyreCarcassTemperature,
		RearRightTyreCarcassTemperature = carPhysics.wheels[3].tyreCarcassTemperature,
	}
---@diagnostic disable-next-line: param-type-mismatch
	if (cspVersion.versionCompare(cspVersion, "0.2.7") > -1) then
		-- this part is required for the Road Rumble effect
		customData.WheelFLSurface = getSurface(wheelsState[0].surfaceExtendedType)
		customData.WheelFLSurfaceVibrationGain = wheelsState[0].surfaceVibrationGain
		customData.WheelFLSurfaceVibrationLength = wheelsState[0].surfaceVibrationLength
		customData.WheelFLTyreOptimumTemperature = wheelsState[0].tyreOptimumTemperature
		customData.WheelFLSlipAngle = wheelsState[0].slipAngle
		customData.WheelFLSpeedDifference = wheelsState[0].speedDifference
		customData.WheelFRSurface = getSurface(wheelsState[1].surfaceExtendedType)
		customData.WheelFRSurfaceVibrationGain = wheelsState[1].surfaceVibrationGain
		customData.WheelFRSurfaceVibrationLength = wheelsState[1].surfaceVibrationLength
		customData.WheelFRTyreOptimumTemperature = wheelsState[1].tyreOptimumTemperature
		customData.WheelFRSlipAngle = wheelsState[1].slipAngle
		customData.WheelFRSpeedDifference = wheelsState[1].speedDifference
		customData.WheelRLSurface = getSurface(wheelsState[2].surfaceExtendedType)
		customData.WheelRLSurfaceVibrationGain = wheelsState[2].surfaceVibrationGain
		customData.WheelRLSurfaceVibrationLength = wheelsState[2].surfaceVibrationLength
		customData.WheelRLTyreOptimumTemperature = wheelsState[2].tyreOptimumTemperature
		customData.WheelRLSlipAngle = wheelsState[2].slipAngle
		customData.WheelRLSpeedDifference = wheelsState[2].speedDifference
		customData.WheelRRSurface = getSurface(wheelsState[3].surfaceExtendedType)
		customData.WheelRRSurfaceVibrationGain = wheelsState[3].surfaceVibrationGain
		customData.WheelRRSurfaceVibrationLength = wheelsState[3].surfaceVibrationLength
		customData.WheelRRTyreOptimumTemperature = wheelsState[3].tyreOptimumTemperature
		customData.WheelRRSlipAngle = wheelsState[3].slipAngle
		customData.WheelRRSpeedDifference = wheelsState[3].speedDifference
		-- end
	else
		customData.WheelSurfaceError = "Please upgrade your csp to version 0.2.7 min."
	end

	if (hasCarConnection) then
---@diagnostic disable-next-line: undefined-global
		carScript(customData)
	end
	local jsonData = JSON.stringify(customData)
	udp:send(jsonData)

	-- for debug only
	if DEBUG_ON then
		debugData(customData)
		-- ac.debug("jsonData", jsonData)
	end
end

function script.onStop()
	udp:close()
end