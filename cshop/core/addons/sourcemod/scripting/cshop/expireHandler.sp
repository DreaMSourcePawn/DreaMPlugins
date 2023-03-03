#define UPDATE_TIME 300.0           // Время, когда список истекающих предметов обновляется

enum struct ExpiringItem
{
    ClanItemId itemId;
    int clanId;
    int expireTime;
}

ArrayList   g_alExpiringItems;      // Собственно здесь все предметы :)

Handle      g_hNextItemTimer = INVALID_HANDLE;                  // Таймер для ближайшего истекающего предмета в списке

int         g_iNextCheckTime;       // Когда будет обновлен список

/**
 * Инициализация списка истекающих предметов
 * 
 * @noreturn
 */
void InitExpiringItemsArray()
{
    g_alExpiringItems = new ArrayList(sizeof(ExpiringItem));
    CreateTimer(1.0, TimerCheckDatabaseConnection);
}

/**
 * Проверка, что база данных готова к работе
 */
Action TimerCheckDatabaseConnection(Handle timer)
{
    if(g_Database == INVALID_HANDLE)
    {
        CreateTimer(1.0, TimerCheckDatabaseConnection);
        return Plugin_Stop;
    }

    CreateTimer(UPDATE_TIME, TimerUpdateExpireItems, 0, TIMER_REPEAT);
    UpdateExpiringItemsArray();
    return Plugin_Stop;
}

/**
 * Обновление списка истекающих предметов
 * 
 * @noreturn
 */
void UpdateExpiringItemsArray()
{
    g_iNextCheckTime = GetTime() + RoundToCeil(UPDATE_TIME);
    DB_GetExpiringItems();
}

/**
 * Таймер для обновления списка предметов
 */
Action TimerUpdateExpireItems(Handle hTimer)
{
    UpdateExpiringItemsArray();
    return Plugin_Continue;
}

/**
 * Таймер удаления истекшего предмета
 */
Action TimerRemoveExpiredItem(Handle hTimer)
{
    ExpiringItem expItem;
    expItem.expireTime = 0;
    while(g_alExpiringItems.Length && expItem.expireTime <= GetTime())
    {
        g_alExpiringItems.GetArray(0, expItem, sizeof(expItem));
        if(expItem.expireTime > GetTime())
            continue;

        ClanItemId itemId = expItem.itemId;
        int iClanId = expItem.clanId;
        RemoveItemFromClan(iClanId, itemId);

        char originalItemName[256], itemName[256];  // Уведомление игрока, что предмет истек
        GetItemNameById(itemId, originalItemName, sizeof(originalItemName));
        for(int i = 1; i <= MaxClients; ++i)
        {
            if(IsClientInGame(i) && Clans_GetClientData(i, CCST_CLANID) == iClanId)
            {
                FormatEx(itemName, sizeof(itemName), "%s", originalItemName);
                DisplayNameForMenu(i, itemName, sizeof(itemName));
                ColorPrintToChat(i, "%T", "c_ItemExpired", i, itemName);
            }
        }

        g_alExpiringItems.Erase(0);
    }

    if(g_alExpiringItems.Length)
    {
        float fRemainingTime = float(expItem.expireTime - GetTime());
        g_hNextItemTimer = CreateTimer(fRemainingTime, TimerRemoveExpiredItem);
    }
    //else g_hNextItemTimer = INVALID_HANDLE;
    return Plugin_Stop;
}

/**
 * Получение списка истекающих предметов из базы
 * 
 * @noreturn
 */
void DB_GetExpiringItems()
{
    char query[256];
    FormatEx(query, sizeof(query), "SELECT item_id, clan_id, expire_time \
                                    FROM cshop_clans_items \
                                    WHERE expire_time > %d AND expire_time < %d \
                                    ORDER BY expire_time ASC;", ITEM_INFINITE, g_iNextCheckTime);
    g_Database.Query(DB_GetExpiringItemsCallback, query);
}

/**
 * Коллбэк получения из базы предметов, которые скоро истекут
 */
void DB_GetExpiringItemsCallback(Database db, DBResultSet rSet, const char[] sError, int iData)
{
    if(sError[0])
    {
        LogError("[CSHOP] Failed to get expiring items: %s", sError);
    }
    else if(rSet.FetchRow())
    {
        ExpiringItem expItem;
        do
        {
            expItem.itemId = rSet.FetchInt(0);
            expItem.clanId = rSet.FetchInt(1);
            expItem.expireTime = rSet.FetchInt(2);
            g_alExpiringItems.PushArray(expItem, sizeof(expItem));
        } while(rSet.FetchRow());

        g_alExpiringItems.GetArray(0, expItem, sizeof(expItem));
        float fRemainingTime = float(expItem.expireTime - GetTime());
        g_hNextItemTimer = CreateTimer(fRemainingTime, TimerRemoveExpiredItem);
    }
}

/**
 * Добавление предмета (который только купили) в текущий список истекающих
 * 
 * Если предмет уже есть в списке, то обновляет его позицию
 * 
 * @param itemId        ид предмета
 * @param clanId        ид клана
 * @param expireTime    время, когда истекает предмет
 * 
 * @noreturn
 */
void TryAddItemToExpiringArray(ClanItemId itemId, int clanId, int expireTime)
{
    /*if(expireTime == ITEM_INFINITE || expireTime > g_iNextCheckTime)
        return false;*/

    ExpiringItem newExpItem;
    newExpItem.itemId = itemId;
    newExpItem.clanId = clanId;
    newExpItem.expireTime = expireTime;

    ExpiringItem expItem;
    int iExistItemIndex = -1;
    bool bAddToArray = expireTime != ITEM_INFINITE && expireTime <= g_iNextCheckTime ? true : false;
    for(int i = 0; i < g_alExpiringItems.Length; ++i)
    {
        g_alExpiringItems.GetArray(i, expItem, sizeof(expItem));
        if(expItem.itemId == itemId && expItem.clanId == clanId)
            iExistItemIndex = i;

        if(expireTime > ITEM_INFINITE && expireTime <= g_iNextCheckTime && expItem.expireTime > expireTime)
        {
            /*if(iExistItemIndex == i-1)  // Прошлый элемент - предмет, который подали
            {
                g_alExpiringItems.SwapAt(i-1, i);
                g_alExpiringItems.GetArray(i, expItem, sizeof(expItem));
                expItem.expireTime = expireTime;
                g_alExpiringItems.SetArray(i, expItem, sizeof(expItem));
                return true;
            }*/
            if(iExistItemIndex == i)   // Текущий элемент - поданный
            {
                expItem.expireTime = expireTime;
                g_alExpiringItems.SetArray(i, expItem, sizeof(expItem));
                bAddToArray = false;
            }
            else
            {
                InsertToArray(newExpItem, i);
                bAddToArray = false;
            }

            if(i == 0)
            {
                if(g_hNextItemTimer != INVALID_HANDLE)
                    KillTimer(g_hNextItemTimer);

                float fRemainingTime = float(expireTime - GetTime());
                g_hNextItemTimer = CreateTimer(fRemainingTime, TimerRemoveExpiredItem);
            }
        }
    }
    if(iExistItemIndex != -1)
    {
        g_alExpiringItems.Erase(iExistItemIndex);
        return;
    }

    if(bAddToArray && g_alExpiringItems.PushArray(newExpItem, sizeof(newExpItem)) == 0)
    {
        float fRemainingTime = float(expireTime - GetTime());
        g_hNextItemTimer = CreateTimer(fRemainingTime, TimerRemoveExpiredItem);
    }
}

/**
 * Удаление предмета из списка истекающих, если он в нем есть
 * 
 * @param itemId     ид предмета
 * @param clanId     ид клана
 * 
 * @return           true, если предмет удален, иначе - false
 */
bool RemoveItemFromExpiring(ClanItemId itemId, int clanId)
{
    ExpiringItem expItem;
    for(int i = 0; i < g_alExpiringItems.Length; ++i)
    {
        g_alExpiringItems.GetArray(i, expItem, sizeof(expItem));
        if(expItem.itemId == itemId && expItem.clanId == clanId)
        {
            g_alExpiringItems.Erase(i);
            return true;
        }
    }

    return false;
}

/**
 * Удаление всех предметов клана из списка истекающих
 * 
 * @param clanId     ид клана
 * @noreturn
 */
void RemoveClanItems(int clanId)
{
    ExpiringItem expItem;
    for(int i = 0; i < g_alExpiringItems.Length; ++i)
    {
        g_alExpiringItems.GetArray(i, expItem, sizeof(expItem));
        if(expItem.clanId == clanId)
        {
            g_alExpiringItems.Erase(i--);
        }
    }
}

/**
 * Добавление нового истекающего предмета в список
 * 
 * @param expItemToInsert       предмет, который вставляется
 * @param index                 индекс, куда вставляется предмет
 * 
 * @noreturn
 */
void InsertToArray(ExpiringItem expItemToInsert, int index)
{
    g_alExpiringItems.ShiftUp(index)
    g_alExpiringItems.SetArray(index, expItemToInsert, sizeof(expItemToInsert));
}