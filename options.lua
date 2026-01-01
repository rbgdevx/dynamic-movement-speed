local AddonName, NS = ...

local CopyTable = CopyTable
local next = next
local LibStub = LibStub

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")

---@type DMS
local DMS = NS.DMS
local DMSFrame = NS.DMS.frame

local Options = {}
NS.Options = Options

NS.AceConfig = {
  name = AddonName,
  type = "group",
  args = {
    lock = {
      name = "Lock the text into place",
      type = "toggle",
      width = "full",
      order = 1,
      set = function(_, val)
        NS.db.global.lock = val
        if val then
          NS.Interface:Lock(NS.Interface.textFrame)
        else
          NS.Interface:Unlock(NS.Interface.textFrame)
        end
      end,
      get = function(_)
        return NS.db.global.lock
      end,
    },
    showzero = {
      name = "Show 0% when NOT moving, instead of run speed",
      type = "toggle",
      width = "full",
      order = 2,
      set = function(_, val)
        NS.db.global.showzero = val
        local currentSpeed, runSpeed = NS.GetSpeedInfo()
        local staticSpeed = NS.db.global.showzero and 0 or runSpeed
        local showSpeed = (currentSpeed == 0 or NS.Interface.speed == 0) and staticSpeed or NS.Interface.speed
        NS.UpdateText(NS.Interface.text, showSpeed, NS.db.global.decimals, NS.IsDragonRiding() and NS.IsFlying())
      end,
      get = function(_)
        return NS.db.global.showzero
      end,
    },
    showlabel = {
      name = "Enable label text",
      type = "toggle",
      width = "full",
      order = 3,
      set = function(_, val)
        NS.db.global.showlabel = val
        NS.UpdateText(
          NS.Interface.text,
          NS.Interface.speed,
          NS.db.global.decimals,
          NS.IsDragonRiding() and NS.IsFlying()
        )
      end,
      get = function(_)
        return NS.db.global.showlabel
      end,
    },
    labeltext = {
      type = "input",
      name = "Label Text",
      width = "double",
      order = 4,
      disabled = function()
        return not NS.db.global.showlabel
      end,
      set = function(_, val)
        NS.db.global.labeltext = val
        NS.UpdateText(
          NS.Interface.text,
          NS.Interface.speed,
          NS.db.global.decimals,
          NS.IsDragonRiding() and NS.IsFlying()
        )
        NS.Interface.textFrame:SetWidth(NS.Interface.text:GetStringWidth())
        NS.Interface.textFrame:SetHeight(NS.Interface.text:GetStringHeight())
      end,
      get = function(_)
        return NS.db.global.labeltext
      end,
    },
    spacer1 = { name = " ", type = "description", order = 5, width = "full" },
    decimals = {
      type = "range",
      name = "Decimals",
      desc = "The number of decimal places to show.",
      width = "double",
      min = 0,
      max = 5,
      step = 1,
      order = 6,
      set = function(_, val)
        NS.db.global.decimals = val
        NS.UpdateText(NS.Interface.text, NS.Interface.speed, val, NS.IsDragonRiding() and NS.IsFlying())
        NS.Interface.textFrame:SetWidth(NS.Interface.text:GetStringWidth())
        NS.Interface.textFrame:SetHeight(NS.Interface.text:GetStringHeight())
      end,
      get = function(_)
        return NS.db.global.decimals
      end,
    },
    spacer2 = { name = " ", type = "description", order = 7, width = "full" },
    fontsize = {
      type = "range",
      name = "Font Size",
      width = "double",
      order = 8,
      min = 2,
      max = 64,
      step = 1,
      set = function(_, val)
        NS.db.global.fontsize = val
        NS.UpdateFont(NS.Interface.text)
        NS.Interface.textFrame:SetWidth(NS.Interface.text:GetStringWidth())
        NS.Interface.textFrame:SetHeight(NS.Interface.text:GetStringHeight())
      end,
      get = function(_)
        return NS.db.global.fontsize
      end,
    },
    spacer3 = { name = " ", type = "description", order = 9, width = "full" },
    font = {
      type = "select",
      name = "Font",
      width = 1.5,
      dialogControl = "LSM30_Font",
      values = SharedMedia:HashTable("font"),
      order = 10,
      set = function(_, val)
        NS.db.global.font = val
        NS.UpdateFont(NS.Interface.text)
        NS.Interface.textFrame:SetWidth(NS.Interface.text:GetStringWidth())
        NS.Interface.textFrame:SetHeight(NS.Interface.text:GetStringHeight())
      end,
      get = function(_)
        return NS.db.global.font
      end,
    },
    spacer4 = { name = "", type = "description", order = 11, width = 0.1 },
    color = {
      type = "color",
      name = "Color",
      width = 0.5,
      order = 12,
      hasAlpha = true,
      set = function(_, val1, val2, val3, val4)
        NS.db.global.color.r = val1
        NS.db.global.color.g = val2
        NS.db.global.color.b = val3
        NS.db.global.color.a = val4
        NS.Interface.text:SetTextColor(val1, val2, val3, val4)
      end,
      get = function(_)
        return NS.db.global.color.r, NS.db.global.color.g, NS.db.global.color.b, NS.db.global.color.a
      end,
    },
    spacer5 = { type = "description", order = 13, name = " ", width = "full" },
    reset = {
      name = "Reset Everything",
      type = "execute",
      width = "normal",
      order = 100,
      func = function()
        DMSDB = CopyTable(NS.DefaultDatabase)
        NS.db = CopyTable(NS.DefaultDatabase)
      end,
    },
  },
}

function Options:SlashCommands(message)
  if message == "toggle lock" then
    if NS.db.global.lock == false then
      NS.db.global.lock = true
      NS.Interface:Lock(NS.Interface.textFrame)
    else
      NS.db.global.lock = false
      NS.Interface:Unlock(NS.Interface.textFrame)
    end
  else
    AceConfigDialog:Open(AddonName)
  end
end

function Options:Setup()
  AceConfig:RegisterOptionsTable(AddonName, NS.AceConfig)
  AceConfigDialog:AddToBlizOptions(AddonName, AddonName)

  SLASH_DMS1 = "/dynamicmovementspeed"
  SLASH_DMS2 = "/dms"

  function SlashCmdList.DMS(message)
    self:SlashCommands(message)
  end
end

function DMS:ADDON_LOADED(addon)
  if addon == AddonName then
    DMSFrame:UnregisterEvent("ADDON_LOADED")

    DMSDB = DMSDB and next(DMSDB) ~= nil and DMSDB or {}

    -- Copy any settings from default if they don't exist in current profile
    NS.CopyDefaults(NS.DefaultDatabase, DMSDB)

    -- Reference to active db profile
    -- Always use this directly or reference will be invalid
    NS.db = DMSDB

    -- Remove table values no longer found in default settings
    NS.CleanupDB(DMSDB, NS.DefaultDatabase)

    Options:Setup()
  end
end
DMSFrame:RegisterEvent("ADDON_LOADED")
