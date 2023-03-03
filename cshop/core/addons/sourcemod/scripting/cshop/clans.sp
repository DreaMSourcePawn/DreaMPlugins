/**
 * Добавление предмета клану. Добавляет в базу данных автоматически.
 * 
 * @param int iClanid - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iLevel - уровень предмета
 * @param int iExpireTime - срок действия предмета
 * 
 * @return true в случае успеха, false - иначе (нет такого предмета/время указано в прошлом/поданный уровень некорректен/выдачу запретили)
 */
bool AddItemToClan(int iClanId, ClanItemId itemId, int iLevel = 1, int iExpireTime = INVALID_ITEM_PARAM)
{
    DB_AddItemToClan(iClanId, itemId, iLevel, iExpireTime);
    
    ClanItem clanItem;
    if(GetItemById(itemId, clanItem))
    {
        if(iExpireTime == INVALID_ITEM_PARAM)
        {
            iExpireTime = clanItem.iDuration;
            if(iExpireTime != ITEM_INFINITE)
                iExpireTime += GetTime();
        }

        if(!F_OnItemAddingToClan(iClanId, itemId, iLevel, iExpireTime))
            return false;

        if((iExpireTime != ITEM_INFINITE && iExpireTime < GetTime()) || (iLevel < 1 || iLevel > GetItemMaxLevelById(itemId)))
            return false;


        char sSteamId[32];
        for(int i = 1; i <= MaxClients; ++i)                        //Меняем всем игрокам онлайн
        {
            if(IsClientInGame(i) && Clans_GetClientData(i, CCST_CLANID) == iClanId)
            {
                GetClientAuthId(i, AuthId_Steam2, sSteamId, sizeof(sSteamId));
                AddItemToClient(i, itemId, iLevel, CSHOP_STATE_UNACTIVE, iExpireTime);
                if(clanItem.type == CSHOP_TYPE_ONEUSE)
                    DB_AddItemToClient(sSteamId, Clans_GetClientData(i, CCST_ID), iClanId, itemId, CSHOP_STATE_UNACTIVE);
            }
        }

        F_OnItemAddedToClan(iClanId, itemId, iLevel, iExpireTime);
        return true;
    }

    return false;
}

/**
 * Забрать предмет у клана
 * 
 * @param iClanId   ид клана
 * @param itemId    ид предмета
 * 
 * @noreturn
 */
void RemoveItemFromClan(int iClanId, ClanItemId itemId)
{
    DB_RemoveItemFromClan(iClanId, itemId);

    ClanItem clanItem;
    if(GetItemById(itemId, clanItem))
    {
        for(int i = 1; i <= MaxClients; ++i)
        {
            if(IsClientInGame(i) && Clans_GetClientData(i, CCST_CLANID) == iClanId)
            {
                RemovePlayerItemById(i, itemId);
            }
        }
    }

    F_OnItemRemovedFromClan(iClanId, itemId);
}

/**
 * Удаление всех предметов клана
 * 
 * @param int iClanId - ид клана
 * 
 * @noreturn
 */
void DeleteClanItems(int iClanId)
{
    //DB ONLY?
    //Игроков же, наверно, почистит форвард ниже?
    DB_PreDeleteClan(iClanId);
}
    //================ ОБНОВЛЕНИЕ ПОЛЕЙ ================//

/**
 * Изменить состояние предмета у клана
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - id предмета
 * @param int iNewExpireTime - новый срок действия предмета
 * 
 * @return true в случае успеха, иначе - false (поданное время заканчивается в прошлом)
 */
bool SetClanItemExpireTime(int iClanId, ClanItemId itemId, int iNewExpireTime)
{
    if(iNewExpireTime != ITEM_INFINITE && iNewExpireTime < GetTime())
        return false;

    DB_SetClanItemExpireTime(iClanId, itemId, iNewExpireTime);  //Изменяем в базе

    for(int i = 1; i <= MaxClients; ++i)                        //Меняем всем игрокам онлайн
    {
        if(IsClientInGame(i) && Clans_GetClientData(i, CCST_CLANID) == iClanId)
        {
            SetPlayerItemExpireTime(i, itemId, iNewExpireTime);
        }
    }

    F_OnClanItemExpireTimeChanged(iClanId, itemId, iNewExpireTime);

    return true;
}

/**
 * Установить новый уровень предмета клану
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iNewLevel - новый уровень предмета
 * 
 * @return true в случае успеха, иначе - false
 */
bool SetClanItemLevel(int iClanId, ClanItemId itemId, int iNewLevel)
{
    if(iNewLevel < 1 || iNewLevel > GetItemMaxLevelById(itemId))
        return false;

    DB_SetClanItemLevel(iClanId, itemId, iNewLevel);

    for(int i = 1; i <= MaxClients; ++i)
    {
        if(IsClientInGame(i) && Clans_GetClientData(i, CCST_CLANID) == iClanId)
        {
            SetPlayerItemLevel(i, itemId, iNewLevel);
        }
    }

    F_OnClanItemLevelChanged(iClanId, itemId, iNewLevel);

    return true;
}