--This is from Cloudy TradeSkill, however without it, this addon would not function.


--- Initialization ---
local numTabs = 0
local searchTxt = ''
local filterMats, filterSkill
local skinUI, loadedUI

local function InitDB()
	-- Create new DB if needed --
	if (not ProfessionTabButtonsDB) then
		ProfessionTabButtonsDB = {}
		ProfessionTabButtonsDB['Size'] = 30
		ProfessionTabButtonsDB['Unlock'] = false
		ProfessionTabButtonsDB['Fade'] = false
		ProfessionTabButtonsDB['Level'] = true
	end
	if not ProfessionTabButtonsDB['Tabs'] then ProfessionTabButtonsDB['Tabs'] = {} end

	-- Load UI addons --
	if IsAddOnLoaded('Aurora') then
		skinUI = 'Aurora'
		loadedUI = unpack(Aurora)
	elseif IsAddOnLoaded('ElvUI') then
		skinUI = 'ElvUI'
		loadedUI = unpack(ElvUI):GetModule('Skins')
	end
end


--- Create Frame ---
local f = CreateFrame('Frame', 'ProfessionTabButtons')
f:RegisterEvent('PLAYER_LOGIN')
f:RegisterEvent('TRADE_SKILL_LIST_UPDATE')
f:RegisterEvent('TRADE_SKILL_DATA_SOURCE_CHANGED')


--- Local Functions ---
	--- Save Filters ---
	local function saveFilters()
		searchTxt = TradeSkillFrame.SearchBox:GetText()
		filterMats = C_TradeSkillUI.GetOnlyShowMakeableRecipes()
		filterSkill = C_TradeSkillUI.GetOnlyShowSkillUpRecipes()
	end

	--- Restore Filters ---
	local function restoreFilters()
		TradeSkillFrame.SearchBox:SetText('')
		TradeSkillFrame.SearchBox:SetText(searchTxt)
		C_TradeSkillUI.SetOnlyShowMakeableRecipes(filterMats)
		C_TradeSkillUI.SetOnlyShowSkillUpRecipes(filterSkill)
	end

	--- Check Current Tab ---
	local function isCurrentTab(self)
		if self.tooltip and IsCurrentSpell(self.tooltip) then
			if TradeSkillFrame:IsShown() and (self.isSub == 0) then
				ProfessionTabButtonsDB['Panel'] = C_TradeSkillUI.GetTradeSkillLine()
				restoreFilters()
			end
			self:SetChecked(true)
			self:RegisterForClicks(nil)
		else
			self:SetChecked(false)
			self:RegisterForClicks('AnyDown')
		end
	end

	--- Add Tab Button ---
	local function addTab(id, index, isSub)
		local name, icon, tabType
		if (id == 134020) then
			name, icon = select(2, C_ToyBox.GetToyInfo(id))
			tabType = 'toy'
		else
			name, _, icon = GetSpellInfo(id)
			if (id == 126462) then
				tabType = 'item'
			else
				tabType = 'spell'
			end
		end
		if (not name) or (not icon) then return end

		local tab = _G['ProfessionTabButtonsTab' .. index] or CreateFrame('CheckButton', 'ProfessionTabButtonsTab' .. index, TradeSkillFrame, 'SpellBookSkillLineTabTemplate, SecureActionButtonTemplate')
		tab:SetScript('OnEvent', isCurrentTab)
		tab:RegisterEvent('TRADE_SKILL_SHOW')
		tab:RegisterEvent('CURRENT_SPELL_CAST_CHANGED')

		tab.id = id
		tab.isSub = isSub
		tab.tooltip = name
		tab:SetNormalTexture(icon)
		tab:SetAttribute('type', tabType)
		tab:SetAttribute(tabType, name)

		if skinUI and not tab.skinned then
			local checkedTexture
			if (skinUI == 'Aurora') then
				checkedTexture = 'Interface\\AddOns\\Aurora\\media\\CheckButtonHilight'
			elseif (skinUI == 'ElvUI') then
				checkedTexture = tab:CreateTexture(nil, 'HIGHLIGHT')
				checkedTexture:SetColorTexture(1, 1, 1, 0.3)
				checkedTexture:SetInside()
				tab:SetHighlightTexture(nil)
			end
			tab:SetCheckedTexture(checkedTexture)
			tab:GetNormalTexture():SetTexCoord(.08, .92, .08, .92)
			tab:GetRegions():Hide()
			tab.skinned = true
		end

		isCurrentTab(tab)
		tab:Show()
	end

	--- Remove Tab Buttons ---
	local function removeTabs()
		for i = 1, numTabs do
			local tab = _G['ProfessionTabButtonsTab' .. i]
			if tab and tab:IsShown() then
				tab:UnregisterEvent('TRADE_SKILL_SHOW')
				tab:UnregisterEvent('CURRENT_SPELL_CAST_CHANGED')
				tab:Hide()
			end
		end
	end

	--- Sort Tabs ---
	local function sortTabs()
		local index = 1
		for i = 1, numTabs do
			local tab = _G['ProfessionTabButtonsTab' .. i]
			if tab then
				if ProfessionTabButtonsDB['Tabs'][tab.id] == true then
					tab:SetPoint('TOPLEFT', TradeSkillFrame, 'TOPRIGHT', skinUI and 1 or 0, (-44 * index) + (-40 * tab.isSub))
					tab:Show()
					index = index + 1
				else
					tab:Hide()
				end
			end
		end
	end

	--- Check Fading State ---
	local function fadeState()
		if GetUnitSpeed('player') == 0 then
			TradeSkillFrame:SetAlpha(1.0)
		else
			if ProfessionTabButtonsDB['Fade'] == true then
				TradeSkillFrame:SetAlpha(0.4)
			else
				TradeSkillFrame:SetAlpha(1.0)
			end
		end

		if ProfessionTabButtonsDB['Fade'] == true then
			f:RegisterEvent('PLAYER_STARTED_MOVING')
			f:RegisterEvent('PLAYER_STOPPED_MOVING')
		else
			f:UnregisterEvent('PLAYER_STARTED_MOVING')
			f:UnregisterEvent('PLAYER_STOPPED_MOVING')
		end
	end

	--- Check Profession Useable ---
	local function isUseable(id)
		local name = GetSpellInfo(id)
		return IsUsableSpell(name)
	end

	--- Update Profession Tabs ---
	local function updateTabs(init)
		if init and ProfessionTabButtonsDB['Panel'] then return end
		local mainTabs, subTabs = {}, {}

		local _, class = UnitClass('player')
		if class == 'DEATHKNIGHT' and isUseable(53428) then
			tinsert(mainTabs, 53428) --RuneForging
		elseif class == 'ROGUE' and isUseable(1804) then
			tinsert(subTabs, 1804) --PickLock
		end

		if PlayerHasToy(134020) and C_ToyBox.IsToyUsable(134020) then
			tinsert(subTabs, 134020) --ChefHat
		end
		if GetItemCount(87216) ~= 0 then
			tinsert(subTabs, 126462) --ThermalAnvil
		end

		local prof1, prof2, arch, fishing, cooking, firstaid = GetProfessions()
		local profs = {prof1, prof2, cooking, firstaid}
		for _, prof in pairs(profs) do
			local num, offset, line, _, _, spec = select(5, GetProfessionInfo(prof))
			if (spec and spec ~= 0) then num = 1 end
			for i = 1, num do
				if not IsPassiveSpell(offset + i, BOOKTYPE_PROFESSION) then
					local _, id = GetSpellBookItemInfo(offset + i, BOOKTYPE_PROFESSION)
					if (i == 1) then
						tinsert(mainTabs, id)
						if init and not ProfessionTabButtonsDB['Panel'] then
							ProfessionTabButtonsDB['Panel'] = line
							return
						end
					else
						tinsert(subTabs, id)
					end
				end
			end
		end

		local sameTabs = true
		for i = 1, #mainTabs + #subTabs do
			local id = mainTabs[i] or subTabs[i - #mainTabs]
			if ProfessionTabButtonsDB['Tabs'][id] == nil then
				ProfessionTabButtonsDB['Tabs'][id] = true
				sameTabs = false
			end
		end

		if not sameTabs or (numTabs ~= #mainTabs + #subTabs) then
			removeTabs()
			numTabs = #mainTabs + #subTabs

			for i = 1, numTabs do
				local id = mainTabs[i] or subTabs[i - #mainTabs]
				addTab(id, i, mainTabs[i] and 0 or 1)
			end
			sortTabs()
		end
	end

	--- Update Frame Size ---
	local function updateSize(forced)
		TradeSkillFrame:SetHeight(ProfessionTabButtonsDB['Size'] * 16 + 96) --496
		TradeSkillFrame.RecipeInset:SetHeight(ProfessionTabButtonsDB['Size'] * 16 + 10) --410
		TradeSkillFrame.DetailsInset:SetHeight(ProfessionTabButtonsDB['Size'] * 16 - 10) --390
		TradeSkillFrame.DetailsFrame:SetHeight(ProfessionTabButtonsDB['Size'] * 16 - 15) --385
		TradeSkillFrame.DetailsFrame.Background:SetHeight(ProfessionTabButtonsDB['Size'] * 16 - 17) --383

		if TradeSkillFrame.RecipeList.FilterBar:IsVisible() then
			TradeSkillFrame.RecipeList:SetHeight(ProfessionTabButtonsDB['Size'] * 16 - 11) --389
		else
			TradeSkillFrame.RecipeList:SetHeight(ProfessionTabButtonsDB['Size'] * 16 + 5) --405
		end

		if forced and #TradeSkillFrame.RecipeList.buttons < floor(ProfessionTabButtonsDB['Size'], 0.5) + 2 then
			HybridScrollFrame_CreateButtons(TradeSkillFrame.RecipeList, 'TradeSkillRowButtonTemplate', 0, 0)
			TradeSkillFrame.RecipeList:Refresh()
		end
	end

	--- Update Frame Position ---
	local function updatePosition()
		if ProfessionTabButtonsDB['Unlock'] then
			UIPanelWindows['TradeSkillFrame'].area = nil
			TradeSkillFrame:ClearAllPoints()
			if ProfessionTabButtonsDB['OffsetX'] and ProfessionTabButtonsDB['OffsetY'] then
				TradeSkillFrame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', ProfessionTabButtonsDB['OffsetX'], ProfessionTabButtonsDB['OffsetY'])
			else
				TradeSkillFrame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', GetUIPanel('left') and 623 or 16, -116)
			end
		else
			UpdateUIPanelPositions(TradeSkillFrame)
		end
	end


--- Create Resize Bar ---
local resizeBar = CreateFrame('Button', nil, TradeSkillFrame)
resizeBar:SetAllPoints(TradeSkillFrameBottomBorder)
resizeBar:SetScript('OnMouseDown', function(_, button)
	if (button == 'LeftButton') and not InCombatLockdown() then
		TradeSkillFrame:SetResizable(true)
		TradeSkillFrame:SetMinResize(670, 495)
		TradeSkillFrame:SetMaxResize(670, TradeSkillFrame:GetTop() - 40)
		TradeSkillFrame:StartSizing('BOTTOM')
	end
end)
resizeBar:SetScript('OnMouseUp', function(_, button)
	if (button == 'LeftButton') and not InCombatLockdown() then
		TradeSkillFrame:StopMovingOrSizing()
		TradeSkillFrame:SetResizable(false)
		updateSize(true)
	end
end)
resizeBar:SetScript('OnEnter', function()
	if not InCombatLockdown() then
		SetCursor('CAST_CURSOR')
	end
end)
resizeBar:SetScript('OnLeave', function()
	if not InCombatLockdown() then
		ResetCursor()
	end
end)


--- Create Movable Bar ---
local movBar = CreateFrame('Button', nil, TradeSkillFrame)
movBar:SetAllPoints(TradeSkillFrameTopBorder)
movBar:SetScript('OnMouseDown', function(_, button)
	if (button == 'LeftButton') then
		TradeSkillFrame:SetMovable(true)
		TradeSkillFrame:StartMoving()
	elseif (button == 'RightButton') then
		if not InCombatLockdown() then
			ProfessionTabButtonsDB['OffsetX'] = nil
			ProfessionTabButtonsDB['OffsetY'] = nil
			updatePosition()
		end
	end
end)
movBar:SetScript('OnMouseUp', function(_, button)
	if (button == 'LeftButton') then
		TradeSkillFrame:StopMovingOrSizing()
		TradeSkillFrame:SetMovable(false)

		ProfessionTabButtonsDB['OffsetX'] = TradeSkillFrame:GetLeft()
		ProfessionTabButtonsDB['OffsetY'] = TradeSkillFrame:GetTop()
	end
end)


--- Force ESC Close ---
hooksecurefunc('ToggleGameMenu', function()
	if ProfessionTabButtonsDB['Unlock'] and TradeSkillFrame:IsShown() then
		C_TradeSkillUI.CloseTradeSkill()
		HideUIPanel(GameMenuFrame)
	end
end)


--- Refresh TSFrame ---
TradeSkillFrame:HookScript('OnSizeChanged', function(self)
	if not InCombatLockdown() then
		ProfessionTabButtonsDB['Size'] = (self:GetHeight() - 96) / 16
		updateSize()
	end
end)


--- Refresh RecipeList ---
hooksecurefunc('HybridScrollFrame_Update', function(self, ...)
	if (self == TradeSkillFrame.RecipeList) then
		if self.FilterBar:IsVisible() then
			self:SetHeight(ProfessionTabButtonsDB['Size'] * 16 - 11) --389
		else
			self:SetHeight(ProfessionTabButtonsDB['Size'] * 16 + 5) --405
		end
	end
end)


--- Other Adjustment ---
TradeSkillFrame.RankFrame:SetWidth(500)
TradeSkillFrame.SearchBox:SetWidth(240)
MainMenuBarOverlayFrame:SetFrameStrata('MEDIUM')


--- Required Level Display ---
TradeSkillFrame.RecipeList:HookScript('OnUpdate', function(self, ...)
	for i = 1, #self.buttons do
		if ProfessionTabButtonsDB and ProfessionTabButtonsDB['Level'] == true then
			local button = self.buttons[i]
			local lvlFrame = _G['CTSLevel_' .. i] or CreateFrame('Frame', 'CTSLevel_' .. i, button)
			if not lvlFrame.Text then
				lvlFrame.Text = lvlFrame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmall')
				lvlFrame.Text:SetPoint('RIGHT', button.Text, 'LEFT', 1, 0)
			end

			if button.tradeSkillInfo and not button.isHeader then
				local recipe = button.tradeSkillInfo.recipeID
				local item = C_TradeSkillUI.GetRecipeItemLink(recipe)
				local quality, _, level = select(3, GetItemInfo(item))
				if quality and level and level > 1 then
					lvlFrame.Text:SetText(level)
					lvlFrame.Text:SetTextColor(GetItemQualityColor(quality))
				else
					lvlFrame.Text:SetText('')
				end
			else
				if lvlFrame.Text then
					lvlFrame.Text:SetText('')
				end
			end
		else
			if _G['CTSLevel_' .. i] then
				_G['CTSLevel_' .. i].Text:SetText('')
			end
		end
	end
end)


--- Collapse Recipes ---
hooksecurefunc(TradeSkillFrame.RecipeList, 'OnHeaderButtonClicked', function(self, _, info, button)
	if (button ~= 'RightButton') then return end

	local collapsed = self:IsCategoryCollapsed(info.categoryID)
	local subCat = C_TradeSkillUI.GetSubCategories(info.categoryID)
	if subCat then
		collapsed = not self:IsCategoryCollapsed(subCat)
	end

	local allCategories = {C_TradeSkillUI.GetCategories()}
	for _, catId in pairs(allCategories) do
		local subCategories = {C_TradeSkillUI.GetSubCategories(catId)}
		if #subCategories == 0 then
			self.collapsedCategories[catId] = collapsed
		else
			self.collapsedCategories[catId] = false
			for _, subId in pairs(subCategories) do
				self.collapsedCategories[subId] = collapsed
			end
		end
	end
	self:Refresh()
end)


--- Fix SearchBox ---
hooksecurefunc('ChatEdit_InsertLink', function(link)
	if link and TradeSkillFrame:IsShown() then
		local activeWindow = ChatEdit_GetActiveWindow()
		if activeWindow then return end

		if strfind(link, 'item:', 1, true) or strfind(link, 'enchant:', 1, true) then
			local text = strmatch(link, '|h%[(.+)%]|h|r')
			if text then
				text = strmatch(text, ':%s(.+)') or text
				TradeSkillFrame.SearchBox:SetText(text:lower())
			end
		end
	end
end)


--- Fix StackSplit ---
hooksecurefunc('ContainerFrameItemButton_OnModifiedClick', function(self, button)
	if TradeSkillFrame:IsShown() then
		if (button == 'LeftButton') then
			StackSplitFrame:Hide()
		end
	end
end)


--- Fix RecipeLink ---
local getRecipe = C_TradeSkillUI.GetRecipeLink
C_TradeSkillUI.GetRecipeLink = function(link)
	if link and (link ~= '') then
		return getRecipe(link)
	end
end


--- Druid Unshapeshift ---
local function injectButtons()
	local _, class = UnitClass('player')
	if (class ~= 'DRUID') then return end

	local function injectMacro(button, text)
		local macro = CreateFrame('Button', nil, button:GetParent(), 'MagicButtonTemplate, SecureActionButtonTemplate')
		macro:SetAttribute('type', 'macro')
		macro:SetAttribute('macrotext', SLASH_CANCELFORM1)
		macro:SetPoint(button:GetPoint())
		macro:SetFrameStrata('HIGH')
		macro:SetText(text)

		if (skinUI == 'Aurora') then
			loadedUI.Reskin(macro)
		elseif (skinUI == 'ElvUI') then
			loadedUI:HandleButton(macro, true)
		end

		macro:HookScript('OnClick', button:GetScript('OnClick'))
		button:HookScript('OnDisable', function()
			button:SetAlpha(1)
			macro:SetAlpha(0)
			macro:RegisterForClicks(nil)
		end)
		button:HookScript('OnEnable', function()
			button:SetAlpha(0)
			macro:SetAlpha(1)
			macro:RegisterForClicks('LeftButtonDown')
		end)
	end
	injectMacro(TradeSkillFrame.DetailsFrame.CreateButton, CREATE_PROFESSION)
	injectMacro(TradeSkillFrame.DetailsFrame.CreateAllButton, CREATE_ALL)
end


--- Create Warning Dialog ---
StaticPopupDialogs['ProfessionTabButtons_WARNING'] = {
	text = UNLOCK_FRAME .. ' ' .. REQUIRES_RELOAD:lower() .. '!\n',
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		ProfessionTabButtonsDB['Unlock'] = not ProfessionTabButtonsDB['Unlock']
		ReloadUI()
	end,
	OnShow = function()
		_G['ProfessionTabOptions']:Disable()
	end,
	OnHide = function()
		_G['ProfessionTabOptions']:Enable()
	end,
	timeout = 0,
	exclusive = 1,
	preferredIndex = 3,
}


--- Create Option Menu ---
local function createOptions()
	--- Dropdown Menu ---
	local function CTSDropdown_Init(self, level)
		local info = UIDropDownMenu_CreateInfo()
		if level == 1 then
			info.text = f:GetName()
			info.isTitle = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, level)

			info.isTitle = false
			info.disabled = false
			info.isNotRadio = true
			info.notCheckable = false

			info.text = UNLOCK_FRAME
			info.func = function()
				StaticPopup_Show('ProfessionTabButtons_WARNING')
			end
			info.checked = ProfessionTabButtonsDB['Unlock']
			UIDropDownMenu_AddButton(info, level)

			info.text = 'UI ' .. ACTION_SPELL_AURA_REMOVED_BUFF
			info.func = function()
				ProfessionTabButtonsDB['Fade'] = not ProfessionTabButtonsDB['Fade']
				fadeState()
			end
			info.keepShownOnClick = true
			info.checked = ProfessionTabButtonsDB['Fade']
			UIDropDownMenu_AddButton(info, level)

			info.text = STAT_AVERAGE_ITEM_LEVEL
			info.func = function()
				ProfessionTabButtonsDB['Level'] = not ProfessionTabButtonsDB['Level']
				TradeSkillFrame.RecipeList:Refresh()
			end
			info.keepShownOnClick = true
			info.checked = ProfessionTabButtonsDB['Level']
			UIDropDownMenu_AddButton(info, level)

			info.func = nil
			info.checked = 	nil
			info.notCheckable = true
			info.hasArrow = true

			info.text = PRIMARY
			info.value = 1
			info.disabled = InCombatLockdown()
			UIDropDownMenu_AddButton(info, level)

			info.text = SECONDARY
			info.value = 2
			info.disabled = InCombatLockdown()
			UIDropDownMenu_AddButton(info, level)
		elseif level == 2 then
			info.isNotRadio = true
			info.keepShownOnClick = true
			if UIDROPDOWNMENU_MENU_VALUE == 1 then
				for i = 1, numTabs do
					local tab = _G['ProfessionTabButtonsTab' .. i]
					if tab and (tab.isSub == 0) then
						info.text = tab.tooltip
						info.func = function()
							ProfessionTabButtonsDB['Tabs'][tab.id] = not ProfessionTabButtonsDB['Tabs'][tab.id]
							sortTabs()
						end
						info.checked = ProfessionTabButtonsDB['Tabs'][tab.id]
						UIDropDownMenu_AddButton(info, level)
					end
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 2 then
				for i = 1, numTabs do
					local tab = _G['ProfessionTabButtonsTab' .. i]
					if tab and (tab.isSub == 1) then
						info.text = tab.tooltip
						info.func = function()
							ProfessionTabButtonsDB['Tabs'][tab.id] = not ProfessionTabButtonsDB['Tabs'][tab.id]
							sortTabs()
						end
						info.checked = ProfessionTabButtonsDB['Tabs'][tab.id]
						UIDropDownMenu_AddButton(info, level)
					end
				end
			end
		end
	end
	local menu = CreateFrame('Frame', 'CTSDropdown', nil, 'UIDropDownMenuTemplate')
	UIDropDownMenu_Initialize(CTSDropdown, CTSDropdown_Init, 'MENU')

	--- Option Button ---
	local button = CreateFrame('Button', 'ProfessionTabOptions', TradeSkillFrame.FilterButton, 'UIMenuButtonStretchTemplate')
	button:SetScript('OnClick', function(self) ToggleDropDownMenu(1, nil, CTSDropdown, self, 2, -6) end)
	button:SetPoint('RIGHT', TradeSkillFrame.FilterButton, 'LEFT', -8, 0)
	button:SetText(GAMEOPTIONS_MENU)
	button:SetSize(80, 22)
	button.Icon = button:CreateTexture(nil, 'ARTWORK')
	button.Icon:SetPoint('RIGHT')
	button.Icon:Hide()

	if (skinUI == 'Aurora') then
		loadedUI.ReskinFilterButton(button)
	elseif (skinUI == 'ElvUI') then
		button:StripTextures(true)
		button:CreateBackdrop('Default', true)
		button.backdrop:SetAllPoints()
	end
end


--- Handle Events ---
f:SetScript('OnEvent', function(self, event, ...)
	if (event == 'PLAYER_LOGIN') then
		InitDB()
		updateSize(true)
		updatePosition()
		updateTabs(true)
		createOptions()
		injectButtons()
		fadeState()
	elseif (event == 'PLAYER_STARTED_MOVING') then
		TradeSkillFrame:SetAlpha(0.4)
	elseif (event == 'PLAYER_STOPPED_MOVING') then
		TradeSkillFrame:SetAlpha(1.0)
	elseif (event == 'TRADE_SKILL_LIST_UPDATE') then
		saveFilters()
	elseif (event == 'TRADE_SKILL_DATA_SOURCE_CHANGED') then
		if not InCombatLockdown() then
			updateTabs()
		end
	end
end)
