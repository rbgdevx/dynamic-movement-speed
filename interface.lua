local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local Interface = {}
NS.Interface = Interface

function Interface:MakeUnmovable(frame)
  frame:SetMovable(false)
  frame:RegisterForDrag()
  frame:SetScript("OnDragStart", nil)
  frame:SetScript("OnDragStop", nil)
end

function Interface:MakeMoveable(frame)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(f)
    if NS.db.global.lock == false and frame:IsVisible() and frame:GetAlpha() ~= 0 then
      f:StartMoving()
    end
  end)
  frame:SetScript("OnDragStop", function(f)
    if NS.db.global.lock == false and frame:IsVisible() and frame:GetAlpha() ~= 0 then
      f:StopMovingOrSizing()
      local a, _, b, c, d = f:GetPoint()
      NS.db.global.position[1] = a
      NS.db.global.position[2] = b
      NS.db.global.position[3] = c
      NS.db.global.position[4] = d
    end
  end)
end

function Interface:RemoveControls(frame)
  frame:EnableMouse(false)
  frame:SetScript("OnMouseUp", nil)
end

function Interface:AddControls(frame)
  frame:EnableMouse(true)
  frame:SetScript("OnMouseUp", function(_, btn)
    if NS.db.global.lock == false and not IsInInstance() and frame:IsVisible() and frame:GetAlpha() ~= 0 then
      if btn == "RightButton" then
        AceConfigDialog:Open(AddonName)
      end
    end
  end)
end

function Interface:Lock(frame)
  self:RemoveControls(frame)
  self:MakeUnmovable(frame)
end

function Interface:Unlock(frame)
  self:AddControls(frame)
  self:MakeMoveable(frame)
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
    NS.UpdateText(Text, showSpeed, NS.db.global.decimals, NS.db.global.round)

    Interface.speed = showSpeed
    Interface.text = Text
    Interface.textFrame = TextFrame

    if NS.db.global.lock then
      self:Lock(Interface.textFrame)
    else
      self:Unlock(Interface.textFrame)
    end

    TextFrame:SetWidth(Text:GetStringWidth())
    TextFrame:SetHeight(Text:GetStringHeight())
  end
end
