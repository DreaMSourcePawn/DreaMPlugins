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
		if(client)
			ColorPrintToChat(client, print_buff);
		else
			PrintToServer("[CLANS] Incorrectly entered command! Tip: !ptoclan [userid in status] [clan id] [4 - leader, 2 - co-leader, 1 - elder, 0 - member]!");
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
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_WrongRoleFlag", client);
			ColorPrintToChat(client, print_buff);
		}
		else
			PrintToServer("[CLANS] Wrong role flag inputted!");
		return Plugin_Handled;
	}
	if(GetClanMembers(clanid) < 1)
	{
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanDoesntExist", client);
			ColorPrintToChat(client, print_buff);
		}
		else
			PrintToServer("[CLANS] Clan doesn't exist!");
		return Plugin_Handled;
	}
	if(!target || !IsClientAuthorized(target))
	{
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerIsntAuth", client);
			ColorPrintToChat(client, print_buff);
		}
		else
			PrintToServer("[CLANS] Player isn't authorized!");
		return Plugin_Handled;
	}
	if(GetClientClanByID(GetClientIDinDB(target)) == clanid)
	{
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerInThisClan", client);
			ColorPrintToChat(client, print_buff);
		}
		else
			PrintToServer("[CLANS] Player is already in this clan!");
		return Plugin_Handled;
	}
	SetOnlineClientClan(target, clanid, roleFlag);
	if(client)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerAddedToClan", client, clanName);
		ColorPrintToChat(client, print_buff);
	}
	else
		PrintToServer("[CLANS] Player was added to clan %s", clanName);
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
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_WrongPOutOfClan", client);
			ColorPrintToChat(client, print_buff);
		}
		else
			PrintToServer("[CLANS] Incorrectly entered command! Tip: !poutofclan [player ID in database or his steam]");
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
			if(client)
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerIDDoesntExist", client);
				ColorPrintToChat(client, print_buff);
			}
			else
				PrintToServer("[CLANS] Player with this ID wasn't found!");
			return Plugin_Handled;
		}
		GetClientNameByID(clientID, targetName, sizeof(targetName));
		int clanid = GetClientClanByID(clientID);
		GetClanName(clanid, clanName, sizeof(clanName));
		/*if(g_iClientData[clientID][CLIENT_CLANID] == -1)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerIDDoesntExist", client);
			ColorPrintToChat(client, print_buff);
			return Plugin_Handled;
		}*/
		if(CheckForLog(LOG_CLIENTACTION))
		{
			char log_buff[LOG_SIZE];
			FormatEx(log_buff, sizeof(log_buff), "%T", "LA_DeletePlayer", LANG_SERVER, targetName, clanName);
			DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, clientID, true, clanid, LOG_CLIENTACTION);
		}
		DeleteClientByID(clientID);
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerDelete", client, targetName);
			ColorPrintToChat(client, print_buff);
		}
		else
		{
			PrintToServer("[CLANS] Player %s was deleted!", targetName);
		}
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
			if(client)
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerDelete", client, targetName);
				ColorPrintToChat(client, print_buff);
			}
			else
			{
				PrintToServer("[CLANS] Player %s was deleted!", targetName);
			}
		}
		else
		{
			if(client)
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerSteamDoesntExist", client);
				ColorPrintToChat(client, print_buff);
			}
			else
				PrintToServer("[CLANS] Player with this Steam ID wasn't found!");
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
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_Wrongadclan", client);
			ColorPrintToChat(client, print_buff);
		}
		else
			PrintToServer("[CLANS] Incorrectly entered command! Tip: !adclan [clan id]");
		return Plugin_Handled;
	}
	char buff[33];
	int clanid;
	GetCmdArg(1, buff, sizeof(buff));
	clanid = StringToInt(buff);
	if(!IsClanValid(clanid))
	{
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanDoesntExist", client);
			ColorPrintToChat(client, print_buff);
		}
		else
			PrintToServer("[CLANS] Clan doesn't exist!");
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
	if(client)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanDelete", client, clanid);
		ColorPrintToChat(client, print_buff);
	}
	else
		PrintToServer("[CLANS] Clan with id %d was deleted", clanid);
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
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_Wrongasetcoins", client);
			ColorPrintToChat(client, print_buff);
		}
		else
			PrintToServer("[CLANS] Incorrectly entered command! Tip: !asetcoins [clan id] [amount of coins]");
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
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanDoesntExist", client);
			ColorPrintToChat(client, print_buff);
		}
		else
			PrintToServer("[CLANS] Clan doesn't exist!");
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
		int takenCoins = coins;
		coins = GetClanCoins(clanid) - coins;
		SetClanCoins(clanid, coins);
		if(CheckForLog(LOG_COINS))
		{
			char log_buff[LOG_SIZE];
			FormatEx(log_buff, sizeof(log_buff), "%T", "L_TakeCoins", LANG_SERVER, takenCoins, clanName);
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
		int givenCoins = coins;
		coins += GetClanCoins(clanid);
		SetClanCoins(clanid, coins);
		if(CheckForLog(LOG_COINS))
		{
			char log_buff[LOG_SIZE];
			FormatEx(log_buff, sizeof(log_buff), "%T", "L_GiveCoins", LANG_SERVER, givenCoins, clanName);
			DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_COINS);
		}
	}
	if(client)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_CoinsNow", client, clanName, coins);
		ColorPrintToChat(client, print_buff);
	}
	else
		PrintToServer("[CLANS] Clan %s has %d coins now", clanName, coins);
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
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_Wrongarclan", client);
			ColorPrintToChat(client, print_buff);
		}
		else
			PrintToServer("[CLANS] Incorrectly entered command! Tip: !arclan [clan id]");
		return Plugin_Handled;
	}
	char buff[33],
		 clanName[MAX_CLAN_NAME+1];
	int clanid;
	GetCmdArg(1, buff, sizeof(buff));
	clanid = StringToInt(buff);
	if(!IsClanValid(clanid))
	{
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanDoesntExist", client);
			ColorPrintToChat(client, print_buff);
		}
		else
			PrintToServer("[CLANS] Clan doesn't exist!");
		return Plugin_Handled;
	}
	if(ResetClan(clanid))
	{
		GetClanName(clanid, clanName, sizeof(clanName));
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanReset", client, clanName);
			ColorPrintToChat(client, print_buff);
		}
		else
			PrintToServer("[CLANS] Clan %s was reseted", clanName);

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
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_Wrongarclient", client);
			ColorPrintToChat(client, print_buff);
		}
		else
			PrintToServer("[CLANS] Incorrectly entered command! Tip: !arclient [player id in database or his SteamID]");
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
		if(client)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerReset", client, targetName);
			ColorPrintToChat(client, print_buff);
		}
		else
			PrintToServer("[CLANS] Player %s was reseted", targetName);

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
			if(client)
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerReset", client, targetName);
				ColorPrintToChat(client, print_buff);
			}
			else
			{
				PrintToServer("[CLANS] Player %s was reseted", targetName);
			}
		}
		else
		{
			if(client)
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerSteamDoesntExist", client);
				ColorPrintToChat(client, print_buff);
			}
			else
				PrintToServer("[CLANS] Player with this Steam ID wasn't found!");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}