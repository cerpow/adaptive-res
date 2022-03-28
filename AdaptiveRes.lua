--AdaptiveRes by Cerpow
local UPGRADE_TIMER = 0;
local DOWNGRADE_TIMER = 0;
local SECONDS_TIMER = 0;
local LOGIN_TIMER = 0;
local GUI = CreateFrame("frame","AdaptiveResGUI",UIParent);
GUI:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end);

----------------------
-- Color Functions  --
----------------------
local function AdaptiveRes_GetThresholdPercentage(quality, ...)
	local n = select('#', ...)
	if n <= 1 then
		return AdaptiveRes_GetThresholdPercentage(quality, 0, ... or 1)
	end

	local worst = ...
	local best = select(n, ...)

	if worst == best and quality == worst then
		return 0.5
	end

	if worst <= best then
		if quality <= worst then
			return 0
		elseif quality >= best then
			return 1
		end
		local last = worst
		for i = 2, n-1 do
			local value = select(i, ...)
			if quality <= value then
				return ((i-2) + (quality - last) / (value - last)) / (n-1)
			end
			last = value
		end

		local value = select(n, ...)
		return ((n-2) + (quality - last) / (value - last)) / (n-1)
	else
		if quality >= worst then
			return 0
		elseif quality <= best then
			return 1
		end
		local last = worst
		for i = 2, n-1 do
			local value = select(i, ...)
			if quality >= value then
				return ((i-2) + (quality - last) / (value - last)) / (n-1)
			end
			last = value
		end

		local value = select(n, ...)
		return ((n-2) + (quality - last) / (value - last)) / (n-1)
	end
end

local function AdaptiveRes_GetThresholdColor(quality, ...)

	local inf = 1/0

	if quality ~= quality or quality == inf or quality == -inf then
		return 1, 1, 1
	end

	local percent = AdaptiveRes_GetThresholdPercentage(quality, ...)

	if percent <= 0 then
		return 1, 0, 0
	elseif percent <= 0.5 then
		return 1, percent*2, 0
	elseif percent >= 1 then
		return 0, 1, 0
	else
		return 2 - percent*2, 1, 0
	end
end

local function AdaptiveRes_GetThresholdHexColor(quality, ...)
	local r, g, b = AdaptiveRes_GetThresholdColor(quality, ...)
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

----------------------
--      Enable      --
----------------------
function GUI:PLAYER_LOGIN()
	if not AdaptiveRes_DB then AdaptiveRes_DB = {} end

	if AdaptiveRes_DB.scale == nil then AdaptiveRes_DB.scale = 1 end
	if AdaptiveRes_DB.fpsAdapt == nil then AdaptiveRes_DB.fpsAdapt = 60 end
	if AdaptiveRes_DB.minScale == nil then AdaptiveRes_DB.minScale = 0.55 end
	if AdaptiveRes_DB.maxScale == nil then AdaptiveRes_DB.maxScale = 1 end
	if AdaptiveRes_DB.fontSize == nil then AdaptiveRes_DB.fontSize = 12 end
	if AdaptiveRes_DB.timeDecreaseScale == nil then AdaptiveRes_DB.timeDecreaseScale = 1 end
	if AdaptiveRes_DB.timeIncreaseScale == nil then AdaptiveRes_DB.timeIncreaseScale = 20 end
	if AdaptiveRes_DB.guiEnabled == nil then AdaptiveRes_DB.guiEnabled = true end
	if AdaptiveRes_DB.guiEnabledScale == nil then AdaptiveRes_DB.guiEnabledScale = true end
	if AdaptiveRes_DB.guiEnabledFps == nil then AdaptiveRes_DB.guiEnabledFps = true end
	if AdaptiveRes_DB.guiEnabledHomeLetency == nil then AdaptiveRes_DB.guiEnabledHomeLetency = true end
	if AdaptiveRes_DB.guiEnabledWorldLetency == nil then AdaptiveRes_DB.guiEnabledWorldLetency = true end
	if AdaptiveRes_DB.guiEnabledChatLog == nil then AdaptiveRes_DB.guiEnabledChatLog = false end

	self:drawGUI();
	self:RestoreLayout();
	CreateConfigMenu();
	AdaptiveRes_DB.scale = AdaptiveRes_DB.maxScale;
	SetCVar("renderscale", AdaptiveRes_DB.scale);

	SLASH_AdaptiveRes1 = "/AdaptiveRes";
	SlashCmdList["AdaptiveRes"] = AdaptiveRes_SlashCommand;

	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff3c9df2%s|r |cff1ef407v%s|r is loaded.", "AdaptiveRes", GetAddOnMetadata("AdaptiveRes","Version")))

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

function AdaptiveRes_SlashCommand(cmd)
	InterfaceOptionsFrame_OpenToCategory("AdaptiveRes");
end

local g;
function GUI:drawGUI()
	GUI:SetWidth(30);
	GUI:SetHeight(25);
	GUI:SetMovable(true);
	GUI:SetClampedToScreen(true);
	GUI:SetScale(1);
	GUI:EnableMouse(true);

	GUI:RegisterEvent("PLAYER_ENTERING_WORLD");
	local function eventHandler(self, event, ...)
		LOGIN_TIMER = 0;
	end
	GUI:SetScript("OnEvent", eventHandler);


	g = GUI:CreateFontString("$parentText", "ARTWORK", "GameFontNormalSmall")
	g:SetFont("Fonts\\FRIZQT__.TTF", AdaptiveRes_DB.fontSize);
	g:SetJustifyH("LEFT");
	g:SetPoint("CENTER",0,0);
	g:SetText("");

	GUI:SetScript("OnMouseDown",function(widget, button)
		if (button == "RightButton") then
			InterfaceOptionsFrame_OpenToCategory("AdaptiveRes");
		end

		if (button == "LeftButton" and IsShiftKeyDown()) then
			self.isMoving = true
			self:StartMoving();
	 	end
	end)

	GUI:SetScript("OnMouseUp",function()
		if( self.isMoving ) then

			self.isMoving = nil
			self:StopMovingOrSizing()

			GUI:SaveLayout();

		end
	end)


	GUI:SetScript("OnUpdate", function(self, elapsed)
		UPGRADE_TIMER = UPGRADE_TIMER + elapsed;
		DOWNGRADE_TIMER = DOWNGRADE_TIMER + elapsed;
		SECONDS_TIMER = SECONDS_TIMER + elapsed;
		if LOGIN_TIMER < 6  then LOGIN_TIMER = LOGIN_TIMER + elapsed; end

		local framerate = GetFramerate();
		local framerate_text = format("|cff%s%d|r fps", AdaptiveRes_GetThresholdHexColor(floor(framerate + 0.5) / 60), floor(framerate + 0.5));

		local latencyHome = select(3, GetNetStats());
		local latency_text = format("|cff%s%d|rms", AdaptiveRes_GetThresholdHexColor(latencyHome, 1000, 500, 250, 100, 0), latencyHome);

		local latencyWorld = select(4, GetNetStats());
		local latency_text_server = format("|cff%s%d|r ms", AdaptiveRes_GetThresholdHexColor(latencyWorld, 1000, 500, 250, 100, 0), latencyWorld);

		local rate = floor(framerate / AdaptiveRes_DB.fpsAdapt * 100)/100 + 0.04;


		-- UPGRADE --
		if UPGRADE_TIMER >= AdaptiveRes_DB.timeIncreaseScale then
				if (rate >= 1 and AdaptiveRes_DB.scale < AdaptiveRes_DB.maxScale and LOGIN_TIMER > 5) then
					AdaptiveRes_DB.scale = AdaptiveRes_DB.scale + 0.05;
					SetCVar("renderscale", AdaptiveRes_DB.scale);
					GUI:updateText(framerate_text,latency_text,latency_text_server);
					DOWNGRADE_TIMER = 0;

					if (AdaptiveRes_DB.guiEnabledChatLog) then
						print("Scale up — |cff3c9df2" .. AdaptiveRes_DB.scale * 100 .. "%|r")
					end
				end
			UPGRADE_TIMER = 0;
		end

		-- DOWNGRADE --
		if DOWNGRADE_TIMER >= AdaptiveRes_DB.timeDecreaseScale then
				if (rate < 1 and AdaptiveRes_DB.scale > AdaptiveRes_DB.minScale and LOGIN_TIMER > 5) then
					AdaptiveRes_DB.scale = AdaptiveRes_DB.scale - 0.05;
					SetCVar("renderscale", AdaptiveRes_DB.scale);
					GUI:updateText(framerate_text,latency_text,latency_text_server);
					UPGRADE_TIMER = 0;

					if (AdaptiveRes_DB.guiEnabledChatLog) then
						print("Scale down — |cff3c9df2" .. AdaptiveRes_DB.scale * 100 .. "%|r")
					end
				end
			DOWNGRADE_TIMER = 0;
		end


		--EACH SECOND--
		if (SECONDS_TIMER >= 1) then
			if tonumber(GetCVar("renderscale")) ~= AdaptiveRes_DB.scale then
				SetCVar("renderscale", AdaptiveRes_DB.scale);
			end

			GUI:updateText(framerate_text,latency_text,latency_text_server);
			SECONDS_TIMER = 0;

			--RESIZE FRAME--
			if g:GetStringWidth() > GUI:GetWidth() then
				GUI:SetWidth(g:GetStringWidth() + 20)
			elseif (GUI:GetWidth() - g:GetStringWidth()) > 41 then
				GUI:SetWidth(g:GetStringWidth() + 41)
			end
		end
	end);


	function GUI:updateText(fps,letency_home,letency_world)
		local scale_text, fps_text, letency_home_text, letency_world_text;
		if (AdaptiveRes_DB.guiEnabledScale) then
			if (AdaptiveRes_DB.guiEnabledFps or AdaptiveRes_DB.guiEnabledHomeLetency or AdaptiveRes_DB.guiEnabledWorldLetency) then
				scale_text = "|cff3c9df2".. AdaptiveRes_DB.scale * 100 .."%|r scale • "
			else
				scale_text = "|cff3c9df2".. AdaptiveRes_DB.scale * 100 .."%|r scale"
			end
		else
			scale_text = ""
		end

		if (AdaptiveRes_DB.guiEnabledFps) then
			if (AdaptiveRes_DB.guiEnabledHomeLetency or AdaptiveRes_DB.guiEnabledWorldLetency) then
				fps_text = fps .. " • "
			else
				fps_text = fps
			end
		else
			fps_text = ""
		end

		if (AdaptiveRes_DB.guiEnabledHomeLetency) then
			if (AdaptiveRes_DB.guiEnabledWorldLetency) then
				letency_home_text = "h: " .. letency_home .. " • "
			else
				letency_home_text = "h: " .. letency_home
			end
		else
			letency_home_text = ""
		end
		if (AdaptiveRes_DB.guiEnabledWorldLetency) then letency_world_text = "w: " .. letency_world else letency_world_text = "" end
		g:SetText(scale_text .. fps_text .. letency_home_text .. letency_world_text);
	end


	GUI:Show()
end

function GUI:SaveLayout()
	if not AdaptiveRes_DB then AdaptiveRes_DB = {} end

	local opt = AdaptiveRes_DB["GUI_POSITION"] or nil

	if not opt then
		AdaptiveRes_DB["GUI_POSITION"] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = AdaptiveRes_DB["GUI_POSITION"]
		return
	end

	local point, relativeTo, relativePoint, xOfs, yOfs = GUI:GetPoint()
	opt.point = point
	opt.relativePoint = relativePoint
	opt.xOfs = xOfs
	opt.yOfs = yOfs
end

function GUI:RestoreLayout()
	if not AdaptiveRes_DB then AdaptiveRes_DB = {} end

	local opt = AdaptiveRes_DB["GUI_POSITION"] or nil

	if not opt then
		AdaptiveRes_DB["GUI_POSITION"] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = AdaptiveRes_DB["GUI_POSITION"]
	end

	GUI:ClearAllPoints()
	GUI:SetPoint(opt.point, UIParent, opt.relativePoint, opt.xOfs, opt.yOfs)
end

--------------------------------------
-- Config functions
--------------------------------------
function CreateConfigMenu()
	local ConfigPanel = CreateFrame("FRAME");
	ConfigPanel.name = "AdaptiveRes";
	InterfaceOptions_AddCategory(ConfigPanel);

	local ConfigPanelTitle = ConfigPanel:CreateFontString(nil,"ARTWORK","GameFontNormalLarge");
	ConfigPanelTitle:SetPoint("TOPLEFT",16,-15);
	ConfigPanelTitle:SetText("AdaptiveRes v" .. GetAddOnMetadata("AdaptiveRes","Version"));

	local scaletitle = ConfigPanel:CreateFontString(nil,"ARTWORK","GameFontNormal")
	scaletitle:SetPoint("TOPLEFT",16,-40);
	scaletitle:SetText("Resolution scale settings");

	local GUItitle = ConfigPanel:CreateFontString(nil,"ARTWORK","GameFontNormal")
	GUItitle:SetPoint("TOPLEFT",16,-420);
	GUItitle:SetText("Stats indicator");

	local GUIdescription = ConfigPanel:CreateFontString(nil,"ARTWORK","GameFontNormal")
	GUIdescription:SetTextColor(1,1,1);
	GUIdescription:SetPoint("TOPLEFT",16,-440);
	GUIdescription:SetText("To move the stats indicator, hold down SHIFT then left-click drag to a new position.");

	--SLIDERS--
	local fpsadapt = CreateFrame("Slider", "AdaptiveResFpsAdapt", ConfigPanel, "OptionsSliderTemplate")
	local minscale = CreateFrame("Slider", "AdaptiveResMinScale", ConfigPanel, "OptionsSliderTemplate")
	local maxscale = CreateFrame("Slider", "AdaptiveResMaxScale", ConfigPanel, "OptionsSliderTemplate")
	local decreasescale = CreateFrame("Slider", "AdaptiveRestimeDecreaseScale", ConfigPanel, "OptionsSliderTemplate")
	local increasescale = CreateFrame("Slider", "AdaptiveRestimeIncreaseScale", ConfigPanel, "OptionsSliderTemplate")
	local fontsize = CreateFrame("Slider", "AdaptiveResFontSize", ConfigPanel, "OptionsSliderTemplate")

	-- FONT SIZE --
	fontsize:SetWidth(200)
	fontsize:SetHeight(20)
	fontsize:SetOrientation('HORIZONTAL');
	fontsize:SetPoint("TOPLEFT",380,-500);

	fontsize:SetMinMaxValues(11, 22);
	fontsize:SetValue(AdaptiveRes_DB.fontSize);
	fontsize:RegisterForDrag("LeftButton");
	fontsize:SetValueStep(1);
	fontsize:SetObeyStepOnDrag(true);

	getglobal(fontsize:GetName() .. 'Low'):SetText("11");
	getglobal(fontsize:GetName() .. 'High'):SetText("22");
	getglobal(fontsize:GetName() .. 'Text'):SetText("Font size - |cff3c9df2" .. AdaptiveRes_DB.fontSize .. "pt");
	getglobal(fontsize:GetName() .. 'Text'):SetPoint("LEFT");

	fontsize:SetScript("OnReceiveDrag", function(self, button)
		local n = fontsize:GetValue();
		AdaptiveRes_DB.fontSize = n;
		getglobal(fontsize:GetName() .. 'Text'):SetText("Font size - |cff3c9df2" .. AdaptiveRes_DB.fontSize .. "pt");
		g:SetFont("Fonts\\FRIZQT__.TTF", AdaptiveRes_DB.fontSize);
	end);

	fontsize:SetScript("OnValueChanged", function(self, button)
		local n = fontsize:GetValue();
		AdaptiveRes_DB.fontSize = n;
		getglobal(fontsize:GetName() .. 'Text'):SetText("Font size - |cff3c9df2" .. AdaptiveRes_DB.fontSize .. "pt");
		g:SetFont("Fonts\\FRIZQT__.TTF", AdaptiveRes_DB.fontSize);
	end);


	--FPS to adapt--
	fpsadapt:SetWidth(300)
	fpsadapt:SetHeight(20)
	fpsadapt:SetOrientation('HORIZONTAL');
	fpsadapt:SetPoint("TOPLEFT",16,-80);

	fpsadapt:SetMinMaxValues(20, 200);
	fpsadapt:SetValue(AdaptiveRes_DB.fpsAdapt);
	fpsadapt:RegisterForDrag("LeftButton");
	fpsadapt:SetValueStep(1);
	fpsadapt:SetObeyStepOnDrag(true);

	getglobal(fpsadapt:GetName() .. 'Low'):SetText('20fps');
	getglobal(fpsadapt:GetName() .. 'High'):SetText("200fps");
	getglobal(fpsadapt:GetName() .. 'Text'):SetText("Target FPS - |cff3c9df2" .. AdaptiveRes_DB.fpsAdapt .. "fps|r");
	getglobal(fpsadapt:GetName() .. 'Text'):SetPoint("LEFT");

	fpsadapt:SetScript("OnReceiveDrag", function(self, button)
		local n = fpsadapt:GetValue();
		AdaptiveRes_DB.fpsAdapt = n;
		getglobal(fpsadapt:GetName() .. 'Text'):SetText("Target FPS - |cff3c9df2" .. AdaptiveRes_DB.fpsAdapt .. "fps|r");
	end);

	fpsadapt:SetScript("OnValueChanged", function(self, button)
		local n = fpsadapt:GetValue();
		AdaptiveRes_DB.fpsAdapt = n;
		getglobal(fpsadapt:GetName() .. 'Text'):SetText("Target FPS - |cff3c9df2" .. AdaptiveRes_DB.fpsAdapt .. "fps|r");
	end);

	--MIN SCALE--
	minscale:SetWidth(300)
	minscale:SetHeight(20)
	minscale:SetOrientation('HORIZONTAL');
	minscale:SetPoint("TOPLEFT",16,-150);

	minscale:SetMinMaxValues(30, AdaptiveRes_DB.maxScale * 100);
	minscale:SetValue(AdaptiveRes_DB.minScale * 100);
	minscale:RegisterForDrag("LeftButton");
	minscale:SetValueStep(5);
	minscale:SetObeyStepOnDrag(true);

	getglobal(minscale:GetName() .. 'Low'):SetText('30%');
	getglobal(minscale:GetName() .. 'High'):SetText(AdaptiveRes_DB.maxScale * 100 .. "%");
	getglobal(minscale:GetName() .. 'Text'):SetText("Minimum resolution scale - |cff3c9df2" .. AdaptiveRes_DB.minScale * 100 .. "%|r");
	getglobal(minscale:GetName() .. 'Text'):SetPoint("LEFT");

	minscale:SetScript("OnReceiveDrag", function(self, button)
		local n = minscale:GetValue() / 100;
		AdaptiveRes_DB.minScale = n;
		getglobal(minscale:GetName() .. 'Text'):SetText("Minimum resolution scale - |cff3c9df2" .. AdaptiveRes_DB.minScale * 100 .. "%|r");
		getglobal(maxscale:GetName() .. 'Low'):SetText(AdaptiveRes_DB.minScale * 100 .. "%");
		maxscale:SetMinMaxValues(AdaptiveRes_DB.minScale * 100, 200);

		if (AdaptiveRes_DB.scale < n) then
			AdaptiveRes_DB.scale = n;
			SetCVar("renderscale", n);
		end
	end);

	minscale:SetScript("OnValueChanged", function(self, button)
		local n = minscale:GetValue() / 100;
		AdaptiveRes_DB.minScale = n;
		getglobal(minscale:GetName() .. 'Text'):SetText("Minimum resolution scale - |cff3c9df2" .. AdaptiveRes_DB.minScale * 100 .. "%|r");
		getglobal(maxscale:GetName() .. 'Low'):SetText(AdaptiveRes_DB.minScale * 100 .. "%");
		maxscale:SetMinMaxValues(AdaptiveRes_DB.minScale * 100, 200);

		if (AdaptiveRes_DB.scale < n) then
			AdaptiveRes_DB.scale = n;
			SetCVar("renderscale", n);
			if (AdaptiveRes_DB.guiEnabledChatLog) then
				print("Scale up — |cff3c9df2" .. AdaptiveRes_DB.scale * 100 .. "%|r")
			end
		end
	end);

	--MAX SCALE--
	maxscale:SetWidth(300)
	maxscale:SetHeight(20)
	maxscale:SetOrientation('HORIZONTAL');
	maxscale:SetPoint("TOPLEFT",16,-220);

	maxscale:SetMinMaxValues(AdaptiveRes_DB.minScale * 100, 200);
	maxscale:SetValue(AdaptiveRes_DB.maxScale * 100);
	maxscale:RegisterForDrag("LeftButton");
	maxscale:SetValueStep(5);
	maxscale:SetObeyStepOnDrag(true);

	getglobal(maxscale:GetName() .. 'Low'):SetText(AdaptiveRes_DB.minScale * 100 .. "%");
	getglobal(maxscale:GetName() .. 'High'):SetText('200%');
	getglobal(maxscale:GetName() .. 'Text'):SetText("Maximum resolution scale - |cff3c9df2" .. AdaptiveRes_DB.maxScale * 100 .. "%|r");
	getglobal(maxscale:GetName() .. 'Text'):SetPoint("LEFT");

	maxscale:SetScript("OnReceiveDrag", function(self, button)
		local n = maxscale:GetValue() / 100;
		AdaptiveRes_DB.maxScale = n;
		getglobal(maxscale:GetName() .. 'Text'):SetText("Maximum resolution scale - |cff3c9df2" .. AdaptiveRes_DB.maxScale * 100 .. "%|r");
		getglobal(minscale:GetName() .. 'High'):SetText(AdaptiveRes_DB.maxScale * 100 .. "%");
		minscale:SetMinMaxValues(30, AdaptiveRes_DB.maxScale * 100);

		if (AdaptiveRes_DB.scale > n) then
			AdaptiveRes_DB.scale = n;
			SetCVar("renderscale", n);
		end
	end);

	maxscale:SetScript("OnValueChanged", function(self, button)
		local n = maxscale:GetValue() / 100;
		AdaptiveRes_DB.maxScale = n;
		getglobal(maxscale:GetName() .. 'Text'):SetText("Maximum resolution scale - |cff3c9df2" .. AdaptiveRes_DB.maxScale * 100 .. "%|r");
		getglobal(minscale:GetName() .. 'High'):SetText(AdaptiveRes_DB.maxScale * 100 .. "%");
		minscale:SetMinMaxValues(30, AdaptiveRes_DB.maxScale * 100);

		if (AdaptiveRes_DB.scale > n) then
			AdaptiveRes_DB.scale = n;
			SetCVar("renderscale", n);
			if (AdaptiveRes_DB.guiEnabledChatLog) then
				print("Scale down — |cff3c9df2" .. AdaptiveRes_DB.scale * 100 .. "%|r")
			end
		end
	end);

	--TIME DECREASE SCALE--
	decreasescale:SetWidth(300)
	decreasescale:SetHeight(20)
	decreasescale:SetOrientation('HORIZONTAL');
	decreasescale:SetPoint("TOPLEFT",16,-290);

	decreasescale:SetMinMaxValues(0.5, 10);
	decreasescale:SetValue(AdaptiveRes_DB.timeDecreaseScale);
	decreasescale:RegisterForDrag("LeftButton");
	decreasescale:SetValueStep(0.5);
	decreasescale:SetObeyStepOnDrag(true);

	getglobal(decreasescale:GetName() .. 'Low'):SetText('0.5s');
	getglobal(decreasescale:GetName() .. 'High'):SetText('10s');
	getglobal(decreasescale:GetName() .. 'Text'):SetPoint("LEFT");
	getglobal(decreasescale:GetName() .. 'Text'):SetText("Time to decrease resolution scale - |cff3c9df2" .. AdaptiveRes_DB.timeDecreaseScale .. "sec|r");

	decreasescale:SetScript("OnReceiveDrag", function(self, button)
		local n = decreasescale:GetValue();
		AdaptiveRes_DB.timeDecreaseScale = n;
		getglobal(decreasescale:GetName() .. 'Text'):SetText("Time to decrease resolution scale - |cff3c9df2" .. AdaptiveRes_DB.timeDecreaseScale .. "sec|r");
	end);

	decreasescale:SetScript("OnValueChanged", function(self, button)
		local n = decreasescale:GetValue();
		AdaptiveRes_DB.timeDecreaseScale = n;
		getglobal(decreasescale:GetName() .. 'Text'):SetText("Time to decrease resolution scale - |cff3c9df2" .. AdaptiveRes_DB.timeDecreaseScale .. "sec|r");
	end);

	--TIME INCREASE SCALE--
	increasescale:SetWidth(300)
	increasescale:SetHeight(20)
	increasescale:SetOrientation('HORIZONTAL');
	increasescale:SetPoint("TOPLEFT",16,-360);

	increasescale:SetMinMaxValues(0.5, 60);
	increasescale:SetValue(AdaptiveRes_DB.timeIncreaseScale);
	increasescale:RegisterForDrag("LeftButton");
	increasescale:SetValueStep(0.5);
	increasescale:SetObeyStepOnDrag(true);

	getglobal(increasescale:GetName() .. 'Low'):SetText('0.5s');
	getglobal(increasescale:GetName() .. 'High'):SetText('60s');
	getglobal(increasescale:GetName() .. 'Text'):SetPoint("LEFT");
	getglobal(increasescale:GetName() .. 'Text'):SetText("Time to increase resolution scale - |cff3c9df2" .. AdaptiveRes_DB.timeIncreaseScale .. "sec|r");

	increasescale:SetScript("OnReceiveDrag", function(self, button)
		local n = increasescale:GetValue();
		AdaptiveRes_DB.timeIncreaseScale = n;
		getglobal(increasescale:GetName() .. 'Text'):SetText("Time to increase resolution scale - |cff3c9df2" .. AdaptiveRes_DB.timeIncreaseScale .. "sec|r");
	end);

	increasescale:SetScript("OnValueChanged", function(self, button)
		local n = increasescale:GetValue();
		AdaptiveRes_DB.timeIncreaseScale = n;
		getglobal(increasescale:GetName() .. 'Text'):SetText("Time to increase resolution scale - |cff3c9df2" .. AdaptiveRes_DB.timeIncreaseScale .. "sec|r");
	end);

	--CHECKBOXES
	function createCheckbutton(x_loc, y_loc, varname, displaytext, tooltiptext)
		local checkbutton = CreateFrame("CheckButton", "checkButton_" .. varname, ConfigPanel, "ChatConfigCheckButtonTemplate");
		checkbutton:SetHitRectInsets(0,0,0,0);
		checkbutton:SetPoint("TOPLEFT", x_loc, y_loc);
		_G[checkbutton:GetName() .. "Text"]:SetText(displaytext);
		checkbutton.tooltip = tooltiptext;
		return checkbutton;
	end

	-- Enable GUI --
	local guiEnable = createCheckbutton(16, -470, "guiEnable", "Show stats indicator", "Enable/Disable Stats Indicator. AdaptiveRes will keep adapting resolution in the background.");
	if AdaptiveRes_DB.guiEnabled then guiEnable:SetChecked(true) end
	guiEnable:SetScript("OnClick", function()
		if (AdaptiveRes_DB.guiEnabled) then
			AdaptiveRes_DB.guiEnabled = false;
			GUI:Hide();
		else
			AdaptiveRes_DB.guiEnabled = true;
			GUI:Show();
		end
	end);


	-- Enable GUI Scale --
	local guiEnableScale = createCheckbutton(16, -500, "guiEnableScale", "Show resolution scale", nil);
	if AdaptiveRes_DB.guiEnabledScale then guiEnableScale:SetChecked(true) end
	guiEnableScale:SetScript("OnClick", function()
		if (AdaptiveRes_DB.guiEnabledScale) then
			AdaptiveRes_DB.guiEnabledScale = false;
		else
			AdaptiveRes_DB.guiEnabledScale = true;
		end
	end);

	-- Enable GUI Fps --
	local guiEnableFps = createCheckbutton(180, -500, "guiEnableFps", "Show FPS", nil);
	if AdaptiveRes_DB.guiEnabledFps then guiEnableFps:SetChecked(true) end
	guiEnableFps:SetScript("OnClick", function()
		if (AdaptiveRes_DB.guiEnabledFps) then
			AdaptiveRes_DB.guiEnabledFps = false;
		else
			AdaptiveRes_DB.guiEnabledFps = true;
		end
	end);

	-- Enable GUI Home Letency --
	local guiEnableHomeLetency = createCheckbutton(16, -530, "guiEnableHomeLetency", "Show home letency", nil);
	if AdaptiveRes_DB.guiEnabledHomeLetency then guiEnableHomeLetency:SetChecked(true) end
	guiEnableHomeLetency:SetScript("OnClick", function()
		if (AdaptiveRes_DB.guiEnabledHomeLetency) then
			AdaptiveRes_DB.guiEnabledHomeLetency = false;
		else
			AdaptiveRes_DB.guiEnabledHomeLetency = true;
		end
	end);

	-- Enable GUI World Letency --
	local guiEnableWorldLetency = createCheckbutton(180, -530, "guiEnableWorldLetency", "Show world letency", nil);
	if AdaptiveRes_DB.guiEnabledWorldLetency then guiEnableWorldLetency:SetChecked(true) end
	guiEnableWorldLetency:SetScript("OnClick", function()
		if (AdaptiveRes_DB.guiEnabledWorldLetency) then
			AdaptiveRes_DB.guiEnabledWorldLetency = false;
		else
			AdaptiveRes_DB.guiEnabledWorldLetency = true;
		end
	end);

	-- Enable Chat Log --
	local guiEnableChatLog = createCheckbutton(180, -35, "guiEnableChatLog", "Log events to chat", nil);
	if AdaptiveRes_DB.guiEnabledChatLog then guiEnableChatLog:SetChecked(true) end
	guiEnableChatLog:SetScript("OnClick", function()
		if (AdaptiveRes_DB.guiEnabledChatLog) then
			AdaptiveRes_DB.guiEnabledChatLog = false;
			DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff3c9df2%s|r — Chat log disabled.", "AdaptiveRes"))
		else
			AdaptiveRes_DB.guiEnabledChatLog = true;
			DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff3c9df2%s|r — Chat log enabled.", "AdaptiveRes"))
		end
	end);

	--BUTTONS--
	function CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text)
		local btn = CreateFrame("Button", nil, relativeFrame, "GameMenuButtonTemplate");
		btn:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset);
		btn:SetSize(120,20);
		btn:SetText(text);
		btn:SetNormalFontObject("GameFontNormal");
		btn:SetHighlightFontObject("GameFontHighlight");
		return btn;
	end

	local resetbtn = CreateButton("RIGHT", ConfigPanel, "TOP", 290, -30, "Reset settings")

	resetbtn:SetScript("OnClick", function()
		AdaptiveRes_DB.scale = 1
		SetCVar("renderscale", AdaptiveRes_DB.scale);

		AdaptiveRes_DB.fpsAdapt = 60
		fpsadapt:SetValue(AdaptiveRes_DB.fpsAdapt);
		getglobal(fpsadapt:GetName() .. 'Text'):SetText("Target FPS - |cff3c9df260fps|r");

		AdaptiveRes_DB.minScale = 0.55
		minscale:SetValue(AdaptiveRes_DB.minScale * 100);
		getglobal(minscale:GetName() .. 'Text'):SetText("Minimum resolution scale - |cff3c9df255%|r");
		getglobal(maxscale:GetName() .. 'Low'):SetText(AdaptiveRes_DB.minScale * 100 .. "%");
		maxscale:SetMinMaxValues(AdaptiveRes_DB.minScale * 100, 200);

		AdaptiveRes_DB.maxScale = 1
		maxscale:SetValue(AdaptiveRes_DB.maxScale * 100);
		getglobal(maxscale:GetName() .. 'Text'):SetText("Maximum resolution scale - |cff3c9df2100%|r");
		getglobal(minscale:GetName() .. 'High'):SetText(AdaptiveRes_DB.maxScale * 100 .. "%");
		minscale:SetMinMaxValues(30, AdaptiveRes_DB.maxScale * 100);

		AdaptiveRes_DB.timeDecreaseScale = 1
		decreasescale:SetValue(AdaptiveRes_DB.timeDecreaseScale);
		getglobal(decreasescale:GetName() .. 'Text'):SetText("Time to decrease resolution scale - |cff3c9df21sec|r");

		AdaptiveRes_DB.timeIncreaseScale = 20
		increasescale:SetValue(AdaptiveRes_DB.timeIncreaseScale);
		getglobal(increasescale:GetName() .. 'Text'):SetText("Time to increase resolution scale - |cff3c9df220sec|r");

		AdaptiveRes_DB.guiEnabled = true
		GUI:Show();
		guiEnable:SetChecked(true)

		AdaptiveRes_DB.guiEnabledScale = true
		guiEnableScale:SetChecked(true)

		AdaptiveRes_DB.guiEnabledFps = true
		guiEnableFps:SetChecked(true)

		AdaptiveRes_DB.guiEnabledHomeLetency = true
		guiEnableHomeLetency:SetChecked(true)

		AdaptiveRes_DB.guiEnabledWorldLetency = true
		guiEnableWorldLetency:SetChecked(true)

		AdaptiveRes_DB.guiEnabledChatLog = false
		guiEnableChatLog:SetChecked(false)

		AdaptiveRes_DB["GUI_POSITION"] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}

		GUI:RestoreLayout();

		print("|cff3c9df2AdaptiveRes|r — All settings has been reset.")
	end);
end

if IsLoggedIn() then GUI:PLAYER_LOGIN() else GUI:RegisterEvent("PLAYER_LOGIN") end
