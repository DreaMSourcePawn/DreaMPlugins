//Действия (купить, улучшить, продать, использовать) тут
//Т.е. действия, направленные на весь клан

/**
 * Игрок покупает предмет
 * 
 * @param iClient       индекс игрока
 * @param itemId        ид предмета
 * @param iPrice        цена покупки
 * @param iExpireTime   срок действия предмета
 * 
 * @noreturn
 */
void ClientBuyItem(int iClient, ClanItemId itemId, int iPrice, int iExpireTime)
{
    int iItemsInUse = GetItemAmountById(itemId);
    int iItemMaxUses = GetItemMaxAmountById(itemId);
    if(iItemMaxUses - iItemsInUse < 1)
    {
        ColorPrintToChat(iClient, "%T", "c_NoAvailableItems", iClient);
        return;
    }

    SetItemAmountById(itemId, ++iItemsInUse);

    int iClientClanId = Clans_GetClientData(iClient, CCST_CLANID);

    DataPack dp = new DataPack();
    dp.WriteCell(iClient);
    dp.WriteCell(iClientClanId);
    dp.WriteCell(true);
    dp.WriteCell(itemId);
    dp.WriteCell(iPrice);
    dp.WriteCell(iExpireTime);
    dp.Reset();

    char query[128];
    FormatEx(query, sizeof(query), "SELECT clan_coins FROM clans_table WHERE clan_id = %d", iClientClanId);
    g_dbClans.Query(DB_GetClanCoinsCallback, query, dp);
}

/**
 * Игрок улучшает предмет
 * 
 * @param iClient                       индекс игрока
 * @param itemId                        ид предмета
 * @param iPrice                        цена покупки
 * @param iLevel                        покупаемый уровень
 * @param bOpenInventoryAfterAction     открыть инвентарь после действия
 * 
 * @noreturn
 */
void ClientUpgradeItem(int iClient, ClanItemId itemId, int iPrice, int iLevel, bool bOpenInventoryAfterAction = false)
{
    int iClientClanId = Clans_GetClientData(iClient, CCST_CLANID);

    DataPack dp = new DataPack();
    dp.WriteCell(iClient);
    dp.WriteCell(iClientClanId);
    dp.WriteCell(false);
    dp.WriteCell(itemId);
    dp.WriteCell(iPrice);
    dp.WriteCell(iLevel);
    dp.WriteCell(bOpenInventoryAfterAction);        //BETA2
    dp.Reset();

    char query[128];
    FormatEx(query, sizeof(query), "SELECT clan_coins FROM clans_table WHERE clan_id = %d", iClientClanId);
    g_dbClans.Query(DB_GetClanCoinsCallback, query, dp);
}

/**
 * Коллбэк, в котором получен ид клана и монеты для покупки предмета
 * 
 * В датапаке: 
 *      iClient, 
 *      iClientClanId, 
 *      bBuy, itemId, 
 *      (iLevel - желаемый уровень ИЛИ iExpireTime - срок действия предмета),
 *      bOpenInventoryAfterAction - открыть инвентарь после действия (для апгрейда)
 */
void DB_GetClanCoinsCallback(Database db, DBResultSet rSet, const char[] sError, DataPack dp)
{
    int iClient = dp.ReadCell();
    int iClientClanId = dp.ReadCell();
    bool bBuy = dp.ReadCell();  //Флаг покупки
    ClanItemId itemId = dp.ReadCell();
    int iPrice = dp.ReadCell();

    if(sError[0])
    {
        if(bBuy)
        {
            AddItemAmountById(itemId, -1);
            if(IsClientInGame(iClient))
            {
                ColorPrintToChat(iClient, "%T", "c_ErrorWithPurchase", iClient);
                ThrowItemToBuy(iClient, itemId);
            }
        }
        else if(IsClientInGame(iClient))
        {
            ColorPrintToChat(iClient, "%T", "c_ErrorWithUpgrade", iClient);
            ThrowOwnedItem(iClient, itemId);
        }

        LogError("[CSHOP] Failed to get clan's coins: %s", sError);
        delete dp;
    }
    else if(IsClientInGame(iClient))
    {
        if(!rSet.FetchRow())
        {
            if(bBuy)
            {
                AddItemAmountById(itemId, -1);
                ColorPrintToChat(iClient, "%T", "c_ErrorWithPurchase", iClient);
                ThrowItemToBuy(iClient, itemId);
            }
            else
            {
                ColorPrintToChat(iClient, "%T", "c_ErrorWithUpgrade", iClient);
                ThrowOwnedItem(iClient, itemId);
            }
            delete dp;
            return;
        }

        int iCoins = rSet.FetchInt(0);
        if(iCoins < iPrice)
        {
            if(bBuy)
            {
                AddItemAmountById(itemId, -1);
                ThrowItemToBuy(iClient, itemId);
            }
            else
                ThrowOwnedItem(iClient, itemId);

            ColorPrintToChat(iClient, "%T", "c_NoEnoughCoins", iClient);
            delete dp;
            return;
        }

        if(!bBuy && !HasPlayerItem(iClient, itemId))
        {
            char itemName[256];
            GetItemNameById(itemId, itemName, sizeof(itemName));
            DisplayNameForMenu(iClient, itemName, sizeof(itemName));
            ColorPrintToChat(iClient, "%T", "c_ErrorWithUpgrade", iClient);
            ColorPrintToChat(iClient, "%T", "c_ItemExpired", iClient, itemName);
            ThrowItemToBuy(iClient, itemId);
            delete dp;
            return;
        }

        dp.Reset();
        Transaction txn = SQL_CreateTransaction();
        char query[256];
        FormatEx(query, sizeof(query), "SELECT clan_coins FROM clans_table WHERE clan_id = %d;", iClientClanId);
        txn.AddQuery(query);
        FormatEx(query, sizeof(query), "UPDATE clans_table SET clan_coins = IF(clan_coins < %d, clan_coins, clan_coins-%d) WHERE clan_id = %d;",
                                            iPrice, iPrice, iClientClanId);
        txn.AddQuery(query);
        FormatEx(query, sizeof(query), "SELECT clan_coins FROM clans_table WHERE clan_id = %d;", iClientClanId);
        txn.AddQuery(query);

        g_dbClans.Execute(txn, DB_TakeClanCoinsSuccess, DB_TakeClanCoinsFailure, dp);
    }
    else
    {
        if(bBuy)
            AddItemAmountById(itemId, -1);
        delete dp;
    }
}

/**
 * Транзакция на изменение монет прошла успешно
 */
void DB_TakeClanCoinsSuccess(Database db, DataPack dp, int numQueries, DBResultSet[] rSet, any[] queryData)
{
    int iClient = dp.ReadCell();
    int iClientClanId = dp.ReadCell();
    bool bBuy = dp.ReadCell();  //Флаг покупки
    ClanItemId itemId = dp.ReadCell();
    int iPrice = dp.ReadCell();
    bool bOpenInventoryAfterAction = false;

    if(!rSet[0].FetchRow())     // Получаем сколько монет было до
    {
        if(bBuy)
        {
            AddItemAmountById(itemId, -1);
            if(IsClientInGame(iClient))
            {
                ColorPrintToChat(iClient, "%T", "c_ErrorWithPurchase", iClient);
                ThrowItemToBuy(iClient, itemId);
            }
        }
        else if(IsClientInGame(iClient))
        {
            ColorPrintToChat(iClient, "%T", "c_ErrorWithUpgrade", iClient);
            ThrowOwnedItem(iClient, itemId);
        }

        LogError("[CSHOP] Failed to fetch row #1 in DB_TakeClanCoinsSuccess");
        delete dp;
        return;
    }

    int iCoinsBefore = rSet[0].FetchInt(0);

    if(!rSet[2].FetchRow())     // Получаем сколько монет было после
    {
        if(bBuy)
        {
            AddItemAmountById(itemId, -1);
            if(IsClientInGame(iClient))
            {
                ColorPrintToChat(iClient, "%T", "c_ErrorWithPurchase", iClient);
                ThrowItemToBuy(iClient, itemId);
            }
        }
        else if(IsClientInGame(iClient))
        {
            ColorPrintToChat(iClient, "%T", "c_ErrorWithUpgrade", iClient);
            ThrowOwnedItem(iClient, itemId);
        }
            
        LogError("[CSHOP] Failed to fetch row #3 in DB_TakeClanCoinsSuccess");
        delete dp;
        return;
    }

    int iCoinsAfter = rSet[2].FetchInt(0);
    if(iCoinsBefore - iCoinsAfter < iPrice)
    {
        if(bBuy)
        {
            AddItemAmountById(itemId, -1);
        }
        if(IsClientInGame(iClient))
        {
            ColorPrintToChat(iClient, "%T", "c_NoEnoughCoins", iClient);
            if(bBuy)
                ThrowItemToBuy(iClient, itemId);
            else
                ThrowOwnedItem(iClient, itemId);
        }
        delete dp;
        return;
    }

    if(bBuy)
    {
        DB_ChangeItemMaxAmount(itemId, -1);
        int iExpireTime = dp.ReadCell();
        AddItemToClan(iClientClanId, itemId, 1, iExpireTime);
        TryAddItemToExpiringArray(iClientClanId, itemId, iExpireTime);
        if(IsClientInGame(iClient))
        {
            char sName[256];
            GetItemNameById(itemId, sName, sizeof(sName));
            DisplayNameForMenu(iClient, sName, sizeof(sName));
            ColorPrintToChat(iClient, "%T", "c_YouBought", iClient, sName);
        }
    }

    else
    {
        int iLevel = dp.ReadCell();
        bOpenInventoryAfterAction = dp.ReadCell();
        SetClanItemLevel(iClientClanId, itemId, iLevel);
        if(IsClientInGame(iClient))
        {
            char sName[256];
            GetItemNameById(itemId, sName, sizeof(sName));
            DisplayNameForMenu(iClient, sName, sizeof(sName));
            ColorPrintToChat(iClient, "%T", "c_YouUpgraded", iClient, sName, iLevel);
        }
    }

    ThrowOwnedItem(iClient, itemId, bOpenInventoryAfterAction); //BETA2

    delete dp;
}

/**
 * Если транзакция по изменению монет у клана провалилась
 */
void DB_TakeClanCoinsFailure(Database db, DataPack dp, int numQueries, const char[] sError, int failIndex, any[] queryData)
{
    int iClient = dp.ReadCell();
    dp.ReadCell(); 
    bool bBuy = dp.ReadCell();
    ClanItemId itemId = dp.ReadCell();

    AddItemAmountById(itemId, -1);

    if(IsClientInGame(iClient))
    {
        ColorPrintToChat(iClient, "%T", "c_ErrorWithPurchase", iClient);
        if(bBuy)
            ThrowItemToBuy(iClient, itemId);
        else
            ThrowOwnedItem(iClient, itemId);
    }

    LogError("[CSHOP] Failed to change clan coins (#%d query): %s", failIndex, sError);
    delete dp;
}

/**
 * Клановый предмет используется
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 */
void ClientUseItem(int iClient, ClanItemId itemId)
{
    if(!HasPlayerItem(iClient, itemId))
    {
        char itemName[256];
        GetItemNameById(itemId, itemName, sizeof(itemName));
        DisplayNameForMenu(iClient, itemName, sizeof(itemName));
        ColorPrintToChat(iClient, "%T", "c_ErrorWithUse", iClient);
        ColorPrintToChat(iClient, "%T", "c_ItemExpired", iClient, itemName);
        ThrowItemToBuy(iClient, itemId);
        return;
    }

    int iClientClanId = Clans_GetClientData(iClient, CCST_CLANID);
    int iLevel = GetPlayerItemLevel(iClient, itemId);

    RemoveItemFromClan(iClientClanId, itemId);
    F_OnClanItemUsed(iClientClanId, itemId, iLevel);
}

/**
 * Игрок продает предмет
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - ид предмета
 * @param int iSellPrice - цена продажи
 * 
 * @noreturn
 */
void ClientSellItem(int iClient, ClanItemId itemId, int iSellPrice)
{
    if(!HasPlayerItem(iClient, itemId))
    {
        char itemName[256];
        GetItemNameById(itemId, itemName, sizeof(itemName));
        DisplayNameForMenu(iClient, itemName, sizeof(itemName));
        ColorPrintToChat(iClient, "%T", "c_ErrorWithSale", iClient);
        ColorPrintToChat(iClient, "%T", "c_ItemExpired", iClient, itemName);
        ThrowItemToBuy(iClient, itemId);
        return;
    }

    int iClientClanId = Clans_GetClientData(iClient, CCST_CLANID);
    
    AddItemAmountById(itemId, -1);
    DB_ChangeItemMaxAmount(itemId, 1);

    RemoveItemFromClan(iClientClanId, itemId);
    Clans_GiveClanCoins(iClientClanId, iSellPrice);

    char sName[256];
    GetItemNameById(itemId, sName, sizeof(sName));
    DisplayNameForMenu(iClient, sName, sizeof(sName));
    ColorPrintToChat(iClient, "%T", "c_YouSold", iClient, sName);

    RemoveItemFromExpiring(itemId, iClientClanId);
    ThrowItemToBuy(iClient, itemId);
}