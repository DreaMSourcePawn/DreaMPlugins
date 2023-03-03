/**
 * Вызов коллбэка из указанного плагина
 * 
 * @param Handle hPlugin - плагин, в котором вызывает коллбэк
 * @param Function callback - вызываемый коллбэк
 * @param ClanItemId itemId - id предмета
 * @param const char[] sName - имя предмета
 * 
 * @noreturn
 */
void StartRegCallback(Handle hPlugin, Function callback, ClanItemId itemId, const char[] sName)
{
    Call_StartFunction(hPlugin, callback);
    Call_PushCell(itemId);
    Call_PushString(sName);
    Call_Finish();
}

/**
 * Регистрирует предмет
 *
 * @param const char[] sCategory - название категории
 * @param const char[] sName - название предмета
 * @param const char[] sDesc - описание предмета (если указанное описание найдено в файле перевода, то берется оттуда)
 * @param Handle hPluginOwner - плагин, который регистрирует предмет
 * @param Function callback - коллбэк, вызываемый после регистрации
 * 
 * @noreturn
 */
void RegisterItem(const char[] sCategory, const char[] sName, const char[] sDesc, Handle hPluginOwner, Function callback)
{
    ClanItemId itemId;
    if(g_smItemsNameToArrayId.GetValue(sName, itemId))
    {
        ClanItem clanItem;
        g_alItems.GetArray(itemId, clanItem, sizeof(clanItem));
        StartRegCallback(hPluginOwner, callback, clanItem.id, clanItem.sName);
        return;
    }

    DataPack dp = new DataPack();
    dp.WriteCell(hPluginOwner);
    dp.WriteFunction(callback);
    dp.WriteString(sName);
    dp.WriteString(sCategory);
    dp.WriteString(sDesc);
    dp.Reset();

    Transaction txn = SQL_CreateTransaction();
    char query[512];
    FormatEx(query, sizeof(query), "SELECT id, price, sell_price, duration, \
                                    (SELECT COUNT(*) FROM cshop_clans_items WHERE item_id = id), \
                                    max_amount, max_level, type, hidden \
                                    FROM cshop_items WHERE server_id = %d AND name = '%s'", SERVER_ID, sName);
    txn.AddQuery(query);
    FormatEx(query, sizeof(query), "SELECT price FROM cshop_item_levels \
                                    WHERE item_id = (SELECT id FROM cshop_items WHERE server_id = %d AND name = '%s') \
                                    ORDER BY level ASC;",
                                    SERVER_ID, sName);
    txn.AddQuery(query);
    g_Database.Execute(txn, OnGetItemInfoForRegSuccess, OnGetItemInfoForRegFailure, dp);
}

/**
 * Если транзакция по предварительному получении информации о регистрируемом предмете прошла успешно
 */
void OnGetItemInfoForRegSuccess(Database db, DataPack dp, int numQueries, DBResultSet[] rSet, any[] queryData)
{
    if(rSet[0].FetchRow())  //Зарегистрирован
    {
        Handle hPlugin = dp.ReadCell();
        Function callback = dp.ReadFunction();

        char sCategory[256];
        ClanItem clanItem;

        clanItem.id = rSet[0].FetchInt(0);
        dp.ReadString(clanItem.sName, sizeof(clanItem.sName));
        dp.ReadString(sCategory, sizeof(sCategory));
        clanItem.categoryId = RegisterCategory(sCategory);
        dp.ReadString(clanItem.sDesc, sizeof(clanItem.sDesc));
        clanItem.iPrice = rSet[0].FetchInt(1);
        clanItem.iSellPrice = rSet[0].FetchInt(2);
        clanItem.iDuration = rSet[0].FetchInt(3);
        clanItem.iAmount = rSet[0].FetchInt(4);
        clanItem.iMaxAmount = rSet[0].FetchInt(5);
        clanItem.iMaxLevel = rSet[0].FetchInt(6);
        clanItem.type = view_as<CShop_ItemType>(rSet[0].FetchInt(7));
        clanItem.bHidden = rSet[0].FetchInt(8) != 0;
        clanItem.hPluginOwner = hPlugin;

        if(rSet[1].FetchRow())
        {
            ArrayList alLevelPrices = new ArrayList();
            do
            {
                alLevelPrices.Push(rSet[1].FetchInt(0));
            } while(rSet[1].FetchRow());

            clanItem.alLevelsPrices = alLevelPrices;
        }

        AddItemInList(clanItem);

        StartRegCallback(hPlugin, callback, clanItem.id, clanItem.sName);
        delete dp;
    }
    else    //Новый предмет
    {
        char query[256], sName[256], sCategory[256];
        dp.ReadCell();
        dp.ReadFunction();
        dp.ReadString(sName, sizeof(sName));
        dp.ReadString(sCategory, sizeof(sCategory));
        
        FormatEx(query, sizeof(query), "INSERT INTO cshop_items \
                                            (server_id, name, category) \
                                        VALUES \
                                            (%d, '%s', '%s');", SERVER_ID, sName, sCategory);

        dp.Reset();
        g_Database.Query(DB_RegisterItemCallback, query, dp);
    }
}

/**
 * Если транзакция по предварительному получении информации о регистрируемом предмете провалилась
 */
void OnGetItemInfoForRegFailure(Database db, DataPack dp, int numQueries, const char[] sError, int failIndex, any[] queryData)
{
    Handle hPlugin = dp.ReadCell();
    Function callback = dp.ReadFunction();
    char sName[256];
    dp.ReadString(sName, sizeof(sName));
    LogError("[CSHOP] Failed to get info about item %s: %s", sName, sError);
    StartRegCallback(hPlugin, callback, INVALID_ITEM, sName);
    delete dp;
}

/**
 * Коллбэк для регистрации нового предмета
 */
void DB_RegisterItemCallback(Database db, DBResultSet rSet, const char[] sError, DataPack dp)
{
    Handle hPlugin = dp.ReadCell();
    Function callback = dp.ReadFunction();
    if(sError[0])
    {
        LogError(PLUGIN_LOG_NAME ... "Failed to register item: %s", sError);
        char sItemName[256];
        dp.ReadString(sItemName, sizeof(sItemName));
        StartRegCallback(hPlugin, callback, INVALID_ITEM, sItemName);
    }
    else
    {
        char sCategory[256];
        ClanItem clanItem;
        clanItem.id = rSet.InsertId;
        dp.ReadString(clanItem.sName, sizeof(clanItem.sName));
        dp.ReadString(sCategory, sizeof(sCategory));
        clanItem.categoryId = RegisterCategory(sCategory);
        dp.ReadString(clanItem.sDesc, sizeof(clanItem.sDesc));
        clanItem.iPrice = ITEM_NOTBUYABLE,
        clanItem.iSellPrice = ITEM_NOTSELLABLE,
        clanItem.iDuration = ITEM_INFINITE,
        clanItem.iAmount = 0,
        clanItem.iMaxAmount = 0,
        clanItem.iMaxLevel = 1,
        clanItem.alLevelsPrices = null,
        clanItem.type = CSHOP_TYPE_INVALID,
        clanItem.bHidden = true;
        clanItem.hPluginOwner = hPlugin;

        AddItemInList(clanItem);
        StartRegCallback(hPlugin, callback, clanItem.id, clanItem.sName);
    }

    delete dp;
}

/**
 * Снятие всех предметов плагина с регистрации
 * 
 * @param Handle hPlugin - дескриптор плагина, который снимает предметы с регистрации
 * 
 * @noreturn
 */
void UnregisterPlugin(Handle hPlugin)
{
    ClanItem clanItem;

    // Проход по всем предметам
    for(int i = 0; i < g_alItems.Length; ++i)
    {
        g_alItems.GetArray(i, clanItem, sizeof(clanItem));
        if(clanItem.hPluginOwner == hPlugin)
        {
            RemoveItemById(clanItem.id);    //Удаляем предмет из списка
            --i;
        }
    }
}