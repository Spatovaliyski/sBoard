local ServicesBoard = {}
_G.ServicesBoard = ServicesBoard

function ServicesBoard:InitDB()
	self.db = self.db or ServicesBoardDB or {}
	self.FRAME_WIDTH = 600
	self.FRAME_HEIGHT = 500
	ServicesBoardDB = self.db
end

function ServicesBoard:Init()
	self:InitDB()
	self.messages = self.messages or {}
	self.playerLastPost = self.playerLastPost or {}
	self.cooldown = 300
	self:CreateMainFrame()
	self:CreateScrollBox()
	self:RegisterEvents()
	self:RegisterSlashCommands()
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

function ServicesBoard:HasModernTextures()
	return C_Texture and C_Texture.GetAtlasInfo and type(C_Texture.GetAtlasInfo) == "function"
end

function ServicesBoard:SetTextureAtlas(textureObject, atlasName, fallbackColor)
	if not textureObject then
		return false
	end

	if self:HasModernTextures() and C_Texture.GetAtlasInfo(atlasName) then
		textureObject:SetAtlas(atlasName)
		return true
	else
		if fallbackColor then
			textureObject:SetColorTexture(fallbackColor[1], fallbackColor[2], fallbackColor[3], fallbackColor[4] or 1.0)
		end
		return false
	end
end

function ServicesBoard:RegisterEvents()
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
	eventFrame:SetScript("OnEvent", function(_, event, text, author, _, _, _, _, channelName)
		self:OnChatMsgChannel(text, author, channelName)
	end)
end

function ServicesBoard:RegisterSlashCommands()
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
