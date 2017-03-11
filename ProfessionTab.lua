--This is a heavy work in progress. Sorry if a lot of the code is frustrating. I'm still learning. I got the wowprogramming book right after I finished this. Hopefully future updates are to come. :)



local f = CreateFrame("Frame")

SpellBookFrameTabButton1:Hide()
SpellBookFrameTabButton2:Hide()

--Right Button, TradeSkillFrame
local function TSF_OnClick(self)
	if SpellBookFrame and SpellBookFrame:IsVisible() then
		SpellBookFrameTabButton2:Click()
		PrimaryProfession1SpellButtonBottom:Click()
		SpellBookFrameCloseButton:Click()
	else
		self:SetChecked(true)
	end
end

--Left Button, SpellBookFrame
local function SBF_OnClick(self)
	if TradeSkillFrame and TradeSkillFrame:IsVisible() then
		SpellbookMicroButton:Click()
		TradeSkillFrameCloseButton:Click()
	else
		self:SetChecked(true)
	end
end


--Creates the Spellbook buttons
local function CreateOtherButtons()
	f.tsf2 = CreateFrame("CheckButton", "TradeskillTab2", SpellBookFrame, "CharacterFrameTabButtonTemplate")
		f.tsf2:SetPoint("TOP", SpellBookFrame, "BOTTOMLEFT", 123, 0)
		f.tsf2:SetSize(100,30)
		f.tsf2:SetText("Professions")
		f.tsf2:SetFrameStrata("HIGH")
		
		
		
	f.sbf2 = CreateFrame("CheckButton", "SpellbookTab2", SpellBookFrame, "CharacterFrameTabButtonTemplate")
		f.sbf2:SetPoint("TOP", SpellBookFrame, "BOTTOMLEFT", 43, 0)
		f.sbf2:SetSize(100,30)
		f.sbf2:SetText("Spellbook")
		f.sbf2:SetFrameStrata("HIGH")
		
		PanelTemplates_TabResize(TradeskillTab2, 0)
		PanelTemplates_TabResize(SpellbookTab2, 0)


		
	f.tsf2:SetScript("OnClick", TSF_OnClick)
	f.sbf2:SetScript("OnClick", SBF_OnClick)
	f.tsf2:SetScript("OnShow", function()
			f.tsf2:SetChecked(true)
			f.sbf2:SetChecked(false)
		end)
	
		
		

end

--Creates the tradeskill buttons
local function CreateButtons()
	f.tsf = CreateFrame("CheckButton", "TradeskillTab", TradeSkillFrame, "CharacterFrameTabButtonTemplate") --CharacterFrameTabButtonTemplate makes the tabs have a bottom border
		f.tsf:SetPoint("TOP", TradeSkillFrame, "BOTTOMLEFT", 123, 0)
		f.tsf:SetSize(100,30)
		f.tsf:SetText("Professions")
		f.tsf:SetFrameStrata("HIGH")
		
		
		
	f.sbf = CreateFrame("CheckButton", "SpellbookTab", TradeSkillFrame, "CharacterFrameTabButtonTemplate")
		f.sbf:SetPoint("TOP", TradeSkillFrame, "BOTTOMLEFT", 43, 0)
		f.sbf:SetSize(100,30)
		f.sbf:SetText("Spellbook")
		f.sbf:SetFrameStrata("HIGH")
		
		PanelTemplates_TabResize(TradeskillTab, 0)
		PanelTemplates_TabResize(SpellbookTab, 0)


		
	f.tsf:SetScript("OnClick", TSF_OnClick) --recalls the OnClick function for TradeSkillFrame
	f.sbf:SetScript("OnClick", SBF_OnClick) --recalls the OnClick function for SpellBookFrame
	f.tsf:SetScript("OnShow", function()
			f.tsf:SetChecked(true)
			f.sbf:SetChecked(false)
		end)
	
		
		
	
	CreateButtons = nil
end



SpellBookFrame:HookScript("OnShow", function()
		if not f.sbf then
			CreateOtherButtons()
		end
	end)
f:SetScript("OnEvent", function(self, event, addon)
		if addon == "Blizzard_SpellBookFrame" then
			CreateButtons()
			f:UnregisterEvent("ADDON_LOADED")
			CreateButtons = nil
		end
	end)
	
	


f:RegisterEvent("ADDON_LOADED")
	