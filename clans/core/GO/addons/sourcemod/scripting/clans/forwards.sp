void CreateForwards()
{
	g_hACMOpened = CreateGlobalForward("Clans_OnAdminClanMenuOpened", ET_Ignore, Param_Any, Param_Cell);
	g_hACMSelected = CreateGlobalForward("Clans_OnAdminClanMenuSelected", ET_Ignore, Param_Any, Param_Cell, Param_Cell);
	g_hCMOpened = CreateGlobalForward("Clans_OnClanMenuOpened", ET_Ignore, Param_Any, Param_Cell);
	g_hCMSelected = CreateGlobalForward("Clans_OnClanMenuSelected", ET_Ignore, Param_Any, Param_Cell, Param_Cell);
	g_hCSOpened = CreateGlobalForward("Clans_OnClanStatsOpened", ET_Ignore, Param_Any, Param_Cell);
	g_hPSOpened = CreateGlobalForward("Clans_OnPlayerStatsOpened", ET_Ignore, Param_Any, Param_Cell);
	g_hClansLoaded = CreateGlobalForward("Clans_OnClansLoaded", ET_Ignore);
	g_hClanAdded = CreateGlobalForward("Clans_OnClanAdded", ET_Ignore, Param_Cell, Param_Cell);
	g_hClanDeleted = CreateGlobalForward("Clans_OnClanDeleted", ET_Ignore, Param_Cell);
	g_hClientAdded = CreateGlobalForward("Clans_OnClientAdded", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hClientDeleted = CreateGlobalForward("Clans_OnClientDeleted", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hClanSelectedInList = CreateGlobalForward("Clans_OnClanSelectedInList", ET_Ignore, Param_Any, Param_Cell, Param_Cell);
	g_hOnClanCoinsGive = CreateGlobalForward("Clans_OnClanCoinsGive", ET_Ignore, Param_Cell, Param_CellByRef, Param_Cell);
	g_hOnClanClientLoaded = CreateGlobalForward("Clans_OnClientLoaded", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
}

/**
 * Starts Clans_OnAdminClanMenuOpened forward
 *
 * @param Handle adminClansMenu - admin menu
 * @param int client - who opened the menu
 */
void F_OnAdminClanMenuOpened(Handle adminClansMenu, int client)
{
	Call_StartForward(g_hACMOpened);
	Call_PushCell(adminClansMenu);
	Call_PushCell(client);
	Call_Finish();
}

/**
 * Starts Clans_OnAdminClanMenuSelected forward
 *
 * @param Handle adminMenu - admin menu
 * @param int client - who opened the menu
 * @param int option - selected option
 */
void F_OnAdminClanMenuSelected(Handle adminClansMenu, int client, int option)
{
	Call_StartForward(g_hACMSelected);
	Call_PushCell(adminClansMenu);
	Call_PushCell(client);
	Call_PushCell(option);
	Call_Finish();
}

/**
 * Starts Clans_OnClanMenuOpened forward
 *
 * @param Handle playerClanMenu - clan menu
 * @param int client - who opened the menu
 */
void F_OnClanMenuOpened(Handle playerClanMenu, int client)
{
	Call_StartForward(g_hCMOpened);
	Call_PushCell(playerClanMenu);
	Call_PushCell(client);
	Call_Finish();
}

/**
 * Starts Clans_OnClanMenuSelected forward
 *
 * @param Handle playerClanMenu - clan menu
 * @param int client - who opened the menu
 * @param int option - selected option
 */
void F_OnClanMenuSelected(Handle playerClanMenu, int client, int option)
{
	Call_StartForward(g_hCMSelected);
	Call_PushCell(playerClanMenu);
	Call_PushCell(client);
	Call_PushCell(option);
	Call_Finish();
}

/**
 * Starts Clans_OnClanStatsOpened forward
 *
 * @param Handle clanStatsMenu - clan stats menu
 * @param int client - who opened the menu
 */
void F_OnClanStatsOpened(Handle clanStatsMenu, int client)
{
	Call_StartForward(g_hCSOpened);
	Call_PushCell(clanStatsMenu);
	Call_PushCell(client);
	Call_Finish();
}

/**
 * Starts Clans_OnPlayerStatsOpened forward
 *
 * @param Handle playerStatsMenu - player stats menu
 * @param int client - who opened the menu
 */
void F_OnPlayerStatsOpened(Handle playerStatsMenu, int client)
{
	Call_StartForward(g_hPSOpened);
	Call_PushCell(playerStatsMenu);
	Call_PushCell(client);
	Call_Finish();
}

/**
 * Starts Clans_OnClansLoaded forward
 */
void F_OnClansLoaded()
{
	/*Call_StartForward(g_hClansLoaded);
	Call_Finish();*/
	CreateTimer(2.0, FT_OnClansLoaded, 0, TIMER_FLAG_NO_MAPCHANGE);
}

Action FT_OnClansLoaded(Handle timer)
{
	Handle plugin;
	Handle thisplugin = GetMyHandle();
	Handle plugIter = GetPluginIterator();
	while (MorePlugins(plugIter))
	{
		plugin = ReadPlugin(plugIter);
		if (plugin != thisplugin && GetPluginStatus(plugin) == Plugin_Running)
		{
			Function func = GetFunctionByName(plugin, "Clans_OnClansLoaded");
			if (func != INVALID_FUNCTION)
			{
				Call_StartFunction(plugin, func);
				Call_Finish();
			}
		}
	}
	delete plugIter;
	delete plugin;
	delete thisplugin;
}

/**
 * Starts Clans_OnClanAdded forward
 *
 * @param int clanid - clan's id
 * @param int createBy - client, who created the clan
 */
void F_OnClanAdded(int clanid, int createBy)
{
	Call_StartForward(g_hClanAdded);
	Call_PushCell(clanid);
	Call_PushCell(createBy);
	Call_Finish();
}

/**
 * Starts Clans_OnClanDeleted forward
 *
 * @param int clanid - clan's id
 */
void F_OnClanDeleted(int clanid)
{
	Call_StartForward(g_hClanDeleted);
	Call_PushCell(clanid);
	Call_Finish();
}

/**
 * Starts Clans_OnClientAdded forward
 *
 * @param		int iClient - client's index (-1 if player is offline)
 * @param 		int iClientID - client's ID in clan database
 * @param 		int iClanid - client clan's index
 * @noreturn
 */
void F_OnClientAdded(int iClient, int iClientID, int iClanid)
{
	Call_StartForward(g_hClientAdded);
	Call_PushCell(iClient);
	Call_PushCell(iClientID);
	Call_PushCell(iClanid);
	Call_Finish();
}

/**
 * Starts Clans_OnClientDeleted forward
 *
 * @param		int iClient - client's index (-1 if player is offline)
 * @param 		int iClientID - client's ID in clan database
 * @param 		int iClanid - client clan's index
 */
void F_OnClientDeleted(int iClient, int iClientID, int iClanid)
{
	Call_StartForward(g_hClientDeleted);
	Call_PushCell(iClient);
	Call_PushCell(iClientID);
	Call_PushCell(iClanid);
	Call_Finish();
}

/**
 * Starts Clans_OnClanSelectedInList forward
 *
 * @param Handle clansMenu - list with clans menu
 * @param int client - who opened the menu
 * @param int option - selected option
 */
void F_OnClanSelectedInList(Handle clansMenu, int client, int option)
{
	Call_StartForward(g_hClanSelectedInList);
	Call_PushCell(clansMenu);
	Call_PushCell(client);
	Call_PushCell(option);
	Call_Finish();
}

/**
 * Starts Clans_OnClanCoinsGive forward
 *
 * @param int clanid - clan's id
 * @param int& coins - coins to be given
 * @param bool givenByAdmin - flag if admin gave coins to clan
 */
void F_OnClanCoinsGive(int clanid, int& coins, bool givenByAdmin)
{
	Call_StartForward(g_hOnClanCoinsGive);
	Call_PushCell(clanid);
	Call_PushCellRef(coins);
	Call_PushCell(givenByAdmin);
	Call_Finish();
}

/**
 * Starts Clans_OnClientLoaded forward
 *
 * @param int iClient - client's index
 * @param int iClientID - client's id in database
 * @param int iClanid - client's clan id
 */
void F_OnClientLoaded(int iClient, int iClientID, int iClanid)
{
	Call_StartForward(g_hOnClanClientLoaded);
	Call_PushCell(iClient);
	Call_PushCell(iClientID);
	Call_PushCell(iClanid);
	Call_Finish();
}