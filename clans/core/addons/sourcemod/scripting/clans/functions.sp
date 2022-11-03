	//=============================== CLANS КЛАНЫ ===============================//

/**
 * Check if clan is valid
 *
 * @param int clanid - clan's id
 * 
 * @return true - clan is valid, false - otherwise
 */
bool IsClanValid(int clanid)
{
	SQL_LockDatabase(g_hClansDB);
	char query[150];
	FormatEx(query, sizeof(query), "SELECT 1 FROM `clans_table` WHERE `clan_id` = '%d'", clanid);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		delete rSet;
		return true;
	}
	delete rSet;
	return false;
}

/**
 * Получить имя клана
 *
 * @param int clanid - айди клана
 * @param char[] buffer - буффер, куда сохранять имя
 * @param int maxlength - размер буффера 
 */
void GetClanName(int clanid, char[] buffer, int maxlength)
{
	if(clanid != -1)
	{
		for(int i = 1; i <= MaxClients; ++i)	//v1.87T
		{
			if(IsClientInGame(i) && g_iClientData[i][CLIENT_CLANID] == clanid)
			{
				FormatEx(buffer, maxlength, "%s", g_sClientData[i][CLIENT_CLANNAME]);
				return;
			}
		}
		SQL_LockDatabase(g_hClansDB);
		char query[150];
		FormatEx(query, sizeof(query), "SELECT `clan_name` FROM `clans_table` WHERE `clan_id` = '%d'", clanid);
		DBResultSet rSet = SQL_Query(g_hClansDB, query);
		SQL_UnlockDatabase(g_hClansDB);
		if(rSet != null && rSet.FetchRow())
		{
			rSet.FetchString(0, buffer, maxlength);
		}
		delete rSet;
	}
}

/**
 * Установить имя клана
 *
 * @param int clanid - айди клана
 * @param char[] name - новое имя клана
 *
 * @return true - успешное переименование, false - имя занято
 */
bool SetClanName(int clanid, char[] name)
{
	char clanNameEscaped[MAX_CLAN_NAME*2+1];
	if(!g_hClansDB.Escape(name, clanNameEscaped, sizeof(clanNameEscaped)))
	{
		LogError("[CLANS] Failed to escape clanName in SetClanName!");
		return false;
	}
	SQL_LockDatabase(g_hClansDB);
	char query[150],
		 prevClanName[MAX_CLAN_NAME];
	FormatEx(query, sizeof(query), "SELECT 1 FROM `clans_table` WHERE `clan_name` = '%s'", clanNameEscaped);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.RowCount > 0)
	{
		delete rSet;
		return false;
	}
	GetClanName(clanid, prevClanName, sizeof(prevClanName));
	FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `clan_name` = '%s' WHERE `clan_id` = '%d'", clanNameEscaped, clanid);
	g_hClansDB.Query(DB_LogError, query, 3);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], prevClanName))
		{
			FormatEx(g_sClientData[i][CLIENT_CLANNAME], MAX_NAME_LENGTH, "%s", name);
		}
	}
	if(!g_bCSS34)
		UpdatePlayersClanTag();
	delete rSet;
	return true;
}

/**
 * Get number of clan's coins
 *
 * @param int clanid - clan's id
 * 
 * @return number of clan's coins
 */
int GetClanCoins(int clanid)
{
	SQL_LockDatabase(g_hClansDB);
	int coins = -1;
	char query[150];
	FormatEx(query, sizeof(query), "SELECT `clan_coins` FROM `clans_table` WHERE `clan_id` = '%d'", clanid);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		coins = rSet.FetchInt(0);
	}
	delete rSet;
	return coins;
}

/**
 * Give coins to clan
 *
 * @param int clanid - clan's id
 * @param int coins - coint to be given
 * @param bool givenByAdmin - flag if admin gave coins to clan
 * 
 * @noretun
 */
void GiveClanCoins(int clanid, int coins, bool givenByAdmin)
{
	F_OnClanCoinsGive(clanid, coins, givenByAdmin);
	DB_ChangeClanCoins(clanid, coins);
}

/**
 * Set number of clan's coins
 *
 * @param int clanid - clan's id
 * @param int coins - number of coins to set
 * 
 * @return true - success, false - failed
 */
bool SetClanCoins(int clanid, int coins)
{
	return DB_SetClanCoins(clanid, coins);
}

/**
 * Get number of clan's kills
 *
 * @param int clanid - clan's id
 * 
 * @return number of clan's kills
 */
int GetClanKills(int clanid)
{
	SQL_LockDatabase(g_hClansDB);
	int kills = -1;
	char query[150];
	FormatEx(query, sizeof(query), "SELECT `clan_kills` FROM `clans_table` WHERE `clan_id` = '%d'", clanid);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		kills = rSet.FetchInt(0);
	}
	delete rSet;
	return kills;
}

/**
 * Set number of clan's kills
 *
 * @param int clanid - clan's id
 * @param int kills - number of kills to set
 * 
 * @return true - success, false - failed
 */
bool SetClanKills(int clanid, int kills)
{
	return DB_SetClanKills(clanid, kills);
}

/**
 * Get number of clan's deaths
 *
 * @param int clanid - clan's id
 * 
 * @return number of clan's deaths
 */
int GetClanDeaths(int clanid)
{
	SQL_LockDatabase(g_hClansDB);
	int deaths = -1;
	char query[150];
	FormatEx(query, sizeof(query), "SELECT `clan_deaths` FROM `clans_table` WHERE `clan_id` = '%d'", clanid);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		deaths = rSet.FetchInt(0);
	}
	delete rSet;
	return deaths;
}

/**
 * Set number of clan's deaths
 *
 * @param int clanid - clan's id
 * @param int deaths - number of deaths to set
 * 
 * @return true - success, false - failed
 */
bool SetClanDeaths(int clanid, int deaths)
{
	return DB_SetClanDeaths(clanid, deaths);
}

/**
 * Get number of members in clan
 *
 * @param int clanid - clan's id
 * 
 * @return number of members in clan
 */
int GetClanMembers(int clanid)
{
	SQL_LockDatabase(g_hClansDB);
	int members = 0;
	char query[150];
	FormatEx(query, sizeof(query), "SELECT COUNT(*) FROM `players_table` WHERE `player_clanid` = '%d'", clanid);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		members = rSet.FetchInt(0);
	}
	delete rSet;
	return members;
}

/**
 * Get maximum number of members in clan
 *
 * @param int clanid - clan's id
 * 
 * @return maximum number of members in clan
 */
int GetClanMaxMembers(int clanid)
{
	SQL_LockDatabase(g_hClansDB);
	int members = -1;
	char query[150];
	FormatEx(query, sizeof(query), "SELECT `maxmembers` FROM `clans_table` WHERE `clan_id` = '%d'", clanid);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		members = rSet.FetchInt(0);
	}
	delete rSet;
	return members;
}

/**
 * Set maximum number of members in clan
 *
 * @param int clanid - clan's id
 * @param int maxMembers - maximum number of members in clan to set
 * 
 * @return true - success, false - failed
 */
bool SetClanMaxMembers(int clanid, int maxMembers)
{
	return DB_SetClanMaxMembers(clanid, maxMembers);
}

/**
 * Get clan type
 *
 * @param int clanid - clan's id
 * 
 * @return 0 - closed clan, 1 - open clan, -1 - clan is invalid
 */
int GetClanType(int clanid)
{
	SQL_LockDatabase(g_hClansDB);
	int type = -1;
	char query[150];
	FormatEx(query, sizeof(query), "SELECT `clan_type` FROM `clans_table` WHERE `clan_id` = '%d'", clanid);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		type = rSet.FetchInt(0);
	}
	delete rSet;
	return type;
}

/**
 * Set clan type
 *
 * @param int clanid - clan's id
 * @param int type - 0 - closed clan, 1 - open clan
 * 
 * @return true - success, false - failed
 */
bool SetClanType(int clanid, int type)
{
	if(type < CLAN_CLOSED || type > CLAN_OPEN)
		return false;
	return DB_SetClanType(clanid, type);
}

/**
 *
 * Create clan with online leader
 *
 * @param int leader - leader's id
 * @param char[] clanName - clan's name
 * @param int createdBy - who create a clan (if leader create it by himself/herself createdBy is -1, otherwise - id of administator)
 */
void CreateClan(int leader, char[] clanName, int createdBy = -1)
{
	/*if(leader == createdBy)
		createdBy = -1;*/
	if(!F_PreClanCreate(leader, clanName, createdBy))
		return;
	DB_CreateClan(leader, clanName, createdBy);
	UpdateLastClanCreationTime(leader);
}

/**
 * Reset clan by it's id
 *
 * @param int clanid - clan's id
 *
 * @return true - success, false - failed
 */
bool ResetClan(int clanid, bool bResetPlayers = false, bool bResetCoins = false)
{
	if(bResetPlayers)
	{
		for(int i = 1; i <= MaxClients; ++i)	//v1.86
		{
			if(IsClientInGame(i) && g_iClientData[i][CLIENT_CLANID] == clanid)
			{
				g_iClientData[i][CLIENT_KILLS] = g_iClientData[i][CLIENT_DEATHS] = 0;
				g_iClientDiffData[i][CD_DIFF_KILLS] = g_iClientDiffData[i][CD_DIFF_DEATHS] = 0;
			}
		}
	}
	DB_ResetClan(clanid, bResetPlayers, bResetCoins);
	return true;
}

/**
 * Reset all clans
 */
void ResetAllClans(bool bResetPlayers = false, bool bResetCoins = false)
{
	if(bResetPlayers)
	{
		for(int i = 1; i <= MaxClients; ++i)	//v1.86
		{
			if(IsClientInGame(i) && g_iClientData[i][CLIENT_CLANID] != CLAN_INVALID_CLAN)
			{
				g_iClientData[i][CLIENT_KILLS] = g_iClientData[i][CLIENT_DEATHS] = 0;
				g_iClientDiffData[i][CD_DIFF_KILLS] = g_iClientDiffData[i][CD_DIFF_DEATHS] = 0;
			}
		}
	}
	DB_ResetAllClans(bResetPlayers, bResetCoins);
}

/*
 * Удаление клана по айди
 *
 * @param int clanid - айди клана
 */
void DeleteClan(int clanid)
{
	/*char clanName[MAX_CLAN_NAME];
	GetClanName(clanid, clanName, sizeof(clanName));*/
	DB_DeleteClan(clanid);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		//if(IsClientInGame(i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], clanName))
		if(IsClientInGame(i) && g_iClientData[i][CLIENT_CLANID] == clanid)
		{
			ClearClientData(i);
			F_OnClientDeleted(i, playerID[i], clanid);
		}
	}
	
	F_OnClanDeleted(clanid);
}

	//=============================== CLIENTS ===============================//
/**
 * Очистить данные игрока
 *
 * @param int client - айди игрока
 */
void ClearClientData(int client)
{
	if(client && client <= MaxClients)
	{
		ClanClient = -1;
		g_iClientData[client][CLIENT_CLANID] = -1;
		g_sClientData[client][CLIENT_CLANNAME] = "";
		UpdatePlayerClanTag(client);
	}
}

/**
 * Update all online players' clan tag
 */
void UpdatePlayersClanTag()
{
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			UpdatePlayerClanTag(i);
}

/**
 * Update online player's clan tag
 *
 * @param int client - player's id
 */
void UpdatePlayerClanTag(int client)
{	
	if(!ISTAGENABLE || g_bCSS34 || !IsClientInGame(client))	//v1.9
		return;

	if(ClanClient != -1 && WantToChangeTag(client))
	{
		if(g_iClientData[client][CLIENT_ROLE] == CLIENT_LEADER)
		{
			char leaderTag[16];	//亗
			FormatEx(leaderTag, sizeof(leaderTag), "♦ %s", g_sClientData[client][CLIENT_CLANNAME]);
			CS_SetClientClanTag(client, leaderTag);
		}
		else
		{
			CS_SetClientClanTag(client, g_sClientData[client][CLIENT_CLANNAME]);
		}
	}
	else if(WantToChangeTag(client))
	{
		CS_SetClientClanTag(client, "");
	}
}

/**
 * Get online client's id in database
 *
 * @param int client - player's id
 *
 * @return client's id in database
 */
int GetClientIDinDB(int client)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return -1;
	return ClanClient;
}

/**
 * Get client's id in database by his/her steam
 *
 * @param char[] auth - player's steam
 *
 * @return client's id in database
 */
int GetClientIDinDBbySteam(char[] auth)
{
	char playerAuth[33];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(USEAUTH2)
				GetClientAuthId(i, AuthId_Steam2, playerAuth, sizeof(playerAuth));
			else
				GetClientAuthId(i, AuthId_Steam3, playerAuth, sizeof(playerAuth));
			if(!strcmp(playerAuth, auth))
				return playerID[i];
		}
	}
	SQL_LockDatabase(g_hClansDB);
	int clientID = -1;
	char query[150];
	FormatEx(query, sizeof(query), "SELECT `player_id` FROM `players_table` WHERE `player_steam` = '%s'", auth);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		clientID = rSet.FetchInt(0);
	}
	delete rSet;
	return clientID;
}

/**
 * Get client's name by client's id in database
 *
 * @param int clientID - client's id in database
 * @param char[] buffer - buffer to contain the name
 * @param int maxlength - buffer's size
 */
void GetClientNameByID(int clientID, char[] buffer, int maxlength)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(playerID[i] == clientID && IsClientInGame(i))
		{
			GetClientName(i, buffer, maxlength);
			return;
		}
	}
	SQL_LockDatabase(g_hClansDB);
	char query[150];
	FormatEx(query, sizeof(query), "SELECT `player_name` FROM `players_table` WHERE `player_id` = '%d'", clientID);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		rSet.FetchString(0, buffer, maxlength);
	}
	delete rSet;
}

/**
 * Check if online player in clan
 *
 * @param int client - player's id
 *
 * @return true - player in any clan, false otherwise
 */
bool IsClientInClan(int client)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || ClanClient < 0)
	//if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return false;
	return true; //Если что то будет не так, то тут было: strcmp(g_sClientData[client][CLIENT_CLANNAME], "") == 0;
	//return strcmp(g_sClientData[client][CLIENT_CLANNAME], "") != 0;
}

/**
 * Get client's clan id in database by client's id
 *
 * @param int clientID - player's id in database
 * @param bool bFromDB = false - get data from database (v1.86). Returns the cached value if player is online
 *
 * @return client's clan id
 */
int GetClientClanByID(int clientID, bool bFromDB = false)
{
	if(clientID < 0)
		return -1;
	if(!bFromDB)
	{
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(playerID[i] == clientID)
				return g_iClientData[i][CLIENT_CLANID];
		}
	}
	SQL_LockDatabase(g_hClansDB);
	int clanid = -1;
	char query[150];
	FormatEx(query, sizeof(query), "SELECT `player_clanid` FROM `players_table` WHERE `player_id` = '%d'", clientID);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		clanid = rSet.FetchInt(0);
	}
	delete rSet;
	return clanid;
}

/**
 * Check if players in different clans
 *
 * @param int client - player's id
 *
 * @param int other - other player's id
 *
 * @return true - players in different clans, otherwise - false
 */
bool AreClientsInDifferentClans(int client, int other)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || other < 1 || other > MaxClients || !IsClientInGame(other))
		return true;
	//return strcmp(g_sClientData[client][CLIENT_CLANNAME], g_sClientData[other][CLIENT_CLANNAME]) != 0;
	return g_iClientData[client][CLIENT_CLANID] != g_iClientData[other][CLIENT_CLANID];	//v1.87T
}

/**
 * Поставить нового лидера в клане по айди игрока в базе данных
 * Проверять, что игрок состоит в этом клане!
 *
 * @param int leaderid - айди нового лидера в базе данных
 * @param int clanid - айди клана (removed since 1.87T)
 */
void SetClanLeaderByID(int leaderid)//, int clanid)
{
	SetClientRoleByID(leaderid, CLIENT_LEADER);
}

/**
 * Get player's role by his/her id
 *
 * @param int clientID - player's id in database
 * @param bool bFromDB = false - get data from database (v1.86). Returns the cached value if player is online
 *
 * @return player's role
*/
int GetClientRoleByID(int clientID, bool bFromDB = false)
{
	if(clientID < 0)
		return -1;
	if(!bFromDB)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(playerID[i] == clientID)
				return g_iClientData[i][CLIENT_ROLE];
		}
	}
	SQL_LockDatabase(g_hClansDB);
	int role = -1;
	char query[150];
	FormatEx(query, sizeof(query), "SELECT `player_role` FROM `players_table` WHERE `player_id` = '%d'", clientID);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		role = rSet.FetchInt(0);
	}
	delete rSet;
	return role;
}

/**
 * Check if player is clan leader by id
 *
 * @param int clientID - player's id in database
 * @param bool bFromDB = false - get data from database (v1.86). Returns the cached value if player is online
 *
 * @return true - player is clan leader, otherwise - false
 */
bool IsClientClanLeaderByID(int clientID, bool bFromDB = false)
{
	return GetClientRoleByID(clientID, bFromDB) == CLIENT_LEADER;
}

/**
 * Check if player is clan co-leader by id
 *
 * @param int clientID - player's id
 * @param bool bFromDB = false - get data from database (v1.86). Returns the cached value if player is online
 *
 * @return true - player is clan co-leader, otherwise - false
 */
bool IsClientClanCoLeaderByID(int clientID, bool bFromDB = false)
{
	return GetClientRoleByID(clientID, bFromDB) == CLIENT_COLEADER;
}

/**
 * Check if player is clan elder by id
 *
 * @param int clientID - player's id in database
 * @param bool bFromDB = false - get data from database (v1.86). Returns the cached value if player is online
 *
 * @return true - player is clan elder, otherwise - false
 */
bool IsClientClanElderByID(int clientID, bool bFromDB = false)
{
	return GetClientRoleByID(clientID, bFromDB) == CLIENT_ELDER;
}

/**
 * Set player's role by id
 *
 * @param int clientID - player's id in database
 * @param int newRole - new role of the player
 *
 * @return true if succeed, false otherwise
*/
bool SetClientRoleByID(int clientID, int newRole)
{
	if(newRole < CLIENT_MEMBER || newRole > CLIENT_LEADER || clientID < 0)
		return false;
	DB_SetClientRole(clientID, newRole);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(playerID[i] == clientID)
			g_iClientData[i][CLIENT_ROLE] = newRole;
	}
	return true;
}

/**
 * Get client's kills in current clan by client's id
 *
 * @param int clientID - client's id in database
 * @param		bool bFromDB = false - get data from database (v1.86). Returns the cached value if player is online
 *
 * @return number of client's kills
 */
int GetClientKillsInClanByID(int clientID, bool bFromDB = false)
{
	if(clientID < 0)
		return -1;
	if(!bFromDB)
	{
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(playerID[i] == clientID)
				return g_iClientData[i][CLIENT_KILLS]+g_iClientDiffData[i][CD_DIFF_KILLS] > 0 ? g_iClientData[i][CLIENT_KILLS]+g_iClientDiffData[i][CD_DIFF_KILLS] : 0;
		}
	}
	SQL_LockDatabase(g_hClansDB);
	char query[150];
	FormatEx(query, sizeof(query), "SELECT `player_kills` FROM `players_table` WHERE `player_id` = '%d'", clientID);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		return rSet.FetchInt(0);
	}
	delete rSet;
	return -1;
}

/**
 * Set client kills in clan by client's id
 *
 * @param int clientID - client's id in database
 *
 * @param int kills - player's kills to set
 *
 * @return true - success, false - failed
 */
bool SetClientKillsInClanByID(int clientID, int kills)
{
	if(clientID < 0)
		return false;
	int clanid = GetClientClanByID(clientID);
	if(clanid == -1)
		return false;
	int killsNow = GetClientKillsInClanByID(clientID);
	int killsToAddToClan = kills - killsNow;
	DB_SetClientKills(clientID, kills);
	DB_ChangeClanKills(clanid, killsToAddToClan);
	return true;
}

/**
 * Изменение числа убийств игрока
 *
 * @param int clientID - айди игрока в БД
 * @param int amountToAdd - число, на сколько изменить число убийств
 *
 * @return true - success, false - failed
 */
bool ChangeClientKillsInClanByID(int clientID, int amountToAdd)
{
	if(clientID < 0)
		return false;
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(playerID[i] == clientID)
		{
			g_iClientDiffData[i][CD_DIFF_KILLS] += amountToAdd;
			return true;
		}
	}
	char query[400];
	Transaction txn = SQL_CreateTransaction();
	FormatEx(query, sizeof(query), "UPDATE `players_table` SET `player_kills` = `player_kills`+'%d' WHERE `player_id` = '%d'", amountToAdd, clientID);
	txn.AddQuery(query);
	FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `clans_kills` = `clans_kills` + '%d' WHERE `clan_id` = (SELECT `player_clanid` FROM `players_table` WHERE `player_id` = '%d')", amountToAdd, clientID);
	txn.AddQuery(query);
	SQL_ExecuteTransaction(g_hClansDB, txn);
	return true;
}

/**
 * Get client's deaths in current clan by client's id
 *
 * @param int clientID - client's id in database
 * @param		bool bFromDB = false - get data from database (v1.86). Returns the cached value if player is online
 *
 * @return number of client's deaths
 */
int GetClientDeathsInClanByID(int clientID, bool bFromDB = false)
{
	if(clientID < 0)
		return -1;
	if(!bFromDB)
	{
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(playerID[i] == clientID)
				return g_iClientData[i][CLIENT_DEATHS]+g_iClientDiffData[i][CD_DIFF_DEATHS] >= 0 ? g_iClientData[i][CLIENT_DEATHS]+g_iClientDiffData[i][CD_DIFF_DEATHS] : 0;
		}
	}
	SQL_LockDatabase(g_hClansDB);
	char query[150];
	FormatEx(query, sizeof(query), "SELECT `player_deaths` FROM `players_table` WHERE `player_id` = '%d'", clientID);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		return rSet.FetchInt(0);
	}
	delete rSet;
	return -1;
}
/**
 * Set client's deaths in current clan by client's id
 *
 * @param int clientID - player's id in database
 *
 * @param int deaths - client's deaths to set
 *
 * @return true - success, false - failed
 */
bool SetClientDeathsInClanByID(int clientID, int deaths)
{
	if(clientID < 0)
		return false;
	int clanid = GetClientClanByID(clientID);
	if(clanid == -1)
		return false;
	int deathsNow = GetClientDeathsInClanByID(clientID);
	int deathsToAddToClan = deaths - deathsNow;
	DB_SetClientDeaths(clientID, deaths);
	DB_ChangeClanDeaths(clanid, deathsToAddToClan);
	return true;
}

/**
 * Изменение числа смертей игрока
 *
 * @param int clientID - айди игрока в БД
 * @param int amountToAdd - число, на сколько изменить число смертей
 *
 * @return true - success, false - failed
 */
bool ChangeClientDeathsInClanByID(int clientID, int amountToAdd)
{
	if(clientID < 0)
		return false;
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(playerID[i] == clientID)
		{
			g_iClientDiffData[i][CD_DIFF_DEATHS] += amountToAdd;
			return true;
		}
	}
	char query[400];
	Transaction txn = SQL_CreateTransaction();
	FormatEx(query, sizeof(query), "UPDATE `players_table` SET `player_deaths` = `player_deaths`+'%d' WHERE `player_id` = '%d'", amountToAdd, clientID);
	txn.AddQuery(query);
	FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `clans_deaths` = `clans_deaths` + '%d' WHERE `clan_id` = (SELECT `player_clanid` FROM `players_table` WHERE `player_id` = '%d')", amountToAdd, clientID);
	txn.AddQuery(query);
	SQL_ExecuteTransaction(g_hClansDB, txn);
	return true;
}

void KillFunc(int attacker, int victim, int amount)
{
	/*
	//Transaction txn = SQL_CreateTransaction();
	char query[400];
	if(victimID != -1)
	{
		FormatEx(query, sizeof(query), "UPDATE `players_table` SET `player_deaths` = `player_deaths`+'%d' WHERE `player_id` = '%d'", amount, victimID);
		//txn.AddQuery(query);
		g_hClansDB.Query(DB_ClientError, query, 2);
		FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `clan_deaths` = `clan_deaths` + '%d' WHERE `clan_id` = (SELECT `player_clanid` FROM `players_table` WHERE `player_id` = '%d')", amount, victimID);
		g_hClansDB.Query(DB_ClansError, query, 2);
		//txn.AddQuery(query);
	}
	if(attackerID != -1)
	{
		FormatEx(query, sizeof(query), "UPDATE `players_table` SET `player_kills` = `player_kills`+'%d' WHERE `player_id` = '%d'", amount, attackerID);
		//txn.AddQuery(query);
		g_hClansDB.Query(DB_ClientError, query, 1);
		FormatEx(query, sizeof(query), "UPDATE `clans_table` SET `clan_kills` = `clan_kills` + '%d' WHERE `clan_id` = (SELECT `player_clanid` FROM `players_table` WHERE `player_id` = '%d')", amount, attackerID);
		g_hClansDB.Query(DB_ClansError, query, 1);
		//txn.AddQuery(query);
	}
	//SQL_ExecuteTransaction(g_hClansDB, txn);*/
	g_iClientDiffData[attacker][CD_DIFF_KILLS] += amount;
	g_iClientDiffData[victim][CD_DIFF_DEATHS] += amount;
}

/**
 * Get clien't time in clan by client's id in database
 *
 * @param int clientID - client's index in database
 *
 * @return client's time in clan. Returns -1 if client isn't in any clan
 */
int GetClientTimeInClanByID(int clientID)
{
	if(clientID < 0)
		return -1;
	for(int i = 1; i <= MaxClients; ++i)	//vv1.86
	{
		if(IsClientInGame(i) && playerID[i] == clientID)
		{
			return g_iClientData[i][CLIENT_TIME];
		}
	}
	SQL_LockDatabase(g_hClansDB);
	int time = -1;
	char query[150];
	FormatEx(query, sizeof(query), "SELECT `player_timejoining` FROM `players_table` WHERE `player_id` = '%d'", clientID);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		time = rSet.FetchInt(0);
	}
	delete rSet;
	return time;
}

/**
 * Get clan client's name by client's id
 *
 * @param int clientID - client's id in database
 * @param char[] buffer - buffer to contain the name
 * @param int maxlength - buffer size
 */
void GetClanClientNameByID(int clientID, char[] buffer, int maxlength)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(playerID[i] == clientID && IsClientInGame(i))
		{
			GetClientName(i, buffer, maxlength);
			return;
		}
	}
	if(clientID < 0)
		return;
	SQL_LockDatabase(g_hClansDB);
	char query[150];
	FormatEx(query, sizeof(query), "SELECT `player_name` FROM `players_table` WHERE `player_id` = '%d'", clientID);
	DBResultSet rSet = SQL_Query(g_hClansDB, query);
	SQL_UnlockDatabase(g_hClansDB);
	if(rSet != null && rSet.FetchRow())
	{
		rSet.FetchString(0, buffer, maxlength);
	}
	delete rSet;
}

/**
 * Create online clan client
 *
 * @param int client - client's id
 * @param int clanid - clan's id
 @ @param int role - client's role
 */
void CreateClient(int client, int clanid, int role)
{
	char name[MAX_NAME_LENGTH+1], auth[33];
	ClearClientData(client);
	GetClientName(client, name, sizeof(name));
	if(USEAUTH2)
		GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	else
		GetClientAuthId(client, AuthId_Steam3, auth, sizeof(auth));
	DB_CreateClientByData(name, auth, clanid, role, client);
	DB_LoadClient(client);
}

/**
 * Reset player's stats in clan by player's id
 *
 * @param int clientID - player's id in database
 */
void ResetClient(int clientID)
{
	if(clientID >= 0)
	{
		for(int i = 1; i <= MaxClients; ++i)	//vv1.86
		{
			if(IsClientInGame(i) && playerID[i] == clientID)
			{
				g_iClientDiffData[i][CD_DIFF_KILLS] = -g_iClientData[i][CLIENT_KILLS];
				g_iClientDiffData[i][CD_DIFF_DEATHS] = -g_iClientData[i][CLIENT_DEATHS];
				return;
			}
		}
	}
	DB_ResetClient(clientID);
}

/**
 * Delete client by his/her id in database
 *
 * @param int clientID - player's id in database
 *
 * @return true - success, false - failed
 */
bool DeleteClientByID(int clientID)
{
	if(clientID < 0)
		return false;
	char query[256];
	FormatEx(query, sizeof(query), "SELECT COUNT(*), player_clanid FROM players_table WHERE player_clanid = (SELECT player_clanid FROM players_table WHERE player_id = %d) GROUP BY player_clanid", clientID);
	g_hClansDB.Query(DBF_DeleteClientByID, query, clientID);	//v1.87T
	return true;
}

//v1.87T
void DBF_DeleteClientByID(Database db, DBResultSet rSet, const char[] sError, int iClientID)
{
	if(sError[0])
	{
		LogError("[CLANS] Failed to get members in the clan (DeleteClientByID): %s", sError);
	}
	else if(rSet.FetchRow())
	{
		int clanid = rSet.FetchInt(1);
		int clanMembers = rSet.FetchInt(0);
		if(clanMembers == 1)	//Если в клане нет никого еще, кроме того, кого удаляют ( лидер кому-то не угодил или сам ливнуть решил :( )
		{
			DeleteClan(clanid);
		}
		else	//Если в клане все же есть еще люди
		{
			int iClient = -1;
			for(int i = 1; i <= MaxClients; i++)
			{
				if(playerID[i] == iClientID)
				{
					ClearClientData(i);
					iClient = i;
				}
			}
			DB_SavePlayer(iClient);
			DB_PreDeleteClient(iClientID);
			F_OnClientDeleted(iClient, iClientID, clanid);
		}
		if(!g_bCSS34)
			UpdatePlayersClanTag();
	}
}

/**
 * Set client's clan id (only if client is online)
 *
 * @param int client - player's id
 * @param int clanid - clan id
 * @param int role - role of player. 0 - member, 1 - elder, 2 - co-leader, 4 - leader
 *
 * @return true - success, false - failed
 */
bool SetOnlineClientClan(int client, int clanid, int role)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return false;
	
	if(IsClientInClan(client))
	{
		DeleteClientByID(ClanClient);
	}
	CreateClient(client, clanid, role);
	return true;
}

/**
 * Check if player has a permission to do smth
 *
 * @param int client - player's id
 * @param int permission - permission id
 * @return true if player has the permission, false otherwise
*/
bool CanPlayerDo(int client, int permission)
{
	if(client < 0 || client > MaxClients)
		return false;
	//int role = GetClientRoleByID(ClanClient);
	int role = g_iClientData[client][CLIENT_ROLE];	//v1.87T
	switch(permission)
	{
		case 1:	//invite
			return g_iRInvitePerm & role > 0;
		case 2: //givecoins
			return g_iRGiveCoinsToClan & role > 0;
		case 3: //expand
			return g_iRExpandClan & role > 0;
		case 4: //kick
			return g_iRKickPlayer & role > 0;
		case 5: //change type
			return g_iRChangeType & role > 0;
		case 6: //change role
			return g_iRChangeRole & role > 0;
		default:
			return false;
	}
}

/**
 * Check if role has a permission to do smth
 *
 * @param int role - role's index
 * @param int permission - permission id
 * @return true if player has the permission, false otherwise
*/
bool CanRoleDo(int role, int permission)
{
	if(role < CLIENT_MEMBER || role > CLIENT_LEADER)
		return false;
	switch(permission)
	{
		case 1:	//invite
			return g_iRInvitePerm & role > 0;
		case 2: //givecoins
			return g_iRGiveCoinsToClan & role > 0;
		case 3: //expand
			return g_iRExpandClan & role > 0;
		case 4: //kick
			return g_iRKickPlayer & role > 0;
		case 5: //change type
			return g_iRChangeType & role > 0;
		case 6: //change role
			return g_iRChangeRole & role > 0;
		default:
			return false;
	}
}

/**
 * Проверка, что роль может делать хоть что-то
 *
 * @param int role - индекс роли
 *
 * @return true - игрок может делать хоть что-то, false иначе
 */
bool CanRoleDoAnything(int role)
{
	if(role < CLIENT_MEMBER || role > CLIENT_LEADER)
		return false;
		
	int check;
	check = g_iRInvitePerm & role;
	check |= g_iRGiveCoinsToClan & role;
	check |= g_iRExpandClan & role;
	check |= g_iRKickPlayer & role;
	check |= g_iRChangeType & role;
	check |= g_iRChangeRole & role;

	if(role > 3)
		role = 3;
	
	if(g_alRolesOptions[role].Length > 0)
	{
		return true;
	}

	return check > 0;
}

	//=============================== OTHERS ОСТАЛЬНЫЕ ===============================//

/**
 * Converting seconds to time
 *
 * @param int seconds
 * @param char[] buffer - time, format: MONTHS:DAYS:HOURS:MINUTES:SECONDS
 * @param int maxlength - size of buffer
 * @param int client - who will see the time
 */
void SecondsToTime(int seconds, char[] buffer, int maxlength, int client)
{
	int months, days, hours, minutes;
	months = seconds/2678400;
	seconds -= 2678400*months;
	days = seconds/86400;
	seconds -= 86400*days;
	hours = seconds/3600;
	seconds -= 3600*hours;
	minutes = seconds/60;
	seconds -= 60*minutes;
	FormatEx(buffer, maxlength, "%T", "Time", client, months, days, hours, minutes, seconds);
}

/**
 * Register a clan control option. If there is any of extra different from the core options
 * Clan control menu will be created and shown to client. Also it will be active in the main menu
 *
 * @param int iRole - required role for the option
 *
 * @return Clan_RegStatus - status of the registration
 */
Clan_RegStatus RegisterExtraOptionForClanControl(int iRole, Handle hPlugin)
{
	if(GetFunctionByName(hPlugin, "Clans_OnClanControlMenuOpened") == INVALID_FUNCTION)
		return CR_NoMenuOpenedForward;

	if(GetFunctionByName(hPlugin, "Clans_ApproveHandle") == INVALID_FUNCTION)
		return CR_NoApprove;
	
	for(int i = 0; i < g_alRolesOptions[iRole].Length; ++i)
	{
		if(g_alRolesOptions[iRole].Get(i) == hPlugin)
			return CR_AlreadyExists;
	}

	g_alRolesOptions[iRole].Push(hPlugin);
	return CR_Success;
}

/**
 * Remove an extra clan control option.
 *
 * @param int iRole - required role for the option
 *
 * @return true on success, false otherwise (plugin hasn't registered options for this role)
 */
bool RemoveClanControlOption(int iRole, Handle hPlugin)
{
	for(int i = 0; i < g_alRolesOptions[iRole].Length; ++i)
	{
		if(g_alRolesOptions[iRole].Get(i) == hPlugin)
		{
			g_alRolesOptions[iRole].Erase(i);
			return true;
		}
	}

	return false;
}

/**
 * Check if player has required admin flag (z)
 *
 * @param int iClient - client's index
 *
 * @return true if he/she has, false otherwise
 */
bool HasPlayerAdminFlag(int iClient)
{
	if(g_iAdminFlagForCCT == -1)
		return false;

	AdminId admID = GetUserAdmin(iClient);
	return admID != INVALID_ADMIN_ID && admID.HasFlag(view_as<AdminFlag>(g_iAdminFlagForCCT), Access_Real);
}