void RegAdminCommands()
{
	RegAdminCmd("sm_aclans", Command_AdminClansMenu, ADMFLAG_ROOT);
	RegAdminCmd("sm_ptoclan", Command_AddPlayerToClan, ADMFLAG_ROOT);
	RegAdminCmd("sm_poutofclan", Command_RemovePlayerFromClan, ADMFLAG_ROOT);
	RegAdminCmd("sm_adclan", Command_AdminDeleteClan, ADMFLAG_ROOT);
	RegAdminCmd("sm_asetcoins", Command_AdminSetCoins, ADMFLAG_ROOT);
	RegAdminCmd("sm_arclan", Command_AdminResetClan, ADMFLAG_ROOT);
	RegAdminCmd("sm_arclient", Command_AdminResetClient, ADMFLAG_ROOT);
	RegAdminCmd("sm_achelp", Command_AdminClanHelp, ADMFLAG_ROOT);
}

/**
 * Add online player to clan by command
 * 
 * @param args 1 - player's userid in status
 * @param args 2 - clan id
 */
public Action Command_AddPlayerToClan(int client, int args)
{
	char print_buff[BUFF_SIZE];
	if(args != 3)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_WrongPToClan", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	char buff[10],
		 clanName[MAX_CLAN_NAME+1];
	int target, clanid, roleFlag;
	GetCmdArg(1, buff, sizeof(buff));
	target = GetClientOfUserId(StringToInt(buff));
	GetCmdArg(2, buff, sizeof(buff));
	clanid = StringToInt(buff);
	GetClanName(clanid, clanName, sizeof(clanName));
	GetCmdArg(3, buff, sizeof(buff));
	roleFlag = StringToInt(buff);
	if(roleFlag < 0 || roleFlag > 4 || roleFlag == 3)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_WrongRoleFlag", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	if(GetClanMembers(clanid) < 1)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanDoesntExist", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	if(!target || !IsClientAuthorized(target))
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerIsntAuth", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	if(GetClientClanByID(GetClientIDinDB(target)) == clanid)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerInThisClan", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	SetOnlineClientClan(target, clanid, roleFlag);
	FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerAddedToClan", client, clanName);
	CPrintToChat(client, print_buff);
	if(CheckForLog(LOG_CLIENTACTION))
	{
		char log_buff[LOG_SIZE], 
			 userName[MAX_NAME_LENGTH+1];
		GetClientName(target, userName, sizeof(userName));
		FormatEx(log_buff, sizeof(log_buff), "%T", "LA_CreatePlayer", LANG_SERVER, userName, clanName, roleFlag);
		DB_LogAction(ClanClient, true, GetClientClanByID(ClanClient), log_buff, target, false, clanid, LOG_CLIENTACTION);
	}
	return Plugin_Handled;
}

/**
 * Remove player from a clan
 * 
 * @param args 1 - player's userid in status
 */
public Action Command_RemovePlayerFromClan(int client, int args)
{
	char print_buff[BUFF_SIZE];
	if(args != 1)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_WrongPOutOfClan", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	char buff[33],
		 clanName[MAX_CLAN_NAME+1],
		 targetName[MAX_NAME_LENGTH+1];
	int clientID;
	GetCmdArg(1, buff, sizeof(buff));
	if(IsCharNumeric(buff[0]))
	{
		clientID = StringToInt(buff);
		if(clientID == -1)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerIDDoesntExist", client);
			CPrintToChat(client, print_buff);
			return Plugin_Handled;
		}
		GetClientNameByID(clientID, targetName, sizeof(targetName));
		int clanid = GetClientClanByID(clientID);
		GetClanName(clanid, clanName, sizeof(clanName));
		/*if(g_iClientData[clientID][CLIENT_CLANID] == -1)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerIDDoesntExist", client);
			CPrintToChat(client, print_buff);
			return Plugin_Handled;
		}*/
		if(CheckForLog(LOG_CLIENTACTION))
		{
			char log_buff[LOG_SIZE];
			FormatEx(log_buff, sizeof(log_buff), "%T", "LA_DeletePlayer", LANG_SERVER, targetName, clanName);
			DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, clientID, true, clanid, LOG_CLIENTACTION);
		}
		DeleteClientByID(clientID);
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerDelete", client, buff);
		CPrintToChat(client, print_buff);
	}
	else
	{
		clientID = GetClientIDinDBbySteam(buff);
		if(clientID != -1)
		{
			GetClientNameByID(clientID, targetName, sizeof(targetName));
			int clanid = GetClientClanByID(clientID);
			GetClanName(clanid, clanName, sizeof(clanName));
			if(CheckForLog(LOG_CLIENTACTION))
			{
				char log_buff[LOG_SIZE];
				GetClientNameByID(clientID, targetName, sizeof(targetName));
				FormatEx(log_buff, sizeof(log_buff), "%T", "LA_DeletePlayer", LANG_SERVER, targetName, clanName);
				DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, clientID, true, clanid, LOG_CLIENTACTION);
			}
			DeleteClientByID(clientID);
			IntToString(clientID, buff, sizeof(buff));
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerDelete", client, buff);
			CPrintToChat(client, print_buff);
		}
		else
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerSteamDoesntExist", client);
			CPrintToChat(client, print_buff);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

/**
 * Delete clan by it's id by admin command
 * 
 * @param args 1 - clan id
 */
public Action Command_AdminDeleteClan(int client, int args)
{
	char print_buff[BUFF_SIZE];
	if(args != 1)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_Wrongadclan", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	char buff[33];
	int clanid;
	GetCmdArg(1, buff, sizeof(buff));
	clanid = StringToInt(buff);
	if(!IsClanValid(clanid))
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanDoesntExist", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	if(CheckForLog(LOG_CLANACTION))
	{
		char log_buff[LOG_SIZE],
			 clanName[MAX_CLAN_NAME+1];
		GetClanName(clanid, clanName, sizeof(clanName));
		FormatEx(log_buff, sizeof(log_buff), "%T", "L_DeleteClan", LANG_SERVER, clanName);
		DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_CLANACTION);
	}
	DeleteClan(clanid);
	FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanDelete", client, clanid);
	CPrintToChat(client, print_buff);
	return Plugin_Handled;
}

/**
 * Throws admin menu to client
 */
public Action Command_AdminClansMenu(int client, int args)
{
	ThrowAdminMenu(client);
	return Plugin_Handled;
}

/**
 * Set number of coins in clan
 */
public Action Command_AdminSetCoins(int client, int args)
{
	char print_buff[BUFF_SIZE];
	if(args != 2)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_Wrongasetcoins", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	char buff[33],
		 clanName[MAX_CLAN_NAME+1];
	int clanid, coins;
	int type = 1; //0 - take, 1 - set, 2 - give
	GetCmdArg(1, buff, sizeof(buff));
	clanid = StringToInt(buff);
	if(!IsClanValid(clanid))
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanDoesntExist", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	GetClanName(clanid, clanName, sizeof(clanName));
	GetCmdArg(2, buff, sizeof(buff));
	if(buff[0] == '+')
		type = 2;
	else if(buff[0] == '-')
		type = 0;
	ReplaceString(buff, sizeof(buff), "+", "");
	ReplaceString(buff, sizeof(buff), "-", "");
	coins = StringToInt(buff);
	if(type == 0)
	{
		SetClanCoins(clanid, GetClanCoins(clanid) - coins);
		if(CheckForLog(LOG_COINS))
		{
			char log_buff[LOG_SIZE];
			FormatEx(log_buff, sizeof(log_buff), "%T", "L_TakeCoins", LANG_SERVER, coins, clanName);
			DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_COINS);
		}
	}
	else if(type == 1)
	{
		SetClanCoins(clanid, coins);
		if(CheckForLog(LOG_COINS))
		{
			char log_buff[LOG_SIZE];
			FormatEx(log_buff, sizeof(log_buff), "%T", "L_SetCoins", LANG_SERVER, coins, clanName);
			DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_COINS);
		}
	}
	else
	{
		SetClanCoins(clanid, GetClanCoins(clanid) + coins);
		if(CheckForLog(LOG_COINS))
		{
			char log_buff[LOG_SIZE];
			FormatEx(log_buff, sizeof(log_buff), "%T", "L_GiveCoins", LANG_SERVER, coins, clanName);
			DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_COINS);
		}
	}
	FormatEx(print_buff, sizeof(print_buff), "%T", "c_CoinsNow", client, clanName, GetClanCoins(clanid));
	CPrintToChat(client, print_buff);
	return Plugin_Handled;
}

/**
 * Reset clan by its id
 */
public Action Command_AdminResetClan(int client, int args)
{
	char print_buff[BUFF_SIZE];
	if(args != 1)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_Wrongarclan", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	char buff[33],
		 clanName[MAX_CLAN_NAME+1];
	int clanid;
	GetCmdArg(1, buff, sizeof(buff));
	clanid = StringToInt(buff);
	if(!IsClanValid(clanid))
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanDoesntExist", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	if(ResetClan(clanid))
	{
		GetClanName(clanid, clanName, sizeof(clanName));
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanReset", client, clanName);
		CPrintToChat(client, print_buff);
		if(CheckForLog(LOG_CLANACTION))
		{
			char log_buff[LOG_SIZE];
			FormatEx(log_buff, sizeof(log_buff), "%T", "L_ResetClan", LANG_SERVER, clanName);
			DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_CLANACTION);
		}
	}
	return Plugin_Handled;
}

/**
 * Reset client by id in database or by steam id
 */
public Action Command_AdminResetClient(int client, int args)
{
	char print_buff[BUFF_SIZE];
	if(args != 1)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_Wrongarclient", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	char buff[33],
		 targetName[MAX_NAME_LENGTH+1];
	int clientID;
	GetCmdArg(1, buff, sizeof(buff));
	if(IsCharNumeric(buff[0]))
	{
		clientID = StringToInt(buff);
		GetClientNameByID(clientID, targetName, sizeof(targetName));
		ResetClient(clientID);
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerReset", client, targetName);
		CPrintToChat(client, print_buff);
		if(CheckForLog(LOG_CLANACTION))
		{
			char log_buff[LOG_SIZE];
			FormatEx(log_buff, sizeof(log_buff), "%T", "L_ResetPlayer", LANG_SERVER, targetName);
			DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, clientID, true, GetClientClanByID(clientID), LOG_CLANACTION);
		}
	}
	else
	{
		clientID = GetClientIDinDBbySteam(buff);
		if(clientID != -1)
		{
			GetClientNameByID(clientID, targetName, sizeof(targetName));
			ResetClient(clientID);
			if(CheckForLog(LOG_CLANACTION))
			{
				char log_buff[LOG_SIZE];
				FormatEx(log_buff, sizeof(log_buff), "%T", "L_ResetPlayer", LANG_SERVER, targetName);
				DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, clientID, true, GetClientClanByID(clientID), LOG_CLANACTION);
			}
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerReset", client, g_sClientData[clientID][CLIENT_NAME]);
			CPrintToChat(client, print_buff);
		}
		else
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerSteamDoesntExist", client);
			CPrintToChat(client, print_buff);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}