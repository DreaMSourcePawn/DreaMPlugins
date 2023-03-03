/**
 * Показ главного меню игроку
 * 
 * @param iClient       индекс игрока
 * 
 * @noreturn
 */
void ThrowMainMenuToClient(int iClient, bool bComeFromClansMenu = false)
{
    if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
        return;

    ClearAdminInfo(iClient);
    bool bIsAdmin = HasPlayerAdminFlag(iClient);

    Menu mMainMenu = CreateMenu(MainMenu_Handler);
    mMainMenu.SetTitle("%T", "m_ClanShop", iClient);

    char sDisplayName[256];
    FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_Categories", iClient);
    mMainMenu.AddItem("Buy", sDisplayName);

    FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_Inventory", iClient);
    mMainMenu.AddItem("Inventory", sDisplayName);

    if(bIsAdmin)
    {
        FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_AdminMenu", iClient);
        mMainMenu.AddItem("Admin", sDisplayName);
    }

    if(bComeFromClansMenu)
        mMainMenu.ExitBackButton = true;

    mMainMenu.Display(iClient, 0);
}

/**
 * Обработчик главного меню
 */
int MainMenu_Handler(Menu mMainMenu, MenuAction mAction, int iClient, int iOption)
{
    if(mAction == MenuAction_Select)
    {
        if(iOption == 0)                        //Buy menu
            ThrowCategoriesToClient(iClient);
        else if(iOption == 1)                   //Inventory
        {
            if(!HasClientAnyItem(iClient))
            {
                ColorPrintToChat(iClient, "%T", "c_EmptyInventory", iClient);
                ThrowMainMenuToClient(iClient);
                return 0;
            }

            ThrowInventoryToClient(iClient);
        }
        else                                    //Admin Menu
            ThrowAdminMenuToClient(iClient);
    }
    else if(mAction == MenuAction_End)
    {
        delete mMainMenu;
    }
    else if(iOption == MenuCancel_ExitBack && mAction == MenuAction_Cancel)
	{
		Clans_ShowClientMenu(iClient, CM_Main);
	}

    return 0;
}

/**
 * Показ всех доступных категорий игроку
 * 
 * @param iClient       индекс игрока
 * 
 * @return              true в случае успеха, иначе - false
 */
bool ThrowCategoriesToClient(int iClient)
{
    if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
        return false;

    bool bIsAdmin = HasPlayerAdminFlag(iClient);

    ArrayList alCategories = GetClientItemsCategories(iClient);

    Menu mCategories = CreateMenu(BUY_CategoriesHandler);
    mCategories.SetTitle("%T", "m_Categories", iClient);

    char sDisplayName[256], sId[20];
    Category category;
    ClanCategoryId categoryId;
    bool bCategoryHidden = false, 
         bShow = false,
         bHasItemInCategory;    //BETA2
    for(int i = 0; i < g_alCategories.Length; ++i)
    {
        g_alCategories.GetArray(i, category, sizeof(category));

        bCategoryHidden = category.iVisibleItems == 0;

        categoryId = RegisterCategory(category.sName);
        if(alCategories == null || alCategories.FindValue(categoryId) == -1)
            bHasItemInCategory = false;
        else
            bHasItemInCategory = true;

        if((!bCategoryHidden || bHasItemInCategory || bIsAdmin) && category.alItems.Length > 0)
        {
            FormatEx(sId, sizeof(sId), "%d", categoryId);
            FormatEx(sDisplayName, sizeof(sDisplayName), "%s", category.sName);
            DisplayNameForMenu(iClient, sDisplayName, sizeof(sDisplayName), bCategoryHidden);
            mCategories.AddItem(sId, sDisplayName);
            bShow = true;
        }
    }

    if(alCategories)
        delete alCategories;

    if(bShow)
    {
        mCategories.ExitBackButton = true;
        mCategories.Display(iClient, 0);
    }
    else
    {
        delete mCategories;
        ColorPrintToChat(iClient, "%T", "c_NoAvailableItems", iClient);
        return false;
    }

    return true;
}

/**
 * Обработчик меню категорий (покупка)
 */
int BUY_CategoriesHandler(Menu mCategories, MenuAction mAction, int iClient, int iOption)
{
    if(mAction == MenuAction_Select)
    {
        char sCategoryId[20];
        mCategories.GetItem(iOption, sCategoryId, sizeof(sCategoryId));
        ClanCategoryId categoryId = StringToInt(sCategoryId);
        ThrowCategoryItemsToClient(iClient, categoryId);
    }
    else if(mAction == MenuAction_End)
    {
        delete mCategories;
    }
    else if(iOption == MenuCancel_ExitBack && mAction == MenuAction_Cancel)
	{
		ThrowMainMenuToClient(iClient);
	}

    return 0;
}

/**
 * Показ всех доступных предметов категорий игроку
 * 
 * @param iClient           индекс игрока
 * @param categoryId        ид категории
 * 
 * @return                  true в случае успеха, иначе - false
 */
bool ThrowCategoryItemsToClient(int iClient, ClanCategoryId categoryId)
{
    if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
        return false;

    char sDisplayName[256], sItemId[20];
    Category category;
    GetCategoryFromArray(categoryId, category);
    FormatEx(sDisplayName, sizeof(sDisplayName), "%s", category.sName);
    DisplayNameForMenu(iClient, sDisplayName, sizeof(sDisplayName), category.iVisibleItems == 0);

    bool bIsAdmin = HasPlayerAdminFlag(iClient);

    Menu mCategoryItems = CreateMenu(BUY_CategoryItemsHandler);
    mCategoryItems.SetTitle(sDisplayName);

    ArrayList items = GetCategoryItems(categoryId);
    ClanItem clanItem;
    ClanItemId itemId;
    int iAvailableAmount;
    for(int i = 0; i < items.Length; ++i)
    {
        itemId = items.Get(i);
        GetItemById(itemId, clanItem);
        iAvailableAmount = clanItem.iAmount > clanItem.iMaxAmount ? 0 : clanItem.iMaxAmount-clanItem.iAmount;

        FormatEx(sItemId, sizeof(sItemId), "%d", clanItem.id);
        FormatEx(sDisplayName, sizeof(sDisplayName), "%s", clanItem.sName);

        DisplayNameForMenu(iClient, sDisplayName, sizeof(sDisplayName), clanItem.bHidden);
        Format(sDisplayName, sizeof(sDisplayName), "%s [%d]", sDisplayName, iAvailableAmount);

        if(!clanItem.bHidden || bIsAdmin || HasPlayerItem(iClient, itemId)) //BETA2
        {
            mCategoryItems.AddItem(sItemId, sDisplayName);
        }
    }

    mCategoryItems.ExitBackButton = true;
    mCategoryItems.Display(iClient, 0);
    return true;
}

/**
 * Обработчик меню предметов категории (покупка)
 */
int BUY_CategoryItemsHandler(Menu mCategoryItems, MenuAction mAction, int iClient, int iOption)
{
    if(mAction == MenuAction_Select)
    {
        char sItemId[20];
        mCategoryItems.GetItem(iOption, sItemId, sizeof(sItemId));
        ClanItemId itemId = StringToInt(sItemId);

        AdminAction adminAction = GetClientAdminAction(iClient);
        if(adminAction == AA_ChangeStock)
        {
            SetAdminInfo(iClient, AA_ChangeStock + AA_Input, itemId, TARGET_NONE);
            char sDisplayName[256];
            int iMaxAmount = GetItemMaxAmountById(itemId);
            GetItemNameById(itemId, sDisplayName, sizeof(sDisplayName));
            DisplayNameForMenu(iClient, sDisplayName, sizeof(sDisplayName), false);
            ColorPrintToChat(iClient, "%T", "c_ChangeItemStock", iClient, sDisplayName, iMaxAmount);
            ColorPrintToChat(iClient, "%T", "c_AdminCancel", iClient);
            return 0;
        }
        else if(adminAction == AA_GiveItemToClan)
        {
            int iClanId = GetAdminActionClanTarget(iClient);
            int iExpireTime = GetItemDurationById(itemId);
            if(iExpireTime > ITEM_INFINITE)
                iExpireTime += GetTime();

            AddItemToClan(iClanId, itemId, 1, iExpireTime);
            TryAddItemToExpiringArray(itemId, iClanId, iExpireTime);
            char originalItemName[256], itemName[256];  // Уведомление игрока, что предмет забрали
            GetItemNameById(itemId, originalItemName, sizeof(originalItemName));
            for(int i = 1; i <= MaxClients; ++i)
            {
                if(IsClientInGame(i) && Clans_GetClientData(i, CCST_CLANID) == iClanId)
                {
                    FormatEx(itemName, sizeof(itemName), "%s", originalItemName);
                    DisplayNameForMenu(i, itemName, sizeof(itemName));
                    ColorPrintToChat(i, "%T %N", "c_ItemGivenByAdmin", i, itemName, iClient);
                }
            }

            char clanName[MAX_CLAN_NAME+1];
            GetAdminActionClanNameTarget(iClient, clanName, sizeof(clanName));
            ColorPrintToChat(iClient, "%T", "c_ItemGivenSuccessfully", iClient, itemName, clanName);
            ClanCategoryId categoryId = GetItemCategoryIdById(itemId);
            ThrowCategoryItemsToClient(iClient, categoryId);
            return 0;
        }

        if(HasPlayerItem(iClient, itemId))
            ThrowOwnedItem(iClient, itemId);
        else
            ThrowItemToBuy(iClient, itemId);
    }
    else if(mAction == MenuAction_End)
    {
        delete mCategoryItems;
    }
    else if(iOption == MenuCancel_ExitBack && mAction == MenuAction_Cancel)
	{
		ThrowCategoriesToClient(iClient);
	}
    return 0;
}

/**
 * Показ предмета, которого у игрока нет (страница покупки)
 * 
 * @param iClient           индекс игрока
 * @param itemId            ид предмета
 * 
 * @noreturn
 */
void ThrowItemToBuy(int iClient, ClanItemId itemId)
{
    if(!IsClientInGame(iClient))
        return;

    ClanItem clanItem;
    GetItemById(itemId, clanItem);

    char sDisplayName[256], sDisplayDesc[256], sDuration[128], sBuff[256];
    Menu mItemMenu = CreateMenu(BUY_ItemMenuHandler);
    FormatEx(sDisplayName, sizeof(sDisplayName), "%s", clanItem.sName);
    DisplayNameForMenu(iClient, sDisplayName, sizeof(sDisplayName), clanItem.bHidden);

    FormatEx(sDisplayDesc, sizeof(sDisplayDesc), "%s", clanItem.sDesc);
    DisplayNameForMenu(iClient, sDisplayDesc, sizeof(sDisplayDesc));

    if(clanItem.iDuration == ITEM_INFINITE)
        FormatEx(sDuration, sizeof(sDuration), "%T", "Forever", iClient);
    else
        SecondsToTime(clanItem.iDuration, sDuration, sizeof(sDuration), iClient);

    int iAvailableToBuy = clanItem.iAmount > clanItem.iMaxAmount ? 0 : clanItem.iMaxAmount-clanItem.iAmount;

    if(clanItem.iMaxLevel > 1 && clanItem.alLevelsPrices) //Улучшаемый
    {
        mItemMenu.SetTitle("%T", "m_ItemInfoUpgradable", iClient,
                sDisplayName, sDisplayDesc, sDuration, 
                clanItem.iMaxLevel, iAvailableToBuy);
    }
    else
    {
        mItemMenu.SetTitle("%T", "m_ItemInfo", iClient,
                sDisplayName, sDisplayDesc, sDuration, iAvailableToBuy);
    }

    int iClientRole = Clans_GetClientData(iClient, CCST_ROLE);

    /*if(IsShopManager(iClientRole) && iAvailableToBuy && clanItem.iPrice != ITEM_NOTBUYABLE)
    {
        FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_Buy", iClient, clanItem.iPrice);
        FormatEx(sBuff, sizeof(sBuff), "B%d", clanItem.id);
        mItemMenu.AddItem(sBuff, sDisplayName);
    }*/
    if(IsShopManager(iClientRole))
    {
        if(iAvailableToBuy && clanItem.iPrice != ITEM_NOTBUYABLE)
        {
            FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_Buy", iClient, clanItem.iPrice);
            FormatEx(sBuff, sizeof(sBuff), "B%d", clanItem.id);
            mItemMenu.AddItem(sBuff, sDisplayName);
        }
        else
        {
            FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_Notbuyable", iClient);
            mItemMenu.AddItem("", sDisplayName, ITEMDRAW_DISABLED);
        }
    }

    FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_Back", iClient);
    FormatEx(sBuff, sizeof(sBuff), "R%d", clanItem.categoryId);
    mItemMenu.AddItem(sBuff, sDisplayName);

    mItemMenu.Display(iClient, 0);
}

/**
 * Показ предмета, который у игрока есть (страница инвентаря)
 * 
 * @param iClient               индекс игрока
 * @param itemId                ид предмета
 * @param bComeFromInventory    флаг прихода из инвентаря
 * 
 * @noreturn
 */
void ThrowOwnedItem(int iClient, ClanItemId itemId, bool bComeFromInventory = false)
{
    if(!IsClientInGame(iClient))
        return;

    ClanItem clanItem;
    GetItemById(itemId, clanItem);

    char sDisplayName[256], sDisplayDesc[256], sTimeLeft[128], sDuration[128], sBuff[256];
    Menu mItemMenu = CreateMenu(BUY_ItemMenuHandler);
    FormatEx(sDisplayName, sizeof(sDisplayName), "%s", clanItem.sName);
    DisplayNameForMenu(iClient, sDisplayName, sizeof(sDisplayName), clanItem.bHidden);

    FormatEx(sDisplayDesc, sizeof(sDisplayDesc), "%s", clanItem.sDesc);
    DisplayNameForMenu(iClient, sDisplayDesc, sizeof(sDisplayDesc));

    if(clanItem.iDuration == ITEM_INFINITE)
        FormatEx(sDuration, sizeof(sDuration), "%T", "Forever", iClient);
    else
        SecondsToTime(clanItem.iDuration, sDuration, sizeof(sDuration), iClient);

    int iTimeLeft = GetPlayerItemExpireTime(iClient, itemId);
    if(iTimeLeft == ITEM_INFINITE)
        FormatEx(sTimeLeft, sizeof(sTimeLeft), "%T", "Forever", iClient);
    else
    {
        if(iTimeLeft == 0)
            SecondsToTime(0, sTimeLeft, sizeof(sTimeLeft), iClient);
        else
            SecondsToTime(iTimeLeft-GetTime(), sTimeLeft, sizeof(sTimeLeft), iClient);
    }

    CShop_ItemState playerState = GetPlayerItemState(iClient, itemId);
    int iPlayeritemLevel = GetPlayerItemLevel(iClient, itemId);

    int iAvailableToBuy = clanItem.iAmount > clanItem.iMaxAmount ? 0 : clanItem.iMaxAmount-clanItem.iAmount;

    bool bUpgradeable = clanItem.alLevelsPrices != null;// && iPlayeritemLevel < clanItem.iMaxLevel;

    if(bUpgradeable) //Улучшаемый
    {
        mItemMenu.SetTitle("%T", "m_OwnedItemInfoUpgradable", iClient,
                sDisplayName, sDisplayDesc, sDuration, sTimeLeft, 
                iPlayeritemLevel, clanItem.iMaxLevel, iAvailableToBuy);
    }
    else
    {
        mItemMenu.SetTitle("%T", "m_OwnedItemInfo", iClient,
                sDisplayName, sDisplayDesc, sDuration, sTimeLeft, iAvailableToBuy);
    }

    // Если вдруг захочется, чтобы кланы могли накапливать предметы, которые используются одноразово
    // Только надо будет тогда доделать playerItem, чтоб там количество еще было
    /*if(iAvailableToBuy && clanItem.iPrice != ITEM_NOTBUYABLE && clanItem.type == CSHOP_TYPE_ONEUSE)
    {
        FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_Buy", iClient, clanItem.iPrice);
        FormatEx(sBuff, sizeof(sBuff), "B%d", clanItem.id);
        mItemMenu.AddItem(sBuff, sDisplayName);
    }*/

    int iClientRole = Clans_GetClientData(iClient, CCST_ROLE);

    if(IsShopManager(iClientRole))
    {
        if(bUpgradeable && iPlayeritemLevel < clanItem.iMaxLevel)
        {
            int iNextLevelPrice = GetItemLevelPriceById(itemId, iPlayeritemLevel+1);
            if(iNextLevelPrice != ITEM_NOTBUYABLE)
            {
                FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_Upgrade", iClient, iNextLevelPrice);
                FormatEx(sBuff, sizeof(sBuff), "UP%d%s", clanItem.id, (bComeFromInventory == true ? "I" : "")); //BETA2
                mItemMenu.AddItem(sBuff, sDisplayName);
            }
        }

        if(clanItem.iSellPrice != ITEM_NOTSELLABLE)
        {
            FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_Sell", iClient, clanItem.iSellPrice);
            FormatEx(sBuff, sizeof(sBuff), "S%d", clanItem.id);
            mItemMenu.AddItem(sBuff, sDisplayName);
        }
        else
        {
            FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_Notsellable", iClient);
            mItemMenu.AddItem("", sDisplayName, ITEMDRAW_DISABLED);
        }
    }

    if(clanItem.type == CSHOP_TYPE_TOGGLEABLE)
    {
        if(playerState == CSHOP_STATE_UNACTIVE)
        {
            FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_Activate", iClient);
            FormatEx(sBuff, sizeof(sBuff), "A%d", clanItem.id);
        }
        else
        {
            FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_Deactivate", iClient);
            FormatEx(sBuff, sizeof(sBuff), "D%d", clanItem.id);
        }
        mItemMenu.AddItem(sBuff, sDisplayName);
    }
    else if(IsShopManager(iClientRole) && clanItem.type == CSHOP_TYPE_ONEUSE)
    {
        FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_Use", iClient);
        FormatEx(sBuff, sizeof(sBuff), "US%d", clanItem.id);
        mItemMenu.AddItem(sBuff, sDisplayName);
    }

    FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_Back", iClient);
    FormatEx(sBuff, sizeof(sBuff), "R%d%s", clanItem.categoryId, (bComeFromInventory == true ? "I" : ""));  //BETA2
    mItemMenu.AddItem(sBuff, sDisplayName);

    mItemMenu.Display(iClient, 0);
}

/**
 * Обработчик меню предмета (покупка/инвентарное)
 */
int BUY_ItemMenuHandler(Menu mItemMenu, MenuAction mAction, int iClient, int iOption)
{
    if(mAction == MenuAction_Select)
    {
        char sSelectedItem[30];
        mItemMenu.GetItem(iOption, sSelectedItem, sizeof(sSelectedItem));
        ClanItemId itemId;
        if(sSelectedItem[0] == 'B') //Buy
        {
            itemId = StringToInt(sSelectedItem[1]);
            int iPrice = GetItemPriceById(itemId);
            int iExpireTime = GetItemDurationById(itemId);
            //Форвард перед покупкой: можно менять цену/длительность. То же сделать для меню сразу хотелось бы :)
            if(iExpireTime != ITEM_INFINITE)
                iExpireTime += GetTime();

            ClientBuyItem(iClient, itemId, iPrice, iExpireTime);
        }
        else if(sSelectedItem[0] == 'S') //Sell
        {
            itemId = StringToInt(sSelectedItem[1]);
            int iSellPrice = GetItemSellPriceById(itemId);

            //Форвард перед продажей: можно менять цену. То же сделать для меню сразу хотелось бы :)
            ClientSellItem(iClient, itemId, iSellPrice);
        }
        else if(sSelectedItem[0] == 'U' && sSelectedItem[1] == 'P') //Upgrade
        {
            int indexOfi = StrContains(sSelectedItem[2], "I");
            if(indexOfi != -1)
                sSelectedItem[indexOfi] = 0;
            itemId = StringToInt(sSelectedItem[2]);
            int iPlayerLevel = GetPlayerItemLevel(iClient, itemId);
            int iPrice = GetItemLevelPriceById(itemId, iPlayerLevel+1);

            bool bOpenInventoryAfterAction = indexOfi != -1;
            //Форвард перед покупкой: можно менять цену. То же сделать для меню сразу хотелось бы :)
            ClientUpgradeItem(iClient, itemId, iPrice, iPlayerLevel+1, bOpenInventoryAfterAction);
        }
        else if(sSelectedItem[0] == 'U' && sSelectedItem[1] == 'S') //Use
        {
            itemId = StringToInt(sSelectedItem[2]);
            ClientUseItem(iClient, itemId);
            ThrowItemToBuy(iClient, itemId);
        }
        else if(sSelectedItem[0] == 'A')    //Activate      Сделать тут кд, чтоб базу не терроризировали?
        {
            itemId = StringToInt(sSelectedItem[1]);
            SetPlayerItemState(iClient, itemId, CSHOP_STATE_ACTIVE);
            ThrowOwnedItem(iClient, itemId);
        }
        else if(sSelectedItem[0] == 'D')    //Deactivate    Сделать тут кд, чтоб базу не терроризировали?
        {
            itemId = StringToInt(sSelectedItem[1]);
            SetPlayerItemState(iClient, itemId, CSHOP_STATE_UNACTIVE);
            ThrowOwnedItem(iClient, itemId);
        }
        else if(sSelectedItem[0] == 'R')    //Back (return to category)
        {
            int indexOfi = StrContains(sSelectedItem, "I");
            if(indexOfi != -1)
                sSelectedItem[indexOfi] = 0;
            ClanCategoryId categoryId = StringToInt(sSelectedItem[1]);

            if(indexOfi == -1)            
                ThrowCategoryItemsToClient(iClient, categoryId);
            else
                ThrowItemsInInventoryToClient(iClient, categoryId);
        }
    }
    else if(mAction == MenuAction_End)
    {
        delete mItemMenu;
    }
    return 0;
}

/**
 * Показ инвентаря игрока
 * 
 * @param iClient           индекс игрока
 * 
 * @noreturn
 */
void ThrowInventoryToClient(int iClient)
{
    if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
        return;

    ArrayList alCategories = GetClientItemsCategories(iClient);
    Menu mInventoryMenu = CreateMenu(Inventory_Handler);
    mInventoryMenu.SetTitle("%T", "m_Inventory", iClient);

    char sDisplayName[256], sId[20];
    ClanCategoryId categoryId;
    Category category;
    bool bCategoryHidden;
    for(int i = 0; i < alCategories.Length; ++i)
    {
        categoryId = alCategories.Get(i);
        GetCategoryFromArray(categoryId, category);

        bCategoryHidden = category.iVisibleItems == 0;
        FormatEx(sDisplayName, sizeof(sDisplayName), "%s", category.sName);

        DisplayNameForMenu(iClient, sDisplayName, sizeof(sDisplayName), bCategoryHidden);
        FormatEx(sId, sizeof(sId), "%d", categoryId);
        mInventoryMenu.AddItem(sId, sDisplayName);
    }

    mInventoryMenu.ExitBackButton = true;
    mInventoryMenu.Display(iClient, 0);
    delete alCategories;
}

/**
 * Обработчик меню инвентаря (категории)
 */
int Inventory_Handler(Menu mInventoryMenu, MenuAction mAction, int iClient, int iOption)
{
    if(mAction == MenuAction_Select)
    {
        char sCategoryId[20];
        mInventoryMenu.GetItem(iOption, sCategoryId, sizeof(sCategoryId));
        ClanCategoryId categoryId = StringToInt(sCategoryId);
        if(!ThrowItemsInInventoryToClient(iClient, categoryId) && IsClientInGame(iClient))
        {
            ColorPrintToChat(iClient, "%T", "c_NoAvailableItems", iClient);
            ThrowInventoryToClient(iClient);
        }
    }
    else if(mAction == MenuAction_End)
    {
        delete mInventoryMenu;
    }
    else if(iOption == MenuCancel_ExitBack && mAction == MenuAction_Cancel)
	{
		ThrowMainMenuToClient(iClient);
	}

    return 0;
}

/**
 * Показать предметы категории из инвентаря игроку
 * 
 * @param iClient       индекс игрока
 * @param categoryId    индекс категории
 * @return              true в случае успеха, false иначе (игрок не в сети/нет предметов для показа)
 */
bool ThrowItemsInInventoryToClient(int iClient, ClanCategoryId categoryId)
{
    if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
        return false;

    ArrayList alOwnedItems = GetClientOwnedItemsIdInCategory(iClient, categoryId);
    if(alOwnedItems == null)
        return false;

    char sDisplayName[256];
    Category category;
    bool bCategoryHidden;
    GetCategoryFromArray(categoryId, category);
    FormatEx(sDisplayName, sizeof(sDisplayName), "%s", category.sName);
    bCategoryHidden = category.iVisibleItems == 0;
    DisplayNameForMenu(iClient, sDisplayName, sizeof(sDisplayName), bCategoryHidden);


    Menu mOwnedItemsMenu = CreateMenu(OwnedItemsMenu_Handler);
    mOwnedItemsMenu.SetTitle(sDisplayName);

    char sItemId[20];
    ClanItemId itemId;
    bool bItemHidden;
    for(int i = 0; i < alOwnedItems.Length; ++i)
    {
        itemId = alOwnedItems.Get(i);
        GetItemNameById(itemId, sDisplayName, sizeof(sDisplayName));
        bItemHidden = !GetItemVisibilityById(itemId);

        DisplayNameForMenu(iClient, sDisplayName, sizeof(sDisplayName), bItemHidden);
        FormatEx(sItemId, sizeof(sItemId), "%d", itemId);
        mOwnedItemsMenu.AddItem(sItemId, sDisplayName);
    }

    delete alOwnedItems;
    mOwnedItemsMenu.ExitBackButton = true;
    mOwnedItemsMenu.Display(iClient, 0);
    return true;
}

/**
 * Обработчик инвентаря игрока (предметы в категории)
 */
int OwnedItemsMenu_Handler(Menu mOwnedItemsMenu, MenuAction mAction, int iClient, int iOption)
{
    if(mAction == MenuAction_Select)
    {
        char sItemId[20];
        mOwnedItemsMenu.GetItem(iOption, sItemId, sizeof(sItemId));
        ClanItemId itemId = StringToInt(sItemId);
        if(HasPlayerItem(iClient, itemId))
            ThrowOwnedItem(iClient, itemId, true);
        else
            ThrowItemToBuy(iClient, itemId);
    }
    else if(mAction == MenuAction_End)
    {
        delete mOwnedItemsMenu;
    }
    else if(iOption == MenuCancel_ExitBack && mAction == MenuAction_Cancel)
	{
		ThrowInventoryToClient(iClient);
	}

    return 0;
}

/**
 * Показ админ меню игроку
 * 
 * @param iClient           индекс игрока
 * 
 * @noretun
 */
void ThrowAdminMenuToClient(int iClient)
{
    if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || !HasPlayerAdminFlag(iClient))
        return;

    ClearAdminInfo(iClient);

    Menu mAdminMenu = CreateMenu(AdminMenu_Handler);
    mAdminMenu.SetTitle("%T", "m_AdminMenu", iClient);

    char sDisplayName[256];
    FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_ChangeStock", iClient); //Изменить запас предметов на складе
    mAdminMenu.AddItem("ChangeStock", sDisplayName);
    FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_GiveItemToClan", iClient); //Выдать предмет клану
    mAdminMenu.AddItem("GiveItem", sDisplayName);
    FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_TakeItemFromClan", iClient); //Забрать предмет у клана
    mAdminMenu.AddItem("TakeItem", sDisplayName);
    FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_SetItemLvlInClan", iClient); //Установить уровень предмета клану
    mAdminMenu.AddItem("SetLevel", sDisplayName);
    FormatEx(sDisplayName, sizeof(sDisplayName), "%T", "m_SetItemExpireTimeInClan", iClient); //Установить срок окончания предмета клану
    mAdminMenu.AddItem("SetExpireTime", sDisplayName);

    mAdminMenu.ExitBackButton = true;
    mAdminMenu.Display(iClient, 0);
}

/**
 * Обработчик админ меню
 */
int AdminMenu_Handler(Menu mAdminMenu, MenuAction mAction, int iClient, int iOption)
{
    if(mAction == MenuAction_Select)
    {
        char sItem[20];
        mAdminMenu.GetItem(iOption, sItem, sizeof(sItem));
        if(!strcmp(sItem, "ChangeStock"))
        {
            if(IsAnyItemInList())
            {
                if(ThrowCategoriesToClient(iClient))
                    SetAdminInfo(iClient, AA_ChangeStock, TARGET_NONE, TARGET_NONE);
            }
            else
            {
                ColorPrintToChat(iClient, "%T", "c_NoAvailableItems", iClient);
                ThrowAdminMenuToClient(iClient);
            }
        }
        else if(!strcmp(sItem, "GiveItem"))
        {
            SetAdminInfo(iClient, AA_GiveItemToClan, TARGET_NONE, TARGET_NONE);
            ThrowClansListToAdmin(iClient, false);
        }
        else if(!strcmp(sItem, "TakeItem"))
        {
            SetAdminInfo(iClient, AA_TakeItemFromClan, TARGET_NONE, TARGET_NONE);
            ThrowClansListToAdmin(iClient, true);
        }
        else if(!strcmp(sItem, "SetLevel"))
        {
            SetAdminInfo(iClient, AA_SetItemLvlInClan, TARGET_NONE, TARGET_NONE);
            ThrowClansListToAdmin(iClient, true);
        }
        else if(!strcmp(sItem, "SetExpireTime"))
        {
            SetAdminInfo(iClient, AA_SetExpireTimeInClan, TARGET_NONE, TARGET_NONE);
            ThrowClansListToAdmin(iClient, true);
        }
    }
    else if(mAction == MenuAction_End)
    {
        delete mAdminMenu;
    }
    else if(iOption == MenuCancel_ExitBack && mAction == MenuAction_Cancel)
	{
		ThrowMainMenuToClient(iClient);
	}

    return 0;
}

/**
 * Показ списка кланов администратору
 * 
 * @param iClient       индекс игрока
 * @param bWithItems    флаг, что отбирать кланы с предметами
 * 
 * @noreturn
 */
void ThrowClansListToAdmin(int iClient, bool bWithItems)
{
    if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || !HasPlayerAdminFlag(iClient))
        return;

    char query[128];
    if(bWithItems)
    {
        FormatEx(query, sizeof(query), "SELECT clan_id FROM cshop_clans_items ORDER BY clan_id;");
        g_Database.Query(DBM_GetClanWithItemsCallback, query, iClient);
    }
    else
    {
        FormatEx(query, sizeof(query), "SELECT clan_id, clan_name FROM clans_table ORDER BY clan_id;");
        g_dbClans.Query(DBM_GetClanNamesCallback, query, iClient);
    }
}

// Коллбэк получения ID кланов, у которых есть предметы
void DBM_GetClanWithItemsCallback(Database db, DBResultSet rSet, const char[] sError, int iClient)
{
    if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || !HasPlayerAdminFlag(iClient))
        return;

    if(sError[0])
    {
        LogError("[CSHOP] Failed to get clans with items: %s", sError);
        ColorPrintToChat(iClient, "%T", "c_Error", iClient);
        return;
    }

    if(!rSet.FetchRow())
    {
        ColorPrintToChat(iClient, "%T", "c_NoClansWithItems", iClient);
        return;
    }

    char sClanIds[1024];
    int clanId;
    do
    {
        clanId = rSet.FetchInt(0);
        if(sClanIds[0])
            Format(sClanIds, sizeof(sClanIds), "%s,%d", sClanIds, clanId);
        else
            FormatEx(sClanIds, sizeof(sClanIds), "%d", clanId);
    } while(rSet.FetchRow());

    char query[1024];
    FormatEx(query, sizeof(query), "SELECT clan_id, clan_name FROM clans_table WHERE clan_id IN (%s);", sClanIds);
    g_dbClans.Query(DBM_GetClanNamesCallback, query, iClient);
}

// Коллбэк получения ид и имен кланов
void DBM_GetClanNamesCallback(Database db, DBResultSet rSet, const char[] sError, int iClient)
{
    if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || !HasPlayerAdminFlag(iClient))
        return;

    if(sError[0])
    {
        LogError("[CSHOP] Failed to get clans names: %s", sError);
        ColorPrintToChat(iClient, "%T", "c_Error", iClient);
        return;
    }

    Menu mClans = CreateMenu(ClansList_Handler);
    mClans.SetTitle("%T", "m_Clans", iClient);
    char clanName[MAX_CLAN_NAME+1], sClanId[10];
    int iClanId;
    while(rSet.FetchRow())
    {
        iClanId = rSet.FetchInt(0);
        FormatEx(sClanId, sizeof(sClanId), "%d", iClanId);
        rSet.FetchString(1, clanName, sizeof(clanName));
        mClans.AddItem(sClanId, clanName);
    }

    mClans.ExitBackButton = true;
    mClans.Display(iClient, 0);
}

/**
 * Обработчик списка кланов
 */
int ClansList_Handler(Menu mClans, MenuAction mAction, int iClient, int iOption)
{
    if(mAction == MenuAction_Select)
    {
        char sClanId[10], clanName[MAX_CLAN_NAME+1];
        int style;
        mClans.GetItem(iOption, sClanId, sizeof(sClanId), style, clanName, sizeof(clanName));
        int iClanId = StringToInt(sClanId);
        SetAdminActionClanTarget(iClient, iClanId);
        SetAdminActionClanNameTarget(iClient, clanName);
        AdminAction aAction = GetClientAdminAction(iClient);
        switch(aAction)
        {
            case AA_GiveItemToClan:
            {
                ColorPrintToChat(iClient, "%T", "c_GiveItemTip", iClient);
                ThrowCategoriesToClient(iClient);
            }
            case AA_TakeItemFromClan:
                ThrowClanItemsToClient(iClient, iClanId, clanName);
            case AA_SetItemLvlInClan:
                ThrowClanItemsToClient(iClient, iClanId, clanName);
            case AA_SetExpireTimeInClan:
                ThrowClanItemsToClient(iClient, iClanId, clanName);
            default:
                return 0;
        }
    }
    else if(mAction == MenuAction_End)
    {
        delete mClans;
    }
    else if(iOption == MenuCancel_ExitBack && mAction == MenuAction_Cancel)
	{
		ThrowAdminMenuToClient(iClient);
	}
    return 0;
}

/**
 * Показ предметов клана игроку
 * 
 * @param iClient     индекс игрока
 * @param iClanId     индекс клана
 * @param clanName    название клана
 * @noreturn
 */
void ThrowClanItemsToClient(int iClient, int iClanId, const char[] clanName)
{
    if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || !HasPlayerAdminFlag(iClient))
        return;

    DataPack dp = new DataPack();
    dp.WriteCell(iClient);
    dp.WriteCell(iClanId);
    dp.WriteString(clanName);
    dp.Reset();
    char query[256];
    FormatEx(query, sizeof(query), "SELECT \
                                        item_id, \
                                        (SELECT name FROM cshop_items WHERE id = item_id), \
                                        item_level, \
                                        expire_time \
                                    FROM cshop_clans_items \
                                    WHERE clan_id = %d AND server_id = %d", iClanId, SERVER_ID);
    g_Database.Query(DBM_GetClanItemsCallback, query, dp);
}

/**
 * Коллбэк получения предметов клана
 * 
 * В датапаке: ид игрока, ид клана, название клана
 */
void DBM_GetClanItemsCallback(Database db, DBResultSet rSet, const char[] sError, DataPack dp)
{
    int iClient = dp.ReadCell();
    if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || !HasPlayerAdminFlag(iClient))
    {
        delete dp;
        return;
    }
    
    int iClanId = dp.ReadCell();
    char clanName[MAX_CLAN_NAME+1];
    dp.ReadString(clanName, sizeof(clanName));
    if(sError[0])
    {
        LogError("[CSHOP] Failed to get clan %s (%d ID) items: %s", clanName, iClanId, sError);
        ColorPrintToChat(iClient, "%T", "c_Error", iClient);
        delete dp;
        return;
    }

    Menu mClanItems = CreateMenu(ClanItems_Handler);
    mClanItems.SetTitle("%T", "m_ClanItems", iClient, clanName);
    ClanItemId itemId;
    char    itemDisplay[512], 
            sDuration[128], 
            sLevel[128], 
            sInfo[256+MAX_CLAN_NAME];      // itemId;iClanId;clanName
    int itemLevel, iItemExpireTime;
    while(rSet.FetchRow())
    {
        itemId = rSet.FetchInt(0);
        rSet.FetchString(1, itemDisplay, sizeof(itemDisplay));
        itemLevel = rSet.FetchInt(2);
        int itemMaxLevel = GetItemMaxLevelById(itemId);
        iItemExpireTime = rSet.FetchInt(3);

        DisplayNameForMenu(iClient, itemDisplay, sizeof(itemDisplay));

        int iDuration = iItemExpireTime;
        if(iDuration > 0)
        {
            iDuration -= GetTime();
            SecondsToTime(iDuration, sDuration, sizeof(sDuration), iClient);
        }
        else
            FormatEx(sDuration, sizeof(sDuration), "%T", "Forever", iClient);

        Format(sDuration, sizeof(sDuration), "%T", "m_Duration", iClient, sDuration);
        FormatEx(sLevel, sizeof(sLevel), "%T/%d", "m_Level", iClient, itemLevel, itemMaxLevel);
        Format(itemDisplay, sizeof(itemDisplay), "%s\n%s\n%s", itemDisplay, sDuration, sLevel);

        FormatEx(sInfo, sizeof(sInfo), "%d;%d;%d;%d;%s", itemId, iClanId, itemLevel, iItemExpireTime, clanName);
        mClanItems.AddItem(sInfo, itemDisplay);
    }

    mClanItems.ExitBackButton = true;
    mClanItems.Display(iClient, 0);
    delete dp;
}

/**
 * Обработчик меню предметов клана
 */
int ClanItems_Handler(Menu mClanItems, MenuAction mAction, int iClient, int iOption)
{
    if(mAction == MenuAction_Select)
    {
        char sInfo[256+MAX_CLAN_NAME], 
             sItemInfo[5][64];  // itemId;clanId;itemLvl;itemExpireTime;clanName
        mClanItems.GetItem(iOption, sInfo, sizeof(sInfo));
        ExplodeString(sInfo, ";", sItemInfo, sizeof(sItemInfo), sizeof(sItemInfo[]));
        ClanItemId itemId = StringToInt(sItemInfo[0]);
        int iClanId = StringToInt(sItemInfo[1]);
        char clanName[MAX_CLAN_NAME+1];
        FormatEx(clanName, sizeof(clanName), "%s", sItemInfo[4]);

        AdminAction aAction = GetClientAdminAction(iClient);
        //SetAdminInfo(iClient, aAction, itemId, iClanId, clanName);
        SetAdminActionItemTarget(iClient, itemId);
        switch(aAction)
        {
            case AA_TakeItemFromClan:
            {
                ThrowConfirmTakeItem(iClient, itemId, iClanId, clanName);
            }
            case AA_SetItemLvlInClan:
            {
                char itemName[256];
                GetItemNameById(itemId, itemName, sizeof(itemName));
                DisplayNameForMenu(iClient, itemName, sizeof(itemName));
                int itemLevel = StringToInt(sItemInfo[2]);
                int itemMaxLevel = GetItemMaxLevelById(itemId);
                ColorPrintToChat(iClient, "%T", "c_InputNewLevel", iClient, itemName, clanName, itemLevel, itemMaxLevel);
                //SetAdminInfo(iClient, aAction + AA_Input, itemId, iClanId, clanName);
                SetClientAdminAction(iClient, AA_SetItemLvlInClan + AA_Input);
            }
            case AA_SetExpireTimeInClan:
            {
                ThrowTimeSelectMenu(iClient);
            }
            default:
            {
                ColorPrintToChat(iClient, "%T", "c_Error", iClient);
                ThrowAdminMenuToClient(iClient);
            }
        }
    }
    else if(mAction == MenuAction_End)
    {
        delete mClanItems;
    }
    else if(iOption == MenuCancel_ExitBack && mAction == MenuAction_Cancel)
	{
		ThrowClansListToAdmin(iClient, true);
	}
    return 0;
}

/**
 * Показ меню подтверждения забора предмета у клана
 * 
 * @param iClient      индекс игрока (админа)
 * @param itemId       ид предмета
 * @param iClanId      ид клана
 * @param clanName     название клана
 * @noreturn
 */
void ThrowConfirmTakeItem(int iClient, ClanItemId itemId, int iClanId, const char[] clanName)
{
    if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || !HasPlayerAdminFlag(iClient))
        return;

    char itemName[256], sMenuItem[64], sClanId[10];
    GetItemNameById(itemId, itemName, sizeof(itemName));
    DisplayNameForMenu(iClient, itemName, sizeof(itemName));
    FormatEx(sClanId, sizeof(sClanId), "%d", iClanId);

    Menu mConfirmTakeItem = CreateMenu(ConfirmTakeItem_Handler);
    mConfirmTakeItem.SetTitle("%T", "m_SureToTakeItem", iClient, itemName, clanName);
    FormatEx(sMenuItem, sizeof(sMenuItem), "%T", "m_Yes", iClient);
    mConfirmTakeItem.AddItem(clanName, sMenuItem);
    FormatEx(sMenuItem, sizeof(sMenuItem), "%T", "m_Back", iClient);
    mConfirmTakeItem.AddItem(sClanId, sMenuItem);

    mConfirmTakeItem.Display(iClient, 0);
}

/**
 * Обработчик подтверждения удаления предмета у клана
 */
int ConfirmTakeItem_Handler(Menu mConfirmTakeItem, MenuAction mAction, int iClient, int iOption)
{
    if(mAction == MenuAction_Select)
    {
        char clanName[MAX_CLAN_NAME+1];
        mConfirmTakeItem.GetItem(0, clanName, sizeof(clanName));
        ClanItemId itemId = GetAdminActionItemTarget(iClient);
        int iClanId = GetAdminActionClanTarget(iClient);
        if(iOption == 0)    // Yes
        {
            RemoveItemFromExpiring(itemId, iClanId);
            RemoveItemFromClan(iClanId, itemId);

            char originalItemName[256], itemName[256];  // Уведомление игрока, что предмет забрали
            GetItemNameById(itemId, originalItemName, sizeof(originalItemName));
            for(int i = 1; i <= MaxClients; ++i)
            {
                if(IsClientInGame(i) && Clans_GetClientData(i, CCST_CLANID) == iClanId)
                {
                    FormatEx(itemName, sizeof(itemName), "%s", originalItemName);
                    DisplayNameForMenu(i, itemName, sizeof(itemName));
                    ColorPrintToChat(i, "%T %N", "c_ItemWasTakenByAdmin", i, itemName, iClient);
                }
            }

            ColorPrintToChat(iClient, "%T", "c_ItemWasSuccessfullyTaken", iClient, itemName, clanName);
            ThrowClanItemsToClient(iClient, iClanId, clanName);
        }
        else    // Back
        {
            ThrowClanItemsToClient(iClient, iClanId, clanName);
        }
    }
    else if(mAction == MenuAction_End)
    {
        delete mConfirmTakeItem;
    }
    return 0;
}

/**
 * Throw time selection menu to client
 *
 * @param iClient       client's index
 *
 * @noreturn
 */
void ThrowTimeSelectMenu(int iClient)
{
    char sBuff[300];
    Menu mTimeSelection = CreateMenu(SelectTime_Handler);
    FormatEx(sBuff, sizeof(sBuff), "%T", "m_TimeSelection", iClient);
    mTimeSelection.SetTitle(sBuff);
    FormatEx(sBuff, sizeof(sBuff), "%T", "Forever", iClient);
    mTimeSelection.AddItem("-1", sBuff);
    SecondsToTime(604800, sBuff, sizeof(sBuff), iClient);
    mTimeSelection.AddItem("604800", sBuff);
    SecondsToTime(1209600, sBuff, sizeof(sBuff), iClient);
    mTimeSelection.AddItem("1209600", sBuff);
    SecondsToTime(2592000, sBuff, sizeof(sBuff), iClient);
    mTimeSelection.AddItem("2592000", sBuff);
    FormatEx(sBuff, sizeof(sBuff), "%T", "m_InputTimeByYourself", iClient);
    mTimeSelection.AddItem("self", sBuff);
    mTimeSelection.ExitBackButton = true;
    mTimeSelection.Display(iClient, 0);
}

/**
 * Обработчик выбора нового времени
 */
int SelectTime_Handler(Menu mTimeSelection, MenuAction mAction, int iClient, int iOption)
{
    if(mAction == MenuAction_Select)
    {
        char sMenuItem[10];
        mTimeSelection.GetItem(iOption, sMenuItem, sizeof(sMenuItem));

        ClanItemId itemId = GetAdminActionItemTarget(iClient);
        char clanName[MAX_CLAN_NAME+1];
        GetAdminActionClanNameTarget(iClient, clanName, sizeof(clanName));
        char originalItemName[256], itemName[256];
        GetItemNameById(itemId, originalItemName, sizeof(originalItemName));

        if(sMenuItem[0] == 's') // self
        {
            FormatEx(itemName, sizeof(itemName), "%s", originalItemName);
            DisplayNameForMenu(iClient, itemName, sizeof(itemName));
            ColorPrintToChat(iClient, "%T", "c_InputNewDuration", iClient, itemName, clanName);
            SetClientAdminAction(iClient, AA_SetExpireTimeInClan + AA_Input);
        }
        else
        {
            int iNewDuration = StringToInt(sMenuItem);   // INFINITE or seconds now
            /*int iClanId = GetAdminActionClanTarget(iClient);
            int iDuration = iExpireTime;
            if(iExpireTime != ITEM_INFINITE)
                iExpireTime += GetTime();

            if(!SetClanItemExpireTime(iClanId, itemId, iExpireTime))
            {
                ColorPrintToChat(iClient, "%T", "c_Error", iClient);
                ThrowTimeSelectMenu(iClient);
                return 0;
            }

            char sDurationToDisplay[128];
            TryAddItemToExpiringArray(itemId, iClanId, iExpireTime);
            for(int i = 1; i <= MaxClients; ++i)
            {
                if(IsClientInGame(i) && Clans_GetClientData(i, CCST_CLANID) == iClanId)
                {
                    SecondsToTime(iDuration, sDurationToDisplay, sizeof(sDurationToDisplay), i);
                    FormatEx(itemName, sizeof(itemName), "%s", originalItemName);
                    DisplayNameForMenu(i, itemName, sizeof(itemName));
                    ColorPrintToChat(i, "%T %N", "c_ItemDurationWasChangedByAdmin", i, itemName, sDurationToDisplay, iClient);
                }
            }

            ColorPrintToChat(iClient, "%T", "c_ItemDurationWasSuccessfullyChanged", iClient, itemName, clanName);
            ThrowClanItemsToClient(iClient, iClanId, clanName);*/
            ThrowConfirmNewDurationForItem(iClient, itemId, clanName, iNewDuration);
        }
    }
    else if(mAction == MenuAction_End)
    {
        delete mTimeSelection;
    }
    else if(iOption == MenuCancel_ExitBack && mAction == MenuAction_Cancel)
    {
        char clanName[MAX_CLAN_NAME+1];
        GetAdminActionClanNameTarget(iClient, clanName, sizeof(clanName));
        int iClanId = GetAdminActionClanTarget(iClient);
        ThrowClanItemsToClient(iClient, iClanId, clanName);
    }
    return 0;
}

/**
 * Показ меню подтверждения установки нового времени предмета у клана
 * 
 * @param iClient      индекс игрока (админа)
 * @param itemId       ид предмета
 * @param iClanId      ид клана
 * @param clanName     название клана
 * @param iNewDuration    новая длительность предмета
 * @noreturn
 */
void ThrowConfirmNewDurationForItem(int iClient, ClanItemId itemId, const char[] clanName, int iNewDuration)
{
    if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || !HasPlayerAdminFlag(iClient))
        return;

    char itemName[256], sMenuItem[128], sDurationToDisplay[128], sDuration[10];
    GetItemNameById(itemId, itemName, sizeof(itemName));
    DisplayNameForMenu(iClient, itemName, sizeof(itemName));
    SecondsToTime(iNewDuration, sDurationToDisplay, sizeof(sDurationToDisplay), iClient);
    FormatEx(sDuration, sizeof(sDuration), "%d", iNewDuration);

    Menu mConfirmNewDurationForItem = CreateMenu(ConfirmNewDurationForItem_Handler);
    mConfirmNewDurationForItem.SetTitle("%T", "m_SureToSetNewTimeForItem", iClient, itemName, clanName, sDurationToDisplay);
    FormatEx(sMenuItem, sizeof(sMenuItem), "%T", "m_Yes", iClient);
    mConfirmNewDurationForItem.AddItem(sDuration, sMenuItem);
    FormatEx(sMenuItem, sizeof(sMenuItem), "%T", "m_SetItemExpireTimeInClan", iClient);
    mConfirmNewDurationForItem.AddItem("", sMenuItem);

    mConfirmNewDurationForItem.ExitBackButton = true;
    mConfirmNewDurationForItem.Display(iClient, 0);
}

/**
 * Обработчик подтверждения установки нового времени предмета у клана
 */
int ConfirmNewDurationForItem_Handler(Menu mConfirmNewDurationForItem, MenuAction mAction, int iClient, int iOption)
{
    if(mAction == MenuAction_Select)
    {
        char sDuration[10], sDurationToDisplay[128];
        mConfirmNewDurationForItem.GetItem(0, sDuration, sizeof(sDuration));
        int iDuration = StringToInt(sDuration);

        ClanItemId itemId = GetAdminActionItemTarget(iClient);
        int iClanId = GetAdminActionClanTarget(iClient);
        char clanName[MAX_CLAN_NAME+1];
        GetAdminActionClanNameTarget(iClient, clanName, sizeof(clanName));

        char originalItemName[256], itemName[256];
        GetItemNameById(itemId, originalItemName, sizeof(originalItemName));
        if(iOption == 0)    // Yes
        {
            int iNewExpireTime = iDuration != ITEM_INFINITE ? iDuration + GetTime() : ITEM_INFINITE;
            TryAddItemToExpiringArray(itemId, iClanId, iNewExpireTime);
            SetClanItemExpireTime(iClanId, itemId, iNewExpireTime);

            for(int i = 1; i <= MaxClients; ++i)    // Уведомление игрока, что предмет забрали
            {
                if(IsClientInGame(i) && Clans_GetClientData(i, CCST_CLANID) == iClanId)
                {
                    SecondsToTime(iDuration, sDurationToDisplay, sizeof(sDurationToDisplay), i);
                    FormatEx(itemName, sizeof(itemName), "%s", originalItemName);
                    DisplayNameForMenu(i, itemName, sizeof(itemName));
                    ColorPrintToChat(i, "%T %N", "c_ItemDurationWasChangedByAdmin", i, itemName, sDurationToDisplay, iClient);
                }
            }

            ColorPrintToChat(iClient, "%T", "c_ItemDurationWasSuccessfullyChanged", iClient, itemName, clanName);
            ThrowClanItemsToClient(iClient, iClanId, clanName);
        }
        else    // New time input
        {
            /*FormatEx(itemName, sizeof(itemName), "%s", originalItemName);
            DisplayNameForMenu(iClient, itemName, sizeof(itemName));
            ColorPrintToChat(iClient, "%T", "c_InputNewDuration", iClient, itemName, clanName);
            SetClientAdminAction(iClient, AA_SetExpireTimeInClan + AA_Input);*/
            ThrowTimeSelectMenu(iClient);
        }
    }
    else if(mAction == MenuAction_End)
    {
        delete mConfirmNewDurationForItem;
    }
    else if(iOption == MenuCancel_ExitBack && mAction == MenuAction_Cancel) // Отмена изменения времени
    {
        char clanName[MAX_CLAN_NAME+1];
        GetAdminActionClanNameTarget(iClient, clanName, sizeof(clanName));
        int iClanId = GetAdminActionClanTarget(iClient);
        ThrowClanItemsToClient(iClient, iClanId, clanName);
    }
    return 0;
}