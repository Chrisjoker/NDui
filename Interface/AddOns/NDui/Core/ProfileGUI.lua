local _, ns = ...
local B, C, L, DB = unpack(ns)
local G = B:GetModule("GUI")

local cr, cg, cb = DB.r, DB.g, DB.b
local myFullName = DB.MyFullName

-- Static popups
StaticPopupDialogs["RESET_NDUI"] = {
	text = L["Reset NDui Check"],
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		NDuiDB = {}
		NDuiADB = {}
		NDuiPDB = {}
		ReloadUI()
	end,
	whileDead = 1,
}

StaticPopupDialogs["NDUI_RESET_PROFILE"] = {
	text = L["Reset current profile?"],
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		wipe(C.db)
		ReloadUI()
	end,
	whileDead = 1,
}

StaticPopupDialogs["NDUI_APPLY_PROFILE"] = {
	text = L["Apply selected profile?"],
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		NDuiADB["ProfileIndex"][myFullName] = G.currentProfile
		ReloadUI()
	end,
	whileDead = 1,
}

StaticPopupDialogs["NDUI_DOWNLOAD_PROFILE"] = {
	text = L["Download selected profile?"],
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		local profileIndex = NDuiADB["ProfileIndex"][myFullName]
		if G.currentProfile == 1 then
			NDuiPDB[profileIndex-1] = NDuiDB
		elseif profileIndex == 1 then
			NDuiDB = NDuiPDB[G.currentProfile-1]
		else
			NDuiPDB[profileIndex-1] = NDuiPDB[G.currentProfile-1]
		end
		ReloadUI()
	end,
	whileDead = 1,
}

StaticPopupDialogs["NDUI_UPLOAD_PROFILE"] = {
	text = L["Upload current profile?"],
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		local profileIndex = NDuiADB["ProfileIndex"][myFullName]
		if G.currentProfile == 1 then
			NDuiDB = C.db
		else
			NDuiPDB[G.currentProfile-1] = C.db
		end
	end,
	whileDead = 1,
}

function G:CreateProfileIcon(bar, index, texture, title, description)
	local button = CreateFrame("Button", nil, bar)
	button:SetSize(32, 32)
	button:SetPoint("RIGHT", -5 - (index-1)*37, 0)
	B.PixelIcon(button, texture, true)
	button.title = title
	B.AddTooltip(button, "ANCHOR_RIGHT", description, "info")

	return button
end

function G:Reset_OnClick()
	StaticPopup_Show("NDUI_RESET_PROFILE")
end

function G:Apply_OnClick()
	G.currentProfile = self:GetParent().index
	StaticPopup_Show("NDUI_APPLY_PROFILE")
end

function G:Download_OnClick()
	G.currentProfile = self:GetParent().index
	StaticPopup_Show("NDUI_DOWNLOAD_PROFILE")
end

function G:Upload_OnClick()
	G.currentProfile = self:GetParent().index
	StaticPopup_Show("NDUI_UPLOAD_PROFILE")
end

function G:FindProfleUser(icon)
	icon.list = {}
	for name, index in pairs(NDuiADB["ProfileIndex"]) do
		if index == icon.index then
			tinsert(icon.list, name)
		end
	end
end

function G:Icon_OnEnter()
	if #self.list == 0 then return end

	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["SharedCharacters"])
	GameTooltip:AddLine(" ")
	for _, name in pairs(self.list) do
		GameTooltip:AddLine(name, 1,1,1)
	end
	GameTooltip:Show()
end

function G:Note_OnEscape()
	self:SetText(NDuiADB["ProfileNames"][self.index])
end

function G:Note_OnEnter()
	local text = self:GetText()
	if text == "" then
		NDuiADB["ProfileNames"][self.index] = self.__defaultText
		self:SetText(self.__defaultText)
	else
		NDuiADB["ProfileNames"][self.index] = text
	end
end

function G:CreateProfileBar(parent, index)
	local bar = B.CreateBDFrame(parent, .25)
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", 10, -10 - 45*(index-1))
	bar:SetSize(570, 40)
	bar.index = index
	
	local icon = CreateFrame("Frame", nil, bar)
	icon:SetSize(32, 32)
	icon:SetPoint("LEFT", 5, 0)
	if index == 1 then
		B.PixelIcon(icon, nil, true) -- character
		SetPortraitTexture(icon.Icon, "player")
	else
		B.PixelIcon(icon, 235423, true) -- share
		icon.Icon:SetTexCoord(.6, .9, .1, .4)
		icon.index = index
		G:FindProfleUser(icon)
		icon:SetScript("OnEnter", G.Icon_OnEnter)
		icon:SetScript("OnLeave", B.HideTooltip)
	end

	local note = B.CreateEditBox(bar, 150, 32)
	note:SetPoint("LEFT", icon, "RIGHT", 5, 0)
	note:SetMaxLetters(20)
	if index == 1 then
		note.__defaultText = L["DefaultCharacterProfile"]
	else
		note.__defaultText = L["DefaultSharedProfile"]..(index - 1)
	end
	if not NDuiADB["ProfileNames"][index] then
		NDuiADB["ProfileNames"][index] = note.__defaultText
	end
	note:SetText(NDuiADB["ProfileNames"][index])
	note.index = index
	note:HookScript("OnEnterPressed", G.Note_OnEnter)
	note:HookScript("OnEscapePressed", G.Note_OnEscape)
	note.title = L["ProfileName"]
	B.AddTooltip(note, "ANCHOR_TOP", L["ProfileNameTip"], "info")

	local reset = G:CreateProfileIcon(bar, 1, "Atlas:transmog-icon-revert", L["ResetProfile"], L["ResetProfileTip"])
	reset:SetScript("OnClick", G.Reset_OnClick)
	bar.reset = reset

	local apply = G:CreateProfileIcon(bar, 2, "Interface\\RAIDFRAME\\ReadyCheck-Ready", L["SelectProfile"], L["SelectProfileTip"])
	apply:SetScript("OnClick", G.Apply_OnClick)
	bar.apply = apply

	local download = G:CreateProfileIcon(bar, 3, "Atlas:streamcinematic-downloadicon", L["DownloadProfile"], L["DownloadProfileTip"])
	download.Icon:SetTexCoord(.25, .75, .25, .75)
	download:SetScript("OnClick", G.Download_OnClick)
	bar.download = download

	local upload = G:CreateProfileIcon(bar, 4, "Atlas:bags-icon-addslots", L["UploadProfile"], L["UploadProfileTip"])
	upload.Icon:SetInside(nil, 6, 6)
	upload:SetScript("OnClick", G.Upload_OnClick)
	bar.upload = upload

	return bar
end

local function UpdateButtonStatus(button, enable)
	button:EnableMouse(enable)
	button.Icon:SetDesaturated(not enable)
end

function G:UpdateCurrentProfile()
	for index, bar in pairs(G.bars) do
		if index == G.currentProfile then
			UpdateButtonStatus(bar.upload, false)
			UpdateButtonStatus(bar.download, false)
			UpdateButtonStatus(bar.apply, false)
			UpdateButtonStatus(bar.reset, true)
			bar:SetBackdropColor(cr, cg, cb, .25)
			bar.apply.bg:SetBackdropBorderColor(1, .8, 0)
		else
			UpdateButtonStatus(bar.upload, true)
			UpdateButtonStatus(bar.download, true)
			UpdateButtonStatus(bar.apply, true)
			UpdateButtonStatus(bar.reset, false)
			bar:SetBackdropColor(0, 0, 0, .25)
			bar.apply.bg:SetBackdropBorderColor(0, 0, 0)
		end
	end
end

function G:CreateProfileGUI(parent)
	local reset = B.CreateButton(parent, 120, 24, L["NDui Reset"])
	reset:SetPoint("BOTTOMRIGHT", -10, 10)
	reset:SetScript("OnClick", function()
		StaticPopup_Show("RESET_NDUI")
	end)

	local import = B.CreateButton(parent, 120, 24, L["Import"])
	import:SetPoint("BOTTOMLEFT", 10, 10)
	import:SetScript("OnClick", function()
		parent:GetParent():Hide()
		G:CreateDataFrame()
		G.ProfileDataFrame.Header:SetText(L["Import Header"])
		G.ProfileDataFrame.text:SetText(L["Import"])
		G.ProfileDataFrame.editBox:SetText("")
	end)

	local export = B.CreateButton(parent, 120, 24, L["Export"])
	export:SetPoint("LEFT", import, "RIGHT", 3, 0)
	export:SetScript("OnClick", function()
		parent:GetParent():Hide()
		G:CreateDataFrame()
		G.ProfileDataFrame.Header:SetText(L["Export Header"])
		G.ProfileDataFrame.text:SetText(OKAY)
		G:ExportGUIData()
	end)

	B.CreateFS(parent, 14, L["Profile Management"], "system", "TOPLEFT", 10, -10)
	local description = B.CreateFS(parent, 14, L["Profile Description"], nil, "TOPLEFT", 10, -35)
	description:SetPoint("TOPRIGHT", -10, -30)
	description:SetWordWrap(true)
	description:SetJustifyH("LEFT")

	G.currentProfile = NDuiADB["ProfileIndex"][DB.MyFullName]

	local numBars = 6
	local panel = B.CreateBDFrame(parent, .25)
	panel:ClearAllPoints()
	panel:SetPoint("BOTTOMLEFT", 10, 80)
	panel:SetWidth(parent:GetWidth() - 20)
	panel:SetHeight(15 + numBars*45)
	panel:SetFrameLevel(11)

	G.bars = {}
	for i = 1, numBars do
		G.bars[i] = G:CreateProfileBar(panel, i)
	end

	G:UpdateCurrentProfile()
end