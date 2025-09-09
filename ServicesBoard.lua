local ServicesBoard = {}

function ServicesBoard:InitDB()
	self.db = self.db or ServicesBoardDB or {}
	-- Fixed size like Adventure Guide - no more resizing
	self.FRAME_WIDTH = 700
	self.FRAME_HEIGHT = 500
	ServicesBoardDB = self.db
end

function ServicesBoard:CreateMainFrame()
	-- Use PortraitFrameTemplate like Adventure Guide for modern look
	local f = CreateFrame("Frame", "ServicesBoardFrame", UIParent, "PortraitFrameTemplate")
	f:SetSize(self.FRAME_WIDTH, self.FRAME_HEIGHT)
	f:SetPoint("CENTER")
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:Hide()

	-- Set up portrait icon
	f.PortraitContainer.portrait:SetTexture("Interface\\Icons\\Trade_Engineering")

	-- Set title
	f.TitleContainer.TitleText:SetText("Services Board")

	-- Dragging (simplified)
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
	inset:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -35, 40)

	-- Create modern ScrollFrame compatible with ScrollUtil
	local scrollFrame = CreateFrame("ScrollFrame", "ServicesBoardScrollFrame", inset, "ScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", inset, "TOPLEFT", 4, -4)
	scrollFrame:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -23, 4)

	-- Create scroll child
	local scrollChild = CreateFrame("Frame", "ServicesBoardScrollChild")
	scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
	scrollFrame:SetScrollChild(scrollChild)

	-- Use the built-in scrollbar from ScrollFrameTemplate and enhance it
	local scrollBar = scrollFrame.ScrollBar
	if scrollBar then
		-- Position the scrollbar nicely
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, -16)
		scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 6, 16)
		scrollBar:SetWidth(12)

		-- Add the methods that ScrollUtil needs
		if not scrollBar.SetScrollPercentage then
			scrollBar.SetScrollPercentage = function(self, percentage, interpolationMode)
				-- Convert percentage to slider value
				local minVal, maxVal = self:GetMinMaxValues()
				local value = minVal + (percentage * (maxVal - minVal))
				self:SetValue(value)
			end
		end

		if not scrollBar.SetVisibleExtentPercentage then
			scrollBar.SetVisibleExtentPercentage = function(self, percentage)
				-- Handle visible extent for scroll bar thumb sizing
				if self.SetThumbTexture then
					-- Adjust thumb size based on visible extent
					local height = self:GetHeight() * math.max(0.1, percentage)
					if self.ThumbTexture then
						self.ThumbTexture:SetHeight(height)
					end
				end
			end
		end

		if not scrollBar.SetPanExtentPercentage then
			scrollBar.SetPanExtentPercentage = function(self, percentage)
				-- Handle pan extent for scroll stepping
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

		-- Ensure the scrollbar has callback registry support
		if not scrollBar.RegisterCallback and CallbackRegistryMixin then
			Mixin(scrollBar, CallbackRegistryMixin)
			CallbackRegistryMixin.OnLoad(scrollBar)
		end

		-- Initialize with ScrollUtil
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

function ServicesBoard:MakeLinksClickable(text)
	-- Make achievement links clickable
	return text:gsub("(|c%x%x%x%x%x%x%x%x|H(achievement:[^|]+)|h%[[^%]]+%]|h|r)", "|cff00ff00|H%2|h[Achievement]|h|r")
end

function ServicesBoard:RefreshUI()
	if not self.scrollChild then
		return
	end

	-- Clear existing children
	local children = { self.scrollChild:GetChildren() }
	for _, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
	end

	local yOffset = -10
	local entryHeight = 60 -- Base height per entry

	-- Create entries for each message
	for i, msg in ipairs(self.messages) do
		local entry = CreateFrame("Frame", nil, self.scrollChild)
		entry:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 10, yOffset)
		entry:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT", -10, yOffset)
		entry:SetHeight(entryHeight)
		entry:EnableMouse(true)

		-- Player name
		local playerName = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		playerName:SetPoint("TOPLEFT", entry, "TOPLEFT", 0, -8)
		local shortName = msg.author:match("^([^%-]+)") or msg.author
		local r, g, b = self:GetClassColor(msg.author)
		playerName:SetText(shortName)
		playerName:SetTextColor(r, g, b)

		-- Timestamp
		local timestamp = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		timestamp:SetPoint("TOPRIGHT", entry, "TOPRIGHT", 0, -8)
		timestamp:SetText(date("%H:%M", msg.time))
		timestamp:SetTextColor(0.7, 0.7, 0.7)

		-- Channel
		if msg.channel and msg.channel ~= "" then
			local channel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			channel:SetPoint("TOPLEFT", playerName, "TOPRIGHT", 5, 0)
			channel:SetText("(" .. msg.channel .. ")")
			channel:SetTextColor(0.8, 0.8, 0.8)
		end

		-- Message text
		local messageText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		messageText:SetPoint("TOPLEFT", playerName, "BOTTOMLEFT", 0, -4)
		messageText:SetPoint("TOPRIGHT", timestamp, "BOTTOMRIGHT", 0, -4)
		messageText:SetJustifyH("LEFT")
		messageText:SetWordWrap(true)
		messageText:SetText(self:MakeLinksClickable(msg.text))

		-- Adjust entry height based on text
		local textHeight = messageText:GetStringHeight()
		local actualHeight = math.max(entryHeight, 30 + textHeight)
		entry:SetHeight(actualHeight)

		-- Divider
		local divider = entry:CreateTexture(nil, "ARTWORK")
		divider:SetColorTexture(0.3, 0.3, 0.3, 0.8)
		divider:SetPoint("BOTTOMLEFT", entry, "BOTTOMLEFT", 0, 2)
		divider:SetPoint("BOTTOMRIGHT", entry, "BOTTOMRIGHT", 0, 2)
		divider:SetHeight(1)

		-- Hover effect
		local highlight = entry:CreateTexture(nil, "BACKGROUND")
		highlight:SetAllPoints()
		highlight:SetColorTexture(1, 1, 1, 0.1)
		highlight:Hide()

		entry:SetScript("OnEnter", function(self)
			highlight:Show()
		end)
		entry:SetScript("OnLeave", function(self)
			highlight:Hide()
		end)

		-- Click to whisper
		entry:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" then
				ChatFrame_OpenChat("/w " .. msg.author .. " ")
			end
		end)

		yOffset = yOffset - actualHeight - 5
	end

	-- Set scroll child height and update scroll range
	local totalHeight = math.abs(yOffset) + 20
	self.scrollChild:SetHeight(totalHeight)

	-- Force scroll range update
	if self.scrollFrame.GetScrollChild then
		self.scrollFrame:GetScrollChild():SetHeight(totalHeight)
	end

	-- Auto-scroll to bottom for new messages with proper range update
	C_Timer.After(0.1, function()
		if self.scrollFrame then
			-- Update scroll range first
			if self.scrollFrame.UpdateScrollChildRect then
				self.scrollFrame:UpdateScrollChildRect()
			end

			-- Then scroll to bottom
			local maxScroll = self.scrollFrame:GetVerticalScrollRange()
			if maxScroll > 0 then
				self.scrollFrame:SetVerticalScroll(maxScroll)
			end
		end
	end)
end

-- Initialize
ServicesBoard:Init()
