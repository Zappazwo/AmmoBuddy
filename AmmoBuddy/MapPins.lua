-- AmmoBuddy: vendor pins on the world map and the minimap (no libraries)
local ADDON, ns = ...
if not ns.enabled then return end

local Data = ns.Data
local PIN_SIZE_MAP, PIN_SIZE_MINIMAP = 18, 14

-- Minimap diameter in yards per zoom level (same values HereBeDragons uses).
local MINIMAP_YARDS = {
  outdoor = { [0] = 466 + 2 / 3, [1] = 400, [2] = 333 + 1 / 3, [3] = 266 + 2 / 3, [4] = 200, [5] = 133 + 1 / 3 },
  indoor  = { [0] = 300, [1] = 240, [2] = 180, [3] = 120, [4] = 80, [5] = 50 },
}

---------------------------------------------------------------------------
-- Pins and tooltip
---------------------------------------------------------------------------
local function ShowVendorTooltip(pin)
  local vendor = Data.vendors[pin.vendorID]
  if not vendor then return end
  GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
  GameTooltip:SetText(vendor.name, 1, 1, 1)
  if vendor.title then GameTooltip:AddLine(vendor.title, 0.6, 0.6, 0.6) end
  GameTooltip:AddLine(" ")
  local level = UnitLevel("player")
  for _, itemID in ipairs(vendor.items) do
    local item = Data.items[itemID]
    if item then
      local line = string.format("|T%s:16|t %s", ns.ItemIcon(itemID), ns.ColoredName(itemID))
      local r, g, b = 0.8, 0.8, 0.8
      if item.req > level then r, g, b = 1, 0.25, 0.25 end
      GameTooltip:AddDoubleLine(line, "Level " .. item.req, 1, 1, 1, r, g, b)
    end
  end
  GameTooltip:Show()
end

local function CreatePin(parent, size)
  local pin = CreateFrame("Button", nil, parent)
  pin:SetSize(size, size)
  local border = pin:CreateTexture(nil, "BACKGROUND")
  border:SetAllPoints()
  border:SetColorTexture(0, 0, 0, 0.85)
  pin.icon = pin:CreateTexture(nil, "ARTWORK")
  pin.icon:SetPoint("TOPLEFT", 1, -1)
  pin.icon:SetPoint("BOTTOMRIGHT", -1, 1)
  pin.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  pin:SetScript("OnEnter", ShowVendorTooltip)
  pin:SetScript("OnLeave", GameTooltip_Hide)
  return pin
end

---------------------------------------------------------------------------
-- World map
--
-- Blizzard's map (and map addons built on it): a map canvas data provider with our own pin pool,
-- the same way Blizzard's own pins and HereBeDragons work. Blizzard places, scales and layers them.
-- OpenMap's seamless map draws its own art over the canvas: there, pins are placed by world
-- position through OpenMapAPI and lifted above its art.
---------------------------------------------------------------------------
local TEMPLATE = "AmmoBuddyVendorPinTemplate"

-- OpenMap (seamless world map for WoW Forever), while its stitched map is shown.
local function OpenMap()
  local OM = OpenMapAPI
  if OM and (OM.version or 0) >= 2 and OM.IsStitched() then return OM end
end

-- Pin icons (our buttons with tooltip), reused between the provider's pins.
local freeIcons = {}
local function AcquireIcon(parent, vendorID)
  local icon = table.remove(freeIcons) or CreatePin(parent, PIN_SIZE_MAP)
  icon:SetParent(parent)
  icon:SetScale(1)
  icon.vendorID = vendorID
  icon.icon:SetTexture(ns.VendorIcon(Data.vendors[vendorID]))
  icon:ClearAllPoints()
  icon:Show()
  return icon
end
local function ReleaseIcon(icon)
  icon:Hide()
  icon:ClearAllPoints()
  icon:SetParent(UIParent)
  table.insert(freeIcons, icon)
end

-- Data provider ------------------------------------------------------------
local provider
local function CreateProvider()
  if provider or not (MapCanvasDataProviderMixin and MapCanvasPinMixin and WorldMapFrame.AddDataProvider
      and WorldMapFrame.pinPools and (CreateUnsecuredRegionPoolInstance or CreateFramePool)) then
    return
  end
  local pinMixin = CreateFromMixins(MapCanvasPinMixin)

  function pinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    self:SetScalingLimits(1, 1.0, 1.2)
  end
  function pinMixin:OnAcquired(vendorID, x, y)
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    self:SetScalingLimits(1, 1.0, 1.2)
    self:SetPosition(x, y)
    self.vendorIcon = AcquireIcon(self, vendorID)
    self.vendorIcon:SetPoint("CENTER", self, "CENTER")
  end
  function pinMixin:OnReleased()
    if self.vendorIcon then ReleaseIcon(self.vendorIcon); self.vendorIcon = nil end
  end
  pinMixin.SetPassThroughButtons = function() end -- avoids an in-combat error (as HereBeDragons does)

  local pool = CreateUnsecuredRegionPoolInstance and CreateUnsecuredRegionPoolInstance(TEMPLATE) or CreateFramePool("FRAME")
  pool.parent = WorldMapFrame:GetCanvas()
  pool.createFunc = function()
    local frame = CreateFrame("Frame", nil, WorldMapFrame:GetCanvas())
    frame:SetSize(1, 1)
    return Mixin(frame, pinMixin)
  end
  pool.resetFunc = function(_, pin)
    pin:Hide()
    pin:ClearAllPoints()
    pin:OnReleased()
    pin.pinTemplate = nil
    pin.owningMap = nil
  end
  pool.creationFunc, pool.resetterFunc = pool.createFunc, pool.resetFunc -- older clients' names
  WorldMapFrame.pinPools[TEMPLATE] = pool

  provider = CreateFromMixins(MapCanvasDataProviderMixin)
  function provider:RemoveAllData()
    self:GetMap():RemoveAllPinsByTemplate(TEMPLATE)
  end
  function provider:RefreshAllData()
    self:RemoveAllData()
    if not ns.db or not ns.db.mapPins or OpenMap() then return end
    local map = self:GetMap()
    for _, e in ipairs(ns.vendorsByMap[map:GetMapID()] or {}) do
      if ns.VendorVisible(Data.vendors[e.id]) then
        map:AcquirePin(TEMPLATE, e.id, e.x, e.y)
      end
    end
  end
  WorldMapFrame:AddDataProvider(provider)
end

-- OpenMap's stitched map (and fallback without the provider API) ----------
local canvasPins, canvasUsed = {}, 0

local function PlaceCanvasPin(canvas, vendorID, mx, my, scale, level)
  canvasUsed = canvasUsed + 1
  local pin = canvasPins[canvasUsed]
  if not pin then
    pin = CreatePin(canvas, PIN_SIZE_MAP)
    canvasPins[canvasUsed] = pin
  end
  local w, h = canvas:GetSize()
  pin.vendorID = vendorID
  pin.icon:SetTexture(ns.VendorIcon(Data.vendors[vendorID]))
  pin:SetScale(scale)
  -- Frame levels on the map can't be changed in combat; keep the last one then.
  if not InCombatLockdown() then pin:SetFrameLevel(level) end
  pin:ClearAllPoints()
  -- SetPoint offsets are in the pin's own (scaled) units.
  pin:SetPoint("CENTER", canvas, "TOPLEFT", mx * w / scale, -my * h / scale)
  pin:Show()
end

local function RefreshCanvasPins()
  for i = 1, #canvasPins do canvasPins[i]:Hide() end
  canvasUsed = 0
  if not ns.db or not ns.db.mapPins or not WorldMapFrame:IsShown() then return end
  local OM = OpenMap()
  if not OM and provider then return end -- Blizzard's map: the data provider shows them

  local canvas = WorldMapFrame:GetCanvas()
  local scale = WorldMapFrame.GetCanvasScale and (1 / WorldMapFrame:GetCanvasScale()) or 1
  local level = canvas:GetFrameLevel() + 2100

  if OM then
    local top = OM.ArtTopLevel and OM.ArtTopLevel()
    if top and level <= top then level = top + 5 end
    for _, s in ipairs(ns.VendorSpawns()) do
      if ns.VendorVisible(Data.vendors[s.id]) then
        local mx, my = OM.CanvasFromWorldPos(s.cont, s.north, s.west)
        -- Keep pins just outside the map underneath: the stitched view shows its neighbours.
        if mx and mx > -1 and mx < 2 and my > -1 and my < 2 then
          PlaceCanvasPin(canvas, s.id, mx, my, scale, level)
        end
      end
    end
  else
    for _, e in ipairs(ns.vendorsByMap[WorldMapFrame:GetMapID()] or {}) do
      if ns.VendorVisible(Data.vendors[e.id]) then
        PlaceCanvasPin(canvas, e.id, e.x, e.y, scale, level)
      end
    end
  end
end

function ns.RefreshWorldMapPins()
  if not WorldMapFrame then return end
  if provider and provider:GetMap() then provider:RefreshAllData() end
  RefreshCanvasPins()
end

local function HookWorldMap()
  if not WorldMapFrame or WorldMapFrame.AmmoBuddyHooked then return end
  WorldMapFrame.AmmoBuddyHooked = true
  CreateProvider()
  WorldMapFrame:HookScript("OnShow", RefreshCanvasPins)
  hooksecurefunc(WorldMapFrame, "OnMapChanged", RefreshCanvasPins)
  if WorldMapFrame.OnCanvasScaleChanged then
    hooksecurefunc(WorldMapFrame, "OnCanvasScaleChanged", RefreshCanvasPins)
  end
  local OM = OpenMapAPI
  if OM and OM.RegisterCallback then
    local owner = {}
    OM.RegisterCallback(owner, "OpenMap_ViewChanged", RefreshCanvasPins)
    -- Switching between OpenMap's and Blizzard's map: move the pins to the other system.
    OM.RegisterCallback(owner, "OpenMap_StitchedChanged", function() ns.RefreshWorldMapPins() end)
  end
end

---------------------------------------------------------------------------
-- Minimap
---------------------------------------------------------------------------
local miniPins = {}
local updater = CreateFrame("Frame")
local elapsed = 0

local function HideMinimapPins(from)
  for i = from or 1, #miniPins do miniPins[i]:Hide() end
end

local function UpdateMinimapPins()
  local cont, pNorth, pWest = ns.PlayerWorldPos()
  if not cont then HideMinimapPins(); return end

  local zoom = Minimap:GetZoom()
  local yards = (IsIndoors() and MINIMAP_YARDS.indoor or MINIMAP_YARDS.outdoor)[zoom] or 400
  local size = Minimap:GetWidth()
  local radius = size / 2 - PIN_SIZE_MINIMAP / 2
  local pxPerYard = size / yards
  local square = GetMinimapShape and GetMinimapShape() == "SQUARE"

  local facing = 0
  if GetCVar("rotateMinimap") == "1" then
    facing = GetPlayerFacing()
    if not facing or ns.IsSecret(facing) then facing = 0 end
  end
  local cosF, sinF = math.cos(facing), math.sin(facing)

  local used = 0
  for _, s in ipairs(ns.VendorSpawns()) do
    if s.cont == cont and ns.VendorVisible(Data.vendors[s.id]) then
      local north, east = s.north - pNorth, pWest - s.west
      -- Rotating minimap: turn the map so that the player's facing points up.
      local x = (east * cosF + north * sinF) * pxPerYard
      local y = (-east * sinF + north * cosF) * pxPerYard
      local inside
      if square then
        inside = math.abs(x) <= radius and math.abs(y) <= radius
      else
        inside = x * x + y * y <= radius * radius
      end
      if inside then
        used = used + 1
        local pin = miniPins[used]
        if not pin then
          pin = CreatePin(Minimap, PIN_SIZE_MINIMAP)
          miniPins[used] = pin
        end
        pin.vendorID = s.id
        pin.icon:SetTexture(ns.VendorIcon(Data.vendors[s.id]))
        pin:SetFrameLevel(Minimap:GetFrameLevel() + 5)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", Minimap, "CENTER", x, y)
        pin:Show()
      end
    end
  end
  HideMinimapPins(used + 1)
end

updater:SetScript("OnUpdate", function(_, dt)
  elapsed = elapsed + dt
  if elapsed < 0.1 then return end
  elapsed = 0
  UpdateMinimapPins()
end)

function ns.RefreshMinimapPins()
  if ns.db.minimapPins then
    updater:Show()
  else
    updater:Hide()
    HideMinimapPins()
  end
end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
function ns.SetMapPins(v)
  ns.db.mapPins = v
  ns.RefreshWorldMapPins()
  if ns.RefreshWindow then ns.RefreshWindow() end
end

function ns.SetMinimapPins(v)
  ns.db.minimapPins = v
  ns.RefreshMinimapPins()
  if ns.RefreshWindow then ns.RefreshWindow() end
end

updater:Hide()
table.insert(ns.onReady, function()
  HookWorldMap()
  if not WorldMapFrame then
    -- The world map may be load-on-demand; hook it once it is loaded.
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, _, name)
      if name == "Blizzard_WorldMap" then HookWorldMap(); self:UnregisterAllEvents() end
    end)
  end
  ns.RefreshMinimapPins()
end)
