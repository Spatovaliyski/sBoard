local ServicesBoard = _G.ServicesBoard

function ServicesBoard:RefreshUI()
	if not self.scrollChild then
		return
	end

	local currentScroll = self.scrollFrame:GetVerticalScroll()
	local maxScroll = self.scrollFrame:GetVerticalScrollRange()
	local wasAtBottom = (maxScroll == 0) or (currentScroll >= maxScroll - 5)

	local children = { self.scrollChild:GetChildren() }
	for _, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
	end

	local yOffset = -10
	local entryHeight = 60
	for i = #self.messages, 1, -1 do
		local msg = self.messages[i]
		local entry = CreateFrame("Frame", nil, self.scrollChild)
		entry:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 10, yOffset)
		entry:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT", -10, yOffset)
		entry:SetHeight(entryHeight)
		entry:EnableMouse(true)

		local playerName = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		playerName:SetPoint("TOPLEFT", entry, "TOPLEFT", 0, 0)
		local shortName = msg.author:match("^([^%-]+)") or msg.author
		local r, g, b = self:GetClassColor(msg.author)
		playerName:SetText(shortName)
		playerName:SetTextColor(r, g, b)

		local timestamp = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		timestamp:SetPoint("TOPRIGHT", entry, "TOPRIGHT", 0, 0)
		timestamp:SetText(date("%H:%M", msg.time))
		timestamp:SetTextColor(0.7, 0.7, 0.7)

		if msg.channel and msg.channel ~= "" then
			local channelName = self:GetChannelName(msg.channel)
			if channelName then
				local channel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
				channel:SetPoint("TOPLEFT", playerName, "TOPRIGHT", 5, -2)
				channel:SetText("(" .. channelName .. ")")
				channel:SetTextColor(0.8, 0.8, 0.8)
			end
		end

		local messageBox = CreateFrame("Frame", nil, entry)
		messageBox:SetPoint("TOPLEFT", entry, "TOPLEFT", 0, -18)
		messageBox:SetPoint("TOPRIGHT", entry, "TOPRIGHT", 0, -18)

		local bgTexture = messageBox:CreateTexture(nil, "BACKGROUND")
		if not self:SetTextureAtlas(bgTexture, "Professions-background-summarylist", { 0.1, 0.1, 0.1, 0.8 }) then
			self:SetTextureAtlas(bgTexture, "auctionhouse-background-index", { 0.1, 0.1, 0.1, 0.8 })
		end
		bgTexture:SetAllPoints(messageBox)
		if bgTexture:GetAtlas() then
			bgTexture:SetVertexColor(0.1, 0.1, 0.1, 0.8)
		end

		local borderFrame = CreateFrame("Frame", nil, messageBox, "NineSlicePanelTemplate")
		borderFrame:SetAllPoints(messageBox)
		local nineSlice = borderFrame.NineSlice or borderFrame
		if nineSlice.SetupTextureKit then
			nineSlice:SetupTextureKit("Professions")
		else
			local border = messageBox:CreateTexture(nil, "BORDER")
			border:SetAllPoints(messageBox)
			border:SetColorTexture(0.3, 0.3, 0.3, 0.4)
			local inset = messageBox:CreateTexture(nil, "ARTWORK")
			inset:SetPoint("TOPLEFT", border, "TOPLEFT", 1, -1)
			inset:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -1, 1)
			inset:SetColorTexture(0.0, 0.0, 0.0, 0.6)
		end

		local messageText = CreateFrame("SimpleHTML", nil, messageBox)
		messageText:SetFrameLevel(messageBox:GetFrameLevel() + 1)
		messageText:SetPoint("TOPLEFT", messageBox, "TOPLEFT", 12, -12)
		messageText:SetPoint("TOPRIGHT", messageBox, "TOPRIGHT", -12, -12)
		messageText:SetHeight(1)

		local availableWidth = entry:GetWidth() - 16
		messageText:SetWidth(availableWidth)
		messageText:SetScript("OnHyperlinkClick", function(self, linkData, link, button)
			SetItemRef(linkData, link, button)
		end)
		messageText:SetScript("OnHyperlinkEnter", function(self, linkData, link)
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
			GameTooltip:SetHyperlink(linkData)
		end)
		messageText:SetScript("OnHyperlinkLeave", function(self)
			GameTooltip:Hide()
		end)

		messageText:SetFont("p", "Fonts\\FRIZQT__.TTF", 11, "")
		messageText:SetJustifyH("p", "LEFT")
		messageText:SetSpacing("p", 3)
		messageText:SetText(self:MakeLinksClickable(msg.text))

		local textHeight = messageText:GetContentHeight()
		local messageBoxHeight = textHeight + 24
		local actualHeight = 18 + messageBoxHeight + 8

		entry:SetHeight(actualHeight)
		messageBox:SetHeight(messageBoxHeight)
		messageText:SetHeight(textHeight)

		local highlight = messageBox:CreateTexture(nil, "HIGHLIGHT")
		self:SetTextureAtlas(highlight, "auctionhouse-ui-row-highlight", { 1, 1, 1, 0.15 })
		highlight:SetAllPoints(messageBox)
		highlight:SetBlendMode("ADD")
		highlight:Hide()

		entry:SetScript("OnEnter", function(self)
			highlight:Show()
		end)
		entry:SetScript("OnLeave", function(self)
			highlight:Hide()
		end)

		local whisperClicked = false
		entry:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				whisperClicked = true
			end
		end)
		entry:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" and whisperClicked then
				ChatFrame_OpenChat("/w " .. msg.author .. " ")
			end
			whisperClicked = false
		end)

		messageText:SetScript("OnMouseDown", function(self, button)
			whisperClicked = false
		end)

		yOffset = yOffset - actualHeight - 8
	end

	local totalHeight = math.abs(yOffset) + 20
	self.scrollChild:SetHeight(totalHeight)

	if self.scrollFrame.GetScrollChild then
		self.scrollFrame:GetScrollChild():SetHeight(totalHeight)
	end

	C_Timer.After(0.1, function()
		if self.scrollFrame then
			if self.scrollFrame.UpdateScrollChildRect then
				self.scrollFrame:UpdateScrollChildRect()
			end

			if wasAtBottom then
				self.scrollFrame:SetVerticalScroll(0)
			else
				local newMaxScroll = self.scrollFrame:GetVerticalScrollRange()
				if newMaxScroll > 0 and maxScroll > 0 then
					local scrollRatio = currentScroll / maxScroll
					self.scrollFrame:SetVerticalScroll(scrollRatio * newMaxScroll)
				end
			end
		end
	end)
end
