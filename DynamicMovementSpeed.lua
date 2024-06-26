local AddonName, NS = ...

local Interface = NS.Interface

local CreateFrame = CreateFrame
local IsPlayerMoving = IsPlayerMoving
local LibStub = LibStub

DMS = LibStub("AceAddon-3.0"):NewAddon("DMS", "AceEvent-3.0", "AceConsole-3.0")

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

    local currentSpeed, runSpeed = NS.GetSpeedInfo()

    if playerMovingFrame and playerMovingFrame.speed ~= currentSpeed then
      playerMovingFrame.speed = currentSpeed

      local speedPercent = playerMovingFrame.speed

      if playerMovingFrame.moving or currentSpeed > 0 then
        speedPercent = currentSpeed
      else
        speedPercent = runSpeed
      end

      Interface.speed = speedPercent
      NS.UpdateText(Interface.text, speedPercent)
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
  self:WatchForPlayerMoving()
end

function DMS:SlashCommands(_)
  LibStub("AceConfigDialog-3.0"):Open(AddonName)
end

function DMS:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("DMSDB", NS.DefaultDatabase, true)
  self:SetupOptions()
  self:RegisterChatCommand(AddonName, "SlashCommands")
  self:RegisterChatCommand("dms", "SlashCommands")
end

function DMS:OnEnable()
  Interface:CreateInterface()

  self:RegisterEvent("PLAYER_ENTERING_WORLD")
end
