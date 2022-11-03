/**
 * Calls when clans have been loaded
 *
 * @noreturn
*/
forward void Clans_OnClansLoaded();

/**
 * Calls when client opens admin clan menu
 *
 * @param 		Handle adminClanMenu - adminMenu handle
 * @param 		int iClient - client's index
 * @noreturn
*/
forward void Clans_OnAdminClanMenuOpened(Handle adminClanMenu, int iClient);

/**
 * Calls when client selects menu item in admin clan menu
 *
 * @param 		Handle adminClanMenu - admin clan menu handle
 * @param 		int iClient - client's index
 * @param 		int iOption - selected option
 * @noreturn
*/
forward void Clans_OnAdminClanMenuSelected(Handle adminClanMenu, int iClient, int iOption);

/**
 * Calls when client opens main clan menu
 *
 * @param 		Handle clanMenu - clan menu handle
 * @param 		int iClient - client's index
 * @noreturn
*/
forward void Clans_OnClanMenuOpened(Handle clanMenu, int iClient);

/**
 * Calls when client selects menu item in main clan menu
 *
 * @param 		Handle clanMenu - main clan menu handle
 * @param 		int iClient - client's index
 * @param 		int iOption - selected option
 * @noreturn
*/
forward void Clans_OnClanMenuSelected(Handle clanMenu, int iClient, int iOption);

/**
 * Calls when client opens a clan's stats
 *
 * @param 		Handle clanStatsMenu - clan stats panel handle
 * @param 		int iClient - client's index
 * @param 		int iClanid - clan's index, whose stats is opened
 * @noreturn
*/
forward void Clans_OnClanStatsOpened(Handle clanStatsMenu, int iClient, int iClanid);

/**
 * Calls when client opens a player's stats
 *
 * @param 		Handle playerStatsMenu - player stats panel handle
 * @param 		int iClient - client's index
 * @param 		int targetID - target's id, whose stats is opened
 * @noreturn
*/
forward void Clans_OnPlayerStatsOpened(Handle playerStatsMenu, int iClient, int targetID);

/**
 * Calls when player has been selected in list of players of a clan
 *
 * @param 		Handle clansMenu - menu with all clans
 * @param 		int iClient - client's index, who selected the clan
 * @param 		int iOption - selected option in the menu
 * @noreturn
*/
forward void Clans_OnClanMemberSelectedInList(Handle clansMenu, int iClient, int iOption);

/**
 * Calls when clan has been selected in list of all clans
 *
 * @param 		Handle clansMenu - menu with all clans
 * @param 		int iClient - client's index, who selected the clan
 * @param 		int iOption - selected option in the menu
 *
 * info field - clan id
 * display field - clan name
 *
 * @noreturn
*/
forward void Clans_OnClanSelectedInList(Handle clansMenu, int iClient, int iOption);

/**
 * Calls when clan has been added
 *
 * @param 		int iClanid - clan's index
 * @param 		const char[] sName - clan's name
 * @param 		int iClient - client's index, who created the clan
 * @noreturn
*/
forward void Clans_OnClanAdded(int iClanid, const char[] sName, int iClient);

/**
 * Calls when clan has been deleted
 *
 * @param 		int iClanid - clan's index
 * @noreturn
*/
forward void Clans_OnClanDeleted(int iClanid);

/**
 * Calls when client is loaded
 *
 * @param 		int iClient - client's index
 * @param 		int iClientID - client's id in database
 * @param 		int iClanid - client's clan id
 * @noreturn
*/
forward void Clans_OnClientLoaded(int iClient, int iClientID, int iClanid);

/**
 * Calls when new clan client has been added
 *
 * @param		int iClient - client's index (-1 if player is offline)
 * @param 		int iClientID - client's ID in clan database
 * @param 		int iClanid - client clan's index
 * @noreturn
*/
forward void Clans_OnClientAdded(int iClient, int iClientID, int iClanid);

/**
 * Calls when clan client has been deleted
 *
 * @param		int iClient - client's index (-1 if player is offline)
 * @param 		int iClientID - client's ID in clan database
 * @param 		int iClanid - clan's index, where clan client was
 * @noreturn
*/
forward void Clans_OnClientDeleted(int iClient, int iClientID, int iClanid);

/**
 * Calls when clan is going to get coins
 *
 * @param 		int iClanid - clan's index
 * @param		int& coins - coins to be given
 * @param		bool givenByAdmin - flag if admin gave coins to clan
 * @noreturn
*/
forward void Clans_OnClanCoinsGive(int iClanid, int& coins, bool givenByAdmin);

/**
 * Calls when top menu was opened
 *
 * @param Handle topMenu - top menu handle
 * @param int iClient - client's index
 */
forward void Clans_OnTopMenuOpened(Handle topMenu, int iClient);

/**
 * Calls when any item was selected in the top menu
 *
 * @param Handle topMenu - top menu handle
 * @param int iClient - client's index
 * @param int iOption - selected option
 */
forward void Clans_OnTopMenuSelected(Handle topMenu, int iClient, int iOption);

/**
 * Calls when clan control menu was opened
 *
 * @param Handle clanControlMenu - clan control menu handle
 * @param int iClient - client's index
 */
forward void Clans_OnClanControlMenuOpened(Handle clanControlMenu, int iClient);

/**
 * Calls when any item was selected in the clan control menu
 *
 * @param Handle clanControlMenu - clan control menu handle
 * @param int iClient - client's index
 * @param int iOption - selected option
 */
forward void Clans_OnClanControlMenuSelected(Handle clanControlMenu, int iClient, int iOption);

/**
 * Calls when clan is to be created
 *
 * @param int iLeader - leader's index
 * @param const char[] clanName - clan's name
 * @param int iCreator - creator's index
 *
 * @return Plugin_Continue to allow to create the clan, any other value to not
 */
forward Action Clans_PreClanCreate(int iLeader, const char[] clanName, int iCreator);

/**
 * Calls when clan is to be renamed
 *
 * @param int iClanId - clan's index
 * @param const char[] oldClanName - old clan's name
 * @param const char[] newClanName - new clan's name
 * @param int iWhoRename - index of the one who rename the clan
 *
 * @return Plugin_Continue to allow to create the clan, any other value to not
 */
forward Action Clans_PreClanRename(int iClanId, const char[] oldClanName, const char[] newClanName, int iWhoRename);

/**
 * Sends approve request for handle which is used for extra option in clan control menu
 *
 * @param Handle hPlugin - handle of the plugin to be approved
 * 
 * @return true to approve (return GetMyHandle() == hPlugin;)
 */
forward bool Clans_ApproveHandle(Handle hPlugin);