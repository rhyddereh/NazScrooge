--[[----------------------------------------------------------------------------------
	NazScrooge Core addon
	
	TODO:  Add in display updates for various addons
           
    Compatibility with: (note: those with ? after them have not been tested by me and therefor not verified)
            ArkInventory
            Auditor2
            FuBar_AuditorFu
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
			
	Changelog:
		0.5	Initial commit
        0.6 fixed message when using the max option and reached the max
        1.0 fixed wording and made the long verbose output only when the reason for the savings changed
        1.05 added in amount per hour in the display command
------------------------------------------------------------------------------------]]

local L = AceLibrary("AceLocale-2.2"):new("NazScrooge")
local dewdrop = AceLibrary("Dewdrop-2.0")
local NazScrooge_Orig_GetMoney, NazScrooge_Orig_BuyMerchantItem, NazScrooge_Orig_BuybackItem, NazScrooge_Orig_RepairAllItems, NazScrooge_Orig_BuyGuildBankTab, NazScrooge_Orig_BuyGuildCharter, NazScrooge_Orig_BuyStableSlot, NazScrooge_Orig_BuyPetition, NazScrooge_Orig_BuyTrainerService, NazScrooge_Orig_PickupInventoryItem, NazScrooge_Orig_PickupContainerItem, NazScrooge_Orig_PickupMerchantItem, NazScrooge_Orig_TakeTaxiNode, NazScrooge_Orig_PickupPlayerMoney, NazScrooge_Orig_SetTradeMoney, NazScrooge_Orig_SetSendMailMoney, NazScrooge_Orig_SendMail, NazScrooge_Orig_CompleteQuest, NazScrooge_Orig_TabardModel_Save, NazScrooge_Orig_DepositGuildBankMoney, NazScrooge_Orig_BuyGuildBankTab, NazScrooge_Orig_PurchaseSlot, NazScrooge_Orig_ConfirmTalentWipe, NazScrooge_Orig_PlaceAuctionBid, NazScrooge_Orig_StartAuction

NazScrooge = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceDB-2.0")
LibStub("LibSink-2.0"):Embed(NazScrooge)
local iconpath = "Interface\\AddOns\\NazScrooge\\textures\\"
local coppertex = ' |T' .. iconpath .. 'Copper.blp' .. ':16:16:0:0|t '
local silvertex = ' |T' .. iconpath .. 'Silver.blp' .. ':16|t '
local goldtex = ' |T' .. iconpath .. 'Gold.blp' .. ':16|t '

local sessionsaved = 0
local starttime = 0
local verbosemin = false
local verbosemax = false
local verbosepct = false

--[[----------------------------------------------------------------------------------
	Notes:
	* Prints out errors
    * Pulled it into a function so we can later ouput to various places depending on option chosen
------------------------------------------------------------------------------------]]
local function Error(msg)
	NazScrooge:Pour(msg)
end

local function GetAvgSaved()
    return sessionsaved/((time() - starttime)/3600)
end

local function round(num, idp)
	local mult = 10^(idp or 2)
	return math.floor(num * mult + 0.5) / mult
end

local function makedisplay(copper)
	copper = tonumber(copper)
	local gold = math.floor(copper/10000)
	local silver = math.floor((copper - gold*10000)/100)
	copper = round(copper - gold*10000 - silver*100, 0)
	local value = ''
	if gold >= 1 then
		value = gold .. ' ' .. goldtex .. ' '
	end
	if silver >= 1 or gold >= 1 then
		value = value .. silver .. ' ' .. silvertex .. ' '
	end
	return value .. copper .. ' ' .. coppertex
end

--[[----------------------------------------------------------------------------------
	Notes:
	* Refreshes displays (bag, etc.)
------------------------------------------------------------------------------------]]
local function Refresh_Display()

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
		elseif (name == "ClassTrainerFrame") then
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
    
    if Auditor then
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
    
    if AllPlayed then
        AllPlayed:Update()
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
end

--[[----------------------------------------------------------------------------------
	Notes:
	* Adds the amount (in copper) given to the saved lockbox
    
    Returns true if it's able to add the entire amount, false if it can only add some
------------------------------------------------------------------------------------]]
local function addmoney(amount)
    amount = amount or 0
    if tonumber(NazScrooge.db.profile.savedcopper) + tonumber(amount) > NazScrooge_Orig_GetMoney() then
        sessionsaved = sessionsaved + (tonumber(NazScrooge.db.profile.savedcopper) + tonumber(amount) - NazScrooge.db.profile.savedcopper)
        NazScrooge.db.profile.savedcopper = NazScrooge_Orig_GetMoney()
        Refresh_Display()
        return false
    end
    sessionsaved = sessionsaved + amount
    NazScrooge.db.profile.savedcopper = tonumber(NazScrooge.db.profile.savedcopper) + tonumber(amount)
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
    NazScrooge.db.profile.savedcopper = tonumber(NazScrooge.db.profile.savedcopper) - tonumber(amount)
    sessionsaved = sessionsaved - amount
    if NazScrooge.db.profile.savedcopper < 0 then
        local diff = NazScrooge.db.profile.savedcopper
        NazScrooge.db.profile.savedcopper = 0
        sessionsaved = sessionsaved + diff
        return amount + diff
    end
    return true
end

local options = { 
    type='group',
    args = {
        options = {
            type = 'group',
            desc = L["Lockbox Options"],
            name = L["Lockbox Options"],
            args = {
                percent = {
                    type = 'toggle',
                    name = L["Set aside a percent of earnings?"],
                    desc = L["Should I set aside a percent of the money you make?"],
                    get = function()
                                return NazScrooge.db.profile.percenttoggle
                            end,
                    set = function(newValue)
                                NazScrooge.db.profile.percenttoggle = newValue
                            end,
                    map = { [false] = L["No"], [true] = L["Yes"] },
                    order = 30,
                },
                keeppercent = {
                    type = 'text',
                    name = L["Percentage of earnings to set aside."],
                    desc = L["What percent of earnings should I set aside for you?"],
                    usage = L["<just the percent>"],
                    disabled = function()
                                    return not NazScrooge.db.profile.percenttoggle
                                end,
                    get = function()
                                return NazScrooge.db.profile.keeppercent
                            end,
                    set = function(newValue)
                                newValue = newValue or 0
                                NazScrooge.db.profile.keeppercent = tonumber(newValue)
                            end,
                    validate = function(value)
                                    value = tonumber(value) or 0
                                    if value > 0 and value < 100 then
                                        return true
                                    else
                                        return false
                                    end
                                end,
                    order = 31,
                },
                min = {
                    type = 'toggle',
                    name = L["Set aside a certain minimum amount?"],
                    desc = L["Should I set aside a minimum amount of money?"],
                    get = function()
                                return NazScrooge.db.profile.flattoggle
                            end,
                    set = function(newValue)
                                NazScrooge.db.profile.flattoggle = newValue
                            end,
                    map = { [false] = L["No"], [true] = L["Yes"] },
                    order = 35,
                },
                minamount = {
                    type = 'text',
                    name = L["Minimum amount to set aside."],
                    desc = L["What's the minimum should I set aside for you?"],
                    usage = L["<number in gold>"],
                    disabled = function()
                                    return not NazScrooge.db.profile.flattoggle
                                end,
                    get = function()
                                return NazScrooge.db.profile.keepamount
                            end,
                    set = function(newValue)
                                newValue = newValue or 0
                                NazScrooge.db.profile.keepamount = tonumber(newValue)
                                if NazScrooge.db.profile.savedcopper < NazScrooge.db.profile.keepamount*10000 then
                                    NazScrooge.db.profile.savedcopper = NazScrooge.db.profile.keepamount*10000
                                end
                            end,
                    order = 36,
                },
                max = {
                    type = 'toggle',
                    name = L["Set aside any money over a certain amount?"],
                    desc = L["Should I set aside money after you reach a certain amount?"],
                    get = function()
                                return NazScrooge.db.profile.maxtoggle
                            end,
                    set = function(newValue)
                                NazScrooge.db.profile.maxtoggle = newValue
                            end,
                    map = { [false] = L["No"], [true] = L["Yes"] },
                    order = 40,
                },
                maxamount = {
                    type = 'text',
                    name = L["Maximum gold to keep available"],
                    desc = L["What's the max gold amount you want available to spend?"],
                    usage = L["<number in gold>"],
                    disabled = function()
                                    return not NazScrooge.db.profile.maxtoggle
                                end,
                    get = function()
                                return NazScrooge.db.profile.maxamount
                            end,
                    set = function(newValue)
                                newValue = newValue or 0
                                NazScrooge.db.profile.maxamount = tonumber(newValue)
                            end,
                    order = 41,
                },
            },
        },
		deposit = {
			type = 'text',
			name = L["deposit"],
			desc = L["Deposit how much to your lockbox?"],
            usage = L["<number in gold>"],
			get = false,
            input = true,
            message = L["%s: Deposited %s gold to your lockbox"],
			set = function(newValue)
                        newValue = newValue or 0
						if addmoney(newValue*10000) then
                            Error(string.format(L["You now have %s in your lockbox"], makedisplay(NazScrooge.db.profile.savedcopper)))
                        else
                            Error(string.format(L["You tried to deposit more money than you had! Deposited %s."], makedisplay(NazScrooge_Orig_GetMoney())))
                            Error(string.format(L["You now have %s in your lockbox"], makedisplay(NazScrooge.db.profile.savedcopper)))
                        end
                        Refresh_Display()
					end,
			order = 32,
		},
		withdraw = {
			type = 'text',
			name = L["withdraw"],
			desc = L["withdraw how much from your lockbox?"],
            usage = L["<number in gold>"],
			get = false,
            input = true,
            message = L["%s: Withdrew %s gold from your lockbox"],
			set = function(newValue)
                        newValue = newValue or 0
                        local removed = removemoney(newValue*10000)
						if removed == true then
                            Error(string.format(L["You have %s in your lockbox"], makedisplay(NazScrooge.db.profile.savedcopper)))
                        else
                            Error(string.format(L["You tried to take out more money than you had saved.  Withrew the balance of %s."], makedisplay(removed)))
                        end   
                        Refresh_Display()
					end,
			order = 32,
		},
		display = {
			type = 'execute',
			name = L["display"],
			desc = L["Display the gold in your lockbox"],
			func = function()
						Error(string.format(L["You have %s in your lockbox"], makedisplay(NazScrooge.db.profile.savedcopper)))
						Error(string.format(L["You are saving %s per hour"], makedisplay(GetAvgSaved())))
					end,
			order = 32,
		},
		output = {
		},
	},
}

NazScrooge:RegisterDB("NazScroogeDB", "NazScroogeDBPC", "char")
NazScrooge:RegisterDefaults("profile", {
	sinkOptions = {},
    percenttoggle = false, --keep a percent
    maxtoggle = false, --keep all after a max amount
    mintoggle = false, --keep at least a min
    keeppercent = 0, --percent to save
	keepamount = 0, --min to keep (in gold)
    maxamount = 0, --max to have avail (in gold)
    savedcopper = 0, --amount of money saved in copper
} )

local t1
local lasttotal --running total

--Reusable functions

--[[----------------------------------------------------------------------------------
	Notes:
	* Returns money amount in copper, or gold if arg1 == true
------------------------------------------------------------------------------------]]
local function GetBoxMoney(gold)
    if gold then
        return NazScrooge.db.profile.savedcopper/10000
    else
        return NazScrooge.db.profile.savedcopper --return the amount of money in box
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
	* Checks to see if you have at least the amount given
------------------------------------------------------------------------------------]]
local function checktotal(price)
    price = price or 0
    if price >  GetMoney() then
        Error(L["You do not have enough money to do that."])
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
local function NazScrooge_GetMoney(...)
    local money = NazScrooge_Orig_GetMoney(...) --get the real value
    money = money - GetBoxMoney() --remove the amount of money in box
    if money < 0 then money = 0 end --don't show a negative value
    return round(money, 0)  -- return the value minus what we are keeping
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyMerchantItem
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_BuyMerchantItem(index, qty, ...)
    local x, x, price = GetMerchantItemInfo(index)
    if qty ~= nil then price = price * qty end
    if checktotal(price) then
        return NazScrooge_Orig_BuyMerchantItem(index, qty, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyMerchantItem
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_BuybackItem(index, ...)
    local x, x, price = GetBuybackItemInfo(index)
    if checktotal(price) then
        return NazScrooge_Orig_BuybackItem(index, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of RepairAllItems
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_RepairAllItems(gb, ...)
    local price = GetRepairAllCost()
    if checktotal(price) or gb == 1 then
        return NazScrooge_Orig_RepairAllItems(gb, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyGuildBankTab
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_BuyGuildBankTab(...)
    local price = GetGuildBankTabCost()
    if checktotal(price) then
        return NazScrooge_Orig_BuyGuildBankTab(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyGuildCharter
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_BuyGuildCharter(...)
    local price = GetGuildCharterCost()
    if checktotal(price) then
        return NazScrooge_Orig_BuyGuildCharter(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyStableSlot
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_BuyStableSlot(...)
    local price = GetNextStableSlotCost()
    if checktotal(price) then
        return NazScrooge_Orig_BuyStableSlot(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyPetition
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_BuyPetition(index, ...)
    local x, x, price = GetPetitionItemInfo(index)
    if checktotal(price) then
        return NazScrooge_Orig_BuyPetition(index, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyTrainerService
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_BuyTrainerService(index, ...)
    local price = GetTrainerServiceCost(index)
    if checktotal(price) then
        return NazScrooge_Orig_BuyTrainerService(index, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of PickupInventoryItem
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_PickupInventoryItem(index, ...)
    if InRepairMode() then
        local hasItem, x, price = GameTooltip:SetInventoryItem("player", index)
        if hasItem and checktotal(price) then
            return NazScrooge_Orig_PickupInventoryItem(index, ...)
        end
    else
        return NazScrooge_Orig_PickupInventoryItem(index, ...)
    end

end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of PickupContainerItem
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_PickupContainerItem(bag, slot, ...)
    if InRepairMode() then
        local hasItem, price = GameTooltip:SetBagItem(bag, slot)
        if hasItem and checktotal(price) then
            return NazScrooge_Orig_PickupContainerItem(bag, slot, ...)
        end
    else
        return NazScrooge_Orig_PickupContainerItem(bag, slot, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of PickupMerchantItem
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_PickupMerchantItem(index, ...)
    local x, x, price = GetMerchantItemInfo(index)
    if checktotal(price) then
        return NazScrooge_Orig_PickupMerchantItem(index, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of TakeTaxiNode
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_TakeTaxiNode(index, ...)
    local price = TaxiNodeCost(index)
    if checktotal(price) then
        return NazScrooge_Orig_TakeTaxiNode(index, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of PickupPlayerMoney
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_PickupPlayerMoney(price, ...)
    if checktotal(price) then
        return NazScrooge_Orig_PickupPlayerMoney(price, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of SetTradeMoney
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_SetTradeMoney(price, ...)
    if checktotal(price) then
        return NazScrooge_Orig_SetTradeMoney(price, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of SetSendMailMoney
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_SetSendMailMoney(price, ...)
    if checktotal(price) then
        return NazScrooge_Orig_SetSendMailMoney(price, ...)
    else
        return nil --simulate the nil == not enough money returns of the orig
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of SendMail
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_SendMail(...)
    local price = GetSendMailPrice()
    if checktotal(price) then
        return NazScrooge_Orig_SendMail(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of CompleteQuest
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_CompleteQuest(...)
    local price = GetQuestMoneyToGet()
    if checktotal(price) then
        return NazScrooge_Orig_CompleteQuest(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of TabardModel:Save
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_TabardModel_Save(...)
    local price = GetTabardCreationCost()
    if checktotal(price) then
        return NazScrooge_Orig_TabardModel_Save(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of DepositGuildBankMoney
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_DepositGuildBankMoney(price, ...)
    if checktotal(price) then
        return NazScrooge_Orig_DepositGuildBankMoney(price, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of BuyGuildBankTab
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_BuyGuildBankTab(...)
    local price = GetGuildBankTabCost()
    if checktotal(price) then
        return NazScrooge_Orig_BuyGuildBankTab(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of PurchaseSlot
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_PurchaseSlot(...)
    local price = GetBankSlotCost(GetNumBankSlots() + 1)
    if checktotal(price) then
        return NazScrooge_Orig_PurchaseSlot(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of ConfirmTalentWipe
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_ConfirmTalentWipe(...)
    local frame = StaticPopup_Visible("CONFIRM_TALENT_WIPE")
    local money = getglobal(frame.."MoneyFrame")
    local price = money.staticMoney
    if checktotal(price) then
        return NazScrooge_Orig_ConfirmTalentWipe(...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of PlaceAuctionBid
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_PlaceAuctionBid(kind, index, bid, ...)
    if checktotal(bid) then
        return NazScrooge_Orig_PlaceAuctionBid(kind, index, bid, ...)
    end
end

--[[----------------------------------------------------------------------------------
	Notes:
    * Hooked version of StartAuction
	* Makes sure you have enough non-hidden money and then passes or blocks depending
------------------------------------------------------------------------------------]]
local function NazScrooge_StartAuction(minBid, buyoutPrice, runTime, ...)
    local price = CalculateAuctionDeposit(runTime)
    if checktotal(price) then
        return NazScrooge_Orig_StartAuction(minBid, buyoutPrice, runTime, ...)
    end
end

--Setup functions

local function SetLayout(this)
  dewdrop:Close()  -- closes any open dewdrop menu when switching
  if not t1 then
    -- title text
    t1 = this:CreateFontString(nil, "ARTWORK")
    t1:SetFontObject(GameFontNormalLarge)
    t1:SetJustifyH("LEFT") 
    t1:SetJustifyV("TOP")
    t1:SetPoint("TOPLEFT", 16, -16)
    t1:SetText(this.name)

    -- description text
    local t2 = this:CreateFontString(nil, "ARTWORK")
    t2:SetFontObject(GameFontHighlightSmall)
    t2:SetJustifyH("LEFT") 
    t2:SetJustifyV("TOP")
    t2:SetHeight(43)
    t2:SetPoint("TOPLEFT", t1, "BOTTOMLEFT", 0, -8)
    t2:SetPoint("RIGHT", this, "RIGHT", -32, 0)
    t2:SetNonSpaceWrap(true)
    local function GetInfo(field)
      return GetAddOnMetadata(this.addon, field) or "N/A"
    end
    t2:SetFormattedText("Notes: %s\nAuthor: %s\nVersion: %s\nRevision: %s", GetInfo("Notes"), GetInfo("Author"), GetInfo("Version"), GetInfo("X-Build"))

    -- general button
    local b = CreateFrame("Button", nil, this, "UIPanelButtonTemplate")
    b:SetWidth(120)
    b:SetHeight(20)
    b:SetText("Options Menu")
    b:SetScript("OnClick", NazScrooge.DewOptions)  -- your options function here
    b:SetPoint("TOPLEFT", t2, "BOTTOMLEFT", -2, -8)
  end
end

function NazScrooge:DewOptions()
	dewdrop:Open('dummy', 'children', function() dewdrop:FeedAceOptionsTable(options) end, 'cursorX', true, 'cursorY', true)
end

local function CreateUIOptionsFrame(addon)  -- call from your load function, using your addon's name
  local panel = CreateFrame("Frame")
  panel.name = GetAddOnMetadata(addon, "Title") or addon
  panel.addon = addon
  panel:SetScript("OnShow", SetLayout)
  InterfaceOptions_AddCategory(panel)
end

function NazScrooge:OnInitialize()
	if not self.version then self.version = tonumber(GetAddOnMetadata("NazScrooge", "Version")) end --pull version from toc
	if not self.revision then self.revision = tonumber(GetAddOnMetadata("NazScrooge", "Revision")) end --pull revision from toc
	self:SetSinkStorage(self.db.profile.sinkOptions)
	options.args.output = self:GetSinkAce2OptionsDataTable().output
	local channel = L["Channel"]
	options.args.output.args[channel] = nil
	NazScrooge:RegisterChatCommand(L["Slash-Commands"], options)
	NazScrooge:RegisterChatCommand(L["Slash-Commands2"], options)
    CreateUIOptionsFrame('NazScrooge')
end

function NazScrooge:OnEnable()
	lasttotal = GetMoney() --save money at enable
    starttime = time()
    NazScrooge_Orig_GetMoney = GetMoney --remember old GetMoney() call
    GetMoney = NazScrooge_GetMoney --replace the GetMoney to my own
    NazScrooge_Orig_BuyMerchantItem = BuyMerchantItem
    BuyMerchantItem = NazScrooge_BuyMerchantItem
    NazScrooge_Orig_BuybackItem = BuybackItem
    BuybackItem = NazScrooge_BuybackItem
    NazScrooge_Orig_RepairAllItems = RepairAllItems
    RepairAllItems = NazScrooge_RepairAllItems
    NazScrooge_Orig_BuyGuildBankTab = BuyGuildBankTab
    BuyGuildBankTab = NazScrooge_BuyGuildBankTab
    NazScrooge_Orig_BuyGuildCharter = BuyGuildCharter
    BuyGuildCharter = NazScrooge_BuyGuildCharter
    NazScrooge_Orig_BuyStableSlot = BuyStableSlot
    BuyStableSlot = NazScrooge_BuyStableSlot
    NazScrooge_Orig_BuyPetition = BuyPetition
    BuyPetition = NazScrooge_BuyPetition
    NazScrooge_Orig_BuyTrainerService = BuyTrainerService
    BuyTrainerService = NazScrooge_BuyTrainerService
--    NazScrooge_Orig_PickupInventoryItem = PickupInventoryItem
--    PickupInventoryItem = NazScrooge_PickupInventoryItem
--    NazScrooge_Orig_PickupContainerItem = PickupContainerItem
--    PickupContainerItem = NazScrooge_PickupContainerItem
    NazScrooge_Orig_PickupMerchantItem = PickupMerchantItem
    PickupMerchantItem = NazScrooge_PickupMerchantItem
    NazScrooge_Orig_TakeTaxiNode = TakeTaxiNode
    TakeTaxiNode = NazScrooge_TakeTaxiNode
    NazScrooge_Orig_PickupPlayerMoney = PickupPlayerMoney
    PickupPlayerMoney = NazScrooge_PickupPlayerMoney
    NazScrooge_Orig_SetTradeMoney = SetTradeMoney
    SetTradeMoney = NazScrooge_SetTradeMoney
    NazScrooge_Orig_SetSendMailMoney = SetSendMailMoney
    SetSendMailMoney = NazScrooge_SetSendMailMoney
    NazScrooge_Orig_SendMail = SendMail
    SendMail = NazScrooge_SendMail
    NazScrooge_Orig_CompleteQuest = CompleteQuest
    CompleteQuest = NazScrooge_CompleteQuest
    NazScrooge_Orig_TabardModel_Save = TabardModel.Save
    TabardModel.Save = NazScrooge_TabardModel_Save
    NazScrooge_Orig_DepositGuildBankMoney = DepositGuildBankMoney
    DepositGuildBankMoney = NazScrooge_DepositGuildBankMoney
    NazScrooge_Orig_BuyGuildBankTab = BuyGuildBankTab
    BuyGuildBankTab = NazScrooge_BuyGuildBankTab
    NazScrooge_Orig_PurchaseSlot = PurchaseSlot
    PurchaseSlot = NazScrooge_PurchaseSlot
    NazScrooge_Orig_ConfirmTalentWipe = ConfirmTalentWipe
    ConfirmTalentWipe = NazScrooge_ConfirmTalentWipe
    NazScrooge_Orig_PlaceAuctionBid = PlaceAuctionBid
    PlaceAuctionBid = NazScrooge_PlaceAuctionBid
    NazScrooge_Orig_StartAuction = StartAuction
    StartAuction = NazScrooge_StartAuction
	self:RegisterEvent("PLAYER_MONEY")
end

function NazScrooge:PLAYER_MONEY()
	local newmoney = NazScrooge_Orig_GetMoney()
	local diff = newmoney - lasttotal
	if NazScrooge.db.profile.flattoggle and NazScrooge.db.profile.savedcopper < NazScrooge.db.profile.keepamount*10000 then
        if NazScrooge_Orig_GetMoney() < NazScrooge.db.profile.keepamount*10000 then
            NazScrooge.db.profile.savedcopper = NazScrooge_Orig_GetMoney()
            if not verbosemin then
                Error(string.format(L['You do not have enough saved, increasing lockbox money by %s gold.'], makedisplay(diff)))
                verbosemin = true
                verbosemax = false
                verbosepct = false
            else
                Error(string.format(L['Saving %s'], makedisplay(diff)))
            end
        else
        	NazScrooge.db.profile.savedcopper = NazScrooge.db.profile.keepamount*10000
            if not verbosemin then
                Error(string.format(L['You do not have enough saved, increasing lockbox money to the minimum %s gold.'], makedisplay(NazScrooge.db.profile.keepamount*10000)))
                verbosemin = true
                verbosemax = false
                verbosepct = false
            else
                Error(string.format(L['Saving %s'], makedisplay(NazScrooge.db.profile.keepamount*10000)))
            end
        end
	elseif diff > 0 then
		if NazScrooge.db.profile.maxtoggle and NazScrooge_Orig_GetMoney() > tonumber(NazScrooge.db.profile.maxamount*10000) then
			NazScrooge.db.profile.savedcopper = NazScrooge_Orig_GetMoney() - NazScrooge.db.profile.maxamount*10000
            if not verbosemax then
                Error(string.format(L['You have reached the maximum amount you want available, increasing lockbox money by %s gold.'], makedisplay(diff)))
                verbosemin = false
                verbosemax = true
                verbosepct = false
            else
                Error(string.format(L['Saving %s'], makedisplay(diff)))
            end
		elseif NazScrooge.db.profile.percenttoggle then
			local increase = round((NazScrooge.db.profile.keeppercent / 100) * diff, 0)
			addmoney(increase)
			Error(string.format(L['Earned %s, saving %s.'], makedisplay(diff), makedisplay(increase)))
		end
	end
	lasttotal = lasttotal + diff
	Refresh_Display()
end
