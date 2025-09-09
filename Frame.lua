local ServicesBoard = _G.ServicesBoard

function ServicesBoard:CreateMainFrame()
	local f = CreateFrame("Frame", "ServicesBoardFrame", UIParent, "PortraitFrameTemplate")
	f:SetSize(self.FRAME_WIDTH, self.FRAME_HEIGHT)
	f:SetPoint("CENTER")
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:Hide()

	-- Use a more modern profession-style icon
	f.PortraitContainer.portrait:SetTexture("Interface\\Icons\\ui_profession_engineering")
	f.TitleContainer.TitleText:SetText("Services Board")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)

	-- Keep the original PortraitFrameTemplate background - don't modify it to maintain proper opacity

	-- Esc key closes the frame
	f:SetScript("OnShow", function(self)
		table.insert(UISpecialFrames, self:GetName())
	end)
	f:SetScript("OnHide", function(self)
		for i, frameName in ipairs(UISpecialFrames) do
			if frameName == self:GetName() then
				table.remove(UISpecialFrames, i)
				break
			end
		end
	end)

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
