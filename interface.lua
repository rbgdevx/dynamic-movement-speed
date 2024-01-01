local AddonName, NS = ...

local Interface = {}
NS.Interface = Interface

function Interface:AddControls(frame)
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:SetScript("OnMouseUp", function(_, btn)
    if btn == "RightButton" then
      InterfaceOptionsFrame_OpenToCategory(AddonName)
    end
  end)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(f)
    f:StartMoving()
  end)
  frame:SetScript("OnDragStop", function(f)
    f:StopMovingOrSizing()
    local a, _, b, c, d = f:GetPoint()
    DMS.db.global.position[1] = a
    DMS.db.global.position[2] = b
    DMS.db.global.position[3] = c
    DMS.db.global.position[4] = d
  end)
end

function Interface:CreateInterface()
  local TextFrame = CreateFrame("Frame", "DMSInterfaceTextFrame", UIParent)
  TextFrame:SetPoint(
    DMS.db.global.position[1],
    UIParent,
    DMS.db.global.position[2],
    DMS.db.global.position[3],
    DMS.db.global.position[4]
  )
  self:AddControls(TextFrame)

  local Text = TextFrame:CreateFontString(nil, "OVERLAY")
  Text:SetTextColor(DMS.db.global.color.r, DMS.db.global.color.g, DMS.db.global.color.b, DMS.db.global.color.a)
  Text:SetShadowOffset(0, 0)
  Text:SetShadowColor(0, 0, 0, 1)
  Text:SetJustifyH("MIDDLE")
  Text:SetJustifyV("MIDDLE")
  Text:SetPoint("CENTER", TextFrame, "CENTER", 0, 0)

  local _, runSpeed = NS.GetSpeedInfo()
  NS.UpdateFont(Text)
  NS.UpdateText(Text, runSpeed)

  Interface.text = Text
  Interface.textFrame = TextFrame

  TextFrame:SetWidth(Text:GetStringWidth())
  TextFrame:SetHeight(Text:GetStringHeight())
end
