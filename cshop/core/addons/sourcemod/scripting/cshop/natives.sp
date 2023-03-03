public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("CShop_GetShopDatabase", Native_GetShopDatabase);
    CreateNative("CShop_IsShopLoaded", Native_IsShopLoaded);
    CreateNative("CShop_IsShopActive", Native_IsShopActive);
    CreateNative("CShop_SetShopActive", Native_SetShopActive);

    //=========== REGISTRATION ===========//
    CreateNative("CShop_RegisterItem", Native_RegisterItem);
    CreateNative("CShop_UnregisterMe", Native_UnregisterMe);

    //=========== ITEMS ===========//
    CreateNative("CShop_GetIntItemInfo", Native_GetIntItemInfo);
    CreateNative("CShop_SetIntItemInfo", Native_SetIntItemInfo);
    CreateNative("CShop_GetItemLevelsPrices", Native_GetItemLevelsPrices);
    CreateNative("CShop_SetItemLevelsPrices", Native_SetItemLevelsPrices);
    CreateNative("CShop_GetItemCategory", Native_GetItemCategory);
    CreateNative("CShop_SetItemCategory", Native_SetItemCategory);
    CreateNative("CShop_GetItemDescription", Native_GetItemDescription);
    CreateNative("CShop_SetItemDescription", Native_SetItemDescription);

    //=========== PLAYERS ===========//
    CreateNative("CShop_GetPlayerItemLevel", Native_GetPlayerItemLevel);
    CreateNative("CShop_GetPlayerItemState", Native_GetPlayerItemState);
    CreateNative("CShop_GetPlayerItemExpireTime", Native_GetPlayerItemExpireTime);

    //=========== CLANS ===========//
    CreateNative("CShop_AddItemToClan", Native_AddItemToClan);
    CreateNative("CShop_RemoveItemFromClan", Native_RemoveItemFromClan);
    CreateNative("CShop_SetClanItemExpireTime", Native_SetClanItemExpireTime);
    CreateNative("CShop_SetClanItemLevel", Native_SetClanItemLevel);

    RegPluginLibrary("ClanShop_DreaM");
    return APLRes_Success;
}
        //=========== GENERAL ===========//

/**
 * Получение базы данных магазина
 */
public any Native_GetShopDatabase(Handle hPlugin, int iArgs)
{
    return g_Database;
}

/**
 * Узнать, загружен ли магазин
 * 
 * @return true - активен, false - отключен
 */
public any Native_IsShopLoaded(Handle hPlugin, int iArgs)
{
    return g_Database != null && g_dbClans != null;
}

/**
 * Получение статуса магазина
 * 
 * @return true - активен, false - отключен
 */
public any Native_IsShopActive(Handle hPlugin, int iArgs)
{
    return IsShopActive();
}

/**
 * Установка статуса магазина
 * 
 * @param bool bActive - статус магазин (включен/выключен)
 * 
 * @noreturn
 */
public int Native_SetShopActive(Handle hPlugin, int iArgs)
{
    bool bActive = GetNativeCell(1);
    SetShopStatus(bActive);
    return 0;
}
        //=========== REGISTRATION ===========//

/**
 * Регистрирует предмет
 *
 * @param const char[] sName - название категории
 * @param const char[] sDesc - описание предмета (если указанное описание найдено в файле перевода, то берется оттуда)
 * @param int iPrice - цена предмета
 * @param int iSellPrice - за сколько предмет продается
 * @param int iDuration - длительность предмета
 * @param int iMaxAmount - максимальное число предметов
 * @param CShop_ItemType type - тип предмета
 * @param CShop_RegItemCallback callback - коллбэк, вызываемый после регистрации
 * 
 * @noreturn
 */
public int Native_RegisterItem(Handle hPlugin, int iArgs)
{
    char sName[256], sDesc[256], sCategory[256];
    GetNativeString(1, sCategory, sizeof(sCategory));
    GetNativeString(2, sName, sizeof(sName));
    GetNativeString(3, sDesc, sizeof(sDesc));

    if(!sCategory[0])
        ThrowNativeError(SP_ERROR_PARAM, "[CSHOP] Category name is empty!");
    if(!sName[0])
        ThrowNativeError(SP_ERROR_PARAM, "[CSHOP] Name is empty!");

    Function callback = GetNativeFunction(4);

    RegisterItem(sCategory, sName, sDesc, hPlugin, callback);
    return 0;
}

/**
 * Снятие всех предметов с регистрации
 * @noreturn
 */
public int Native_UnregisterMe(Handle hPlugin, int iArgs)
{
    UnregisterPlugin(hPlugin);
    return 0;
}

        //===================== ITEMS =====================//

/**
 * Получение информации (int типа) о предмете 
 * 
 * @param ClanItemId itemId - id предмета
 * @param CSHOP_INT_ITEM_INFO itemInfo - желаемая информация о предмете
 */
public int Native_GetIntItemInfo(Handle hPlugin, int iArgs)
{
    ClanItemId itemId = GetNativeCell(1);
    CSHOP_INT_ITEM_INFO itemInfo = GetNativeCell(2);
    switch(itemInfo)
    {
        case CSHOP_ITEM_PRICE:              //Цена покупки
        {
            return GetItemPriceById(itemId);
        }
        case CSHOP_ITEM_SELLPRICE:          //Цена продажи
        {
            return GetItemSellPriceById(itemId);
        }
        case CSHOP_ITEM_DURATION:           //Длительность
        {
            return GetItemDurationById(itemId);
        }
        case CSHOP_ITEM_AMOUNT_IN_USE:      //Сколько используется
        {
            return GetItemAmountById(itemId);
        }
        case CSHOP_ITEM_AMOUNT_AVAILABLE:   //Доступное значение
        {
            return GetItemAvailableAmountById(itemId);
        }
        case CSHOP_ITEM_MAX_AMOUNT:         //Максимальное значение
        {
            return GetItemMaxAmountById(itemId);
        }
        case CSHOP_ITEM_MAX_LEVEL:          //Максимальный уровень
        {
            return GetItemMaxLevelById(itemId);
        }
        case CSHOP_ITEM_VISIBILITY:         //Видимость предмета
        {
            return view_as<int>(GetItemVisibilityById(itemId));
        }
        case CSHOP_ITEM_TYPE:               //Тип предмета
        {
            return view_as<int>(GetItemTypeById(itemId));
        }
        default:
        {
            return INVALID_ITEM_PARAM;
        }
    }
}


/**
 * Установка новой информации (int типа) о предмете 
 * 
 * @param ClanItemId itemId - id предмета
 * @param CSHOP_INT_ITEM_INFO itemInfo - желаемая новая информация о предмете
 * @param int iNewValue - новое значение
 * 
 * @return CShop_Response ответ на запрос
 */
public any Native_SetIntItemInfo(Handle hPlugin, int iArgs)
{
    ClanItemId itemId = GetNativeCell(1);
    CSHOP_INT_ITEM_INFO itemInfo = GetNativeCell(2);
    int iNewValue = GetNativeCell(3);
    CShop_Response response;
    switch(itemInfo)
    {
        case CSHOP_ITEM_PRICE:              //Цена покупки
        {
            response = SetItemPriceById(itemId, iNewValue);
            if(response == CSHOP_SUCCESS)
                DB_SetItemPrice(itemId, iNewValue);
        }
        case CSHOP_ITEM_SELLPRICE:          //Цена продажи
        {
            response = SetItemSellPriceById(itemId, iNewValue);
            if(response == CSHOP_SUCCESS)
                DB_SetItemSellPrice(itemId, iNewValue);
        }
        case CSHOP_ITEM_DURATION:           //Длительность
        {
            response = SetItemDurationById(itemId, iNewValue);
            if(response == CSHOP_SUCCESS)
                DB_SetItemDuration(itemId, iNewValue);
        }
        case CSHOP_ITEM_AMOUNT_IN_USE:      //Сколько используется
        {
            response = CSHOP_CANT_BE_CHANGE;
        }
        case CSHOP_ITEM_AMOUNT_AVAILABLE:   //Доступное значение
        {
            response = CSHOP_CANT_BE_CHANGE;
        }
        case CSHOP_ITEM_MAX_AMOUNT:         //Максимальное значение
        {
            response = CSHOP_CANT_BE_CHANGE
        }
        case CSHOP_ITEM_MAX_LEVEL:          //Максимальный уровень
        {
            response = SetItemMaxLevelById(itemId, iNewValue);
            if(response == CSHOP_SUCCESS)
                DB_SetItemMaxLevel(itemId, iNewValue);
        }
        case CSHOP_ITEM_TYPE:               //Тип предмета
        {
            CShop_ItemType type = view_as<CShop_ItemType>(iNewValue);
            response = SetItemTypeById(itemId, type);
            if(response == CSHOP_SUCCESS)
                DB_SetItemType(itemId, type);
        }
        case CSHOP_ITEM_VISIBILITY:         //Видимость предмета
        {
            bool bVisibility = view_as<bool>(iNewValue);
            response = SetItemVisibilityById(itemId, bVisibility);
            if(response == CSHOP_SUCCESS)
                DB_SetItemVisibility(itemId, bVisibility);
        }
        default:
        {
            response = CSHOP_WRONG_PARAM;
        }
    }
    return response;
}

/**
 * Получение списка цен на улучшение предмета
 * 
 * @param ClanItemId itemId - ид предмета
 * 
 * @return список цен (не копия!). Вернет null, если предмет не найден.
 */
public any Native_GetItemLevelsPrices(Handle hPlugin, int iArgs)
{
    ClanItemId itemId = GetNativeCell(1);
    return GetItemLevelsPricesById(itemId);
}

/**
 * Установка списка цен на улучшение предмета
 * 
 * @param ClanItemId itemId - ид предмета
 * @param ArrayList alNewLevelsPrices - список новых цен
 * 
 * @return CShop_Response ответ на запрос
 */
public any Native_SetItemLevelsPrices(Handle hPlugin, int iArgs)
{
    ClanItemId itemId = GetNativeCell(1);
    ArrayList alNewLevelsPrices = GetNativeCell(2);
    CShop_Response response = SetItemLevelsPricesById(itemId, alNewLevelsPrices);
    if(response == CSHOP_SUCCESS)
        DB_SetItemLevelsPrices(itemId, alNewLevelsPrices);
    return response;
}

/**
 * Получение название категории предмета
 * 
 * @param ClanItemId itemId - ид предмета
 * @param char[] sBuffer - буфер
 * @param int iBufferSize - размер буфера
 */
public int Native_GetItemCategory(Handle hPlugin, int iArgs)
{
    ClanItemId itemId = GetNativeCell(1);
    int iBufferSize = GetNativeCell(3);
    char[] sBuffer = new char[iBufferSize];
    GetItemCategoryNameById(itemId, sBuffer, iBufferSize);
    SetNativeString(2, sBuffer, iBufferSize);
    return 0;
}

/**
 * Установка новой категории предмету
 * 
 * @param ClanItemId itemId - ид предмета
 * @param const char[] sCategory - название новой категории
 * 
 * @return CShop_Response ответ на запрос
 */
public any Native_SetItemCategory(Handle hPlugin, int iArgs)
{
    ClanItemId itemId = GetNativeCell(1);
    char sCategory[256];
    GetNativeString(2, sCategory, sizeof(sCategory));
    CShop_Response response = SetItemCategoryNameById(itemId, sCategory);
    if(response == CSHOP_SUCCESS)
        DB_SetItemCategoryName(itemId, sCategory);
    return response;
}

/**
 * Получение описания предмета
 * 
 * @param ClanItemId itemId - ид предмета
 * @param char[] sBuffer - буфер
 * @param int iBufferSize - размер буфера
 */
public int Native_GetItemDescription(Handle hPlugin, int iArgs)
{
    ClanItemId itemId = GetNativeCell(1);
    int iBufferSize = GetNativeCell(3);
    char[] sBuffer = new char[iBufferSize];
    GetItemDescriptionById(itemId, sBuffer, iBufferSize);
    SetNativeString(2, sBuffer, iBufferSize);
    return 0;
}

/**
 * Установка нового описания предмету
 * 
 * @param ClanItemId itemId - ид предмета
 * @param const char[] sCategory - название новой категории
 * 
 * @return CShop_Response ответ на запрос
 */
public any Native_SetItemDescription(Handle hPlugin, int iArgs)
{
    ClanItemId itemId = GetNativeCell(1);
    char sDesc[256];
    GetNativeString(2, sDesc, sizeof(sDesc));
    return SetItemDescriptionById(itemId, sDesc);
}

        //===================== PLAYERS =====================//
/**
 * Получить уровень предмета у игрока
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * 
 * @return уровень предмета (0 - предмета нет)
 */
public int Native_GetPlayerItemLevel(Handle hPlugin, int iArgs)
{
    int iClient = GetNativeCell(1);
    ClanItemId itemId = GetNativeCell(2);
    return GetPlayerItemLevel(iClient, itemId);
}

/**
 * Получить состояние предмета у игрока
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * 
 * @return CShop_ItemState state (вернет CSHOP_STATE_NOTBOUGHT если предмета нет)
 */
public any Native_GetPlayerItemState(Handle hPlugin, int iArgs)
{
    int iClient = GetNativeCell(1);
    ClanItemId itemId = GetNativeCell(2);
    return GetPlayerItemState(iClient, itemId);
}

/**
 * Получить срок окончания предмета у игрока
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * 
 * @return время, когда предмет закончится (unix секунды). 0, если предмета не нашлось
 */
public int Native_GetPlayerItemExpireTime(Handle hPlugin, int iArgs)
{
    int iClient = GetNativeCell(1);
    ClanItemId itemId = GetNativeCell(2);
    return GetPlayerItemExpireTime(iClient, itemId);
}

        //===================== CLANS =====================//
/**
 * Добавление предмета клану
 * 
 * @param int iClanid - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iLevel - уровень предмета
 * @param int iExpireTime - срок действия предмета (INVALIID_TEM_PARAM -> использовать стандартную длительность предмета)
 * 
 * @return true в случае успеха, false - иначе (нет такого предмета/время указано в прошлом/поданный уровень некорректен)
 */
public any Native_AddItemToClan(Handle hPlugin, int iArgs)
{
    int iClanId = GetNativeCell(1);
    ClanItemId itemId = GetNativeCell(2);
    int iLevel = GetNativeCell(3);
    int iExpireTime = GetNativeCell(4);

    return AddItemToClan(iClanId, itemId, iLevel, iExpireTime);
}

/**
 * Забрать предмет у клана
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * 
 * @noreturn
 */
public int Native_RemoveItemFromClan(Handle hPlugin, int iArgs)
{
    int iClanId = GetNativeCell(1);
    ClanItemId itemId = GetNativeCell(2);
    RemoveItemFromClan(iClanId, itemId);
    return 0;
}

/**
 * Изменить состояние предмета у клана
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - id предмета
 * @param int iNewExpireTime - новый срок действия предмета
 * 
 * @return true в случае успеха, иначе - false (поданное время заканчивается в прошлом)
 */
public any Native_SetClanItemExpireTime(Handle hPlugin, int iArgs)
{
    int iClanId = GetNativeCell(1);
    ClanItemId itemId = GetNativeCell(2);
    int iNewExpireTime = GetNativeCell(3);
    return SetClanItemExpireTime(iClanId, itemId, iNewExpireTime);
}

/**
 * Установить новый уровень предмета клану (предмет должен быть зарегистрирован на сервере)
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iNewLevel - новый уровень предмета
 * 
 * @return true в случае успеха, иначе - false (поданный уровень ниже 1 или выше максимального для предмета)
 */
public any Native_SetClanItemLevel(Handle hPlugin, int iArgs)
{
    int iClanId = GetNativeCell(1);
    ClanItemId itemId = GetNativeCell(2);
    int iNewLevel = GetNativeCell(3);
    return SetClanItemLevel(iClanId, itemId, iNewLevel);
}