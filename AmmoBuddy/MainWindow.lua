-- AmmoBuddy: main window with sidebar tabs (Arrows/Bullets, Quivers/Pouches, Settings).
-- Opened with /ammo, the minimap button or a right-click on the ammo counter.
local ADDON, ns = ...
if not ns.enabled then return end

local Data = ns.Data
local GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo

local C = {
  bg       = { 0.07, 0.07, 0.08, 0.97 },
  sidebar  = { 0.045, 0.045, 0.05, 1 },
  panel    = { 0.10, 0.10, 0.11, 1 },
  input    = { 0.03, 0.03, 0.035, 1 },
  border   = { 0.22, 0.22, 0.24, 1 },
  accent   = { 0.55, 0.85, 0.30, 1 },
  hover    = { 1, 1, 1, 0.05 },
  selected = { 1, 1, 1, 0.09 },
  stripe   = { 1, 1, 1, 0.025 },
  dim      = { 0.6, 0.6, 0.6 },
}

local TABS = {
  { key = "ammo",     label = "Arrows/Bullets",   icon = function() return ns.ItemIcon(2512) end },
  { key = "bags",     label = "Quivers/Pouches",  icon = function() return ns.ItemIcon(11362) end },
  { key = "settings", label = "Settings",         icon = function() return "Interface\\Icons\\Trade_Engineering" end },
}

local FILTERS = {
  ammo = {
    { key = "arrow",  label = "Arrows",  kinds = { arrow = true } },
    { key = "bullet", label = "Bullets", kinds = { bullet = true } },
    { key = "all",    label = "All",     kinds = { arrow = true, bullet = true } },
  },
  bags = {
    { key = "quiver", label = "Quivers",      kinds = { quiver = true } },
    { key = "pouch",  label = "Ammo Pouches", kinds = { pouch = true } },
    { key = "all",    label = "All",          kinds = { quiver = true, pouch = true } },
  },
}

local WIDTH, HEIGHT, HEADER, SIDEBAR = 760, 480, 56, 180
local BOX_WIDTH = WIDTH - SIDEBAR - 1 - 32
local ROW_HEIGHT = 44

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
  local lines = {}
  local function Line(p1, p2, w, h)
    local t = frame:CreateTexture(nil, "BORDER")
    t:SetColorTexture(unpack(color))
    t:SetPoint(p1); t:SetPoint(p2)
    if w then t:SetWidth(w) else t:SetHeight(h) end
    table.insert(lines, t)
  end
  Line("TOPLEFT", "TOPRIGHT", nil, 1)
  Line("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
  Line("TOPLEFT", "BOTTOMLEFT", 1)
  Line("TOPRIGHT", "BOTTOMRIGHT", 1)
  return lines
end

local function Icon(parent, size, path)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetSize(size, size)
  if path then t:SetTexture(path) end
  t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  return t
end

local function Text(parent, font, text, color)
  local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
  if text then fs:SetText(text) end
  if color then fs:SetTextColor(unpack(color)) end
  return fs
end

local function FlatButton(parent, w, h, label)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h)
  Fill(b, C.panel)
  b.border = Border(b)
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(unpack(C.hover))
  local fs = Text(b)
  fs:SetPoint("CENTER")
  b:SetFontString(fs)
  b:SetText(label)
  b.SetSelected = function(self, on)
    for _, t in ipairs(self.border) do t:SetColorTexture(unpack(on and C.accent or C.border)) end
    fs:SetTextColor(unpack(on and C.accent or { 1, 1, 1 }))
  end
  return b
end

local function Checkbox(parent, label, get, set)
  local row = CreateFrame("Button", nil, parent)
  row:SetSize(250, 22)
  local box = CreateFrame("Frame", nil, row)
  box:SetSize(16, 16)
  box:SetPoint("LEFT")
  Fill(box, C.input)
  Border(box)
  local check = box:CreateTexture(nil, "ARTWORK")
  check:SetPoint("TOPLEFT", 3, -3)
  check:SetPoint("BOTTOMRIGHT", -3, 3)
  check:SetColorTexture(unpack(C.accent))
  local fs = Text(row, nil, label)
  fs:SetPoint("LEFT", box, "RIGHT", 8, 0)
  row:SetScript("OnClick", function() set(not get()) end)
  row.Refresh = function() check:SetShown(get() and true or false) end
  table.insert(refreshers, row)
  return row
end

local function NumberInput(parent, get, set, maxLetters)
  local eb = CreateFrame("EditBox", nil, parent)
  eb:SetSize(64, 22)
  eb:SetFontObject(GameFontHighlight)
  eb:SetJustifyH("CENTER")
  eb:SetAutoFocus(false)
  eb:SetNumeric(true)
  eb:SetMaxLetters(maxLetters or 5)
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

local function Refresher(fn)
  table.insert(refreshers, { Refresh = fn })
end

-- A page fills the content area: gold title on top, bordered panel below.
local function CreatePage(key, title)
  local page = CreateFrame("Frame", nil, window.content)
  page:SetAllPoints()
  page:Hide()
  Text(page, "GameFontNormalLarge", title):SetPoint("TOPLEFT", 16, -16)
  local box = CreateFrame("Frame", nil, page)
  box:SetPoint("TOPLEFT", 16, -44)
  box:SetPoint("BOTTOMRIGHT", -16, 16)
  Fill(box, C.panel)
  Border(box)
  page.box = box
  pages[key] = page
  return page
end

---------------------------------------------------------------------------
-- Item list pages
---------------------------------------------------------------------------
local function ItemStats(item)
  if item.dps then return item.dps .. " DPS" end
  local t = item.slots .. " slots"
  if item.haste then t = t .. "  ·  +" .. item.haste .. "% attack speed" end
  return t
end

local function RowTooltip(row)
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:SetItemByID(row.itemID)
  ns.AddSourceLines(GameTooltip, row.itemID)
  GameTooltip:AddLine(" ")
  if ns.vendorsByItem[row.itemID] then
    GameTooltip:AddLine("Click: show the nearest vendor on the map", 0.5, 0.5, 0.5)
  end
  GameTooltip:AddLine("Shift-click: link the item in chat", 0.5, 0.5, 0.5)
  GameTooltip:Show()
end

local function RowClick(row)
  if IsModifiedClick("CHATLINK") then
    local _, link = GetItemInfo(row.itemID)
    if link then ChatEdit_InsertLink(link) end
  elseif not ns.ShowNearestVendor(row.itemID) and ns.vendorsByItem[row.itemID] then
    ns.Print("Can't open the map right now.")
  end
end

local function CreateRow(parent, width)
  local row = CreateFrame("Button", nil, parent)
  row:SetSize(width, ROW_HEIGHT)
  row.stripe = Fill(row, C.stripe)
  local hl = row:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(unpack(C.hover))
  row.icon = Icon(row, 30)
  row.icon:SetPoint("LEFT", 10, 0)
  row.name = Text(row)
  row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 10, -1)
  row.badge = Text(row, "GameFontHighlightSmall", "Best for you", C.accent)
  row.badge:SetPoint("LEFT", row.name, "RIGHT", 8, 0)
  row.level = Text(row, "GameFontHighlightSmall")
  row.level:SetPoint("TOPRIGHT", -12, -8)
  row.stats = Text(row, "GameFontHighlightSmall", nil, C.dim)
  row.stats:SetPoint("BOTTOMRIGHT", -12, 8)
  row.source = Text(row, "GameFontHighlightSmall", nil, C.dim)
  row.source:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 10, 1)
  row.source:SetPoint("RIGHT", row, "RIGHT", -190, 0)
  row.source:SetJustifyH("LEFT")
  row.source:SetWordWrap(false)
  row:SetScript("OnEnter", RowTooltip)
  row:SetScript("OnLeave", GameTooltip_Hide)
  row:SetScript("OnClick", RowClick)
  return row
end

local function BuildItemPage(key, title)
  local page = CreatePage(key, title)
  local box, filters = page.box, FILTERS[key]

  -- Filter buttons (top right, next to the title)
  local buttons, x = {}, -16
  for i = #filters, 1, -1 do
    local f = filters[i]
    local b = FlatButton(page, f.label == "All" and 50 or 110, 22, f.label)
    b:SetPoint("TOPRIGHT", x, -12)
    x = x - b:GetWidth() - 6
    b:SetScript("OnClick", function() ns.db.filters[key] = f.key; page:Refresh() end)
    buttons[f.key] = b
  end

  -- Scrollable list
  local scroll = CreateFrame("ScrollFrame", nil, box)
  scroll:SetPoint("TOPLEFT", 1, -1)
  scroll:SetPoint("BOTTOMRIGHT", -10, 1)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(BOX_WIDTH - 11, 1)
  scroll:SetScrollChild(child)

  local track = box:CreateTexture(nil, "ARTWORK")
  track:SetColorTexture(1, 1, 1, 0.04)
  track:SetPoint("TOPRIGHT", -3, -4)
  track:SetPoint("BOTTOMRIGHT", -3, 4)
  track:SetWidth(4)
  local thumb = box:CreateTexture(nil, "OVERLAY")
  thumb:SetColorTexture(unpack(C.border))
  thumb:SetWidth(4)

  local function UpdateThumb()
    local range = scroll:GetVerticalScrollRange()
    local trackH = scroll:GetHeight() - 8
    if range <= 0 then thumb:Hide(); track:Hide(); return end
    local visible = scroll:GetHeight()
    local h = math.max(20, trackH * visible / (visible + range))
    thumb:ClearAllPoints()
    thumb:SetPoint("TOPRIGHT", track, "TOPRIGHT", 0, -(trackH - h) * scroll:GetVerticalScroll() / range)
    thumb:SetHeight(h)
    thumb:Show(); track:Show()
  end

  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    local v = self:GetVerticalScroll() - delta * ROW_HEIGHT * 2
    self:SetVerticalScroll(math.max(0, math.min(v, self:GetVerticalScrollRange())))
    UpdateThumb()
  end)

  local empty = Text(box, nil, "Nothing found.", C.dim)
  empty:SetPoint("CENTER")

  local rows = {}
  function page:Refresh()
    local filterKey = ns.db.filters[key]
    if not filterKey then
      local kind = ns.RangedAmmoKind()
      if kind and key == "bags" then kind = ns.BAG_FOR_AMMO[kind] end
      filterKey = kind or "all"
    end
    local filter
    for _, f in ipairs(filters) do
      if f.key == filterKey then filter = f end
      buttons[f.key]:SetSelected(f.key == filterKey)
    end
    filter = filter or filters[#filters]

    local best = {}
    for kind in pairs(filter.kinds) do
      local id = ns.BestVendorItem(kind)
      if id then best[id] = true end
    end

    local level = UnitLevel("player")
    local items = ns.ItemsOfKinds(filter.kinds)
    for i, itemID in ipairs(items) do
      local row = rows[i]
      if not row then
        row = CreateRow(child, BOX_WIDTH - 11)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        rows[i] = row
      end
      local item = Data.items[itemID]
      row.itemID = itemID
      row.stripe:SetShown(i % 2 == 0)
      row.icon:SetTexture(ns.ItemIcon(itemID))
      row.name:SetText(item.name)
      row.name:SetTextColor(ns.QualityColor(item.quality))
      row.badge:SetShown(best[itemID] or false)
      row.level:SetText(item.req > 0 and ("Level " .. item.req) or "Any level")
      if item.req > level then row.level:SetTextColor(1, 0.25, 0.25) else row.level:SetTextColor(1, 1, 1) end
      row.stats:SetText(ItemStats(item))
      row.source:SetText(ns.SourceSummary(itemID))
      row:Show()
    end
    for i = #items + 1, #rows do rows[i]:Hide() end
    empty:SetShown(#items == 0)
    child:SetHeight(math.max(1, #items * ROW_HEIGHT))
    scroll:SetVerticalScroll(0)
    UpdateThumb()
  end

  page:SetScript("OnShow", page.Refresh)
  return page
end

---------------------------------------------------------------------------
-- Settings page
---------------------------------------------------------------------------
local function BuildSettingsPage()
  local box = CreatePage("settings", "Settings").box
  local col2 = math.floor(BOX_WIDTH / 2) + 8

  -- Left column: ammo counter and warnings
  Text(box, "GameFontNormal", "Ammo counter"):SetPoint("TOPLEFT", 16, -14)
  Checkbox(box, "Show ammo counter",
    function() return not ns.db.hidden end, ns.SetCounterShown):SetPoint("TOPLEFT", 16, -36)
  Checkbox(box, "Lock ammo counter",
    function() return ns.db.locked end, ns.SetLocked):SetPoint("TOPLEFT", 16, -60)
  local reset = FlatButton(box, 180, 24, "Reset counter position")
  reset:SetPoint("TOPLEFT", 16, -90)
  reset:SetScript("OnClick", function() ns.ResetPosition() end)

  Text(box, "GameFontNormal", "Warnings"):SetPoint("TOPLEFT", 16, -138)
  local warnLabel = Text(box, nil, "Raid warning at")
  warnLabel:SetPoint("TOPLEFT", 16, -164)
  NumberInput(box, function() return ns.db.warn end, ns.SetWarn):SetPoint("LEFT", warnLabel, "RIGHT", 12, 0)
  local warnHelp = Text(box, "GameFontHighlightSmall", nil, C.dim)
  warnHelp:SetPoint("TOPLEFT", 16, -190)
  warnHelp:SetWidth(col2 - 40)
  warnHelp:SetJustifyH("LEFT")
  Refresher(function()
    warnHelp:SetText(string.format("You also get a chat reminder (only you can see it) at %d and %d.",
      ns.db.warn + ns.CHAT_STEPS[1], ns.db.warn + ns.CHAT_STEPS[2]))
  end)

  -- Right column: map and auto-buy
  Text(box, "GameFontNormal", "Map"):SetPoint("TOPLEFT", col2, -14)
  Checkbox(box, "Show minimap button",
    function() return not ns.db.minimap.hide end, ns.SetMinimapShown):SetPoint("TOPLEFT", col2, -36)
  Checkbox(box, "Show vendors on the world map",
    function() return ns.db.mapPins end, ns.SetMapPins):SetPoint("TOPLEFT", col2, -60)
  Checkbox(box, "Show vendors on the minimap",
    function() return ns.db.minimapPins end, ns.SetMinimapPins):SetPoint("TOPLEFT", col2, -84)

  Text(box, "GameFontNormal", "Auto-buy"):SetPoint("TOPLEFT", col2, -138)
  Checkbox(box, "Buy the best ammo at vendors",
    function() return ns.db.autoBuy end, ns.SetAutoBuy):SetPoint("TOPLEFT", col2, -160)
  Checkbox(box, "Detect quiver / pouch slots",
    function() return ns.db.autoSlots end, ns.SetAutoSlots):SetPoint("TOPLEFT", col2, -184)

  local slotsLabel = Text(box, nil, "Quiver / pouch slots")
  slotsLabel:SetPoint("TOPLEFT", col2, -216)
  local slots = NumberInput(box, function() return ns.db.quiverSlots end, ns.SetQuiverSlots, 2)
  slots:SetPoint("LEFT", slotsLabel, "RIGHT", 12, 0)
  slots:SetWidth(40)
  local detected = Text(box, "GameFontHighlightSmall", nil, C.dim)
  detected:SetPoint("LEFT", slots, "RIGHT", 10, 0)

  local buyHelp = Text(box, "GameFontHighlightSmall", nil, C.dim)
  buyHelp:SetPoint("TOPLEFT", col2, -246)
  buyHelp:SetWidth(BOX_WIDTH - col2 - 16)
  buyHelp:SetJustifyH("LEFT")
  buyHelp:SetText("Only fills your quiver or ammo pouch and always keeps two normal bag slots free. "
    .. "The slot number is used when no matching quiver or pouch is equipped. "
    .. "Hold Shift while talking to a vendor to skip auto-buy.")

  Refresher(function()
    local auto = ns.db.autoSlots
    local kind = ns.RangedAmmoKind() or "arrow"
    local found = ns.DetectAmmoBagSlots(kind)
    if auto and found > 0 then
      detected:SetText("Detected: " .. found)
      slots:SetAlpha(0.4)
      slots:Disable()
    else
      detected:SetText(auto and "None equipped" or "")
      slots:SetAlpha(1)
      slots:Enable()
    end
  end)
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
  local icon = Icon(b, 22, tab.icon())
  icon:SetPoint("LEFT", 12, 0)
  Text(b, nil, tab.label):SetPoint("LEFT", icon, "RIGHT", 10, 0)
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
  Text(header, "GameFontHighlightLarge", "AmmoBuddy"):SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, -1)
  Text(header, "GameFontHighlightSmall", "Ammo & quiver helper for Hunters", C.dim)
    :SetPoint("BOTTOMLEFT", logo, "BOTTOMRIGHT", 10, 2)

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
  local version = Text(sidebar, "GameFontHighlightSmall", "v" .. (GetMeta(ADDON, "Version") or "?"))
  version:SetPoint("BOTTOMLEFT", 12, 10)
  version:SetTextColor(0.45, 0.45, 0.45)

  local mm = FlatButton(sidebar, SIDEBAR - 16, 28, "")
  mm:SetPoint("BOTTOMLEFT", 8, 28)
  mm:SetScript("OnClick", function() ns.SetMinimapShown(ns.db.minimap.hide) end)
  Refresher(function()
    mm:SetText(ns.db.minimap.hide and "Show on minimap" or "Hide from minimap")
  end)

  -- Content area
  window.content = CreateFrame("Frame", nil, window)
  window.content:SetPoint("TOPLEFT", SIDEBAR + 1, -HEADER)
  window.content:SetPoint("BOTTOMRIGHT", -1, 1)

  BuildItemPage("ammo", "Arrows/Bullets")
  BuildItemPage("bags", "Quivers/Pouches")
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
