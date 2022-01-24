#include "clans/menus_enum.sp"

//ArrayStack g_asClientLastMenu[MAXPLAYERS+1] = {null, null, ...};	//v1.86 stack of Functions
ArrayStack g_asClientLastMenu[MAXPLAYERS+1] = {null, null, ...};	//v1.86 stack of Functions's id (see menus_defines)
ArrayStack g_asMClientBuffer[MAXPLAYERS+1] = {null, null, ...};		//v1.86 stack of params

/**
 * Clears player's buffer (v1.86)
 *
 * @param int iClient - client's index
 */
void ClearPlayerMenuBuffer(int iClient)
{
	if(g_asClientLastMenu[iClient] == null)
	{
		g_asClientLastMenu[iClient] = CreateStack();
	}
	else
	{
		while(!g_asClientLastMenu[iClient].Empty)
			g_asClientLastMenu[iClient].Pop();
	}
	
	if(g_asMClientBuffer[iClient] == null)
	{
		g_asMClientBuffer[iClient] = CreateStack();
	}
	else
	{
		while(!g_asMClientBuffer[iClient].Empty)
			g_asMClientBuffer[iClient].Pop();
	}
}

//=============================== MENUS HANDLERS ===============================//
/**
 * Calls when player selects any option in Invite Menu
 */
int Clan_InvitePlayerSelectMenu(Handle inviteSelectMenu, MenuAction action, int client, int option)
{
	if (action == MenuAction_Select)
	{
		char 	print_buff[BUFF_SIZE], 		//Вывод в чат
				userid[15],					//Айди юзера
				clanName[MAX_CLAN_NAME+1];	//Имя клана
		userid[0] = '\0';
		GetClanName(GetClientClanByID(ClanClient), clanName, sizeof(clanName));
		GetMenuItem(inviteSelectMenu, option, userid, 15); 
		int target = GetClientOfUserId(StringToInt(userid)); 
		invitedBy[target][0] = client;
		invitedBy[target][1] = GetTime();
		MenuSource checkForMenus = GetClientMenu(target, INVALID_HANDLE);
		if(checkForMenus == MenuSource_None)	//target isn't viewing any menu
		{
			Handle inviteMenu = CreateMenu(Clans_InviteAcceptMenu);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_InvitedToClan", target, clanName);
			SetMenuTitle(inviteMenu, print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_Yes", target);
			AddMenuItem(inviteMenu, "Yes", print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_No", target);
			AddMenuItem(inviteMenu, "No", print_buff);
			SetMenuExitButton(inviteMenu, true);
			DisplayMenu(inviteMenu, target, 0);
		}
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_YouAreInvited", client, clanName);
		CPrintToChat(target, print_buff);
	}
	else if (action == MenuAction_End && action == MenuAction_Cancel)
	{
		CloseHandle(inviteSelectMenu);
	}
}

/**
 * Calls when player select any option in Clan Menu
 */
int Clan_PlayerClanSelectMenu(Handle playerClanMenu, MenuAction action, int client, int option)
{
	if (action == MenuAction_Select)
	{
		F_OnClanMenuSelected(playerClanMenu, client, option);
		char selectedItem[50], print_buff[BUFF_SIZE];
		int buff;
		GetMenuItem(playerClanMenu, option, selectedItem, sizeof(selectedItem), buff, "", 0);
		if(!strcmp(selectedItem, "AdminMenu"))
		{
			ThrowAdminMenu(client);
		}
		if(!strcmp(selectedItem, "ClanControl"))
		{
			ThrowClanControlMenu(client);
		}
		else if(!strcmp(selectedItem, "ClanStats"))
		{
			ThrowClanStatsToClient(client, GetClientClanByID(ClanClient));
		}
		else if(!strcmp(selectedItem, "PlayerStats"))
		{
			ThrowPlayerStatsToClient(client, ClanClient);
		}
		else if(!strcmp(selectedItem, "Members"))
		{
			CLAN_STYPE = 0;
			if(!ThrowClanMembersToClient(client, GetClientClanByID(ClanClient), 1))
				ThrowClanMenuToClient(client);
		}
		else if(!strcmp(selectedItem, "TopClans"))
		{
			ThrowTopsMenuToClient(client);
		}
		else if(!strcmp(selectedItem, "LeaveClan"))
		{
			Handle leaveClanMenu = CreateMenu(Clan_LeaveClanSelectMenu);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_SureLeaving", client);
			SetMenuTitle(leaveClanMenu, print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_Yes", client);
			AddMenuItem(leaveClanMenu, "Yes", print_buff);
			SetMenuExitButton(leaveClanMenu, true);
			DisplayMenu(leaveClanMenu, client, 0);
		}
		else if(!strcmp(selectedItem, "ClanCreate")) //1.7
		{
			if(!createClan[client])
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_YouCantCreateClan", client);
				CPrintToChat(client, print_buff);
				return;
			}
			int timeOfCD = GetTime() - GetLastClanCreationTime(client); //1.7
			if(g_iClanCreationCD-timeOfCD/60 > 0)
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_YouCantCreateClanDueToCD", client, g_iClanCreationCD-timeOfCD/60);
				CPrintToChat(client, print_buff);
			}
			else
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_EnterClanName", client);
				CPrintToChat(client, print_buff);
				creatingClan[client] = true;
			}
		}
		else if(!strcmp(selectedItem, "ClanChatWrite"))	//1.7
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanChatWrite", client);
			CPrintToChat(client, print_buff);
			writeToClanChat[client] = true;
		}
		else if(!strcmp(selectedItem, "ClanTagSet")) //1.7
		{
			ThrowClanTagSettings(client);
		}
		else if(!strcmp(selectedItem, "ClanHelp")) //1.7
		{
			ThrowClanHelp(client);
		}
	}
	else if (action == MenuAction_End && action == MenuAction_Cancel)
		CloseHandle(playerClanMenu);
}

/**
 * Calls when player closes his/her stats
 */
int Clan_PlayerStatsMenu(Handle playerStatsMenu, MenuAction action, int client, int option)
{
	CloseHandle(playerStatsMenu);
	/*if(ClanClient == -1)
		ThrowTopsMenuToClient(client);
	else
		ThrowClanMenuToClient(client);*/
	ThrowLastMenu(client);	//v1.86
}

/**
 * Calls when player select a menu item in clan stats
 */
int Clan_ClanStatsMenu(Handle clanStatsMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		int clanid = CLAN_STARGET;
		char print_buff[BUFF_SIZE];
		if(option == 1)
		{
			CLAN_STYPE = 0;
			ThrowClanMembersToClient(client, clanid, 1);
		}
		else if(option == 2)	//Join or Close
		{
			if(GetClanType(clanid) == 1 && ClanClient == -1)
			{
				if(GetClanMembers(clanid) >= GetClanMaxMembers(clanid))
				{
					FormatEx(print_buff, sizeof(print_buff), "%T", "c_MaxMembersInClan", client)
					CPrintToChat(client, print_buff);
					CLAN_STYPE = -1;
					CLAN_STARGET = -1;
					//ThrowClanStatsToClient(client, clanid);
					ThrowLastMenu(client, true);	//v1.86
				}
				else
				{
					if(CheckForLog(LOG_CLIENTACTION))
					{
						char 	log_buff[LOG_SIZE],
								clanName[MAX_CLAN_NAME+1];
						GetClanName(clanid, clanName, sizeof(clanName));
						FormatEx(log_buff, sizeof(log_buff), "%T", "L_CreatePlayer", LANG_SERVER, clanName);
						DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_CLIENTACTION);
					}
					SetOnlineClientClan(client, clanid, 0);
					FormatEx(print_buff, sizeof(print_buff), "%T", "c_JoinSuccess", client)
					CPrintToChat(client, print_buff);
					CLAN_STYPE = -1;
					CLAN_STARGET = -1;
				}
			}
			else
			{
				//ThrowClanMenuToClient(client);
				ThrowLastMenu(client);	//v1.86
				CLAN_STYPE = -1;
				CLAN_STARGET = -1;
			}
		}
		else	//Close
		{
			CLAN_STYPE = -1;
			CLAN_STARGET = -1;
			//ThrowTopsMenuToClient(client);
			ThrowLastMenu(client);	//v1.86
		}
	}
	else
	{
		CloseHandle(clanStatsMenu);
		//ThrowClanMenuToClient(client);
		ThrowLastMenu(client);	//v1.86
	}
}

/**
 * Player's dicision to leave the clan or not
 */
int Clan_LeaveClanSelectMenu(Handle leaveClanMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		if(CheckForLog(LOG_CLIENTACTION))
		{
			char 	log_buff[LOG_SIZE],
					clanName[MAX_CLAN_NAME+1];
			GetClanName(GetClientClanByID(ClanClient), clanName, sizeof(clanName));
			FormatEx(log_buff, sizeof(log_buff), "%T", "L_LeaveClan", LANG_SERVER, clanName);
			DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, GetClientClanByID(ClanClient), LOG_CLIENTACTION);
		}
		DeleteClientByID(ClanClient);
		char print_buff[BUFF_SIZE];
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_LeavingSuccess", client);
		CPrintToChat(client, print_buff);
	}
	else if (action == MenuAction_End)
		CloseHandle(leaveClanMenu);
}

/**
 * Action in members menu, which shows clan members' stats
 */
int Clan_ClanMembersSelectMenu(Handle clanMembersMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char auth[33], print_buff[BUFF_SIZE];
		int buff;
		if(ADMIN_STYPE == 6)	//change leader
		{
			char userName[MAX_NAME_LENGTH+20];
			GetMenuItem(clanMembersMenu, option, auth, sizeof(auth), buff, userName, sizeof(userName));
			ReplaceString(userName, sizeof(userName), " (leader)", "");
			ADMIN_STARGET = GetClientIDinDBbySteam(auth);
			Handle kickMenu = CreateMenu(Clan_LeaderSelectMenu);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_ChooseNewLeader", client);
			SetMenuTitle(kickMenu, print_buff);
			AddMenuItem(kickMenu, "Yes", userName);
			SetMenuExitButton(kickMenu, true);
			DisplayMenu(kickMenu, client, 0);
		}
		
		else if(CLAN_STYPE == 0)	//See stats
		{
			GetMenuItem(clanMembersMenu, option, auth, sizeof(auth), buff, "", 0);
			ThrowPlayerStatsToClient(client, GetClientIDinDBbySteam(auth));
		}
			
		else if(CLAN_STYPE == 1)	//Kick 
		{
			char userName[MAX_NAME_LENGTH+20];
			GetMenuItem(clanMembersMenu, option, auth, sizeof(auth), buff, userName, sizeof(userName));
			ReplaceString(userName, sizeof(userName), " (leader)", "");
			CLAN_STARGET = GetClientIDinDBbySteam(auth);
			Handle kickMenu = CreateMenu(Clan_KickSelectMenu);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_KickPlayerByNick", client);
			SetMenuTitle(kickMenu, print_buff);
			AddMenuItem(kickMenu, "Yes", userName);
			SetMenuExitButton(kickMenu, true);
			DisplayMenu(kickMenu, client, 0);
		}
		
		else if(CLAN_STYPE == 2)	//select new leader
		{
			char userName[MAX_NAME_LENGTH+20];
			GetMenuItem(clanMembersMenu, option, auth, sizeof(auth), buff, userName, sizeof(userName));
			ReplaceString(userName, sizeof(userName), " (leader)", "");
			CLAN_STARGET = GetClientIDinDBbySteam(auth);
			Handle kickMenu = CreateMenu(Clan_LeaderSelectMenu);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_ChooseNewLeader", client);
			SetMenuTitle(kickMenu, print_buff);
			AddMenuItem(kickMenu, "Yes", userName);
			SetMenuExitButton(kickMenu, true);
			DisplayMenu(kickMenu, client, 0);
		}

		else if(CLAN_STYPE == 4 || ADMIN_STYPE == 10)	//change role
		{
			char userName[MAX_NAME_LENGTH+20];
			GetMenuItem(clanMembersMenu, option, auth, sizeof(auth), buff, userName, sizeof(userName));
			ReplaceString(userName, sizeof(userName), " (leader)", "");
			CLAN_STARGET = GetClientIDinDBbySteam(auth);
			ThrowChangeRoleMenu(client, CLAN_STARGET);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(clanMembersMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		/*if(ADMIN_STYPE == 10 || ADMIN_STYPE == 6)	//Смена роли/лидера админом
			ThrowClansToClient(client, true);
		else if(CLAN_STYPE == 4)	//Смена роли игроком из клана
			ThrowClanControlMenu(client);
		else if(CLAN_STARGET != -1 && CLAN_STYPE != -1)
			ThrowClanStatsToClient(client, CLAN_STARGET);
		else
			ThrowClanMenuToClient(client);*/
		ThrowLastMenu(client);	//v1.86
	}
}

/**
 * Actions in clan control menu
 */
int Clan_ClanControlSelectMenu(Handle clanControlMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char selectedItem[50], print_buff[BUFF_SIZE];
		int buff;
		int clientClan = GetClientClanByID(ClanClient);
		GetMenuItem(clanControlMenu, option, selectedItem, sizeof(selectedItem), buff, "", 0);
		if(!strcmp(selectedItem, "Expand"))
		{
			Handle expandClanPanel = CreatePanel();
			char info[150];
			int clanCoins = GetClanCoins(clientClan);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_BuySlots", client, g_iExpandValue, g_iExpandingCost, clanCoins);
			Format(info, sizeof(info), print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_BuySlotsSure", client);
			SetPanelTitle(expandClanPanel, print_buff);
			DrawPanelText(expandClanPanel, info);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_Yes", client);
			DrawPanelItem(expandClanPanel, print_buff, 0);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_No", client);
			DrawPanelItem(expandClanPanel, print_buff, 0);
			SendPanelToClient(expandClanPanel, client, Clan_ExpandClanSelectPanel, 0);
		}
		else if(!strcmp(selectedItem, "TransferCoins"))
		{
			CLAN_STYPE = 3;
			ThrowClansToClient(client, false);
		}
		else if(!strcmp(selectedItem, "Invite"))
		{
			int clanMembers = GetClanMembers(clientClan);
			int clanMaxMembers = GetClanMaxMembers(clientClan);
			if(clanMembers < clanMaxMembers)
			{
				ThrowInviteList(client);	//v1.86
			}
			else
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_MaxMembersInClan", client);
				CPrintToChat(client, print_buff);
				//ThrowClanControlMenu(client);
				ThrowLastMenu(client, true);	//v1.86
			}
		}
		else if(!strcmp(selectedItem, "Kick"))
		{
			CLAN_STYPE = 1;
			ThrowClanMembersToClient(client, clientClan, 4);
		}
		else if(!strcmp(selectedItem, "SelectLeader"))
		{
			CLAN_STYPE = 2;
			ThrowClanMembersToClient(client, clientClan, 0);
		}
		else if(!strcmp(selectedItem, "DeleteClan"))
		{
			Handle deleteClanMenu = CreateMenu(Clan_DeleteClanSelectMenu);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_DisbandSure", client);
			SetMenuTitle(deleteClanMenu, print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_Yes", client);
			AddMenuItem(deleteClanMenu, "Yes", print_buff);
			SetMenuExitButton(deleteClanMenu, true);
			DisplayMenu(deleteClanMenu, client, 0);
		}
		else if(!strcmp(selectedItem, "RenameClan"))
		{
			if(g_iRenameClanPrice > 0)
			{
				int clanCoins = GetClanCoins(clientClan);
				Handle renameClanMenu = CreateMenu(Clan_RenameClanSelectMenu);
				FormatEx(print_buff, sizeof(print_buff), "%T", "m_ClanRenamingMenu", client, g_iRenameClanPrice, clanCoins);
				SetMenuTitle(renameClanMenu, print_buff);
				FormatEx(print_buff, sizeof(print_buff), "%T", "m_Yes", client);
				AddMenuItem(renameClanMenu, "Yes", print_buff);
				SetMenuExitButton(renameClanMenu, true);
				DisplayMenu(renameClanMenu, client, 0);
			}
			else
			{
				renameClan[client] = true;
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_RenameClan", client);
				CPrintToChat(client, print_buff);
			}
		}
		else if(!strcmp(selectedItem, "SetType"))
		{
			ThrowSetTypeMenu(client);
		}
		else if(!strcmp(selectedItem, "ChangeRole"))
		{
			CLAN_STYPE = 4;
			ThrowClanMembersToClient(client, clientClan, 4);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(clanControlMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		//ThrowClanMenuToClient(client);
		ThrowLastMenu(client);	//v1.86
	}
}

/**
 * Calls when leader accept expansion the clan
 */
int Clan_ExpandClanSelectPanel(Handle expandClanPanel, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		if(option == 1)
		{
			char print_buff[BUFF_SIZE];
			int clientClan = GetClientClanByID(ClanClient);
			int clanCoins = GetClanCoins(clientClan);
			int clanMaxMembers = GetClanMaxMembers(clientClan);
			if(clanCoins < g_iExpandingCost)
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_NotEnoughCoins", client);
				CPrintToChat(client, print_buff);
			}
			else if(clanMaxMembers + g_iExpandValue > g_iMaxClanMembers)
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_MaxMembersInClan", client);
				CPrintToChat(client, print_buff);
			}
			else
			{
				if(CheckForLog(LOG_SLOTS))
				{
					char log_buff[LOG_SIZE];
					FormatEx(log_buff, sizeof(log_buff), "%T", "L_ExpandClan", LANG_SERVER, g_iExpandValue);
					DB_LogAction(client, false, clientClan, log_buff, -1, true, clientClan, LOG_SLOTS);
				}
				SetClanCoins(clientClan, clanCoins - g_iExpandingCost);
				SetClanMaxMembers(clientClan, clanMaxMembers + g_iExpandValue);
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_ExpandSuccess", client);
				CPrintToChat(client, print_buff);
				//ThrowClanControlMenu(client);
				ThrowLastMenu(client);	//v1.86
			}
		}
	}
	else if (action == MenuAction_End)
		CloseHandle(expandClanPanel);
}

/**
 * Calls when leader select to delete clan or not
 */
int Clan_DeleteClanSelectMenu(Handle deleteClanMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		if(CheckForLog(LOG_CLANACTION))
		{
			char log_buff[LOG_SIZE];
			FormatEx(log_buff, sizeof(log_buff), "%T", "L_DeleteClan", LANG_SERVER, g_sClientData[client][CLIENT_NAME]);
			DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, GetClientClanByID(ClanClient), LOG_CLANACTION);
		}
		DeleteClan(GetClientClanByID(ClanClient));
		char print_buff[BUFF_SIZE];
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_DisbandSuccess", client);
		CPrintToChat(client, print_buff);
	}
	else if (action == MenuAction_End && action == MenuAction_Cancel)
		CloseHandle(deleteClanMenu);
}

/**
 * Calls when leader selects to kick a player
 */
int Clan_KickSelectMenu(Handle kickMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char print_buff[BUFF_SIZE],
			 clientName[MAX_NAME_LENGTH+1],			//Имя игрока, который кикает
			 clanName[MAX_CLAN_NAME+1],				//Название клана игрока
			 targetName[MAX_NAME_LENGTH+1];			//Имя цели для кика
			 
		int targetID = CLAN_STARGET;	//Айди выбранного игрока в базе данных
		int clanid = GetClientClanByID(ClanClient);			//Клан, в котором кикают
		GetClientNameByID(targetID, targetName, sizeof(targetName));
		GetClientName(client, clientName, sizeof(clientName));
		GetClanName(clanid, clanName, sizeof(clanName));
		if(targetID != -1)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerDelete", client, targetName);
			CPrintToChat(client, print_buff);
			if(CheckForLog(LOG_CLIENTACTION))
			{
				char log_buff[LOG_SIZE];
				FormatEx(log_buff, sizeof(log_buff), "%T", "L_DeletePlayer", LANG_SERVER, targetName, clanName);
				DB_LogAction(client, false, clanid, log_buff, targetID, true, clanid, LOG_CLIENTACTION);
			}
			for(int i = 1; i <= MaxClients; i++)
			{
				if(i != client && IsClientInGame(i) && playerID[i] == targetID)
				{
					FormatEx(print_buff, sizeof(print_buff), "%T", "c_KickYou", i, clientName);
					CPrintToChat(i, print_buff);
					i = MaxClients+1;
				}
			}
			DeleteClientByID(targetID);
			CLAN_STYPE = -1;
			CLAN_STARGET = -1;
		}
		else
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerIsNotInClan", client);
			CPrintToChat(client, print_buff);
			CLAN_STYPE = -1;
			CLAN_STARGET = -1;
		}
	}
	else if (action == MenuAction_End)
		CloseHandle(kickMenu);
}

/**
 * Calls when leader select a new clan leader
 */
int Clan_LeaderSelectMenu(Handle kickMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char print_buff[BUFF_SIZE],
			 clientName[MAX_NAME_LENGTH+1],		//Ник клиента
			 targetName[MAX_NAME_LENGTH+1],		//Ник цели
			 targetClanName[MAX_CLAN_NAME+1];	//Название клана цели
		int targetID;
		if(ADMIN_STYPE == 6)
			targetID = ADMIN_STARGET;
		else
			targetID = CLAN_STARGET
		int clanid = GetClientClanByID(targetID);
		GetClientName(client, clientName, sizeof(clientName));
		GetClientNameByID(targetID, targetName, sizeof(targetName));
		GetClanName(clanid, targetClanName, sizeof(targetClanName));
		if(targetID != -1)
		{
			if(ADMIN_STYPE == 6)
			{
				if(CheckForLog(LOG_CHANGEROLE))
				{
					char log_buff[LOG_SIZE];
					FormatEx(log_buff, sizeof(log_buff), "%T", "L_SetLeader", LANG_SERVER, targetName, targetClanName);
					DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, targetID, true, clanid, LOG_CHANGEROLE);
				}
				SetClanLeaderByID(targetID, clanid);
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_LeaderSuccess", client);
				CPrintToChat(client, print_buff);
				for(int i = 1; i <= MaxClients; i++)
				{
					if(i != client && IsClientInGame(i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], targetClanName))
					{
						FormatEx(print_buff, sizeof(print_buff), "%T", "c_AdminChangedLeader", i, clientName, targetName);
						CPrintToChat(i, print_buff);
					}
				}
				ADMIN_STYPE = -1;
				ADMIN_STARGET = -1;
			}
			else
			{
				if(CheckForLog(LOG_CHANGEROLE))
				{
					char log_buff[LOG_SIZE];
					FormatEx(log_buff, sizeof(log_buff), "%T", "L_SetLeader", LANG_SERVER, targetName, targetClanName);
					DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, targetID, true, clanid, LOG_CHANGEROLE);
				}
				SetClanLeaderByID(targetID, clanid);
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_LeaderSuccess", client);
				CPrintToChat(client, print_buff);
				for(int i = 1; i <= MaxClients; i++)
				{
					if(i != client && IsClientInGame(i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], targetClanName))
					{
						FormatEx(print_buff, sizeof(print_buff), "%T", "c_ChangedLeader", i, clientName, targetName);
						CPrintToChat(i, print_buff);
					}
				}
				CLAN_STYPE = -1;
				CLAN_STARGET = -1;
			}
		}
		else
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerIsNotInClan", client);
			CPrintToChat(client, print_buff);
		}
	}
	else if (action == MenuAction_End)
		CloseHandle(kickMenu);
}

/**
 * Player select type of top of clans
 */
int Clan_TopsSelectMenu(Handle topsMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char buffer[60];
		int iOptionToFunc = 0;
		GetMenuItem(topsMenu, option, buffer, sizeof(buffer));
		if(buffer[0] == 'K' && buffer[2] == 'l') // Kills
		{
			if(buffer[5] != 'D')	// KillsDesc
				iOptionToFunc = 1;
		}
		else if(buffer[0] == 'D' && buffer[2] == 'a') // Deaths
		{
			if(buffer[6] == 'D')	// DeathsDesc
				iOptionToFunc = 2;
			else
				iOptionToFunc = 3;
		}
		else if(buffer[0] == 'T' && buffer[2] == 'm') // Time of clan creation
		{
			if(buffer[4] == 'D')	// TimeDesc
				iOptionToFunc = 4;
			else
				iOptionToFunc = 5;
		}
		else if(buffer[0] == 'M' && buffer[2] == 'm') // Members
		{
			if(buffer[7] == 'D')	// MembersDesc
				iOptionToFunc = 6;
			else
				iOptionToFunc = 7;
		}
		else if(buffer[0] == 'C' && buffer[2] == 'i') // Coins
		{
			if(buffer[5] == 'D')	// CoinsDesc
				iOptionToFunc = 8;
			else
				iOptionToFunc = 9;
		}
		ThrowTopClanInCategoryToClient(client, iOptionToFunc);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(topsMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		ThrowLastMenu(client);	//v1.86
	}
}

/**
 * Player select clan in top
 */
int Clan_TopClansSelectMenu(Handle topMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char str_clanid[10], displayInfo[10];
		int style, clanid;
		GetMenuItem(topMenu, option, str_clanid, sizeof(str_clanid), style, displayInfo, sizeof(displayInfo));
		clanid = StringToInt(str_clanid);
		CLAN_STYPE = -2;
		ThrowClanStatsToClient(client, clanid);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(topMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		//ThrowTopsMenuToClient(client);
		ThrowLastMenu(client);	//v1.86
	}
}

/**
 * Admin select action in admin menu
 */
int Clan_AdminClansSelectMenu(Handle adminClansMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char selectedItem[50];
		int style;
		GetMenuItem(adminClansMenu, option, selectedItem, sizeof(selectedItem), style, "", 0);
		if(!strcmp(selectedItem, "CreateClan"))
		{
			bool available = false;
			Handle newClanLeaderSelectMenu = CreateMenu(Clan_LeaderOfNewClanSelectMenu);
			char print_buff[BUFF_SIZE], name[MAX_NAME_LENGTH+1], userid[15];
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_OnlinePlayers", client);
			SetMenuTitle(newClanLeaderSelectMenu, print_buff);
			for(int target = 1; target <= MaxClients; target++)
			{
				if(IsClientInGame(target) && !IsClientInClan(target))
				{
					available = true;
					GetClientName(target, name, sizeof(name));
					IntToString(target, userid, sizeof(userid));
					AddMenuItem(newClanLeaderSelectMenu, userid, name);
				}
			}
			SetMenuExitButton(newClanLeaderSelectMenu, true);
			DisplayMenu(newClanLeaderSelectMenu, client, 0);
			if(available)
			{
				ADMIN_STYPE = 5;
			}
			else
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "NoPlayers", client);
				CPrintToChat(client, print_buff);
			}
		}
		else if(!strcmp(selectedItem, "SetCoins"))
		{
			ADMIN_STYPE = 0;
			ThrowClansToClient(client, true);
		}
		else if(!strcmp(selectedItem, "ResetClient"))
		{
			ADMIN_STYPE = 1;
			ThrowClanClientsToClient(client);
		}
		else if(!strcmp(selectedItem, "ResetClan"))
		{
			ADMIN_STYPE = 2;
			ThrowClansToClient(client, true);
		}
		else if(!strcmp(selectedItem, "DeleteClient"))
		{
			ADMIN_STYPE = 3;
			ThrowClanClientsToClient(client);
		}
		else if(!strcmp(selectedItem, "DeleteClan"))
		{
			ADMIN_STYPE = 4;
			ThrowClansToClient(client, true);
		}
		else if(!strcmp(selectedItem, "ChangeLeader"))
		{
			ADMIN_STYPE = 6;
			ThrowClansToClient(client, true);
		}
		else if(!strcmp(selectedItem, "RenameClan"))
		{
			ADMIN_STYPE = 7;
			renameClan[client] = true;
			ThrowClansToClient(client, true);
		}
		else if(!strcmp(selectedItem, "SetSlots"))
		{
			ADMIN_STYPE = 8;
			ThrowClansToClient(client, true);
		}
		else if(!strcmp(selectedItem, "SetClanType"))
		{
			ADMIN_STYPE = 9;
			ThrowClansToClient(client, true);
		}
		else if(!strcmp(selectedItem, "ChangeRole"))
		{
			ADMIN_STYPE = 10;
			ThrowClansToClient(client, true);
		}
		else
		{
			F_OnAdminClanMenuSelected(adminClansMenu, client, option);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(adminClansMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		//ThrowTopsMenuToClient(client);
		ThrowLastMenu(client);	//v1.86
	}
}

/**
 * Player selects any menu item in list of clans
 */
int Clan_ClansSelectMenu(Handle clansMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char str_clanid[10], 
			 print_buff[BUFF_SIZE],
			 clanName[MAX_CLAN_NAME+1];
		int style, 
			clanid;
		GetMenuItem(clansMenu, option, str_clanid, sizeof(str_clanid), style, "", 0);
		clanid = StringToInt(str_clanid);
		GetClanName(clanid, clanName, sizeof(clanName));	//убрать получение имени через функцию, сделать через GetMenuItem
		if(ADMIN_STYPE == 0)	//set coins
		{
			ADMIN_STARGET = clanid;
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_SetCoins1", client);
			CPrintToChat(client, print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_SetCoins2", client);
			CPrintToChat(client, print_buff);
		}
		else if(ADMIN_STYPE == 2)	//reset clan
		{
			ADMIN_STARGET = clanid;
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanResetCmd", client, clanid, clanName);
			CPrintToChat(client, print_buff);
		}
		else if(ADMIN_STYPE == 4)	//delete clan
		{
			ADMIN_STARGET = clanid;
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanDeleteCmd", client, clanid, clanName);
			CPrintToChat(client, print_buff);
		}
		else if(ADMIN_STYPE == 6)	//change leader
		{
			ADMIN_STARGET = clanid;
			ThrowClanMembersToClient(client, clanid, 1);
		}
		else if(ADMIN_STYPE == 7)	//rename clan
		{
			ADMIN_STARGET = clanid;
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_RenameClan", client);
			CPrintToChat(client, print_buff);
		}
		else if(ADMIN_STYPE == 8)	//change slots
		{
			ADMIN_STARGET = clanid;
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_SetSlots1", client);
			CPrintToChat(client, print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_SetSlots2", client);
			CPrintToChat(client, print_buff);
		}
		else if(ADMIN_STYPE == 9)	//set clan type
		{
			ADMIN_STARGET = clanid;
			ThrowSetTypeMenu(client);
		}
		else if(ADMIN_STYPE == 10)	//change player's role in clan
		{
			ADMIN_STARGET = clanid;
			ThrowClanMembersToClient(client, clanid, 1);
		}
		else if(CLAN_STYPE == 3)	//transfer coins
		{
			CLAN_STARGET = clanid;
			int clientClanCoins = GetClanCoins(GetClientClanByID(ClanClient));
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_TranferCoins", client, clientClanCoins);
			CPrintToChat(client, print_buff);
		}
		else
		{
			F_OnClanSelectedInList(clansMenu, client, option);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(clansMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		/*if(ADMIN_STYPE != -1)
			ThrowAdminMenu(client);
		else
			ThrowClanControlMenu(client);*/
		ThrowLastMenu(client);	//v1.86
		ADMIN_STYPE = -1;
		CLAN_STYPE = -1;
		CLAN_STARGET = -1;
	}
}

/**
 * Admin selects any menu item in list of clan clients
 */
int Clan_ClanClientsSelectMenu(Handle clanClientsMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char print_buff[BUFF_SIZE], 
			 str_targetID[10],				//Айди цели, но в строковом виде
			 targetName[MAX_NAME_LENGTH+1];	//Имя цели
		int style,
			targetID;
		GetMenuItem(clanClientsMenu, option, str_targetID, sizeof(str_targetID), style, "", 0);
		ADMIN_STARGET = targetID = StringToInt(str_targetID);
		GetClientNameByID(ADMIN_STARGET, targetName, sizeof(targetName));
		if(ADMIN_STYPE == 1)	//reset client
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerResetCmd", client, targetID, targetName);
			CPrintToChat(client, print_buff);
		}
		else if(ADMIN_STYPE == 3)	//delete client
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerDeleteCmd", client, targetID, targetName);
			CPrintToChat(client, print_buff);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(clanClientsMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		ADMIN_STYPE = -1;
		ThrowLastMenu(client);
	}
}

/**
 * Calls when player open help menu
 */
int Clan_HelpMenu(Handle helpMenu, MenuAction action, int client, int option)
{
	CloseHandle(helpMenu);
}

/**
 * Calls when admin select a player for new clan
 */
int Clan_LeaderOfNewClanSelectMenu(Handle newClanLeaderSelectMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char str_targetID[10], print_buff[BUFF_SIZE];
		int style;
		GetMenuItem(newClanLeaderSelectMenu, option, str_targetID, sizeof(str_targetID), style, "", 0);
		ADMIN_STARGET = StringToInt(str_targetID);
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_EnterClanName", client);
		CPrintToChat(client, print_buff);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(newClanLeaderSelectMenu);
	}
	/*else if(action == MenuAction_Cancel)
	{
		ADMIN_STYPE = -1;
	}*/
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		ADMIN_STYPE = -1;
		ThrowLastMenu(client);
	}
}

/**
 * Calls when player got an invitation to clan
 */
int Clans_InviteAcceptMenu(Handle inviteMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char answer[10];
		int style;
		GetMenuItem(inviteMenu, option, answer, sizeof(answer), style, "", 0);
		if(!strcmp(answer, "Yes"))
		{
			char buff[BUFF_SIZE];
			int whoInvited = invitedBy[client][0];
			int invitingClan = GetClientClanByID(playerID[whoInvited]);
			if(GetClanMembers(invitingClan) >= GetClanMaxMembers(invitingClan))
			{
				FormatEx(buff, sizeof(buff), "%T", "c_MaxMembersInClan", client);
				CPrintToChat(client, buff);
				invitedBy[client][0] = -1;
			}
			else
			{
				if(CheckForLog(LOG_CLIENTACTION))
				{
					char log_buff[LOG_SIZE],
						 clanName[MAX_CLAN_NAME+1];
					GetClanName(invitingClan, clanName, sizeof(clanName));
					FormatEx(log_buff, sizeof(log_buff), "%T", "L_CreatePlayer", LANG_SERVER, clanName);
					DB_LogAction(client, false, -1, log_buff, invitedBy[client][0], false, invitingClan, LOG_CLIENTACTION);
				}
				SetOnlineClientClan(client, invitingClan, 0);
				invitedBy[client][0] = -1;
				FormatEx(buff, sizeof(buff), "%T", "c_JoinSuccess", client);
				CPrintToChat(client, buff);
			}
		}
		invitedBy[client][0] = -1;
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(inviteMenu);
	}
}

/**
 * Calls when player selects a type for a clan
 */
int Clan_SetTypeSelectMenu(Handle setTypeMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char print_buff[BUFF_SIZE], 
			 clientName[MAX_NAME_LENGTH+1], 
			 type[150],
			 clanName[MAX_CLAN_NAME+1];
		int clanid,
			clanType;
			//clientRole = -1;	//Если не админ, то проверяем, чтобы можно было выбросить меню управления кланом

		GetClientName(client, clientName, sizeof(clientName));
		if(ADMIN_STYPE == 9)
		{
			clanid = ADMIN_STARGET;
			GetClanName(clanid, clanName, sizeof(clanName));
		}
		else
		{
			clanid = GetClientClanByID(ClanClient, true);
			FormatEx(clanName, sizeof(clanName), "%s", g_sClientData[client][CLIENT_CLANNAME]);
			//clientRole = GetClientRoleByID(client);
		}
		clanType = GetClanType(clanid);
		if(option == 0)			//Player selects closed clan
		{
			if(clanType != CLAN_CLOSED)
			{
				if(CheckForLog(LOG_CHANGETYPE))
				{
					char log_buff[LOG_SIZE];
					FormatEx(log_buff, sizeof(log_buff), "%T", "L_SetClanType", LANG_SERVER, 0, clanName);
					DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_CHANGETYPE);
				}
				SetClanType(clanid, CLAN_CLOSED);
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_TypeChangeSuccess", client);
				CPrintToChat(client, print_buff);
				for(int i = 1; i <= MaxClients; i++)
				{
					if(i != client && IsClientInGame(i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], clanName))
					{
						FormatEx(type, sizeof(type), "%T", "m_TypeInvite", i);
						FormatEx(print_buff, sizeof(print_buff), "%T", "c_TypeChangedTo", i, clientName, type);
						CPrintToChat(i, print_buff);
					}
				}
			}
		}
		else if(option == 1)	//Player selects open clan
		{
			if(clanType != CLAN_OPEN)
			{
				if(CheckForLog(LOG_CHANGETYPE))
				{
					char log_buff[LOG_SIZE];
					FormatEx(log_buff, sizeof(log_buff), "%T", "L_SetClanType", LANG_SERVER, 1, clanName);
					DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_CHANGETYPE);
				}
				SetClanType(clanid, CLAN_OPEN);
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_TypeChangeSuccess", client);
				CPrintToChat(client, print_buff);
				for(int i = 1; i <= MaxClients; i++)
				{
					if(i != client && IsClientInGame(i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], clanName))
					{
						FormatEx(type, sizeof(type), "%T", "m_TypeOpen", i);
						FormatEx(print_buff, sizeof(print_buff), "%T", "c_TypeChangedTo", i, clientName, type);
						CPrintToChat(i, print_buff);
					}
				}
			}
		}
		/*if(ADMIN_STYPE == 9)
			ThrowClansToClient(client, true);
		/else if(CanRoleDo(clientRole, PERM_TYPE))
			ThrowClanControlMenu(client);
		else
			ThrowClanMenuToClient(client);/
		else
			ThrowClanControlMenu(client);*/
		ThrowLastMenu(client);	//v1.86
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(setTypeMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		/*if(ADMIN_STYPE == 9)
			ThrowClansToClient(client, true);
		else
			ThrowClanControlMenu(client);*/
		ThrowLastMenu(client);	//v1.86
	}
}

/**
 * Calls when player selects a new role for a clan member
 */
int Clan_ChangeRoleSelectMenu(Handle changeRoleMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		int targetID, 
			role, 
			newRole, 
			style;
		char print_buff[BUFF_SIZE], 
			 selectedItem[50], 
			 c_newRole[50],
			 clientName[MAX_NAME_LENGTH+1],
			 targetName[MAX_NAME_LENGTH+1];
			 
		GetClientName(client, clientName, sizeof(clientName));
		targetID = CLAN_STARGET;
		role = GetClientRoleByID(targetID);
		GetClientNameByID(targetID, targetName, sizeof(targetName));
		GetMenuItem(changeRoleMenu, option, selectedItem, sizeof(selectedItem), style, "", 0);
		if(!strcmp(selectedItem, "Member"))
		{
			newRole = CLIENT_MEMBER;
		}
		else if(!strcmp(selectedItem, "Elder"))
		{
			newRole = CLIENT_ELDER;
		}

		else if(!strcmp(selectedItem, "Coleader"))
		{
			newRole = CLIENT_COLEADER;
		}
		else if(!strcmp(selectedItem, "Leader"))
		{
			newRole = CLIENT_LEADER;
		}
		if(role != newRole)
		{
			if(CheckForLog(LOG_CHANGEROLE))
			{
				char log_buff[LOG_SIZE];
				FormatEx(log_buff, sizeof(log_buff), "%T", "L_SetRole", LANG_SERVER, targetName, newRole);
				DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, targetID, true, GetClientClanByID(targetID), LOG_CHANGEROLE);
			}
			if(SetClientRoleByID(targetID, newRole))
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_ChangeRoleSuccess", client);
				CPrintToChat(client, print_buff);
				for(int i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i) && playerID[i] == targetID)
					{
						FormatEx(c_newRole, sizeof(c_newRole), "%T", selectedItem, i);
						FormatEx(print_buff, sizeof(print_buff), "%T", "c_RoleChangedTo", i, clientName, c_newRole);
						CPrintToChat(i, print_buff);
						i = MaxClients+1;
					}
				}
			}
		}
		/*if(ADMIN_STYPE == 10)
		{
			ThrowClansToClient(client, true);
		}
		else
		{
			ThrowClanControlMenu(client);
		}*/
		ThrowLastMenu(client);	//v1.86
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(changeRoleMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		/*int clanid, flags;
		if(ADMIN_STYPE == 10)
		{
			clanid = GetClientClanByID(ADMIN_STARGET);
			flags = 1;
		}
		else
		{
			clanid = GetClientClanByID(CLAN_STARGET);
			flags = 2;
		}
		if(!ThrowClanMembersToClient(client, clanid, flags))
			ThrowClanControlMenu(client);*/
		ThrowLastMenu(client);	//v1.86
	}
}

/**
 * Calls when player wants to rename the clan
 */
int Clan_RenameClanSelectMenu(Handle renameClanMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char print_buff[BUFF_SIZE];
		int clanid = GetClientClanByID(ClanClient);
		int clanCoins = GetClanCoins(clanid);
		if(clanCoins - g_iRenameClanPrice < 0)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_NotEnoughCoins", client);
			CPrintToChat(client, print_buff);
		}
		else
		{
			renameClan[client] = true;
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_RenameClan", client);
			CPrintToChat(client, print_buff);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(renameClanMenu);
	}
	else if(action == MenuAction_Cancel)
	{
		//ThrowClanControlMenu(client);
		ThrowLastMenu(client);	//v1.86
	}
}

/**
 * Called when player select smth in clan tag setting menu (1.81)
 */
int Clan_ClanTagSetMenu(Handle clanTagSetMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char sBuff[BUFF_SIZE];
		if(option == 0)	//Yes
		{
			SetClanTagCookie(client, 1);
		}
		else	//No
		{
			SetClanTagCookie(client, 0);
		}
		FormatEx(sBuff, sizeof(sBuff), "%T", "c_ClanTagSetSuccess", client);
		CPrintToChat(client, sBuff);
		//ThrowClanTagSettings(client);
		ThrowLastMenu(client, true);	//v1.86
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(clanTagSetMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		//ThrowClanMenuToClient(client);
		ThrowLastMenu(client);	//v1.86
	}
}

//=============================== MENUS THROWS ===============================//
/**
 * Throws clan menu to player
 *
 * @param int client - player's id, who will see the clan menu
 *
 * @return true - success, false - failed
 */
bool ThrowClanMenuToClient(int client)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return false;
	ADMIN_STYPE = -1;
	ADMIN_STARGET = -1;
	char query[200];
	FormatEx(query, sizeof(query), "SELECT `player_role` FROM `players_table` WHERE `player_id` = '%d'", ClanClient);
	g_hClansDB.Query(DBM_ClanMenuCallback, query, client);
	g_asClientLastMenu[client].Push(MDINT(MD_ThrowClanMenuToClient));
	g_asMClientBuffer[client].Push(NO_BUFF_DATA);
	return true;
}

/**
 * Throws player stats to client
 *
 * @param int client - player's id, who will see the stats
 * @param int targetID - player's id in database, whose stats will be shown
 *
 * @return true - success, false - failed
 */
bool ThrowPlayerStatsToClient(int client, int targetID)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return false;
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && playerID[i] == targetID)
		{
			char stats[400],
				timeInClan[60],
				targetName[MAX_NAME_LENGTH+1],
				status[30],
				sLastJoin[60];	//v1.86
			int targetClanid = g_iClientData[i][CLIENT_CLANID];
			int targetRole = g_iClientData[i][CLIENT_ROLE];
			int targetKills = g_iClientData[i][CLIENT_KILLS]+g_iClientDiffData[i][CD_DIFF_KILLS];
			int targetDeaths = g_iClientData[i][CLIENT_DEATHS]+g_iClientDiffData[i][CD_DIFF_DEATHS];
			int targetTimeInClan = g_iClientData[i][CLIENT_TIME];
			
			GetClientName(i, targetName, sizeof(targetName));
				
			Handle playerStatsMenu = CreatePanel();
			
			FormatEx(stats, sizeof(stats), "%T", "m_PlayerStatsTitle", client);
			SetPanelTitle(playerStatsMenu, stats);
			FormatEx(stats, sizeof(stats), "%T", "m_Close", client);
			DrawPanelItem(playerStatsMenu, stats, 0);
			SecondsToTime(GetTime() - targetTimeInClan, timeInClan, sizeof(timeInClan), client);
			if(targetRole == CLIENT_LEADER)
				FormatEx(status, sizeof(status), "%T", "Leader", client);
			else if(targetRole == CLIENT_COLEADER)
				FormatEx(status, sizeof(status), "%T", "Coleader", client);
			else if(targetRole == CLIENT_ELDER)
				FormatEx(status, sizeof(status), "%T", "Elder", client);
			else
				FormatEx(status, sizeof(status), "%T", "Member", client);
			FormatEx(sLastJoin, sizeof(sLastJoin), "%T", "ActiveNow", client);
			FormatEx(stats, sizeof(stats), "%T", "m_PlayerStats", client, targetName, 
																	targetID, g_sClientData[i][CLIENT_CLANNAME], 
																	targetClanid, status, 
																	targetKills, targetDeaths, 
																	timeInClan, sLastJoin);
			DrawPanelText(playerStatsMenu, stats);
			F_OnPlayerStatsOpened(playerStatsMenu, client);
			SendPanelToClient(playerStatsMenu, client, Clan_PlayerStatsMenu, 0);
			g_asClientLastMenu[client].Push(MDINT(MD_ThrowPlayerStatsToClient));
			g_asMClientBuffer[client].Push(targetID);
			return true;
		}
	}
	char query[300];
	FormatEx(query, sizeof(query), "SELECT `player_id`, `player_clanid`, `player_role`, `player_kills`, `player_deaths`, `player_timejoining`, player_lastjoin FROM `players_table` WHERE `player_id` = '%d'", targetID);
	g_hClansDB.Query(DBM_PlayerStats, query, client);
	g_asClientLastMenu[client].Push(MDINT(MD_ThrowPlayerStatsToClient));
	g_asMClientBuffer[client].Push(targetID);
	return true;
}

/**
 * Throws clan stats to client
 *
 * @param int client - player's id, who will see the stats
 * @param int clanid - clan's id, whose stats will be shown
 *
 * @return true - success, false - failed
 */
bool ThrowClanStatsToClient(int client, int clanid)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return false;
	char query[300];
	FormatEx(query, sizeof(query), "SELECT `clan_name`, `clan_id`, `clan_type`, `leader_name`, `maxmembers`, `clan_kills`, `clan_deaths`, `time_creation`, `clan_coins` FROM `clans_table` WHERE `clan_id` = '%d';", clanid);
	g_hClansDB.Query(DBM_ClanStats, query, client);
	g_asClientLastMenu[client].Push(MDINT(MD_ThrowClanStatsToClient));
	g_asMClientBuffer[client].Push(clanid);
	return true;
}

/**
 * Throws clan members to client
 *
 * @param int client - player's id, who will see members
 * @param int clanid - clan's id, whose members will be shown
 * @param int showFlags - flags to members to show: 1st bit - client will be shown in menu, 2nd bit - don't show clients whose role is above client's one, 3rd bit - don't show whose role is above or equals client's one
 *
 * @return true - success, false - failed
 */
bool ThrowClanMembersToClient(int client, int clanid, int showFlags)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return false;
	bool showClient = showFlags & 1 > 0;
	bool notShowHigher = showFlags & 2 > 0;
	bool notShowEquals = showFlags & 4 > 0;
	char query[200];
	FormatEx(query, sizeof(query), "SELECT `player_name`, `player_steam`, `player_role` FROM `players_table` WHERE `player_clanid` = '%d'", clanid);
	if(!showClient)
	{
		Format(query, sizeof(query), "%s AND `player_id` != '%d'", query, ClanClient);
	}
	if(notShowEquals)
	{
		Format(query, sizeof(query), "%s AND `player_role` < '%d'", query, GetClientRoleByID(ClanClient));
	}
	else if(notShowHigher)
	{
		Format(query, sizeof(query), "%s AND `player_role` <= '%d'", query, GetClientRoleByID(ClanClient));
	}
	g_hClansDB.Query(DBM_ClanMembersListCallback, query, client);
	g_asClientLastMenu[client].Push(MDINT(MD_ThrowClanMembersToClient));
	g_asMClientBuffer[client].Push(clanid | showFlags << 29);
	return true;
}

/**
 * Throws tops of clans menu to player
 *
 * @param int client - player's id, who will see tops of clans menu
 *
 * @return true - success, false - failed
 */
bool ThrowTopsMenuToClient(int client)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return false;
	Handle topsMenu = CreateMenu(Clan_TopsSelectMenu);
	char print_buff[100];
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_Top", client);
	SetMenuTitle(topsMenu, print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "t_KillsDesc", client);
	AddMenuItem(topsMenu, "KillsDesc", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "t_KillsAsc", client);
	AddMenuItem(topsMenu, "KillsInc", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "t_DeathsDesc", client);
	AddMenuItem(topsMenu, "DeathsDesc", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "t_DeathsAsc", client);
	AddMenuItem(topsMenu, "DeathsInc", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "t_TimeDesc", client);
	AddMenuItem(topsMenu, "TimeDesc", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "t_TimeAsc", client);
	AddMenuItem(topsMenu, "TimeInc", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "t_MembersDesc", client);
	AddMenuItem(topsMenu, "MembersDesc", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "t_MembersAsc", client);
	AddMenuItem(topsMenu, "MembersInc", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "t_CoinsDesc", client);
	AddMenuItem(topsMenu, "CoinsDesc", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "t_CoinsAsc", client);
	AddMenuItem(topsMenu, "CoinsInc", print_buff);
	if(IsMBufferEmpty(client))
		SetMenuExitButton(topsMenu, true);
	else
		SetMenuExitBackButton(topsMenu, true);
	DisplayMenu(topsMenu, client, 0);
	g_asClientLastMenu[client].Push(MDINT(MD_ThrowTopsMenuToClient));
	g_asMClientBuffer[client].Push(NO_BUFF_DATA);
	return true;
}

void ThrowTopClanInCategoryToClient(int client, int option)
{
	Handle topMenu = CreateMenu(Clan_TopClansSelectMenu);
	char query[300],
		 buffer[300];
	if(option < 2)	//Kills
	{
		Format(query, sizeof(query), "SELECT `clan_id`, `clan_name`, `clan_kills` FROM `clans_table` ORDER BY `clan_kills` %s", (option == 0 ? "DESC" : "ASC") );
		FormatEx(buffer, sizeof(buffer), "%T", (option == 0 ? "t_KillsDesc" : "t_KillsAsc"), client);
		SetMenuTitle(topMenu, buffer);
	}
	else if(option < 4)	//Deaths
	{
		Format(query, sizeof(query), "SELECT `clan_id`, `clan_name`, `clan_deaths` FROM `clans_table` ORDER BY `clan_deaths` %s", (option == 2 ? "DESC" : "ASC") );
		FormatEx(buffer, sizeof(buffer), "%T", (option == 2 ? "t_DeathsDesc" : "t_DeathsAsc"), client);
		SetMenuTitle(topMenu, buffer);
	}
	else if(option < 6)	//Time of clan creation
	{
		FormatEx(query, sizeof(query), "SELECT `clan_id`, `clan_name`, `time_creation` FROM `clans_table` ORDER BY `time_creation` %s", (option == 4 ? "ASC" : "DESC") );
		FormatEx(buffer, sizeof(buffer), "%T", (option == 4 ? "t_TimeDesc" : "t_TimeAsc"), client);
		SetMenuTitle(topMenu, buffer);
	}
	else if(option < 8)	//Members
	{
		FormatEx(query, sizeof(query), "SELECT `clan_id`, `clan_name`, (SELECT COUNT(*) FROM `players_table` WHERE `player_clanid` = `clan_id`) AS `playersInClan` FROM `clans_table` ORDER BY `playersInClan` %s;", (option == 6 ? "DESC" : "ASC") );
		FormatEx(buffer, sizeof(buffer), "%T", (option == 6 ? "t_MembersDesc" : "t_MembersAsc"), client);
		SetMenuTitle(topMenu, buffer);
	}
	else if(option < 10) //Coins
	{
		Format(query, sizeof(query), "SELECT `clan_id`, `clan_name`, `clan_coins` FROM `clans_table` ORDER BY `clan_coins` %s", (option == 8 ? "DESC" : "ASC") );
		FormatEx(buffer, sizeof(buffer), "%T", (option == 8 ? "t_CoinsDesc" : "t_CoinsAsc"), client);
		SetMenuTitle(topMenu, buffer);
	}
	DataPack dp = CreateDataPack();
	dp.WriteCell(client);
	dp.WriteCell(topMenu);
	dp.WriteCell(option);
	dp.Reset();
	g_hClansDB.Query(DBM_TopClansListCallback, query, dp);
	g_asClientLastMenu[client].Push(MDINT(MD_ThrowTopClanInCategoryToClient));
	g_asMClientBuffer[client].Push(option);
}

/**
 * Throws clans to player
 *
 * @param int client - player's id, who will see clans
 * @param bool showClientClan - flag if client's clan will be shown in menu
 *
 * @return true - success, false - failed
 */
bool ThrowClansToClient(int client, bool showClientClan)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return false;
	char query[200];
	FormatEx(query, sizeof(query), "SELECT `clan_id`, `clan_name` FROM `clans_table`");
	if(!showClientClan)
	{
		Format(query, sizeof(query), "%s WHERE `clan_id` != '%d'", query, GetClientClanByID(ClanClient));
	}
	g_hClansDB.Query(DBM_ClansListCallback, query, client);
	g_asClientLastMenu[client].Push(MDINT(MD_ThrowClansToClient));
	g_asMClientBuffer[client].Push(view_as<int>(showClientClan));
	return true;
}

/**
 * Throws all clan clients to player
 *
 * @param int client - player's id, who will see clients
 * @return true - success, false - failed
 */
bool ThrowClanClientsToClient(int client)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return false;
	char query[70];
	FormatEx(query, sizeof(query), "SELECT `player_id`, `player_name` FROM `players_table`");
	g_hClansDB.Query(DBM_ClanClientsListCallback, query, client);
	g_asClientLastMenu[client].Push(MDINT(MD_ThrowClanClientsToClient));
	g_asMClientBuffer[client].Push(NO_BUFF_DATA);
	return true;
}

/**
 * Show all players available to invite
 *
 * @param int client - player's id
 * @return true - success, false - failed
 */
bool ThrowInviteList(int client)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || !CanPlayerDo(client, PERM_INVITE))
		return false;
	Handle inviteSelectMenu = CreateMenu(Clan_InvitePlayerSelectMenu);
	char print_buff[80], 
		 name[MAX_NAME_LENGTH+1], 
		 userid[15];
	bool allPlayersFree = true;
		 
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_WhomToInvite", client);
	SetMenuTitle(inviteSelectMenu, print_buff);
	for (int target = 1; target <= MaxClients; target++)
	{
		if(IsClientInGame(target) && !IsFakeClient(target) && !IsClientInClan(target) && (invitedBy[target][0] == -1 || GetTime() - invitedBy[target][1] > MAX_INVITATION_TIME ))
		{
			allPlayersFree = false;
			GetClientName(target, name, sizeof(name));
			IntToString(GetClientUserId(target), userid, 15); 
			AddMenuItem(inviteSelectMenu, userid, name);
		}
	}
	if(allPlayersFree)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "c_NoOneToInvite", client);
		CPrintToChat(client, print_buff);
		return false;
	}
	SetMenuExitButton(inviteSelectMenu, true);
	DisplayMenu(inviteSelectMenu, client, 0);
	g_asClientLastMenu[client].Push(MDINT(MD_ThrowInviteList));
	g_asMClientBuffer[client].Push(NO_BUFF_DATA);
	return true;
}

/**
 * Throws clan control menu
 *
 * @param int client - player's id
 *
 * @return true - success, false - failed
 */
bool ThrowClanControlMenu(int client)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return false;
	char query[500];
	FormatEx(query, sizeof(query), "SELECT `player_role` FROM `players_table` WHERE `player_id` = '%d'", ClanClient);
	g_hClansDB.Query(DBM_ControlMenuCallback, query, client);
	g_asClientLastMenu[client].Push(MDINT(MD_ThrowClanControlMenu));
	g_asMClientBuffer[client].Push(NO_BUFF_DATA);
	return true;
}

/**
 * Throws set type clan menu to client
 *
 * @param int client - player's id, who will see clients
 * @return true - success, false - failed
 */
bool ThrowSetTypeMenu(int client)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
		return false;
	int clanid;
	if(ADMIN_STYPE == 9)
		clanid = ADMIN_STARGET;
	else
		clanid = GetClientClanByID(ClanClient, true);
	int type = GetClanType(clanid);
	char print_buff[100];
	Handle setTypeMenu = CreateMenu(Clan_SetTypeSelectMenu);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_SetClanType", client);
	SetMenuTitle(setTypeMenu, print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_TypeInvite", client);
	if(type == 0)
		Format(print_buff, sizeof(print_buff), "%s [✓]", print_buff);
	AddMenuItem(setTypeMenu, "Closed", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_TypeOpen", client);
	if(type == 1)
		Format(print_buff, sizeof(print_buff), "%s [✓]", print_buff);
	AddMenuItem(setTypeMenu, "Open", print_buff);
	SetMenuExitBackButton(setTypeMenu, true);
	DisplayMenu(setTypeMenu, client, 0);
	g_asClientLastMenu[client].Push(MDINT(MD_ThrowSetTypeMenu));
	g_asMClientBuffer[client].Push(NO_BUFF_DATA);
	return true;
}

/**
 * Throws change role menu to client
 *
 * @param int client - player's id, who will see clients
 * @param int targetID - target's id in database
 * @return true - success, false - failed
 */
bool ThrowChangeRoleMenu(int client, int targetID)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || targetID < 0)
		return false;
	int role = GetClientRoleByID(targetID);
	int clientRole;
	if(ADMIN_STYPE != 10)
		clientRole = GetClientRoleByID(ClanClient);
	else
		clientRole = CLIENT_LEADER;
	char print_buff[100];
	Handle changeRoleMenu = CreateMenu(Clan_ChangeRoleSelectMenu);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_ChangeRole", client);
	SetMenuTitle(changeRoleMenu, print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "Member", client);
	if(role == CLIENT_MEMBER)
		Format(print_buff, sizeof(print_buff), "%s [✓]", print_buff);
	AddMenuItem(changeRoleMenu, "Member", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "Elder", client);
	if(role == CLIENT_ELDER)
		Format(print_buff, sizeof(print_buff), "%s [✓]", print_buff);
	AddMenuItem(changeRoleMenu, "Elder", print_buff);
	if(clientRole > CLIENT_ELDER)
	{
		FormatEx(print_buff, sizeof(print_buff), "%T", "Coleader", client);
		if(role == CLIENT_COLEADER)
			Format(print_buff, sizeof(print_buff), "%s [✓]", print_buff);
		AddMenuItem(changeRoleMenu, "Coleader", print_buff);
		if(clientRole > CLIENT_COLEADER && (g_bLeaderChange || ADMIN_STYPE == 10))
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "Leader", client);
			if(role == CLIENT_LEADER)
				Format(print_buff, sizeof(print_buff), "%s [✓]", print_buff);
			AddMenuItem(changeRoleMenu, "Leader", print_buff);
		}
	}
	SetMenuExitBackButton(changeRoleMenu, true);
	DisplayMenu(changeRoleMenu, client, 0);
	g_asClientLastMenu[client].Push(MDINT(MD_ThrowChangeRoleMenu));
	g_asMClientBuffer[client].Push(targetID);
	return true;
}

/**
 * Показ админ меню игроку
 *
 * @param int client - игрок, которому показываем админ меню
 *
 * @return true - успешно, false иначе
 */
bool ThrowAdminMenu(int client)
{
	if(client < 1 || client > MaxClients)
		return false;
		
	AdminId adminid = GetUserAdmin(client);
	if(!GetAdminFlag(adminid, Admin_Root))
		return false;
		
	CLAN_STYPE = -1;
	CLAN_STARGET = -1;
	ADMIN_STYPE = -1;
	ADMIN_STARGET = -1;
	
	char print_buff[BUFF_SIZE];
	Handle adminClansMenu = CreateMenu(Clan_AdminClansSelectMenu);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_AdminMenu", client);
	SetMenuTitle(adminClansMenu, print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_CreateClan", client);
	AddMenuItem(adminClansMenu, "CreateClan", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_ChangeCoinsInClan", client);
	AddMenuItem(adminClansMenu, "SetCoins", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_AdminChangeSlots", client);
	AddMenuItem(adminClansMenu, "SetSlots", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_ResetPlayer", client);
	AddMenuItem(adminClansMenu, "ResetClient", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_ResetClan", client);
	AddMenuItem(adminClansMenu, "ResetClan", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_KickPlayer", client);
	AddMenuItem(adminClansMenu, "DeleteClient", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_DeleteClan", client);
	AddMenuItem(adminClansMenu, "DeleteClan", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_RenameClan", client);
	AddMenuItem(adminClansMenu, "RenameClan", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_ChangeLeader", client);
	AddMenuItem(adminClansMenu, "ChangeLeader", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_SetClanType", client);
	AddMenuItem(adminClansMenu, "SetClanType", print_buff);
	FormatEx(print_buff, sizeof(print_buff), "%T", "m_ChangeRole", client);
	AddMenuItem(adminClansMenu, "ChangeRole", print_buff);
	F_OnAdminClanMenuOpened(adminClansMenu, client);
	if(IsMBufferEmpty(client))
		SetMenuExitButton(adminClansMenu, true);
	else
		SetMenuExitBackButton(adminClansMenu, true);
	DisplayMenu(adminClansMenu, client, 0);
	g_asClientLastMenu[client].Push(MDINT(MD_ThrowAdminMenu));
	g_asMClientBuffer[client].Push(NO_BUFF_DATA);
	return true;
}

/**
 * Throws clan commands for players
 */
void ThrowClanHelp(int client)
{
	if(client > 0 && client <= MaxClients)
	{
		Handle helpPanel = CreatePanel();
		char helpText[500];
		FormatEx(helpText, sizeof(helpText), "%T", "m_ClanHelpCmds", client);
		SetPanelTitle(helpPanel, helpText);
		FormatEx(helpText, sizeof(helpText), "%T", "m_ClanHelp", client);
		DrawPanelText(helpPanel, helpText);
		FormatEx(helpText, sizeof(helpText), "%T", "m_Close", client);
		DrawPanelItem(helpPanel, helpText, 0);
		SendPanelToClient(helpPanel, client, Clan_HelpMenu, 0);
		g_asClientLastMenu[client].Push(MDINT(MD_ThrowClanHelp));
		g_asMClientBuffer[client].Push(NO_BUFF_DATA);
	}
}

/**
 * Throws clan tag setting menu to client
 */
void ThrowClanTagSettings(int client)
{
	if(!IsClientInGame(client))
		return;
	char sBuff[BUFF_SIZE];
	bool tagEnable = GetClanTagCookie(client) == 1;
	Handle clanTagSetMenu = CreateMenu(Clan_ClanTagSetMenu);
	FormatEx(sBuff, sizeof(sBuff), "%T", "m_ClanTagSetTitle", client);
	SetMenuTitle(clanTagSetMenu, sBuff);
	FormatEx(sBuff, sizeof(sBuff), "%T", "m_Yes", client);
	if(tagEnable)
		Format(sBuff, sizeof(sBuff), "%s [✓]", sBuff);
	AddMenuItem(clanTagSetMenu, "Yes", sBuff);
	FormatEx(sBuff, sizeof(sBuff), "%T", "m_No", client);
	if(!tagEnable)
		Format(sBuff, sizeof(sBuff), "%s [✓]", sBuff);
	AddMenuItem(clanTagSetMenu, "No", sBuff);
	SetMenuExitBackButton(clanTagSetMenu, true);
	DisplayMenu(clanTagSetMenu, client, 0);
	g_asClientLastMenu[client].Push(MDINT(MD_ThrowClanTagSettings));
	g_asMClientBuffer[client].Push(NO_BUFF_DATA);
}

/**
 * Show last menu to client (v1.86)
 *
 * @param int iClient - client's index
 *
 * params - any params (30st and 29st bits are used for additional flags, starting from 30st)
 *
 **/
#define TLM_PARAM1(%1) %1 & (1 << 29)
#define TLM_PARAM2(%1) %1 & (1 << 30)
#define TLM_NO_FLAGS(%1) %1 & ((1 << 29) - 1)
void ThrowLastMenu(int iClient, bool bActualMenu = false)
{
	if(IsClientInGame(iClient) && !IsMBufferEmpty(iClient))
	{
		int params = g_asMClientBuffer[iClient].Pop();
		int iFlags = params & (TLM_PARAM1(params) | TLM_PARAM2(params));
		iFlags = iFlags >> 29;
		MD_Funcs mdFunc = view_as<MD_Funcs>(g_asClientLastMenu[iClient].Pop());
		if(!bActualMenu && g_asClientLastMenu[iClient].Empty)
			return;
		if(!bActualMenu)
		{
			mdFunc = view_as<MD_Funcs>(g_asClientLastMenu[iClient].Pop());
			params = g_asMClientBuffer[iClient].Pop();
			iFlags = params & (TLM_PARAM1(params) | TLM_PARAM2(params));
			iFlags = iFlags >> 29;
		}
		
		//PrintToServer("Menu -> |%d|\nbActualMenu = %d\nparams = %d | %d\niFlags = %d", mdFunc, bActualMenu, params, TLM_NO_FLAGS(params), iFlags);	//DEBUG

		switch(mdFunc)
		{
			case MD_ThrowClanMenuToClient:
			{
				ThrowClanMenuToClient(iClient);
			}
			case MD_ThrowPlayerStatsToClient:
			{
				ThrowPlayerStatsToClient(iClient, params);
			}
			case MD_ThrowClanStatsToClient:
			{
				ThrowClanStatsToClient(iClient, params);
			}
			case MD_ThrowClanMembersToClient:
			{
				ThrowClanMembersToClient(iClient, TLM_NO_FLAGS(params), iFlags);
			}
			case MD_ThrowTopsMenuToClient:
			{
				ThrowTopsMenuToClient(iClient);
			}
			case MD_ThrowTopClanInCategoryToClient:
			{
				ThrowTopClanInCategoryToClient(iClient, params);
			}
			case MD_ThrowClansToClient:
			{
				ThrowClansToClient(iClient, view_as<bool>(params));
			}
			case MD_ThrowClanClientsToClient:
			{
				ThrowClanClientsToClient(iClient);
			}
			case MD_ThrowInviteList:
			{
				ThrowInviteList(iClient);
			}
			case MD_ThrowClanControlMenu:
			{
				ThrowClanControlMenu(iClient);
			}
			case MD_ThrowSetTypeMenu:
			{
				ThrowSetTypeMenu(iClient);
			}
			case MD_ThrowChangeRoleMenu:
			{
				ThrowChangeRoleMenu(iClient, params);
			}
			case MD_ThrowAdminMenu:
			{
				ThrowAdminMenu(iClient);
			}
			case MD_ThrowClanHelp:
			{
				ThrowClanHelp(iClient);
			}
			case MD_ThrowClanTagSettings:
			{
				ThrowClanTagSettings(iClient);
			}
		}
	}
}

	//MENUS CALLBACKS

/**
 * Показ списка участников клана игроку
 */
void DBM_ClanMembersListCallback(Handle owner, Handle hndl, const char[] error, int client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[CLANS] Query Fail get clan members: %s", error);
	}
	else
	{
		if(SQL_FetchRow(hndl))
		{
			char playerName[MAX_NAME_LENGTH+5],
				 playerSteam[33],
				 buffer[60];	//Для заголовка и ролей
				 
			int iRole;
			Handle clanMembersMenu = CreateMenu(Clan_ClanMembersSelectMenu);
			FormatEx(buffer, sizeof(buffer), "%T", "m_Members", client);
			SetMenuTitle(clanMembersMenu, buffer);
			do
			{
				SQL_FetchString(hndl, 0, playerName, sizeof(playerName));
				SQL_FetchString(hndl, 1, playerSteam, sizeof(playerSteam));
				iRole = SQL_FetchInt(hndl, 2);
				if(iRole > CLIENT_MEMBER)
				{
					if(iRole == CLIENT_ELDER)
						FormatEx(buffer, sizeof(buffer), "%T", "Elder", client);
					else if(iRole == CLIENT_COLEADER)
						FormatEx(buffer, sizeof(buffer), "%T", "Coleader", client);
					else
						FormatEx(buffer, sizeof(buffer), "%T", "Leader", client);
					Format(playerName, sizeof(playerName), "%s (%s)", playerName, buffer);
				}
				AddMenuItem(clanMembersMenu, playerSteam, playerName);
			} while(SQL_FetchRow(hndl));
			SetMenuExitBackButton(clanMembersMenu, true);
			DisplayMenu(clanMembersMenu, client, 0);
		}
		else
		{
			char print_buff[BUFF_SIZE];
			FormatEx(print_buff, sizeof(print_buff), "%T", "NoPlayers", client);
			CPrintToChat(client, print_buff);
		}
	}
}

/**
 * Показ списка кланов игроку
 */
void DBM_ClansListCallback(Handle owner, Handle hndl, const char[] error, int client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[CLANS] Query Fail get clans: %s", error);
	}
	else
	{
		if(SQL_FetchRow(hndl))
		{
			char clanName[MAX_CLAN_NAME+1],
				 sClanid[15],
				 buffer[60];		//Для заголовка
				 
			Handle clansMenu = CreateMenu(Clan_ClansSelectMenu);
			FormatEx(buffer, sizeof(buffer), "%T", "m_Clans", client);
			SetMenuTitle(clansMenu, buffer);
			do
			{
				SQL_FetchString(hndl, 0, sClanid, sizeof(sClanid));
				SQL_FetchString(hndl, 1, clanName, sizeof(clanName));
				AddMenuItem(clansMenu, sClanid, clanName);
			} while(SQL_FetchRow(hndl));
			SetMenuExitBackButton(clansMenu, true);
			DisplayMenu(clansMenu, client, 0);
		}
		else
		{
			char print_buff[BUFF_SIZE];
			FormatEx(print_buff, sizeof(print_buff), "%T", "NoClans", client);
			CPrintToChat(client, print_buff);
		}
	}
}

/**
 * Показ всех игроков в кланах игроку
 */
void DBM_ClanClientsListCallback(Handle owner, Handle hndl, const char[] error, int client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[CLANS] Query Fail get clan clients: %s", error);
	}
	else
	{
		if(SQL_FetchRow(hndl))
		{
			char playerName[MAX_CLAN_NAME+1],
				 playerid[15],
				 buffer[60];		//Для заголовка
				 
			Handle clanClientsMenu = CreateMenu(Clan_ClanClientsSelectMenu);
			FormatEx(buffer, sizeof(buffer), "%T", "m_Players", client);
			SetMenuTitle(clanClientsMenu, buffer);
			do
			{
				SQL_FetchString(hndl, 0, playerid, sizeof(playerid));
				SQL_FetchString(hndl, 1, playerName, sizeof(playerName));
				AddMenuItem(clanClientsMenu, playerid, playerName);
			} while(SQL_FetchRow(hndl));
			SetMenuExitBackButton(clanClientsMenu, true);
			DisplayMenu(clanClientsMenu, client, 0);
		}
		else
		{
			char print_buff[BUFF_SIZE];
			FormatEx(print_buff, sizeof(print_buff), "%T", "NoPlayers", client);
			CPrintToChat(client, print_buff);
		}
	}
}

/**
 * Показ топа кланов игроку
 */
void DBM_TopClansListCallback(Handle owner, Handle hndl, const char[] error, DataPack dp)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[CLANS] Query Fail get top of clans: %s", error);
	}
	else
	{
		int client = dp.ReadCell();
		Handle topMenu = dp.ReadCell();
		int option = dp.ReadCell();
		if(SQL_FetchRow(hndl))
		{
			char sAmount[60],
				 sClanid[30],
				 clanName[MAX_CLAN_NAME+61];	//Clan name + amount of smth (kills, coins etc)
			int clanid,
				amount,
				curTime = GetTime();	//For SecondsToTime
			do
			{
				clanid = SQL_FetchInt(hndl, 0);
				IntToString(clanid, sClanid, sizeof(sClanid));
				SQL_FetchString(hndl, 1, clanName, sizeof(clanName));
				amount = SQL_FetchInt(hndl, 2);
				if(option == 4 || option == 5)
				{
					SecondsToTime(curTime-amount, sAmount, sizeof(sAmount), client);
				}
				else
				{
					IntToString(amount, sAmount, sizeof(sAmount));
				}
				Format(clanName, sizeof(clanName), "%s (%s)", clanName, sAmount);
				AddMenuItem(topMenu, sClanid, clanName);
			} while(SQL_FetchRow(hndl));
			SetMenuExitBackButton(topMenu, true);
			DisplayMenu(topMenu, client, 0);
		}
		else
		{
			char print_buff[BUFF_SIZE];
			FormatEx(print_buff, sizeof(print_buff), "%T", "NoClans", client);
			CPrintToChat(client, print_buff);
		}
	}
	delete dp;
}

/**
 * Показ статистики игрока
 */
void DBM_PlayerStats(Handle owner, Handle hndl, const char[] error, int client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[CLANS] Query Fail get player stats: %s", error);
	}
	else if(SQL_FetchRow(hndl))
	{
		char stats[400],
			 timeInClan[60],
			 targetName[MAX_NAME_LENGTH+1],
			 targetClanName[MAX_CLAN_NAME+1],
			 status[30],
			 sLastJoin[60];
		int targetID = SQL_FetchInt(hndl, 0); 
		int targetClanid = SQL_FetchInt(hndl, 1);
		int targetRole = SQL_FetchInt(hndl, 2);
		int targetKills = SQL_FetchInt(hndl, 3);
		int targetDeaths = SQL_FetchInt(hndl, 4);
		int targetTimeInClan = SQL_FetchInt(hndl, 5);
		int targetLastJoin = SQL_FetchInt(hndl, 6);
		
		GetClanName(targetClanid, targetClanName, sizeof(targetClanName));
		GetClientNameByID(targetID, targetName, sizeof(targetName));
		if(targetLastJoin != 0)
			FormatTime(sLastJoin, sizeof(sLastJoin), "%d/%m/%Y %H:%M:%S", targetLastJoin);
		else
			FormatEx(sLastJoin, sizeof(sLastJoin), "%T", "LongTimeNoVisit", client);
			
		Handle playerStatsMenu = CreatePanel();
		
		FormatEx(stats, sizeof(stats), "%T", "m_PlayerStatsTitle", client);
		SetPanelTitle(playerStatsMenu, stats);
		FormatEx(stats, sizeof(stats), "%T", "m_Close", client);
		DrawPanelItem(playerStatsMenu, stats, 0);
		SecondsToTime(GetTime() - targetTimeInClan, timeInClan, sizeof(timeInClan), client);
		if(targetRole == CLIENT_LEADER)
			FormatEx(status, sizeof(status), "%T", "Leader", client);
		else if(targetRole == CLIENT_COLEADER)
			FormatEx(status, sizeof(status), "%T", "Coleader", client);
		else if(targetRole == CLIENT_ELDER)
			FormatEx(status, sizeof(status), "%T", "Elder", client);
		else
			FormatEx(status, sizeof(status), "%T", "Member", client);
		FormatEx(stats, sizeof(stats), "%T", "m_PlayerStats", client, targetName, 
															  targetID, targetClanName, 
															  targetClanid, status, 
															  targetKills, targetDeaths, 
															  timeInClan, sLastJoin);
		
		DrawPanelText(playerStatsMenu, stats);
		F_OnPlayerStatsOpened(playerStatsMenu, client);
		SendPanelToClient(playerStatsMenu, client, Clan_PlayerStatsMenu, 0);
	}
}

/**
 * Показ статистики клана, стадия 1
 */	
void DBM_ClanStats(Handle owner, Handle hndl, const char[] error, int client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[CLANS] Query Fail get clan stats: %s", error);
	}
	else if(SQL_FetchRow(hndl))
	{
		char clanName[MAX_CLAN_NAME+1],
			 leaderName[MAX_NAME_LENGTH+1],
			 dateCreation[30];
		SQL_FetchString(hndl, 0, clanName, sizeof(clanName));
		int clanid = SQL_FetchInt(hndl, 1);
		int iType = SQL_FetchInt(hndl, 2);
		SQL_FetchString(hndl, 3, leaderName, sizeof(leaderName));
		int maxMembers = SQL_FetchInt(hndl, 4);
		int kills = SQL_FetchInt(hndl, 5);
		int deaths = SQL_FetchInt(hndl, 6);
		int iTimeCreation = SQL_FetchInt(hndl, 7);
		int coins = SQL_FetchInt(hndl, 8);
		int members = GetClanMembers(clanid);

		FormatTime(dateCreation, sizeof(dateCreation), "%d/%m/%Y %H:%M:%S", iTimeCreation);
		
		Handle clanStatsMenu = CreatePanel();
		char stats[400], 
			 sType[100];
		FormatEx(stats, sizeof(stats), "%T", "m_ClanStatsTitle", client);
		SetPanelTitle(clanStatsMenu, stats);
		FormatEx(stats, sizeof(stats), "%T", "m_SeeMembers", client);
		DrawPanelItem(clanStatsMenu, stats, 0);
		if(GetClanType(clanid) == 1 && ClanClient == -1)
		{
			FormatEx(stats, sizeof(stats), "%T", "m_JoinClan", client);
			DrawPanelItem(clanStatsMenu, stats, 0);
		}
		FormatEx(stats, sizeof(stats), "%T", "m_Close", client);
		DrawPanelItem(clanStatsMenu, stats, 0);
		if(iType == CLAN_CLOSED)
			FormatEx(sType, sizeof(sType), "%T", "m_TypeInvite", client);
		else
			FormatEx(sType, sizeof(sType), "%T", "m_TypeOpen", client);
		
		FormatEx(stats, sizeof(stats), "%T", "m_ClanStats", client, 
		clanName, clanid, sType, leaderName, members, maxMembers,
		kills, deaths, dateCreation, coins);
		DrawPanelText(clanStatsMenu, stats);
			
		F_OnClanStatsOpened(clanStatsMenu, client);
		CLAN_STARGET = clanid;
		SendPanelToClient(clanStatsMenu, client, Clan_ClanStatsMenu, 0);
	}
}

/**
 * Показ меню управления кланом
 */
void DBM_ControlMenuCallback(Handle owner, Handle hndl, const char[] error, int client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[CLANS] Query Fail get player's role for clan control menu: %s", error);
	}
	else
	{
		if(SQL_FetchRow(hndl) && IsClientInGame(client))
		{
			int role = SQL_FetchInt(hndl, 0);
			if(!CanRoleDoAnything(role))
				return;
			Handle clanControlMenu = CreateMenu(Clan_ClanControlSelectMenu);
			char print_buff[80];
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_ClanControl", client);
			SetMenuTitle(clanControlMenu, print_buff);
			if(CanRoleDo(role, PERM_EXPAND))
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "m_ExpandClan", client);
				AddMenuItem(clanControlMenu, "Expand", print_buff);
			}
			if(CanRoleDo(role, PERM_GIVECOINS) && g_bCoinsTransfer)
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "m_TransferCoins", client);
				AddMenuItem(clanControlMenu, "TransferCoins", print_buff);
			}
			if(CanRoleDo(role, PERM_INVITE))
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "m_Invite", client);
				AddMenuItem(clanControlMenu, "Invite", print_buff);
			}
			if(CanRoleDo(role, PERM_KICK))
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "m_KickPlayer", client);
				AddMenuItem(clanControlMenu, "Kick", print_buff);
			}
			if(CanRoleDo(role, PERM_TYPE))
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "m_SetClanType", client);
				AddMenuItem(clanControlMenu, "SetType", print_buff);
			}
			if(CanRoleDo(role, PERM_ROLE))
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "m_ChangeRole", client);
				AddMenuItem(clanControlMenu, "ChangeRole", print_buff);
			}
			if(role == CLIENT_LEADER)
			{
				if(g_bLeaderChange)
				{
					FormatEx(print_buff, sizeof(print_buff), "%T", "m_NewLeader", client);
					AddMenuItem(clanControlMenu, "SelectLeader", print_buff);
				}
				FormatEx(print_buff, sizeof(print_buff), "%T", "m_RenameClan", client);
				AddMenuItem(clanControlMenu, "RenameClan", print_buff);
				FormatEx(print_buff, sizeof(print_buff), "%T", "m_Disband", client);
				AddMenuItem(clanControlMenu, "DeleteClan", print_buff);
			}
			SetMenuExitBackButton(clanControlMenu, true);
			DisplayMenu(clanControlMenu, client, 0);
		}
	}
}

void DBM_ClanMenuCallback(Handle owner, Handle hndl, const char[] error, int client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("[CLANS] Query Fail get player's role for main clan menu: %s", error);
	}
	else
	{
		int clientRole = 0;
		if(SQL_FetchRow(hndl))
		{
			clientRole = SQL_FetchInt(hndl, 0);
		}
		else	//v1.86. Если будет плохо, то переделать
			ClanClient = -1;
		char print_buff[BUFF_SIZE];
	
		Handle playerClanMenu = CreateMenu(Clan_PlayerClanSelectMenu);
		FormatEx(print_buff, sizeof(print_buff), "%T", "m_ClanMenu", client);
		SetMenuTitle(playerClanMenu, print_buff);
		
		AdminId adminid = GetUserAdmin(client);
		bool hasAdminAccess = adminid != INVALID_ADMIN_ID ? GetAdminFlag(adminid, Admin_Root) : false;
		
		if(hasAdminAccess)
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_AdminMenu", client);
			AddMenuItem(playerClanMenu, "AdminMenu", print_buff);
		}
		
		if(ClanClient >= 0)
		{
			if(CanRoleDoAnything(clientRole))
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "m_ClanControl", client);
				AddMenuItem(playerClanMenu, "ClanControl", print_buff);
			}
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_ClanStatsMenu", client);
			AddMenuItem(playerClanMenu, "ClanStats", print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_MyStatsMenu", client);
			AddMenuItem(playerClanMenu, "PlayerStats", print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_Members", client);
			AddMenuItem(playerClanMenu, "Members", print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_WriteToClanChat", client);
			AddMenuItem(playerClanMenu, "ClanChatWrite", print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_Top", client);
			AddMenuItem(playerClanMenu, "TopClans", print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_ClanTagSet", client);
			AddMenuItem(playerClanMenu, "ClanTagSet", print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_ClanHelpCmds", client);
			AddMenuItem(playerClanMenu, "ClanHelp", print_buff);
			if(!(clientRole == CLIENT_LEADER) || (clientRole == CLIENT_LEADER && g_bLeaderLeave))
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "m_LeaveClan", client);
				AddMenuItem(playerClanMenu, "LeaveClan", print_buff);
			}
		}
		else
		{
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_CreateClan", client);
			AddMenuItem(playerClanMenu, "ClanCreate", print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_Top", client);
			AddMenuItem(playerClanMenu, "TopClans", print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_ClanTagSet", client);
			AddMenuItem(playerClanMenu, "ClanTagSet", print_buff);
			FormatEx(print_buff, sizeof(print_buff), "%T", "m_ClanHelpCmds", client);
			AddMenuItem(playerClanMenu, "ClanHelp", print_buff);
		}
		F_OnClanMenuOpened(playerClanMenu, client);
		SetMenuExitButton(playerClanMenu, true);
		DisplayMenu(playerClanMenu, client, 0);
	}
}