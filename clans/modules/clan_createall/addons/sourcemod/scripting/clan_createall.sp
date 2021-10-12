#include <sourcemod>
#include <clans>

public Plugin myinfo = 
{ 
	name = "[CLANS] Everyone can create clan", 
	author = "Dream", 
	description = "everyone can create clan", 
	version = "1.0", 
}

public void OnClientPostAdminCheck(int client)
{
	CreateTimer(1.0, GivePermission, client, TIMER_FLAG_NO_MAPCHANGE);
}

Action GivePermission(Handle timer, int client)
{
	Clans_SetCreatePerm(client, true);
}