local _, NS = ...

local LibStub = LibStub
local GetUnitSpeed = GetUnitSpeed
local AbbreviateNumbers = AbbreviateNumbers
local issecretvalue = issecretvalue or function()
  return false
end
local pairs = pairs
local type = type
local next = next
local setmetatable = setmetatable
local getmetatable = getmetatable
local UnitPowerBarID = UnitPowerBarID
local IsFlying = IsFlying
local IsFalling = IsFalling

local mceil = math.ceil
local mfloor = math.floor
local sformat = string.format

local GetGlidingInfo = C_PlayerInfo.GetGlidingInfo

local SharedMedia = LibStub("LibSharedMedia-3.0")

local BASE_MOVEMENT_SPEED = BASE_MOVEMENT_SPEED or 7

NS.Debug = function(...)
  if NS.db and NS.db.global.debug then
    print(...)
  end
end

NS.round = function(x)
  local decimal = x - mfloor(x)
  if decimal < 0.5 then
    return mfloor(x)
  else
    return mceil(x)
  end
end

-- Patch 12.0.5 made player stats (incl. GetUnitSpeed) return "secret" values in
-- combat / encounters / Mythic+ / rated PvP. A secret can't be used in any
-- arithmetic, comparison or string.format we control, so we can no longer
-- compute "(speed / BASE_MOVEMENT_SPEED) * 100" ourselves. AbbreviateNumbers is
-- a guarded formatter (SecretArguments = AllowedWhenTainted): it does the scale
-- internally and returns a (still-secret) string we can hand to SetText.
--
-- It computes floor(value / significandDivisor) / fractionDivisor and appends
-- the abbreviation, so significandDivisor * fractionDivisor sets the overall
-- scale and fractionDivisor sets the decimal resolution. We use two scales:
--   percentOptions: raw yd/s -> %  (significand*fraction = BASE_MOVEMENT_SPEED/100)
--   riderOptions:   value already a % -> %  (identity, significand*fraction = 1)
-- Caveat vs the old string.format path: AbbreviateNumbers truncates (not rounds)
-- and drops trailing zeros, so this renders "100%" / "150.5%", never "100.00%".
local percentOptions, riderOptions = {}, {}
do
  local fractionByDecimals = { [0] = 1, [1] = 10, [2] = 100, [3] = 1000, [4] = 10000, [5] = 100000 }
  for decimals, fraction in pairs(fractionByDecimals) do
    percentOptions[decimals] = {
      breakpointData = {
        {
          breakpoint = 0,
          abbreviation = "%",
          abbreviationIsGlobal = false,
          significandDivisor = (BASE_MOVEMENT_SPEED / 100) / fraction,
          fractionDivisor = fraction,
        },
      },
    }
    riderOptions[decimals] = {
      breakpointData = {
        {
          breakpoint = 0,
          abbreviation = "%",
          abbreviationIsGlobal = false,
          significandDivisor = 1 / fraction,
          fractionDivisor = fraction,
        },
      },
    }
  end
end

NS.formatSpeed = function(speed, decimals, isDragonRiding)
  local options = (isDragonRiding and riderOptions or percentOptions)[decimals] or percentOptions[1]
  return AbbreviateNumbers(speed, options)
end

NS.GetSpeedInfo = function()
  --[[
  -- currentSpeed: number
  -- current movement speed in yards per second (normal running: 7; an epic ground mount: 14)
  -- runSpeed: number
  -- the maximum speed on the ground, in yards per second (including talents such as Pursuit of Justice and ground mounts)
  -- flightSpeed: number
  -- the maximum speed while flying, in yards per second (the unit need to be on a flying mount to get the flying speed)
  -- swimSpeed: number
  -- the maximum speed while swimming, in yards per second (not tested but it should be the same as the flying mount)
  --]]
  local currentSpeed, runSpeed = GetUnitSpeed("player")
  -- In restricted contexts (combat, encounters, Mythic+, rated PvP) these come
  -- back as secret values under Patch 12.0.5. We no longer blank the display;
  -- instead callers pass the (possibly secret) numbers straight to the guarded
  -- AbbreviateNumbers formatter and branch on movement state (IsPlayerMoving,
  -- never secret) rather than on the speed value. The third return is a plain
  -- boolean so callers can decide without comparing a secret.
  return currentSpeed, runSpeed, (issecretvalue(currentSpeed) or issecretvalue(runSpeed))
end

NS.IsFalling = function()
  return IsFalling("player")
end

NS.IsDriving = function()
  return UnitPowerBarID("player") == 720
end

NS.IsDragonRiding = function()
  local _, canGlide = GetGlidingInfo()
  return canGlide
end

NS.IsFlying = function()
  return IsFlying("player")
end

NS.UpdateText = function(frame, speed, decimals, isDragonRiding)
  local txt = NS.formatSpeed(speed, decimals, isDragonRiding)
  if NS.db.global.showlabel then
    if NS.db.global.labeltext then
      -- string.format accepts secret args and returns a secret string, so the
      -- label prefix works whether or not txt is secret.
      local speedWithLabel = sformat("%s %s", NS.db.global.labeltext, txt)
      frame:SetText(speedWithLabel)
    end
  else
    frame:SetText(txt)
  end
end

-- Size the text frame to fit its text. After SetText with a secret string the
-- font string can report secret metrics; skip the resize in that case (keep the
-- previous size) rather than risk operating on a secret value.
NS.AutoSize = function(frame, fontString)
  local width = fontString:GetStringWidth()
  local height = fontString:GetStringHeight()
  if issecretvalue(width) or issecretvalue(height) then
    return
  end
  frame:SetWidth(width)
  frame:SetHeight(height)
end

NS.UpdateFont = function(frame)
  frame:SetFont(SharedMedia:Fetch("font", NS.db.global.font), NS.db.global.fontsize, "OUTLINE")
end

-- Copies table values from src to dst if they don't exist in dst
NS.CopyDefaults = function(src, dst)
  if type(src) ~= "table" then
    return {}
  end

  if type(dst) ~= "table" then
    dst = {}
  end

  for k, v in pairs(src) do
    if type(v) == "table" then
      dst[k] = NS.CopyDefaults(v, dst[k])
    elseif type(v) ~= type(dst[k]) then
      dst[k] = v
    end
  end

  return dst
end

NS.CopyTable = function(src, dest)
  -- Handle non-tables and previously-seen tables.
  if type(src) ~= "table" then
    return src
  end

  if dest and dest[src] then
    return dest[src]
  end

  -- New table; mark it as seen an copy recursively.
  local s = dest or {}
  local res = {}
  s[src] = res

  for k, v in next, src do
    res[NS.CopyTable(k, s)] = NS.CopyTable(v, s)
  end

  return setmetatable(res, getmetatable(src))
end

-- Cleanup savedvariables by removing table values in src that no longer
-- exists in table dst (default settings)
NS.CleanupDB = function(src, dst)
  for key, value in pairs(src) do
    if dst[key] == nil then
      -- HACK: offsetsXY are not set in DEFAULT_SETTINGS but sat on demand instead to save memory,
      -- which causes nil comparison to always be true here, so always ignore these for now
      if key ~= "offsetsX" and key ~= "offsetsY" and key ~= "version" then
        src[key] = nil
      end
    elseif type(value) == "table" then
      if key ~= "disabledCategories" and key ~= "categoryTextures" then -- also sat on demand
        dst[key] = NS.CleanupDB(value, dst[key])
      end
    end
  end
  return dst
end
