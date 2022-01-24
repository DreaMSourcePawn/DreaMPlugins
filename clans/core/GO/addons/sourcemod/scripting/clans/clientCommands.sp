void RegClientCommands()
{
	RegConsoleCmd("sm_cclan", Command_CreateClan);
	RegConsoleCmd("sm_leaveclan", Command_LeaveClan);
	RegConsoleCmd("sm_myclan", Command_MyClan);
	RegConsoleCmd("sm_mcl", Command_MyClan);
	RegConsoleCmd("sm_clan", Command_MyClan);
	RegConsoleCmd("sm_invite", Command_Invite);
	RegConsoleCmd("sm_caccept", Command_AcceptClanInvitation);
	RegConsoleCmd("sm_ctop", Command_TopClans);
	RegConsoleCmd("sm_mystats", Command_MyStats);
	RegConsoleCmd("sm_chelp", Command_ClanHelp);
	RegConsoleCmd("sm_cchat", Command_ClanChat);
	RegConsoleCmd("sm_cct", Command_ClanChat);
	RegConsoleCmd("sm_jclan", Command_JoinClan);
}

Action Command_CreateClan(int client, int args)
{
	char print_buff[BUFF_SIZE], buff[50];
	if(!createClan[client])
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_YouCantCreateClan", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	int timeOfCD = GetTime() - GetLastClanCreationTime(client);	//1.7
	if(g_iClanCreationCD-timeOfCD/60 > 0)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_YouCantCreateClanDueToCD", client, g_iClanCreationCD-timeOfCD/60);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	if(GetClientClanByID(ClanClient) != -1)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_YouAreAlreadyInClan", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	char clanName[MAX_CLAN_NAME+1];
	if(args != 1)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_Wrongcclan", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	GetCmdArg(1, buff, sizeof(buff));
	TrimString(buff);
	
	if(strlen(buff) < 1 || strlen(buff) > MAX_CLAN_NAME)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_WrongClanName", client, MAX_CLAN_NAME);
		CPrintToChat(client, print_buff);
		admin_SelectMode[client][0] = -1;
		admin_SelectMode[client][1] = -1;
		return Plugin_Handled;
	}
	else
	{
		for(int i = 0; i < MAX_CLAN_NAME; i++)
			clanName[i] = buff[i];
		clanName[MAX_CLAN_NAME] = '\0';
	}
	
	CreateClan(client, clanName);
	return Plugin_Handled;
}

public Action Command_LeaveClan(int client, int args)
{
	char print_buff[BUFF_SIZE];
	int clanid = GetClientClanByID(ClanClient);
	if(clanid == -1)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_YouAreNotInClan", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	if(CheckForLog(LOG_CLIENTACTION))
	{
		char log_buff[LOG_SIZE],
			 clanName[MAX_CLAN_NAME+1];
		GetClanName(clanid, clanName, sizeof(clanName));
		FormatEx(log_buff, sizeof(log_buff), "%T", "L_LeaveClan", LANG_SERVER, clanName);
		DB_LogAction(ClanClient, true, clanid, log_buff, -1, true, clanid, LOG_CLIENTACTION);
	}
	DeleteClientByID(ClanClient);
	FormatEx(print_buff, sizeof(print_buff), "%T", "c_LeftClan", client);
	CPrintToChat(client, print_buff);
	return Plugin_Handled;
}

public Action Command_MyClan(int client, int args)
{
	ClearPlayerMenuBuffer(client);
	ThrowClanMenuToClient(client);
	return Plugin_Handled;
}

public Action Command_MyStats(int client, int args)
{
	ClearPlayerMenuBuffer(client);
	int clanid = GetClientClanByID(ClanClient);
	if(clanid != -1)
		ThrowPlayerStatsToClient(client, ClanClient);
	else
	{
		char print_buff[BUFF_SIZE];
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_YouAreNotInClan", client);
		CPrintToChat(client, print_buff);
	}
	return Plugin_Handled;
}

public Action Command_AcceptClanInvitation(int client, int args)
{
	char buff[BUFF_SIZE];
	if(invitedBy[client][0] == -1 || GetTime()-invitedBy[client][1] > MAX_INVITATION_TIME)
	{
		FormatEx(buff, sizeof(buff), "%T", "c_NotInvited", client);
		CPrintToChat(client, buff);
		return Plugin_Handled;
	}
	int whoInvited = invitedBy[client][0];
	int invitingClan = GetClientClanByID(playerID[whoInvited]);
	SetOnlineClientClan(client, invitingClan, CLIENT_MEMBER);
	FormatEx(buff, sizeof(buff), "%T", "c_JoinSuccess", client);
	CPrintToChat(client, buff);
	if(CheckForLog(LOG_CLIENTACTION))
	{
		char log_buff[LOG_SIZE],
			 clanName[MAX_CLAN_NAME+1];
		GetClanName(invitingClan, clanName, sizeof(clanName));
		FormatEx(log_buff, sizeof(log_buff), "%T", "L_CreatePlayer", LANG_SERVER, clanName);
		DB_LogAction(ClanClient, true, GetClientClanByID(ClanClient), log_buff, -1, true, invitingClan, LOG_CLIENTACTION);
	}
	invitedBy[client][0] = -1;
	return Plugin_Handled;
}

public Action Command_Invite(int client, int args)
{
	int clanid = GetClientClanByID(ClanClient);
	if(!CanPlayerDo(ClanClient, PERM_INVITE))
	{
		char print_buff[BUFF_SIZE];
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_CantInvite", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	if(GetClanMembers(clanid) >= GetClanMaxMembers(clanid))
	{
		char print_buff[BUFF_SIZE];
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_MaxMembersInClan", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	ClearPlayerMenuBuffer(client);
	ThrowInviteList(client);
	return Plugin_Handled;
}

public Action Command_TopClans(int client, int args)
{
	ClearPlayerMenuBuffer(client);
	ThrowTopsMenuToClient(client);
	return Plugin_Handled;
}

public Action Command_ClanHelp(int client, int args)
{
	ThrowClanHelp(client);
	return Plugin_Handled;
}

public Action Command_AdminClanHelp(int client, int args)
{
	Handle helpPanel = CreatePanel();
	char helpText[500];
	FormatEx(helpText, sizeof(helpText), "%T", "m_AdminClanHelp", client);
	SetPanelTitle(helpPanel, helpText);
	FormatEx(helpText, sizeof(helpText), "%T", "m_AdminClanHelpCmds", client);
	DrawPanelText(helpPanel, helpText);
	FormatEx(helpText, sizeof(helpText), "%T", "m_Close", client);
	DrawPanelItem(helpPanel, helpText, 0);
	SendPanelToClient(helpPanel, client, Clan_HelpMenu, 0);
	return Plugin_Handled;
}

bool CanSeeMessageInClanChat(bool senderAlive, int senderTeam, int client)
{
	if(!IsClientInGame(client))
		return false;
	if(g_iClanChatFilter & 1 == 0 && senderAlive^IsPlayerAlive(client) != false)
		return false;
	int clientTeam = GetClientTeam(client);
	if(g_iClanChatFilter & 2 == 0 && senderTeam != clientTeam)
		return false;
	return true;
}

public Action Command_ClanChat(int client, int args)
{
	char buff[BUFF_SIZE], 
		 userName[MAX_NAME_LENGTH+1], 
		 clanName[MAX_CLAN_NAME],
		 print_buff[350];
	if(ClanClient == -1)
	{
		FormatEx(buff, sizeof(buff), "%T", "c_YouAreNotInClan", client);
		CPrintToChat(client, buff);
		return Plugin_Handled;
	}
	int clanid = GetClientClanByID(ClanClient);
	int role = GetClientRoleByID(ClanClient);
	GetClanName(clanid, clanName, sizeof(clanName));
	GetCmdArgString(buff, sizeof(buff));
	if(strlen(buff) < 1)
		return Plugin_Handled;
	GetClientName(client, userName, sizeof(userName));
	if(!g_bCSS34)
	{
		if(role == CLIENT_MEMBER)
			FormatEx(print_buff, sizeof(print_buff), "{%s}[%s] %s:{default} %s", g_cCCMember, g_sClientData[client][CLIENT_CLANNAME], userName, buff);
		else if(role == CLIENT_ELDER)
			FormatEx(print_buff, sizeof(print_buff), "{%s}[%s] %s:{default} %s", g_cCCElder, g_sClientData[client][CLIENT_CLANNAME], userName, buff);
		else if(role == CLIENT_COLEADER)
			FormatEx(print_buff, sizeof(print_buff), "{%s}[%s] %s:{lightgreen} %s", g_cCCColeader, g_sClientData[client][CLIENT_CLANNAME], userName, buff);
		else
			FormatEx(print_buff, sizeof(print_buff), "{%s}[%s] %s:{lightgreen} %s", g_cCCLeader, g_sClientData[client][CLIENT_CLANNAME], userName, buff);
	}
	
	bool clientAlive = IsPlayerAlive(client);
	int clientTeam = GetClientTeam(client);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(CanSeeMessageInClanChat(clientAlive, clientTeam, i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], clanName))
		{
			if(!g_bCSS34)
				CPrintToChat(i, print_buff);
			else
				CPrintToChat(i, "{green}[%s] %s: {lightgreen}%s", clanName, userName, buff);
		}
	}
	if(CheckForLog(LOG_CLANCHAT))
	{
		char log_buff[LOG_SIZE];
		FormatEx(log_buff, sizeof(log_buff), "%T", "L_ClanChat", LANG_SERVER, buff);
		DB_LogAction(ClanClient, true, clanid, log_buff, -1, true, -1, LOG_CLANCHAT);
	}
	return Plugin_Handled;
}

Action Command_JoinClan(int client, int args)
{
	char print_buff[BUFF_SIZE];
	if(args != 1)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_Wrongjclan", client);
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	if(ClanClient != -1)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_YouAreAlreadyInClan", client)
		CPrintToChat(client, print_buff);
		return Plugin_Handled;
	}
	int clanid, type;
	char buff[50];
	GetCmdArg(1, buff, sizeof(buff));
	TrimString(buff);
	clanid = StringToInt(buff);
	if(IsClanValid(clanid))
	{
		type = GetClanType(clanid);
		if(type == 0)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_JoinClosedClan", client)
			CPrintToChat(client, print_buff);
			return Plugin_Handled;
		}
		if(GetClanMembers(clanid) >= GetClanMaxMembers(clanid))
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_MaxMembersInClan", client)
			CPrintToChat(client, print_buff);
			return Plugin_Handled;
		}
		SetOnlineClientClan(client, clanid, 0);
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_JoinSuccess", client)
		CPrintToChat(client, print_buff);
		if(CheckForLog(LOG_CLIENTACTION))
		{
			char log_buff[LOG_SIZE],
				 clanName[MAX_CLAN_NAME+1];
			GetClanName(clanid, clanName, sizeof(clanName));
			FormatEx(log_buff, sizeof(log_buff), "%T", "L_CreatePlayer", LANG_SERVER, clanName);
			DB_LogAction(ClanClient, true, clanid, log_buff, -1, true, -1, LOG_CLIENTACTION);
		}
	}
	return Plugin_Handled;
}