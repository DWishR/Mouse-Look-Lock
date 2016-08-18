--[[------------------------------------------------------------
	Mouse Look v6.0
	
	By Trimble Epic
	
	This mod allows a button to be mapped to allow
	WoW to simulate the Mouselook mode found in DAoC.
	
	The code below is a work-around for the
	way WoW handles it's mouse controlled camera functions
	
	Revision History
	6.0 Nov 13 '14  Updated TOC for use with 6.0
	5.1 Aug 11 '14  Updated TOC for use with 5.4
			Also added many new user interface windows to automatically pop up cursor.

	5.0 Aug 29 '12  Updated TOC for use with 5.0.4 Mists of Pandaria

	4.0 Oct 12 '10  Updated the addon to fix some code issues.  Blizzard removed "this", as well as
			a few other "features" like values passed as "arg1" in XML code.  I also updated
			the TOC for use with 4.0.1
	3.2 Aug 16 '09
			Updated TOC for use with 3.2
	3.1 Apr 15 '09
			Updated TOC for use with 3.1
	2.2 Oct 14 '08
			Updated TOC for use with 3.0.2
	2.1 Aug 4 '08
			Updated TOC for use with 2.4
			Fixed bug associated with sRaidFrames (wouldn't return to mouselook mode)
			Fixed bug so that mouselook setting is started when entering the world
	1.6 Nov 3
			Updated TOC for use with patch 1.12
	1.5 Mar 29
			Updated TOC for use with patch 1.10
			Changed essential functions used to engage and disengage mouselook to comply with new 1.10 rules
	1.4	Jun 20
			Updated TOC for use with version 1500 of game client
	1.3	Feb 22
			Updated TOC for use with version 4216 of game client
	1.2	Feb 15
			Updated TOC for use with version 4211 of game client
			Reworked Lua file to contain all code internally to reduce stray code in bindings.xml
			Reworked bindings.xml to be cleaner and leaner
			Added some code in an attempt to fix 'walklock' issue.
	1.1	I wasn't keeping track of changes prior to 1.2, but it should be sufficient to say that
			1.1 was pretty much a stable release.

	Todo notes:
	Implement MouseOverFrame function and increase update speed
	
--------------------------------------------------------------]]

local Version = '6.0'
local Debugging = false
local MouseLook_TempLockout = false
local MouseLook_LastUpdate = 0
local MouseLook_UpdateFrequency = 0.2  ---> Adjust this number UP to improve frame rate.

BINDING_HEADER_MouseLook            = 'MouseLook'
BINDING_NAME_MouseLook_mode_toggle  = "MouseLook toggle" -- are these needed?
BINDING_NAME_MouseLook_momentary    = "MouseLook momentary"


--List of frames that should automatically undo mouselook while they are up
local MouseLook_FramesToCheck = {
	"AuctionFrame",       "BankFrame",          "BattlefieldFrame",   "CharacterFrame",
	"ChatMenu",           "EmoteMenu",          "LanguageMenu",       "VoiceMacroMenu",
	"ClassTrainerFrame",  "CoinPickupFrame",    "CraftFrame",         "FriendsFrame",
	"GameMenuFrame",      "GossipFrame",        "GuildRegistrarFrame","HelpFrame",
	"InspectFrame",       "KeyBindingFrame",    "LoXXXotFrame",       "MacroFrame",
	"MailFrame",          "MerchantFrame",      "OptionsFrame",       "PaperDollFrame",
	"PetPaperDollFrame",  "PetRenamePopup",     "PetStable",          "QuestFrame",
	"QuestLogFrame",      "RaidFrame",          "ReputationFrame",    "ScriptErrors",
	"SkillFrame",         "SoundOptionsFrame",  "SpellBookFrame",     "StackSplitFrame",
	"StatsFrame",         "SuggestFrame",       "TabardFrame",        "TalentFrame",
	"TalentTrainerFrame", "TaxiFrame",          "TradeFrame",         "TradeSkillFrame",
	"TutorialFrame",      "UIOptionsFrame",     "UnitPopup",          "WorldMapFrame",
	"CosmosMasterFrame",  "CosmosDropDown",     "ChooseItemsFrame",   "ImprovedErrorFrame",
	"TicTacToeFrame",     "OthelloFrame",       "MinesweeperFrame",   "GamesListFrame",
	"ConnectFrame",       "ChessFrame",         "QuestShareFrame",    "TotemStomperFrame",
	"StaticPopXXXup1",       "StaticPopup2",       "StaticPopup3",       "StaticPopup4",
	"DropDownList1",      "DropDownList2",      "DropDownList3",      "WantAds",
	"CosmosDropDownBis",  "InventoryManagerFrame", "InspectPaperDollFrame",
	"ContainerFrame1",    "ContainerFrame2", "ContainerFrame3", "ContainerFrame4",
	"ContainerFrame5",    "ContainerFrame6",    "ContainerFrame7",    "ContainerFrame8",
	"ContainerFrame9",    "ContainerFrame10",   "ContainerFrame11",   "ContainerFrame12",
	"ContainerFrame13",   "ContainerFrame14",   "ContainerFrame15",   "ContainerFrame16",
	"ContainerFrame17",   "AutoPotion_Template_Dialog","NxSocial",    "ARKINV_Frame1",
	"AchievementFrame",   "LookingForGuildFrame", "PVPUIFrame",       "GuildFrame",
	"WorldMapFrame",      "VideoOptionsFrame",  "InterfaceOptionsFrame",
        "ACP_AddonList",      "PlayerTalentFrame",  "PVEFrame",           "EncounterJournal",
	"PetJournalParent",   "AccountantFrame", 
	"GarrisonLandingPage", "GarrisonMissionFrame", "GarrisonBuildingFrame",
	--   "NxMap1",  (carbonite's world map breaks mouselook)
	-- "StoreFrame", (causes taint??!??  wtf, blizzard?)
	}

--List of frames that mouse might be over (Yes, these could badly use some cleanup)
local MouseLook_FramesToCheckForMouse = {
	"BonusActionBarFrame",
	"BuffFrame",
	"CastingBarFrame",
	"ChatFrameMenuButton", "ChatFrameEditBox",
	"ChatFrame1Tab", "ChatFrame2Tab", "ChatFrame3Tab", "ChatFrame4Tab", "ChatFrame5Tab", "ChatFrame6Tab", "ChatFrame7Tab",
	"ChatFrame1BottomButton", "ChatFrame2BottomButton", "ChatFrame3BottomButton", "ChatFrame4BottomButton", "ChatFrame5BottomButton", "ChatFrame6BottomButton", "ChatFrame7BottomButton",
	"ChatFrame1DownButton", "ChatFrame2DownButton", "ChatFrame3DownButton", "ChatFrame4DownButton", "ChatFrame5DownButton", "ChatFrame6DownButton", "ChatFrame7DownButton",
	"ChatFrame1UpButton", "ChatFrame2UpButton", "ChatFrame3UpButton", "ChatFrame4UpButton", "ChatFrame5UpButton", "ChatFrame6UpButton", "ChatFrame7UpButton",
	"CoinPickupFrame",
	"ColorPickerFrame",
	"DialogBoxFrame",
	"DurabilityFrame",
	"GameTimeFrame",
	"ItemTextFrame",
	"MainMenuBar",
	"MinimapCluster",
	"PartyFrame",
	"PetActionBarFrame", "PetFrame", "PetitionFrame",
	"PlayerFrame",
	"QuestTimerFrame",
	"TargetFrame",
	"UnitFrame",
	"AutoFollowStatus",
	"SecondBar",
	"ClockFrame",
	"CosmosTooltip",
	"CombatStatsDataFrame",
	"CombatStatsFrame",
	"DPSPLUS_PlayerFrame",
	"ItemBuffBar",
	"ItemBuffButton1", "ItemBuffButton2", "ItemBuffButton3", "ItemBuffButton4", "ItemBuffButton5", "ItemBuffButton6",
	"KillCountFrame", "KillCountFrame2",
	"InventoryManagerTooltip",
	"MonitorStatus",
	"SideBar", "SideBar2",
	"TargetDistanceFrame",
	"TargetStatsTooltip",
	"HealomaticMainFrame",
	}

local function ML_debug(...)
	
	if not DEFAULT_CHAT_FRAME or not Debugging then return end
	
	local msg = ''
	
	for k,v in ipairs(arg) do
		
		msg = msg .. tostring(v) .. ' : '
		
	end
	
	DEFAULT_CHAT_FRAME:AddMessage(msg)
	
end

local function Print(text)
	
	if not DEFAULT_CHAT_FRAME then return end
	
	DEFAULT_CHAT_FRAME:AddMessage(text)
	
end

local function UnmouseableFrameOnScreen()
	
	for index in pairs(MouseLook_FramesToCheck) do
		
		local curFrame = getglobal(MouseLook_FramesToCheck[index])
		if (curFrame and curFrame:IsVisible()) then
			--ML_debug("Frame on screen : " .. MouseLook_FramesToCheck[index])
			return true
		end
		
	end
	
end

local function MouseIsOverFrame()
	
	for index in pairs(MouseLook_FramesToCheckForMouse) do
		
		local curFrameName = MouseLook_FramesToCheckForMouse[index]
		local curFrame = getglobal(curFrameName)
		
		if  curFrame
		and curFrame:IsVisible() then
			
			local xPos, yPos = GetCursorPosition()
			
			local top    = curFrame:GetTop()    * UIParent:GetScale() + 10
			local right  = curFrame:GetRight()  * UIParent:GetScale() + 10
			local left   = curFrame:GetLeft()   * UIParent:GetScale() - 10
			local bottom = curFrame:GetBottom() * UIParent:GetScale() - 10
			
			if string.find(curFrameName, "ChatFrame") then
				top = top + 10
				left = left - 10
			end
			
			if  xPos and yPos
			and left and right
			and top  and bottom then
				
				if  (xPos >= left)
				and (xPos <= right)
				and (yPos >= bottom)
				and (yPos <= top) then
					
					--ML_debug("Mouse is over frame : " .. curFrameName)
					return true
					
				end
				
			end
			
		end
		
	end
	
end


function MouseLook_OnUpdate(self,elapsed,...)
	
	
	MouseLook_LastUpdate = MouseLook_LastUpdate + elapsed
	
	if (MouseLook_LastUpdate >= MouseLook_UpdateFrequency) then
		
		MouseLook_LastUpdate = 0
		
		if MouseLookOn
		and not MouseLook_MomentaryPointer then
			
			if CursorHasItem()
			or SpellIsTargeting()
			or UnmouseableFrameOnScreen()
			or MouseIsOverFrame() then
				
				if not MouseLook_TempLockout then
					
					--IsMouselooking() -- also for mouselook tools ;)
					MouselookStop()
					--Print("MouselookStop()")
					--SetBinding("BUTTON1","CAMERAORSELECTORMOVE")
					--SetBinding("BUTTON2","TURNORACTION")
					MouseLook_TempLockout = true
					
					
				end
				
			else
				
				if MouseLook_TempLockout then
					
					MouselookStart()
					--Print("MouselookStart()")
					--SetBinding("BUTTON1","MOVEBACKWARD")
					--SetBinding("BUTTON2","MOVEFORWARD")
					MouseLook_TempLockout = false
					
				end
				
			end
			
		end
		
	end
	
end

function MouseLook_Toggle()
	
	if not MouseLookOn then
		
		MouselookStart()
		--SetBinding("BUTTON1","MOVEBACKWARD")
		--SetBinding("BUTTON2","MOVEFORWARD")
		MouseLookOn = true
		
	else
		
		MouselookStop()
		--SetBinding("BUTTON1","CAMERAORSELECTORMOVE")
		--SetBinding("BUTTON2","TURNORACTION")
		MouseLookOn = false
		
		
	end
	
end

local oldMouseDown
local oldMouseUp
local mouse_button_down

local function status(bool)
	
	if bool then return "true" else return "false" end
	
end

function MouseLook_Momentary(keystate)
	
	if MouseLookOn then
		
		if ( keystate == "down" ) then
			
			MouselookStop()
			--Print("MouselookStop()")
			--SetBinding("BUTTON1","CAMERAORSELECTORMOVE")
			--SetBinding("BUTTON2","TURNORACTION")
			MouseLook_MomentaryPointer = true
			--Print("Down")
			
		else
			
			--if mouse_button_down then
				
			--	waiting_to_reset = true
			--	Print("1")
			--else
				
				if not MouseLook_TempLockout then
					
					MouselookStart()
					--Print("MouselookStart()")
					--SetBinding("BUTTON1","MOVEBACKWARD")
					--SetBinding("BUTTON2","MOVEFORWARD")
					--Print("2")
				else
					--Print("3")
					
				end
				
				MouseLook_MomentaryPointer = false
				
			--end
			--Print("up")
			
		end
		
	end
	
end


function MouseLook_OnLoad(self,...)
	
	MouseLookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	MouseLookFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	MouseLookFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	
	oldMouseDown=WorldFrame:GetScript("OnMouseDown")
	oldMouseUp = WorldFrame:GetScript("OnMouseUp")
	WorldFrame:SetScript("OnMouseDown",MouseDown)
	WorldFrame:SetScript("OnMouseUp",MouseUp)
	
	SetMouselookOverrideBinding("BUTTON1", "MOVEBACKWARD") 
	SetMouselookOverrideBinding("BUTTON2", "MOVEFORWARD") 
	--Print("on load")
end;


function MouseDown(...)
-- need to determine WHICH mousebutton is down.  it's in arg2.   how do I read it?  i forgot.  actually, it doesn't really matter anymore.
	
	if mouse_button_down then
		
		--both_buttons_down = true
		--Print("MouseDown() mouse_button_down true")
		
	else
		
		mouse_button_down = true
		--Print("MouseDown() mouse_button_down false")
		
	end
	
	if oldMouseDown then oldMouseDown(args) end
	
end

function MouseUp(...)
	
	if both_buttons_down then
		
		both_buttons_down = false
		--Print("MouseUp() both_buttons_down true")
		
	else
		
		mouse_button_down = false
		--Print("MouseUp() both_buttons_down false")
		if waiting_to_reset then
			
			MouseLook_TempLockout = true
			
			MouseLook_MomentaryPointer = false
			
			waiting_to_reset = false
			
		end
		
	end
	
	if oldMouseUp then oldMouseUp(args) end
	
end

function MouseLook_OnEvent(self,event,...)
	
	--Print("on event:" ..event)
	
	if event == "PLAYER_ENTERING_WORLD" then
		
		--Print("PLAYER_ENTERING_WORLD event")
		
		if MouseLookOn then
			
			--Print("Trying to automatically start Mouselook")
			MouselookStart()
			--Print("MouselookStart()")
			--SetBinding("BUTTON1","MOVEBACKWARD")
			--SetBinding("BUTTON2","MOVEFORWARD")
			
		end
		
	end
	
	if event == "PLAYER_REGEN_DISABLED" then
		
		if MouseLookOn then
			
			--SetBinding("BUTTON1","CAMERAORSELECTORMOVE")
			--SetBinding("BUTTON2","TURNORACTION")
			
		end
		
	end
	
	if event == "PLAYER_REGEN_ENABLED" then
		
		if MouseLookOn then
			
			--SetBinding("BUTTON1","MOVEBACKWARD")
			--SetBinding("BUTTON2","MOVEFORWARD")
			
		end
		
	end
	
end
