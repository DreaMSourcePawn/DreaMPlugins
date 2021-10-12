#include <sourcemod>
#include <clans>

Handle 	g_hCoinsByKill,
		g_hCoinsByDeath;

int		g_iCoinsByKill,
		g_iCoinsByDeath;

public Plugin myinfo = 
{ 
	name = "[Clans] Coins by kill", 
	author = "Dream", 
	description = "Give/take coins when player kills/dies", 
	version = "1.1", 
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
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
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
	return Plugin_Continue;
}