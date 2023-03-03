enum CSHOP_INT_ITEM_INFO
{
    CSHOP_ITEM_PRICE = 0,           //Цена покупки
    CSHOP_ITEM_SELLPRICE,           //Цена продажи
    CSHOP_ITEM_DURATION,            //Длительность
    CSHOP_ITEM_AMOUNT_IN_USE,       //Сколько используется (GET ONLY)
    CSHOP_ITEM_AMOUNT_AVAILABLE,    //Доступное значение (GET ONLY)
    CSHOP_ITEM_MAX_AMOUNT,          //Максимальное значение (GET ONLY)
    CSHOP_ITEM_MAX_LEVEL,           //Максимальный уровень
    CSHOP_ITEM_TYPE,                //Тип предмета
    CSHOP_ITEM_VISIBILITY           //Видимость предмета
}

/**
 * Получение информации (int типа) о предмете 
 * 
 * @param ClanItemId itemId - id предмета
 * @param CSHOP_INT_ITEM_INFO itemInfo - желаемая информация о предмете
 */
native int CShop_GetIntItemInfo(ClanItemId itemId, CSHOP_INT_ITEM_INFO itemInfo);

/**
 * Установка новой информации (int типа) о предмете 
 * 
 * @param ClanItemId itemId - id предмета
 * @param CSHOP_INT_ITEM_INFO itemInfo - желаемая новая информация о предмете
 * @param int iNewValue - новое значение
 * 
 * @return CShop_Response ответ на запрос
 */
native CShop_Response CShop_SetIntItemInfo(ClanItemId itemId, CSHOP_INT_ITEM_INFO itemInfo, int iNewValue);

/**
 * Получение списка цен на улучшение предмета
 * 
 * @param ClanItemId itemId - ид предмета
 * 
 * @return список цен (не копия!). Вернет null, если предмет не найден.
 */
native ArrayList CShop_GetItemLevelsPrices(ClanItemId itemId);

/**
 * Установка списка цен на улучшение предмета
 * 
 * @param ClanItemId itemId - ид предмета
 * @param ArrayList alNewLevelsPrices - список новых цен (клонируется в предмет)
 * 
 * @return CShop_Response ответ на запрос
 */
native CShop_Response CShop_SetItemLevelsPrices(ClanItemId itemId, ArrayList alNewLevelsPrices);

/**
 * Получение название категории предмета
 * 
 * @param ClanItemId itemId - ид предмета
 * @param char[] sBuffer - буфер
 * @param int iBufferSize - размер буфера
 */
native void CShop_GetItemCategory(ClanItemId itemId, char[] sBuffer, int iBufferSize);

/**
 * Установка новой категории предмету
 * 
 * @param ClanItemId itemId - ид предмета
 * @param const char[] sCategory - название новой категории
 * 
 * @return CShop_Response ответ на запрос
 */
native CShop_Response CShop_SetItemCategory(ClanItemId itemId, const char[] sCategory);

/**
 * Получение описания предмета
 * 
 * @param ClanItemId itemId - ид предмета
 * @param char[] sBuffer - буфер
 * @param int iBufferSize - размер буфера
 */
native void CShop_GetItemDescription(ClanItemId itemId, char[] sBuffer, int iBufferSize);

/**
 * Установка нового описания предмету
 * 
 * @param ClanItemId itemId - ид предмета
 * @param const char[] sCategory - название новой категории
 * 
 * @return CShop_Response ответ на запрос
 */
native CShop_Response CShop_SetItemDescription(ClanItemId itemId, const char[] sCategory);