local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub
local IsFlying = IsFlying

local Interface = {}
NS.Interface = Interface

function Interface:StopMovement(frame)
  frame:SetMovable(false)
end

function Interface:MakeMoveable(frame)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(f)
    if NS.db.global.lock == false then
      f:StartMoving()
    end
  end)
  frame:SetScript("OnDragStop", function(f)
    if NS.db.global.lock == false then
      f:StopMovingOrSizing()
      local a, _, b, c, d = f:GetPoint()
      NS.db.global.position[1] = a
      NS.db.global.position[2] = b
      NS.db.global.position[3] = c
      NS.db.global.position[4] = d
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
    if NS.db.global.lock == false then
      if btn == "RightButton" then
        LibStub("AceConfigDialog-3.0"):Open(AddonName)
      end
    end
  end)

  if NS.db.global.lock then
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
      NS.db.global.position[1],
      UIParent,
      NS.db.global.position[2],
      NS.db.global.position[3],
      NS.db.global.position[4]
    )

    local Text = TextFrame:CreateFontString(nil, "OVERLAY")
    Text:SetTextColor(NS.db.global.color.r, NS.db.global.color.g, NS.db.global.color.b, NS.db.global.color.a)
    Text:SetShadowOffset(0, 0)
    Text:SetShadowColor(0, 0, 0, 1)
    Text:SetJustifyH("CENTER")
    Text:SetJustifyV("MIDDLE")
    Text:SetPoint("CENTER", TextFrame, "CENTER", 0, 0)

    local currentSpeed, runSpeed = NS.GetSpeedInfo()
    NS.UpdateFont(Text)
    local showSpeed = currentSpeed == 0 and (NS.db.global.showzero and 0 or runSpeed) or currentSpeed
    NS.UpdateText(Text, showSpeed, NS.IsDragonriding() and IsFlying())

    Interface.speed = showSpeed
    Interface.text = Text
    Interface.textFrame = TextFrame

    self:AddControls(Interface.textFrame)

    TextFrame:SetWidth(Text:GetStringWidth())
    TextFrame:SetHeight(Text:GetStringHeight())
  end
end
