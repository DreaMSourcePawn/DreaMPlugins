enum CSHOP_DBERrors
{
	DBER_ITEM_CHANGE_CATEGORY,				// Ошибка смены категории предмета
	DBER_ITEM_SET_PRICE,					// Ошибка установки новой цены предмета
	DBER_ITEM_SET_SELLPRICE,				// Ошибка установки новой цены продажи предмета
	DBER_ITEM_SET_DURATION,					// Ошибка установки новой длительности предмета
	DBER_ITEM_CHANGE_MAX_AMOUNT,			// Ошибка изменения максимального числа предмета
	DBER_ITEM_SET_MAX_AMOUNT,				// Ошибка установки нового максимального числа предмета
	DBER_ITEM_SET_MAX_LEVEL,				// Ошибка установки нового максимального уровня предмета
	DBER_ITEM_SET_LEVELS_PRICES,			// Ошибка установки новых цен на уровни предмета
	DBER_ITEM_SET_TYPE,						// Ошибка установки нового типа предмета
	DBER_ITEM_SET_VISIBILITY,				// Ошибка установки флага видимости предмета

	DBER_ADD_ITEM_TO_CLIENT,				//Ошибка добавления предмета игроку
	DBER_REMOVE_CLIENT_ITEM,				//Ошибка удаления предмета у игрока
	DBER_REMOVE_CLIENT_ITEMS,				//Ошибка удаления всех предметов у игрока
	DBER_CHANGE_STATE_PITEM,				//Ошибка изменения состояния предмета у игрока

	DBER_CLAN_REMOVE,						//Ошибка удаления клана
	DBER_CLAN_ADD_ITEM,						//Ошибка добавления предмета клану
	DBER_CLAN_REMOVE_ITEM,					//Ошибка удаления предмета у клана
	DBER_CLAN__CHANGE_EXPIRE_TIME,			//Ошибка изменения срока действия предмета у клана
	DBER_CLAN_CHANGE_LEVEL					//Ошибка изменения уровня предмета у клана
}

Database g_Database = null,
		 g_dbClans = null;

/**
 * Calls when clans have been loaded
 *
 * @noreturn
*/
public void Clans_OnClansLoaded()
{
	g_dbClans = Clans_GetClanDatabase();
	if(g_Database != null)
		F_OnShopLoaded();
}

/**
 * Подключение к базе данных
 */
void ConnectToDatabase()
{
	if(SQL_CheckConfig("clans_shop"))
		Database.Connect(OnDatabaseConnected, "clans_shop");
	else
		SetFailState("[CSHOP] No database configuration in databases.cfg!");
}

void OnDatabaseConnected(Database db, const char[] sError, any data)
{
	g_Database = db;

	if(g_Database == null)
		SetFailState("[CSHOP] Unable to connect to database: %s", sError);

	char sErrorInQuery[256];
	SQL_FastQuery(g_Database, "CREATE TABLE IF NOT EXISTS cshop_items \
								( \
									server_id SMALLINT NOT NULL, \
									id INT PRIMARY KEY AUTO_INCREMENT, \
                                    name VARCHAR(64) NOT NULL, \
									category VARCHAR(64) NOT NULL, \
									price INT NOT NULL DEFAULT -1, \
									sell_price INT NOT NULL DEFAULT -1, \
									duration INT NOT NULL DEFAULT -1, \
									max_amount INT NOT NULL DEFAULT 0, \
									max_level TINYINT NOT NULL DEFAULT 1, \
									type TINYINT NOT NULL DEFAULT 0, \
									hidden TINYINT NOT NULL DEFAULT 1 \
								) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;");
	
	if(SQL_GetError(db, sErrorInQuery, sizeof(sErrorInQuery)))
		SetFailState("[CSHOP] Unable create table cshop_items: %s", sErrorInQuery);

	SQL_FastQuery(g_Database, "CREATE TABLE IF NOT EXISTS cshop_clans_items \
								( \
									server_id SMALLINT NOT NULL, \
									clan_id INT NOT NULL, \
									item_id INT NOT NULL, \
									item_level TINYINT NOT NULL, \
									expire_time INT NOT NULL, \
									PRIMARY KEY(clan_id, item_id), \
									FOREIGN KEY (item_id) REFERENCES cshop_items(id) ON DELETE CASCADE \
								) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;");

	if(SQL_GetError(db, sErrorInQuery, sizeof(sErrorInQuery)))
		SetFailState("[CSHOP] Unable create table cshop_clans_items: %s", sErrorInQuery);

	SQL_FastQuery(g_Database, "CREATE TABLE IF NOT EXISTS cshop_players_items \
								( \
									server_id SMALLINT NOT NULL, \
									auth CHAR(32) NOT NULL, \
									client_id INT NOT NULL, \
									clan_id INT NOT NULL, \
									item_id INT NOT NULL, \
									state INT NOT NULL, \
									PRIMARY KEY (auth, item_id), \
									FOREIGN KEY (item_id) REFERENCES cshop_items(id) ON DELETE CASCADE, \
									FOREIGN KEY (clan_id) REFERENCES cshop_clans_items(clan_id) ON DELETE CASCADE \
								) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;");

	if(SQL_GetError(db, sErrorInQuery, sizeof(sErrorInQuery)))
		SetFailState("[CSHOP] Unable create table cshop_players_items: %s", sErrorInQuery);

	SQL_FastQuery(g_Database, "CREATE TABLE IF NOT EXISTS cshop_item_levels \
								( \
									item_id INT NOT NULL, \
									level TINYINT NOT NULL, \
									price INT NOT NULL, \
									PRIMARY KEY (item_id, level), \
									FOREIGN KEY (item_id) REFERENCES cshop_items(id) ON DELETE CASCADE \
								) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;");

	if(SQL_GetError(db, sErrorInQuery, sizeof(sErrorInQuery)))
		SetFailState("[CSHOP] Unable create table cshop_item_levels: %s", sErrorInQuery);

	SQL_SetCharset(g_Database, "utf8");

	DB_RemoveExpiredRecords();

	if(g_dbClans != null)
		F_OnShopLoaded();
}

/**
 * Удаление истекших записей в базе
 */
void DB_RemoveExpiredRecords()
{
	char query[128];
	FormatEx(query, sizeof(query), "DELETE FROM cshop_clans_items WHERE expire_time <= %d AND expire_time != %d", GetTime(), ITEM_INFINITE);
	g_Database.Query(DB_RemoveExpiredRecordsCallback, query);
}

/**
 * Коллбэк удаления устаревших записей из базы
 */
void DB_RemoveExpiredRecordsCallback(Database db, DBResultSet rSet, const char[] sError, int iData)
{
	if(sError[0])
		LogError("[CSHOP] Failed to remove expired records: %s", sError);
}

	//==================== ПРЕДМЕТ ====================//
void DB_ItemLogError(Database db, DBResultSet rSet, const char[] sError, DataPack dp)
{
	if(sError[0])
	{
		char err[64];
		ClanItemId itemId = dp.ReadCell();
		CSHOP_DBERrors dbErrorId = dp.ReadCell();
		switch(dbErrorId)
		{
			case DBER_ITEM_CHANGE_CATEGORY: err = "failed to change category";
			case DBER_ITEM_SET_PRICE: err = "failed to set price";
			case DBER_ITEM_SET_SELLPRICE: err = "failed to set sell price";
			case DBER_ITEM_SET_DURATION: err = "failed to set duration";
			case DBER_ITEM_CHANGE_MAX_AMOUNT: err = "failed to change max amount";
			case DBER_ITEM_SET_MAX_AMOUNT: err = "failed to set max amount";
			case DBER_ITEM_SET_MAX_LEVEL: err = "failed to set max level";
			case DBER_ITEM_SET_LEVELS_PRICES: err = "failed to set levels prices";
			case DBER_ITEM_SET_TYPE: err = "failed to set type";
			case DBER_ITEM_SET_VISIBILITY: err = "failed to set visibility";
			default:
			{
				err = "Unknown error";
			}
		}

		LogError("[CSHOP] Failed to update item %d (Error #%d, %s): %s", itemId, view_as<int>(dbErrorId), err, sError);
	}
	delete dp;
}

/**
 * Установка новой категории предмету
 * 
 * @param ClanItemId itemId - ид предмета
 * @param const char[] sCategory - название новой категории
 */
void DB_SetItemCategoryName(ClanItemId itemId, const char[] sCategory)
{
	char query[256];
	FormatEx(query, sizeof(query), "UPDATE cshop_items SET category = '%s' WHERE id = %d", sCategory, itemId);
	DataPack dp = GetItemLogDataPack(itemId, DBER_ITEM_CHANGE_CATEGORY);
	g_Database.Query(DB_ItemLogError, query, dp);
}

/**
 * Установка новой цены предмета по его id
 * 
 * @param ClanItemId itemId - id предмета
 * @param int iNewPrice - новая цена
 */
void DB_SetItemPrice(ClanItemId itemId, int iNewPrice)
{
	char query[256];
	FormatEx(query, sizeof(query), "UPDATE cshop_items SET price = %d WHERE id = %d", iNewPrice, itemId);
	DataPack dp = GetItemLogDataPack(itemId, DBER_ITEM_SET_PRICE);
	g_Database.Query(DB_ItemLogError, query, dp);
}

/**
 * Установка новой цены продажи предмета по его id
 * 
 * @param ClanItemId itemId - id предмета
 * @param int iNewSellPrice - новая цена
 */
void DB_SetItemSellPrice(ClanItemId itemId, int iNewSellPrice)
{
	char query[256];
	FormatEx(query, sizeof(query), "UPDATE cshop_items SET sell_price = %d WHERE id = %d", iNewSellPrice, itemId);
	DataPack dp = GetItemLogDataPack(itemId, DBER_ITEM_SET_SELLPRICE);
	g_Database.Query(DB_ItemLogError, query, dp);
}

/**
 * Установка новой цены продажи предмета по его id
 * 
 * @param ClanItemId itemId - id предмета
 * @param int iNewDuration - новая длительность
 */
void DB_SetItemDuration(ClanItemId itemId, int iNewDuration)
{
	char query[256];
	FormatEx(query, sizeof(query), "UPDATE cshop_items SET duration = %d WHERE id = %d", iNewDuration, itemId);
	DataPack dp = GetItemLogDataPack(itemId, DBER_ITEM_SET_DURATION);
	g_Database.Query(DB_ItemLogError, query, dp);
}

/**
 * Изменение нового максимального числа предметов по его id на iAmount
 * 
 * @param ClanItemId itemId - id предмета
 * @param int iAmount - число, которое добавляется к максимуму
 */
void DB_ChangeItemMaxAmount(ClanItemId itemId, int iAmount)
{
	char query[256];
	FormatEx(query, sizeof(query), "UPDATE cshop_items SET max_amount = IF(max_amount + %d < 0, 0, max_amount + %d) WHERE id = %d", 
									iAmount, iAmount, itemId);
	DataPack dp = GetItemLogDataPack(itemId, DBER_ITEM_CHANGE_MAX_AMOUNT);
	g_Database.Query(DB_ItemLogError, query, dp);
}

/**
 * Установка нового максимального числа предметов по его id
 * 
 * @param ClanItemId itemId - id предмета
 * @param int iNewMaxAmount - новый максимум
 */
void DB_SetItemMaxAmount(ClanItemId itemId, int iNewMaxAmount)
{
	char query[256];
	FormatEx(query, sizeof(query), "UPDATE cshop_items SET max_amount = %d WHERE id = %d", iNewMaxAmount, itemId);
	DataPack dp = GetItemLogDataPack(itemId, DBER_ITEM_SET_MAX_AMOUNT);
	g_Database.Query(DB_ItemLogError, query, dp);
}

/**
 * Установка нового максимального уровня предмета по его id
 * 
 * @param ClanItemId itemId - id предмета
 * @param int iNewMaxLevel - новый максимальный уровень
 */
void DB_SetItemMaxLevel(ClanItemId itemId, int iNewMaxLevel)
{
	char query[256];
	FormatEx(query, sizeof(query), "UPDATE cshop_items SET max_level = %d WHERE id = %d", iNewMaxLevel, itemId);
	DataPack dp = GetItemLogDataPack(itemId, DBER_ITEM_SET_MAX_LEVEL);
	g_Database.Query(DB_ItemLogError, query, dp);
}

/**
 * Установка цен уровней предмета
 * 
 * @param ClanItemId itemId - ид предмета
 * @param ArrayList alLevelsPrices - список цен на уровни предмета (начиная со 2-го)
 */
void DB_SetItemLevelsPrices(ClanItemId itemId, ArrayList alLevelsPrices)
{
	char query[1024];
	FormatEx(query, sizeof(query), "INSERT INTO cshop_item_levels VALUES ");
	for(int i = 0; i < alLevelsPrices.Length; ++i)
	{
		Format(query, sizeof(query), "%s%s(%d, %d, %d)", query, (i > 0 ? "," : ""), itemId, i+2, alLevelsPrices.Get(i));
	}
	Format(query, sizeof(query), "%s ON DUPLICATE KEY UPDATE price = VALUES(price);", query);
	DataPack dp = GetItemLogDataPack(itemId, DBER_ITEM_SET_LEVELS_PRICES);
	g_Database.Query(DB_ItemLogError, query, dp);
}

/**
 * Установка нового типа предмета по его id
 * 
 * @param ClanItemId itemId - id предмета
 * @param CShop_ItemType newType - новый тип
 */
void DB_SetItemType(ClanItemId itemId, CShop_ItemType newType)
{
	char query[256];
	FormatEx(query, sizeof(query), "UPDATE cshop_items SET type = %d WHERE id = %d", view_as<int>(newType), itemId);
	DataPack dp = GetItemLogDataPack(itemId, DBER_ITEM_SET_TYPE);
	g_Database.Query(DB_ItemLogError, query, dp);
}

/**
 * Установка видимости предмета по его id
 * 
 * @param ClanItemId itemId - id предмета
 * @param bool bVisible - флаг видимости
 */
void DB_SetItemVisibility(ClanItemId itemId, bool bVisible)
{
	char query[256];
	FormatEx(query, sizeof(query), "UPDATE cshop_items SET hidden = %d WHERE id = %d", view_as<int>(!bVisible), itemId);
	DataPack dp = GetItemLogDataPack(itemId, DBER_ITEM_SET_VISIBILITY);
	g_Database.Query(DB_ItemLogError, query, dp);
}

/**
 * Формирование датапака для запросов действия над предметом
 * 
 * @param ClanItemId itemId - ид предмета
 * @param CSHOP_DBERrors DBERror - тип потенциальной ошибки
 * 
 * @return DataPack с поданными значениями
 */
DataPack GetItemLogDataPack(ClanItemId itemId, CSHOP_DBERrors DBERror)
{
	DataPack dp = new DataPack();
	dp.WriteCell(itemId);
	dp.WriteCell(DBERror);
	dp.Reset();
	return dp;
}

	//==================== КЛАН ====================//
/**
 * Коллбэк действий над кланом
 */
void DB_ClanLogError(Database db, DBResultSet rSet, const char[] sError, DataPack dp)
{
	if(sError[0])
	{
		int iClanId = dp.ReadCell();
		ClanItemId itemId = dp.ReadCell();
		CSHOP_DBERrors dbErrorId = dp.ReadCell();
		char err[64];
		switch(dbErrorId)
		{
			case DBER_CLAN_REMOVE: err = "Failed to delete clan";
			case DBER_CLAN_ADD_ITEM: err = "Failed to add item to clan";
			case DBER_CLAN_REMOVE_ITEM: err = "Failed to delete item from clan";
			case DBER_CLAN__CHANGE_EXPIRE_TIME: err = "Failed to change clan item expire time";
			default: err = "Unknown error with clan";
		}
		if(itemId != INVALID_ITEM)
			LogError("[CSHOP] %s (clan id: %d, item id: %s): %s", err, iClanId, itemId, sError);
		else
			LogError("[CSHOP] %s (clan id: %d): %s", err, iClanId, sError);
	}
	delete dp;
}

/**
 * Этап перед удалением клана: получаем все предметы, что у них были, чтобы "освободить" их на сервере для новых покупок
 * 
 * @param int iClanId - ид клана
 * 
 * @noreturn
 */
void DB_PreDeleteClan(int iClanId)
{
	char query[256];
	FormatEx(query, sizeof(query), "SELECT item_id FROM cshop_clans_items WHERE server_id = %d AND clan_id = %d AND \
										(expire_time = %d OR expire_time > %d)", SERVER_ID, iClanId, ITEM_INFINITE, GetTime());
	g_Database.Query(DB_PreDeleteClanCallback, query, iClanId);
}

/**
 * Коллбэк предудаления клана: получает все предметы, что есть у клана
 */
void DB_PreDeleteClanCallback(Database db, DBResultSet rSet, const char[] sError, int iClanId)
{
	if(sError[0])
	{
		LogError("[CSHOP] Failed to get clan %d items to before deleting the clan: %s", iClanId, sError);
	}
	else
	{
		ClanItemId itemId;
		int iAmountOfItem
		while(rSet.FetchRow())
		{
			itemId = rSet.FetchInt(0);
			iAmountOfItem = GetItemAmountById(itemId);
			SetItemAmountById(itemId, --iAmountOfItem);
		}

		DB_DeleteClan(iClanId);
	}
}

/**
 * Удаление клана из базы
 * 
 * @param int iClanId - ид клана
 * 
 * @noreturn
 */
void DB_DeleteClan(int iClanId)
{
	//Сначала посмотреть, что было, а потом удалить записи в базе
	char query[128];
	FormatEx(query, sizeof(query), "DELETE FROM cshop_clans_items WHERE server_id = %d AND clan_id = %d", SERVER_ID, iClanId);
	DataPack dp = GetClanLogDataPack(iClanId, INVALID_ITEM, DBER_CLAN_REMOVE);
	g_Database.Query(DB_ClanLogError, query, dp);
}

/**
 * Добавление предмета клану
 * 
 * @param int iClanid - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iLevel - уровень предмета
 * @param int iExpireTime - срок окончания предмета
 * 
 * @noreturn
 */
void DB_AddItemToClan(int iClanId, ClanItemId itemId, int iLevel, int iExpireTime)
{
	char query[256];
	FormatEx(query, sizeof(query), "INSERT INTO cshop_clans_items \
										(server_id, clan_id, item_id, \
										 item_level, expire_time) \
									VALUES \
										(%d, %d, %d, \
										 %d, %d) \
									ON DUPLICATE KEY UPDATE item_level = %d, expire_time = %d;",
									SERVER_ID, iClanId, itemId, iLevel, iExpireTime, iLevel, iExpireTime);

	DataPack dp = GetClanLogDataPack(iClanId, itemId, DBER_CLAN_ADD_ITEM);
	g_Database.Query(DB_ClanLogError, query, dp);
}

/**
 * Забрать предмет у клана
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * 
 * @noreturn
 */
void DB_RemoveItemFromClan(int iClanId, ClanItemId itemId)
{
	char query[128];
	FormatEx(query, sizeof(query), "DELETE FROM cshop_clans_items WHERE clan_id = %d AND item_id = %d", iClanId, itemId);
	DataPack dp = GetClanLogDataPack(iClanId, itemId, DBER_CLAN_REMOVE_ITEM);
	g_Database.Query(DB_ClanLogError, query, dp);
}

/**
 * Изменить уровень предмета у клана
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - id предмета
 * @param int iNewLevel - новый уровень предмета
 * 
 * @noreturn
 */
void DB_SetClanItemLevel(int iClanId, ClanItemId itemId, int iNewLevel)
{
	char query[256];
	FormatEx(query, sizeof(query), "UPDATE cshop_clans_items SET item_level = %d WHERE clan_id = %d AND item_id = %d", iNewLevel, iClanId, itemId);

	DataPack dp = GetClanLogDataPack(iClanId, itemId, DBER_CLAN_CHANGE_LEVEL);
	g_Database.Query(DB_ClanLogError, query, dp);
}

/**
 * Изменить состояние предмета у клана
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - id предмета
 * @param int iNewExpireTime - новый срок действия предмета
 * 
 * @noreturn
 */
void DB_SetClanItemExpireTime(int iClanId, ClanItemId itemId, int iNewExpireTime)
{
	char query[256];
	FormatEx(query, sizeof(query), "UPDATE cshop_clans_items SET expire_time = %d WHERE clan_id = %d AND item_id = %d", iNewExpireTime, iClanId, itemId);

	DataPack dp = GetClanLogDataPack(iClanId, itemId, DBER_CLAN__CHANGE_EXPIRE_TIME);
	g_Database.Query(DB_ClanLogError, query, dp);
}

/**
 * Формирование датапака для запросов действия над кланом
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param CSHOP_DBERrors DBERror - тип потенциальной ошибки
 * 
 * @return DataPack с поданными значениями
 */
DataPack GetClanLogDataPack(int iClanId, ClanItemId itemId, CSHOP_DBERrors DBERror)
{
	DataPack dp = new DataPack();
	dp.WriteCell(iClanId);
	dp.WriteCell(itemId);
	dp.WriteCell(DBERror);
	dp.Reset();
	return dp;
}
	//==================== ИГРОК ====================//
/**
 * Коллбэк для обновления предмета игрока в базе
 */
void DB_PlayerItemLogError(Database db, DBResultSet rSet, const char[] sError, DataPack dp)
{
	if(sError[0])
	{
		ClanItemId itemId = dp.ReadCell();
		int iClientId = dp.ReadCell();
		CSHOP_DBERrors dbErrorId = dp.ReadCell();
		char err[64];
		switch(dbErrorId)
		{
			case DBER_ADD_ITEM_TO_CLIENT: err = "Failed to add item";
			case DBER_REMOVE_CLIENT_ITEM: err = "Failed to remove player item with id";
			case DBER_REMOVE_CLIENT_ITEMS: err = "Failed to remove all player items";
			case DBER_CHANGE_STATE_PITEM: err = "Failed to change state for item";
			default: err = "Unknown error with player item";
		}
		if(itemId != INVALID_ITEM)
			LogError("[CSHOP] %s %d (player's id %d): %s", err, itemId, iClientId, sError);
		else
			LogError("[CSHOP] %s (player's id %d): %s", err, iClientId, sError);
	}
	delete dp;
}

/**
 * Добавление предмета игроку в базу
 * 
 * @param const char[] sSteamId - steam id игрока
 * @param int iClientId - ид клиента в базе кланов
 * @param int iClanId - id клана
 * @param ClanItemId itemId - id предмета
 * @param CShop_ItemState state - состояние предмета
 */
void DB_AddItemToClient(const char[] sSteamId, int iClientId, int iClanId, ClanItemId itemId, CShop_ItemState state)
{
	char query[256];
	FormatEx(query, sizeof(query), "INSERT INTO cshop_players_items \
									(server_id, auth, client_id, clan_id, item_id, state) \
									VALUES \
									(%d, '%s', %d, %d, %d, %d) \
									ON DUPLICATE KEY UPDATE state = %d;",
									SERVER_ID, sSteamId, iClientId, iClanId, itemId, view_as<int>(state), view_as<int>(state));

	DataPack dp = GetPlayerItemLogDataPack(itemId, iClientId, DBER_ADD_ITEM_TO_CLIENT);
	g_Database.Query(DB_PlayerItemLogError, query, dp);
}

/**
 * Удалить предмет у игрока
 * 
 * @param int iClientId - ид клиента в базе кланов
 * @param ClanItemId itemId - ид предмета
 * 
 * @noreturn
 */
void DB_RemovePlayerItem(int iClientId, ClanItemId itemId)
{
	char query[256];
	FormatEx(query, sizeof(query), "DELETE FROM cshop_players_items WHERE server_id = %d AND client_id = %d AND item_id = %d", 
										SERVER_ID, iClientId, itemId);

	DataPack dp = GetPlayerItemLogDataPack(itemId, iClientId, DBER_REMOVE_CLIENT_ITEM);
	g_Database.Query(DB_PlayerItemLogError, query, dp);
}

/**
 * Удаление предметов игрока из базы
 * 
 * @param int iClientId - ид клиента в базе кланов
 */
void DB_ClearPlayerItems(int iClientId)
{
	char query[256];
	FormatEx(query, sizeof(query), "DELETE FROM cshop_players_items WHERE server_id = %d AND client_id = %d", SERVER_ID, iClientId);

	DataPack dp = GetPlayerItemLogDataPack(INVALID_ITEM, iClientId, DBER_REMOVE_CLIENT_ITEMS);
	g_Database.Query(DB_PlayerItemLogError, query, dp);
}

/**
 * Обновление состояния предмета игрока в базе
 * 
 * @param int iClientId - ид клиента в базе кланов
 * @param ClanItemId itemId - id предмета
 * @param CShop_ItemState newState - новое состояние предмета
 */
void DB_UpdatePlayerItemState(int iClientId, ClanItemId itemId, CShop_ItemState newState)
{
	char query[128];
	FormatEx(query, sizeof(query), "UPDATE cshop_players_items SET state = %d WHERE item_id = %d AND client_id = %d", 
										view_as<int>(newState), itemId, iClientId);

	DataPack dp = GetPlayerItemLogDataPack(itemId, iClientId, DBER_CHANGE_STATE_PITEM);
	g_Database.Query(DB_PlayerItemLogError, query, dp);
}

/**
 * Формирование датапака для запросов действия над предметом игрока
 * 
 * @param ClanItemId itemId - ид предмета
 * @param int iClientId - ид клиента в базе кланов
 * @param CSHOP_DBERrors DBERror - тип потенциальной ошибки
 * 
 * @return DataPack с поданными значениями
 */
DataPack GetPlayerItemLogDataPack(ClanItemId itemId, int iClientId, CSHOP_DBERrors DBERror)
{
	DataPack dp = new DataPack();
	dp.WriteCell(itemId);
	dp.WriteCell(iClientId);
	dp.WriteCell(DBERror);
	dp.Reset();
	return dp;
}