/**
 * Добавление предмета клану (предмет должен быть зарегистрирован на сервере)
 * 
 * @param int iClanid - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iLevel - уровень предмета
 * @param int iExpireTime - срок действия предмета (INVALIID_TEM_PARAM -> использовать стандартную длительность предмета)
 * 
 * @return true в случае успеха, false - иначе (нет такого предмета/время указано в прошлом/поданный уровень некорректен/выдачу запретили)
 */
native bool CShop_AddItemToClan(int iClanId, ClanItemId itemId, int iLevel = 1, int iExpireTime = INVALID_ITEM_PARAM);

/**
 * Забрать предмет у клана
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * 
 * @noreturn
 */
native void CShop_RemoveItemFromClan(int iClanId, ClanItemId itemId);

/**
 * Изменить состояние предмета у клана
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - id предмета
 * @param int iNewExpireTime - новый срок действия предмета
 * 
 * @return true в случае успеха, иначе - false (поданное время заканчивается в прошлом)
 */
native bool CShop_SetClanItemExpireTime(int iClanId, ClanItemId itemId, int iNewExpireTime);

/**
 * Установить новый уровень предмета клану (предмет должен быть зарегистрирован на сервере)
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iNewLevel - новый уровень предмета
 * 
 * @return true в случае успеха, иначе - false (поданный уровень ниже 1 или выше максимального для предмета)
 */
native bool CShop_SetClanItemLevel(int iClanId, ClanItemId itemId, int iNewLevel);