/** Содержит список ClanItem */
ArrayList g_alItems;

/** Для быстрого поиска: имя -> id в списке g_alItems */
StringMap g_smItemsNameToArrayId;
/** Для быстрого поиска: id в базе -> id в списке g_alItems */
StringMap g_smItemsDbIdToArrayId;

/**
 * Инициализирует все для предметов в магазине
 */
void InitItems()
{
    g_alItems = new ArrayList(sizeof(ClanItem));
    g_smItemsNameToArrayId = new StringMap();
    g_smItemsDbIdToArrayId = new StringMap();
}

/**
 * Проверка, есть ли предметы в списке
 * 
 * @return     true, если есть, иначе - false
 */
bool IsAnyItemInList()
{
    return g_alItems.Length > 0;
}

/**
 * Добавляет предмет в список предметов
 *
 * @param clanItem      структура кланового предмета
 * 
 * @return true в случае успеха, false - предмет уже есть
 */
bool AddItemInList(ClanItem clanItem)
{
    char sItemId[20];
    FormatEx(sItemId, sizeof(sItemId), "%d", clanItem.id);
    int indexInArray;
    if(g_smItemsDbIdToArrayId.GetValue(sItemId, indexInArray))
        return false;

    indexInArray = g_alItems.PushArray(clanItem);                   //Закидываем в список
    g_smItemsNameToArrayId.SetValue(clanItem.sName, indexInArray);      //Создаем связь имя->индекс в списке

    char sId[20];
    FormatEx(sId, sizeof(sId), "%d", clanItem.id);   
    g_smItemsDbIdToArrayId.SetValue(sId, indexInArray);                 //Создаем связь id в базе->индекс в списке

    AddItemToCategory(clanItem.categoryId, clanItem.id, clanItem.bHidden);   //Добавляем в категорию

    int iClientId, iClientClanId;
    for(int i = 1; i <= MaxClients; ++i)        // Грузим предмет игрокам
    {
        if(IsClientInGame(i))
        {
            iClientId = Clans_GetClientData(i, CCST_ID);
            if(iClientId > 0)
            {
                iClientClanId = Clans_GetClientData(i, CCST_CLANID);
                DB_LoadItemForPlayer(i, iClientId, iClientClanId, clanItem.id);
            }
        }
    }
    return true;
}

/**
 * Проверка, есть ли предмет с данным идом в списке
 * 
 * @param itemId        ид предмета
 * 
 * @return true, если есть, иначе - false
 */
bool IsItemInList(ClanItemId itemId)
{
    char sItemId[20];
    FormatEx(sItemId, sizeof(sItemId), "%d", itemId);

    int indexInArray;
    return g_smItemsDbIdToArrayId.GetValue(sItemId, indexInArray);
}

/**
 * Получение структуры ClanItem по id предмета
 * 
 * @param itemId        id предмета
 * @param clanItem      структура, куда записывать данные
 * 
 * @return true в случае успеха, иначе - false
 */
bool GetItemById(ClanItemId itemId, ClanItem clanItem)
{
    char sItemId[20];
    FormatEx(sItemId, sizeof(sItemId), "%d", itemId);

    int indexInArray;
    if(!g_smItemsDbIdToArrayId.GetValue(sItemId, indexInArray))
        return false;

    g_alItems.GetArray(indexInArray, clanItem, sizeof(clanItem));
    return true;
}

/**
 * Обновление структуры ClanItem по id предмета
 * 
 * @param itemId        id предмета
 * @param clanItem      обновленная структура
 * 
 * @return true в случае успеха, иначе - false
 */
bool UpdateItemById(ClanItemId itemId, ClanItem clanItem)
{
    char sItemId[20];
    FormatEx(sItemId, sizeof(sItemId), "%d", itemId);

    int indexInArray;
    if(!g_smItemsDbIdToArrayId.GetValue(sItemId, indexInArray))
        return false;

    g_alItems.SetArray(indexInArray, clanItem, sizeof(clanItem));
    return true;
}

/**
 * Удаление предмета по его id
 * 
 * @param itemId        id предмета
 * 
 * @return true в случае успеха, иначе - false (нет такого предмета)
 */
bool RemoveItemById(ClanItemId itemId)
{
    char sItemId[20];
    FormatEx(sItemId, sizeof(sItemId), "%d", itemId);

    int indexInArray;
    if(!g_smItemsDbIdToArrayId.GetValue(sItemId, indexInArray))
        return false;
    
    ClanItem clanItem;
    g_alItems.GetArray(indexInArray, clanItem, sizeof(clanItem));
    if(clanItem.alLevelsPrices)
        delete clanItem.alLevelsPrices;

    RemoveItemFromCategory(clanItem.categoryId, itemId);

    g_alItems.Erase(indexInArray);
    g_smItemsDbIdToArrayId.Remove(sItemId);
    g_smItemsNameToArrayId.Remove(clanItem.sName);

    int iIndexInArrayForSnapshot;           // Передвигаем остальные отображения для предметов
    StringMapSnapshot dbToArraySnapShot = g_smItemsDbIdToArrayId.Snapshot();
    StringMapSnapshot nameToArraySnapShot = g_smItemsNameToArrayId.Snapshot();
    for(int i = 0; i < dbToArraySnapShot.Length || i < nameToArraySnapShot.Length; ++i)
    {
        if(i < dbToArraySnapShot.Length)
        {
            dbToArraySnapShot.GetKey(i, sItemId, sizeof(sItemId));
            g_smItemsDbIdToArrayId.GetValue(sItemId, iIndexInArrayForSnapshot);
            if(iIndexInArrayForSnapshot > indexInArray)
                g_smItemsDbIdToArrayId.SetValue(sItemId, --iIndexInArrayForSnapshot);
        }
        if(i < nameToArraySnapShot.Length)
        {
            nameToArraySnapShot.GetKey(i, sItemId, sizeof(sItemId));
            g_smItemsNameToArrayId.GetValue(sItemId, iIndexInArrayForSnapshot);
            if(iIndexInArrayForSnapshot > indexInArray)
                g_smItemsNameToArrayId.SetValue(sItemId, --iIndexInArrayForSnapshot);
        }
    }

    for(int i = 1; i <= MaxClients; ++i)        // Убираем предмет у игроков
    {
        if(IsClientInGame(i))
            RemovePlayerItemById(i, itemId);
    }
    return true;
}

    //================ ПОЛУЧЕНИЕ/ОБНОВЛЕНИЕ ПОЛЕЙ ================//
/**
 * Получение названия предмета по его id
 * 
 * @param itemId        id предмета
 * @param sBuffer       буфер, куда записывать название
 * @param iBufferSize   размер буфера
 */
void GetItemNameById(ClanItemId itemId, char[] sBuffer, int iBufferSize)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return;

    FormatEx(sBuffer, iBufferSize, "%s", clanItem.sName);
}

/**
 * Получение индекса категории предмета по его id
 * 
 * @param itemId        id предмета
 * 
 * @return ClanCategoryId - индекс категории
 */
ClanCategoryId GetItemCategoryIdById(ClanItemId itemId)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return INVALID_ITEM;

    return clanItem.categoryId;
}

/**
 * Получение названия категории предмета по его id
 * 
 * @param itemId        id предмета
 * @param sBuffer       буфер, куда записывать название категории
 * @param iBufferSize   размер буфера
 */
void GetItemCategoryNameById(ClanItemId itemId, char[] sBuffer, int iBufferSize)
{
    Category category;
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return;

    GetCategoryFromArray(clanItem.categoryId, category);
    FormatEx(sBuffer, iBufferSize, "%s", category.sName);
}

/**
 * Установка новой категории предмету
 * 
 * @param itemId        ид предмета
 * @param sCategory     название новой категории
 * 
 * @return CShop_Response ответ на запрос
 */
CShop_Response SetItemCategoryNameById(ClanItemId itemId, const char[] sCategory)
{
    if(!sCategory[0])
        return CSHOP_WRONG_PARAM;

    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return CSHOP_ITEM_NOT_EXISTS;

    ClanCategoryId categoryId = RegisterCategory(sCategory);
    if(clanItem.categoryId == categoryId)
        return CSHOP_SAME_VALUE;

    RemoveItemFromCategory(clanItem.categoryId, itemId);

    clanItem.categoryId = categoryId;
    if(UpdateItemById(itemId, clanItem))
        AddItemToCategory(categoryId, itemId, clanItem.bHidden);
    return CSHOP_SUCCESS;
}

/**
 * Получение описания предмета по его id
 * 
 * @param itemId        id предмета
 * @param sBuffer       буфер, куда записывать название категории
 * @param iBufferSize   размер буфера
 */
void GetItemDescriptionById(ClanItemId itemId, char[] sBuffer, int iBufferSize)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return;
    FormatEx(sBuffer, iBufferSize, "%s", clanItem.sDesc);
}

/**
 * Установка описания предмета по его id
 * 
 * @param itemId        id предмета
 * @param sNewDesc      новое описание
 * 
 * @return CShop_Response ответ на установку
 */
CShop_Response SetItemDescriptionById(ClanItemId itemId, const char[] sNewDesc)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return CSHOP_ITEM_NOT_EXISTS;

    if(!strcmp(clanItem.sDesc, sNewDesc))
        return CSHOP_SAME_VALUE;

    FormatEx(clanItem.sDesc, sizeof(clanItem.sDesc), "%s", sNewDesc);
    UpdateItemById(itemId, clanItem);
    return CSHOP_SUCCESS;
}

/**
 * Получение цены предмета по его id
 * 
 * @param itemId        id предмета
 * 
 * @return цена предмета (INVALID_ITEM_PARAM, если предмет получить не удалось)
 */
int GetItemPriceById(ClanItemId itemId)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return INVALID_ITEM_PARAM;
    
    return clanItem.iPrice;
}

/**
 * Установка новой цены предмета по его id
 * 
 * @param itemId        id предмета
 * @param iNewPrice     новая цена
 * 
 * @return CShop_Response ответ на установку
 */
CShop_Response SetItemPriceById(ClanItemId itemId, int iNewPrice)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return CSHOP_ITEM_NOT_EXISTS;

    if(clanItem.iPrice == iNewPrice)
        return CSHOP_SAME_VALUE;
    
    clanItem.iPrice = iNewPrice;
    UpdateItemById(itemId, clanItem);
    return CSHOP_SUCCESS;
}

/**
 * Получение цены продажи предмета по его id
 * 
 * @param itemId        id предмета
 * 
 * @return цена продажи предмета (INVALID_ITEM_PARAM, если предмет получить не удалось)
 */
int GetItemSellPriceById(ClanItemId itemId)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return INVALID_ITEM_PARAM;
    
    return clanItem.iSellPrice;
}

/**
 * Установка новой цены продажи предмета по его id
 * 
 * @param itemId        id предмета
 * @param iNewSellPrice новая цена продажи
 * 
 * @return CShop_Response ответ на установку
 */
CShop_Response SetItemSellPriceById(ClanItemId itemId, int iNewSellPrice)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return CSHOP_ITEM_NOT_EXISTS;

    if(clanItem.iSellPrice == iNewSellPrice)
        return CSHOP_SAME_VALUE;
    
    clanItem.iSellPrice = iNewSellPrice;
    UpdateItemById(itemId, clanItem);
    return CSHOP_SUCCESS;
}

/**
 * Получение длительности действия предмета по его id
 * 
 * @param itemId        id предмета
 * 
 * @return длительность предмета в секундах (INVALID_ITEM_PARAM, если предмет получить не удалось)
 */
int GetItemDurationById(ClanItemId itemId)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return INVALID_ITEM_PARAM;
    
    return clanItem.iDuration;
}

/**
 * Установка новой длительности действия предмета по его id
 * ВНИМАНИЕ! Новая длительность будет применена при НОВЫХ покупках!
 * 
 * @param itemId        id предмета
 * @param iNewDuration  новая длительность
 * 
 * @return CShop_Response ответ на установку
 */
CShop_Response SetItemDurationById(ClanItemId itemId, int iNewDuration)
{
    if(iNewDuration != ITEM_INFINITE && iNewDuration < 1)
        return CSHOP_WRONG_PARAM;

    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return CSHOP_ITEM_NOT_EXISTS;

    if(clanItem.iDuration == iNewDuration)
        return CSHOP_SAME_VALUE;
    
    clanItem.iDuration = iNewDuration;
    UpdateItemById(itemId, clanItem);
    return CSHOP_SUCCESS;
}

/**
 * Получение текущего числа предметов по его id (сколько используется)
 * 
 * @param itemId        id предмета
 * 
 * @return число используемых предметов (INVALID_ITEM_PARAM, если предмет получить не удалось)
 */
int GetItemAmountById(ClanItemId itemId)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return INVALID_ITEM_PARAM;
    
    return clanItem.iAmount;
}

/**
 * Добавить количество предметов по его id (сколько используется)
 * 
 * @param itemId        id предмета
 * @param iAmount       значение для добавления
 * 
 * @return true в случае успеха, иначе - false
 */
bool AddItemAmountById(ClanItemId itemId, int iAmount)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return false;
    
    clanItem.iAmount += iAmount;
    return UpdateItemById(itemId, clanItem);
}

/**
 * Установка нового числа предметов по его id (сколько используется)
 * 
 * @param itemId        id предмета
 * @param iNewAmount    новое значение
 * 
 * @return true в случае успеха, false - иначе
 */
bool SetItemAmountById(ClanItemId itemId, int iNewAmount)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return false;
    
    clanItem.iAmount = iNewAmount;
    return UpdateItemById(itemId, clanItem);
}

/**
 * Получение текущего числа доступных к покупке предметов по его id
 * 
 * @param itemId        id предмета
 * 
 * @return число используемых предметов (INVALID_ITEM_PARAM, если предмет получить не удалось)
 */
int GetItemAvailableAmountById(ClanItemId itemId)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return INVALID_ITEM_PARAM;
    
    return clanItem.iAmount > clanItem.iMaxAmount ? 0 : clanItem.iMaxAmount-clanItem.iAmount;
}

/**
 * Получение максимального числа предметов по его id
 * 
 * @param itemId        id предмета
 * 
 * @return максимальное число предметов (INVALID_ITEM_PARAM, если предмет получить не удалось)
 */
int GetItemMaxAmountById(ClanItemId itemId)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return INVALID_ITEM_PARAM;
    
    return clanItem.iMaxAmount;
}

/**
 * Добавление нового максимального числа предметов по его id
 * 
 * @param itemId        id предмета
 * @param iAmount       число, которое добавляется к максимуму
 * 
 * @return CShop_Response ответ на установку
 */
CShop_Response AddItemMaxAmountById(ClanItemId itemId, int iAmount)
{
    if(iAmount == 0)
        return CSHOP_WRONG_PARAM;

    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return CSHOP_ITEM_NOT_EXISTS;

    if(clanItem.iMaxAmount + iAmount < 0)
        clanItem.iMaxAmount = 0;
    else
        clanItem.iMaxAmount += iAmount;

    UpdateItemById(itemId, clanItem);
    return CSHOP_SUCCESS;
}

/**
 * Установка нового максимального числа предметов по его id
 * 
 * @param itemId            id предмета
 * @param iNewMaxAmount     новый максимум
 * 
 * @return CShop_Response ответ на установку
 */
CShop_Response SetItemMaxAmountById(ClanItemId itemId, int iNewMaxAmount)
{
    if(iNewMaxAmount < 0)
        return CSHOP_WRONG_PARAM;

    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return CSHOP_ITEM_NOT_EXISTS;

    if(clanItem.iMaxAmount == iNewMaxAmount)
        return CSHOP_SAME_VALUE;
    
    clanItem.iMaxAmount = iNewMaxAmount;
    UpdateItemById(itemId, clanItem);
    return CSHOP_SUCCESS;
}

/**
 * Получение максимального уровня предмета по его id
 * 
 * @param itemId        id предмета
 * 
 * @return максимальный уровень предмета (INVALID_ITEM_PARAM, если предмет получить не удалось)
 */
int GetItemMaxLevelById(ClanItemId itemId)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return INVALID_ITEM_PARAM;
    
    return clanItem.iMaxLevel;
}

/**
 * Установка нового максимального уровня предмета по его id
 * 
 * @param itemId        id предмета
 * @param iNewMaxLevel  новый максимальный уровень
 * 
 * @return CShop_Response ответ на установку
 */
CShop_Response SetItemMaxLevelById(ClanItemId itemId, int iNewMaxLevel)
{
    if(iNewMaxLevel < 1)
        return CSHOP_WRONG_PARAM;

    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return CSHOP_ITEM_NOT_EXISTS;

    if(clanItem.iMaxLevel == iNewMaxLevel)
        return CSHOP_SAME_VALUE;
    
    clanItem.iMaxLevel = iNewMaxLevel;
    UpdateItemById(itemId, clanItem);
    return CSHOP_SUCCESS;
}

/**
 * Получение цен уровней предмета (no copy!!!)
 * 
 * @param itemId        ид предмета
 * 
 * @return список цен предмета (null, если у предмета только 1 уровень/предмет не зарегистрирован. 
 *                              В таком случае смотрится цена покупки предмета)
 */
ArrayList GetItemLevelsPricesById(ClanItemId itemId)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return null;
    
    return clanItem.alLevelsPrices;
}

/**
 * Получение цены конкретного уровня предмета
 * 
 * @param itemId        ид предмета
 * @param iLevel        желаемый уровень (2+)
 * 
 * @return цену улучшения (ITEM_NOTBUYABLE если такого уровня нет)
 */
int GetItemLevelPriceById(ClanItemId itemId, int iLevel)
{
    ArrayList alLevelsPrices = GetItemLevelsPricesById(itemId);
    int iMaxLevel = GetItemMaxLevelById(itemId);

    if(iLevel < 2 || iLevel > alLevelsPrices.Length+1 || iLevel > iMaxLevel)
        return ITEM_NOTBUYABLE;

    return alLevelsPrices.Get(iLevel-2);
}

/**
 * Установка цен уровней предмета
 * 
 * @param itemId            ид предмета
 * @param alLevelsPrices    список цен на уровни предмета (начиная со 2-го)
 * 
 * @return CShop_Response ответ на установку
 */
CShop_Response SetItemLevelsPricesById(ClanItemId itemId, ArrayList alLevelsPrices)
{
    if(alLevelsPrices == null)
        return CSHOP_WRONG_PARAM;

    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return CSHOP_ITEM_NOT_EXISTS;

    if(clanItem.alLevelsPrices)
    {
        bool bOneNewAtLeast = false;
        if(alLevelsPrices.Length == clanItem.alLevelsPrices.Length)
        {
            for(int i = 0; !bOneNewAtLeast && i < alLevelsPrices.Length; ++i)
            {
                if(alLevelsPrices.Get(i) != clanItem.alLevelsPrices.Get(i))
                    bOneNewAtLeast = true;
            }
        }
        else
            bOneNewAtLeast = true;

        if(!bOneNewAtLeast)
            return CSHOP_SAME_VALUE;
    
        delete clanItem.alLevelsPrices;
    }
    
    clanItem.alLevelsPrices = alLevelsPrices.Clone();
    UpdateItemById(itemId, clanItem);
    return CSHOP_SUCCESS;
}

/**
 * Получение типа предмета по его id
 * 
 * @param itemId        id предмета
 * 
 * @return тип предмета (CSHOP_TYPE_INVALID, если предмет получить не удалось)
 */
CShop_ItemType GetItemTypeById(ClanItemId itemId)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return CSHOP_TYPE_INVALID;
    
    return clanItem.type;
}

/**
 * Установка нового типа предмета по его id
 * 
 * @param itemId        id предмета
 * @param newType       новый тип
 * 
 * @return CShop_Response ответ на установку
 */
CShop_Response SetItemTypeById(ClanItemId itemId, CShop_ItemType newType)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return CSHOP_ITEM_NOT_EXISTS;

    if(clanItem.type == newType)
        return CSHOP_SAME_VALUE;

    clanItem.type = newType;
    UpdateItemById(itemId, clanItem);
    return CSHOP_SUCCESS;
}

/**
 * Получение видимости предмета по его id
 * 
 * @param itemId        id предмета
 * 
 * @return видимость предмета (false, если предмет получить не удалось)
 */
bool GetItemVisibilityById(ClanItemId itemId)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return false;
    
    return !clanItem.bHidden;
}

/**
 * Установка видимости предмета по его id
 * 
 * @param itemId        id предмета
 * @param bVisible      флаг видимости
 * 
 * @return CShop_Response ответ на установку
 */
CShop_Response SetItemVisibilityById(ClanItemId itemId, bool bVisible)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return CSHOP_ITEM_NOT_EXISTS;
    
    bool bOldHidden = clanItem.bHidden;
    if(bOldHidden == !bVisible) // Если ничего не меняется
        return CSHOP_SAME_VALUE;

    Category category;
    GetCategoryFromArray(clanItem.categoryId, category);
    if(bOldHidden)
        category.iVisibleItems++;
    else
        category.iVisibleItems--;

    UpdateCategoryInArray(clanItem.categoryId, category);

    clanItem.bHidden = !bVisible;
    UpdateItemById(itemId, clanItem);

    return CSHOP_SUCCESS;
}

/**
 * Получение владельца предмета
 * 
 * @param itemId        ид предмета
 * 
 * @return Handle плагина владельца
 */
Handle GetItemOwner(ClanItemId itemId)
{
    ClanItem clanItem;
    if(!GetItemById(itemId, clanItem))
        return INVALID_HANDLE;

    return clanItem.hPluginOwner;
}