local AddonName, NS = ...

NS.DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"

NS.DefaultDatabase = {
  global = {
    version = 1,
    labeltext = "Speed:",
    showlabel = true,
    fontsize = 15,
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
  },
  profile = {
    setting = true,
  },
}

NS.Settings = NS.DefaultDatabase.global

NS.AceConfig = {
  name = AddonName,
  handler = NS,
  type = "group",
  args = {
    showlabel = {
      name = "Toggle label on/off",
      type = "toggle",
      width = "double",
      order = 1,
      set = function(_, val)
        NS.Settings.showlabel = val
        NS.db.global.showlabel = val
      end,
      get = function(_)
        return NS.db.global.showlabel
      end,
    },
    labeltext = {
      type = "input",
      name = "Label Text",
      width = "double",
      order = 2,
      set = function(_, val)
        NS.Settings.labeltext = val
        NS.db.global.labeltext = val
        NS.UpdateText(NS.Interface.text, val)
        NS.Interface.textFrame:SetWidth(NS.Interface.text:GetStringWidth())
        NS.Interface.textFrame:SetHeight(NS.Interface.text:GetStringHeight())
      end,
      get = function(_)
        return NS.db.global.labeltext
      end,
    },
    fontsize = {
      type = "range",
      name = "Font Size",
      width = "double",
      order = 3,
      min = 1,
      max = 500,
      step = 1,
      set = function(_, val)
        NS.Settings.fontsize = val
        NS.db.global.fontsize = val
        NS.Interface.text:SetFont(NS.DEFAULT_FONT, val, "THINOUTLINE")
        NS.Interface.textFrame:SetWidth(NS.Interface.text:GetStringWidth())
        NS.Interface.textFrame:SetHeight(NS.Interface.text:GetStringHeight())
      end,
      get = function(_)
        return NS.db.global.fontsize
      end,
    },
    color = {
      type = "color",
      name = "Color",
      width = "double",
      order = 4,
      hasAlpha = true,
      set = function(_, val1, val2, val3, val4)
        NS.Settings.color.r = val1
        NS.Settings.color.g = val2
        NS.Settings.color.b = val3
        NS.Settings.color.a = val4
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
  },
}
