local _, NS = ...

local Interface = NS.Interface

local CreateFrame = CreateFrame
local IsPlayerMoving = IsPlayerMoving
local GetTime = GetTime
local UnitIsUnit = UnitIsUnit
local GetUnitSpeed = GetUnitSpeed

local mmin = math.min
local mmax = math.max
local sformat = string.format

local After = C_Timer.After
local GetGlidingInfo = C_PlayerInfo.GetGlidingInfo
local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetPlayerMapPosition = C_Map.GetPlayerMapPosition
local GetMapWorldSize = C_Map.GetMapWorldSize

---@type DMS
local DMS = NS.DMS
local DMSFrame = NS.DMS.frame

local isFalling = false
local isDriving = false
local isFlying = false
local isDragonRiding = false
local ascentSpell = 372610
local boostSpell = 1215073
local lastUpdatedSpeed = 0
local ascentStart = 0
local dynamicSpeed = 0
local speedtext = ""
local trueSpeedPercent = 0

local MAIN_EVENTS = {
  "PLAYER_ENTERING_WORLD",
  "PLAYER_MOUNT_DISPLAY_CHANGED",
  "UNIT_POWER_BAR_SHOW",
  "UNIT_POWER_BAR_HIDE",
  "UNIT_SPELLCAST_SUCCEEDED",
}

-- Falling
do
  local lastC = 0
  local lastT = 0
  local lastZ = 0
  local samples = 0
  local smoothSpeed = 0
  local lastSpeed = 0
  local smoothAccel = 0
  local lastAccel = 0

  local maxSamples = 5
  local updatePeriod = 1 / 10

  function DMS:GetFallingSpeed()
    local now = GetTime()

    -- Delta time
    local dc = now - lastC
    if dc < updatePeriod then
      -- Rate limit speed updates!
      return false
    end
    lastC = now

    isFalling = NS.IsFalling()

    -- Player position
    local currentX, currentY, currentZ = UnitPosition("player")
    if not currentZ then
      return
    end

    lastZ = currentZ
    lastT = lastT

    -- local currentSpeed = GetUnitSpeed("player")
    -- local isGliding, canGlide, forwardSpeed = GetGlidingInfo()
    -- local base = isGliding and forwardSpeed or currentSpeed

    print(currentX, currentY, currentZ)

    -- Delta position
    local dz = currentZ - lastZ

    -- Delta time
    local t = GetTime()
    local dt = t - lastT

    if dt == 0 then
      return
    end

    lastZ = currentZ
    lastT = t

    -- Vertical speed (yd/s), falling is negative
    local verticalSpeed = dz / dt

    -- Smooth speed using exponential moving average
    samples = math.min(samples + 1, maxSamples)
    local lastWeight = (samples - 1) / samples
    local newWeight = 1 / samples
    smoothSpeed = smoothSpeed * lastWeight + verticalSpeed * newWeight

    -- Only track falling speeds
    if smoothSpeed >= -1 then
      return false
    end

    -- Optional: show only falling
    if verticalSpeed < -1 then
      print(string.format("Falling at %.2f yd/s", -verticalSpeed))
    end

    -- Convert to % based on base speed (use absolute value)
    local percentSpeed = (math.abs(smoothSpeed) / BASE_MOVEMENT_SPEED) * 100

    -- Clamp it for sanity
    percentSpeed = math.min(percentSpeed, 500)

    -- Optional debug print
    print(string.format("Falling at %.2f yd/s (%d%%)", -smoothSpeed, percentSpeed))

    -- Convert to % movement speed
    dynamicSpeed = math.abs(smoothSpeed)
  end
end

-- D.R.I.V.E.
do
  local lastC = 0
  local lastT = 0
  local lastX = 0
  local lastY = 0
  local samples = 0
  local smoothSpeed = 0
  local lastSpeed = 0
  local smoothAccel = 0
  local lastAccel = 0

  local maxSamples = 5
  local updatePeriod = 1 / 10

  function DMS:GetDrivingSpeed()
    local now = GetTime()

    -- Delta time
    local dc = now - lastC
    if dc < updatePeriod then
      -- Rate limit speed updates!
      return false
    end
    lastC = now

    isDriving = NS.IsDriving()

    -- Map position
    local map = GetBestMapForUnit("player")
    if not map then
      return
    end

    -- Player position
    local pos = GetPlayerMapPosition(map, "player")
    if not pos then
      return
    end

    -- Get flying speed
    local currentSpeed = GetUnitSpeed("player")
    local speed = currentSpeed

    -- x, y coordinates
    local x, y = pos:GetXY()
    local w, h = GetMapWorldSize(map)
    x = x * w
    y = y * h

    -- Delta position
    local dx = x - (lastX or 0)
    local dy = y - (lastY or 0)
    lastX = x
    lastY = y

    -- Delta time
    local t = GetTime()
    local dt = t - (lastT or 0)
    lastT = t

    if dt == 0 then
      return
    end

    -- Compute horizontal speed
    speed = math.sqrt(dx * dx + dy * dy)

    -- Adjust for delta time
    speed = speed / dt

    -- Skip huge jumps (teleports, lag spikes)
    if math.abs(speed - (lastSpeed or 0)) > 100 then
      -- Reset samples on huge apparent speed changes
      smoothAccel = 0
      samples = 0
      return
    end

    -- Compute smooth speed
    samples = math.min(maxSamples, samples + 1)
    local lastWeight = (samples - 1) / samples
    local newWeight = 1 / samples

    smoothSpeed = speed
    local newAccel = smoothSpeed - lastSpeed
    smoothSpeed = smoothSpeed * lastWeight + speed * newWeight
    lastSpeed = smoothSpeed

    -- Compute smooth speed and acceleration
    smoothAccel = smoothAccel * lastWeight + newAccel * newWeight
    lastAccel = smoothAccel

    -- Convert to % movement speed
    dynamicSpeed = smoothSpeed
  end
end

-- Dragon Riding
do
  local thrillBuff = 377234
  local lastT = 0
  local samples = 0
  local smoothSpeed = 0
  local lastSpeed = 0
  local smoothAccel = 0
  local lastAccel = 0
  local speedshowunits = true

  local maxSamples = 5
  local ascentDuration = 3.5
  local updatePeriod = 1 / 10
  local speedunits = 2

  local speedTextFormat, speedTextFactor = "", 1
  if speedunits == 1 then
    speedTextFormat = speedshowunits and "%.1fyd/s" or "%.1f"
  else
    speedTextFormat = speedshowunits and "%.0f%%" or "%.0f"
    speedTextFactor = 100 / BASE_MOVEMENT_SPEED
  end

  local isThrill = false
  local isBoosting = false

  function DMS:GetDragonRidingSpeed()
    local time = GetTime()

    -- Delta time
    local dt = time - lastT
    if dt < updatePeriod then
      -- Rate limit speed updates!
      return false
    end
    lastT = time

    isDriving = NS.IsDriving()
    isFlying = NS.IsFlying()

    -- Get flying speed
    local _, _, forwardSpeed = GetGlidingInfo()
    local speed = forwardSpeed

    local thrill = GetPlayerAuraBySpellID(thrillBuff)
    local boosting = thrill and time < ascentStart + ascentDuration or false

    -- Compute smooth speed
    samples = mmin(maxSamples, samples + 1)
    local lastWeight = (samples - 1) / samples
    local newWeight = 1 / samples

    smoothSpeed = speed
    local newAccel = smoothSpeed - lastSpeed
    lastSpeed = smoothSpeed

    -- Compute smooth acceleration
    smoothAccel = smoothAccel * lastWeight + newAccel * newWeight
    if speed > 63 then
      -- Don't track negative acceleration when boosting
      smoothAccel = mmax(0, smoothAccel)
    end
    if not isFlying then
      smoothAccel = 0 -- Don't track acceleration on ground
    end
    lastAccel = smoothAccel
    -- NS.Debug("smoothAccel", smoothAccel)
    -- NS.Debug("lastAccel", lastAccel)

    -- Update display variables
    isBoosting = boosting
    isThrill = not not thrill
    -- NS.Debug("isBoosting", isBoosting)
    -- NS.Debug("isThrill", isThrill)

    dynamicSpeed = smoothSpeed * speedTextFactor
    speedtext = smoothSpeed < 1 and "" or sformat(speedTextFormat, dynamicSpeed)
  end
end

-- Player Moving
do
  --- @class PlayerMovingFrame
  --- @field moving boolean|nil
  --- @field speed integer|nil

  --- @type PlayerMovingFrame|Frame|nil
  local playerMovingFrame = nil

  local function PlayerMoveUpdate()
    local moving = IsPlayerMoving()
    isFalling = NS.IsFalling()
    isDriving = NS.IsDriving()
    isDragonRiding = NS.IsDragonRiding()
    isFlying = NS.IsFlying()

    if playerMovingFrame and (playerMovingFrame.moving ~= moving or playerMovingFrame.moving == nil) then
      playerMovingFrame.moving = moving
    end

    local currentSpeed, runSpeed = NS.GetSpeedInfo()
    local correctSpeed = currentSpeed

    -- if isFalling then
    --  DMS:GetFallingSpeed()
    --  correctSpeed = dynamicSpeed
    -- end

    if moving and isDriving then
      DMS:GetDrivingSpeed()
      correctSpeed = dynamicSpeed
    end

    if moving and isFlying and isDragonRiding then
      DMS:GetDragonRidingSpeed()
      correctSpeed = dynamicSpeed
    end

    if playerMovingFrame and playerMovingFrame.speed ~= correctSpeed then
      playerMovingFrame.speed = correctSpeed

      local speedPercent = playerMovingFrame.speed

      if playerMovingFrame.moving or correctSpeed > 0 then
        local showSpeed = correctSpeed
        if not isFlying and not isDriving then
          showSpeed = currentSpeed == 0 and runSpeed or currentSpeed
        end

        speedPercent = showSpeed
      else
        local showSpeed = NS.db.global.showzero and 0 or runSpeed
        speedPercent = showSpeed
      end

      NS.Interface.speed = speedPercent
      NS.UpdateText(Interface.text, speedPercent, NS.db.global.decimals, NS.db.global.round)
    end
  end

  function DMS:WatchForPlayerMoving()
    isFalling = NS.IsFalling()
    isDriving = NS.IsDriving()
    isDragonRiding = NS.IsDragonRiding()
    isFlying = NS.IsFlying()

    local currentSpeed, runSpeed = NS.GetSpeedInfo()

    local showSpeed = currentSpeed == 0 and (NS.db.global.showzero and 0 or runSpeed) or currentSpeed
    NS.UpdateText(Interface.text, showSpeed, NS.db.global.decimals, NS.db.global.round)

    if not playerMovingFrame then
      playerMovingFrame = CreateFrame("Frame")
      --- @cast playerMovingFrame PlayerMovingFrame
      playerMovingFrame.speed = currentSpeed

      local runSpeedPercent = runSpeed
      showSpeed = currentSpeed == 0 and (NS.db.global.showzero and 0 or runSpeedPercent) or currentSpeed
      NS.Interface.speed = showSpeed
      NS.UpdateText(Interface.text, showSpeed, NS.db.global.decimals, NS.db.global.round)
    end

    playerMovingFrame:SetScript("OnUpdate", PlayerMoveUpdate)
  end
end

function DMS:PLAYER_ENTERING_WORLD()
  isFalling = NS.IsFalling()
  isDriving = NS.IsDriving()
  isDragonRiding = NS.IsDragonRiding()
  isFlying = NS.IsFlying()

  self:WatchForPlayerMoving()

  if NS.db and NS.db.global.debug then
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetPoint("CENTER", 0, 50)
    f:SetSize(132, 50)
    f:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0, 0, 0, 0.5)
    f.glide = f:CreateFontString(nil, nil, "GameTooltipText")
    f.glide:SetPoint("TOPLEFT", 10, -12)
    f.movespeed = f:CreateFontString(nil, nil, "GameTooltipText")
    f.movespeed:SetPoint("TOPLEFT", f.glide, "BOTTOMLEFT")
    C_Timer.NewTicker(0.1, function()
      local isGliding, canGlide, forwardSpeed = GetGlidingInfo()
      local base = isGliding and forwardSpeed or GetUnitSpeed("player")
      local movespeed = Round(base / BASE_MOVEMENT_SPEED * 100)
      f.glide:SetText(format("Gliding speed: |cff71d5ff%d%%|r", forwardSpeed))
      f.movespeed:SetText(format("Move speed: |cffffff00%d%%|r", movespeed))
    end)
  end
end

local function checkSpeed()
  local _, runSpeed = NS.GetSpeedInfo()
  if runSpeed == lastUpdatedSpeed then
    After(0.1, checkSpeed)
  else
    isFalling = NS.IsFalling()
    isDriving = NS.IsDriving()
    isDragonRiding = NS.IsDragonRiding()
    isFlying = NS.IsFlying()
    DMS:WatchForPlayerMoving()
  end
end

function DMS:PLAYER_MOUNT_DISPLAY_CHANGED()
  local _, runSpeed = NS.GetSpeedInfo()
  lastUpdatedSpeed = runSpeed
  After(0, checkSpeed)
end

function DMS:UNIT_POWER_BAR_SHOW(unitTarget)
  if UnitIsUnit(unitTarget, "player") then
    isFalling = NS.IsFalling()
    isDriving = NS.IsDriving()
    isDragonRiding = NS.IsDragonRiding()
    isFlying = NS.IsFlying()
    self:WatchForPlayerMoving()
  end
end

function DMS:UNIT_POWER_BAR_HIDE(unitTarget)
  if UnitIsUnit(unitTarget, "player") then
    isFalling = NS.IsFalling()
    isDriving = NS.IsDriving()
    isDragonRiding = NS.IsDragonRiding()
    isFlying = NS.IsFlying()
    self:WatchForPlayerMoving()
  end
end

function DMS:UNIT_SPELLCAST_SUCCEEDED(unitTarget, _, spellID)
  if UnitIsUnit(unitTarget, "player") then
    if spellID == ascentSpell or spellID == boostSpell then
      ascentStart = GetTime()
    end
  end
end

function DMS:PLAYER_LOGIN()
  DMSFrame:UnregisterEvent("PLAYER_LOGIN")
  Interface:CreateInterface()
  FrameUtil.RegisterFrameForEvents(DMSFrame, MAIN_EVENTS)
end
DMSFrame:RegisterEvent("PLAYER_LOGIN")
