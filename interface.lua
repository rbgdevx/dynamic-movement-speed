local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub

local Interface = {}
NS.Interface = Interface

function Interface:StopMovement(frame)
  frame:SetMovable(false)
end

function Interface:MakeMoveable(frame)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(f)
    if DMS.db.global.lock == false then
      f:StartMoving()
    end
  end)
  frame:SetScript("OnDragStop", function(f)
    if DMS.db.global.lock == false then
      f:StopMovingOrSizing()
      local a, _, b, c, d = f:GetPoint()
      DMS.db.global.position[1] = a
      DMS.db.global.position[2] = b
      DMS.db.global.position[3] = c
      DMS.db.global.position[4] = d
    end
  end)
end

function Interface:Lock(frame)
  self:StopMovement(frame)
end

function Interface:Unlock(frame)
  self:MakeMoveable(frame)
end

function Interface:AddControls(frame)
  frame:EnableMouse(true)
  frame:SetScript("OnMouseUp", function(_, btn)
    if btn == "RightButton" then
      LibStub("AceConfigDialog-3.0"):Open(AddonName)
    end
  end)

  if DMS.db.global.lock then
    self:StopMovement(frame)
  else
    self:MakeMoveable(frame)
  end
end

function Interface:CreateInterface()
  if not Interface.textFrame then
    local TextFrame = CreateFrame("Frame", "DMSInterfaceTextFrame", UIParent)
    TextFrame:SetClampedToScreen(true)
    TextFrame:SetPoint(
      DMS.db.global.position[1],
      UIParent,
      DMS.db.global.position[2],
      DMS.db.global.position[3],
      DMS.db.global.position[4]
    )

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

    Interface.speed = runSpeed
    Interface.text = Text
    Interface.textFrame = TextFrame

    self:AddControls(Interface.textFrame)

    TextFrame:SetWidth(Text:GetStringWidth())
    TextFrame:SetHeight(Text:GetStringHeight())
  end
end
