-- AmmoBuddy: main window with sidebar tabs (Ammo, Bags, Settings).
-- Opened with /ammo, the minimap button or a right-click on the ammo counter.
local ADDON, ns = ...
if not ns.enabled then return end

local C = {
  bg       = { 0.07, 0.07, 0.08, 0.97 },
  sidebar  = { 0.045, 0.045, 0.05, 1 },
  panel    = { 0.10, 0.10, 0.11, 1 },
  input    = { 0.03, 0.03, 0.035, 1 },
  border   = { 0.22, 0.22, 0.24, 1 },
  accent   = { 0.55, 0.85, 0.30, 1 },
  hover    = { 1, 1, 1, 0.05 },
  selected = { 1, 1, 1, 0.09 },
  dim      = { 0.6, 0.6, 0.6 },
}

local TABS = {
  { key = "ammo",     label = "Ammo",     icon = "Interface\\Icons\\INV_Ammo_Arrow_02" },
  { key = "bags",     label = "Bags",     icon = "Interface\\Icons\\INV_Misc_Bag_08" },
  { key = "settings", label = "Settings", icon = "Interface\\Icons\\Trade_Engineering" },
}

local WIDTH, HEIGHT, HEADER, SIDEBAR = 640, 420, 56, 180

local window
local tabButtons, pages, refreshers = {}, {}, {}

---------------------------------------------------------------------------
-- Flat style helpers
---------------------------------------------------------------------------
local function Fill(frame, color, layer)
  local t = frame:CreateTexture(nil, layer or "BACKGROUND")
  t:SetAllPoints()
  t:SetColorTexture(unpack(color))
  return t
end

local function Border(frame, color)
  color = color or C.border
  local function Line(p1, p2, w, h)
    local t = frame:CreateTexture(nil, "BORDER")
    t:SetColorTexture(unpack(color))
    t:SetPoint(p1); t:SetPoint(p2)
    if w then t:SetWidth(w) else t:SetHeight(h) end
  end
  Line("TOPLEFT", "TOPRIGHT", nil, 1)
  Line("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
  Line("TOPLEFT", "BOTTOMLEFT", 1)
  Line("TOPRIGHT", "BOTTOMRIGHT", 1)
end

local function Icon(parent, size, path)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetSize(size, size)
  t:SetTexture(path)
  t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  return t
end

local function FlatButton(parent, w, h, label)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h)
  Fill(b, C.panel)
  Border(b)
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(unpack(C.hover))
  local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("CENTER")
  b:SetFontString(fs)
  b:SetText(label)
  return b
end

local function Checkbox(parent, label, get, set)
  local row = CreateFrame("Button", nil, parent)
  row:SetSize(280, 22)
  local box = CreateFrame("Frame", nil, row)
  box:SetSize(16, 16)
  box:SetPoint("LEFT")
  Fill(box, C.input)
  Border(box)
  local check = box:CreateTexture(nil, "ARTWORK")
  check:SetPoint("TOPLEFT", 3, -3)
  check:SetPoint("BOTTOMRIGHT", -3, 3)
  check:SetColorTexture(unpack(C.accent))
  local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("LEFT", box, "RIGHT", 8, 0)
  fs:SetText(label)
  row:SetScript("OnClick", function() set(not get()) end)
  row.Refresh = function() check:SetShown(get() and true or false) end
  table.insert(refreshers, row)
  return row
end

local function NumberInput(parent, get, set)
  local eb = CreateFrame("EditBox", nil, parent)
  eb:SetSize(64, 22)
  eb:SetFontObject(GameFontHighlight)
  eb:SetJustifyH("CENTER")
  eb:SetAutoFocus(false)
  eb:SetNumeric(true)
  eb:SetMaxLetters(5)
  Fill(eb, C.input)
  Border(eb)
  local function Apply(self)
    local v = tonumber(self:GetText())
    if v then set(v) else self:SetText(get()) end
  end
  eb:SetScript("OnEnterPressed", function(self) Apply(self); self:ClearFocus() end)
  eb:SetScript("OnEditFocusLost", Apply)
  eb:SetScript("OnEscapePressed", function(self) self:SetText(get()); self:ClearFocus() end)
  eb.Refresh = function() if not eb:HasFocus() then eb:SetText(get()) end end
  table.insert(refreshers, eb)
  return eb
end

local function SectionTitle(parent, text, x, y)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetPoint("TOPLEFT", x, y)
  fs:SetText(text)
  return fs
end

-- A page fills the content area: gold title on top, bordered panel below.
local function CreatePage(key, title)
  local page = CreateFrame("Frame", nil, window.content)
  page:SetAllPoints()
  page:Hide()
  local fs = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  fs:SetPoint("TOPLEFT", 16, -14)
  fs:SetText(title)
  local box = CreateFrame("Frame", nil, page)
  box:SetPoint("TOPLEFT", 16, -42)
  box:SetPoint("BOTTOMRIGHT", -16, 16)
  Fill(box, C.panel)
  Border(box)
  page.box = box
  pages[key] = page
  return page
end

local function ComingSoon(page)
  local fs = page.box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("CENTER")
  fs:SetTextColor(unpack(C.dim))
  fs:SetText("Coming soon.")
end

---------------------------------------------------------------------------
-- Pages
---------------------------------------------------------------------------
local function BuildSettingsPage()
  local box = CreatePage("settings", "Settings").box

  SectionTitle(box, "Ammo counter", 16, -14)
  Checkbox(box, "Show ammo counter",
    function() return not ns.db.hidden end, ns.SetCounterShown):SetPoint("TOPLEFT", 16, -36)
  Checkbox(box, "Lock ammo counter",
    function() return ns.db.locked end, ns.SetLocked):SetPoint("TOPLEFT", 16, -60)

  local warnLabel = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  warnLabel:SetPoint("TOPLEFT", 16, -96)
  warnLabel:SetText("Low-ammo warning at")
  NumberInput(box, function() return ns.db.warn end, ns.SetWarn)
    :SetPoint("LEFT", warnLabel, "RIGHT", 12, 0)

  local reset = FlatButton(box, 180, 24, "Reset counter position")
  reset:SetPoint("TOPLEFT", 16, -124)
  reset:SetScript("OnClick", function() ns.ResetPosition() end)

  SectionTitle(box, "Minimap", 16, -172)
  Checkbox(box, "Show minimap button",
    function() return not ns.db.minimap.hide end, ns.SetMinimapShown):SetPoint("TOPLEFT", 16, -194)
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local function SelectTab(key)
  ns.db.tab = key
  for k, page in pairs(pages) do page:SetShown(k == key) end
  for k, b in pairs(tabButtons) do
    b.selected:SetShown(k == key)
    b.bar:SetShown(k == key)
  end
end

local function CreateTabButton(parent, tab, index)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(SIDEBAR - 16, 34)
  b:SetPoint("TOPLEFT", 8, -10 - (index - 1) * 38)
  b.selected = Fill(b, C.selected)
  b.bar = b:CreateTexture(nil, "ARTWORK")
  b.bar:SetColorTexture(unpack(C.accent))
  b.bar:SetPoint("TOPLEFT"); b.bar:SetPoint("BOTTOMLEFT")
  b.bar:SetWidth(3)
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(unpack(C.hover))
  local icon = Icon(b, 22, tab.icon)
  icon:SetPoint("LEFT", 12, 0)
  local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("LEFT", icon, "RIGHT", 10, 0)
  fs:SetText(tab.label)
  b:SetScript("OnClick", function() SelectTab(tab.key) end)
  tabButtons[tab.key] = b
end

local function CreateWindow()
  window = CreateFrame("Frame", "AmmoBuddyWindow", UIParent)
  window:SetSize(WIDTH, HEIGHT)
  window:SetPoint("CENTER")
  window:SetFrameStrata("DIALOG")
  window:SetClampedToScreen(true)
  window:SetMovable(true)
  window:EnableMouse(true)
  window:Hide()
  Fill(window, C.bg)
  Border(window)
  table.insert(UISpecialFrames, "AmmoBuddyWindow") -- close with Escape

  -- Header (also the drag handle)
  local header = CreateFrame("Frame", nil, window)
  header:SetPoint("TOPLEFT"); header:SetPoint("TOPRIGHT")
  header:SetHeight(HEADER)
  header:EnableMouse(true)
  header:RegisterForDrag("LeftButton")
  header:SetScript("OnDragStart", function() window:StartMoving() end)
  header:SetScript("OnDragStop", function() window:StopMovingOrSizing() end)
  local sep = header:CreateTexture(nil, "BORDER")
  sep:SetColorTexture(unpack(C.border))
  sep:SetPoint("BOTTOMLEFT"); sep:SetPoint("BOTTOMRIGHT")
  sep:SetHeight(1)

  local logo = Icon(header, 36, ns.DEFAULT_ICON)
  logo:SetPoint("LEFT", 12, 0)
  local title = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, -1)
  title:SetText("AmmoBuddy")
  local subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  subtitle:SetPoint("BOTTOMLEFT", logo, "BOTTOMRIGHT", 10, 2)
  subtitle:SetTextColor(unpack(C.dim))
  subtitle:SetText("Ammo & bag helper for Hunters")

  local close = CreateFrame("Button", nil, header)
  close:SetSize(20, 20)
  close:SetPoint("RIGHT", -14, 0)
  local x = close:CreateTexture(nil, "ARTWORK")
  x:SetAllPoints()
  x:SetTexture("Interface\\Buttons\\UI-StopButton")
  x:SetVertexColor(unpack(C.dim))
  close:SetScript("OnEnter", function() x:SetVertexColor(1, 1, 1) end)
  close:SetScript("OnLeave", function() x:SetVertexColor(unpack(C.dim)) end)
  close:SetScript("OnClick", function() window:Hide() end)

  -- Sidebar
  local sidebar = CreateFrame("Frame", nil, window)
  sidebar:SetPoint("TOPLEFT", 1, -HEADER)
  sidebar:SetPoint("BOTTOMLEFT", 1, 1)
  sidebar:SetWidth(SIDEBAR)
  Fill(sidebar, C.sidebar)
  local sideSep = sidebar:CreateTexture(nil, "BORDER")
  sideSep:SetColorTexture(unpack(C.border))
  sideSep:SetPoint("TOPRIGHT"); sideSep:SetPoint("BOTTOMRIGHT")
  sideSep:SetWidth(1)

  for i, tab in ipairs(TABS) do CreateTabButton(sidebar, tab, i) end

  local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local version = sidebar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  version:SetPoint("BOTTOMLEFT", 12, 10)
  version:SetTextColor(0.45, 0.45, 0.45)
  version:SetText("v" .. (GetMeta(ADDON, "Version") or "?"))

  local mm = FlatButton(sidebar, SIDEBAR - 16, 28, "")
  mm:SetPoint("BOTTOMLEFT", 8, 28)
  mm:SetScript("OnClick", function() ns.SetMinimapShown(ns.db.minimap.hide) end)
  mm.Refresh = function()
    mm:SetText(ns.db.minimap.hide and "Show on minimap" or "Hide from minimap")
  end
  table.insert(refreshers, mm)

  -- Content area
  window.content = CreateFrame("Frame", nil, window)
  window.content:SetPoint("TOPLEFT", SIDEBAR + 1, -HEADER)
  window.content:SetPoint("BOTTOMRIGHT", -1, 1)

  ComingSoon(CreatePage("ammo", "Ammo"))
  ComingSoon(CreatePage("bags", "Bags"))
  BuildSettingsPage()

  window:SetScript("OnShow", function() ns.RefreshWindow() end)
  SelectTab(pages[ns.db.tab] and ns.db.tab or TABS[1].key)
end

function ns.RefreshWindow()
  if not window or not window:IsShown() then return end
  for _, w in ipairs(refreshers) do w.Refresh() end
end

function ns.ToggleWindow(tab)
  if not window then CreateWindow() end
  if tab then
    SelectTab(tab)
    window:Show()
  else
    window:SetShown(not window:IsShown())
  end
end
