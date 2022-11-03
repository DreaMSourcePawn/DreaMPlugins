Database g_hLogDB = null;

/**
 * Подготовка базы данных для логирования
 */
void PrepareDatabaseToLog()
{
	char DB_Error[255];
	if(SQL_CheckConfig("clans_log"))
		g_hLogDB = SQL_Connect("clans_log", true, DB_Error, sizeof(DB_Error));
	else
		g_hLogDB = SQLite_UseDatabase("clans_log", DB_Error, sizeof(DB_Error));

	if(g_hLogDB == INVALID_HANDLE)
	{
		SetFailState("[Clans] Unable to connect to log database (%s)", DB_Error);
		return;
	}
	SQL_FastQuery(g_hLogDB, "CREATE TABLE IF NOT EXISTS `logs` (`playerid` INTEGER, `pname` VARCHAR(255), `clanid` INTEGER, `cname` VARCHAR(255), `action` TEXT, `toWhomPID` INTEGER, `toWhomPName` VARCHAR(255), `toWhomCID` INTEGER, `toWhomCName` VARCHAR(255), `type` INTEGER, `itime` INTEGER, `time` VARCHAR(50))");
	DeleteExpiredRecords();
}

/**
 * Удалить слишком старые записи из базы
 */
void DeleteExpiredRecords()
{
	int time = GetTime();
	char query[100];
	time = time - g_iLogExpireDays*24*60*60;
	FormatEx(query, sizeof(query), "DELETE FROM `logs` WHERE `time` < '%d'", time);
	g_hLogDB.Query(DB_LogError, query, 1);
}

/**
 * Логирование действий игроков
 *
 * @param int client - айди игрока, который совершил действие
 * @param bool clientFromDB - флаг, что client - айди из базы данных
 * @param int clientClanid - айди клана того игрока, кто совершил действие
 * @param char[] action - действие, которое совершил игрок
 * @param int target - айди игрока, над которым совершили действие
 * @param bool targetFromDB - флаг, что toWhomP - айди игрока из базы данных
 * @param int targetClanid - айди клана игрока, над которым совершили действие
 * @param int type - тип лога (см. define LOG_???)
 *
 */
void DB_LogAction(int client, bool clientFromDB, int clientClanid, const char[] action, int target, bool targetFromDB, int targetClanid, int type)
{
	DataPack dp = CreateDataPack();
	dp.WriteCell(client);
	dp.WriteCell(clientFromDB);
	dp.WriteCell(clientClanid);
	dp.WriteString(action);
	dp.WriteCell(target);
	dp.WriteCell(targetFromDB);
	dp.WriteCell(targetClanid);
	dp.WriteCell(type);
	dp.Reset();
	CreateTimer(0.1, Timer_LogAction, dp);
}
 
//Action Timer_LogAction(int client, bool clientFromDB, int clientClanid, const char[] action, int target, bool targetFromDB, int targetClanid, int type)
Action Timer_LogAction(Handle timer, DataPack data)
{
	char query[1024],
		 clientName[MAX_NAME_LENGTH+1],
		 targetName[MAX_NAME_LENGTH+1], 
		 action[300];
	clientName = "None"; targetName = "None";
	
	int client = data.ReadCell();
	bool clientFromDB = data.ReadCell();
	int clientClanid = data.ReadCell();
	data.ReadString(action, sizeof(action));
	int target = data.ReadCell();
	bool targetFromDB = data.ReadCell();
	int targetClanid = data.ReadCell();
	int type = data.ReadCell();
	delete data;
	
	int clientID = -1;	//айди игрока, который совершил действие, в базе
	if(clientFromDB)	//нам подали айди с базы
	{
		clientID = client;
		GetClanClientNameByID(clientID, clientName, sizeof(clientName));
	}
	else if(client > 0 && client <= MaxClients)
	{
		clientID = ClanClient;
		if(IsClientInGame(client))
			GetClientName(client, clientName, sizeof(clientName));
	}
	
	int targetID = -1;	//Айди игрока, над которым произошло действие, в базе
	if(targetFromDB)
	{
		targetID = target;
		GetClanClientNameByID(targetID, targetName, sizeof(targetName));
	}
	else if(target > 0 && target <= MaxClients)
	{
		targetID = playerID[target];
		if(IsClientInGame(target))
			GetClientName(target, targetName, sizeof(targetName));
	}
	DataPack dp = CreateDataPack();
	dp.WriteCell(clientID);
	dp.WriteString(clientName);
	dp.WriteCell(clientClanid);
	dp.WriteString(action);
	dp.WriteCell(targetID);
	dp.WriteString(targetName);
	dp.WriteCell(targetClanid);
	dp.WriteCell(type);
	dp.Reset();
	
	FormatEx(query, sizeof(query), "SELECT `clan_name` FROM `clans_table` WHERE `clan_id` = '%d'\
									UNION SELECT `clan_name` FROM `clans_table` WHERE `clan_id` = '%d'", clientClanid, targetClanid);
	g_hClansDB.Query(DB_LogCallback, query, dp);

	return Plugin_Stop;
}

void DB_LogCallback(Handle owner, Handle hndl, const char[] error, DataPack dp)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[CLANS] Query Fail log: %s", error);
	}
	else
	{
		char clientName[MAX_NAME_LENGTH+1], 
			 clientClanName[MAX_NAME_LENGTH+1], 
			 targetName[MAX_NAME_LENGTH+1], 
			 targetClanName[MAX_NAME_LENGTH+1], 
			 action[300],
			 query[2048];
		clientClanName = "None"; targetClanName = "None";
		int clientID = dp.ReadCell();
		dp.ReadString(clientName, sizeof(clientName));
		int clientClanid = dp.ReadCell();
		dp.ReadString(action, sizeof(action));
		int targetID = dp.ReadCell();
		dp.ReadString(targetName, sizeof(targetName));
		int targetClanid = dp.ReadCell();
		int type = dp.ReadCell();
		if(clientClanid >= 0)
		{
			if(SQL_FetchRow(hndl))
				SQL_FetchString(hndl, 0, clientClanName, sizeof(clientClanName));
			if(clientClanid == targetClanid)
				targetClanName = clientClanName;
		}
		if(targetClanid >= 0)
		{
			if(SQL_FetchRow(hndl))
				SQL_FetchString(hndl, 0, targetClanName, sizeof(targetClanName));
			if(clientClanid == targetClanid)
				clientClanName = targetClanName;
		}
		
		int time = GetTime();
		char c_time[50];
		if(g_iLogs > 1)	//ToFile
		{
			char fileName[150],
				 date[30];
			File file;
			FormatTime(c_time, sizeof(c_time), "%H:%M:%S", time);
			FormatTime(date, sizeof(date), "%Y%m%d", time);
			if(!DirExists("addons/sourcemod/logs/clans"))
				CreateDirectory("addons/sourcemod/logs/clans", 509);
			if(g_iLogs == 2)	//log file name equals to current date
				FormatEx(fileName, sizeof(fileName), "addons/sourcemod/logs/clans/clans_%s.log", date);
			else
				FormatEx(fileName, sizeof(fileName), "addons/sourcemod/logs/clans/clans.log");
			file = OpenFile(fileName, "a");
			if(file != null)
			{
				file.WriteLine("%s: %s (%d in DB) from %s clan (%d in DB) %s %s (%d in DB) from %s clan (%d in DB). Type = %d", c_time, clientName, clientID, clientClanName, clientClanid, action, targetName, targetID, targetClanName, targetClanid, type);
				file.Close();
			}
			else
			{
				LogError("CLANS LOG: failed to open file. Something wrong with the log file.");
			}
			//LogToFileEx(fileName, "%s (%d in DB) from %s clan (%d in DB) %s %s (%d in DB) from %s clan (%d in DB). Type = %d", clientName, clientID, clientClanName, clientClanid, action, targetName, targetID, targetClanName, targetClanid, type);
		}
		else	//To sqlite
		{
			char clientNameEscaped[MAX_NAME_LENGTH*2+1],
			 	 clientClanNameEscaped[MAX_NAME_LENGTH*2+1],
			 	 targetNameEscaped[MAX_NAME_LENGTH*2+1],
			 	 targetClanNameEscaped[MAX_CLAN_NAME*2+1],
                 actionEscaped[610];
			if(!g_hLogDB.Escape(clientName, clientNameEscaped, sizeof(clientNameEscaped)))
			{
				LogError("[CLANS] Failed to escape the clientName in LogCallback!");
				return;
			}
			if(!g_hLogDB.Escape(clientClanName, clientClanNameEscaped, sizeof(clientClanNameEscaped)))
			{
				LogError("[CLANS] Failed to escape the clientClanName in LogCallback!");
				return;
			}
			if(!g_hLogDB.Escape(targetName, targetNameEscaped, sizeof(targetNameEscaped)))
			{
				LogError("[CLANS] Failed to escape the targetName in LogCallback!");
				return;
			}
			if(!g_hLogDB.Escape(targetClanName, targetClanNameEscaped, sizeof(targetClanNameEscaped)))
			{
				LogError("[CLANS] Failed to escape the targetClanName in LogCallback!");
				return;
			}if(!g_hLogDB.Escape(action, actionEscaped, sizeof(actionEscaped)))
			{
				LogError("[CLANS] Failed to escape the targetClanName in LogCallback!");
				return;
			}
			FormatTime(c_time, sizeof(c_time), "%c", time);
			FormatEx(query, sizeof(query), "INSERT INTO `logs` VALUES ('%d', '%s', '%d', '%s', '%s', '%d', '%s', '%d', '%s', '%d', '%d', '%s')", clientID, clientNameEscaped, clientClanid, clientClanNameEscaped, actionEscaped, targetID, targetNameEscaped, targetClanid, targetClanNameEscaped, type, time, c_time);
			g_hLogDB.Query(DB_LogError, query, 0);
		}
	}
	delete dp;
}

/**
 * Check if the type of logging is available
 *
 * @param int type - type of logging
 * @return true if this type is available, false otherwise
*/
bool CheckForLog(int type)
{
	return g_iLogs > 0 && type & g_iLogFlags > 0;
}