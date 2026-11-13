-- Diablo Map
-- A see-through map overlay drawn in the middle of the screen and centered on
-- the player, in the style of the Diablo automap. It does nothing else.

local ADDON_NAME = ...

BINDING_HEADER_DIABLOMAP = "Diablo Map"
BINDING_NAME_DIABLOMAP_TOGGLE = "Toggle map overlay"
BINDING_NAME_DIABLOMAP_ZOOMIN = "Zoom in"
BINDING_NAME_DIABLOMAP_ZOOMOUT = "Zoom out"

local DEFAULTS = {
	shown = false,   -- overlay visible
	alpha = 0.6,     -- overall opacity (0-1)
	zoom = 1.5,      -- map scale
	size = 0.8,      -- portion of the screen the overlay may cover (0.2-1)
	fog = 0.35,      -- brightness of unexplored areas (0 hides them entirely)
	style = "color", -- color | gray | gold
	group = true,    -- show party/raid members
}

local STYLES = {
	color = { desaturate = false, r = 1, g = 1, b = 1 },
	gray  = { desaturate = true,  r = 0.9, g = 0.9, b = 0.9 },
	gold  = { desaturate = true,  r = 1, g = 0.82, b = 0.5 },
}

local MIN_ZOOM, MAX_ZOOM = 0.4, 8
local MAP_POLL_INTERVAL = 0.5
local GROUP_INTERVAL = 0.1

local db
local currentMapID
local layer -- art layer info of the current map
local baseTiles, exploredTiles, groupDots = {}, {}, {}
local hasExploration = false

local C_Map = C_Map
local C_MapExplorationInfo = C_MapExplorationInfo
local issecretvalue = issecretvalue

local function usable(v)
	return type(v) == "number" and not (issecretvalue and issecretvalue(v))
end

------------------------------------------------------------------------------
-- Frames
------------------------------------------------------------------------------

-- Root: click-through, behind the rest of the UI, clips the map to its bounds.
local root = CreateFrame("Frame", "DiabloMapFrame", UIParent)
root:SetFrameStrata("BACKGROUND")
root:SetPoint("CENTER")
root:EnableMouse(false)
root:SetClipsChildren(true)
root:Hide()

-- Canvas: holds the map art at its native pixel size, scaled by zoom.
local canvas = CreateFrame("Frame", nil, root)
canvas:EnableMouse(false)

-- Player arrow, always in the middle of the overlay.
local arrow = root:CreateTexture(nil, "OVERLAY", nil, 7)
arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
arrow:SetSize(32, 32)
arrow:SetPoint("CENTER")

------------------------------------------------------------------------------
-- Drawing
------------------------------------------------------------------------------

local function acquire(pool, index, drawLayer, sublevel)
	local tex = pool[index]
	if not tex then
		tex = canvas:CreateTexture(nil, drawLayer, nil, sublevel)
		pool[index] = tex
	end
	tex:ClearAllPoints()
	tex:SetTexCoord(0, 1, 0, 1)
	tex:Show()
	return tex
end

local function releaseFrom(pool, first)
	for i = first, #pool do
		pool[i]:Hide()
	end
end

local function applyStyle()
	local style = STYLES[db.style] or STYLES.color
	local fog = (hasExploration and db.fog) or 1
	for _, tex in ipairs(baseTiles) do
		tex:SetDesaturated(style.desaturate)
		tex:SetVertexColor(style.r * fog, style.g * fog, style.b * fog)
		tex:SetAlpha(fog > 0 and 1 or 0)
	end
	for _, tex in ipairs(exploredTiles) do
		tex:SetDesaturated(style.desaturate)
		tex:SetVertexColor(style.r, style.g, style.b)
	end
end

local function drawBase(mapID)
	local textures = C_Map.GetMapArtLayerTextures(mapID, 1)
	local cols = math.ceil(layer.layerWidth / layer.tileWidth)
	local rows = math.ceil(layer.layerHeight / layer.tileHeight)
	local n = 0
	if textures then
		for row = 1, rows do
			for col = 1, cols do
				local file = textures[(row - 1) * cols + col]
				if file then
					n = n + 1
					local tex = acquire(baseTiles, n, "BACKGROUND")
					tex:SetTexture(file, nil, nil, "TRILINEAR")
					tex:SetSize(layer.tileWidth, layer.tileHeight)
					tex:SetPoint("TOPLEFT", (col - 1) * layer.tileWidth, -(row - 1) * layer.tileHeight)
				end
			end
		end
	end
	releaseFrom(baseTiles, n + 1)
end

-- Explored-area overlays, laid out the same way Blizzard's world map does it.
local function drawExplored(mapID)
	local n = 0
	local list = C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures(mapID)
	hasExploration = list ~= nil and #list > 0
	if list then
		local tileW, tileH = layer.tileWidth, layer.tileHeight
		for _, info in ipairs(list) do
			if not info.isShownByMouseOver then
				local wide = math.ceil(info.textureWidth / tileW)
				local tall = math.ceil(info.textureHeight / tileH)
				for j = 1, tall do
					local pixelH, fileH = tileH, tileH
					if j == tall then
						pixelH = info.textureHeight % tileH
						if pixelH == 0 then pixelH = tileH end
						fileH = 16
						while fileH < pixelH do fileH = fileH * 2 end
					end
					for k = 1, wide do
						local pixelW, fileW = tileW, tileW
						if k == wide then
							pixelW = info.textureWidth % tileW
							if pixelW == 0 then pixelW = tileW end
							fileW = 16
							while fileW < pixelW do fileW = fileW * 2 end
						end
						local file = info.fileDataIDs[(j - 1) * wide + k]
						if file then
							n = n + 1
							local tex = acquire(exploredTiles, n, "ARTWORK")
							tex:SetTexture(file, nil, nil, "TRILINEAR")
							tex:SetSize(pixelW, pixelH)
							tex:SetTexCoord(0, pixelW / fileW, 0, pixelH / fileH)
							tex:SetPoint("TOPLEFT", info.offsetX + tileW * (k - 1), -(info.offsetY + tileH * (j - 1)))
						end
					end
				end
			end
		end
	end
	releaseFrom(exploredTiles, n + 1)
end

local function loadMap(mapID)
	currentMapID = mapID
	layer = nil
	if mapID then
		local layers = C_Map.GetMapArtLayers(mapID)
		layer = layers and layers[1]
	end
	if not layer then
		releaseFrom(baseTiles, 1)
		releaseFrom(exploredTiles, 1)
		return
	end
	canvas:SetSize(layer.layerWidth, layer.layerHeight)
	drawBase(mapID)
	drawExplored(mapID)
	applyStyle()
end

------------------------------------------------------------------------------
-- Layout and per-frame updates
------------------------------------------------------------------------------

local function applyLayout()
	local w, h = UIParent:GetSize()
	root:SetSize(w * db.size, h * db.size)
	root:SetAlpha(db.alpha)
	canvas:SetScale(db.zoom)
end

local function updateGroup()
	local n = 0
	if db.group and layer and IsInGroup() then
		local raid = IsInRaid()
		local count = raid and GetNumGroupMembers() or GetNumSubgroupMembers()
		local dotSize = 10 / db.zoom
		for i = 1, count do
			local unit = (raid and "raid" or "party") .. i
			if not UnitIsUnit(unit, "player") and UnitIsConnected(unit) then
				local pos = C_Map.GetPlayerMapPosition(currentMapID, unit)
				if pos then
					local x, y = pos:GetXY()
					if usable(x) and usable(y) then
						n = n + 1
						local dot = groupDots[n]
						if not dot then
							dot = canvas:CreateTexture(nil, "OVERLAY")
							dot:SetTexture("Interface\\Buttons\\WHITE8X8")
							groupDots[n] = dot
						end
						local _, class = UnitClass(unit)
						local c = class and RAID_CLASS_COLORS[class]
						dot:SetVertexColor(c and c.r or 0.3, c and c.g or 0.6, c and c.b or 1)
						dot:SetSize(dotSize, dotSize)
						dot:ClearAllPoints()
						dot:SetPoint("CENTER", canvas, "TOPLEFT", x * layer.layerWidth, -y * layer.layerHeight)
						dot:Show()
					end
				end
			end
		end
	end
	for i = n + 1, #groupDots do
		groupDots[i]:Hide()
	end
end

local function updatePlayer()
	canvas:ClearAllPoints()
	local x, y
	local pos = C_Map.GetPlayerMapPosition(currentMapID, "player")
	if pos then
		x, y = pos:GetXY()
	end
	if usable(x) and usable(y) then
		canvas:SetPoint("TOPLEFT", root, "CENTER", -x * layer.layerWidth, y * layer.layerHeight)
		local facing = GetPlayerFacing()
		if usable(facing) then
			arrow:SetRotation(facing)
			arrow:Show()
		else
			arrow:Hide()
		end
	else
		-- Position unavailable (e.g. inside instances): just center the map.
		canvas:SetPoint("CENTER", root, "CENTER")
		arrow:Hide()
	end
end

local function worldMapOpen()
	return WorldMapFrame and WorldMapFrame:IsShown()
end

local driver = CreateFrame("Frame")
local mapPollElapsed, groupElapsed = MAP_POLL_INTERVAL, GROUP_INTERVAL

driver:SetScript("OnUpdate", function(_, elapsed)
	if not db or not db.shown then
		if root:IsShown() then root:Hide() end
		return
	end

	mapPollElapsed = mapPollElapsed + elapsed
	if mapPollElapsed >= MAP_POLL_INTERVAL then
		mapPollElapsed = 0
		local mapID = C_Map.GetBestMapForUnit("player")
		if mapID ~= currentMapID then
			loadMap(mapID)
		end
	end

	if not layer or worldMapOpen() then
		if root:IsShown() then root:Hide() end
		return
	end
	if not root:IsShown() then root:Show() end

	updatePlayer()

	groupElapsed = groupElapsed + elapsed
	if groupElapsed >= GROUP_INTERVAL then
		groupElapsed = 0
		updateGroup()
	end
end)

local function refresh()
	if not db then return end
	applyLayout()
	loadMap(C_Map.GetBestMapForUnit("player"))
	mapPollElapsed, groupElapsed = 0, GROUP_INTERVAL
end

------------------------------------------------------------------------------
-- Default key: Alt-M, set once per character if the key is free and the
-- toggle has no key yet. If you later unbind or change it, it stays that way.
------------------------------------------------------------------------------

local DEFAULT_KEY = "ALT-M"

local function setDefaultKey()
	if db.defaultKeySet or InCombatLockdown() then return end
	db.defaultKeySet = true
	if GetBindingKey("DIABLOMAP_TOGGLE") then return end
	local action = GetBindingAction(DEFAULT_KEY)
	if action == nil or action == "" then
		if SetBinding(DEFAULT_KEY, "DIABLOMAP_TOGGLE") then
			SaveBindings(GetCurrentBindingSet())
		end
	else
		print("|cffc8a050Diablo Map:|r Alt-M is already used for something else. Bind the overlay under Key Bindings > AddOns > Diablo Map.")
	end
end

------------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------------

driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("ZONE_CHANGED")
driver:RegisterEvent("ZONE_CHANGED_INDOORS")
driver:RegisterEvent("ZONE_CHANGED_NEW_AREA")
driver:RegisterEvent("MAP_EXPLORATION_UPDATED")
driver:RegisterEvent("UI_SCALE_CHANGED")
driver:RegisterEvent("DISPLAY_SIZE_CHANGED")

driver:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 ~= ADDON_NAME then return end
		DiabloMapDB = DiabloMapDB or {}
		db = DiabloMapDB
		for k, v in pairs(DEFAULTS) do
			if db[k] == nil then db[k] = v end
		end
		if not STYLES[db.style] then db.style = DEFAULTS.style end
		driver:UnregisterEvent("ADDON_LOADED")
	elseif event == "PLAYER_LOGIN" then
		setDefaultKey()
	elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
		if db then applyLayout() end
	else
		refresh()
	end
end)

------------------------------------------------------------------------------
-- Public functions (used by key bindings) and slash commands
------------------------------------------------------------------------------

function DiabloMap_Toggle()
	if not db then return end
	db.shown = not db.shown
	if db.shown then refresh() end
end

function DiabloMap_Zoom(direction)
	if not db then return end
	db.zoom = math.min(MAX_ZOOM, math.max(MIN_ZOOM, db.zoom * (1.25 ^ direction)))
	applyLayout()
end

local function say(msg)
	print("|cffc8a050Diablo Map:|r " .. msg)
end

local function clamp(v, lo, hi)
	return math.min(hi, math.max(lo, v))
end

local HELP = {
	"/dmap - toggle the overlay",
	"/dmap alpha <0-1> - opacity (now %s)",
	"/dmap zoom <0.4-8> - map scale (now %s)",
	"/dmap size <0.2-1> - screen area covered (now %s)",
	"/dmap fog <0-1> - brightness of unexplored areas, 0 hides them (now %s)",
	"/dmap style color|gray|gold - map colors (now %s)",
	"/dmap group - show/hide party and raid members (now %s)",
	"/dmap reset - restore defaults",
}

SLASH_DIABLOMAP1 = "/dmap"
SLASH_DIABLOMAP2 = "/diablomap"
SlashCmdList.DIABLOMAP = function(input)
	if not db then return end
	local cmd, arg = (input or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
	local num = tonumber(arg)

	if cmd == "" or cmd == "toggle" then
		DiabloMap_Toggle()
	elseif cmd == "alpha" and num then
		db.alpha = clamp(num, 0.05, 1)
		applyLayout()
	elseif cmd == "zoom" and num then
		db.zoom = clamp(num, MIN_ZOOM, MAX_ZOOM)
		applyLayout()
	elseif cmd == "size" and num then
		db.size = clamp(num, 0.2, 1)
		applyLayout()
	elseif cmd == "fog" and num then
		db.fog = clamp(num, 0, 1)
		applyStyle()
	elseif cmd == "style" and STYLES[arg] then
		db.style = arg
		applyStyle()
	elseif cmd == "group" then
		db.group = not db.group
	elseif cmd == "reset" then
		local shown, keySet = db.shown, db.defaultKeySet
		wipe(db)
		for k, v in pairs(DEFAULTS) do db[k] = v end
		db.shown, db.defaultKeySet = shown, keySet
		refresh()
		say("settings reset.")
	else
		say("commands:")
		local values = { nil, db.alpha, db.zoom, db.size, db.fog, db.style, db.group and "on" or "off" }
		for i, line in ipairs(HELP) do
			print("  " .. (values[i] ~= nil and line:format(tostring(values[i])) or line))
		end
	end
end
