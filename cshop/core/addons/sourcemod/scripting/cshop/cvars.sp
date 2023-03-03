#define SERVER_ID g_cvServerId.IntValue
#define IsShopManager(%1) (%1 & g_cvRequiredRole.IntValue)

ConVar g_cvServerId,
       g_cvRequiredRole;

void InitConVars()
{
    g_cvServerId = CreateConVar("cshop_serverid", "-1", "Server's id in database");
    g_cvRequiredRole = CreateConVar("cshop_manager_role", "4", "Clan role to do action in shop");

    AutoExecConfig(true, "settings", "cshop");
}