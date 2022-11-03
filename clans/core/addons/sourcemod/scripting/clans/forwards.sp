//Forwards below
GlobalForward	g_hACMOpened, 				//Clans_OnAdminClanMenuOpened
				g_hACMSelected,				//Clans_OnAdminClanMenuSelected
				g_hCMOpened, 				//Clans_OnClanMenuOpened
				g_hCMSelected,				//Clans_OnClanMenuSelected
				g_hCSOpened, 				//Clans_OnClanStatsOpened
				g_hPSOpened, 				//Clans_OnPlayerStatsOpened
				g_hClanAdded,				//Clans_OnClanAdded
				g_hClanDeleted,				//Clans_OnClanDeleted
				g_hClientAdded,				//Clans_OnClientAdded
				g_hOnClanClientLoaded,		//Clans_OnClientLoaded v1.83
				g_hClientDeleted,			//Clans_OnClientDeleted
				g_hClanSelectedInList,		//Clans_OnClanSelectedInList	v1.8
				g_hOnClanCoinsGive,			//Clans_OnClanCoinsGive	v1.8
				g_hOnTopOpened,				//Clans_OnTopMenuOpened	v1.87
				g_hOnTopSelected,			//Clans_OnTopMenuSelected
				g_hOnClanControlOpened,		//Clans_OnClanControlMenuOpened	v1.88
				g_hOnClanControlSelected,	//Clans_OnClanControlMenuSelected v1.88
				g_hPreClanCreate,			//Clans_PreClanCreate v1.88
				g_hPreClanRename,			//Clans_PreClanRename v1.88
				g_hApproveHandle;			//Clans_ApproveHandle v1.88

void CreateForwards()
{
	g_hACMOpened = CreateGlobalForward("Clans_OnAdminClanMenuOpened", ET_Ignore, Param_Any, Param_Cell);
	g_hACMSelected = CreateGlobalForward("Clans_OnAdminClanMenuSelected", ET_Ignore, Param_Any, Param_Cell, Param_Cell);
	g_hCMOpened = CreateGlobalForward("Clans_OnClanMenuOpened", ET_Ignore, Param_Any, Param_Cell);
	g_hCMSelected = CreateGlobalForward("Clans_OnClanMenuSelected", ET_Ignore, Param_Any, Param_Cell, Param_Cell);
	g_hCSOpened = CreateGlobalForward("Clans_OnClanStatsOpened", ET_Ignore, Param_Any, Param_Cell, Param_Cell);
	g_hPSOpened = CreateGlobalForward("Clans_OnPlayerStatsOpened", ET_Ignore, Param_Any, Param_Cell, Param_Cell);
	g_hClanAdded = CreateGlobalForward("Clans_OnClanAdded", ET_Ignore, Param_Cell, Param_String, Param_Cell);
	g_hClanDeleted = CreateGlobalForward("Clans_OnClanDeleted", ET_Ignore, Param_Cell);
	g_hClientAdded = CreateGlobalForward("Clans_OnClientAdded", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hClientDeleted = CreateGlobalForward("Clans_OnClientDeleted", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hClanSelectedInList = CreateGlobalForward("Clans_OnClanSelectedInList", ET_Ignore, Param_Any, Param_Cell, Param_Cell);
	g_hOnClanCoinsGive = CreateGlobalForward("Clans_OnClanCoinsGive", ET_Ignore, Param_Cell, Param_CellByRef, Param_Cell);
	g_hOnClanClientLoaded = CreateGlobalForward("Clans_OnClientLoaded", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hOnTopOpened = CreateGlobalForward("Clans_OnTopMenuOpened", ET_Ignore, Param_Any, Param_Cell);
	g_hOnTopSelected = CreateGlobalForward("Clans_OnTopMenuSelected", ET_Ignore, Param_Any, Param_Cell, Param_Cell);
	//v1.88 below
	g_hOnClanControlOpened = CreateGlobalForward("Clans_OnClanControlMenuOpened", ET_Ignore, Param_Any, Param_Cell);						//v1.88
	g_hOnClanControlSelected = CreateGlobalForward("Clans_OnClanControlMenuSelected", ET_Ignore, Param_Any, Param_Cell, Param_Cell);		//v1.88
	g_hPreClanCreate = CreateGlobalForward("Clans_PreClanCreate", ET_Hook, Param_Cell, Param_String, Param_Cell);							//v1.88
	g_hPreClanRename = CreateGlobalForward("Clans_PreClanRename", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell);				//v1.88
	g_hApproveHandle = CreateGlobalForward("Clans_ApproveHandle", ET_Hook, Param_Cell);
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
 * @param int clanid - clan, whose stats is opened
 */
void F_OnClanStatsOpened(Handle clanStatsMenu, int client, int clanid)
{
	Call_StartForward(g_hCSOpened);
	Call_PushCell(clanStatsMenu);
	Call_PushCell(client);
	Call_PushCell(clanid);
	Call_Finish();
}

/**
 * Starts Clans_OnPlayerStatsOpened forward
 *
 * @param Handle playerStatsMenu - player stats menu
 * @param int client - who opened the menu
 * @param int targetID - whose stats is opened
 */
void F_OnPlayerStatsOpened(Handle playerStatsMenu, int client, int targetID)
{
	Call_StartForward(g_hPSOpened);
	Call_PushCell(playerStatsMenu);
	Call_PushCell(client);
	Call_PushCell(targetID);
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
	return Plugin_Stop;
}

/**
 * Starts Clans_OnClanAdded forward
 *
 * @param int clanid - clan's id
 * @param const char[] sName - clan's name
 * @param int createBy - client, who created the clan
 */
void F_OnClanAdded(int clanid, const char[] sName, int createBy)
{
	Call_StartForward(g_hClanAdded);
	Call_PushCell(clanid);
	Call_PushString(sName);
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

/**
 * Starts Clans_OnTopMenuOpened forward
 *
 * @param Handle topMenu - top menu handle
 * @param int iClient - client's index
 */
void F_OnTopMenuOpened(Handle topMenu, int iClient)
{
	Call_StartForward(g_hOnTopOpened);
	Call_PushCell(topMenu);
	Call_PushCell(iClient);
	Call_Finish();
}

/**
 * Starts Clans_OnTopMenuSelected forward
 *
 * @param Handle topMenu - top menu handle
 * @param int iClient - client's index
 * @param int iOption - selected option
 */
void F_OnTopMenuSelected(Handle topMenu, int iClient, int iOption)
{
	Call_StartForward(g_hOnTopSelected);
	Call_PushCell(topMenu);
	Call_PushCell(iClient);
	Call_PushCell(iOption);
	Call_Finish();
}

/**
 * Starts Clans_OnClanControlMenuOpened forward
 *
 * @param Handle clanControlMenu - clan control menu handle
 * @param int iClient - client's index
 */
void F_OnClanControlMenuOpened(Handle clanControlMenu, int iClient)
{
	Call_StartForward(g_hOnClanControlOpened);
	Call_PushCell(clanControlMenu);
	Call_PushCell(iClient);
	Call_Finish();
}

/**
 * Starts Clans_OnClanControlMenuSelected forward
 *
 * @param Handle clanControlMenu - clan control menu handle
 * @param int iClient - client's index
 * @param int iOption - selected option
 */
void F_OnClanControlMenuSelected(Handle clanControlMenu, int iClient, int iOption)
{
	Call_StartForward(g_hOnClanControlSelected);
	Call_PushCell(clanControlMenu);
	Call_PushCell(iClient);
	Call_PushCell(iOption);
	Call_Finish();
}

/**
 * Starts Clans_PreClanCreate forward
 *
 * @param int iLeader - leader's index
 * @param const char[] clanName - clan's name
 * @param int iCreator - creator's index (if leader create it by himself/herself createdBy is -1)
 */
bool F_PreClanCreate(int iLeader, const char[] clanName, int iCreator)
{
	Action aCreate = Plugin_Continue;
	Call_StartForward(g_hPreClanCreate);
	Call_PushCell(iLeader);
	Call_PushString(clanName);
	Call_PushCell(iCreator);
	Call_Finish(aCreate);
	return aCreate == Plugin_Continue;
}

/**
 * Starts Clans_PreClanCreate forward
 *
 * @param int iClanId - clan's index
 * @param const char[] oldClanName - old clan's name
 * @param const char[] newClanName - new clan's name
 * @param int iWhoRename - index of the one who rename the clan
 */
bool F_PreClanRename(int iClanId, const char[] oldClanName, const char[] newClanName, int iWhoRename)
{
	Action aRename = Plugin_Continue;
	Call_StartForward(g_hPreClanRename);
	Call_PushCell(iClanId);
	Call_PushString(oldClanName);
	Call_PushString(newClanName);
	Call_PushCell(iWhoRename);
	Call_Finish(aRename);
	return aRename == Plugin_Continue;
}

/**
 * Sends approve request for handle (Clans_ApproveHandle)
 *
 * @param Handle hPlugin - handle of the plugin to be approved
 * 
 * @return true on approved, false otherwise
 */
bool F_ApproveHandle(Handle hPlugin)
{
	bool bApprove = false;
	Call_StartForward(g_hApproveHandle);
	Call_PushCell(hPlugin);
	Call_Finish(bApprove);
	return bApprove;
}