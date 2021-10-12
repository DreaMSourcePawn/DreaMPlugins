#include <sourcemod>
#include <cstrike>
#include <clans>
#include <clans_shop>

new Handle:g_hFile;
static char buffer[1024];

public Plugin:myinfo = 
{ 
	name = "[CShop] Map restrict", 
	author = "Dream", 
	description = "Disable shop at some maps", 
	version = "1.0", 
} 

public OnPluginStart() 
{
	g_hFile = OpenFile("cfg/clans/cshop_map_restrict.txt", "r", false, NULL_STRING);
	ReadFileString(g_hFile, buffer, sizeof(buffer), -1);
}

public OnMapStart()
{
	char mapname[50];
	GetCurrentMap(mapname, sizeof(mapname));
	mapname[strlen(mapname)] = ';';
	mapname[strlen(mapname)] = '\0';
	if(StrContains(buffer, mapname) != -1)
		CShop_SetShopStatus(false);
	else
		CShop_SetShopStatus(true);
}