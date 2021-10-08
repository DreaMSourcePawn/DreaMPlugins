/**
 * Create a clan client with data
 *
 * @param		char[] name - client's name
 * @param		char[] auth - client's auth (U:)
 * @param		int clanid - clan, to which client will be added
 * @param		int role - client's role
 * @noreturn
 */
native void Clans_CreateClientWithData(const char[] name, const char[] auth, int clanid, int role);

/**
 * Get client's id in database
 *
 * @param		client - client's index
 * @return		client's id in database
 */
native int Clans_GetClientID(int client);

/**
 * Check if client is clan leader
 *
 * @param		clientID - client's id in database
 * @return		true - player is clan leader, false - otherwise
 */
native bool Clans_IsClanLeader(int clientID);

/**
 * Check if client is clan co-leader
 *
 * @param		clientID - client's id in database
 * @return		true - player is clan co-leader, false - otherwise
 */
native bool Clans_IsClanCoLeader(int clientID);

/**
 * Check if client is clan elder
 *
 * @param		clientID - client's id in database
 * @return		true - player is clan elder, false - otherwise
 */
native bool Clans_IsClanElder(int clientID);

/**
 * Get client's role in his/her clan
 *
 * @param		clientID - client's id in database
 * @return		client's role
 */
native int Clans_GetClientRole(int clientID);

/**
 * Set client's role in his/her clan
 *
 * @param		int clientID - client's id in database
 * @param		int role - client's new role
 * @noreturn
 */
native void Clans_SetClientRole(int clientID, int role);

/**
 * Get client clan's id in database
 *
 * @param		clientID - client's id in database
 * @return		client clan's id in database
 */
native int Clans_GetClientClan(int clientID);

/**
 * Set client clan's id in database
 *
 * @param		clientID - client's id in database
 * @param		int clanid - new client clan's id
 * @noreturn
 */
native int Clans_SetClientClan(int clientID, int clanid);

/**
 * Get online client clan's id in database
 *
 * @param		clientID - client's id at server
 * @return		client clan's id in database, -1 if client isn't in any clan
 */
native int Clans_GetOnlineClientClan(int client);

/**
 * Get client's number of kills in current clan
 *
 * @param		clientID - client's id in database
 * @return		client's number of kills
 */
native int Clans_GetClientKills(int clientID);

/**
 * Set client's kills in clan
 *
 * @param		clientID - client's id in database
 * @param		kills - number of kills to set
 * @return 		true if successed, false otherwise
 */
native bool Clans_SetClientKills(int clientID, int kills);

/**
 * Get client's number of deaths in current clan
 *
 * @param		clientID - client's id in database
 * @return		client's number of deaths
 */
native int Clans_GetClientDeaths(int clientID);

/**
 * Set client's deaths in clan
 *
 * @param		clientID - client's id in database
 * @param		deaths - number of deaths to set
 * @return 		true if successed, false otherwise
 */
native bool Clans_SetClientDeaths(int clientID, int deaths);

/**
 * Check if online clients are in different clans
 *
 * @param		client - first client's index
 * @param		other - other client's index
 * @return		true if they are in different clans, false otherwise
 */
native bool Clans_AreInDifferentClans(int client, int other);

/**
 * Check if online client is in any clan
 *
 * @param		client - client's index
 * @return		true if client's in clan, false otherwise
 */
native bool Clans_IsClientInClan(int client);

/**
 * Show player's stats to client
 *
 * @param		client - client's index, who will see the stats
 * @param		otherID - player's id in database, whose stats will be seen
 * @return		true if successed, false otherwise
 */
native bool Clans_ShowPlayerInfo(int client, int otherID);

/**
 * Get a permission to create a clan for client
 *
 * @param		client - client's index, who will see the stats
 * @param		bool status - true to give permission, false to take it
 * @return		true if client has the permission, false otherwise
 */
native bool Clans_GetCreatePerm(int client);

/**
 * Set a permission to create a clan for client
 *
 * @param		client - client's index, who will see the stats
 * @param		bool status - true to give permission, false to take it
 * @noreturn
 */
native void Clans_SetCreatePerm(int client, bool status);

/**
 * Get client's time in clan
 *
 * @param		clientID - client's index in database
 * @return		client's time in clan in seconds, -1 if client isn't in any clan
 */
native bool Clans_GetClientTimeInClan(int clientID);

/**
 * Get all online clients in some clan
 *
 * @param int clanid - clan, whose members are looking for
 * @param ArrayList memberList - list of online players in some clan
 *
 * @noreturn
 */
native void Clans_GetClanMembersOnline(int clanid, ArrayList memberList);