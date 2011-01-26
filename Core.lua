--[[----------------------------------------------------------------------------------
	NazScrooge Core addon
	Note: Ace3 addons can register for the event "MONEY_MODIFIED" in order to update their displays with the new getmoney() amount once it's been modified
	
	TODO:   
           
	Compatibility with: (note: those with ? after them have not been tested by me and therefor not verified)
		Combuctor
		ArkInventory
		Auditor2
		FuBar_AuditorFu
		Broker_Money
		Baggins?
		BagginsAnywhereBags?
		Sanity2?
		MoneyDetailFu?
		OneBag?
		SanityBags?
		AllPlayed?
		MoneyFu?
		Moolah?
		StatBlock_Money?
------------------------------------------------------------------------------------]]

NazScrooge = LibStub("AceAddon-3.0"):NewAddon("NazScrooge", "LibSink-2.0", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("NazScrooge")
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:NewDataObject("NazScrooge", {
    type = "data source",
    icon = "Interface\\Icons\\INV_Misc_Coin_02",
    OnClick = function(clickedframe, button)
        InterfaceOptionsFrame_OpenToCategory(NazScrooge.optionsframe)
    end,
	text = "NazScrooge",
})

local sessionsaved = 0
local starttime = 0
local verbosemin = false
local verbosemax = false
local verbosepct = false

local function GetAvgSaved()
    if sessionsaved == 0 then return 0 end
    return sessionsaved/((time() - starttime)/3600)
end

local function round(num, idp)
	local mult = 10^(idp or 2)
	return math.floor(num * mult + 0.5) / mult
end

local function makedisplay(copper, display)
    if NazScrooge.db.profile.sinkOptions.sink20OutputSink == "Channel" and not display then
		return GetDenominationsFromCopper(copper)
    else
        return GetCoinTextureString(copper, 16)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
	* Flashes the edge of the screen when called
    * Lifted directly from Omen2, thank you Antiarc
------------------------------------------------------------------------------------]]
function NazScrooge:Flash()
	if not self.FlashFrame then
		local flasher = CreateFrame("Frame", "ScroogeFlashFrame")
		flasher:SetToplevel(true)
		flasher:SetFrameStrata("FULLSCREEN_DIALOG")
		flasher:SetAllPoints(UIParent)
		flasher:EnableMouse(false)
		flasher:Hide()
		flasher.texture = flasher:CreateTexture(nil, "BACKGROUND")
		flasher.texture:SetTexture("Interface\\FullScreenTextures\\LowHealth")
		flasher.texture:SetAllPoints(UIParent)
		flasher.texture:SetBlendMode("ADD")
        flasher.texture:SetGradientAlpha("HORIZONTAL",1,1,0,1,.5,1,0,1)
		flasher:SetScript("OnShow", function(self)
			self.elapsed = 0
			self:SetAlpha(0)
		end)
		flasher:SetScript("OnUpdate", function(self, elapsed)
			elapsed = self.elapsed + elapsed
			if elapsed < 2.6 then
				local alpha = elapsed % .65
				if alpha < 0.15 then
					self:SetAlpha(alpha / 0.15)
				elseif alpha < 0.9 then
					self:SetAlpha(1 - (alpha - 0.15) / 0.6)
				else
					self:SetAlpha(0)
				end
			else
				self:Hide()
			end
			self.elapsed = elapsed
		end)
		self.FlashFrame = flasher
	end

	self.FlashFrame:Show()
end

function NazScrooge:ReachedGoal()
    PlaySoundFile("Interface\\AddOns\\NazScrooge\\sounds\\ApplauseShortened.mp3")
    NazScrooge:Flash()
    NazScrooge:Pour(L["CONGRATULATIONS!!"])
    NazScrooge:Pour(string.format(L["You have reached your goal of %s."], makedisplay(NazScrooge.db.char.target)))
	NazScrooge.db.char.targettoggle = false
	if NazScrooge.db.char.targetclear then
		NazScrooge.db.profile.flattoggle = false
		NazScrooge.db.profile.maxtoggle = false
		NazScrooge.db.profile.percenttoggle = false
	end
end

local function CheckGoal()
    if NazScrooge.db.char.targettoggle and NazScrooge.db.char.target <= NazScrooge.db.char.savedcopper then
        NazScrooge:ReachedGoal()
        NazScrooge.db.char.targettoggle = false
    end
end

function dataobj:OnTooltipShow()
    self:AddLine(dataobj.tooltiptext)
end

function dataobj:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
    GameTooltip:ClearLines()
    dataobj.OnTooltipShow(GameTooltip)
    GameTooltip:Show()
end

function dataobj:OnLeave()
    GameTooltip:Hide()
end

local function Refresh_LDB()
    dataobj.text = makedisplay(NazScrooge.db.char.savedcopper, true)
    dataobj.tooltiptext = string.format(L["You have %s in your bag"], makedisplay(GetMoney() - GetCursorMoney()), true) .. "\n" .. string.format(L["You have %s in your lockbox"], makedisplay(NazScrooge.db.char.savedcopper), true) .. "\n" .. string.format(L["You are saving %s per hour"], makedisplay(GetAvgSaved(), true))
end

--[[----------------------------------------------------------------------------------
	Notes:
	* Refreshes displays (bag, etc.)
------------------------------------------------------------------------------------]]
local function Refresh_Display()

    CheckGoal()
    
    Refresh_LDB()
    -- Blizz frames
    
	if (IsBagOpen(0)) then
		for i=1, NUM_CONTAINER_FRAMES, 1 do
			local frame = getglobal("ContainerFrame"..i)
			if ( frame:IsVisible() and (frame:GetID() == 0) ) then
				MoneyFrame_Update("ContainerFrame"..i.."MoneyFrame", GetMoney() - GetCursorMoney())
				break
			end
		end
	end
    
    local frame = GetUIPanel("left")
    if (frame ~= nil) then
        local name = frame:GetName()
		if (name == "MerchantFrame") then
			MoneyFrame_Update("MerchantMoneyFrame", GetMoney() - GetCursorMoney())
			MerchantFrame_Update()
		elseif (name == "BankFrame") then
			MoneyFrame_Update("BankFrameMoneyFrame", GetMoney() - GetCursorMoney())
			UpdateBagSlotStatus()
		elseif (name == "MailFrame") then
			MoneyFrame_Update("SendMailMoneyFrame", GetMoney() - GetCursorMoney())
			SendMailFrame_Update();
		elseif (name == "ClassTrainerFrame" and MoneyFrame_Update) then
			MoneyFrame_Update("ClassTrainerMoneyFrame", GetMoney() - GetCursorMoney())
			ClassTrainer_SelectFirstLearnableSkill()
			ClassTrainerFrame_Update()
		end
	end

    frame = GetUIPanel("center")
    if (frame ~= nil) then
        local name = frame:GetName()
		if (name == "MerchantFrame") then
			MoneyFrame_Update("MerchantMoneyFrame", GetMoney() - GetCursorMoney());
			MerchantFrame_Update();
		elseif (name == "BankFrame") then
			MoneyFrame_Update("BankFrameMoneyFrame", GetMoney() - GetCursorMoney());
			UpdateBagSlotStatus();
		elseif (name == "MailFrame") then
			MoneyFrame_Update("SendMailMoneyFrame", GetMoney() - GetCursorMoney());
			SendMailFrame_Update();
		elseif (name == "ClassTrainerFrame") then
			MoneyFrame_Update("ClassTrainerMoneyFrame", GetMoney() - GetCursorMoney());
			ClassTrainer_SelectFirstLearnableSkill();		
			ClassTrainerFrame_Update();		
		end
	end
    
    frame = GetUIPanel("doublewide")
    if (frame ~= nil) then
        local name = frame:GetName()
		if (name == "AuctionFrame") then
			MoneyFrame_Update("AuctionFrameMoneyFrame", GetMoney() - GetCursorMoney());
			AuctionFrameBid_Update();
			AuctionFrameBrowse_Update();
		end
	end
    
    --addon frames/updates
    
    if Auditor and Auditor.UpdateFigures then
        Auditor:UpdateFigures() 
    end
    
    if AuditorFu then
        AuditorFu:UpdateDisplay()
    end  
    
    if Baggins then
        Baggins:UpdateMoneyFrame()
    end
    
    if MoneyDetailFu then
        MoneyDetailFu:MoneyChanged()
    end
    
    if BagginsAnywhereBags then
        BagginsAnywhereBags:FullProcess()
    end
    
    if Sanity then
        Sanity:Refresh()
    end  
    
    if Moolah then
        Moolah:PLAYER_MONEY()
    end
    
    if SB_MONEY then
        SB_MONEY:UpdateBlock()
    end
	
	if Money and Money.Update then
		Money:Update()
	end
    
    if AllPlayed then
        AllPlayed:EventHandler()
    end
    
    if MoneyFu then
        MoneyFu:UpdateData()
        MoneyFu:UpdateText()
    end
    
    if ArkInventory then
        for i=1, 6, 1 do
            local frame = getfenv()[ArkInventory.Const.Frame.Main.Name .. i]
            ArkInventory.Frame_Main_Update(frame)
        end
    end
	
	if Combuctor and Combuctor.frames and Combuctor.frames[1] and Combuctor.frames[1].moneyFrame.Update then
		Combuctor.frames[1].moneyFrame:Update()
	end
		
	NazScrooge:SendMessage("MONEY_MODIFIED")
	
end

--[[----------------------------------------------------------------------------------
	Notes:
	* Adds the amount (in copper) given to the saved lockbox
    
    Returns true if it's able to add the entire amount, false if it can only add some
------------------------------------------------------------------------------------]]
local function addmoney(amount)
    amount = amount or 0
    if tonumber(NazScrooge.db.char.savedcopper) + tonumber(amount) > NazScrooge.hooks.GetMoney() then
        sessionsaved = sessionsaved + (tonumber(NazScrooge.db.char.savedcopper) + tonumber(amount) - NazScrooge.db.char.savedcopper)
        NazScrooge.db.char.savedcopper = NazScrooge.hooks.GetMoney()
        Refresh_Display()
        return false
    end
    sessionsaved = sessionsaved + amount
    NazScrooge.db.char.savedcopper = tonumber(NazScrooge.db.char.savedcopper) + tonumber(amount)
    return true
end

--[[----------------------------------------------------------------------------------
	Notes:
	* removes the amount (in copper) given to the saved lockbox
    
    Returns true if it's able to remove the entire amount, the amount it can remove
    if it can only remove some
------------------------------------------------------------------------------------]]
local function removemoney(amount)
    amount = amount or 0
    NazScrooge.db.char.savedcopper = tonumber(NazScrooge.db.char.savedcopper) - tonumber(amount)
    sessionsaved = sessionsaved - amount
    if NazScrooge.db.char.savedcopper < 0 then
        local diff = NazScrooge.db.char.savedcopper
        NazScrooge.db.char.savedcopper = 0
        sessionsaved = sessionsaved + diff
        return amount + diff
    end
    return true
end

local options = {
    name = "NazScrooge",
    handler = NazScrooge,
    type = 'group',
    childGroups = "tab",
    args = {
        options = {
            type = 'group',
            desc = L["Lockbox Options"],
            name = L["Lockbox Options"],
            order = 10,
            args = {
                percent = {
                    type = 'toggle',
                    name = L["Keep Percent"],
                    desc = L["Should I set aside a percent of the money you make?"],
                    get = function()
                                return NazScrooge.db.profile.percenttoggle
                            end,
                    set = function(info, newValue)
                                NazScrooge.db.profile.percenttoggle = newValue
                            end,
                    order = 30,
                },
                keeppercent = {
                    type = 'input',
                    name = L["Percentage of earnings to set aside."],
                    desc = L["What percent of earnings should I set aside for you?"],
                    usage = L["<just the percent>"],
                    disabled = function()
                                    return not NazScrooge.db.profile.percenttoggle
                                end,
                    get = function()
                                return tostring(NazScrooge.db.profile.keeppercent)
                            end,
                    set = function(info, newValue)
                                newValue = newValue or 0
                                NazScrooge.db.profile.keeppercent = tonumber(newValue)
                            end,
                    order = 31,
                },
                toggletarget = {
                    type = 'toggle',
                    name = L["Target"],
                    desc = L["Are you saving to a specific goal amount?"],
                    get = function()
                                return NazScrooge.db.char.targettoggle
                            end,
                    set = function(info, newValue)
                                NazScrooge.db.char.targettoggle = newValue
                            end,
                    order = 28,
                },
                target = {
                    type = 'input',
                    name = L["Target amount."],
                    desc = L["What is the target amount you are trying to save?"],
                    usage = L["<number in gold>"],
                    disabled = function()
                                    return not NazScrooge.db.char.targettoggle
                                end,
                    get = function()
                                return tostring(NazScrooge.db.char.target/10000)
                            end,
                    set = function(info, newValue)
                                newValue = newValue or 0
                                NazScrooge.db.char.target = tonumber(newValue)*10000
                            end,
                    order = 29,
                },
				targetclear = {
					type = 'toggle',
					name = L["Quit saving when you reach target?"],
					desc = L["When enabled, deselects all saving options once you reach the target amount"],
					disabled = function()
										return not NazScrooge.db.char.targettoggle
									end,
					get = function()
                                return NazScrooge.db.char.targetclear
                            end,
                    set = function(info, newValue)
                                NazScrooge.db.char.targetclear = newValue
                            end,
                    order = 30,
				},
                min = {
                    type = 'toggle',
                    name = L["Minimum"],
                    desc = L["Should I set aside a minimum amount of money?"],
                    get = function()
                                return NazScrooge.db.profile.flattoggle
                            end,
                    set = function(info, newValue)
                                NazScrooge.db.profile.flattoggle = newValue
                            end,
                    order = 35,
                },
                minamount = {
                    type = 'input',
                    name = L["Minimum amount to set aside."],
                    desc = L["What's the minimum should I set aside for you?"],
                    usage = L["<number in gold>"],
                    disabled = function()
                                    return not NazScrooge.db.profile.flattoggle
                                end,
                    get = function()
                                return tostring(NazScrooge.db.profile.keepamount)
                            end,
                    set = function(info, newValue)
                                newValue = newValue or 0
                                NazScrooge.db.profile.keepamount = tonumber(newValue)
                                if NazScrooge.db.char.savedcopper < NazScrooge.db.profile.keepamount*10000 then
                                    NazScrooge.db.char.savedcopper = NazScrooge.db.profile.keepamount*10000
                                end
                            end,
                    order = 36,
                },
                max = {
                    type = 'toggle',
                    name = L["Maximum"],
                    desc = L["Should I set aside money after you reach a certain amount?"],
                    get = function()
                                return NazScrooge.db.profile.maxtoggle
                            end,
                    set = function(info, newValue)
                                NazScrooge.db.profile.maxtoggle = newValue
                            end,
                    order = 40,
                },
                maxamount = {
                    type = 'input',
                    name = L["Maximum gold to keep available"],
                    desc = L["What's the max gold amount you want available to spend?"],
                    usage = L["<number in gold>"],
                    disabled = function()
                                    return not NazScrooge.db.profile.maxtoggle
                                end,
                    get = function()
                                return tostring(NazScrooge.db.profile.maxamount)
                            end,
                    set = function(info, newValue)
                                newValue = newValue or 0
                                NazScrooge.db.profile.maxamount = tonumber(newValue)
                            end,
                    order = 41,
                },
            },
        },
		deposit = {
			type = 'input',
			name = L["Deposit"],
			desc = L["What amount would you like to Deposit to your lockbox?"],
            usage = L["<number in gold>"],
			get = false,
			set = function(info, newValue)
                        newValue = newValue or 0
                        oldvalue = NazScrooge.db.char.savedcopper
						if addmoney(newValue*10000) then
                            NazScrooge:Pour(string.format(L["You now have %s in your lockbox"], makedisplay(NazScrooge.db.char.savedcopper)))
                        else
                            NazScrooge:Pour(string.format(L["You tried to deposit more money than you have! Deposited %s."], makedisplay(NazScrooge.hooks.GetMoney() - oldvalue)))
                            NazScrooge:Pour(string.format(L["You now have %s in your lockbox"], makedisplay(NazScrooge.db.char.savedcopper)))
                        end
                        Refresh_Display()
					end,
			order = 21,
		},
		withdraw = {
			type = 'input',
			name = L["Withdraw"],
			desc = L["What amount would you like to Withdraw from your lockbox?"],
            usage = L["<number in gold>"],
			get = false,
			set = function(info, newValue)
                        newValue = newValue or 0
                        local removed = removemoney(newValue*10000)
						if removed == true then
                            NazScrooge:Pour(string.format(L["You have %s in your lockbox"], makedisplay(NazScrooge.db.char.savedcopper)))
                        else
                            NazScrooge:Pour(string.format(L["You tried to take out more money than you had saved.  Withrew the balance of %s."], makedisplay(removed)))
                        end   
                        Refresh_Display()
					end,
			order = 22,
		},
		display = {
			type = 'execute',
			name = L["Display"],
			desc = L["Display the gold in your lockbox"],
			func = function()
						NazScrooge:Pour(string.format(L["You have %s in your lockbox"], makedisplay(NazScrooge.db.char.savedcopper)))
						NazScrooge:Pour(string.format(L["You are saving %s per hour"], makedisplay(GetAvgSaved())))
					end,
			order = 20,
		},
		output = {
		},
        verbose = {
            type = 'toggle',
            name = L["Verbose Output"],
            desc = L["Would you like verbose output each time you make money?"],
			get = function()
						return NazScrooge.db.profile.verbose
					end,
			set = function(info, newValue)
						NazScrooge.db.profile.verbose = newValue
					end,
			order = 25,
		}
	},
}

local t1
local lasttotal --running total

--Reusable functions

--[[----------------------------------------------------------------------------------
	Notes:
	* Returns money amount in copper, or gold if arg1 == true
------------------------------------------------------------------------------------]]
local function GetBoxMoney(gold)
    if gold then
        return NazScrooge.db.char.savedcopper/10000
    else
        return NazScrooge.db.char.savedcopper --return the amount of money in box
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
	* Checks to see if you have at least the amount given
------------------------------------------------------------------------------------]]
local function checktotal(price)
    price = price or 0
    if price >  GetMoney() then
        NazScrooge:Pour(L["You do not have enough money to do that."])
        return false
    else
        return true
    end
end

--Hooked functions

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of GetMoney
	* Returns money amount
------------------------------------------------------------------------------------]]
function NazScrooge:GetMoney(...)
    local money = self.hooks.GetMoney(...) --get the real value
    money = money - GetBoxMoney() --remove the amount of money in box
    if money < 0 then money = 0 end --don't show a negative value
    return round(money, 0)  -- return the value minus what we are keeping
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyMerchantItem
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:BuyMerchantItem(index, qty, ...)
    local x, x, price = GetMerchantItemInfo(index)
    if qty ~= nil then price = price * qty end
    if checktotal(price) then
        return self.hooks.BuyMerchantItem(index, qty, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyMerchantItem
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:BuybackItem(index, ...)
    local x, x, price = GetBuybackItemInfo(index)
    if checktotal(price) then
        return self.hooks.BuybackItem(index, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of RepairAllItems
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:RepairAllItems(gb, ...)
    local price = GetRepairAllCost()
    if checktotal(price) or gb == 1 then
        return self.hooks.RepairAllItems(gb, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyGuildBankTab
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:BuyGuildBankTab(...)
    local price = GetGuildBankTabCost()
    if checktotal(price) then
        return self.hooks.BuyGuildBankTab(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyGuildCharter
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:BuyGuildCharter(...)
    local price = GetGuildCharterCost()
    if checktotal(price) then
        return self.hooks.BuyGuildCharter(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyStableSlot
	* Makes sure you have enough non-hidden money and then passes or blocks depending
	
	** Removed due to 4.x changes
	
function NazScrooge:BuyStableSlot(...)
    local price = GetNextStableSlotCost()
    if checktotal(price) then
        return self.hooks.BuyStableSlot(...)
    end
end	
------------------------------------------------------------------------------------]]

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyPetition
	* Makes sure you have enough non-hidden money and then passes or blocks depending
	
	** Removed due to 4.x changes
	
function NazScrooge:BuyPetition(index, ...)
    local x, x, price = GetPetitionItemInfo(index)
    if checktotal(price) then
        return self.hooks.BuyPetition(index, ...)
    end
end
------------------------------------------------------------------------------------]]

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyTrainerService
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:BuyTrainerService(index, ...)
    local price = GetTrainerServiceCost(index)
    if checktotal(price) then
        return self.hooks.BuyTrainerService(index, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of PickupInventoryItem
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:PickupInventoryItem(index, ...)
    if InRepairMode() then
        local hasItem, x, price = GameTooltip:SetInventoryItem("player", index)
        if hasItem and checktotal(price) then
            return self.hooks.PickupInventoryItem(index, ...)
        end
    else
        return self.hooks.PickupInventoryItem(index, ...)
    end

end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of PickupContainerItem
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:PickupContainerItem(bag, slot, ...)
    if InRepairMode() then
        local hasItem, price = GameTooltip:SetBagItem(bag, slot)
        if hasItem and checktotal(price) then
            return self.hooks.PickupContainerItem(bag, slot, ...)
        end
    else
        return self.hooks.PickupContainerItem(bag, slot, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of PickupMerchantItem
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:PickupMerchantItem(index, ...)
    local x, x, price = GetMerchantItemInfo(index)
    if checktotal(price) then
        return self.hooks.PickupMerchantItem(index, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of TakeTaxiNode
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:TakeTaxiNode(index, ...)
    local price = TaxiNodeCost(index)
    if checktotal(price) then
        return self.hooks.TakeTaxiNode(index, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of PickupPlayerMoney
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:PickupPlayerMoney(price, ...)
    if checktotal(price) then
        return self.hooks.PickupPlayerMoney(price, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of SetTradeMoney
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:SetTradeMoney(price, ...)
    if checktotal(price) then
        return self.hooks.SetTradeMoney(price, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of SetSendMailMoney
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:SetSendMailMoney(price, ...)
    if checktotal(price) then
        return self.hooks.SetSendMailMoney(price, ...)
    else
        return nil --simulate the nil == not enough money returns of the orig
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of SendMail
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:SendMail(...)
    local price = GetSendMailPrice()
    if checktotal(price) then
        return self.hooks.SendMail(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of CompleteQuest
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:CompleteQuest(...)
    local price = GetQuestMoneyToGet()
    if checktotal(price) then
        return self.hooks.CompleteQuest(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of TabardModel:Save
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:TabardModel_Save(...)
    local price = GetTabardCreationCost()
    if checktotal(price) then
        return self.hooks[TabardModel].Save(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of DepositGuildBankMoney
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:DepositGuildBankMoney(price, ...)
    if checktotal(price) then
        return self.hooks.DepositGuildBankMoney(price, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyGuildBankTab
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:BuyGuildBankTab(...)
    local price = GetGuildBankTabCost()
    if checktotal(price) then
        return self.hooks.BuyGuildBankTab(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of PurchaseSlot
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:PurchaseSlot(...)
    local price = GetBankSlotCost(GetNumBankSlots() + 1)
    if checktotal(price) then
        return self.hooks.PurchaseSlot(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of ConfirmTalentWipe
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:ConfirmTalentWipe(...)
    local frame = StaticPopup_Visible("CONFIRM_TALENT_WIPE")
    local money = getglobal(frame.."MoneyFrame")
    local price = money.staticMoney
    if checktotal(price) then
        return self.hooks.ConfirmTalentWipe(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of PlaceAuctionBid
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:PlaceAuctionBid(kind, index, bid, ...)
    if checktotal(bid) then
        return self.hooks.PlaceAuctionBid(kind, index, bid, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of StartAuction
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:StartAuction(minBid, buyoutPrice, runTime, ...)
    local price = CalculateAuctionDeposit(runTime)
    if checktotal(price) then
        return self.hooks.StartAuction(minBid, buyoutPrice, runTime, ...)
    end
end


--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of ApplyBarberShopStyle
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
function NazScrooge:ApplyBarberShopStyle(...)
    local price = GetBarberShopTotalCost()
    if checktotal(price) then
        return self.hooks.ApplyBarberShopStyle(...)
    end
end
--Setup functions

local function ChatCmd(input)
	if not input or input:trim() == "" then
		InterfaceOptionsFrame_OpenToCategory(NazScrooge.optionsframe)
	else
		LibStub("AceConfigCmd-3.0").HandleCommand(NazScrooge, "NazScrooge", "NazScrooge", input:trim() ~= "help" and input or "")
	end
end

function NazScrooge:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("NazScroogeDB", {}, "Default")
    self.db:RegisterDefaults({
        profile = {
            sinkOptions = {},
            percenttoggle = false, --keep a percent
            maxtoggle = false, --keep all after a max amount
            mintoggle = false, --keep at least a min
            keeppercent = 0, --percent to save
            keepamount = 0, --min to keep (in gold)
            maxamount = 0, --max to have avail (in gold)
			verbose = true, --do I display saving %s upon every save?
        },
        char = {
            savedcopper = 0, --amount of money saved in copper
            targettoggle = false, --do I have a target?
            target = 0, --amount of money I'm trying to save
        },
    })
	if not self.version then self.version = tonumber(GetAddOnMetadata("NazScrooge", "Version")) end --pull version from toc
	if not self.revision then self.revision = tonumber(GetAddOnMetadata("NazScrooge", "Revision")) end --pull revision from toc
	self:SetSinkStorage(self.db.profile.sinkOptions) -- set location to save sink options
	options.args.output = self:GetSinkAce3OptionsDataTable() -- add in the libsink options table to our options table
	local channel = L["Channel"] -- get the localized channel name
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) -- add in the profile commands to our options table
    self.optionsframe = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NazScrooge", "NazScrooge") -- Add the options to Bliz's new section in interface
	LibStub("AceConfig-3.0"):RegisterOptionsTable("NazScrooge", options) -- Register the chat commands to use our options table
    self:RegisterChatCommand("NazScrooge", ChatCmd)
    self:RegisterChatCommand("nsc", ChatCmd)
    self:RegisterChatCommand(L["Slash-Command"], ChatCmd)
    self:RegisterChatCommand(L["Slash-Command-Short"], ChatCmd)
end

function NazScrooge:OnEnable()
	lasttotal = GetMoney() --save money at enable
    starttime = time() --save timestamp of when enabled
    self:RawHook("GetMoney", true)
    self:RawHook("BuyMerchantItem", true)
    self:RawHook("BuybackItem", true)
    self:RawHook("RepairAllItems", true)
    self:RawHook("BuyGuildBankTab", true)
    self:RawHook("BuyGuildCharter", true)
    --self:RawHook("BuyStableSlot", true)
    --self:RawHook("BuyPetition", true)
    self:RawHook("BuyTrainerService", true)
    self:RawHook("PickupMerchantItem", true)
    self:RawHook("TakeTaxiNode", true)
    self:RawHook("PickupPlayerMoney", true)
    self:RawHook("SetTradeMoney", true)
    self:RawHook("SetSendMailMoney", true)
    self:RawHook("SendMail", true)
    self:RawHook("CompleteQuest", true)
    self:RawHook(TabardModel, "Save", "TabardModel_Save", true)
    self:RawHook("DepositGuildBankMoney", true)
    self:RawHook("PurchaseSlot", true)
    self:RawHook("ConfirmTalentWipe", true)
    self:RawHook("PlaceAuctionBid", true)
    self:RawHook("StartAuction", true)
	self:RawHook("ApplyBarberShopStyle", true)
	self:RegisterEvent("PLAYER_MONEY")
    Refresh_LDB()
end

function NazScrooge:PLAYER_MONEY()
	local newmoney = self.hooks.GetMoney()
	local diff = newmoney - lasttotal
	if NazScrooge.db.profile.flattoggle and NazScrooge.db.char.savedcopper < NazScrooge.db.profile.keepamount*10000 then
        if newmoney < NazScrooge.db.profile.keepamount*10000 then
            NazScrooge.db.char.savedcopper = newmoney
            if not verbosemin then
                NazScrooge:Pour(string.format(L['You do not have enough saved, increasing lockbox money by %s'], makedisplay(diff)))
                verbosemin = true
                verbosemax = false
                verbosepct = false
            elseif self.db.profile.verbose then
                NazScrooge:Pour(string.format(L['Saving %s'], makedisplay(diff)))
            end
        else
        	NazScrooge.db.char.savedcopper = NazScrooge.db.profile.keepamount*10000
            if not verbosemin then
                NazScrooge:Pour(string.format(L['You do not have enough saved, increasing lockbox money to the minimum %s'], makedisplay(NazScrooge.db.profile.keepamount*10000)))
                verbosemin = true
                verbosemax = false
                verbosepct = false
            elseif self.db.profile.verbose then
                NazScrooge:Pour(string.format(L['Saving %s'], makedisplay(NazScrooge.db.profile.keepamount*10000)))
            end
        end
	elseif diff > 0 then
		if NazScrooge.db.profile.maxtoggle and self.hooks.GetMoney() - NazScrooge.db.char.savedcopper + diff > tonumber(NazScrooge.db.profile.maxamount*10000) then
			NazScrooge.db.char.savedcopper = self.hooks.GetMoney() - NazScrooge.db.profile.maxamount*10000
            if not verbosemax then
                NazScrooge:Pour(string.format(L['You have reached the maximum amount you want available, increasing lockbox money by %s'], makedisplay(diff)))
                verbosemin = false
                verbosemax = true
                verbosepct = false
            elseif self.db.profile.verbose then
                NazScrooge:Pour(string.format(L['Saving %s'], makedisplay(diff)))
            end
		elseif NazScrooge.db.profile.percenttoggle then
			local increase = round((NazScrooge.db.profile.keeppercent / 100) * diff, 0)
			if increase then
				addmoney(increase)
				if self.db.profile.verbose then
					NazScrooge:Pour(string.format(L['Earned %s, saving %s.'], makedisplay(diff), makedisplay(increase)))
				end
			end
		end
	end
	lasttotal = lasttotal + diff
	Refresh_Display()
end