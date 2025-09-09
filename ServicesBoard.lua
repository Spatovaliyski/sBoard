local ServicesBoard = {}

function ServicesBoard:InitDB()
	self.db = self.db or ServicesBoardDB or {}
	self.FRAME_WIDTH = 700
	self.FRAME_HEIGHT = 500
	ServicesBoardDB = self.db
end

function ServicesBoard:CreateMainFrame()
	local f = CreateFrame("Frame", "ServicesBoardFrame", UIParent, "PortraitFrameTemplate")
	f:SetSize(self.FRAME_WIDTH, self.FRAME_HEIGHT)
	f:SetPoint("CENTER")
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:Hide()

	f.PortraitContainer.portrait:SetTexture("Interface\\Icons\\Trade_Engineering")
	f.TitleContainer.TitleText:SetText("Services Board")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)

	-- Clear Button
	local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	clearBtn:SetSize(80, 22)
	clearBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 15)
	clearBtn:SetText("Clear All")
	clearBtn:SetScript("OnClick", function()
		wipe(self.messages)
		wipe(self.playerLastPost)
		self:RefreshUI()
	end)

	self.frame = f
end

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

function ServicesBoard:Init()
	self:InitDB()
	self.messages = self.messages or {}
	self.playerLastPost = self.playerLastPost or {}
	self.cooldown = 300
	self:CreateMainFrame()
	self:CreateScrollBox()

	-- Event handler
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
	eventFrame:SetScript("OnEvent", function(_, event, text, author, _, _, _, _, channelName)
		self:OnChatMsgChannel(text, author, channelName)
	end)

	-- Slash command
	SLASH_SERVICESBOARD1 = "/sboard"
	SlashCmdList["SERVICESBOARD"] = function()
		if self.frame:IsShown() then
			self.frame:Hide()
		else
			self.frame:Show()
			self:RefreshUI()
		end
	end
end

function ServicesBoard:IsDuplicate(author, text)
	for _, msg in ipairs(self.messages) do
		if msg.author == author and msg.text == text then
			return true
		end
	end
	return false
end

function ServicesBoard:OnChatMsgChannel(text, author, channelName)
	local now = time()
	if self.playerLastPost[author] and (now - self.playerLastPost[author] < self.cooldown) then
		return
	end
	if not self:IsDuplicate(author, text) then
		table.insert(self.messages, { author = author, text = text, time = now, channel = channelName })
		self.playerLastPost[author] = now
		if self.frame:IsShown() then
			self:RefreshUI()
		end
	end
end

function ServicesBoard:GetClassColor(name)
	if not name then
		return 0.3, 0.6, 1
	end
	local _, class = UnitClass(name)
	if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
		local c = RAID_CLASS_COLORS[class]
		return c.r, c.g, c.b
	end
	return 0.3, 0.6, 1
end

function ServicesBoard:GetChannelName(channelNumber)
	-- Convert channel number to readable name
	if not channelNumber or channelNumber == "" then
		return nil
	end

	local channelNum = tonumber(channelNumber)
	if not channelNum then
		return channelNumber
	end

	local channelNames = {
		[1] = "General",
		[2] = "Trade",
		[3] = "LocalDefense",
		[4] = "LookingForGroup",
		[5] = "WorldDefense",
		[42] = "Services",
		[50] = "Services",
	}

	return channelNames[channelNum] or ("Ch" .. channelNum)
end

function ServicesBoard:MakeLinksClickable(text)
	return text
end

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

		local background = entry:CreateTexture(nil, "BACKGROUND")
		background:SetAllPoints()
		background:SetColorTexture(1, 1, 1, 0.05)

		local border = CreateFrame("Frame", nil, entry, "BackdropTemplate")
		border:SetAllPoints()
		border:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 8,
		})
		border:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.9)

		local playerName = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		playerName:SetPoint("TOPLEFT", entry, "TOPLEFT", 8, -8)
		local shortName = msg.author:match("^([^%-]+)") or msg.author
		local r, g, b = self:GetClassColor(msg.author)
		playerName:SetText(shortName)
		playerName:SetTextColor(r, g, b)

		local timestamp = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		timestamp:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -8, -8)
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

		local messageText = CreateFrame("SimpleHTML", nil, entry)
		messageText:SetPoint("TOPLEFT", playerName, "BOTTOMLEFT", 0, -4)
		messageText:SetPoint("TOPRIGHT", timestamp, "BOTTOMRIGHT", -8, -4)
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
		local actualHeight = math.max(entryHeight, 35 + textHeight)
		entry:SetHeight(actualHeight)
		messageText:SetHeight(textHeight)
		local highlight = entry:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetAllPoints()
		highlight:SetColorTexture(1, 1, 1, 0.1)
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

-- Initialize
ServicesBoard:Init()
