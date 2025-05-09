-- Copyright The Total RP 3 Authors
-- SPDX-License-Identifier: Apache-2.0

-- imports
local Globals, Utils, Events = TRP3_API.globals, TRP3_API.utils, TRP3_Addon.Events;
local loc = TRP3_API.loc;
local registerPage = TRP3_API.navigation.page.registerPage;
local companionIDToInfo = TRP3_API.utils.str.companionIDToInfo;

local setTooltipForSameFrame = TRP3_API.ui.tooltip.setTooltipForSameFrame;
local getCurrentContext = TRP3_API.navigation.page.getCurrentContext;
local setupIconButton = TRP3_API.ui.frame.setupIconButton;
local getCurrentPageID = TRP3_API.navigation.page.getCurrentPageID;
local hidePopups = TRP3_API.popup.hidePopups;
local displayConsult;
local tcopy, EMPTY = Utils.table.copy, Globals.empty;
local stEtN = Utils.str.emptyToNil;
local isUnitIDKnown, hasProfile, getUnitProfile = TRP3_API.register.isUnitIDKnown, TRP3_API.register.hasProfile, TRP3_API.register.getProfile;
local getCompleteName, openPageByUnitID = TRP3_API.register.getCompleteName;
local deleteProfile = TRP3_API.companions.register.deleteProfile;
local showConfirmPopup = TRP3_API.popup.showConfirmPopup;
local getCompanionProfileID = TRP3_API.companions.player.getCompanionProfileID;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Logic
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

TRP3_API.navigation.page.id.COMPANIONS_PAGE = "companions_page";
local COMPANIONS_PAGE_ID = TRP3_API.navigation.page.id.COMPANIONS_PAGE;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Peek management
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local setupGlanceButton = TRP3_API.register.setupGlanceButton;

local function refreshIfNeeded()
	if getCurrentPageID() == COMPANIONS_PAGE_ID then
		local context = getCurrentContext();
		assert(context, "No context for page player_main !");
		if not context.isEditMode then
			hidePopups();
			displayConsult(context);
		end
	end
end

local function applyPeekSlotProfile(slot, dataTab, ic, ac, ti, tx, swap)
	TRP3_AtFirstGlanceEditor:Hide();
	assert(slot, "No selection ...");
	if not dataTab.PE then
		dataTab.PE = {};
	end
	if not dataTab.PE[slot] then
		dataTab.PE[slot] = {};
	end
	local peekTab = dataTab.PE[slot];
	if swap then
		peekTab.AC = not peekTab.AC;
	else
		peekTab.IC = ic;
		peekTab.AC = ac;
		peekTab.TI = ti;
		peekTab.TX = tx;
	end
	-- version increment
	dataTab.PE.v = Utils.math.incrementNumber(dataTab.PE.v or 1, 2);
end

local function applyPeekSlot(slot, ic, ac, ti, tx, swap, companionFullID, profileID)
	if not profileID then
		local _, companionID = companionIDToInfo(companionFullID);
		profileID = getCompanionProfileID(companionID);
	end
	local dataTab = TRP3_API.companions.player.getCompanionProfileByID(profileID) or {};
	applyPeekSlotProfile(slot, dataTab, ic, ac, ti, tx, swap);
	TRP3_Addon:TriggerEvent(Events.REGISTER_DATA_UPDATED, companionFullID, profileID, "misc");
	refreshIfNeeded();
end
TRP3_API.companions.player.applyPeekSlot = applyPeekSlot;

local function swapGlanceSlot(from, to, companionFullID, profileID)
	TRP3_AtFirstGlanceEditor:Hide();
	if not profileID then
		local _, companionID = companionIDToInfo(companionFullID);
		profileID = getCompanionProfileID(companionID);
	end
	local dataTab = TRP3_API.companions.player.getCompanionProfileByID(profileID) or {};
	if not dataTab.PE then
		return;
	end
	local fromData = dataTab.PE[from];
	local toData = dataTab.PE[to];
	dataTab.PE[from] = toData;
	dataTab.PE[to] = fromData;
	-- version increment
	dataTab.PE.v = Utils.math.incrementNumber(dataTab.PE.v or 1, 2);
	TRP3_Addon:TriggerEvent(Events.REGISTER_DATA_UPDATED, nil, profileID, "misc");
	refreshIfNeeded();
end
TRP3_API.companions.player.swapGlanceSlot = swapGlanceSlot;

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Edit Mode
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local draftData;

local function saveInDraft(profileName)
	assert(type(draftData) == "table", "Error: Nil draftData or not a table.");
	draftData.NA = stEtN(strtrim(TRP3_CompanionsPageInformationEdit_NamePanel_NameField:GetText())) or profileName;
	draftData.TI = stEtN(strtrim(TRP3_CompanionsPageInformationEdit_NamePanel_TitleField:GetText()));
	draftData.TX = stEtN(strtrim(TRP3_CompanionsPageInformationEdit_About_TextScrollText:GetText()));
end

local function onNameColorSelected(red, green, blue)
	if red and green and blue then
		local hexa = TRP3_API.CreateColorFromBytes(red, green, blue):GenerateHexColorOpaque();
		draftData.NH = hexa;
	else
		draftData.NH = nil;
	end
end

local function setBkg(frame, bkg)
	TRP3_API.ui.frame.setBackdropToBackground(frame, bkg);
end

local function setEditBkg(frame, bkg)
	draftData.BK = bkg;
	TRP3_API.ui.frame.setBackdropToBackground(frame, bkg);
end

local function saveInformation()
	local context = getCurrentContext();
	assert(context, "No context !");
	assert(context.profile, "No profile in context");

	local dataTab = context.profile;
	assert(type(dataTab.data) == "table", "Error: Nil information data or not a table.");

	saveInDraft(context.profile.profileName);

	wipe(dataTab.data);
	-- By simply copy the draftData we get everything we need about ordering and structures.
	tcopy(dataTab.data, draftData);
	-- version increment
	dataTab.data.v = Utils.math.incrementNumber(dataTab.data.v or 0, 2);

	TRP3_Addon:TriggerEvent(Events.REGISTER_DATA_UPDATED, nil, context.profileID);
end

local function onPlayerIconSelected(icon)
	draftData.IC = icon;
	setupIconButton(TRP3_CompanionsPageInformationEdit_NamePanel_Icon, draftData.IC or TRP3_InterfaceIcons.ProfileDefault);
end

local function displayEdit()
	local context = getCurrentContext();
	assert(context, "No context !");
	assert(context.profile, "No profile in context");

	-- Copy character's data into draft structure : We never work directly on saved_variable structures !
	if not draftData then
		local dataTab = context.profile.data;
		assert(type(dataTab) == "table", "Error: Nil characteristics data or not a table.");
		draftData = {};
		tcopy(draftData, dataTab);
	end

	setupIconButton(TRP3_CompanionsPageInformationEdit_NamePanel_Icon, draftData.IC or TRP3_InterfaceIcons.ProfileDefault);
	TRP3_CompanionsPageInformationEdit_NamePanel_TitleField:SetText(draftData.TI or "");
	TRP3_CompanionsPageInformationEdit_NamePanel_NameField:SetText(draftData.NA or Globals.player);
	TRP3_CompanionsPageInformationEdit_About_TextScrollText:SetText(draftData.TX or "");

	if draftData.NH then
		TRP3_CompanionsPageInformationEdit_NamePanel_NameColor.setColor(TRP3_API.CreateColorFromHexString(draftData.NH):GetRGBAsBytes());
	else
		TRP3_CompanionsPageInformationEdit_NamePanel_NameColor.setColor(nil, nil, nil);
	end

	TRP3_API.navigation.delayedRefresh();
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Consult Mode
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

function displayConsult(context)
	local dataTab = context.profile.data or Globals.empty;

	TRP3_CompanionsPageInformationConsult_NamePanel_Name:SetText(dataTab.NA or UNKNOWN);
	TRP3_CompanionsPageInformationConsult_NamePanel_Name:SetReadableTextColor(TRP3_API.CreateColorFromHexString(dataTab.NH or "ffffff"));
	TRP3_CompanionsPageInformationConsult_NamePanel_Name:SetFixedColor(true);
	TRP3_CompanionsPageInformationConsult_NamePanel_Title:SetText((string.gsub(dataTab.TI or "", "%s+", " ")));
	TRP3_CompanionsPageInformationConsult_NamePanel.Icon:SetIconTexture(dataTab.IC or TRP3_InterfaceIcons.ProfileDefault);

	for i=1,5 do
		local glanceData = (context.profile.PE or {})[tostring(i)] or {};
		local button = _G["TRP3_CompanionsPageInformationConsult_GlanceSlot" .. i];
		button.data = glanceData;
		button.profileID = context.profileID;
		setupGlanceButton(button, glanceData.AC, glanceData.IC, glanceData.TI, glanceData.TX, context.isPlayer);
	end

	TRP3_CompanionsPageInformationConsult_About_Empty:Show();
	TRP3_CompanionsPageInformationConsult_About_ScrollText:SetText("");
	TRP3_CompanionsPageInformationConsult_About_ScrollText.html = "";
	if dataTab.TX and dataTab.TX:len() > 0 then
		TRP3_CompanionsPageInformationConsult_About_Empty:Hide();
		local text = Utils.str.toHTML(dataTab.TX);
		TRP3_CompanionsPageInformationConsult_About_ScrollText:SetText(text);
		TRP3_CompanionsPageInformationConsult_About_ScrollText.html = text;
	end
	setBkg(TRP3_CompanionsPageInformationConsult_About, dataTab.BK);
end

local function onActionSelected(value)
	if value == 1 then
		local context = getCurrentContext();
		assert(context, "No context !");
		assert(context.profileID, "No profile ID in context");
		assert(context.profile, "No profile in context");
		showConfirmPopup(loc.REG_DELETE_WARNING:format(context.profile.data.NA or UNKNOWN), function()
			deleteProfile(context.profileID)
		end);
	elseif type(value) == "string" then
		openPageByUnitID(value);
	end
end

local function onActionClick(button)
	local context = getCurrentContext();
	assert(context, "No context !");
	assert(context.profile, "No profile in context");

	TRP3_MenuUtil.CreateContextMenu(button, function(_, description)
		local masters = {};
		for companionFullId, _ in pairs(context.profile.links or EMPTY) do
			local ownerID, _ = companionIDToInfo(companionFullId);
			masters[ownerID] = true;
		end
		local mastersProfiles = {};
		for ownerID, _ in pairs(masters) do
			if isUnitIDKnown(ownerID) and hasProfile(ownerID) then
				mastersProfiles[hasProfile(ownerID)] = ownerID;
			end
		end
		if TableHasAnyEntries(mastersProfiles) then
			local masterTab = description:CreateButton(loc.PR_CO_MASTERS);
			for profileID, ownerID in pairs(mastersProfiles) do
				local profile = getUnitProfile(profileID);
				local name = getCompleteName(profile.characteristics or EMPTY, ownerID, true);
				masterTab:CreateButton(name, onActionSelected, ownerID);
			end
		end
		description:CreateDivider();
		description:CreateButton("|cnRED_FONT_COLOR:" .. loc.PR_DELETE_PROFILE .. "|r", onActionSelected, 1);
	end);
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- UI: TAB MANAGEMENT
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local tabGroup;

local function refresh()
	local context = getCurrentContext();
	assert(context, "No context !");
	assert(context.profile, "No profile in context");

	TRP3_CompanionsPageInformationConsult:Hide();
	TRP3_CompanionsPageInformationEdit:Hide();
	TRP3_CompanionsPageInformationConsult_NamePanel_EditButton:Hide();
	TRP3_CompanionsPageInformationConsult_NamePanel_ActionButton:Show();

	if context.isPlayer then
		TRP3_CompanionsPageInformationConsult_NamePanel_EditButton:Show();
		TRP3_CompanionsPageInformationConsult_NamePanel_ActionButton:Hide();
	end

	if getCurrentContext().isEditMode then
		assert(context.isPlayer, "Trying to show companion edition but is not mine ...");
		displayEdit();
		TRP3_CompanionsPageInformationEdit:Show();
	else
		displayConsult(context);
		if not context.isPlayer and context.profile.data and context.profile.data.read == false then
			context.profile.data.read = true;
			TRP3_Addon:TriggerEvent(Events.REGISTER_ABOUT_READ);
		end
		TRP3_CompanionsPageInformationConsult:Show();
	end

	TRP3_CompanionsPageInformation:Show();
	TRP3_Addon:TriggerEvent(TRP3_Addon.Events.NAVIGATION_TUTORIAL_REFRESH, COMPANIONS_PAGE_ID);
end

local function showInformationTab()
	getCurrentContext().isEditMode = false;
	refresh();
	if getCurrentContext().isPlayer then
		TRP3_CompanionsPageInformationConsult_GlanceHelp:Show();
	else
		TRP3_CompanionsPageInformationConsult_GlanceHelp:Hide();
	end
end

local function onSave()
	saveInformation();
	showInformationTab();
end

local function toEditMode()
	draftData = nil;
	getCurrentContext().isEditMode = true;
	refresh();
	PlaySound(TRP3_InterfaceSounds.ButtonClick);
end

local function createTabBar()
	local frame = CreateFrame("Frame", "TRP3_CompanionInfoTabBar", TRP3_CompanionsPage);
	frame:SetSize(400, 30);
	frame:SetPoint("TOPLEFT", 17, 0);
	frame:SetFrameLevel(1);
	tabGroup = TRP3_API.ui.frame.createTabPanel(frame,
	{
		{loc.REG_COMPANION_INFO, 1, 150}
	},
	function(_, value)
		-- Clear all
		TRP3_CompanionsPageInformation:Hide();
		if value == 1 then
			showInformationTab();
		end
	end
	);
end

local function onPageShow(context)
	assert(context.profileID, "Missing profileID in context.");
	assert(context.profile, "Missing profile in context.");
	tabGroup:SelectTab(1);
	TRP3_CompanionsPageInformationConsult_About_Scroll.ScrollBar:ScrollToBegin();
end

local function onInformationUpdated(profileID)
	if getCurrentPageID() == COMPANIONS_PAGE_ID then
		local context = getCurrentContext();
		assert(context, "No context for page player_main !");
		if not context.isPlayer and profileID == context.profileID then
			showInformationTab();
		end
	end
end

--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
-- Init
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

local showIconBrowser = function(callback, selectedIcon)
	TRP3_API.popup.showPopup(TRP3_API.popup.ICONS, nil, {callback, nil, nil, selectedIcon});
end;

-- Tutorial
local TUTORIAL_STRUCTURE_EDIT;

local function createTutorialStructure()
	TUTORIAL_STRUCTURE_EDIT = {
		{
			box = {
				allPoints = TRP3_CompanionsPageInformationEdit_NamePanel
			},
			button = {
				x = 0, y = 0, anchor = "CENTER",
				text = loc.REG_COMPANION_PAGE_TUTO_E_1,
				textWidth = 400,
				arrow = "DOWN"
			}
		},
		{
			box = {
				allPoints = TRP3_CompanionsPageInformationEdit_About
			},
			button = {
				x = 0, y = -110, anchor = "CENTER",
				text = loc.REG_COMPANION_PAGE_TUTO_E_2,
				textWidth = 400,
				arrow = "UP"
			}
		}
	}
end

TRP3_API.RegisterCallback(TRP3_Addon, TRP3_Addon.Events.WORKFLOW_ON_LOAD, function()
	openPageByUnitID = TRP3_API.register.openPageByUnitID;

	createTutorialStructure();

	registerPage({
		id = COMPANIONS_PAGE_ID,
		frame = TRP3_CompanionsPage,
		onPagePostShow = function(context)
			assert(context, "Missing context.");
			onPageShow(context);
		end,
		tutorialProvider = function()
			if getCurrentContext().isEditMode then
				return TUTORIAL_STRUCTURE_EDIT;
			end
		end
	});

	TRP3_API.RegisterCallback(TRP3_Addon, Events.REGISTER_DATA_UPDATED, function(_, _, profileID, dataType)
		onInformationUpdated(profileID, dataType);
	end);

	TRP3_CompanionsPageInformationConsult_NamePanel_EditButton:SetScript("OnClick", toEditMode);
	TRP3_CompanionsPageInformationEdit_NamePanel_CancelButton:SetScript("OnClick", showInformationTab);
	TRP3_CompanionsPageInformationEdit_NamePanel_SaveButton:SetScript("OnClick", onSave);
	TRP3_CompanionsPageInformationEdit_NamePanel_Icon:SetScript("OnClick", function(self, button)
		if button == "LeftButton" then
			showIconBrowser(onPlayerIconSelected, draftData.IC);
		elseif button == "RightButton" then
			TRP3_MenuUtil.CreateContextMenu(self, function(_, description)
				description:CreateButton(loc.UI_ICON_COPY, TRP3_API.SetLastCopiedIcon, draftData.IC);
				description:CreateButton(loc.UI_ICON_COPYNAME, function() TRP3_API.popup.showCopyDropdownPopup({draftData.IC}); end);
				description:CreateButton(loc.UI_ICON_PASTE, function() onPlayerIconSelected(TRP3_API.GetLastCopiedIcon()); end);
			end);
		end
	end);
	setTooltipForSameFrame(TRP3_CompanionsPageInformationEdit_NamePanel_Icon, "RIGHT", 0, 5, loc.REG_COMPANION_ICON, loc.REG_COMPANION_ICON_TT .. "\n\n" .. TRP3_API.FormatShortcutWithInstruction("LCLICK", loc.UI_ICON_OPENBROWSER) .. "|n" .. TRP3_API.FormatShortcutWithInstruction("RCLICK", loc.UI_ICON_OPTIONS));

	TRP3_CompanionsPageInformationEdit_NamePanel_NameColor.onSelection = onNameColorSelected;

	TRP3_CompanionsPageInformationConsult_NamePanel:SetTitleText(loc.REG_PLAYER_NAMESTITLES);
	TRP3_CompanionsPageInformationConsult_Glance:SetTitleText(loc.REG_PLAYER_GLANCE);
	TRP3_CompanionsPageInformationConsult_About:SetTitleText(loc.REG_PLAYER_ABOUT);
	TRP3_CompanionsPageInformationConsult_About_Empty:SetText(loc.REG_PLAYER_ABOUT_EMPTY);
	setupIconButton(TRP3_CompanionsPageInformationConsult_NamePanel_ActionButton, TRP3_InterfaceIcons.Gears);
	setTooltipForSameFrame(TRP3_CompanionsPageInformationConsult_NamePanel_ActionButton, "RIGHT", 0, 5, loc.CM_OPTIONS, TRP3_API.FormatShortcutWithInstruction("CLICK", loc.CM_OPTIONS_ADDITIONAL));
	TRP3_CompanionsPageInformationConsult_NamePanel_ActionButton:SetScript("OnMouseDown", onActionClick);

	setTooltipForSameFrame(TRP3_CompanionsPageInformationEdit_NamePanel_NameColor, "RIGHT", 0, 5, loc.REG_COMPANION_NAME_COLOR, loc.REG_COMPANION_NAME_COLOR_TT
	.. "|n|n" .. TRP3_API.FormatShortcutWithInstruction("LCLICK", loc.REG_PLAYER_COLOR_TT_SELECT)
	.. "|n" .. TRP3_API.FormatShortcutWithInstruction("RCLICK", loc.REG_PLAYER_COLOR_TT_OPTIONS)
	.. "|n" .. TRP3_API.FormatShortcutWithInstruction("SHIFT-CLICK", loc.REG_PLAYER_COLOR_TT_DEFAULTPICKER));
	TRP3_CompanionsPageInformationEdit_NamePanel:SetTitleText(loc.REG_PLAYER_NAMESTITLES);
	TRP3_CompanionsPageInformationEdit_About:SetTitleText(loc.REG_PLAYER_ABOUT);
	TRP3_CompanionsPageInformationEdit_NamePanel_NameFieldText:SetText(loc.REG_COMPANION_NAME);
	TRP3_CompanionsPageInformationEdit_NamePanel_TitleFieldText:SetText(loc.REG_TITLE);
	TRP3_CompanionsPageInformationEdit_NamePanel_CancelButton:SetText(loc.CM_CANCEL);
	TRP3_CompanionsPageInformationEdit_NamePanel_SaveButton:SetText(loc.CM_SAVE);

	TRP3_CompanionsPageInformationEdit_About_BckField:SetText(loc.UI_BKG_BUTTON);
	TRP3_CompanionsPageInformationEdit_About_BckField:SetScript("OnClick", function()
		local function OnBackgroundSelected(imageInfo)
			setEditBkg(TRP3_CompanionsPageInformationEdit_About, imageInfo and imageInfo.id or nil);
		end

		TRP3_API.popup.ShowBackgroundBrowser(OnBackgroundSelected, draftData.BK);
	end);

	TRP3_API.ui.text.setupToolbar(TRP3_CompanionsPageInformationEdit_About_Toolbar, TRP3_CompanionsPageInformationEdit_About_TextScrollText);

	setTooltipForSameFrame(TRP3_CompanionsPageInformationConsult_GlanceHelp, "RIGHT", 0, 5, loc.REG_PLAYER_GLANCE, loc.REG_PLAYER_GLANCE_CONFIG
	.. "|n|n" .. TRP3_API.FormatShortcutWithInstruction("LCLICK", loc.REG_PLAYER_GLANCE_CONFIG_EDIT)
	.. "|n" .. TRP3_API.FormatShortcutWithInstruction("DCLICK", loc.REG_PLAYER_GLANCE_CONFIG_TOGGLE)
	.. "|n" .. TRP3_API.FormatShortcutWithInstruction("RCLICK", loc.REG_PLAYER_GLANCE_CONFIG_PRESETS)
	.. "|n" .. TRP3_API.FormatShortcutWithInstruction("DRAGDROP", loc.REG_PLAYER_GLANCE_CONFIG_REORDER));

	TRP3_CompanionsPageInformationConsult_About_ScrollText:SetFontObject("p", GameFontNormal);
	TRP3_CompanionsPageInformationConsult_About_ScrollText:SetFontObject("h1", GameFontNormalHuge3);
	TRP3_CompanionsPageInformationConsult_About_ScrollText:SetFontObject("h2", GameFontNormalHuge);
	TRP3_CompanionsPageInformationConsult_About_ScrollText:SetFontObject("h3", GameFontNormalLarge);
	TRP3_CompanionsPageInformationConsult_About_ScrollText:SetTextColor("h1", 1, 1, 1);
	TRP3_CompanionsPageInformationConsult_About_ScrollText:SetTextColor("h2", 1, 1, 1);
	TRP3_CompanionsPageInformationConsult_About_ScrollText:SetTextColor("h3", 1, 1, 1);

	for index=1,5,1 do
		-- DISPLAY
		local button = _G["TRP3_CompanionsPageInformationConsult_GlanceSlot" .. index];
		button:SetScript("OnClick", TRP3_API.register.glance.onGlanceSlotClick);
		button:SetScript("OnDoubleClick", TRP3_API.register.glance.onGlanceDoubleClick);
		button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		button:RegisterForDrag("LeftButton");
		button:SetScript("OnDragStart", TRP3_API.register.glance.onGlanceDragStart);
		button:SetScript("OnDragStop", TRP3_API.register.glance.onGlanceDragStop);
		button.slot = tostring(index);
	end

	createTabBar();

	-- Resizing
	TRP3_API.RegisterCallback(TRP3_Addon, TRP3_Addon.Events.NAVIGATION_RESIZED, function(_, containerWidth)
		TRP3_CompanionsPageInformationConsult_About_ScrollText:SetSize(containerWidth - 75, 5);
		TRP3_CompanionsPageInformationConsult_About_ScrollText:SetText(TRP3_CompanionsPageInformationConsult_About_ScrollText.html or "");
		TRP3_CompanionsPageInformationEdit_About_TextScrollText:SetSize(containerWidth - 85, 5);
	end);
end);
