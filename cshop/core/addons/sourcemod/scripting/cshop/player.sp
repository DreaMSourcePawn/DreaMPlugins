/** Список предметов игроков */
ArrayList g_alPlayerItems[MAXPLAYERS+1];

/** Отображение id предмета в индекс предмета в списке */
StringMap g_smItemIdToPlayerItemIndex[MAXPLAYERS+1];

/**
 * Инициализация структур для игроков
 */
void InitPlayerItems()
{
    for(int i = 1; i <= MaxClients; ++i)
    {
        g_alPlayerItems[i] = new ArrayList(sizeof(PlayerItem));
        g_smItemIdToPlayerItemIndex[i] = new StringMap();
    }
}

/**
 * Очищение информации о предметах игрока
 * 
 * @param int iClient - индекс игрока
 */
void ClearPlayerItemInfo(int iClient)
{
    g_alPlayerItems[iClient].Clear();
    g_smItemIdToPlayerItemIndex[iClient].Clear();
}

/**
 * Загрузка игрока из базы данных
 * 
 * @param int iClient - индекс игрока
 * @param int iClientId - ид игрока в базе кланов
 * @param int iClanId - ид клана
 */
void DB_LoadPlayer(int iClient, int iClientId, int iClientClanId)
{
    char query[512];
    FormatEx(query, sizeof(query), "SELECT item_id, item_level, \
                                    expire_time, \
                                    (SELECT state FROM cshop_players_items WHERE server_id = %d AND client_id = %d AND cshop_players_items.item_id = cshop_clans_items.item_id) \
                                    FROM cshop_clans_items \
                                    WHERE cshop_clans_items.server_id = %d AND cshop_clans_items.clan_id = %d AND \
                                    (expire_time > %d OR expire_time = %d);", 
                                    SERVER_ID, iClientId, SERVER_ID, iClientClanId, GetTime(), ITEM_INFINITE);

    DataPack dp = new DataPack();
    dp.WriteCell(iClient);
    dp.WriteCell(iClientId);
    dp.WriteCell(iClientClanId);
    dp.WriteCell(true);             //BETA2 Уведомление о том, что загружены предметы
    dp.Reset();
    g_Database.Query(DB_LoadPlayerCallback, query, dp);
}

/**
 * Загрузка одного предмета для игрока из базы данных
 * 
 * @param int iClient - индекс игрока
 * @param int iClientId - ид игрока в базе кланов
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 */
void DB_LoadItemForPlayer(int iClient, int iClientId, int iClientClanId, ClanItemId itemId)
{
    char query[512];
    FormatEx(query, sizeof(query), "SELECT item_id, item_level, expire_time, \
                                    (SELECT state FROM cshop_players_items WHERE server_id = %d AND client_id = %d AND cshop_players_items.item_id = cshop_clans_items.item_id) \
                                    FROM cshop_clans_items \
                                    WHERE cshop_clans_items.server_id = %d AND cshop_clans_items.clan_id = %d AND \
                                    item_id = %d AND (expire_time > %d OR expire_time = %d);",
                                    SERVER_ID, iClientId, SERVER_ID, iClientClanId, itemId, GetTime(), ITEM_INFINITE);
    DataPack dp = new DataPack();
    dp.WriteCell(iClient);
    dp.WriteCell(iClientId);
    dp.WriteCell(iClientClanId);
    dp.WriteCell(false);
    dp.Reset();
    g_Database.Query(DB_LoadPlayerCallback, query, dp);
}

/**
 * Коллбэк загрузки игрока с базы
 */
void DB_LoadPlayerCallback(Database db, DBResultSet rSet, const char[] sError, DataPack dp)
{
    int iClient = dp.ReadCell();
    int iClientId = dp.ReadCell();
    int iClientClanId = dp.ReadCell();
    bool bIsAnyItemsAdded = false;
    bool bNotifyAboutLoading = dp.ReadCell();   //BETA2
    if(sError[0])
    {
        LogError("[CSHOP] Failed to load player %d: %s", iClientId, sError);
    }
    else if(IsClientInGame(iClient))
    {
        char sSteamId[32];
        GetClientAuthId(iClient, AuthId_Steam2, sSteamId, sizeof(sSteamId));
        ClanItemId itemId;
        int iLevel, iExpireTime;
        CShop_ItemState state;
        CShop_ItemType type;
        while(rSet.FetchRow())
        {
            itemId = rSet.FetchInt(0);
            iLevel = rSet.FetchInt(1);
            iExpireTime = rSet.FetchInt(2);
            if(rSet.IsFieldNull(3))
            {
                state = CSHOP_STATE_UNACTIVE;
                type = GetItemTypeById(itemId);
                if(type == CSHOP_TYPE_TOGGLEABLE)
                    DB_AddItemToClient(sSteamId, iClientId, iClientClanId, itemId, CSHOP_STATE_UNACTIVE);
            }
            else
                state = view_as<CShop_ItemState>(rSet.FetchInt(3));

            if(IsItemInList(itemId))
            {
                AddItemToClient(iClient, itemId, iLevel, state, iExpireTime);
                bIsAnyItemsAdded = true;
            }
        }

        F_OnClientLoaded(iClient, iClientId, iClientClanId);
        if(bIsAnyItemsAdded && bNotifyAboutLoading)
            ColorPrintToChat(iClient, "%T", "c_YouWasLoaded", iClient);
    }
    delete dp;
}

/**
 * Добавить (обновить, если есть) предмет игроку
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета в базе
 * @param int iLevel - уровень предмета
 * @param CShop_ItemState state - состояние предмета
 * @param int iExpireTime - срок действия предмета
 * 
 * @noreturn
 */
void AddItemToClient(int iClient, ClanItemId itemId, int iLevel, CShop_ItemState state, int iExpireTime)
{
    PlayerItem playerItem;
    //if(g_smItemIdToPlayerItemIndex[iClient].GetValue(sItemId, indexInArray))    //Предмет уже есть
    if(GetPlayerItemById(iClient, itemId, playerItem))
    {
        playerItem.iLevel = iLevel;
        playerItem.state = state;
        playerItem.iExpireTime = iExpireTime;
        UpdatePlayerItemById(iClient, itemId, playerItem);
        F_OnItemAddedToClient(iClient, itemId, iLevel, state, iExpireTime);
        return;
    }

    char sItemId[20];
    FormatEx(sItemId, sizeof(sItemId), "%d", itemId);
    playerItem.itemId = itemId;
    playerItem.categoryId = GetItemCategoryIdById(itemId);
    playerItem.iLevel = iLevel;
    playerItem.state = state;
    playerItem.iExpireTime = iExpireTime;
    
    int indexInArray = g_alPlayerItems[iClient].PushArray(playerItem);
    g_smItemIdToPlayerItemIndex[iClient].SetValue(sItemId, indexInArray);
    F_OnItemAddedToClient(iClient, itemId, iLevel, state, iExpireTime);
}

/**
 * Проверка, есть ли у игрока какие-либо предметы
 * 
 * @param iClient     индекс игрока
 * @return            true, если есть, иначе - false
 */
bool HasClientAnyItem(int iClient)
{
    return g_alPlayerItems[iClient].Length > 0;
}

/**
 * Получение списка предметов игрока
 * 
 * @param int iClient - индекс игрока
 * 
 * @return ArrayList список предметов игрока
 */
ArrayList GetClientItems(int iClient)
{
    return g_alPlayerItems[iClient];
}

/**
 * Получение списка категорий (id), в которых у игрока есть предмет
 * 
 * @param iClient     индекс игрока
 * @return            новый ArrayList список id категорий (null, если ничего нет)
 */
ArrayList GetClientItemsCategories(int iClient)
{
    if(g_alPlayerItems[iClient].Length < 1)
        return null;

    ArrayList alCategories = new ArrayList();
    PlayerItem playerItem;
    ClanCategoryId categoryId;
    bool bInList;
    for(int i = 0; i < g_alPlayerItems[iClient].Length; ++i)
    {
        bInList = false;
        g_alPlayerItems[iClient].GetArray(i, playerItem, sizeof(playerItem));
        categoryId = playerItem.categoryId;
        for(int j = 0; !bInList && j < alCategories.Length; ++j)
        {
            if(alCategories.Get(j) == categoryId)
                bInList = true;
        }

        if(!bInList)
            alCategories.Push(categoryId);
    }
    return alCategories;
}

/**
 * Получение id предметов, которыми владеет игрок в указанной категории
 * 
 * @param iClient        индекс игрока
 * @param categoryId     индекс категории
 * @return               новый ArrayList список id предметов (null, если ничего нет)
 */
ArrayList GetClientOwnedItemsIdInCategory(int iClient, ClanCategoryId categoryId)
{
    if(g_alPlayerItems[iClient].Length < 1)
        return null;

    ArrayList alOwnedItems = new ArrayList();

    PlayerItem playerItem;
    for(int i = 0; i < g_alPlayerItems[iClient].Length; ++i)
    {
        g_alPlayerItems[iClient].GetArray(i, playerItem, sizeof(playerItem));
        if(playerItem.categoryId == categoryId)
            alOwnedItems.Push(playerItem.itemId);
    }

    if(alOwnedItems.Length < 1)
        delete alOwnedItems;

    return alOwnedItems;
}

/**
 * Проверка, есть ли предмет у игрока
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - ид предмета
 * 
 * @return true, если есть, иначе - false
 */
bool HasPlayerItem(int iClient, ClanItemId itemId)
{
    int iExpireTime = GetPlayerItemExpireTime(iClient, itemId);
    return !(iExpireTime == 0 || (iExpireTime > 0 && iExpireTime - GetTime() < 1));
}

/**
 * Получение структуры PlayerItem у игрока по id предмета
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * @param PlayerItem playerItem - структура, куда записывать данные
 * 
 * @return true в случае успеха, иначе - false
 */
bool GetPlayerItemById(int iClient, ClanItemId itemId, PlayerItem playerItem)
{
    char sItemId[20];
    FormatEx(sItemId, sizeof(sItemId), "%d", itemId);

    int indexInArray;
    if(!g_smItemIdToPlayerItemIndex[iClient].GetValue(sItemId, indexInArray))
        return false;
    
    g_alPlayerItems[iClient].GetArray(indexInArray, playerItem, sizeof(playerItem));
    return true;
}

/**
 * Обновление структуры PlayerItem у игрока по id предмета
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * @param PlayerItem playerItem - обновленная структура
 * 
 * @return true в случае успеха, иначе - false (нет такого предмета)
 */
bool UpdatePlayerItemById(int iClient, ClanItemId itemId, PlayerItem playerItem)
{
    char sItemId[20];
    FormatEx(sItemId, sizeof(sItemId), "%d", itemId);

    int indexInArray;
    if(!g_smItemIdToPlayerItemIndex[iClient].GetValue(sItemId, indexInArray))
        return false;
    
    g_alPlayerItems[iClient].SetArray(indexInArray, playerItem, sizeof(playerItem));
    return true;
}

/**
 * Удаление предмета у игрока по id предмета
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * 
 * @return true в случае успеха, иначе - false (нет такого предмета)
 */
bool RemovePlayerItemById(int iClient, ClanItemId itemId)
{
    char sItemId[20];
    FormatEx(sItemId, sizeof(sItemId), "%d", itemId);

    int indexInArray;
    if(!g_smItemIdToPlayerItemIndex[iClient].GetValue(sItemId, indexInArray))
        return false;
    
    g_alPlayerItems[iClient].Erase(indexInArray);
    g_smItemIdToPlayerItemIndex[iClient].Remove(sItemId);

    int iIndexInArrayForSnapshot;           // Передвигаем остальные отображения для предметов
    StringMapSnapshot snapShot = g_smItemIdToPlayerItemIndex[iClient].Snapshot();
    for(int i = 0; i < snapShot.Length; ++i)
    {
        snapShot.GetKey(i, sItemId, sizeof(sItemId));
        g_smItemIdToPlayerItemIndex[iClient].GetValue(sItemId, iIndexInArrayForSnapshot);
        if(iIndexInArrayForSnapshot > indexInArray)
            g_smItemIdToPlayerItemIndex[iClient].SetValue(sItemId, --iIndexInArrayForSnapshot);
    }

    F_OnItemRemovedFromClient(iClient, itemId);
    return true;
}

    //================ ПОЛУЧЕНИЕ/ОБНОВЛЕНИЕ ПОЛЕЙ ================//
/**
 * Получить уровень предмета у игрока
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * 
 * @return уровень предмета (0 - предмета нет)
 */
int GetPlayerItemLevel(int iClient, ClanItemId itemId)
{
    PlayerItem playerItem;
    if(!GetPlayerItemById(iClient, itemId, playerItem))
        return 0;
    
    return playerItem.iLevel;
}

/**
 * Установить уровень предмета у игрока
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * @param int iNewLevel - новый уровень предмета
 * 
 * @return true в случае успеха, false иначе
 */
bool SetPlayerItemLevel(int iClient, ClanItemId itemId, int iNewLevel)
{
    if(iNewLevel < 1 || iNewLevel > GetItemMaxLevelById(itemId))
        return false;

    PlayerItem playerItem;
    if(!GetPlayerItemById(iClient, itemId, playerItem))
        return false;
    
    playerItem.iLevel = iNewLevel;
    UpdatePlayerItemById(iClient, itemId, playerItem);

    F_OnClientItemLevelChanged(iClient, itemId, iNewLevel);
    return true;
}

/**
 * Получить состояние предмета у игрока
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * 
 * @return CShop_ItemState state (вернет CSHOP_STATE_NOTBOUGHT если предмета нет)
 */
CShop_ItemState GetPlayerItemState(int iClient, ClanItemId itemId)
{
    PlayerItem playerItem;
    if(!GetPlayerItemById(iClient, itemId, playerItem))
        return CSHOP_STATE_NOTBOUGHT;
    
    return playerItem.state;
}

/**
 * Изменить состояние предмета у игрока
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * @param CShop_ItemState newState - новое состояние
 * 
 * @return CShop_Response ответ на установку
 */
CShop_Response SetPlayerItemState(int iClient, ClanItemId itemId, CShop_ItemState newState)
{
    PlayerItem playerItem;
    if(!GetPlayerItemById(iClient, itemId, playerItem))
        return CSHOP_ITEM_NOT_EXISTS;
    
    CShop_ItemState oldState = playerItem.state;
    if(oldState == newState)
        return CSHOP_SAME_VALUE;

    playerItem.state = newState;
    UpdatePlayerItemById(iClient, itemId, playerItem);

    F_OnClientItemStateChanged(iClient, itemId, newState);

    int iClientId = Clans_GetClientData(iClient, CCST_ID);
    DB_UpdatePlayerItemState(iClientId, itemId, newState);
    return CSHOP_SUCCESS;
}

/**
 * Получить срок окончания предмета у игрока
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * 
 * @return время, когда предмет закончится (unix секунды). 0, если предмета не нашлось
 */
int GetPlayerItemExpireTime(int iClient, ClanItemId itemId)
{
    PlayerItem playerItem;
    if(!GetPlayerItemById(iClient, itemId, playerItem))
        return 0;
    
    return playerItem.iExpireTime;
}

/**
 * Изменить состояние предмета у игрока
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * @param int iNewExpireTime - новый срок действия предмета
 * 
 * @return CShop_Response ответ на установку
 */
CShop_Response SetPlayerItemExpireTime(int iClient, ClanItemId itemId, int iNewExpireTime)
{
    PlayerItem playerItem;
    if(!GetPlayerItemById(iClient, itemId, playerItem))
        return CSHOP_ITEM_NOT_EXISTS;
    
    int iOldExpireTime = playerItem.iExpireTime;
    if(iOldExpireTime == iNewExpireTime)
        return CSHOP_SAME_VALUE;

    playerItem.iExpireTime = iNewExpireTime;
    UpdatePlayerItemById(iClient, itemId, playerItem);

    F_OnClientItemExpireTimeChanged(iClient, itemId, iNewExpireTime);
    return CSHOP_SUCCESS;
}