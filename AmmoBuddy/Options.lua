-- AmmoBuddy: options window (opened with /ammo, the minimap button or a right-click on the counter)
local ADDON, ns = ...
if not ns.enabled then return end

local panel
local widgets = {}

local function CreateCheckbox(label, y, get, set)
  local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
  cb:SetSize(26, 26)
  cb:SetPoint("TOPLEFT", 20, y)
  local t = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  t:SetPoint("LEFT", cb, "RIGHT", 4, 0)
  t:SetText(label)
  cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
  cb.Refresh = function() cb:SetChecked(get()) end
  table.insert(widgets, cb)
  return cb
end

local function CreatePanel()
  panel = CreateFrame("Frame", "AmmoBuddyOptions", UIParent, "BackdropTemplate")
  panel:SetSize(270, 230)
  panel:SetPoint("CENTER")
  panel:SetFrameStrata("DIALOG")
  panel:SetClampedToScreen(true)
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", panel.StartMoving)
  panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
  panel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  panel:Hide()
  table.insert(UISpecialFrames, "AmmoBuddyOptions") -- close with Escape

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -18)
  title:SetText("AmmoBuddy")

  local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -6, -6)

  CreateCheckbox("Show ammo counter", -48,
    function() return not ns.db.hidden end, ns.SetCounterShown)
  CreateCheckbox("Lock ammo counter", -76,
    function() return ns.db.locked end, ns.SetLocked)
  CreateCheckbox("Show minimap button", -104,
    function() return not ns.db.minimap.hide end, ns.SetMinimapShown)

  local warnLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  warnLabel:SetPoint("TOPLEFT", 26, -146)
  warnLabel:SetText("Low-ammo warning at")

  local warnBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
  warnBox:SetSize(60, 20)
  warnBox:SetPoint("LEFT", warnLabel, "RIGHT", 12, 0)
  warnBox:SetAutoFocus(false)
  warnBox:SetNumeric(true)
  warnBox:SetMaxLetters(5)
  local function ApplyWarn(self)
    local v = tonumber(self:GetText())
    if v then ns.SetWarn(v) else self:SetText(ns.db.warn) end
  end
  warnBox:SetScript("OnEnterPressed", function(self) ApplyWarn(self); self:ClearFocus() end)
  warnBox:SetScript("OnEditFocusLost", ApplyWarn)
  warnBox:SetScript("OnEscapePressed", function(self) self:SetText(ns.db.warn); self:ClearFocus() end)
  warnBox.Refresh = function() if not warnBox:HasFocus() then warnBox:SetText(ns.db.warn) end end
  table.insert(widgets, warnBox)

  local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  reset:SetSize(160, 24)
  reset:SetPoint("BOTTOM", 0, 22)
  reset:SetText("Reset counter position")
  reset:SetScript("OnClick", function() ns.ResetPosition() end)

  panel:SetScript("OnShow", function() ns.RefreshOptions() end)
end

function ns.RefreshOptions()
  if not panel or not panel:IsShown() then return end
  for _, w in ipairs(widgets) do w.Refresh() end
end

function ns.ToggleOptions()
  if not panel then CreatePanel() end
  panel:SetShown(not panel:IsShown())
end
