local _, NS = ...

local GetUnitSpeed = GetUnitSpeed

local sformat = string.format

NS.getPercent = function(speed)
  return speed / 7 * 100
end

NS.formatSpeed = function(speed)
  return sformat("%.2f%%", NS.getPercent(speed))
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

NS.UpdateText = function(bar, txt)
  if NS.db.global.showlabel then
    if NS.db.global.labeltext then
      local speedWithLabel = sformat("%s %s", NS.db.global.labeltext, txt)
      bar:SetText(speedWithLabel)
    end
  else
    bar:SetText(txt)
  end
end
