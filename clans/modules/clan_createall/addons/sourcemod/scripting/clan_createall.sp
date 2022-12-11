#include <sourcemod>
#include <clans>

public Plugin myinfo = 
{ 
	name = "[CLANS] Everyone can create clan", 
	author = "Dream", 
	description = "everyone can create clan", 
	version = "1.2", 
}

public void OnPluginStart()
{
	if(Clans_AreClansLoaded())
		Clans_OnClansLoaded();
}

public void Clans_OnClansLoaded()
{
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i))
			Clans_SetCreatePerm(i, true);
	}
}

public void Clans_OnClientLoaded(int iClient, int iClientID, int iClanid)
{
	Clans_SetCreatePerm(iClient, true);
}