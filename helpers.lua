local _, NS = ...

local LibStub = LibStub
local GetUnitSpeed = GetUnitSpeed

local sformat = string.format

local LSM = LibStub("LibSharedMedia-3.0")

NS.round = function(x)
  local decimal = x - math.floor(x)
  if decimal < 0.5 then
    return math.floor(x)
  else
    return math.ceil(x)
  end
end

NS.getPercent = function(speed)
  return speed / 7 * 100
end

NS.formatSpeed = function(speed, round)
  if round then
    local percent = NS.getPercent(speed)
    local rounded = NS.round(percent)
    return sformat("%d%%", rounded)
  else
    return sformat("%.1f%%", NS.getPercent(speed))
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
  -- the maximum speed while swimming, in yards per second (not tested but it should be as the flying mount)
  --]]
  return GetUnitSpeed("player")
end

NS.UpdateText = function(frame, speed)
  local txt = NS.formatSpeed(speed, DMS.db.global.round)
  if DMS.db.global.showlabel then
    if DMS.db.global.labeltext then
      local speedWithLabel = sformat("%s %s", DMS.db.global.labeltext, txt)
      frame:SetText(speedWithLabel)
    end
  else
    frame:SetText(txt)
  end
end

NS.UpdateFont = function(frame)
  frame:SetFont(LSM:Fetch("font", DMS.db.global.font), DMS.db.global.fontsize, "THINOUTLINE")
end
