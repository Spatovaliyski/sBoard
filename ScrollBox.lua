local ServicesBoard = _G.ServicesBoard

function ServicesBoard:CreateScrollBox()
	local inset = CreateFrame("Frame", nil, self.frame, "InsetFrameTemplate")
	inset:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 12, -70)
	inset:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -15, 40)

	-- Create modern ScrollFrame compatible with ScrollUtil
	local scrollFrame = CreateFrame("ScrollFrame", "ServicesBoardScrollFrame", inset, "ScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", inset, "TOPLEFT", 4, -4)
	scrollFrame:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -26, 4)

	local scrollChild = CreateFrame("Frame", "ServicesBoardScrollChild")
	scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
	scrollFrame:SetScrollChild(scrollChild)

	local scrollBar = scrollFrame.ScrollBar
	if scrollBar then
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, -8)
		scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 6, 8)
		scrollBar:SetWidth(12)
		if not scrollBar.SetScrollPercentage then
			scrollBar.SetScrollPercentage = function(self, percentage, interpolationMode)
				local minVal, maxVal = self:GetMinMaxValues()
				local value = minVal + (percentage * (maxVal - minVal))
				self:SetValue(value)
			end
		end

		if not scrollBar.SetVisibleExtentPercentage then
			scrollBar.SetVisibleExtentPercentage = function(self, percentage)
				if self.SetThumbTexture then
					local height = self:GetHeight() * math.max(0.1, percentage)
					if self.ThumbTexture then
						self.ThumbTexture:SetHeight(height)
					end
				end
			end
		end

		if not scrollBar.SetPanExtentPercentage then
			scrollBar.SetPanExtentPercentage = function(self, percentage)
				self.panExtentPercentage = percentage
			end
		end

		if not scrollBar.ScrollStepInDirection then
			scrollBar.ScrollStepInDirection = function(self, direction)
				local currentScroll = scrollFrame:GetVerticalScroll()
				local scrollRange = scrollFrame:GetVerticalScrollRange()
				local step = (scrollFrame.GetPanExtent and scrollFrame:GetPanExtent()) or 30

				local newScroll = currentScroll + (direction * step)
				newScroll = math.max(0, math.min(scrollRange, newScroll))
				scrollFrame:SetVerticalScroll(newScroll)
			end
		end

		if not scrollBar.RegisterCallback and CallbackRegistryMixin then
			Mixin(scrollBar, CallbackRegistryMixin)
			CallbackRegistryMixin.OnLoad(scrollBar)
		end

		if ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar then
			ScrollUtil.InitScrollFrameWithScrollBar(scrollFrame, scrollBar)
		end
	end

	self.scrollFrame = scrollFrame
	self.scrollChild = scrollChild
	self.scrollBar = scrollBar
	self.inset = inset
end
