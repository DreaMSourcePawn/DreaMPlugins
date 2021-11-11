#include <sourcemod>
#include <clans>

Database g_DB = null;

Handle 	g_hCoinsByKill,
		g_hCoinsByDeath;

int		g_iCoinsByKill,
		g_iCoinsByDeath;

public Plugin myinfo = 
{ 
	name = "[Clans] Coins by kill", 
	author = "Dream", 
	description = "Give/take coins when player kills/dies", 
	version = "1.2", 
} 

public void OnPluginStart() 
{
	g_hCoinsByKill = CreateConVar("sm_clans_coinsbykill", "1", "Number of coins gained by killing.");
	g_iCoinsByKill = GetConVarInt(g_hCoinsByKill);
	HookConVarChange(g_hCoinsByKill, OnConVarChange);

	g_hCoinsByDeath = CreateConVar("sm_clans_coinsbydeath", "1", "Number of coins taken by death.");
	g_iCoinsByDeath = GetConVarInt(g_hCoinsByDeath);
	HookConVarChange(g_hCoinsByDeath, OnConVarChange);
	
	AutoExecConfig(true, "clans_coinsbykill", "clans");
	
	HookEvent("player_death", Death);
	
	if(Clans_AreClansLoaded())
		Clans_OnClansLoaded();
}

public void OnPluginEnd()
{
	UnhookEvent("player_death", Death);
}

public void Clans_OnClansLoaded()
{
	g_DB = Clans_GetClanDatabase();
	if(g_DB == null)
	{
		LogError("[CLANS COINS] Failed to get database. Use 1.1 give system");
	}
}

public void OnConVarChange(Handle hCvar, const char[] oldValue, const char[] newValue)
{
	if(hCvar == g_hCoinsByKill) 
		g_iCoinsByKill = StringToInt(newValue);
	else if(hCvar == g_hCoinsByDeath) 
		g_iCoinsByDeath = StringToInt(newValue);
}

public Action Death(Handle event, const char[] name, bool db)
{
	int iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!Clans_AreInDifferentClans(iVictim, iAttacker))
		return Plugin_Continue;
	DataPack dp = CreateDataPack();
	if(g_DB != null)
	{
		bool bExecuteToDB = false;
		int iVictimDB = Clans_GetClientID(iVictim);
		int iAttackerDB = Clans_GetClientID(iAttacker);
		Transaction txn = SQL_CreateTransaction();
		char sQuery[300];
		if(iAttackerDB != -1)
		{
			FormatEx(sQuery, sizeof(sQuery), "UPDATE `clans_table` SET `clan_coins` = `clan_coins` + '%d' WHERE `clan_id` = (SELECT `player_clanid` FROM `players_table` WHERE `player_id` = '%d')", g_iCoinsByKill, iAttackerDB);
			txn.AddQuery(sQuery);
			bExecuteToDB = true;
		}
		if(iVictimDB != -1)
		{
			FormatEx(sQuery, sizeof(sQuery), "UPDATE `clans_table` SET `clan_coins` = (CASE WHEN `clan_coins`-'%d' < 0 THEN 0 ELSE `clan_coins`-'%d' END) WHERE `clan_id` = (SELECT `player_clanid` FROM `players_table` WHERE `player_id` = '%d')", g_iCoinsByDeath, g_iCoinsByDeath, iVictimDB);
			txn.AddQuery(sQuery);
			bExecuteToDB = true;
		}
		if(bExecuteToDB)
			SQL_ExecuteTransaction(g_DB, txn, INVALID_FUNCTION, OnTXNFailure);
	}
	else
	{
		dp.WriteCell(iVictim);
		dp.WriteCell(iAttacker);
		dp.Reset();
		CreateTimer(0.1, GiveTakeCoins, dp, TIMER_DATA_HNDL_CLOSE);
	}
	return Plugin_Continue;
}

Action GiveTakeCoins(Handle timer, DataPack dp)
{
	int victim = dp.ReadCell();
	int attacker = dp.ReadCell();
	int victimClan = Clans_GetOnlineClientClan(victim);
	int attackerClan = Clans_GetOnlineClientClan(attacker);
	
	if (victimClan != attackerClan && (victimClan != -1 || attackerClan != -1))
	{
		int coins;
		if(victimClan != -1)
		{
			coins = Clans_GetClanCoins(victimClan);
			if(coins - g_iCoinsByDeath >= 0)
				Clans_GiveClanCoins(victimClan, -g_iCoinsByDeath);
		}
		if(attackerClan != -1)
		{
			coins = Clans_GetClanCoins(attackerClan);
			if(coins + g_iCoinsByKill >= 0)
				Clans_GiveClanCoins(attackerClan, g_iCoinsByKill);
		}
	}
}

void OnTXNFailure(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("[CLANS COINS] Failed on %d/%d query: %s", failIndex, numQueries, error);
}