    //================ ОБЩЕЕ ================//
/**
 * Вызывается, когда меняется статус магазина (первоначальная загрузка тут же)
 * 
 * @param bool bActive - магазин активен
 * 
 * @noreturn
 */
forward void CShop_OnShopStatusChange(bool bActive);

/**
 * Вызывается, когда магазин загружен и готов к работе
 * 
 * @noreturn
 */
forward void CShop_OnShopLoaded();

    //================ КЛАНЫ ================//
/**
 * Вызывается, когда предмет добавляется клану
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int& iLevel - уровень предмета
 * @param int& iExpireTime - срок действия предмета (unix время окончания)
 * 
 * @return Plugin_Continue, чтобы разрешить добавление предмета. Значения выше - запретить
 */
forward Action CShop_OnItemAddingToClan(int iClanId, ClanItemId itemId, int& iLevel, int& iExpireTime);

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
forward void CShop_OnItemAddedToClan(int iClanId, ClanItemId itemId, int iLevel, int iExpireTime);

/**
 * Вызывается, когда у клана забрали предмет
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * 
 * @noreturn
 */
forward void CShop_OnItemRemovedFromClan(int iClanId, ClanItemId itemId);

/**
 * Вызывается, когда у клана изменяется срок действия предмета
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iExpireTime - срок действия предмета (unix время окончания)
 * 
 * @noreturn
 */
forward void CShop_OnClanItemExpireTimeChanged(int iClanId, ClanItemId itemId, int iExpireTime);

/**
 * Вызывается, когда у клана изменяется уровень предмета
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iLevel - новый уровень предмета
 * 
 * @noreturn
 */
forward void CShop_OnClanItemLevelChanged(int iClanId, ClanItemId itemId, int iLevel);

/**
 * Вызывается, когда клановый предмет используется
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iLevel - уровень используемого предмета
 * 
 * @noreturn
 */
forward void CShop_OnClanItemUsed(int iClanId, ClanItemId itemId, int iLevel);

    //================ ИГРОКИ ================//
/**
 * Вызывается, когда предметы игрока были загружены
 * 
 * @param int iClient - индекс игрока
 * @param int iClientId - ид игрока в базе кланов
 * @param int iClanId - ид клана игрока
 * 
 * @noreturn
 */
forward void CShop_OnClientLoaded(int iClient, int iClientId, int iClanId);

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
forward void CShop_OnItemAddedToClient(int iClient, ClanItemId itemId, int iLevel, CShop_ItemState state, int iExpireTime);

/**
 * Вызывается, когда у игрока был отобран предмет
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета в базе
 * 
 * @noreturn
 */
forward void CShop_OnItemRemovedFromClient(int iClient, ClanItemId itemId);

/**
 * Вызывается, когда у предмета игрока меняется уровень
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - ид предмета
 * @param int iNewLevel - новый уровень предмета
 * 
 * @noreturn
 */
forward void CShop_OnClientItemLevelChanged(int iClient, ClanItemId itemId, int iNewLevel);

/**
 * Вызывается, когда у предмета игрока меняется состояние
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - ид предмета
 * @param CShop_ItemState newState - новое состояние
 * 
 * @noreturn
 */
forward void CShop_OnClientItemStateChanged(int iClient, ClanItemId itemId, CShop_ItemState newState);

/**
 * Вызывается, когда у предмета игрока меняется срок окончания предмета
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - ид предмета
 * @param int iNewExpireTime - новый срок действия предмета
 * 
 * @noreturn
 */
forward void CShop_OnClientItemExpireTimeChanged(int iClient, ClanItemId itemId, int iNewExpireTime);