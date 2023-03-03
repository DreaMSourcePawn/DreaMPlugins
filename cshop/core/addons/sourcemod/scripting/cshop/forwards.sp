GlobalForward g_gfOnShopStatusChange,
              g_gfOnItemAddingToClan,
              g_gfOnItemAddedToClan,
              g_gfOnItemRemovedFromClan,
              g_gfOnClanItemUsed,
              g_gfOnClanItemExpireTimeChanged,
              g_gfOnClanItemLevelChanged,
              g_gfOnClientLoaded,
              g_gfOnItemAddedToClient,
              g_gfOnItemRemovedFromClient,
              g_gfOnClientItemLevelChanged,
              g_gfOnClientItemStateChanged,
              g_gfOnClientItemExpireTimeChanged;

/** Создание форвардов */
void CreateForwards()
{
    //ОБЩЕЕ
    g_gfOnShopStatusChange = CreateGlobalForward("CShop_OnShopStatusChange", ET_Ignore, Param_Cell);
    //КЛАНЫ
    g_gfOnItemAddingToClan = CreateGlobalForward("CShop_OnItemAddingToClan", ET_Event, Param_Cell, Param_Cell, Param_CellByRef, Param_CellByRef);
    g_gfOnItemAddedToClan = CreateGlobalForward("CShop_OnItemAddedToClan", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
    g_gfOnItemRemovedFromClan = CreateGlobalForward("CShop_OnItemRemovedFromClan", ET_Ignore, Param_Cell, Param_Cell);
    g_gfOnClanItemUsed = CreateGlobalForward("CShop_OnClanItemUsed", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_gfOnClanItemExpireTimeChanged = CreateGlobalForward("CShop_OnClanItemExpireTimeChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_gfOnClanItemLevelChanged = CreateGlobalForward("CShop_OnClanItemLevelChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    //ИГРОКИ
    g_gfOnClientLoaded = CreateGlobalForward("CShop_OnClientLoaded", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_gfOnItemAddedToClient = CreateGlobalForward("CShop_OnItemAddedToClient", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
    g_gfOnItemRemovedFromClient = CreateGlobalForward("CShop_OnItemRemovedFromClient", ET_Ignore, Param_Cell, Param_Cell);
    g_gfOnClientItemLevelChanged = CreateGlobalForward("CShop_OnClientItemLevelChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_gfOnClientItemLevelChanged = CreateGlobalForward("CShop_OnClientItemLevelChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_gfOnClientItemStateChanged = CreateGlobalForward("CShop_OnClientItemStateChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_gfOnClientItemExpireTimeChanged = CreateGlobalForward("CShop_OnClientItemExpireTimeChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

}

    //================ ОБЩЕЕ ================//    
/**
 * Вызывается, когда меняется статус магазина (первоначальная загрузка тут же)
 * 
 * @param bool bActive - магазин активен
 */
void F_OnShopStatusChange(bool bActive)
{
    Call_StartForward(g_gfOnShopStatusChange);
    Call_PushCell(bActive);
    Call_Finish();
}

/**
 * Вызывается, когда магазин был загружен
 */
void F_OnShopLoaded()
{
    Handle plugin;
    Handle thisplugin = GetMyHandle();
    Handle plugIter = GetPluginIterator();
    while (MorePlugins(plugIter))
    {
        plugin = ReadPlugin(plugIter);
        if (plugin != thisplugin && GetPluginStatus(plugin) == Plugin_Running)
        {
            Function func = GetFunctionByName(plugin, "CShop_OnShopLoaded");
            if (func != INVALID_FUNCTION)
            {
                Call_StartFunction(plugin, func);
                Call_Finish();
            }
        }
    }
    delete plugIter;
    delete plugin;
    delete thisplugin;
}
    //================ КЛАНЫ ================//
/**
 * Вызывается, когда предмет добавляется клану
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int& iLevel - уровень предмета
 * @param int& iExpireTime - срок действия предмета
 * 
 * @return true - разрешить добавление предмета, false - запретить
 */
bool F_OnItemAddingToClan(int iClanId, ClanItemId itemId, int& iLevel, int& iExpireTime)
{
    Action action = Plugin_Continue;
    Call_StartForward(g_gfOnItemAddingToClan);
    Call_PushCell(iClanId);
    Call_PushCell(itemId);
    Call_PushCellRef(iLevel);
    Call_PushCellRef(iExpireTime);
    Call_Finish(action);
    return action == Plugin_Continue;
}

/**
 * Вызывается, когда предмет был добавлен клану
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iLevel - уровень предмета
 * @param int iExpireTime - срок действия предмета (unix время окончания)
 * 
 * @noreturn
 */
void F_OnItemAddedToClan(int iClanId, ClanItemId itemId, int iLevel, int iExpireTime)
{
    Call_StartForward(g_gfOnItemAddedToClan);
    Call_PushCell(iClanId);
    Call_PushCell(itemId);
    Call_PushCell(iLevel);
    Call_PushCell(iExpireTime);
    Call_Finish();
}

/**
 * Вызывается, когда у клана забрали предмет
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * 
 * @noreturn
 */
void F_OnItemRemovedFromClan(int iClanId, ClanItemId itemId)
{
    Call_StartForward(g_gfOnItemRemovedFromClan);
    Call_PushCell(iClanId);
    Call_PushCell(itemId);
    Call_Finish();
}

/**
 * Вызывается, когда у клана изменяется срок действия предмета
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iExpireTime - срок действия предмета (unix время окончания)
 * 
 * @noreturn
 */
void F_OnClanItemExpireTimeChanged(int iClanId, ClanItemId itemId, int iExpireTime)
{
    Call_StartForward(g_gfOnClanItemExpireTimeChanged);
    Call_PushCell(iClanId);
    Call_PushCell(itemId);
    Call_PushCell(iExpireTime);
    Call_Finish();
}

/**
 * Вызывается, когда у клана изменяется уровень предмета
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iLevel - новый уровень предмета
 * 
 * @noreturn
 */
void F_OnClanItemLevelChanged(int iClanId, ClanItemId itemId, int iLevel)
{
    Call_StartForward(g_gfOnClanItemLevelChanged);
    Call_PushCell(iClanId);
    Call_PushCell(itemId);
    Call_PushCell(iLevel);
    Call_Finish();
}

    //================ ИГРОКИ ===============//
/**
 * Вызывается, когда предметы игрока были загружены
 * 
 * @param int iClient - индекс игрока
 * @param int iClientId - ид игрока в базе кланов
 * @param int iClanId - ид клана игрока
 */
void F_OnClientLoaded(int iClient, int iClientId, int iClanId)
{
    Call_StartForward(g_gfOnClientLoaded);
    Call_PushCell(iClient);
    Call_PushCell(iClientId);
    Call_PushCell(iClanId);
    Call_Finish();
}

/**
 * Вызывается, когда игроку добавился (загрузился) какой-либо предмет
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета в базе
 * @param int iLevel - уровень предмета
 * @param CShop_ItemState state - состояние предмета
 * @param int iExpireTime - срок действия предмета
 * 
 * @noreturn
 */
void F_OnItemAddedToClient(int iClient, ClanItemId itemId, int iLevel, CShop_ItemState state, int iExpireTime)
{
    Call_StartForward(g_gfOnItemAddedToClient);
    Call_PushCell(iClient);
    Call_PushCell(itemId);
    Call_PushCell(iLevel);
    Call_PushCell(state);
    Call_PushCell(iExpireTime);
    Call_Finish();
}

/**
 * Вызывается, когда у игрока был отобран предмет
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета в базе
 * 
 * @noreturn
 */
void F_OnItemRemovedFromClient(int iClient, ClanItemId itemId)
{
    Call_StartForward(g_gfOnItemRemovedFromClient);
    Call_PushCell(iClient);
    Call_PushCell(itemId);
    Call_Finish();
}

/**
 * Вызывается, когда у предмета игрока меняется уровень
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - ид предмета
 * @param int iNewLevel - новый уровень предмета
 */
void F_OnClientItemLevelChanged(int iClient, ClanItemId itemId, int iNewLevel)
{
    Call_StartForward(g_gfOnClientItemLevelChanged);
    Call_PushCell(iClient);
    Call_PushCell(itemId);
    Call_PushCell(iNewLevel);
    Call_Finish();
}

/**
 * Вызывается, когда у предмета игрока меняется состояние
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - ид предмета
 * @param CShop_ItemState newState - новое состояние
 */
void F_OnClientItemStateChanged(int iClient, ClanItemId itemId, CShop_ItemState newState)
{
    Call_StartForward(g_gfOnClientItemStateChanged);
    Call_PushCell(iClient);
    Call_PushCell(itemId);
    Call_PushCell(newState);
    Call_Finish();
}

/**
 * Вызывается, когда у предмета игрока меняется срок окончания предмета
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - ид предмета
 * @param int iNewExpireTime - новый срок действия предмета
 */
void F_OnClientItemExpireTimeChanged(int iClient, ClanItemId itemId, int iNewExpireTime)
{
    Call_StartForward(g_gfOnClientItemExpireTimeChanged);
    Call_PushCell(iClient);
    Call_PushCell(itemId);
    Call_PushCell(iNewExpireTime);
    Call_Finish();
}

/**
 * Вызывается, когда клановый предмет используется
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iLevel - уровень используемого предмета
 */
void F_OnClanItemUsed(int iClanId, ClanItemId itemId, int iLevel)
{
    Call_StartForward(g_gfOnClanItemUsed);
    Call_PushCell(iClanId);
    Call_PushCell(itemId);
    Call_PushCell(iLevel);
    Call_Finish();
}