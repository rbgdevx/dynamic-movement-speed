local AddonName, NS = ...

local LibStub = LibStub

local DMS = LibStub("AceAddon-3.0"):GetAddon("DMS")

NS.AceConfig = {
  name = AddonName,
  type = "group",
  args = {
    round = {
      name = "Round the percentage value",
      type = "toggle",
      width = "double",
      order = 1,
      set = function(_, val)
        DMS.db.global.round = val
        NS.UpdateText(NS.Interface.text, NS.Interface.speed)
      end,
      get = function(_)
        return DMS.db.global.round
      end,
    },
    showlabel = {
      name = "Toggle label on/off",
      type = "toggle",
      width = "double",
      order = 2,
      set = function(_, val)
        DMS.db.global.showlabel = val
        NS.UpdateText(NS.Interface.text, NS.Interface.speed)
      end,
      get = function(_)
        return DMS.db.global.showlabel
      end,
    },
    labeltext = {
      type = "input",
      name = "Label Text",
      width = "double",
      order = 3,
      set = function(_, val)
        DMS.db.global.labeltext = val
        NS.UpdateText(NS.Interface.text, NS.Interface.speed)
        NS.Interface.textFrame:SetWidth(NS.Interface.text:GetStringWidth())
        NS.Interface.textFrame:SetHeight(NS.Interface.text:GetStringHeight())
      end,
      get = function(_)
        return DMS.db.global.labeltext
      end,
    },
    fontsize = {
      type = "range",
      name = "Font Size",
      width = "double",
      order = 4,
      min = 1,
      max = 500,
      step = 1,
      set = function(_, val)
        DMS.db.global.fontsize = val
        NS.UpdateFont(NS.Interface.text)
        NS.Interface.textFrame:SetWidth(NS.Interface.text:GetStringWidth())
        NS.Interface.textFrame:SetHeight(NS.Interface.text:GetStringHeight())
      end,
      get = function(_)
        return DMS.db.global.fontsize
      end,
    },
    font = {
      type = "select",
      name = "Font",
      width = "double",
      dialogControl = "LSM30_Font",
      values = AceGUIWidgetLSMlists.font,
      order = 5,
      set = function(_, val)
        DMS.db.global.font = val
        NS.UpdateFont(NS.Interface.text)
        NS.Interface.textFrame:SetWidth(NS.Interface.text:GetStringWidth())
        NS.Interface.textFrame:SetHeight(NS.Interface.text:GetStringHeight())
      end,
      get = function(_)
        return DMS.db.global.font
      end,
    },
    color = {
      type = "color",
      name = "Color",
      width = "double",
      order = 6,
      hasAlpha = true,
      set = function(_, val1, val2, val3, val4)
        DMS.db.global.color.r = val1
        DMS.db.global.color.g = val2
        DMS.db.global.color.b = val3
        DMS.db.global.color.a = val4
        NS.Interface.text:SetTextColor(val1, val2, val3, val4)
      end,
      get = function(_)
        return DMS.db.global.color.r, DMS.db.global.color.g, DMS.db.global.color.b, DMS.db.global.color.a
      end,
    },
  },
}

function DMS:SetupOptions()
  LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, NS.AceConfig)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddonName, AddonName)
end
