-- Copyright The Total RP 3 Authors
-- SPDX-License-Identifier: Apache-2.0

TRP3_BACKDROP_COLOR_GOLD = TRP3_API.CreateColor(1, 0.675, 0.125);
TRP3_BACKDROP_COLOR_GREY = TRP3_API.CreateColor(0.6, 0.6, 0.6);
TRP3_BACKDROP_COLOR_CREAMY_BROWN = TRP3_API.CreateColor(0.48, 0.39, 0.32);

TRP3_BACKDROP_OVERLAY = {
	bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
	tile     = true,
	tileEdge = true,
	tileSize = 32,
	insets   = { left = 4, right = 4, top = 4, bottom = 4 },
};

TRP3_BACKDROP_DIALOG_TOOLTIP = {
	bgFile   = "Interface\\AddOns\\totalRP3\\Resources\\UI\\ui-frame-backdrop-fill",
	edgeFile = "Interface\\AddOns\\totalRP3\\Resources\\UI\\ui-frame-backdrop-edge",
	tile     = true,
	tileEdge = true,
	tileSize = 32,
	edgeSize = 8,
	insets   = { left = 4, right = 4, top = 4, bottom = 4 },
};

TRP3_BACKDROP_TOOLTIP_EDGE_16 = {
	edgeFile = "Interface\\AddOns\\totalRP3\\Resources\\UI\\ui-frame-backdrop-edge",
	tileEdge = true,
	edgeSize = 8,
	insets   = { left = 4, right = 4, top = 4, bottom = 4 },
};

TRP3_BACKDROP_COLLECTIONS_TOOLTIP = {
	bgFile   = "Interface\\Collections\\COLLECTIONSBACKGROUNDTILE",
	edgeFile = "Interface\\AddOns\\totalRP3\\Resources\\UI\\ui-frame-backdrop-edge",
	tile     = true,
	tileEdge = true,
	tileSize = 256,
	edgeSize = 8,
	insets   = { left = 4, right = 4, top = 4, bottom = 4 },
};

TRP3_BACKDROP_DIALOG_16_16 = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileEdge = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 5, right = 6, top = 6, bottom = 5 },
};

TRP3_BACKDROP_ACHIEVEMENT_TOOLTIP = {
	bgFile   = "Interface\\AchievementFrame\\UI-Achievement-StatsBackground",
	edgeFile = "Interface\\AddOns\\totalRP3\\Resources\\UI\\ui-frame-backdrop-edge",
	tile     = true,
	tileEdge = true,
	tileSize = 415,
	edgeSize = 8,
	insets   = { left = 4, right = 4, top = 4, bottom = 4 },
};
