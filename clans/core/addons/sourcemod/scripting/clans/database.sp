Database g_hClansDB = null;

/**
 * Подключение к базе данных
 */
void ConnectToDatabase()
{
	if(SQL_CheckConfig("clans"))
		Database.Connect(DB_Connect, "clans");
	else
		SetFailState("[Clans] No database configuration in databases.cfg!");
}

void DB_Connect(Database db, const char[] error, any data)
{
	g_hClansDB = db;

	if(g_hClansDB == null)
		SetFailState("[Clans] Unable to connect to database (%s)", error);

	SQL_FastQuery(g_hClansDB, "CREATE TABLE IF NOT EXISTS `clans_table` (\
							`clan_id` INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT, \
							`clan_name` VARCHAR(16), \
							`leader_steam` CHAR(48) UNIQUE, \
							`leader_name` VARCHAR(192), \
							`time_creation` INTEGER NOT NULL default '0', \
							`maxmembers` INTEGER NOT NULL default '0', \
							`clan_kills` INTEGER NOT NULL default '0', \
							`clan_deaths` INTEGER NOT NULL default '0', \
							`clan_coins` INTEGER NOT NULL default '0', \
							`clan_type` INTEGER default '0');");
	SQL_FastQuery(g_hClansDB, "CREATE TABLE IF NOT EXISTS `players_table` (\
							`player_id` INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT, \
							`player_name` VARCHAR(192), \
							`player_steam` CHAR(48) UNIQUE, \
							`player_clanid` INTEGER NOT NULL, \
							`player_role` INTEGER NOT NULL, \
							`player_kills` INTEGER NOT NULL default '0', \
							`player_deaths` INTEGER NOT NULL default '0', \
							`player_timejoining` INTEGER NOT NULL, \
							`player_lastjoin` INTEGER NOT NULL);");

	SQL_SetCharset(g_hClansDB, "utf8");

	Upgrade1();
	Upgrade2();
	Upgrade3();
	//Upgrade4 -> steam to UNIQUE

	for(int i = 1; i <= MaxClients; i++)
	{
		ClearPlayerMenuBuffer(i);	// v1.86
		ClearClientData(i);
		if(IsClientInGame(i))
			OnClientPostAdminCheck(i);
	}

	ClansLoaded();
}

/**
 * Обновление базы, если версия не выше 1.51
 */
void Upgrade1()
{
	char query[200];
	FormatEx(query, sizeof(query), "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'players_table' AND COLUMN_NAME = 'player_isleader';");
	DBResultSet hQuery = SQL_Query(g_hClansDB, query, sizeof(query));
	if(hQuery == INVALID_HANDLE)
	{
		char error[255];
		SQL_GetError(g_hClansDB, error, sizeof(error));
		LogError("[CLANS] Unable to upgrade: %s", error);
	}
	else
	{
		if(SQL_FetchRow(hQuery))
		{
			if(SQL_FetchInt(hQuery, 0) == 1)	//If 1.51 or low version
			{
				char error[255];
				if(!SQL_FastQuery(g_hClansDB, "ALTER TABLE `players_table` CHANGE `player_isleader` `player_role` INTEGER;"))
				{
					SQL_GetError(g_hClansDB, error, sizeof(error));
					SetFailState("[CLANS] Failed to upgrade players role field (upg1): %s", error);
				}
				if(!SQL_FastQuery(g_hClansDB, "ALTER TABLE `clans_table` ADD `clan_type` INTEGER default '0';"))
				{
					SQL_GetError(g_hClansDB, error, sizeof(error));
					SetFailState("[CLANS] Failed to upgrade clans table (add type, upg1): %s", error);
				}
				if(!SQL_FastQuery(g_hClansDB, "UPDATE `players_table` SET `player_role` = '4' WHERE `player_role` = '1';"))
				{
					SQL_GetError(g_hClansDB, error, sizeof(error));
					SetFailState("[CLANS] Failed to update players role (upg1): %s", error);
				}
			}
		}
	}
	delete hQuery;
}

/**
 * Обновление базы, если версия не выше 1.86
 * Добавление времени последнего захода
 */
void Upgrade2()
{
	char query[200];
	FormatEx(query, sizeof(query), "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'players_table' AND COLUMN_NAME = 'player_lastjoin';");
	DBResultSet hQuery = SQL_Query(g_hClansDB, query, sizeof(query));
	if(hQuery == INVALID_HANDLE)
	{
		char error[255];
		SQL_GetError(g_hClansDB, error, sizeof(error));
		SetFailState("[CLANS] Unable to upgrade2: %s", error);
	}
	else
	{
		if(SQL_FetchRow(hQuery))
		{
			if(SQL_FetchInt(hQuery, 0) == 0)	//If 1.86 or low
			{
				char error[255];
				if(!SQL_FastQuery(g_hClansDB, "ALTER TABLE players_table ADD COLUMN player_lastjoin INT NOT NULL DEFAULT 0;"))
				{
					SQL_GetError(g_hClansDB, error, sizeof(error));
					SetFailState("[CLANS] Failed to add player_lastjoin column (upg2): %s", error);
				}
				if(!SQL_FastQuery(g_hClansDB, "ALTER TABLE clans_table DROP COLUMN date_creation;"))
				{
					SQL_GetError(g_hClansDB, error, sizeof(error));
					SetFailState("[CLANS] Failed to drop date_creation column in clans_table (upg2): %s", error);
				}
				if(!SQL_FastQuery(g_hClansDB, "ALTER TABLE clans_table DROP COLUMN members;"))
				{
					SQL_GetError(g_hClansDB, error, sizeof(error));
					SetFailState("[CLANS] Failed to drop members column in clans_table (upg2): %s", error);
				}
			}
		}
	}
	delete hQuery;
}

//Set auto increment
void Upgrade3()
{
	char query[256];
	FormatEx(query, sizeof(query), "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'players_table' AND COLUMN_NAME = 'player_id' AND EXTRA LIKE '%%auto_increment%%';");
	DBResultSet rSet = SQL_Query(g_hClansDB, query, sizeof(query));
	if(rSet != INVALID_HANDLE)
	{
		if(rSet.FetchRow() && rSet.FetchInt(0) == 0)
		{
			char error[256];
			if(!SQL_FastQuery(g_hClansDB, "ALTER TABLE `players_table` CHANGE `player_id` `player_id` INT(11) NOT NULL AUTO_INCREMENT;"))
			{
				SQL_GetError(g_hClansDB, error, sizeof(error));
				SetFailState("[CLANS] Failed to add A_I to players_table (upg3): %s", error);
			}
			if(!SQL_FastQuery(g_hClansDB, "ALTER TABLE `clans_table` CHANGE `clan_id` `clan_id` INT(11) NOT NULL AUTO_INCREMENT;"))
			{
				SQL_GetError(g_hClansDB, error, sizeof(error));
				SetFailState("[CLANS] Failed to add A_I to clans_table (upg3): %s", error);
			}
		}
	}
	else
	{
		char error[256];
		SQL_GetError(g_hClansDB, error, sizeof(error));
		SetFailState("[CLANS] Failed to upgrade3: %s", error);
	}
	delete rSet;
}
	//============================== CLANS КЛАНЫ ==============================//

/*
 * Создание клана, если лидер онлайн
 *
 * @param int leaderid - айди лидера клана (должен быть онлайн)
 * @param char[] clanName - название клана
 * @param int createBy - айди того, кто создает (-1, если создает leaderid, иначе администратор)
 */
void DB_CreateClan(int leaderid, char[] clanName, int createBy = -1)
{
	char	query[200],						//Запрос в базу данных
			leaderName[MAX_NAME_LENGTH],	//Имя лидера
			leaderAuth[33];					//Аутентификатор лидера
	DataPack data = CreateDataPack();		//Пак данных: айди лидера, его ник и аутентификатор, название клана и айди того, кто создает
			
	if(createBy == -1)
		createBy = leaderid;
	GetClientName(leaderid, leaderName, sizeof(leaderName));
	if(USEAUTH2)
		GetClientAuthId(leaderid, AuthId_Steam2, leaderAuth, sizeof(leaderAuth));
	else
		GetClientAuthId(leaderid, AuthId_Steam3, leaderAuth, sizeof(leaderAuth));
	char clanNameEscaped[MAX_CLAN_NAME*2+1];
	g_hClansDB.Escape(clanName, clanNameEscaped, sizeof(clanNameEscaped));
	data.WriteCell(leaderid);
	data.WriteString(leaderName);
	data.WriteString(leaderAuth);
	data.WriteString(clanName);
	data.WriteCell(createBy);
	data.Reset();
	FormatEx(query, sizeof(query), "SELECT * FROM `clans_table` WHERE `clan_name` = '%s'", clanNameEscaped);
	g_hClansDB.Query(DB_ClanNameCheckCallback, query, data);
}

/*
 * Коллбэк, где проверялось занято ли имя клана
 * Если свободно, то создается клан, иначе сообщаем, что имя занято
 */
void DB_ClanNameCheckCallback(Database db, DBResultSet rSet, const char[] error, DataPack data)
{
	if(error[0])
	{
		LogError("[CLANS] Query Fail check clan name: %s", error);
		delete data;
	}
	else
	{
		char	leaderName[MAX_NAME_LENGTH+1],	//Имя лидера
				leaderAuth[33],					//Аутентификатор лидера
				clanName[MAX_CLAN_NAME+1],		//Название клана
				leaderNameEscaped[MAX_NAME_LENGTH*2+1],
				clanNameEscaped[MAX_CLAN_NAME*2+1];
		int 	leaderid,						//айди лидера
				createBy;						//айди, кто создает
		
		leaderid = data.ReadCell();
		data.ReadString(leaderName, sizeof(leaderName));
		data.ReadString(leaderAuth, sizeof(leaderAuth));
		data.ReadString(clanName, sizeof(clanName));
		createBy = data.ReadCell();
		if(rSet.FetchRow())	//Такое имя занято
		{
			char print_buff[BUFF_SIZE];
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanAlreadyExists", createBy);
			ColorPrintToChat(createBy, print_buff);
			delete data;
		}
		else	//Имя не занято
		{
			int 	creationTime;	//Время создания клана
			creationTime = GetTime();
			data.Reset(true);
			data.WriteCell(leaderid);
			data.WriteCell(createBy);
			data.Reset();
			
			if(!g_hClansDB.Escape(leaderName, leaderNameEscaped, sizeof(leaderNameEscaped)))
			{
				LogError("[CLANS] Failed to escape the leaderName in ClanNameCheckCallback!");
				return;
			}
			if(!g_hClansDB.Escape(clanName, clanNameEscaped, sizeof(clanNameEscaped)))
			{
				LogError("[CLANS] Failed to escape the clanName in ClanNameCheckCallback!");
				return;
			}

			char query[1024];
			FormatEx(query, sizeof(query), "INSERT INTO `clans_table` (`clan_name`, `leader_steam`, `leader_name`, `time_creation`, `maxmembers`) VALUES ('%s', '%s', '%s', '%d', '%d');",
			clanNameEscaped, leaderAuth, leaderNameEscaped, creationTime, g_iStartSlotsInClan);
			g_hClansDB.Query(DB_CreateClanCallback, query, data);
			
			//Заполняем поля игрока клана
			//g_iClientData[leaderid][CLIENT_CLANID] = clanid;
			g_sClientData[leaderid][CLIENT_NAME] = leaderName;
			g_sClientData[leaderid][CLIENT_STEAMID] = leaderAuth;
			g_sClientData[leaderid][CLIENT_CLANNAME] = clanName;
			
			g_iClientData[leaderid][CLIENT_ROLE] = CLIENT_LEADER;
			g_iClientData[leaderid][CLIENT_KILLS] = 0;
			g_iClientData[leaderid][CLIENT_DEATHS] = 0;
			g_iClientData[leaderid][CLIENT_TIME] = creationTime;
		}
	}
}

/*
 * Коллбэк создания клана
 * @param DataPack data - пак данных:
 *			int leaderid - айди лидера нового клана
 *			int createBy - кем создан
 */
void DB_CreateClanCallback(Database db, DBResultSet rSet, const char[] error, DataPack data)
{
	int leaderid = data.ReadCell();
	int createBy = data.ReadCell();
	if(rSet == INVALID_HANDLE)
	{
		LogError("[CLANS] Query Fail create clan: %s", error);
		g_iClientData[leaderid][CLIENT_CLANID] = -1;
	}
	else
	{
		g_iClientData[leaderid][CLIENT_CLANID] = rSet.InsertId;	//v1.87
		F_OnClanAdded(g_iClientData[leaderid][CLIENT_CLANID], g_sClientData[leaderid][CLIENT_CLANNAME], createBy);
		char print_buff[BUFF_SIZE];
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_CreationSuccess", createBy);
		ColorPrintToChat(createBy, print_buff);
		DB_CreateClient(leaderid);
	}
	delete data;
}

/**
 * Коллбэк переименования клана
 *
 * @param DataPack data - пак данных:
 *			int client - айди того, кто переименовывает
 *			int clanid - айди клана
 *			char[] prevClanName - имя клана до переименовывания
 *			char[] newClanName - новое имя клана
 *			bool takeCoins - забрать монеты за переименование
 */
void DB_RenameClanCallback(Database db, DBResultSet rSet, const char[] error, DataPack data)
{
	if(error[0])
	{
		LogError("[CLANS] Query Fail check clan name for rename: %s", error);
	}
	else
	{
		int client = data.ReadCell();
		int clanid = data.ReadCell();
		char prevClanName[MAX_CLAN_NAME+1],
			 newClanName[MAX_CLAN_NAME+1];
		data.ReadString(prevClanName, sizeof(prevClanName));
		data.ReadString(newClanName, sizeof(newClanName));
		bool takeCoins = data.ReadCell();
		
		char print_buff[BUFF_SIZE];
		if(rSet.FetchRow())
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanAlreadyExists", client);
			ColorPrintToChat(client, print_buff);
			return;
		}
		if(takeCoins)
			DB_ChangeClanCoins(clanid, -g_iRenameClanPrice);
		SetClanName(clanid, newClanName);
		if(!g_bCSS34)
			UpdatePlayersClanTag();
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_RenameClanSuccess", client);
		ColorPrintToChat(client, print_buff);
		if(CheckForLog(LOG_CLANACTION))
		{
			char log_buff[LOG_SIZE],
				 prevClanNameEscaped[MAX_CLAN_NAME*2+1],
				 newClanNameEscaped[MAX_CLAN_NAME*2+1];
			if(g_iLogs == 1)	//sqlite
			{
				g_hClansDB.Escape(prevClanName, prevClanNameEscaped, sizeof(prevClanNameEscaped));
				g_hClansDB.Escape(newClanName, newClanNameEscaped, sizeof(newClanNameEscaped));
				FormatEx(log_buff, sizeof(log_buff), "%T", "L_RenameClan", LANG_SERVER, prevClanNameEscaped, newClanNameEscaped);
			}
			else
				FormatEx(log_buff, sizeof(log_buff), "%T", "L_RenameClan", LANG_SERVER, prevClanName, newClanName);

			DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_CLANACTION);
		}
	}
	delete data;
}

/**
 * Изменение количества монет клану в базе данных
 *
 * @param int clanid - айди клана
 * @param int amountToAdd - число монет, которое нужно добавить(отнять)
 *
 * @return false - число монет будет отрицательное, true иначе
 */
bool DB_ChangeClanCoins(int clanid, int amountToAdd)
{
	char query[256];
	FormatEx(query, sizeof(query), "UPDATE \
										clans_table \
									SET \
										clan_coins = IF(clan_coins + %d < 0, 0, clan_coins + %d) \
									WHERE \
										clan_id = %d;", amountToAdd, amountToAdd, clanid);
	g_hClansDB.Query(DB_ClansError, query, 3);
	return true;
}

/**
 * Установка количества монет клану в базе данных
 *
 * @param int clanid - айди клана
 * @param int coinsToSet - число монет, которое нужно установить
 *
 * @return false - число монет будет отрицательное, true иначе
 */
bool DB_SetClanCoins(int clanid, int coinsToSet)
{
	if(coinsToSet < 0)
		return false;
	char query[128];
	FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `clan_coins` = '%d' WHERE `clan_id` = '%d'", coinsToSet, clanid);
	g_hClansDB.Query(DB_ClansError, query, 3);
	return true;
}

/**
 * Изменение количества убийств клану в базе данных
 *
 * @param int clanid - айди клана
 * @param int amountToAdd - число убийство, которое нужно добавить(отнять)
 *
 * @return false - число убийств будет отрицательное, true иначе
 */
bool DB_ChangeClanKills(int clanid, int amountToAdd)
{
	char query[256];
	FormatEx(query, sizeof(query), "UPDATE \
										`clans_table` \
									SET \
										`clan_kills` = (CASE WHEN `clan_kills`+'%d' < 0 THEN 0 ELSE (`clan_kills`+'%d') END) \
									WHERE \
										`clan_id` = '%d';", amountToAdd, amountToAdd, clanid);
	g_hClansDB.Query(DB_ClansError, query, 1);
	return true;
}

/**
 * Установка количества убийств клану в базе данных
 *
 * @param int clanid - айди клана
 * @param int killsToSet - число убийств, которое нужно установить
 *
 * @return false - число убийств будет отрицательное, true иначе
 */
bool DB_SetClanKills(int clanid, int killsToSet)
{
	if(killsToSet < 0)
		return false;
		
	char query[200];
	FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `clan_kills` = '%d' WHERE `clan_id` = '%d'", killsToSet, clanid);
	g_hClansDB.Query(DB_ClansError, query, 1);
	return true;
}

/**
 * Изменение количества смертей клану в базе данных
 *
 * @param int clanid - айди клана
 * @param int amountToAdd - число смертей, которое нужно добавить(отнять)
 *
 * @return false - число смертей будет отрицательное, true иначе
 */
bool DB_ChangeClanDeaths(int clanid, int amountToAdd)
{
	char query[200];		
	FormatEx(query, sizeof(query), "UPDATE \
										`clans_table` \
									SET \
										`clan_deaths` = (CASE WHEN `clan_deaths`+'%d' < 0 THEN 0 ELSE (`clan_deaths`+'%d') END) \
									WHERE \
										`clan_id` = '%d';", amountToAdd, amountToAdd, clanid);
	g_hClansDB.Query(DB_ClansError, query, 2);
	return true;
}

/**
 * Установка количества смертей клану в базе данных
 *
 * @param int clanid - айди клана
 * @param int deathsToSet - число смертей, которое нужно установить
 *
 * @return false - число смертей будет отрицательное, true иначе
 */
bool DB_SetClanDeaths(int clanid, int deathsToSet)
{
	if(deathsToSet < 0)
		return false;
	char query[200];
	FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `clan_deaths` = '%d' WHERE `clan_id` = '%d'", deathsToSet, clanid);
	g_hClansDB.Query(DB_ClansError, query, 2);
	return true;
}

/**
 * Установка типа клана в базе данных
 *
 * @param int type - тип клана
 *
 * @return false - выбранного типа не существует, true иначе
 */
bool DB_SetClanType(int clanid, int type)
{
	if(type < CLAN_CLOSED || type > CLAN_OPEN)
		return false;
		
	char query[150];
	FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `clan_type` = '%d' WHERE `clan_id` = '%d'", type, clanid);
	g_hClansDB.Query(DB_ClansError, query, 4);
	return true;
}

/**
 * Изменение количества слотов для участников клану в базе данных
 *
 * @param int clanid - айди клана
 * @param int amountToAdd - число слотов, которое нужно добавить(отнять)
 *
 * @return false - число слотов отрицательное или превышает установленный лимит, true иначе
 */
bool DB_ChangeClanMaxMembers(int clanid, int amountToAdd)
{
	SQL_LockDatabase(g_hClansDB);
	int maxMembers;		//Максимум игроков в клане сейчас
	char query[200];
	FormatEx(query, sizeof(query), "SELECT `maxmembers` FROM `clans_table` WHERE `clan_id` = '%d'", clanid);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		maxMembers = rSet.FetchInt(0);
	}
	else
		return false;


	if(maxMembers + amountToAdd > g_iMaxClanMembers || maxMembers + amountToAdd <= 0)
	{
		delete rSet;
		return false;
	}

	FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `maxmembers` = '%d' WHERE `clan_id` = '%d'", maxMembers + amountToAdd, clanid);
	g_hClansDB.Query(DB_ClansError, query, 6);
	delete rSet;
	return true;
}

/**
 * Установка количества слотов клану в базе данных
 *
 * @param int clanid - айди клана
 * @param int maxMembersToSet - число слотов в клане, которое нужно установить
 *
 * @return false - число слотов отрицательное или превышает установленный лимит, true иначе
 */
bool DB_SetClanMaxMembers(int clanid, int maxMembersToSet)
{
	if(maxMembersToSet <= 0 || maxMembersToSet > g_iMaxClanMembers)
		return false;

	char query[200];
	FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `maxmembers` = '%d' WHERE `clan_id` = '%d'", maxMembersToSet, clanid);
	g_hClansDB.Query(DB_ClansError, query, 6);
	return true;
}

/**
 * Reset clan
 *
 * @param int clanid - clan's id in the database
 */
void DB_ResetClan(int clanid, bool bResetPlayers = false, bool bResetCoins = false)
{
	char query[150];
	FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `clan_kills` = '0', `clan_deaths` = '0'%s WHERE `clan_id` = '%d'", bResetCoins == true ? ", `clan_coins` = '0'" : "", clanid);
	g_hClansDB.Query(DB_ClansError, query, 10);
	if(bResetPlayers)	//v1.86
	{
		FormatEx(query, sizeof(query), "UPDATE players_table SET player_kills = 0, player_deaths = 0 WHERE player_clanid = %d", clanid);
		g_hClansDB.Query(DB_ClansError, query, 13);
	}
}

/**
 * Reset all clans //v1.87
 */
void DB_ResetAllClans(bool bResetPlayers, bool bResetCoins)
{
	char query[150];
	FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `clan_kills` = '0', `clan_deaths` = '0'%s", bResetCoins == true ? ", `clan_coins` = '0';" : ";");
	g_hClansDB.Query(DB_ClansError, query, 10);
	if(bResetPlayers)	//v1.87
	{
		FormatEx(query, sizeof(query), "UPDATE players_table SET player_kills = 0, player_deaths = 0");
		g_hClansDB.Query(DB_ClansError, query, 14);
	}
}

/*
 * Удаление клана по айди
 *
 * @param int clanid - айди клана
 */
void DB_DeleteClan(int clanid)
{
	char query[90];
	Format(query, sizeof(query), "DELETE FROM `clans_table` WHERE `clan_id` = '%d'", clanid);
	g_hClansDB.Query(DB_ClansError, query, 9);
	FormatEx(query, sizeof(query), "DELETE FROM `players_table` WHERE `player_clanid` = '%d'", clanid);
	g_hClansDB.Query(DB_ClientError, query, 8);
}
	//============================== PLAYERS ИГРОКИ ==============================//
/*
 * Добавление онлайн игрока в базу данных
 *
 * @param int client - айди игрока
 */
void DB_CreateClient(int client)
{
	bool leader = g_iClientData[client][CLIENT_ROLE] == CLIENT_LEADER;
	
	char clientNameEscaped[MAX_NAME_LENGTH*2+1];
	if(!g_hClansDB.Escape(g_sClientData[client][CLIENT_NAME], clientNameEscaped, sizeof(clientNameEscaped)))
	{
		LogError("[CLANS] Failed to escape the clientName in DB_CreateClient!");
		return;
	}
	
	char query[1024];
	FormatEx(query, sizeof(query), "INSERT INTO players_table (player_name, player_steam, player_clanid, player_role, player_timejoining, player_lastjoin) VALUES ('%s', '%s', %d, %d, %d, %d)",
	clientNameEscaped, g_sClientData[client][CLIENT_STEAMID], g_iClientData[client][CLIENT_CLANID], g_iClientData[client][CLIENT_ROLE], g_iClientData[client][CLIENT_TIME], GetTime());

	DataPack dp = CreateDataPack();
	dp.WriteCell(leader);
	dp.WriteCell(client);
	dp.Reset();
	g_hClansDB.Query(DB_CreateClientCallback, query, dp);
}

void DB_CreateClientCallback(Database db, DBResultSet rSet, const char[] error, DataPack dp)
{
	bool leader = dp.ReadCell();
	int client = dp.ReadCell();
	if(error[0])
	{
		LogError("[CLANS] Failed to create client: %s", error);
		ClanClient = -1;
	}
	else
	{
		ClanClient = rSet.InsertId;
		char query[512];
		if(leader)	//Снимаем старого лидера
		{		
			FormatEx(query, sizeof(query), "\
			UPDATE \
				`players_table` \
			SET \
				`player_role` = '%d' \
			WHERE \
				`player_role` = '%d' AND `player_clanid` = '%d' AND `player_id` != '%d';", CLIENT_COLEADER, CLIENT_LEADER, g_iClientData[client][CLIENT_CLANID], ClanClient);
			g_hClansDB.Query(DB_ClansError, query, 7);
			
			FormatEx(query, sizeof(query), "\
			UPDATE \
				`clans_table` \
			SET \
				`leader_steam` = (SELECT `player_steam` FROM `players_table` WHERE `player_id` = '%d'), \
				`leader_name` = (SELECT `player_name` FROM `players_table` WHERE `player_id` = '%d') \
			WHERE \
				`clan_id` = '%d';", ClanClient, ClanClient, g_iClientData[client][CLIENT_CLANID]);
			g_hClansDB.Query(DB_ClansError, query, 7);
		}

		F_OnClientAdded(client, ClanClient, g_iClientData[client][CLIENT_CLANID]);
	}
	delete dp;
}

/**
 * Create clan client by data
 *
 * @param char[] name - client's name
 * @param char[] auth - client's auth
 * @param int clanid - client clan's id
 * @param int role - client's role
 */
void DB_CreateClientByData(char[] name, const char[] auth, int clanid, int role, int iClient = -1)
{
	int joinTime = GetTime();
	char nameEscaped[MAX_NAME_LENGTH*2+1], query[1024];
	if(!g_hClansDB.Escape(name, nameEscaped, sizeof(nameEscaped)))
	{
		LogError("[CLANS] Failed to escape the clientName in DB_CreateClientByData!");
		return;
	}
	FormatEx(query, sizeof(query), "INSERT INTO players_table (player_name, player_steam, player_clanid, player_role, player_timejoining, player_lastjoin) VALUES ('%s', '%s', %d, %d, %d, %d)",
	nameEscaped, auth, clanid, role, joinTime, GetTime());
	DataPack dp = CreateDataPack();
	dp.WriteCell(iClient);
	dp.WriteCell(clanid);
	dp.WriteCell(role);
	dp.Reset();
	g_hClansDB.Query(DB_CreateClientByDataCallback, query, dp);
}

void DB_CreateClientByDataCallback(Database db, DBResultSet rSet, const char[] error, DataPack dp)
{
	if(error[0])
	{
		LogError("[CLANS] Failed to create client by data: %s", error);
	}
	else
	{
		char query[512];
		int iClient = dp.ReadCell();
		int clanid = dp.ReadCell();
		int role = dp.ReadCell();
		int idOfNewClient = rSet.InsertId;
		if(role == CLIENT_LEADER)
		{		
			FormatEx(query, sizeof(query), "\
			UPDATE \
				`players_table` \
			SET \
				`player_role` = '%d' \
			WHERE \
				`player_role` = '%d' AND `player_clanid` = '%d' AND `player_id` != '%d';", CLIENT_COLEADER, CLIENT_LEADER, clanid, idOfNewClient);
			g_hClansDB.Query(DB_ClansError, query, 7);
			
			FormatEx(query, sizeof(query), "\
			UPDATE \
				`clans_table` \
			SET \
				`leader_steam` = (SELECT `player_steam` FROM `players_table` WHERE `player_id` = '%d'), \
				`leader_name` = (SELECT `player_name` FROM `players_table` WHERE `player_id` = '%d') \
			WHERE \
				`clan_id` = '%d';", idOfNewClient, idOfNewClient, clanid);
			g_hClansDB.Query(DB_ClansError, query, 7);
		}
		F_OnClientAdded(iClient, idOfNewClient, clanid);
	}
	delete dp;
}

/* 
 * Запрос на поиск игрока в базе 
 *
 * @param int client - айди клиента
 */
void DB_LoadClient(int client)
{
	char query[512], auth[32], auth2[32];
	GetClientAuthId(client, AuthId_Steam3, auth, sizeof(auth));
	GetClientAuthId(client, AuthId_Steam2, auth2, sizeof(auth2));
	FormatEx(query, sizeof(query), "SELECT \
										player_id, \
										player_name, \
										player_steam, \
										player_clanid, \
										player_role, \
										player_kills, \
										player_deaths, \
										player_timejoining, \
										`clans_table`.`clan_name` \
									FROM \
										players_table \
									JOIN \
										`clans_table` ON `clans_table`.`clan_id` = `players_table`.`player_clanid` \
									WHERE \
										player_steam = '%s' OR player_steam = '%s'", auth, auth2);
	DataPack dp = new DataPack();
	dp.WriteCell(client);
	dp.WriteString(auth);
	dp.WriteString(auth2);
	dp.Reset();
	g_hClansDB.Query(DB_LoadClientCallback, query, dp);
}

/*
 * Коллбэк на поиск игрока в базе
 */
void DB_LoadClientCallback(Database db, DBResultSet rSet, const char[] error, DataPack dp)
{
	int client = dp.ReadCell();
	if(error[0])
	{
		LogError("[CLANS] Query Fail load client: %s", error);
	}
	else
	{
		if(IsClientInGame(client))
		{
			if(rSet.FetchRow())
			{
				char userName[MAX_NAME_LENGTH+1],
					userSteam[32], 
					steamFromDatapack[32],
					query[300];

				GetClientAuthId(client, AuthId_Steam3, userSteam, sizeof(userSteam));	// v1.9
				dp.ReadString(steamFromDatapack, sizeof(steamFromDatapack));			// Проверяем, что мы выдаем тому, кого грузили
				if(strcmp(userSteam, steamFromDatapack))
				{
					delete dp;
					return;
				}
				GetClientName(client, userName, sizeof(userName));
				ClanClient = rSet.FetchInt(0);
				rSet.FetchString(1, g_sClientData[client][CLIENT_NAME], MAX_NAME_LENGTH);
				rSet.FetchString(2, g_sClientData[client][CLIENT_STEAMID], MAX_NAME_LENGTH);
				g_iClientData[client][CLIENT_CLANID] = rSet.FetchInt(3);
				g_iClientData[client][CLIENT_ROLE] = rSet.FetchInt(4);
				g_iClientData[client][CLIENT_KILLS] = rSet.FetchInt(5);
				g_iClientData[client][CLIENT_DEATHS] = rSet.FetchInt(6);
				g_iClientData[client][CLIENT_TIME] = rSet.FetchInt(7);
				rSet.FetchString(8, g_sClientData[client][CLIENT_CLANNAME], sizeof(g_sClientData[][]));
				UpdatePlayerClanTag(client);

				if(strcmp(userName, g_sClientData[client][CLIENT_NAME]))	//Обновить в базе имя игрока
				{
					char userNameEscaped[MAX_NAME_LENGTH*2+1];
					if(!g_hClansDB.Escape(userName, userNameEscaped, sizeof(userNameEscaped)))
					{
						LogError("[CLANS] Failed to escape the userName in DB_LoadClientCallback! Can't update the name!");
					}
					else
					{
						FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `leader_name` = '%s' WHERE `leader_steam` = '%s';", userNameEscaped, g_sClientData[client][CLIENT_STEAMID]);
						g_hClansDB.Query(DB_ClientError, query, 3);
						FormatEx(query, sizeof(query), "UPDATE `players_table` SET `player_name` = '%s' WHERE `player_steam` = '%s';", userNameEscaped, g_sClientData[client][CLIENT_STEAMID]);
						g_hClansDB.Query(DB_ClientError, query, 3);
					}
				}
				if(USEAUTH2)
				{
					GetClientAuthId(client, AuthId_Steam2, userSteam, sizeof(userSteam));
				}
				else
				{
					GetClientAuthId(client, AuthId_Steam3, userSteam, sizeof(userSteam));
				}
				if(strcmp(userSteam, g_sClientData[client][CLIENT_STEAMID]))	// v1.86
				{
					FormatEx(query, sizeof(query), "UPDATE players_table SET player_steam = '%s' WHERE player_id = %d", userSteam, ClanClient);
					g_hClansDB.Query(DB_ClientError, query, 11);
					FormatEx(query, sizeof(query), "UPDATE clans_table SET leader_steam = '%s' WHERE leader_steam = '%s';", userSteam, g_sClientData[client][CLIENT_STEAMID]);
					g_hClansDB.Query(DB_ClientError, query, 11);
					FormatEx(g_sClientData[client][CLIENT_STEAMID], MAX_NAME_LENGTH, "%s", userSteam);
				}
			}

			F_OnClientLoaded(client, ClanClient, ClanClient != -1 ? g_iClientData[client][CLIENT_CLANID] : -1);
		}
	}
	delete dp;
}

/**
 * Установка клана игроку
 *
 * @param int clientID - айди игрока в базе
 * @param int clanid - айди нового клана
 */
void DB_SetClientClan(int clientID, int clanid)
{
	char query[150];
	FormatEx(query, sizeof(query), "UPDATE `players_table` SET `player_clanid` = '%d' WHERE `player_id` = '%d'", clanid, clientID);
	g_hClansDB.Query(DB_ClientError, query, 10);
}

/**
 * Установка роли игроку
 *
 * @param int clientID - айди игрока в базе
 * @param int role - новая роль игрока
 */
void DB_SetClientRole(int clientID, int role)
{
	char query[600];
	if(role == CLIENT_LEADER)
	{
		int clanid = GetClientClanByID(clientID);

		//Снимаем старого лидера
		FormatEx(query, sizeof(query), "\
		UPDATE \
			`players_table` \
		SET \
			`player_role` = '%d' \
		WHERE \
			`player_role` = '%d' AND `player_clanid` = '%d';", CLIENT_COLEADER, CLIENT_LEADER, clanid);
		g_hClansDB.Query(DB_ClansError, query, 7);
		
		FormatEx(query, sizeof(query), "\
		UPDATE \
			`clans_table` \
		SET \
			`leader_steam` = (SELECT `player_steam` FROM `players_table` WHERE `player_id` = '%d'), \
			`leader_name` = (SELECT `player_name` FROM `players_table` WHERE `player_id` = '%d') \
		WHERE \
			`clan_id` = '%d';", clientID, clientID, clanid);
		g_hClansDB.Query(DB_ClansError, query, 7);
	}
	
	FormatEx(query, sizeof(query), "UPDATE `players_table` SET `player_role` = '%d' WHERE `player_id` = '%d'", role, clientID);
	g_hClansDB.Query(DB_ClientError, query, 4);
}

/**
 * Установка количества убийств игроку
 *
 * @param int clientID - айди игрока в базе
 * @param int kills - число убийств
 */
void DB_SetClientKills(int clientID, int kills)
{
	char query[150];
	FormatEx(query, sizeof(query), "UPDATE `players_table` SET `player_kills` = '%d' WHERE `player_id` = '%d'", kills, clientID);
	g_hClansDB.Query(DB_ClientError, query, 1);
}

/**
 * Установка количества смертей игроку
 *
 * @param int clientID - айди игрока в базе
 * @param int deaths - число смертей
 */
void DB_SetClientDeaths(int clientID, int deaths)
{
	char query[150];
	FormatEx(query, sizeof(query), "UPDATE `players_table` SET `player_deaths` = '%d' WHERE `player_id` = '%d'", deaths, clientID);
	g_hClansDB.Query(DB_ClientError, query, 2);
}

/*
 * Предудаление игрока из базы данных (получение роли)
 *
 * @param int clientID - айди игрока в базе данных
 */
void DB_PreDeleteClient(int clientID)
{
	char query[600];
	FormatEx(query, sizeof(query), "SELECT `player_role`, `player_clanid` FROM `players_table` WHERE `player_id` = '%d'", clientID);
	g_hClansDB.Query(DB_DeleteClient2, query, clientID);
}

/**
 * Непосредственное удаление игрока из клана
 *
 * @param int clientID - айди игрока в базе данных, которого удаляем
 */
void DB_DeleteClient2(Database db, DBResultSet rSet, const char[] error, int clientID)
{
	if(error[0])
	{
		LogError("[CLANS] Query Fail get client's role: %s;", error);
	}
	else
	{
		if(rSet.FetchRow())
		{
			char query[800];
			int role = rSet.FetchInt(0);
			int clanid = rSet.FetchInt(1);
			if(role == CLIENT_LEADER)
			{
				FormatEx(query, sizeof(query), "UPDATE `players_table` SET `player_role` = '%d' WHERE `player_clanid` = '%d' AND `player_id` != '%d' ORDER BY `player_role` DESC LIMIT 1", CLIENT_LEADER, clanid, clientID);
				g_hClansDB.Query(DB_ClientError, query, 4);
				FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `leader_steam` = (SELECT `player_steam` FROM `players_table` WHERE `player_clanid` = '%d' AND `player_id` != '%d' ORDER BY `player_role` DESC LIMIT 1),\
												`leader_name` = (SELECT `player_name` FROM `players_table` WHERE `player_clanid` = '%d' AND `player_id` != '%d' ORDER BY `player_role` DESC LIMIT 1) WHERE `clan_id` = '%d'", clanid, clientID, clanid, clientID, clanid);
				g_hClansDB.Query(DB_ClansError, query, 7);
			}
			FormatEx(query, sizeof(query), "DELETE FROM `players_table` WHERE `player_id` = '%d';", clientID);
			g_hClansDB.Query(DB_ClientError, query, 5);
		}
	}
}

/**
 * Обнулить игрока
 *
 * @param int clientID - айди игрока в базе данных
 */
void DB_ResetClient(int clientID)
{
	char query[300];
	
	//Вычитаем у клана игрока набранными им убийства и смерти
	FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `clan_kills` = (`clan_kills` - (SELECT `player_kills` FROM `players_table` WHERE `player_id` = '%d')) WHERE `clan_id` = (SELECT `player_clanid` FROM `players_table` WHERE `player_id` = '%d');", 
		clientID, clientID);
	g_hClansDB.Query(DB_ClansError, query, 10);
	
	//Обнуляем самого игрока
	FormatEx(query, sizeof(query), "UPDATE `players_table` SET `player_kills` = '0', `player_deaths` = '0' WHERE `player_id` = '%d';", clientID);
	g_hClansDB.Query(DB_ClientError, query, 9);
}

/**
 * Save player (v1.86)
 *
 * @param int iClient - client's index
 *
 * @noreturm
 */
void DB_SavePlayer(int iClient)
{
	if(iClient > 0 && iClient <= MaxClients)
	{
		int iClientID = playerID[iClient];
		if(iClientID != -1)
		{
			char query[512];
			if((g_iClientDiffData[iClient][CD_DIFF_KILLS] != 0 || g_iClientDiffData[iClient][CD_DIFF_DEATHS] != 0))
			{
				FormatEx(query, sizeof(query), "UPDATE players_table SET \
												player_kills = \
													CASE WHEN player_kills + %d < 0 THEN 0 \
													ELSE player_kills + %d END, \
												player_deaths = \
													CASE WHEN player_deaths + %d < 0 THEN 0 \
													ELSE player_deaths + %d END \
												WHERE player_id = %d",
												g_iClientDiffData[iClient][CD_DIFF_KILLS],
												g_iClientDiffData[iClient][CD_DIFF_KILLS],
												g_iClientDiffData[iClient][CD_DIFF_DEATHS],
												g_iClientDiffData[iClient][CD_DIFF_DEATHS],
												iClientID);
				g_hClansDB.Query(DB_ClientError, query, 12);
				//UPDATE IN CLAN
				FormatEx(query, sizeof(query), "UPDATE clans_table SET \
												clan_kills = \
													CASE WHEN clan_kills + %d < 0 THEN 0 \
													ELSE clan_kills + %d END, \
												clan_deaths = \
													CASE WHEN clan_deaths + %d < 0 THEN 0 \
													ELSE clan_deaths + %d END \
												WHERE clan_id = %d",
												g_iClientDiffData[iClient][CD_DIFF_KILLS],
												g_iClientDiffData[iClient][CD_DIFF_KILLS],
												g_iClientDiffData[iClient][CD_DIFF_DEATHS],
												g_iClientDiffData[iClient][CD_DIFF_DEATHS],
												g_iClientData[iClient][CLIENT_CLANID]);
				g_hClansDB.Query(DB_ClansError, query, 12);
			}
			FormatEx(query, sizeof(query), "UPDATE players_table SET player_lastjoin = %d WHERE player_id = %d", GetTime(), iClientID);
			g_hClansDB.Query(DB_ClientError, query, 13);
		}
	}
}
	//============================== LOG ERRORS ЛОГИ ОШИБОК ==============================//

/**
 * Логирование ошибок, связанных с кланами, в базе данных.
 * Номера ошибок:
 * 0 - create, 1 - update kills, 2 - update deaths,
 * 3 - update coins, 4 - update type, 5 - update members
 * 6 - update maxmembers, 7 - update leader, 8 - update name
 * 9 - delete, 10 - reset
 */
void DB_ClansError(Database db, DBResultSet rSet, const char[] error, int errid)
{
    if(error[0] != 0)
    {
        char err[50];
        switch(errid)
        {
            case 0:	err = "create";
            case 1: err = "update kills";
            case 2: err = "update deaths";
            case 3: err = "update coins";
            case 4: err = "update type";
            case 5: err = "update members";
            case 6: err = "update maxmembers";
            case 7: err = "update leader";
            case 8: err = "update name";
            case 9: err = "delete";
            case 10: err = "reset";
			case 11: err = "update leader steam";
			case 12: err = "update when client disconnect";
			case 13: err = "reset clan members";
			case 14: err = "reset clan members in all clans";
			default: err = "UNKNOWN ERROR";
        }
        LogError("[CLANS] Query Fail with clan (code #%d, %s): %s", errid, err, error);
    }
}

/**
 * Логирование ошибок, связанных с клиентами, в базе данных.
 * Номера ошибок:
 * 0 - create, 1 - update kills, 2 - update deaths,
 * 3 - update name, 4 - update role, 5 - delete
 * 6 - load, 7 - full update, 8 - delete by clanid
 * 9 - reset, 10 - update clan
 */
void DB_ClientError(Database db, DBResultSet rSet, const char[] error, int errid)
{
    if(error[0] != 0)
    {
        char err[50];
        switch(errid)
        {
            case 0:	err = "create";
            case 1: err = "update kills";
            case 2: err = "update deaths";
            case 3: err = "update name";
            case 4: err = "update role";
            case 5: err = "delete";
            case 6: err = "load";
            case 7: err = "full update";
            case 8: err = "delete by clanid";
            case 9: err = "reset";
            case 10: err = "update clan";
			case 11: err = "update steam";
			case 12: err = "save player";
			case 13: err = "update last join";
			default: err = "UNKNOWN ERROR";
        }
        LogError("[CLANS] Query Fail with client (code #%d, %s): %s", errid, err, error);
    }
}

/**
 * Логирование ошибок, связанных непосредственно с базой данных
 * 0 - log action, 1 - delete expired actions
 * 2 - update players_table, 3 - update clans_table
 * 
 */
void DB_LogError(Database db, DBResultSet rSet, const char[] error, int errid)
{
	if(error[0] != 0)
	{
		char err[50];
		switch(errid)
		{
			case 0: err = "log action";
			case 1: err = "delete expired actions";
			case 2: err = "update players_table";
			case 3: err = "update clans_table";
			case 4: err = "execute query in queue";
			case 5: err = "add last time join";
			case 6: err = "remove column date_creation";
			case 7: err = "remove column members";
			case 8: err = "add auto_increment to players_table"
			case 9: err = "add auto_increment to clans_table"
			default: err = "UNKNOWN ERROR";
		}
		LogError("[CLANS] Query Failed (code #%d, %s): %s", errid, err, error);
	}
}