void RegAdminCmds()
{
    RegAdminCmd("csa_menu", AdminMenuCmd, ADMFLAG_ROOT, "Show admin menu to client");
    RegAdminCmd("csa_changestock", AdminChangeStockMenuCmd, ADMFLAG_ROOT, "Show change stock menu to client");
    //Предмет
    RegAdminCmd("cs_item_stock_add", ItemStockAddCmd, ADMFLAG_ROOT, "Add some items to stock");
    RegAdminCmd("cs_item_stock_set", ItemStockSetCmd, ADMFLAG_ROOT, "Set the number of item in stock");
    //Кланы
    RegAdminCmd("cs_add_to_clan", AddItemToClanCmd, ADMFLAG_ROOT, "Add item to clan");
    RegAdminCmd("cs_take_from_clan", RemoveItemFromClanCmd, ADMFLAG_ROOT, "Take item from clan");
    RegAdminCmd("cs_clear_clan", ClearClanCmd, ADMFLAG_ROOT, "Take all items from clan");
    RegAdminCmd("cs_clan_set_level", SetItemLevelForClanCmd, ADMFLAG_ROOT, "Set new level of item for clan");
    RegAdminCmd("cs_clan_set_expiretime", SetItemExpireTimeForClanCmd, ADMFLAG_ROOT, "Set new expire time of item for clan");
}

        // ================= АДМИН МЕНЮ ================= //
/**
 * Показ админ меню
 * 
 * @param iClient     индекс игрока
 * @param iArgs       число аргументов
 * @return            Plugin_Handled
 */
Action AdminMenuCmd(int iClient, int iArgs)
{
    if(!iClient)
    {
        PrintToServer("[CSHOP] It's not console's command!");
        return Plugin_Handled;
    }

    ThrowAdminMenuToClient(iClient);
    return Plugin_Handled;
}

/**
 * Показ меню изменения числа предметов в магазине
 * 
 * @param iClient     индекс игрока
 * @param iArgs       число аргументов
 * @return            Plugin_Handled
 */
Action AdminChangeStockMenuCmd(int iClient, int iArgs)
{
    if(!iClient)
    {
        PrintToServer("[CSHOP] It's not console's command!");
        return Plugin_Handled;
    }

    if(IsAnyItemInList())
    {
        if(ThrowCategoriesToClient(iClient))
            SetAdminInfo(iClient, AA_ChangeStock, TARGET_NONE, TARGET_NONE);
    }
    else
        ColorPrintToChat(iClient, "%T", "c_NoAvailableItems", iClient);

    return Plugin_Handled;
}

        // ================= ПРЕДМЕТЫ ================= //
/**
 * Добавление предметов на склад
 */
Action ItemStockAddCmd(int iClient, int iArgs)
{
    if(iArgs < 2)
    {
        ReplyToCommand(iClient, "[CSHOP] cs_item_stock_add [item id] [amount to add/take]");
        return Plugin_Handled;
    }
    ClanItemId itemId;
    int iAmount;
    char sBuffer[64];
    GetCmdArg(1, sBuffer, sizeof(sBuffer));
    itemId = StringToInt(sBuffer);
    GetCmdArg(2, sBuffer, sizeof(sBuffer));
    iAmount = StringToInt(sBuffer);

    if(!IsItemInList(itemId))
    {
        ReplyToCommand(iClient, "[CSHOP] There is no item with this item id!");
        return Plugin_Handled;
    }

    if(iAmount == 0)
    {
        ReplyToCommand(iClient, "[CSHOP] Amount to add/take can't be 0!");
        return Plugin_Handled;
    }

    if(!AddItemMaxAmountById(itemId, iAmount))
    {
        ReplyToCommand(iClient, "[CSHOP] Item's stock was updated!");
        DB_ChangeItemMaxAmount(itemId, iAmount);
    }

    return Plugin_Handled;
}

/**
 * Установка числа предметов на складе
 */
Action ItemStockSetCmd(int iClient, int iArgs)
{
    if(iArgs < 2)
    {
        ReplyToCommand(iClient, "[CSHOP] cs_item_stock_set [item id] [amount to set]");
        return Plugin_Handled;
    }

    ClanItemId itemId;
    int iAmount;
    char sBuffer[64];
    GetCmdArg(1, sBuffer, sizeof(sBuffer));
    itemId = StringToInt(sBuffer);
    GetCmdArg(2, sBuffer, sizeof(sBuffer));
    iAmount = StringToInt(sBuffer);

    if(!IsItemInList(itemId))
    {
        ReplyToCommand(iClient, "[CSHOP] There is no item with this item id!");
        return Plugin_Handled;
    }

    if(iAmount < 0)
    {
        ReplyToCommand(iClient, "[CSHOP] Amount can't be less than 0!");
        return Plugin_Handled;
    }

    if(!SetItemMaxAmountById(itemId, iAmount))
    {
        DB_SetItemMaxAmount(itemId, iAmount);
        ReplyToCommand(iClient, "[CSHOP] Item's stock was updated!");
    }

    return Plugin_Handled;
}

        // ================= КЛАНЫ ================= //

/**
 * Добавление предмета клану
 */
Action AddItemToClanCmd(int iClient, int iArgs)
{
    if(iArgs < 4)
    {
        ReplyToCommand(iClient, "[CSHOP] cs_add_to_clan [clan id] [item id] [level] [expire time]");
        return Plugin_Handled;
    }

    int iClanId, itemId, iLevel, iExpireTime;
    char sBuffer[64];
    GetCmdArg(1, sBuffer, sizeof(sBuffer));
    iClanId = StringToInt(sBuffer);
    if(iClanId < 1)
    {
        ReplyToCommand(iClient, "[CSHOP] Clan id cannot be less than 1!");
        return Plugin_Handled;
    }

    GetCmdArg(2, sBuffer, sizeof(sBuffer));
    itemId = StringToInt(sBuffer);
    GetCmdArg(3, sBuffer, sizeof(sBuffer));
    iLevel = StringToInt(sBuffer);
    GetCmdArg(4, sBuffer, sizeof(sBuffer));
    iExpireTime = StringToInt(sBuffer);

    if(AddItemToClan(iClanId, itemId, iLevel, iExpireTime))
        ReplyToCommand(iClient, "[CSHOP] Item was successfully added to clan!");
    else
        ReplyToCommand(iClient, "[CSHOP] Fail! Item wasn't added to clan!");

    return Plugin_Handled;
}

/**
 * Забрать предмет у клана
 */
Action RemoveItemFromClanCmd(int iClient, int iArgs)
{
    if(iArgs < 2)
    {
        ReplyToCommand(iClient, "[CSHOP] cs_take_from_clan [clan id] [item id]");
        return Plugin_Handled;
    }

    int iClanId, itemId;
    char sBuffer[64];
    GetCmdArg(1, sBuffer, sizeof(sBuffer));
    iClanId = StringToInt(sBuffer);
    if(iClanId < 1)
    {
        ReplyToCommand(iClient, "[CSHOP] Clan id cannot be less than 1!");
        return Plugin_Handled;
    }

    GetCmdArg(2, sBuffer, sizeof(sBuffer));
    itemId = StringToInt(sBuffer);

    RemoveItemFromClan(iClanId, itemId);
    ReplyToCommand(iClient, "[CSHOP] Item was successfully taken from clan!");
    return Plugin_Handled;
}

/**
 * Забрать у клана все предметы
 */
Action ClearClanCmd(int iClient, int iArgs)
{
    if(iArgs < 1)
    {
        ReplyToCommand(iClient, "[CSHOP] cs_clear_clan [clan id]");
        return Plugin_Handled;
    }

    int iClanId;
    char sBuffer[64];
    GetCmdArg(1, sBuffer, sizeof(sBuffer));
    iClanId = StringToInt(sBuffer);
    if(iClanId < 1)
    {
        ReplyToCommand(iClient, "[CSHOP] Clan id cannot be less than 1!");
        return Plugin_Handled;
    }

    DeleteClanItems(iClanId);
    ReplyToCommand(iClient, "[CSHOP] The clan was cleared!");

    return Plugin_Handled;
}

/**
 * Установить новый уровень предмета клану
 */
Action SetItemLevelForClanCmd(int iClient, int iArgs)
{
    if(iArgs < 3)
    {
        ReplyToCommand(iClient, "[CSHOP] cs_clan_set_level [clan id] [item id] [new level]");
        return Plugin_Handled;
    }

    int iClanId, itemId, iLevel;
    char sBuffer[64];
    GetCmdArg(1, sBuffer, sizeof(sBuffer));
    iClanId = StringToInt(sBuffer);
    if(iClanId < 1)
    {
        ReplyToCommand(iClient, "[CSHOP] Clan id cannot be less than 1!");
        return Plugin_Handled;
    }

    GetCmdArg(2, sBuffer, sizeof(sBuffer));
    itemId = StringToInt(sBuffer);

    GetCmdArg(3, sBuffer, sizeof(sBuffer));
    iLevel = StringToInt(sBuffer);

    if(SetClanItemLevel(iClanId, itemId, iLevel))
        ReplyToCommand(iClient, "[CSHOP] Item's level was successfully changed!");
    else
        ReplyToCommand(iClient, "[CSHOP] Fail! Item's level wasn't changed!");

    return Plugin_Handled;
}

/**
 * Установить новый срок предмета клану
 */
Action SetItemExpireTimeForClanCmd(int iClient, int iArgs)
{
    if(iArgs < 3)
    {
        ReplyToCommand(iClient, "[CSHOP] cs_clan_set_expiretime [clan id] [item id] [new expire time]");
        return Plugin_Handled;
    }

    int iClanId, itemId, iExpireTime;
    char sBuffer[64];
    GetCmdArg(1, sBuffer, sizeof(sBuffer));
    iClanId = StringToInt(sBuffer);
    if(iClanId < 1)
    {
        ReplyToCommand(iClient, "[CSHOP] Clan id cannot be less than 1!");
        return Plugin_Handled;
    }

    GetCmdArg(2, sBuffer, sizeof(sBuffer));
    itemId = StringToInt(sBuffer);

    GetCmdArg(3, sBuffer, sizeof(sBuffer));
    iExpireTime = StringToInt(sBuffer);

    if(SetClanItemExpireTime(iClanId, itemId, iExpireTime))
        ReplyToCommand(iClient, "[CSHOP] Item's expire time was successfully changed!");
    else
        ReplyToCommand(iClient, "[CSHOP] Fail! Item's expire time wasn't changed!");

    return Plugin_Handled;
}