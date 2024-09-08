local _, NS = ...

local Interface = NS.Interface

local CreateFrame = CreateFrame
local IsPlayerMoving = IsPlayerMoving
local GetTime = GetTime
local IsFlying = IsFlying

local mmin = math.min
local mmax = math.max
local sformat = string.format

local After = C_Timer.After
local GetGlidingInfo = C_PlayerInfo.GetGlidingInfo
local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID

---@type DMS
local DMS = NS.DMS
local DMSFrame = NS.DMS.frame

local isDragonRiding = false
local ascentSpell = 372610
local lastUpdatedSpeed = 0
local ascentStart = 0
local dynamicSpeed = 0
local speedtext = ""

local MAIN_EVENTS = {
  "PLAYER_ENTERING_WORLD",
  "PLAYER_MOUNT_DISPLAY_CHANGED",
  "UNIT_POWER_BAR_SHOW",
  "UNIT_POWER_BAR_HIDE",
  "UNIT_SPELLCAST_SUCCEEDED",
}

-- Dragon Riding
do
  local thrillBuff = 377234
  local lastT = 0
  local samples = 0
  local smoothSpeed, lastSpeed = 0, 0
  local smoothAccel = 0
  -- local lastAccel = 0
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
    speedTextFactor = 100 / 7
  end

  local isThrill = false
  local isBoosting = false

  function DMS:GetDynamicSpeed()
    local time = GetTime()

    -- Delta time
    local dt = time - lastT
    if dt < updatePeriod then
      -- Rate limit speed updates!
      return false
    end
    lastT = time

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
    if not IsFlying() then
      smoothAccel = 0 -- Don't track acceleration on ground
    end
    -- lastAccel = smoothAccel
    if NS.db.global.debug then
      print("smoothAccel", smoothAccel)
    end

    -- Update display variables
    isBoosting = boosting
    isThrill = not not thrill
    if NS.db.global.debug then
      print("isBoosting", isBoosting)
      print("isThrill", isThrill)
    end

    dynamicSpeed = smoothSpeed * speedTextFactor
    speedtext = smoothSpeed < 1 and "" or sformat(speedTextFormat, dynamicSpeed)
    if NS.db.global.debug then
      print("dynamicSpeed", dynamicSpeed)
      print("speedtext", speedtext)
    end
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

    if playerMovingFrame and (playerMovingFrame.moving ~= moving or playerMovingFrame.moving == nil) then
      playerMovingFrame.moving = moving
    end

    local currentSpeed, runSpeed = NS.GetSpeedInfo()

    local correctSpeed = currentSpeed

    if moving and IsFlying() and isDragonRiding then
      DMS:GetDynamicSpeed()
      correctSpeed = dynamicSpeed
    end

    if playerMovingFrame and playerMovingFrame.speed ~= correctSpeed then
      playerMovingFrame.speed = correctSpeed

      local speedPercent = playerMovingFrame.speed

      if NS.db.global.debug then
        print("moving", moving, "flying", IsFlying(), "isDragonRiding", isDragonRiding)
      end

      if playerMovingFrame.moving or correctSpeed > 0 then
        local showSpeed = correctSpeed
        if not IsFlying() then
          showSpeed = currentSpeed == 0 and runSpeed or currentSpeed
        end

        speedPercent = showSpeed
      else
        speedPercent = runSpeed
      end

      Interface.speed = speedPercent
      NS.UpdateText(Interface.text, speedPercent, isDragonRiding and IsFlying())
    end
  end

  function DMS:WatchForPlayerMoving()
    local currentSpeed, runSpeed = NS.GetSpeedInfo()
    NS.UpdateText(Interface.text, runSpeed)

    if not playerMovingFrame then
      playerMovingFrame = CreateFrame("Frame")
      --- @cast playerMovingFrame PlayerMovingFrame
      playerMovingFrame.speed = currentSpeed

      local runSpeedPercent = runSpeed
      Interface.speed = runSpeedPercent
      NS.UpdateText(Interface.text, runSpeedPercent)
    end

    playerMovingFrame:SetScript("OnUpdate", PlayerMoveUpdate)
  end
end

function DMS:PLAYER_ENTERING_WORLD()
  isDragonRiding = NS.IsDragonriding()
  self:WatchForPlayerMoving()
end

local function checkSpeed()
  local _, runSpeed = NS.GetSpeedInfo()
  if runSpeed == lastUpdatedSpeed then
    After(0.1, checkSpeed)
  else
    isDragonRiding = NS.IsDragonriding()
    DMS:WatchForPlayerMoving()
  end
end

function DMS:PLAYER_MOUNT_DISPLAY_CHANGED()
  local _, runSpeed = NS.GetSpeedInfo()
  lastUpdatedSpeed = runSpeed
  After(0, checkSpeed)
end

function DMS:UNIT_POWER_BAR_SHOW()
  isDragonRiding = NS.IsDragonriding()
  self:WatchForPlayerMoving()
end

function DMS:UNIT_POWER_BAR_HIDE()
  isDragonRiding = NS.IsDragonriding()
  self:WatchForPlayerMoving()
end

function DMS:UNIT_SPELLCAST_SUCCEEDED(unitTarget, _, spellID)
  if unitTarget == "player" and spellID == ascentSpell then
    ascentStart = GetTime()
  end
end

function DMS:PLAYER_LOGIN()
  DMSFrame:UnregisterEvent("PLAYER_LOGIN")

  Interface:CreateInterface()

  FrameUtil.RegisterFrameForEvents(DMSFrame, MAIN_EVENTS)
end
DMSFrame:RegisterEvent("PLAYER_LOGIN")
