-- AmmoBuddy: minimap button (no libraries)
local ADDON, ns = ...
if not ns.enabled then return end

local btn, icon

local function UpdatePosition()
  local angle = math.rad(ns.db.minimap.angle)
  local radius = (Minimap:GetWidth() / 2) + 5
  btn:ClearAllPoints()
  btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function OnDragUpdate()
  local mx, my = Minimap:GetCenter()
  local px, py = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  px, py = px / scale, py / scale
  ns.db.minimap.angle = math.deg(math.atan2(py - my, px - mx))
  UpdatePosition()
end

local function CreateButton()
  btn = CreateFrame("Button", "AmmoBuddyMinimapButton", Minimap)
  btn:SetSize(31, 31)
  btn:SetFrameStrata("MEDIUM")
  btn:SetFrameLevel(8)
  btn:RegisterForClicks("AnyUp")
  btn:RegisterForDrag("LeftButton")
  btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local bg = btn:CreateTexture(nil, "BACKGROUND")
  bg:SetSize(20, 20)
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetPoint("TOPLEFT", 7, -5)

  icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetSize(17, 17)
  icon:SetPoint("TOPLEFT", 7, -6)
  icon:SetTexture(ns.DEFAULT_ICON)

  local border = btn:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53)
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetPoint("TOPLEFT")

  btn:SetScript("OnClick", function() ns.ToggleWindow() end)
  btn:SetScript("OnDragStart", function(self)
    GameTooltip:Hide()
    self:SetScript("OnUpdate", OnDragUpdate)
  end)
  btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("AmmoBuddy")
    GameTooltip:AddLine("Click: open options", 1, 1, 1)
    GameTooltip:AddLine("Drag: move this button", 1, 1, 1)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", GameTooltip_Hide)

  UpdatePosition()
end

function ns.SetMinimapIcon(tex)
  if icon then icon:SetTexture(tex) end
end

function ns.SetMinimapShown(v)
  ns.db.minimap.hide = not v
  if v and not btn then CreateButton() end
  if btn then btn:SetShown(v) end
  if ns.RefreshWindow then ns.RefreshWindow() end
end

table.insert(ns.onReady, function()
  ns.SetMinimapShown(not ns.db.minimap.hide)
end)
