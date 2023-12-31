local AddonName, NS = ...

local Interface = NS.Interface

local CreateFrame = CreateFrame
local IsPlayerMoving = IsPlayerMoving

local RegisterAddonMessagePrefix = C_ChatInfo.RegisterAddonMessagePrefix

local DMS = {}
NS.DMS = DMS

local DMSFrame = CreateFrame("Frame", "DMSFrame")
DMSFrame:SetScript("OnEvent", function(_, event, ...)
  if DMS[event] then
    DMS[event](DMS, ...)
  end
end)

-- Player Moving
do
  --- @class PlayerMovingFrame
  --- @field moving integer|nil
  --- @field speed integer|nil

  --- @type PlayerMovingFrame|Frame|nil
  local playerMovingFrame = nil

  local function PlayerMoveUpdate()
    local moving = IsPlayerMoving()
    if playerMovingFrame and (playerMovingFrame.moving ~= moving or playerMovingFrame.moving == nil) then
      playerMovingFrame.moving = moving
    end

    local speed = NS.GetSpeedInfo()
    if playerMovingFrame and playerMovingFrame.speed ~= speed then
      playerMovingFrame.speed = speed
    end

    if playerMovingFrame then
      local currentSpeed, runSpeed = NS.GetSpeedInfo()
      local speedPercent = ""

      if playerMovingFrame.moving or currentSpeed > 0 then
        speedPercent = NS.formatSpeed(currentSpeed)
      else
        speedPercent = NS.formatSpeed(runSpeed)
      end

      NS.UpdateText(Interface.text, speedPercent)
    end
  end

  function DMS:WatchForPlayerMoving()
    if not playerMovingFrame then
      local currentSpeed, runSpeed = NS.GetSpeedInfo()

      playerMovingFrame = CreateFrame("Frame")
      --- @cast playerMovingFrame PlayerMovingFrame
      playerMovingFrame.speed = currentSpeed

      local runSpeedPercent = NS.formatSpeed(runSpeed)
      NS.UpdateText(Interface.text, runSpeedPercent)
    end

    playerMovingFrame:SetScript("OnUpdate", PlayerMoveUpdate)
  end
end

function DMS:PLAYER_ENTERING_WORLD()
  Interface:CreateInterface()

  self:WatchForPlayerMoving()
end

function DMS:ADDON_LOADED(addon)
  if addon == AddonName then
    DMSFrame:UnregisterEvent("ADDON_LOADED")

    LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, NS.AceConfig)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddonName, AddonName)
    NS.db = LibStub("AceDB-3.0"):New("DMSDB", NS.DefaultDatabase, true)
    RegisterAddonMessagePrefix(AddonName)

    DMSFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  end
end
DMSFrame:RegisterEvent("ADDON_LOADED")
