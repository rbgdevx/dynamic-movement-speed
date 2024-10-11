local _, NS = ...

local Interface = NS.Interface

local CreateFrame = CreateFrame
local IsPlayerMoving = IsPlayerMoving
local GetTime = GetTime
local IsFlying = IsFlying
local UnitIsUnit = UnitIsUnit

local mmin = math.min
local mmax = math.max
local sformat = string.format

local After = C_Timer.After
local GetGlidingInfo = C_PlayerInfo.GetGlidingInfo
local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID

---@type DMS
local DMS = NS.DMS
local DMSFrame = NS.DMS.frame

local isFlying = false
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
    isFlying = IsFlying()

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
    if not isFlying then
      smoothAccel = 0 -- Don't track acceleration on ground
    end
    -- lastAccel = smoothAccel
    NS.Debug("smoothAccel", smoothAccel)

    -- Update display variables
    isBoosting = boosting
    isThrill = not not thrill
    NS.Debug("isBoosting", isBoosting)
    NS.Debug("isThrill", isThrill)

    dynamicSpeed = smoothSpeed * speedTextFactor
    speedtext = smoothSpeed < 1 and "" or sformat(speedTextFormat, dynamicSpeed)
    NS.Debug("speedtext", speedtext)
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
    isDragonRiding = NS.IsDragonriding()
    isFlying = IsFlying()

    if playerMovingFrame and (playerMovingFrame.moving ~= moving or playerMovingFrame.moving == nil) then
      playerMovingFrame.moving = moving
    end

    local currentSpeed, runSpeed = NS.GetSpeedInfo()
    local correctSpeed = currentSpeed

    if moving and isFlying and isDragonRiding then
      DMS:GetDynamicSpeed()
      correctSpeed = dynamicSpeed
    end

    if playerMovingFrame and playerMovingFrame.speed ~= correctSpeed then
      playerMovingFrame.speed = correctSpeed

      local speedPercent = playerMovingFrame.speed

      if playerMovingFrame.moving or correctSpeed > 0 then
        local showSpeed = correctSpeed
        if not isFlying then
          showSpeed = currentSpeed == 0 and runSpeed or currentSpeed
        end

        speedPercent = showSpeed
      else
        local showSpeed = NS.db.global.showzero and 0 or runSpeed
        speedPercent = showSpeed
      end

      NS.Interface.speed = speedPercent
      NS.UpdateText(Interface.text, speedPercent, isDragonRiding and isFlying)
    end
  end

  function DMS:WatchForPlayerMoving()
    isDragonRiding = NS.IsDragonriding()
    isFlying = IsFlying()

    local currentSpeed, runSpeed = NS.GetSpeedInfo()
    local showSpeed = currentSpeed == 0 and (NS.db.global.showzero and 0 or runSpeed) or currentSpeed
    NS.UpdateText(Interface.text, showSpeed, isDragonRiding and isFlying)

    if not playerMovingFrame then
      playerMovingFrame = CreateFrame("Frame")
      --- @cast playerMovingFrame PlayerMovingFrame
      playerMovingFrame.speed = currentSpeed

      local runSpeedPercent = runSpeed
      showSpeed = currentSpeed == 0 and (NS.db.global.showzero and 0 or runSpeedPercent) or currentSpeed
      NS.Interface.speed = showSpeed
      NS.UpdateText(Interface.text, showSpeed, isDragonRiding and isFlying)
    end

    playerMovingFrame:SetScript("OnUpdate", PlayerMoveUpdate)
  end
end

function DMS:PLAYER_ENTERING_WORLD()
  isDragonRiding = NS.IsDragonriding()
  isFlying = IsFlying()

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
      local isGliding, canGlide, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
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
    isDragonRiding = NS.IsDragonriding()
    isFlying = IsFlying()
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
    isDragonRiding = NS.IsDragonriding()
    isFlying = IsFlying()
    self:WatchForPlayerMoving()
  end
end

function DMS:UNIT_POWER_BAR_HIDE(unitTarget)
  if UnitIsUnit(unitTarget, "player") then
    isDragonRiding = NS.IsDragonriding()
    isFlying = IsFlying()
    self:WatchForPlayerMoving()
  end
end

function DMS:UNIT_SPELLCAST_SUCCEEDED(unitTarget, _, spellID)
  if UnitIsUnit(unitTarget, "player") and spellID == ascentSpell then
    ascentStart = GetTime()
  end
end

function DMS:PLAYER_LOGIN()
  DMSFrame:UnregisterEvent("PLAYER_LOGIN")

  Interface:CreateInterface()

  FrameUtil.RegisterFrameForEvents(DMSFrame, MAIN_EVENTS)
end
DMSFrame:RegisterEvent("PLAYER_LOGIN")
