local AddonName, NS = ...

local CopyTable = CopyTable
local next = next
local LibStub = LibStub
local IsPlayerMoving = IsPlayerMoving

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
        local moving = IsPlayerMoving()
        local showSpeed = moving and currentSpeed or (val and 0 or runSpeed)
        NS.Interface.speed = showSpeed
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
        NS.AutoSize(NS.Interface.textFrame, NS.Interface.text)
      end,
      get = function(_)
        return NS.db.global.labeltext
      end,
    },
    spacer1 = { name = " ", type = "description", order = 5, width = "full" },
    decimals = {
      type = "range",
      name = "Decimals",
      desc = "The number of decimal places to show. Trailing zeros are dropped (100% rather than 100.00%).",
      width = "double",
      min = 0,
      max = 5,
      step = 1,
      order = 6,
      set = function(_, val)
        NS.db.global.decimals = val
        NS.UpdateText(NS.Interface.text, NS.Interface.speed, val, NS.IsDragonRiding() and NS.IsFlying())
        NS.AutoSize(NS.Interface.textFrame, NS.Interface.text)
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
      min = 1,
      max = 64,
      step = 1,
      set = function(_, val)
        NS.db.global.fontsize = val
        NS.UpdateFont(NS.Interface.text)
        NS.AutoSize(NS.Interface.textFrame, NS.Interface.text)
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
        NS.AutoSize(NS.Interface.textFrame, NS.Interface.text)
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
    outline = {
      type = "select",
      name = "Outline",
      width = 1.5,
      order = 14,
      values = {
        [""] = "None",
        ["OUTLINE"] = "Outline",
        ["THICKOUTLINE"] = "Thick Outline",
        ["MONOCHROME"] = "Monochrome",
        ["MONOCHROME,OUTLINE"] = "Monochrome Outline",
        ["MONOCHROME,THICKOUTLINE"] = "Monochrome Thick Outline",
      },
      sorting = { "", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "MONOCHROME,OUTLINE", "MONOCHROME,THICKOUTLINE" },
      set = function(_, val)
        NS.db.global.outline = val
        NS.UpdateFont(NS.Interface.text)
        NS.AutoSize(NS.Interface.textFrame, NS.Interface.text)
      end,
      get = function(_)
        return NS.db.global.outline
      end,
    },
    spacer6 = { name = "", type = "description", order = 15, width = 0.1 },
    shadowcolor = {
      type = "color",
      name = "Shadow Color",
      width = 1.5,
      order = 16,
      hasAlpha = true,
      set = function(_, val1, val2, val3, val4)
        NS.db.global.shadowcolor.r = val1
        NS.db.global.shadowcolor.g = val2
        NS.db.global.shadowcolor.b = val3
        NS.db.global.shadowcolor.a = val4
        NS.UpdateFont(NS.Interface.text)
      end,
      get = function(_)
        return NS.db.global.shadowcolor.r,
          NS.db.global.shadowcolor.g,
          NS.db.global.shadowcolor.b,
          NS.db.global.shadowcolor.a
      end,
    },
    spacer7 = { name = " ", type = "description", order = 17, width = "full" },
    shadowoffsetx = {
      type = "range",
      name = "Shadow Offset X",
      width = "double",
      order = 18,
      min = -10,
      max = 10,
      step = 0.5,
      set = function(_, val)
        NS.db.global.shadowoffsetx = val
        NS.UpdateFont(NS.Interface.text)
      end,
      get = function(_)
        return NS.db.global.shadowoffsetx
      end,
    },
    spacer8 = { name = " ", type = "description", order = 19, width = "full" },
    shadowoffsety = {
      type = "range",
      name = "Shadow Offset Y",
      width = "double",
      order = 20,
      min = -10,
      max = 10,
      step = 0.5,
      set = function(_, val)
        NS.db.global.shadowoffsety = val
        NS.UpdateFont(NS.Interface.text)
      end,
      get = function(_)
        return NS.db.global.shadowoffsety
      end,
    },
    spacer9 = { type = "description", order = 21, name = " ", width = "full" },
    reset = {
      name = "Reset Everything",
      type = "execute",
      width = "normal",
      order = 100,
      func = function()
        DMSDB = CopyTable(NS.DefaultDatabase)
        -- NS.db must reference the saved variable itself, otherwise changes
        -- made after a reset are lost on reload
        NS.db = DMSDB
        NS.Interface.text:SetTextColor(
          NS.db.global.color.r,
          NS.db.global.color.g,
          NS.db.global.color.b,
          NS.db.global.color.a
        )
        NS.UpdateFont(NS.Interface.text)
        NS.UpdateText(
          NS.Interface.text,
          NS.Interface.speed,
          NS.db.global.decimals,
          NS.IsDragonRiding() and NS.IsFlying()
        )
        NS.AutoSize(NS.Interface.textFrame, NS.Interface.text)
        NS.Interface.textFrame:ClearAllPoints()
        NS.Interface.textFrame:SetPoint(
          NS.db.global.position[1],
          UIParent,
          NS.db.global.position[2],
          NS.db.global.position[3],
          NS.db.global.position[4]
        )
        if NS.db.global.lock then
          NS.Interface:Lock(NS.Interface.textFrame)
        else
          NS.Interface:Unlock(NS.Interface.textFrame)
        end
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
