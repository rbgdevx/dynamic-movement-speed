local _, NS = ...

local CreateFrame = CreateFrame

---@class PositionArray
---@field[1] string
---@field[2] string
---@field[3] number
---@field[4] number

---@class ColorArray
---@field r number
---@field g number
---@field b number
---@field a number

---@class GlobalTable : table
---@field lock boolean
---@field labeltext string
---@field showlabel boolean
---@field showzero boolean
---@field font string
---@field decimals number
---@field round boolean
---@field color ColorArray
---@field position PositionArray
---@field debug boolean

---@class DBTable : table
---@field global GlobalTable

---@class DMS
---@field ADDON_LOADED function
---@field PLAYER_LOGIN function
---@field PLAYER_ENTERING_WORLD function
---@field PLAYER_MOUNT_DISPLAY_CHANGED function
---@field UNIT_POWER_BAR_SHOW function
---@field UNIT_POWER_BAR_HIDE function
---@field UNIT_SPELLCAST_SUCCEEDED function
---@field WatchForPlayerMoving function
---@field GetDynamicSpeed function
---@field SlashCommands function
---@field frame Frame
---@field db GlobalTable

---@type DMS
---@diagnostic disable-next-line: missing-fields
local DMS = {}
NS.DMS = DMS

local DMSFrame = CreateFrame("Frame", "DMSFrame")
DMSFrame:SetScript("OnEvent", function(_, event, ...)
  if DMS[event] then
    DMS[event](DMS, ...)
  end
end)
NS.DMS.frame = DMSFrame

NS.DefaultDatabase = {
  global = {
    lock = false,
    labeltext = "Speed:",
    showlabel = true,
    showzero = false,
    fontsize = 15,
    decimals = 2,
    font = "Friz Quadrata TT",
    round = true,
    color = {
      r = 1,
      g = 1,
      b = 1,
      a = 1,
    },
    position = {
      "CENTER",
      "CENTER",
      0,
      0,
    },
    debug = false,
  },
}
