-- AmmoBuddy: translations. Keys are the English texts; a missing translation falls back to English.
-- The language follows the game client (GetLocale()).
local ADDON, ns = ...

local L = setmetatable({}, { __index = function(_, key) return key end })
ns.L = L

local translations = {}

translations.deDE = {
  -- Ammo counter and warnings
  ["Right-click to open AmmoBuddy"] = "Rechtsklick: AmmoBuddy öffnen",
  ["Out of ammo!"] = "Keine Munition mehr!",
  ["Low ammo: %d"] = "Munition knapp: %d",
  ["Warning! Only %d Arrows left"] = "Achtung! Nur noch %d Pfeile übrig",
  ["Warning! Only %d Bullets left"] = "Achtung! Nur noch %d Kugeln übrig",
  -- Slash commands
  ["Ammo counter locked."] = "Munitionszähler gesperrt.",
  ["Ammo counter unlocked - left-click and drag to move it."] = "Munitionszähler entsperrt – mit gedrückter linker Maustaste verschieben.",
  ["Raid warning threshold set to %d."] = "Schwelle für die Schlachtzugswarnung auf %d gesetzt.",
  ["Position reset."] = "Position zurückgesetzt.",
  ["open the main window"] = "Hauptfenster öffnen",
  ["lock or unlock the ammo counter"] = "Munitionszähler sperren oder entsperren",
  ["raid-warning threshold (current: %d)"] = "Schwelle für die Schlachtzugswarnung (aktuell: %d)",
  ["show or hide the ammo counter"] = "Munitionszähler ein- oder ausblenden",
  ["toggle the minimap button"] = "Minikarten-Button ein- oder ausblenden",
  ["reset the ammo counter position"] = "Position des Munitionszählers zurücksetzen",
  -- Minimap button
  ["Click: open AmmoBuddy"] = "Klick: AmmoBuddy öffnen",
  ["Drag: move this button"] = "Ziehen: Button verschieben",
  -- How to get it
  ["How to get it"] = "So bekommst du es",
  ["Vendor: %s"] = "Händler: %s",
  ["+%d more"] = "+%d weitere",
  ["Vendor (other faction only)"] = "Händler (nur andere Fraktion)",
  ["Sold by 1 vendor:"] = "Verkauft von 1 Händler:",
  ["Sold by %d vendors, nearest first:"] = "Verkauft von %d Händlern, nächster zuerst:",
  ["... and %d more"] = "… und %d weitere",
  ["Quest: %s (level %d)"] = "Quest: %s (Stufe %d)",
  ["Alliance only"] = "nur Allianz",
  ["Horde only"] = "nur Horde",
  ["Hunter quest"] = "Jägerquest",
  ["Drop: %s (level %s)"] = "Beute: %s (Stufe %s)",
  ["Crafted: %s"] = "Hergestellt: %s",
  ["Engineering"] = "Ingenieurskunst",
  ["Leatherworking"] = "Lederverarbeitung",
  ["Requires %s reputation (%s)"] = "Benötigt Ruf %s (%s)",
  ["Unknown source"] = "Unbekannte Quelle",
  -- Map pins
  ["Level %d"] = "Stufe %d",
  -- Auto-buy
  ["Bought %d %s for %s."] = "%d %s für %s gekauft.",
  -- Main window
  ["Ammo & quiver helper for Hunters"] = "Munitions- und Köcherhelfer für Jäger",
  ["Arrows/Bullets"] = "Pfeile/Kugeln",
  ["Quivers/Pouches"] = "Köcher/Beutel",
  ["Settings"] = "Einstellungen",
  ["Arrows"] = "Pfeile",
  ["Bullets"] = "Kugeln",
  ["Quivers"] = "Köcher",
  ["Ammo Pouches"] = "Munitionsbeutel",
  ["All"] = "Alle",
  ["Best for you"] = "Beste für dich",
  ["Any level"] = "Jede Stufe",
  ["%s DPS"] = "%s DPS",
  ["%d slots"] = "%d Plätze",
  ["+%d%% attack speed"] = "+%d%% Distanzangriffstempo",
  ["Nothing found."] = "Nichts gefunden.",
  ["Click: show the nearest vendor on the map"] = "Klick: nächsten Händler auf der Karte zeigen",
  ["Shift-click: link the item in chat"] = "Shift-Klick: Gegenstand im Chat verlinken",
  ["Can't open the map right now."] = "Die Karte kann gerade nicht geöffnet werden.",
  ["Show on minimap"] = "Auf Minikarte zeigen",
  ["Hide from minimap"] = "Von Minikarte entfernen",
  -- Settings
  ["Ammo counter"] = "Munitionszähler",
  ["Show ammo counter"] = "Munitionszähler anzeigen",
  ["Lock ammo counter"] = "Munitionszähler sperren",
  ["Reset counter position"] = "Position zurücksetzen",
  ["Warnings"] = "Warnungen",
  ["Raid warning at"] = "Schlachtzugswarnung bei",
  ["You also get a chat reminder (only you can see it) at %d and %d."] =
    "Zusätzlich bekommst du bei %d und %d eine Chat-Erinnerung (nur für dich sichtbar).",
  ["Map"] = "Karte",
  ["Show minimap button"] = "Minikarten-Button anzeigen",
  ["Show vendors on the world map"] = "Händler auf der Weltkarte zeigen",
  ["Show vendors on the minimap"] = "Händler auf der Minikarte zeigen",
  ["Auto-buy"] = "Automatisch kaufen",
  ["Buy the best ammo at vendors"] = "Beste Munition beim Händler kaufen",
  ["Detect quiver / pouch slots"] = "Köcher-/Beutelplätze erkennen",
  ["Quiver / pouch slots"] = "Köcher-/Beutelplätze",
  ["Detected: %d"] = "Erkannt: %d",
  ["None equipped"] = "Keiner angelegt",
  ["AUTO_BUY_HELP"] =
    "Füllt nur deinen Köcher oder Munitionsbeutel und lässt immer zwei normale Taschenplätze frei. "
    .. "Die Platzanzahl gilt, wenn kein passender Köcher oder Beutel angelegt ist. "
    .. "Halte Shift beim Ansprechen eines Händlers gedrückt, um den automatischen Kauf zu überspringen.",
}

translations.esES = {
  -- Ammo counter and warnings
  ["Right-click to open AmmoBuddy"] = "Clic derecho: abrir AmmoBuddy",
  ["Out of ammo!"] = "¡Sin munición!",
  ["Low ammo: %d"] = "Poca munición: %d",
  ["Warning! Only %d Arrows left"] = "¡Atención! Solo quedan %d flechas",
  ["Warning! Only %d Bullets left"] = "¡Atención! Solo quedan %d balas",
  -- Slash commands
  ["Ammo counter locked."] = "Contador de munición bloqueado.",
  ["Ammo counter unlocked - left-click and drag to move it."] = "Contador de munición desbloqueado: arrástralo con el clic izquierdo para moverlo.",
  ["Raid warning threshold set to %d."] = "Umbral del aviso de banda fijado en %d.",
  ["Position reset."] = "Posición restablecida.",
  ["open the main window"] = "abrir la ventana principal",
  ["lock or unlock the ammo counter"] = "bloquear o desbloquear el contador de munición",
  ["raid-warning threshold (current: %d)"] = "umbral del aviso de banda (actual: %d)",
  ["show or hide the ammo counter"] = "mostrar u ocultar el contador de munición",
  ["toggle the minimap button"] = "mostrar u ocultar el botón del minimapa",
  ["reset the ammo counter position"] = "restablecer la posición del contador de munición",
  -- Minimap button
  ["Click: open AmmoBuddy"] = "Clic: abrir AmmoBuddy",
  ["Drag: move this button"] = "Arrastrar: mover este botón",
  -- How to get it
  ["How to get it"] = "Cómo conseguirlo",
  ["Vendor: %s"] = "Vendedor: %s",
  ["+%d more"] = "+%d más",
  ["Vendor (other faction only)"] = "Vendedor (solo la otra facción)",
  ["Sold by 1 vendor:"] = "Lo vende 1 vendedor:",
  ["Sold by %d vendors, nearest first:"] = "Lo venden %d vendedores, el más cercano primero:",
  ["... and %d more"] = "... y %d más",
  ["Quest: %s (level %d)"] = "Misión: %s (nivel %d)",
  ["Alliance only"] = "solo Alianza",
  ["Horde only"] = "solo Horda",
  ["Hunter quest"] = "misión de cazador",
  ["Drop: %s (level %s)"] = "Botín: %s (nivel %s)",
  ["Crafted: %s"] = "Fabricado: %s",
  ["Engineering"] = "Ingeniería",
  ["Leatherworking"] = "Peletería",
  ["Requires %s reputation (%s)"] = "Requiere reputación %s (%s)",
  ["Unknown source"] = "Origen desconocido",
  -- Map pins
  ["Level %d"] = "Nivel %d",
  -- Auto-buy
  ["Bought %d %s for %s."] = "Comprado: %d %s por %s.",
  -- Main window
  ["Ammo & quiver helper for Hunters"] = "Ayudante de munición y carcajs para cazadores",
  ["Arrows/Bullets"] = "Flechas/Balas",
  ["Quivers/Pouches"] = "Carcajs/Bolsas",
  ["Settings"] = "Opciones",
  ["Arrows"] = "Flechas",
  ["Bullets"] = "Balas",
  ["Quivers"] = "Carcajs",
  ["Ammo Pouches"] = "Bolsas de munición",
  ["All"] = "Todo",
  ["Best for you"] = "La mejor para ti",
  ["Any level"] = "Cualquier nivel",
  ["%s DPS"] = "%s DPS",
  ["%d slots"] = "%d casillas",
  ["+%d%% attack speed"] = "+%d%% velocidad de ataque a distancia",
  ["Nothing found."] = "No se ha encontrado nada.",
  ["Click: show the nearest vendor on the map"] = "Clic: mostrar el vendedor más cercano en el mapa",
  ["Shift-click: link the item in chat"] = "Mayús-clic: enlazar el objeto en el chat",
  ["Can't open the map right now."] = "Ahora mismo no se puede abrir el mapa.",
  ["Show on minimap"] = "Mostrar en el minimapa",
  ["Hide from minimap"] = "Ocultar del minimapa",
  -- Settings
  ["Ammo counter"] = "Contador de munición",
  ["Show ammo counter"] = "Mostrar contador de munición",
  ["Lock ammo counter"] = "Bloquear contador de munición",
  ["Reset counter position"] = "Restablecer posición",
  ["Warnings"] = "Avisos",
  ["Raid warning at"] = "Aviso de banda con",
  ["You also get a chat reminder (only you can see it) at %d and %d."] =
    "También recibes un recordatorio en el chat (solo lo ves tú) con %d y %d.",
  ["Map"] = "Mapa",
  ["Show minimap button"] = "Mostrar botón del minimapa",
  ["Show vendors on the world map"] = "Mostrar vendedores en el mapa del mundo",
  ["Show vendors on the minimap"] = "Mostrar vendedores en el minimapa",
  ["Auto-buy"] = "Compra automática",
  ["Buy the best ammo at vendors"] = "Comprar la mejor munición",
  ["Detect quiver / pouch slots"] = "Detectar casillas del carcaj/bolsa",
  ["Quiver / pouch slots"] = "Casillas del carcaj/bolsa",
  ["Detected: %d"] = "Detectadas: %d",
  ["None equipped"] = "Nada equipado",
  ["AUTO_BUY_HELP"] =
    "Solo llena tu carcaj o bolsa de munición y siempre deja libres dos casillas de las bolsas normales. "
    .. "El número de casillas se usa cuando no llevas un carcaj o bolsa adecuado. "
    .. "Mantén pulsado Mayús al hablar con un vendedor para omitir la compra automática.",
}
translations.esMX = translations.esES

translations.frFR = {
  -- Ammo counter and warnings
  ["Right-click to open AmmoBuddy"] = "Clic droit : ouvrir AmmoBuddy",
  ["Out of ammo!"] = "Plus de munitions !",
  ["Low ammo: %d"] = "Munitions faibles : %d",
  ["Warning! Only %d Arrows left"] = "Attention ! Plus que %d flèches",
  ["Warning! Only %d Bullets left"] = "Attention ! Plus que %d balles",
  -- Slash commands
  ["Ammo counter locked."] = "Compteur de munitions verrouillé.",
  ["Ammo counter unlocked - left-click and drag to move it."] = "Compteur de munitions déverrouillé : faites-le glisser avec le clic gauche pour le déplacer.",
  ["Raid warning threshold set to %d."] = "Seuil de l'avertissement de raid réglé sur %d.",
  ["Position reset."] = "Position réinitialisée.",
  ["open the main window"] = "ouvrir la fenêtre principale",
  ["lock or unlock the ammo counter"] = "verrouiller ou déverrouiller le compteur de munitions",
  ["raid-warning threshold (current: %d)"] = "seuil de l'avertissement de raid (actuel : %d)",
  ["show or hide the ammo counter"] = "afficher ou masquer le compteur de munitions",
  ["toggle the minimap button"] = "afficher ou masquer le bouton de la minicarte",
  ["reset the ammo counter position"] = "réinitialiser la position du compteur de munitions",
  -- Minimap button
  ["Click: open AmmoBuddy"] = "Clic : ouvrir AmmoBuddy",
  ["Drag: move this button"] = "Glisser : déplacer ce bouton",
  -- How to get it
  ["How to get it"] = "Comment l'obtenir",
  ["Vendor: %s"] = "Marchand : %s",
  ["+%d more"] = "+%d de plus",
  ["Vendor (other faction only)"] = "Marchand (autre faction uniquement)",
  ["Sold by 1 vendor:"] = "Vendu par 1 marchand :",
  ["Sold by %d vendors, nearest first:"] = "Vendu par %d marchands, le plus proche d'abord :",
  ["... and %d more"] = "… et %d autres",
  ["Quest: %s (level %d)"] = "Quête : %s (niveau %d)",
  ["Alliance only"] = "Alliance uniquement",
  ["Horde only"] = "Horde uniquement",
  ["Hunter quest"] = "quête de chasseur",
  ["Drop: %s (level %s)"] = "Butin : %s (niveau %s)",
  ["Crafted: %s"] = "Fabriqué : %s",
  ["Engineering"] = "Ingénierie",
  ["Leatherworking"] = "Travail du cuir",
  ["Requires %s reputation (%s)"] = "Nécessite la réputation %s (%s)",
  ["Unknown source"] = "Source inconnue",
  -- Map pins
  ["Level %d"] = "Niveau %d",
  -- Auto-buy
  ["Bought %d %s for %s."] = "Acheté : %d %s pour %s.",
  -- Main window
  ["Ammo & quiver helper for Hunters"] = "Assistant munitions et carquois pour chasseurs",
  ["Arrows/Bullets"] = "Flèches/Balles",
  ["Quivers/Pouches"] = "Carquois/Gibernes",
  ["Settings"] = "Options",
  ["Arrows"] = "Flèches",
  ["Bullets"] = "Balles",
  ["Quivers"] = "Carquois",
  ["Ammo Pouches"] = "Gibernes",
  ["All"] = "Tout",
  ["Best for you"] = "La meilleure pour vous",
  ["Any level"] = "Tout niveau",
  ["%s DPS"] = "%s DPS",
  ["%d slots"] = "%d emplacements",
  ["+%d%% attack speed"] = "+%d%% vitesse d'attaque à distance",
  ["Nothing found."] = "Aucun résultat.",
  ["Click: show the nearest vendor on the map"] = "Clic : afficher le marchand le plus proche sur la carte",
  ["Shift-click: link the item in chat"] = "Maj-clic : lier l'objet dans la discussion",
  ["Can't open the map right now."] = "Impossible d'ouvrir la carte pour le moment.",
  ["Show on minimap"] = "Afficher sur la minicarte",
  ["Hide from minimap"] = "Masquer de la minicarte",
  -- Settings
  ["Ammo counter"] = "Compteur de munitions",
  ["Show ammo counter"] = "Afficher le compteur",
  ["Lock ammo counter"] = "Verrouiller le compteur",
  ["Reset counter position"] = "Réinitialiser la position",
  ["Warnings"] = "Avertissements",
  ["Raid warning at"] = "Avertissement de raid à",
  ["You also get a chat reminder (only you can see it) at %d and %d."] =
    "Vous recevez aussi un rappel dans la discussion (visible par vous seul) à %d et %d.",
  ["Map"] = "Carte",
  ["Show minimap button"] = "Afficher le bouton de la minicarte",
  ["Show vendors on the world map"] = "Afficher les marchands sur la carte du monde",
  ["Show vendors on the minimap"] = "Afficher les marchands sur la minicarte",
  ["Auto-buy"] = "Achat automatique",
  ["Buy the best ammo at vendors"] = "Acheter les meilleures munitions",
  ["Detect quiver / pouch slots"] = "Détecter les emplacements du carquois",
  ["Quiver / pouch slots"] = "Emplacements du carquois",
  ["Detected: %d"] = "Détectés : %d",
  ["None equipped"] = "Aucun équipé",
  ["AUTO_BUY_HELP"] =
    "Ne remplit que votre carquois ou votre giberne et laisse toujours deux emplacements libres dans vos sacs normaux. "
    .. "Le nombre d'emplacements sert quand aucun carquois ou giberne adapté n'est équipé. "
    .. "Maintenez Maj en parlant à un marchand pour ne pas acheter automatiquement.",
}

-- English text for keys that are not English sentences themselves.
local english = {
  ["AUTO_BUY_HELP"] =
    "Only fills your quiver or ammo pouch and always keeps two normal bag slots free. "
    .. "The slot number is used when no matching quiver or pouch is equipped. "
    .. "Hold Shift while talking to a vendor to skip auto-buy.",
}

for k, v in pairs(english) do L[k] = v end
for k, v in pairs(translations[GetLocale()] or {}) do L[k] = v end
