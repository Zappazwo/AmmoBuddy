import sys, re
from lupa import LuaRuntime

ADDON = sys.argv[1]
HARNESS = sys.argv[2]  # optional 3rd argument: client locale, e.g. deDE
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().LOCALE = sys.argv[3] if len(sys.argv) > 3 else 'enUS'
out = lua.execute(open(HARNESS).read())
lua.execute("""
C_Map.GetWorldPosFromMapPos = function(map, pos)
  return 0, CreateVector2D((1 - pos.y) * 1000 + map * 10000, (1 - pos.x) * 1000)
end
""")
ns = lua.eval('{}')
files = [l.strip() for l in open(ADDON + '/AmmoBuddy.toc') if l.strip() and not l.startswith('#')]
loader = lua.eval('function(src, name, ns) local f = assert(load(src, "@" .. name)); f("AmmoBuddy", ns) end')
for f in files:
    loader(open(ADDON + '/' + f).read(), f, ns)

def run(code):
    return lua.eval('function(ns) ' + code + ' end')(ns)

def show(title):
    print('==', title)
    for i in range(1, len(out) + 1):
        print('  ', out[i])
    for i in range(len(out), 0, -1):
        out[i] = None

# Fire ADDON_LOADED + PLAYER_ENTERING_WORLD on the core frame
run('local f = AmmoBuddyFrame; f.scripts.OnEvent(f, "ADDON_LOADED", "AmmoBuddy"); f.scripts.OnEvent(f, "PLAYER_ENTERING_WORLD")')
show('login (700 Jagged Arrows, warn 200)')

# 1) Chat reminders: 700 -> 601 -> 600 -> 599 -> 401 -> 400 -> 201 -> 200
for c in [601, 600, 599, 401, 400, 201, 200, 150, 800, 600]:
    run('PLAYER.ammoCount = %d; local f = AmmoBuddyFrame; f.scripts.OnEvent(f, "BAG_UPDATE")' % c)
    sys.stdout.write('count %d -> ' % c)
    msgs = [out[i] for i in range(1, len(out) + 1)]
    print(msgs)
    for i in range(len(out), 0, -1): out[i] = None

# 2) Database helpers
print('== best vendor items at level 45 (Alliance)')
print('  arrow:', run('return ns.Data.items[ns.BestVendorItem("arrow")].name'))
print('  bullet:', run('return ns.Data.items[ns.BestVendorItem("bullet")].name'))
print('  quiver:', run('return ns.Data.items[ns.BestVendorItem("quiver")].name'))
print('  pouch:', run('local id = ns.BestVendorItem("pouch"); return id and ns.Data.items[id].name'))
print('== source summaries')
for iid in [2512, 11285, 3464, 18042, 19316, 12654, 8069, 18714, 2662]:
    print('  %d:' % iid, re.sub(r'\|c\w{8}|\|r', '', run('return ns.SourceSummary(%d)' % iid)))
print('== tooltip lines for Jagged Arrow')
run('GameTooltip.lines = {}; ns.AddSourceLines(GameTooltip, 11285)')
for l in list(lua.eval('GameTooltip.lines').values())[:8]:
    print('  ', l)
print('== nearest Rough Arrow vendor from Elwynn (43.96, 65.92):', run('local v = ns.VendorsForItem(2512)[1]; return ns.Data.vendors[v.id].name .. " dist " .. v.dist'))
print('== horde visible vendors for Rough Arrow:', run('return #ns.VendorsForItem(2512)'), end=' ')
run('PLAYER.faction = "Horde"')
lua.execute('-- reset cached faction')
print('(alliance)')

# 3) Auto-buy
def autobuy(desc, setup):
    run('BOUGHT = {}; BAG_ITEMS = {}; ' + setup + '; ns.AutoBuy()')
    b = lua.eval('BOUGHT')
    total = {}
    for i in range(1, len(b) + 1):
        total[b[i].id] = total.get(b[i].id, 0) + b[i].n
    msgs = [re.sub(r'\|c\w{8}|\|r', '', out[i]) for i in range(1, len(out) + 1)]
    for i in range(len(out), 0, -1): out[i] = None
    print('  %-55s bought=%s %s' % (desc, total, msgs))

print('== auto-buy (level 45, merchant: Rough, Sharp, Razor, Jagged arrows + Accurate Slugs)')
run('MERCHANT = { {id=2512, price=10}, {id=2515, price=50}, {id=3030, price=300}, {id=11285, price=1000}, {id=11284, price=1000} }')
autobuy('empty 16-slot quiver', 'PLAYER.ammo = 11285')
autobuy('quiver has 3 full + 1x150 Jagged', 'BAG_ITEMS[1] = { {id=11285,count=200},{id=11285,count=200},{id=11285,count=200},{id=11285,count=150} }')
autobuy('quiver half full of Razor Arrows (8 slots)', 'BAG_ITEMS[1] = {}; for s=1,8 do BAG_ITEMS[1][s] = {id=3030,count=200} end')
autobuy('not enough money (2000c)', 'PLAYER.money = 2000')
autobuy('better ammo equipped (Thorium Headed)', 'PLAYER.money = 1000000; PLAYER.ammo = 18042')
autobuy('auto-buy disabled', 'PLAYER.ammo = 11285; ns.db.autoBuy = false')
autobuy('gun equipped -> bullets, no pouch: manual 8 slots, 1 free bag slot kept', 'ns.db.autoBuy = true; PLAYER.ranged = 1002; BAGS[1].family = 1')
autobuy('gun, no pouch, manual 8 slots, empty backpack', 'BAG_ITEMS[0] = {}')
autobuy('gun, ammo pouch equipped (family 2)', 'BAGS[1].family = 2')
autobuy('level 30 with bow (Jagged needs 40)', 'PLAYER.ranged = 1001; BAGS[1].family = 1; PLAYER.level = 30; PLAYER.ammo = 3030')
run('PLAYER.level = 45; PLAYER.ranged = 1001')
print('  detected quiver slots:', run('return ns.DetectAmmoBagSlots("arrow")'))

# 4) Minimap pins: player standing at Brog Hamfist (Elwynn 43.96, 65.92)
run('ns.db.minimapPins = true')
print('== Blizzard map, Elwynn (1429): provider pins', run('''WorldMapFrame.mapID = 1429; WorldMapFrame.shown = true; ns.RefreshWorldMapPins()
  local n, ok = #WorldMapFrame.activePins, true
  for _, p in ipairs(WorldMapFrame.activePins) do
    ok = ok and p.levelType == "PIN_FRAME_LEVEL_AREA_POI" and p.pos and p.vendorIcon and p.vendorIcon:IsShown()
  end
  return n .. " (expected " .. #ns.vendorsByMap[1429] .. "), level/position/icon ok: " .. tostring(ok)'''))
print('   map pins turned off:', run('ns.SetMapPins(false); local n = #WorldMapFrame.activePins; ns.SetMapPins(true); return n .. " pins, back on: " .. #WorldMapFrame.activePins'))
print('   Durotar (1411, Horde-only vendors hidden for Alliance):', run('WorldMapFrame.mapID = 1411; ns.RefreshWorldMapPins(); return #WorldMapFrame.activePins'))

print('== OpenMap stitched: pins placed by world position, above its art (top 2100)')
run('''OpenMapAPI = { version = 4, IsStitched = function() return true end, ArtTopLevel = function() return 2100 end,
  CanvasFromWorldPos = function(c, x, y) return (x % 1000) / 1000, (y % 1000) / 1000 end }''')
run('WorldMapFrame.mapID = 1429; WorldMapFrame.shown = true; ns.RefreshWorldMapPins()')
print('  provider pins while stitched (should be 0, no duplicates):', run('return #WorldMapFrame.activePins'))
print('  pins shown above the art:', run('''local n, low = 0, 0
  for _, f in ipairs(ALL_FRAMES) do
    if f.kind == "Button" and rawget(f, "vendorID") and f:IsShown() and f.point and f.point[2] == WorldMapFrame then
      if f:GetFrameLevel() > 2100 then n = n + 1 else low = low + 1 end
    end
  end
  return n .. " (below the art: " .. low .. ")"'''))
run('OpenMapAPI = nil; ns.RefreshWorldMapPins()')
print('  OpenMap off again -> provider pins:', run('return #WorldMapFrame.activePins'), ' canvas pins shown:', run('''local n = 0
  for _, f in ipairs(ALL_FRAMES) do if f.kind == "Button" and rawget(f, "vendorID") and f:IsShown() and f.point and f.point[2] == WorldMapFrame then n = n + 1 end end
  return n'''))

# 5) Window: open and switch through the tabs
run('ns.ToggleWindow("ammo"); ns.ToggleWindow("bags"); ns.ToggleWindow("settings"); ns.RefreshWindow()')
print('== window opened, all tabs built OK')
show('remaining output')
