public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	//Clients
	CreateNative("Clans_CreateClientWithData", Native_CreateClientWithData);
	CreateNative("Clans_UseClanTag", Native_UseClanTag);
	CreateNative("Clans_IsClanLeader", Native_IsClanLeader);
	CreateNative("Clans_IsClanCoLeader", Native_IsClanCoLeader);
	CreateNative("Clans_IsClanElder", Native_IsClanElder);
	CreateNative("Clans_GetClientRole", Native_GetClientRole);
	CreateNative("Clans_SetClientRole", Native_SetClientRole);
	CreateNative("Clans_GetClientID", Native_GetClientID);
	CreateNative("Clans_GetClientClan", Native_GetClientClan);
	CreateNative("Clans_SetClientClan", Native_SetClientClan);
	CreateNative("Clans_GetOnlineClientClan", Native_GetOnlineClientClan);
	CreateNative("Clans_GetClientKills", Native_GetClientKills);
	CreateNative("Clans_SetClientKills", Native_SetClientKills);
	CreateNative("Clans_GetClientDeaths", Native_GetClientDeaths);
	CreateNative("Clans_SetClientDeaths", Native_SetClientDeaths);
	CreateNative("Clans_AreInDifferentClans", Native_AreInDifferentClans);
	CreateNative("Clans_IsClientInClan", Native_IsClientInClan);
	CreateNative("Clans_ShowPlayerInfo", Native_ShowPlayerInfo);
	CreateNative("Clans_GetCreatePerm", Native_GetCreatePerm);
	CreateNative("Clans_SetCreatePerm", Native_SetCreatePerm);
	CreateNative("Clans_GetClientTimeInClan", Native_GetClientTimeInClan);
	CreateNative("Clans_GetClientTimeToCreateClan", Native_GetClientTimeToCreateClan);
	CreateNative("Clans_GetClientClanName", Native_GetClientClanName);
	CreateNative("Clans_GetClanMembersOnline", Native_GetClanMembersOnline);
	CreateNative("Clans_ResetClient", Native_ResetClient);
	//Clans
	CreateNative("Clans_IsClanValid", Native_IsClanValid);
	CreateNative("Clans_GetClanName", Native_GetClanName);
	CreateNative("Clans_GetClanKills", Native_GetClanKills);
	CreateNative("Clans_SetClanKills", Native_SetClanKills);
	CreateNative("Clans_GetClanDeaths", Native_GetClanDeaths);
	CreateNative("Clans_SetClanDeaths", Native_SetClanDeaths);
	CreateNative("Clans_GetClanCoins", Native_GetClanCoins);
	CreateNative("Clans_GiveClanCoins", Native_GiveClanCoins);
	CreateNative("Clans_SetClanCoins", Native_SetClanCoins);
	CreateNative("Clans_GetClanMembers", Native_GetClanMembers);
	CreateNative("Clans_GetClanMaxMembers", Native_GetClanMaxMembers);
	CreateNative("Clans_SetClanMaxMembers", Native_SetClanMaxMembers);
	CreateNative("Clans_GetClanType", Native_GetClanType);
	CreateNative("Clans_SetClanType", Native_SetClanType);
	CreateNative("Clans_ShowClanInfo", Native_ShowClanInfo);
	CreateNative("Clans_ShowClanMembers", Native_ShowClanMembers);
	CreateNative("Clans_ShowClanList", Native_ShowClanList);
	CreateNative("Clans_ResetClan", Native_ResetClan);
	//Other
	CreateNative("Clans_GetClanDatabase", Native_GetClanDatabase);
	CreateNative("Clans_IsMySQLDatabase", Native_IsMySQLDatabase);
	CreateNative("Clans_AreClansLoaded", Native_AreClansLoaded);
	//Forwards
	CreateForwards();
	RegPluginLibrary("ClanSystem_DreaM");
	return APLRes_Success;
}

//=============================== CLIENTS ===============================//
public any Native_UseClanTag(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return WantToChangeTag(client);
}

public any Native_IsClanLeader(Handle plugin, int numParams)
{
	int clientID = GetNativeCell(1);
	bool bFromDB = GetNativeCell(2);
	return IsClientClanLeaderByID(clientID, bFromDB);
}

public any Native_IsClanCoLeader(Handle plugin, int numParams)
{
	int clientID = GetNativeCell(1);
	bool bFromDB = GetNativeCell(2);
	return IsClientClanCoLeaderByID(clientID, bFromDB);
}

public any Native_IsClanElder(Handle plugin, int numParams)
{
	int clientID = GetNativeCell(1);
	bool bFromDB = GetNativeCell(2);
	return IsClientClanElderByID(clientID, bFromDB);
}

public int Native_GetClientRole(Handle plugin, int numParams)
{
	int clientID = GetNativeCell(1);
	bool bFromDB = GetNativeCell(2);
	return GetClientRoleByID(clientID, bFromDB);
}

public int Native_SetClientRole(Handle plugin, int numParams)
{
	if(numParams != 2)
		return -1;
	int clientID = GetNativeCell(1);
	int role = GetNativeCell(2);
	SetClientRoleByID(clientID, role);
	return 0;
}

public int Native_GetClientID(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return ClanClient;
	}
	return -1;
}

public int Native_GetClientClan(Handle plugin, int numParams)
{
	int clientID = GetNativeCell(1);
	bool bFromDB = GetNativeCell(2);
	if(clientID >= 0)
	{
		return GetClientClanByID(clientID, bFromDB);
	}
	return -1;
}

public int Native_SetClientClan(Handle plugin, int numParams)
{
	if(numParams != 2)
		return -1;
	int clientID = GetNativeCell(1);
	int clanid = GetNativeCell(2);
	DB_SetClientClan(clientID, clanid);
	return 0;
}

public int Native_GetOnlineClientClan(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool bFromDB = GetNativeCell(2);
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || ClanClient < 0)
		return -1;
	return GetClientClanByID(ClanClient, bFromDB);
}

public int Native_GetClientKills(Handle plugin, int numParams)
{
	int clientID = GetNativeCell(1);
	bool bFromDB = GetNativeCell(2);
	return GetClientKillsInClanByID(clientID, bFromDB);
}

public any Native_SetClientKills(Handle plugin, int numParams)
{
	int clientID = GetNativeCell(1);
	int kills = GetNativeCell(2);
	return SetClientKillsInClanByID(clientID, kills);
}

public int Native_GetClientDeaths(Handle plugin, int numParams)
{
	int clientID = GetNativeCell(1);
	bool bFromDB = GetNativeCell(2);
	return GetClientDeathsInClanByID(clientID, bFromDB);
}

public any Native_SetClientDeaths(Handle plugin, int numParams)
{
	int clientID = GetNativeCell(1);
	int deaths = GetNativeCell(2);
	return SetClientDeathsInClanByID(clientID, deaths);
}

public any Native_AreInDifferentClans(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int other = GetNativeCell(2);
	if(client > 0 && client <= MaxClients && other > 0 && other <= MaxClients && IsClientInGame(client) && IsClientInGame(other))
	{
		return AreClientsInDifferentClans(client, other);
	}
	return false;
}

public any Native_IsClientInClan(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return IsClientInClan(client);
}

public any Native_ShowPlayerInfo(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int otherID = GetNativeCell(2);
	if(otherID >= 0)
	{
		return ThrowPlayerStatsToClient(client, otherID);
	}
	return false;
}

public any Native_GetCreatePerm(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return createClan[client];
	}
	return false;
}

public int Native_SetCreatePerm(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool status = GetNativeCell(2);
	if(client > 0 && client <= MaxClients)
	{
		createClan[client] = status;
	}
	return 0;
}

public int Native_CreateClientWithData(Handle plugin, int numParams)
{
	if(numParams != 4)
		return -1;
	char name[MAX_NAME_LENGTH], auth[33];
	GetNativeString(1, name, sizeof(name));
	GetNativeString(2, auth, sizeof(auth));
	int clanid = GetNativeCell(3);
	int role = GetNativeCell(4);
	DB_CreateClientByData(name, auth, clanid, role);
	return 0;
}

public int Native_GetClientTimeInClan(Handle plugin, int numParams)
{
	if(numParams != 1)
		return -1;
	int clientID = GetNativeCell(1);
	int time = GetClientTimeInClanByID(clientID);
	PrintToChatAll("Time: %d", time);
	return GetTime()-GetClientTimeInClanByID(clientID);
}

public int Native_GetClanMembersOnline(Handle plugin, int numParams)
{
	if(numParams != 2)
		return -1;
	char clanName[MAX_CLAN_NAME];
	int clanid = GetNativeCell(1);
	if(clanid < 0)
		return -1;
	ArrayList memberList = GetNativeCell(2);
	GetClanName(clanid, clanName, sizeof(clanName));
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], clanName))
			memberList.Push(i);
	}
	return 0;
}

public int Native_GetClientTimeToCreateClan(Handle plugin, int iParams)
{
	int iClient = GetNativeCell(1);
	if(iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient))
		return -1;
	int iTimeOfCD = GetTime() - GetLastClanCreationTime(iClient);
	return g_iClanCreationCD-iTimeOfCD/60;
}

public int Native_GetClientClanName(Handle plugin, int iParams)
{
	int iClient = GetNativeCell(1);
	int iBufSize = GetNativeCell(3);
	SetNativeString(2, g_sClientData[iClient][CLIENT_CLANNAME], iBufSize);
	return 0;
}

public int Native_ResetClient(Handle plugin, int iParams)
{
	int iClientID = GetNativeCell(1);
	ResetClient(iClientID);
	return 0;
}
  //=============================== CLANS ===============================//
public any Native_IsClanValid(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	return IsClanValid(clanid);
}

public int Native_GetClanName(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	char clanName[MAX_CLAN_NAME+1];
	int len = GetNativeCell(3);
	int maxSize = sizeof(clanName) > len ? len : sizeof(clanName);
	GetClanName(clanid, clanName, maxSize);
	SetNativeString(2, clanName, maxSize);
	return 0;
}

public int Native_GetClanCoins(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	return GetClanCoins(clanid);
}

public int Native_GiveClanCoins(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	int coins = GetNativeCell(2);
	bool givenByAdmin = GetNativeCell(3);
	GiveClanCoins(clanid, coins, givenByAdmin);
	return 0;
}

public any Native_SetClanCoins(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	int coins = GetNativeCell(2);
	return SetClanCoins(clanid, coins);
}

public any Native_ShowClanInfo(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int clanid = GetNativeCell(2);
	return ThrowClanStatsToClient(client, clanid);
}

public any Native_ShowClanMembers(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int clanid = GetNativeCell(2);
	int showFlags = GetNativeCell(3);
	return ThrowClanMembersToClient(client, clanid, showFlags);
}

public any Native_ShowClanList(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool showClientClan = GetNativeCell(2);
	return ThrowClansToClient(client, showClientClan);
}

public int Native_GetClanKills(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	return GetClanKills(clanid);
}

public any Native_SetClanKills(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	int kills = GetNativeCell(2);
	return SetClanKills(clanid, kills);
}

public int Native_GetClanDeaths(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	return GetClanDeaths(clanid);
}

public any Native_SetClanDeaths(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	int kills = GetNativeCell(2);
	return SetClanDeaths(clanid, kills);
}

public int Native_GetClanMembers(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	return GetClanMembers(clanid);
}

public int Native_GetClanMaxMembers(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	return GetClanMaxMembers(clanid);
}

public any Native_SetClanMaxMembers(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	int maxmembers = GetNativeCell(2);
	return SetClanMaxMembers(clanid, maxmembers);
}

public int Native_GetClanType(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	return GetClanType(clanid);
}

public int Native_SetClanType(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	int type = GetNativeCell(2);
	if(type < CLAN_CLOSED)
		type = CLAN_CLOSED;
	else if(type > CLAN_OPEN)
		type = CLAN_OPEN
	SetClanType(clanid, type);
	return 0;
}

public int Native_ResetClan(Handle plugin, int iParams)
{
	int iClanid = GetNativeCell(1);
	bool bResetPlayers = GetNativeCell(2);
	ResetClan(iClanid, bResetPlayers);
	return 0;
}

//Other
public any Native_GetClanDatabase(Handle plugin, int numParams)
{
	return CloneHandle(g_hClansDB, plugin);
}

public any Native_IsMySQLDatabase(Handle plugin, int numParams)
{
	return mySQL;
}

public any Native_AreClansLoaded(Handle plugin, int numParams)
{
	return g_bClansLoaded;
}