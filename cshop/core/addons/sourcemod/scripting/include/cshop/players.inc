/**
 * Получить уровень предмета у игрока
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * 
 * @return уровень предмета (0 - предмета нет)
 */
native int CShop_GetPlayerItemLevel(int iClient, ClanItemId itemId);

/**
 * Получить состояние предмета у игрока
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * 
 * @return CShop_ItemState state (вернет CSHOP_STATE_NOTBOUGHT если предмета нет)
 */
native CShop_ItemState CShop_GetPlayerItemState(int iClient, ClanItemId itemId);

/**
 * Получить срок окончания предмета у игрока
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета
 * 
 * @return время, когда предмет закончится (unix секунды). 0, если предмета не нашлось
 */
native int CShop_GetPlayerItemExpireTime(int iClient, ClanItemId itemId);