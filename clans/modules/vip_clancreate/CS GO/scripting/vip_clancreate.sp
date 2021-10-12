#include <sourcemod>
#include <vip_core>
#include <clans>
#include <csgo_colors>

static const char g_sFeature[] = "ClanCreate";

#define MAX_CLAN_NAME 10

Handle	g_hTempGive;      //Can a player with temporary VIP create a clan
bool	g_bTempGive;

bool creatingClan[MAXPLAYERS+1];

public Plugin:myinfo = 
{ 
	name = "[VIP] Clan create", 
	author = "Dream", 
	description = "Add permission for VIPs to create a clan", 
	version = "1.2", 
} 

public OnPluginStart()
{
	g_hTempGive = CreateConVar("sm_vip_clancreatetemp", "1", "Can a player with temporary VIP create a clan. 1 - yes, 0 - no");
	g_bTempGive = GetConVarBool(g_hTempGive);
	HookConVarChange(g_hTempGive, OnConVarChange);

	AutoExecConfig(true, "vip_clancreatetemp", "vip");
	
	LoadTranslations("clans.phrases");
	
	AddCommandListener(SayHook, "say");
	
	if(VIP_IsVIPLoaded())
		VIP_OnVIPLoaded();
}

public void OnConVarChange(Handle hCvar, const char[] oldValue, const char[] newValue)
{
	if(hCvar == g_hTempGive) 
	{
		g_bTempGive = StringToInt(newValue) == 1;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(VIP_IsClientVIP(i) && (g_bTempGive || (!g_bTempGive && VIP_GetClientAccessTime(i) == 0)))
					Clans_SetCreatePerm(i, true);
				else
					Clans_SetCreatePerm(i, false);
			}
		}
	}
}

public OnPluginEnd() 
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

public VIP_OnVIPLoaded()
{
	if(!VIP_IsValidFeature(g_sFeature))
		VIP_RegisterFeature(g_sFeature, INT, SELECTABLE, OnClanCreateUsed);
}

public void OnClientPostAdminCheck(int client)
{
	CreateTimer(0.5, RemovePermission, client, TIMER_FLAG_NO_MAPCHANGE);
	creatingClan[client] = false;
}

public void VIP_OnVIPClientLoaded(int client)
{
	if(VIP_GetClientFeatureInt(client, g_sFeature) == 1 && (g_bTempGive || (!g_bTempGive && VIP_GetClientAccessTime(client) == 0)))
		CreateTimer(3.0, GivePermission, client, TIMER_FLAG_NO_MAPCHANGE);
}

public void VIP_OnVIPClientRemoved(int client, const char[] reason, int admin)
{
	CreateTimer(0.5, RemovePermission, client, TIMER_FLAG_NO_MAPCHANGE);
}

bool OnClanCreateUsed(int client, const char[] szFeature)
{
	if(Clans_GetOnlineClientClan(client) != -1)
	{
		CGOPrintToChat(client, "%T", "c_YouAreAlreadyInClan", client);
		return true;
	}
	if(!Clans_GetCreatePerm(client))
		Clans_SetCreatePerm(client, true);
	CGOPrintToChat(client, "%T", "c_RenameClan", client);
	creatingClan[client] = true;
	return false;
}

Action GivePermission(Handle timer, int client)
{
	if(IsClientInGame(client))
		Clans_SetCreatePerm(client, true);
}

Action RemovePermission(Handle timer, int client)
{
	if(IsClientInGame(client))
		Clans_SetCreatePerm(client, false);
}

Action SayHook(int client, const char[] command, int args)
{
	if(client && IsClientInGame(client) && creatingClan[client])
	{
		char buffer[50];
		GetCmdArg(1, buffer, sizeof(buffer));
		TrimString(buffer);
		if(!strcmp(buffer, "отмена") || !strcmp(buffer, "cancel"))
		{
			creatingClan[client] = false;
			return Plugin_Handled;
		}
		if(strlen(buffer) < 1 || strlen(buffer) > MAX_CLAN_NAME)
		{
			char print_buff[200];
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_WrongClanName", client, MAX_CLAN_NAME);
			CGOPrintToChat(client, print_buff);
			creatingClan[client] = false;
			return Plugin_Handled;
		}
		FakeClientCommand(client, "sm_cclan \"%s\"", buffer);
		creatingClan[client] = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}