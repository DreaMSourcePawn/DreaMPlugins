#include <sourcemod>
#include <clans>
#include <cstrike>

ConVar 	g_cvCoinsByKill,
		g_cvCoinsByDeath,
		g_cvMode;

int		g_iCoinsByKill,
		g_iCoinsByDeath,
		g_iMode;

#define MODE_EVERYROUND 1

public Plugin myinfo = 
{ 
	name = "[Clans] Coins by kill", 
	author = "Dream", 
	description = "Give/take coins when player kills/dies", 
	version = "1.4", 
} 

int		g_iClientCoinsGained[MAXPLAYERS+1],	// То, сколько мы должны будем начислить клану игрока
		g_iClientClan[MAXPLAYERS+1];		// Хранит старый клан на случай, если игрок выйдет/сменит клан

public void OnPluginStart() 
{
	g_cvCoinsByKill = CreateConVar("sm_clans_coinsbykill", "1", "Number of coins gained by killing.");

	g_cvCoinsByDeath = CreateConVar("sm_clans_coinsbydeath", "1", "Number of coins taken by death.");

	g_cvMode = CreateConVar("sm_clans_coinsbk_mode", "0", "0 - Save gained coins by player after he/she disconnect, 1 - save coins every round.", 0, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "clans_coinsbykill", "clans");
	
	HookEvent("player_death", Death);

	for(int i = 1; i <= MaxClients; ++i)
	{
		g_iClientCoinsGained[i] = 0;
		g_iClientClan[i] = CLAN_INVALID_CLAN;
	}
	
	if(Clans_AreClansLoaded())
		Clans_OnClansLoaded();
}

public void OnConfigsExecuted()
{
	g_iCoinsByKill = g_cvCoinsByKill.IntValue;
	HookConVarChange(g_cvCoinsByKill, OnConVarChange);

	g_iCoinsByDeath = g_cvCoinsByDeath.IntValue;
	HookConVarChange(g_cvCoinsByDeath, OnConVarChange);

	g_iMode = g_cvMode.IntValue;
	HookConVarChange(g_cvMode, OnConVarChange);
}

public Action CS_OnTerminateRound(float& delay, CSRoundEndReason& reason)
{
	if(g_iMode == MODE_EVERYROUND)
	{
		for(int i = 1; i <= MaxClients; ++i)
		{
			if(IsClientInGame(i) && g_iClientClan[i] != CLAN_INVALID_CLAN)
			{
				ChangeCoins(g_iClientClan[i], g_iClientCoinsGained[i]);
				g_iClientCoinsGained[i] = 0;
			}
		}
	}
}

public void Clans_OnClansLoaded()
{
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && g_iClientClan[i] != CLAN_INVALID_CLAN)
		{
			ChangeCoins(g_iClientClan[i], g_iClientCoinsGained[i]);
		}
	}
}

void OnConVarChange(ConVar hCvar, const char[] oldValue, const char[] newValue)
{
	if(hCvar == g_cvCoinsByKill) 
		g_iCoinsByKill = g_cvCoinsByKill.IntValue;
	else if(hCvar == g_cvCoinsByDeath) 
		g_iCoinsByDeath = g_cvCoinsByDeath.IntValue;
	else if(hCvar == g_cvMode) 
		g_iMode = g_cvMode.IntValue;
}

public void Clans_OnClientLoaded(int iClient, int iClientID, int iClanid)
{
	g_iClientClan[iClient] = iClanid;
	g_iClientCoinsGained[iClient] = 0;
}

public void Clans_OnClientAdded(int iClient, int iClientID, int iClanid)
{
	if(g_iClientClan[iClient] != CLAN_INVALID_CLAN)
		ChangeCoins(g_iClientClan[iClient], g_iClientCoinsGained[iClient]);
	g_iClientClan[iClient] = iClanid;
}

public void Clans_OnClientDeleted(int iClient, int iClientID, int iClanid)
{
	if(iClient != -1)
	{
		if(g_iClientClan[iClient] != CLAN_INVALID_CLAN)
			ChangeCoins(g_iClientClan[iClient], g_iClientCoinsGained[iClient]);
		g_iClientClan[iClient] = CLAN_INVALID_CLAN;
	}
}

public void OnClientDisconnect(int iClient)
{
	if(g_iClientClan[iClient] != CLAN_INVALID_CLAN)
		ChangeCoins(g_iClientClan[iClient], g_iClientCoinsGained[iClient]);

	g_iClientClan[iClient] = g_iClientCoinsGained[iClient] = CLAN_INVALID_CLAN;
}

Action Death(Handle event, const char[] name, bool db)
{
	int iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	int iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(g_iClientClan[iVictim] == g_iClientClan[iAttacker])
		return;
	g_iClientCoinsGained[iVictim] -= g_iCoinsByDeath;
	g_iClientCoinsGained[iAttacker] += g_iCoinsByKill;
}

void ChangeCoins(int iClanid, int iCoinsToGive)
{
	if(iCoinsToGive != 0)
	{
		Clans_GiveClanCoins(iClanid, iCoinsToGive);
	}
}