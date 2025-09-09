local ServicesBoard = _G.ServicesBoard

function ServicesBoard:CreateScrollBox()
	local container = CreateFrame("Frame", nil, self.frame)
	container:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 12, -70)
	container:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -15, 40)

	local background = container:CreateTexture(nil, "BACKGROUND")
	self:SetTextureAtlas(background, "auctionhouse-background-index", { 0.1, 0.1, 0.1, 0.9 })
	background:SetPoint("TOPLEFT", container, "TOPLEFT", 3, -2)
	background:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -5, 0)

	local borderFrame = CreateFrame("Frame", nil, container, "NineSlicePanelTemplate")
	borderFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
	borderFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)

	local nineSlice = borderFrame.NineSlice or borderFrame
	if nineSlice.SetupTextureKit then
		nineSlice:SetupTextureKit("InsetFrame")
	else
		nineSlice.layoutType = "InsetFrameTemplate"
		if nineSlice.SetBorderBlendMode then
			nineSlice:SetBorderBlendMode("BLEND")
		end
		if nineSlice.SetCenterColor then
			nineSlice:SetCenterColor(0, 0, 0, 0.5)
		end
	end

	local scrollFrame = CreateFrame("ScrollFrame", "ServicesBoardScrollFrame", container, "ScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", background, "TOPLEFT", 2, -2)
	scrollFrame:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", -17, 2)

	local scrollChild = CreateFrame("Frame", "ServicesBoardScrollChild")
	scrollChild:SetSize(scrollFrame:GetWidth() - 4, 1)
	scrollFrame:SetScrollChild(scrollChild)

	local scrollBox = scrollFrame

	local scrollBar = scrollFrame.ScrollBar
	if scrollBar then
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -2, -2)
		scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 0, 3)
		scrollBar:SetWidth(12)

		if ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar then
			if CallbackRegistryMixin and not scrollBar.RegisterCallback then
				Mixin(scrollBar, CallbackRegistryMixin)
				CallbackRegistryMixin.OnLoad(scrollBar)
			end
		end
	else
		scrollBar = CreateFrame("Slider", "ServicesBoardScrollBar", container, "UIPanelScrollBarTemplate")
		scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -2, -2)
		scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 0, 3)
		scrollBar:SetWidth(12)
		scrollBar:SetMinMaxValues(0, 0)
		scrollBar:SetValueStep(1)
		scrollBar:SetValue(0)
		scrollBar:SetScript("OnValueChanged", function(self, value)
			scrollFrame:SetVerticalScroll(value)
		end)

		scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
			scrollBar:SetValue(offset)
		end)

		scrollFrame.ScrollBar = scrollBar
	end

	self.scrollFrame = scrollFrame
	self.scrollBox = scrollBox
	self.scrollChild = scrollChild
	self.scrollBar = scrollBar
	self.container = container
	self.background = background
end
