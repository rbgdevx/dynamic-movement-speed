local _, NS = ...

local LibStub = LibStub
local GetUnitSpeed = GetUnitSpeed
local pairs = pairs
local type = type
local next = next
local setmetatable = setmetatable
local getmetatable = getmetatable
local UnitPowerBarID = UnitPowerBarID
local IsFlying = IsFlying
local IsFalling = IsFalling

local wipe = table.wipe
local sformat = string.format

local BASE_MOVEMENT_SPEED = BASE_MOVEMENT_SPEED or 7

local SharedMedia = LibStub("LibSharedMedia-3.0")

NS.Debug = function(...)
  if NS.db and NS.db.global.debug then
    print(...)
  end
end

NS.round = function(x)
  local decimal = x - math.floor(x)
  if decimal < 0.5 then
    return math.floor(x)
  else
    return math.ceil(x)
  end
end

NS.getPercent = function(speed)
  return (speed / BASE_MOVEMENT_SPEED) * 100
end

local zeroDecimalFormat = "%.0f%%"
local singleDecimalFormat = "%.1f%%"
local twoDecimalFormat = "%.2f%%"
local threeDecimalFormat = "%.3f%%"
local fourDecimalFormat = "%.4f%%"
local fiveDecimalFormat = "%.5f%%"

NS.formatSpeed = function(speed, decimals, isDragonRiding)
  local value = isDragonRiding and speed or NS.getPercent(speed)
  if decimals == 0 then
    return sformat(zeroDecimalFormat, value)
  elseif decimals == 1 then
    return sformat(singleDecimalFormat, value)
  elseif decimals == 2 then
    return sformat(twoDecimalFormat, value)
  elseif decimals == 3 then
    return sformat(threeDecimalFormat, value)
  elseif decimals == 4 then
    return sformat(fourDecimalFormat, value)
  elseif decimals == 5 then
    return sformat(fiveDecimalFormat, value)
  end
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
  return GetUnitSpeed("player")
end

NS.IsFalling = function()
  return IsFalling("player")
end

NS.IsDriving = function()
  return UnitPowerBarID("player") == 720
end

NS.IsDragonRiding = function()
  return UnitPowerBarID("player") == 631
end

NS.IsFlying = function()
  return IsFlying("player")
end

NS.UpdateText = function(frame, speed, decimals, round, isDragonRiding)
  local txt = NS.formatSpeed(speed, decimals, round, isDragonRiding)
  if NS.db.global.showlabel then
    if NS.db.global.labeltext then
      local speedWithLabel = sformat("%s %s", NS.db.global.labeltext, txt)
      frame:SetText(speedWithLabel)
    end
  else
    frame:SetText(txt)
  end
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

-- Pool for reusing tables. (Garbage collector isn't ran in combat unless max garbage is reached, which causes fps drops)
do
  local pool = {}

  NS.NewTable = function()
    local t = next(pool) or {}
    pool[t] = nil -- remove from pool
    return t
  end

  NS.RemoveTable = function(tbl)
    if tbl then
      pool[wipe(tbl)] = true -- add to pool, wipe returns pointer to tbl here
    end
  end

  NS.ReleaseTables = function()
    if next(pool) then
      pool = {}
    end
  end
end
