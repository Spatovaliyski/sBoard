local ServicesBoard = _G.ServicesBoard

function ServicesBoard:CreateScrollBox()
	-- Create modern container with profession-style background
	local container = CreateFrame("Frame", nil, self.frame)
	container:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 12, -70)
	container:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -15, 40)

	-- Add the modern background texture using the same atlas as Crafting Orders
	local background = container:CreateTexture(nil, "BACKGROUND")
	self:SetTextureAtlas(background, "auctionhouse-background-index", { 0.1, 0.1, 0.1, 0.9 })
	background:SetPoint("TOPLEFT", container, "TOPLEFT", 3, -2)
	background:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -5, 0)

	-- Create modern frame border using NineSlice
	local borderFrame = CreateFrame("Frame", nil, container, "NineSlicePanelTemplate")
	borderFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
	borderFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)

	-- Set up the nine slice to use InsetFrameTemplate style
	local nineSlice = borderFrame.NineSlice or borderFrame
	if nineSlice.SetupTextureKit then
		nineSlice:SetupTextureKit("InsetFrame")
	else
		-- Fallback for older versions
		nineSlice.layoutType = "InsetFrameTemplate"
		if nineSlice.SetBorderBlendMode then
			nineSlice:SetBorderBlendMode("BLEND")
		end
		if nineSlice.SetCenterColor then
			nineSlice:SetCenterColor(0, 0, 0, 0.5)
		end
	end

	-- Use traditional ScrollFrame but with modern styling
	local scrollFrame = CreateFrame("ScrollFrame", "ServicesBoardScrollFrame", container, "ScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", background, "TOPLEFT", 2, -2)
	scrollFrame:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", -17, 2)

	-- Create scroll child for content
	local scrollChild = CreateFrame("Frame", "ServicesBoardScrollChild")
	scrollChild:SetSize(scrollFrame:GetWidth() - 4, 1) -- Height will be set dynamically
	scrollFrame:SetScrollChild(scrollChild)

	-- Reference for compatibility
	local scrollBox = scrollFrame

	-- Use the existing scrollbar from ScrollFrameTemplate and style it modernly
	local scrollBar = scrollFrame.ScrollBar
	if scrollBar then
		-- Modern scrollbar positioning and styling
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -2, -2)
		scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 0, 3)
		scrollBar:SetWidth(12)

		-- Try to apply modern scrollbar styling if available
		if scrollBar.SetThumbTexture then
			-- Keep the modern look but use traditional functionality
		end

		-- Only initialize with ScrollUtil if it's available and safe
		if ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar then
			-- Initialize callback registry first if needed
			if CallbackRegistryMixin and not scrollBar.RegisterCallback then
				Mixin(scrollBar, CallbackRegistryMixin)
				CallbackRegistryMixin.OnLoad(scrollBar)
			end
		end
	else
		-- Fallback: create our own scrollbar
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

		-- Connect scrollframe to scrollbar
		scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
			scrollBar:SetValue(offset)
		end)

		scrollFrame.ScrollBar = scrollBar
	end

	-- Store references with modern naming
	self.scrollFrame = scrollFrame
	self.scrollBox = scrollBox
	self.scrollChild = scrollChild
	self.scrollBar = scrollBar
	self.container = container
	self.background = background
end
