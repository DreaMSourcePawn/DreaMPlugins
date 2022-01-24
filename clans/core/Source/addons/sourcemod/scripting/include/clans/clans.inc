/**
 * Check if clan is valid
 *
 * @param 		clanid - clan's index
 * @return 		true - valid, false - otherwise
 */
native bool Clans_IsClanValid(int clanid);

/**
 * Get name of clan
 *
 * @param		clanid - clan's index
 * @param 		buffer - buffer string to keep the name
 * @param 		bufflen - length of buffer string (MAX_NAME_LENGTH+1)
 * @noreturn
 */
native void Clans_GetClanName(int clanid, char[] buffer, int bufflen);

/**
 * Get clan's number of kills
 *
 * @param		clanid - clan's index
 * @return		number of clan kills
 */
native int Clans_GetClanKills(int clanid);

/**
 * Set number of kills in clan
 *
 * @param		clanid - clan's index
 * @param 		kills - clan kills to set
 * @return		true if successed, false otherwise
 */
native bool Clans_SetClanKills(int clanid, int kills);

/**
 * Get clan's number of deaths
 *
 * @param		clanid - clan's index
 * @return		number of clan deaths
 */
native int Clans_GetClanDeaths(int clanid);

/**
 * Set number of deaths in clan
 *
 * @param		clanid - clan's index
 * @param 		deaths - clan coins to set
 * @return		true if successed, false otherwise
 */
native bool Clans_SetClanDeaths(int clanid, int deaths);

/**
 * Get clan's number of coins
 *
 * @param		clanid - clan's index
 * @return		number of clan coins
 */
native int Clans_GetClanCoins(int clanid);

/**
 * Give coins to clan
 *
 * @param		clanid - clan's index
 * @param 		coins - clan coins to give
 * @param		givenByAdmin - flag if admin gave coins to clan
 * @return		true if successed, false otherwise
 */
native void Clans_GiveClanCoins(int clanid, int coins, bool givenByAdmin = false);

/**
 * Set number of coins in clan
 *
 * @param		clanid - clan's index
 * @param 		coins - clan coins to set
 * @return		true if successed, false otherwise
 */
native bool Clans_SetClanCoins(int clanid, int coins);

/**
 * Get number of players in clan
 *
 * @param		clanid - clan's index
 * @return		number of members in clan
 */
native int Clans_GetClanMembers(int clanid);

/**
 * Get all online clients in some clan
 *
 * @param int clanid - clan, whose members are looking for
 * @param ArrayList memberList - list of online players in some clan
 *
 * @noreturn
 */
native void Clans_GetClanMembersOnline(int clanid, ArrayList memberList);

/**
 * Get max number of players in clan
 *
 * @param		clanid - clan's index
 * @return		max number of members in clan
 */
native int Clans_GetClanMaxMembers(int clanid);

/**
 * Set max number of players in clan
 *
 * @param		clanid - clan's index
 * @param 		maxMembers - max number of players in clan to set
 * @return		true if successed, false otherwise
 */
native bool Clans_SetClanMaxMembers(int clanid, int maxMembers);

/**
 * Get type of the clan
 *
 * @param		clanid - clan's index
 * @return		clan's type
 */
native int Clans_GetClanType(int clanid);

/**
 * Set type of the clan
 *
 * @param		clanid - clan's index
 * @param 		type - new type of the clan
 * @noreturn		
 */
native void Clans_SetClanType(int clanid, int type);

/**
 * Show clan's stats to client
 *
 * @param		client - client's index, who will see the stats
 * @param		clanid - clan's id, whose stats will be shown
 * @return		true if successed, false otherwise
 */
native bool Clans_ShowClanInfo(int client, int clanid);

/**
 * Show clan members to client
 *
 * @param		client - client's index, who will see members in clan
 * @param 		clanid - clan's id, whose members will be shown
 * @param 		showFlags - flags to members to show: 
 *							1st bit - client will be shown in menu, 
 *							2nd bit - don't show clients whose role is above client's one
 * info field in menu item - steam id of clan members
 * display field in menu item - member's name
 * @return		true if successed, false otherwise
 */
native bool Clans_ShowClanMembers(int client, int clanid, int showFlags);

/**
 * Show list of clans to client
 *
 * @param		client - client's index, who will see clans
 * @param bool showClientClan - flag if client's clan will be shown in menu
 *
 * info field in menu item - clanid
 * display field in menu item - clan's name
 *
 * @return		true if successed, false otherwise
 */
native bool Clans_ShowClanList(int client, bool showClientClan);

/**
 * Reset a clan info (kills, deaths, coins)
 *
 * @param		int iClanid - clan's id in the database
 * @param		bool bResetPlayersInClan - flag if the players in the clan will be reset (kills, deaths -> 0)
 *
 * @noreturn
 */
native void Clans_ResetClan(int iClanid, bool bResetPlayersInClan = false);