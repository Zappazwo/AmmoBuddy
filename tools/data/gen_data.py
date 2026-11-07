"""Generate AmmoBuddy/Data.lua from raw.json (output of extract.py)."""
import sys, json

raw = json.load(open(sys.argv[1]))
OUT = sys.argv[2]

# Crafted items (profession only; no skill levels to avoid guessing).
CRAFT = {
    8067: 'Engineering', 8068: 'Engineering', 8069: 'Engineering', 10512: 'Engineering',
    10513: 'Engineering', 15997: 'Engineering',
    7278: 'Leatherworking', 7279: 'Leatherworking', 7371: 'Leatherworking', 7372: 'Leatherworking',
    8217: 'Leatherworking', 8218: 'Leatherworking',
}
# Quiver / ammo pouch "haste" equip spells -> ranged attack speed bonus in percent.
HASTE = {14824: 10, 14825: 11, 14826: 12, 14827: 13, 14828: 14, 14829: 15}
REP_RANK = {4: 'Friendly', 5: 'Honored', 6: 'Revered', 7: 'Exalted'}
ALLIANCE, HORDE = 1 | 4 | 8 | 64, 2 | 16 | 32 | 128


def lua_str(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


def num(v):
    if isinstance(v, float) and v.is_integer():
        return str(int(v))
    return str(v)


def race_faction(mask):
    mask = (mask or 0) & 0xFF
    if mask == 0 or (mask & ALLIANCE and mask & HORDE):
        return None
    return 'A' if mask & ALLIANCE else 'H'


lines = [
    '-- AmmoBuddy: item and vendor database. AUTO-GENERATED, do not edit by hand.',
    '-- Sources: QuestieDB WoW Forever data (vendors, coordinates, quests, drops,',
    '-- https://github.com/Questie/QuestieDB) and cmangos classic-db (item stats,',
    '-- https://github.com/cmangos/classic-db).',
    'local ADDON, ns = ...',
    'if not ns.enabled then return end',
    '',
    'ns.Data = {}',
    '',
    '-- kind: arrow | bullet | quiver | pouch',
    '-- sources: vendor (see ns.Data.vendors), quest, drop, craft, rep',
    'ns.Data.items = {',
]

items = raw['items']
order = {'arrow': 0, 'bullet': 1, 'quiver': 2, 'pouch': 3}
vendor_items = {}
for iid, it in sorted(items.items(), key=lambda x: (order[x[1]['kind']], x[1]['ilvl'], x[1]['req'], int(x[0]))):
    iid = int(iid)
    f = ['kind = "%s"' % it['kind'], 'name = %s' % lua_str(it['name']),
         'quality = %d' % (it['quality'] or 1), 'ilvl = %d' % it['ilvl'], 'req = %d' % it['req']]
    if it['kind'] in ('arrow', 'bullet'):
        f.append('dps = %s' % num(it['dps']))
    else:
        f.append('slots = %d' % it['slots'])
        if it['spell'] in HASTE:
            f.append('haste = %d' % HASTE[it['spell']])
    src = []
    if it['vendors']:
        src.append('{ type = "vendor" }')
        for v in it['vendors']:
            vendor_items.setdefault(str(v), []).append(iid)
    if it['repFaction']:
        src.append('{ type = "rep", rank = "%s" }' % REP_RANK.get(it['repRank'], 'Friendly'))
    for q in it['quests']:
        qd = raw['quests'].get(str(q))
        if not qd:
            continue
        parts = ['type = "quest"', 'id = %d' % q, 'name = %s' % lua_str(qd['name']),
                 'level = %d' % qd['level'], 'req = %d' % qd['req']]
        fac = race_faction(qd['races'])
        if fac:
            parts.append('faction = "%s"' % fac)
        if qd['classes']:
            parts.append('hunterOnly = true')
        src.append('{ ' + ', '.join(parts) + ' }')
    for d in it['dropNpcs']:
        if d['id'] in it['vendors']:
            continue  # vendor wrongly listed as a drop source
        parts = ['type = "drop"', 'npc = %s' % lua_str(d['name'])]
        if d['zone']:
            parts.append('map = %d' % d['zone'])
        lvl = d['minLevel'] if d['minLevel'] == d['maxLevel'] else '%s-%s' % (d['minLevel'], d['maxLevel'])
        parts.append('level = "%s"' % lvl)
        src.append('{ ' + ', '.join(parts) + ' }')
    if iid in CRAFT:
        src.append('{ type = "craft", profession = "%s" }' % CRAFT[iid])
    f.append('sources = { ' + ', '.join(src) + ' }')
    lines.append('  [%d] = { %s },' % (iid, ', '.join(f)))
lines.append('}')
lines.append('')
lines.append('-- Vendors that sell ammo, quivers or ammo pouches.')
lines.append('-- spawns: { uiMapID, x, y } in map percent (WoW Forever coordinates).')
lines.append('ns.Data.vendors = {')
count = 0
for nid, npc in sorted(raw['npcs'].items(), key=lambda x: int(x[0])):
    spawns = [s for s in npc['spawns'] if s[1]]
    if not spawns:
        continue
    count += 1
    sp = ', '.join('{ %d, %s, %s }' % (s[1], num(s[2]), num(s[3])) for s in spawns)
    its = ', '.join(str(i) for i in sorted(vendor_items.get(nid, [])))
    parts = ['name = %s' % lua_str(npc['name'])]
    if npc['title']:
        parts.append('title = %s' % lua_str(npc['title']))
    parts.append('faction = "%s"' % (npc['faction'] or ''))
    parts.append('spawns = { %s }' % sp)
    parts.append('items = { %s }' % its)
    lines.append('  [%s] = { %s },' % (nid, ', '.join(parts)))
lines.append('}')
open(OUT, 'w').write('\n'.join(lines) + '\n')
print(len(items), 'items,', count, 'vendors written')
