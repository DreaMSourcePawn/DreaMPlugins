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
 * @param 		int client - client's index
 * @noreturn
*/
forward void Clans_OnAdminClanMenuOpened(Handle adminClanMenu, int client);

/**
 * Calls when client selects menu item in admin clan menu
 *
 * @param 		Handle adminClanMenu - admin clan menu handle
 * @param 		int client - client's index
 * @param 		int option - selected option
 * @noreturn
*/
forward void Clans_OnAdminClanMenuSelected(Handle adminClanMenu, int client, int option);

/**
 * Calls when client opens main clan menu
 *
 * @param 		Handle clanMenu - clan menu handle
 * @param 		int client - client's index
 * @noreturn
*/
forward void Clans_OnClanMenuOpened(Handle clanMenu, int client);

/**
 * Calls when client selects menu item in main clan menu
 *
 * @param 		Handle clanMenu - main clan menu handle
 * @param 		int client - client's index
 * @param 		int option - selected option
 * @noreturn
*/
forward void Clans_OnClanMenuSelected(Handle clanMenu, int client, int option);

/**
 * Calls when client opens a clan's stats
 *
 * @param 		Handle clanStatsMenu - clan stats menu handle
 * @param 		int client - client's index
 * @noreturn
*/
forward void Clans_OnClanStatsOpened(Handle clanStatsMenu, int client);

/**
 * Calls when client opens a player's stats
 *
 * @param 		Handle playerStatsMenu - player stats menu handle
 * @param 		int client - client's index
 * @noreturn
*/
forward void Clans_OnPlayerStatsOpened(Handle playerStatsMenu, int client);

/**
 * Calls when player has been selected in list of players of a clan
 *
 * @param 		Handle clansMenu - menu with all clans
 * @param 		int client - client's index, who selected the clan
 * @param 		int option - selected option in the menu
 * @noreturn
*/
forward void Clans_OnClanMemberSelectedInList(Handle clansMenu, int client, int option);

/**
 * Calls when clan has been selected in list of all clans
 *
 * @param 		Handle clansMenu - menu with all clans
 * @param 		int client - client's index, who selected the clan
 * @param 		int option - selected option in the menu
 *
 * info field - clan id
 * display field - clan name
 *
 * @noreturn
*/
forward void Clans_OnClanSelectedInList(Handle clansMenu, int client, int option);

/**
 * Calls when clan has been added
 *
 * @param 		int clanid - clan's index
 * @param 		int client - client's index, who created the clan
 * @noreturn
*/
forward void Clans_OnClanAdded(int clanid, int client);

/**
 * Calls when clan has been deleted
 *
 * @param 		int clanid - clan's index
 * @noreturn
*/
forward void Clans_OnClanDeleted(int clanid);

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
 * @param 		int clanid - clan's index
 * @param		int& coins - coins to be given
 * @param		bool givenByAdmin - flag if admin gave coins to clan
 * @noreturn
*/
forward void Clans_OnClanCoinsGive(int clanid, int& coins, bool givenByAdmin);