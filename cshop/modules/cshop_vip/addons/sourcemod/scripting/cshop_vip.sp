#include <sourcemod>
#include <vip_core>
#include <clans>
#include <clans_shop>

#pragma tabsize 0

#define ITEM_TYPE TYPE_ONEUSE
#define ITEM_CATEGORY "vips"

KeyValues g_kvVIPs;

Handle g_hClansDB = null;   //Database

Handle g_hChangeGroup;      //Should a player's VIP group be changed
bool   g_bChangeGroup,
		reg = false;

public Plugin:myinfo = 
{ 
	name = "[CSHOP] Buy VIP", 
	author = "Dream", 
	description = "Add opportunity to buy VIP for a clan", 
	version = "1.0", 
} 

public OnPluginStart()
{
    g_kvVIPs = CreateKeyValues("vips");
    g_kvVIPs.ImportFromFile("cfg/clans/cshop_vip_list.txt");

    g_hChangeGroup = CreateConVar("sm_cshop_vipschange", "0", "Flag if a player's VIP group should be changed");
	g_bChangeGroup = GetConVarBool(g_hChangeGroup);
	HookConVarChange(g_hChangeGroup, OnConVarChange);

    AutoExecConfig(true, "cshop_vips", "clans");

    char DB_Error[256], query[200];
    g_hClansDB = SQL_Connect("clans", true, DB_Error, sizeof(DB_Error));
    if(g_hClansDB == null)
	{
		SetFailState("[CLANSVIPS] Unable to connect to database (%s)", DB_Error);
		return;
	}

    Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `players_tovip` (`auth` TEXT, `vip_group` TEXT, `time` INTEGER)");
    SQL_TQuery(g_hClansDB, SQL_LogError, query, 0);
	
	if(CShop_IsShopLoaded())
		CShopLoaded();
}

public void OnPluginEnd()
{
    int id;
    g_kvVIPs.Rewind();
    if(g_kvVIPs.GotoFirstSubKey())
    {
        do
        {
            id = g_kvVIPs.GetNum("id", -1);
            CShop_UnregisterItem(id)
        } while(g_kvVIPs.GotoNextKey());
    }
    delete g_kvVIPs;
}

public void OnConVarChange(Handle hCvar, const char[] oldValue, const char[] newValue)
{
	if(hCvar == g_hChangeGroup) 
		g_bChangeGroup = StringToInt(newValue) == 1;
}

public void CShopLoaded()
{
	if(!reg)
	{
		reg = true;
		int price, sellprice;
		char name[70], desc[70];
		g_kvVIPs.Rewind();
		if(g_kvVIPs.GotoFirstSubKey())
		{
			do
			{
				g_kvVIPs.GetSectionName(name, sizeof(name));
				price = g_kvVIPs.GetNum("price", -1);
				sellprice = g_kvVIPs.GetNum("sellprice", -1);
				g_kvVIPs.GetString("desc", desc, sizeof(desc));
				g_kvVIPs.SetNum("id", CShop_RegisterItem(ITEM_CATEGORY, name, desc, price, sellprice, ITEM_INFINITE, ITEM_TYPE));

			} while(g_kvVIPs.GotoNextKey());
		}
		g_kvVIPs.Rewind();
	}
}

public void CShop_OnItemUsed(int client, int itemid)
{
    bool stop = false;
    char name[70];
    int time;
    g_kvVIPs.Rewind();
    if(g_kvVIPs.GotoFirstSubKey())
    {
        do
        {
            if(itemid == g_kvVIPs.GetNum("id", -1))
            {
                stop = true;
                g_kvVIPs.GetString("name", name, sizeof(name));
                time = g_kvVIPs.GetNum("time", 0);
                OnVipUse(Clans_GetOnlineClientClan(client), name, time);
                CreateTimer(3.0, Timer_CheckPlayers, _, TIMER_FLAG_NO_MAPCHANGE);
            }
        } while(!stop && g_kvVIPs.GotoNextKey());
    }
}

public void OnClientPostAdminCheck(int client)
{
    CheckPlayer(client);
}

void OnVipUse(int clanid, char[] nameOfVipGroup, int time)
{
    char query[200];
	DataPack dp = CreateDataPack();
    dp.WriteString(nameOfVipGroup);
    dp.WriteCell(time);
    Format(query, sizeof(query), "SELECT `player_steam` FROM `players_table` WHERE `player_clanid` = '%d'", clanid);
    SQL_TQuery(g_hClansDB, SQL_GetPlayersCallback, query, dp);
}

Action Timer_CheckPlayers(Handle timer)
{
    for(int i = 1; i <= MaxClients; i++)
        CheckPlayer(i);
}

void CheckPlayer(int client)
{
    if(client > 0 && client <= MaxClients && IsClientInGame(client))
    {
        char auth[33], query[200];
        GetClientAuthId(client, AuthId_Steam3, auth, sizeof(auth));
        Format(query, sizeof(query), "SELECT * FROM `players_tovip` WHERE `auth` = '%s'", auth);
        SQL_TQuery(g_hClansDB, SQL_PlayerFoundCallBack, query, client);
    }
}

//SQL CallBacks
void SQL_GetPlayersCallback(Handle owner, Handle hndl, const char[] error, DataPack dp)   //nameOfVipGroup, time
{
	if(hndl == INVALID_HANDLE) LogError("[CSHOPVIPS] Query Fail load clients: %s", error);
	else
	{
	    char auth[33], query[150], nameOfVipGroup[70];
        int time;
        dp.Reset();
        dp.ReadString(nameOfVipGroup, sizeof(nameOfVipGroup));
        time = dp.ReadCell();
        while(SQL_FetchRow(hndl))
        {
            SQL_FetchString(hndl, 0, auth, sizeof(auth));
            FormatEx(query, sizeof(query), "INSERT INTO `players_tovip` VALUES ('%s', '%s', '%d')", auth, nameOfVipGroup, time);
            SQL_TQuery(g_hClansDB, SQL_LogError, query, 0);
        }
	}
	delete dp;
}

void SQL_LogError(Handle owner, Handle hndl, const char[] error, int anyvar)
{
	if(error[0] != 0)
	{
        LogError("[CLANSVIP] Query failed: %s", error);
	}
}

void SQL_PlayerFoundCallBack(Handle owner, Handle hndl, const char[] error, int client)
{
	if(hndl == INVALID_HANDLE) LogError("[CSHOPVIPS] Query Fail find player: %s", error);
	else
	{
        char nameOfVipGroup[70], playerGroup[70];
        char query[100], auth[33];
        int time;
        if(SQL_FetchRow(hndl))
        {
            SQL_FetchString(hndl, 1, nameOfVipGroup, sizeof(nameOfVipGroup));
            time = SQL_FetchInt(hndl, 2);
            GetClientAuthId(client, AuthId_Steam3, auth, sizeof(auth));
            if(VIP_IsClientVIP(client))
            {
                VIP_GetClientVIPGroup(client, playerGroup, sizeof(playerGroup));
                if(!strcmp(nameOfVipGroup, playerGroup))
                {
                    int ptime = VIP_GetClientAccessTime(client);
                    if(ptime > 0)
                        VIP_SetClientAccessTime(client, time+ptime, true);
                }
                else if(g_bChangeGroup && VIP_IsValidVIPGroup(nameOfVipGroup))
				{
                    VIP_RemoveClientVIP2(0, client, true, false);
					VIP_GiveClientVIP(0, client, time, nameOfVipGroup, true);
				}
            }
            else
            {
                if(VIP_IsValidVIPGroup(nameOfVipGroup))
                    VIP_GiveClientVIP(0, client, time, nameOfVipGroup, true);
            }
            FormatEx(query, sizeof(query), "DELETE FROM `players_tovip` WHERE `auth` = '%s'", auth);
            SQL_TQuery(g_hClansDB, SQL_LogError, query, 0);
        }
    }
}