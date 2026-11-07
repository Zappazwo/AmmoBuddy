import sys, os, json, gzip, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from litparse import lua_block, seq, sql_rows

D, SQL, OUT = sys.argv[1], sys.argv[2], sys.argv[3]

items = lua_block(D + '/data/Forever/foreverItemDB.lua', 'QuestieDB.itemData')
npcs = lua_block(D + '/data/Forever/foreverNpcDB.lua', 'QuestieDB.npcData')
quests = lua_block(D + '/data/Forever/foreverQuestDB.lua', 'QuestieDB.questData')
zpath = D + '/support/Forever/Zones/areaIdToUiMapId.lua'
zmap = lua_block(zpath, 'ZoneDB.private.areaIdToUiMapId')
zover = lua_block(zpath, 'ZoneDB.private.areaIdToUiMapIdOverride')

KIND = {(6, 2): 'arrow', (6, 3): 'bullet', (11, 2): 'quiver', (11, 3): 'pouch'}

# cmangos item_template (column order taken from CREATE TABLE)
cols, tmpl, state = [], {}, 0
with gzip.open(SQL, 'rt', encoding='utf-8', errors='replace') as f:
    for line in f:
        if state == 0:
            if line.startswith('CREATE TABLE `item_template`'):
                state = 1
            continue
        if state == 1:
            m = re.match(r'\s*`(\w+)`', line)
            if m:
                cols.append(m.group(1))
                continue
            if line.startswith(')'):
                state = 2
            continue
        if line.startswith('INSERT INTO `item_template`'):
            for r in sql_rows(line):
                rec = dict(zip(cols, r))
                if (rec['class'], rec['subclass']) in KIND:
                    tmpl[rec['entry']] = rec
print('cmangos rows', len(tmpl), 'cols', len(cols))

out = {'items': {}, 'npcs': {}, 'quests': {}}
for iid, raw in items.items():
    it = seq(raw)
    it += [None] * (15 - len(it))
    key = (it[11], it[12])
    if key not in KIND:
        continue
    t = tmpl.get(iid, {})
    rec = {'name': it[0], 'kind': KIND[key], 'ilvl': it[8], 'req': it[9],
           'vendors': seq(it[13]) or [], 'quests': seq(it[5]) or [],
           'npcDrops': len(seq(it[1]) or []), 'objectDrops': len(seq(it[2]) or []),
           'itemDrops': seq(it[3]) or [], 'dropNpcs': [],
           'quality': t.get('Quality'), 'dps': t.get('dmg_min1'), 'slots': t.get('ContainerSlots'),
           'stack': t.get('stackable'), 'buyPrice': t.get('BuyPrice'), 'buyCount': t.get('BuyCount'),
           'spell': t.get('spellid_1'), 'repFaction': t.get('RequiredReputationFaction'),
           'repRank': t.get('RequiredReputationRank'), 'skill': t.get('RequiredSkill'),
           'skillRank': t.get('RequiredSkillRank'), 'inCmangos': bool(t)}
    out['items'][iid] = rec
    for n in (seq(it[1]) or [])[:3]:
        if n in npcs:
            nd = seq(npcs[n]); nd += [None] * (15 - len(nd))
            rec['dropNpcs'].append({'id': n, 'name': nd[0], 'zone': zover.get(nd[8], zmap.get(nd[8])), 'minLevel': nd[3], 'maxLevel': nd[4]})
    for n in rec['vendors']:
        if n in out['npcs'] or n not in npcs:
            continue
        npc = seq(npcs[n])
        npc += [None] * (15 - len(npc))
        spawns = []
        for area, coords in (npc[6] or {}).items():
            ui = zover.get(area, zmap.get(area))
            for c in seq(coords):
                c = seq(c)
                spawns.append([area, ui, c[0], c[1]])
        out['npcs'][n] = {'name': npc[0], 'title': npc[13], 'faction': npc[12], 'spawns': spawns}
    for q in rec['quests']:
        if q not in quests:
            continue
        qd = seq(quests[q])
        qd += [None] * (28 - len(qd))
        out['quests'][q] = {'name': qd[0], 'req': qd[3], 'level': qd[4], 'races': qd[5],
                            'classes': qd[6], 'zone': qd[16], 'starters': qd[1]}

json.dump(out, open(OUT, 'w'), indent=1, sort_keys=True, default=str)
print(len(out['items']), 'items', len(out['npcs']), 'vendors', len(out['quests']), 'quests')
