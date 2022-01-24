#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clans>
#include <csgo_colors>		//CS GO
//#include <morecolors>		//CSS
//#include <colors>			//For CSS v34

#pragma newdecls required

#define ClanClient playerID[client]	//Айди игрока в базе данных
#define BUFF_SIZE 600
#define LOG_SIZE 512
#define PLUGIN_VERSION "1.86"
//================================================
//Flag for CSS v34
bool g_bCSS34 = false;
//Are clan system loaded
bool g_bClansLoaded = false;

/** Client data (int)
 *	0 - Clan ID
 *	1 - Role
 *	2 - Kills
 *	3 - Deaths
 *	4 - time of joining
 *
 * Используется для создания игрока. Но роль используется и позже, чтобы снизить нагрузку на базу во время выставления клан тега
 * Кэшируется убийства/смерти, чтобы снизить кол-во запросов в базу. Роль все еще берется с базы v1.86
 */
int g_iClientData[MAXPLAYERS+1][5];

/** Client's data difference since loading
 * 0 - Kills
 * 1 - Deaths
 */
#define CD_DIFF_KILLS 0
#define CD_DIFF_DEATHS 1
int g_iClientDiffData[MAXPLAYERS+1][2];

/** Client data (String)
 *	0 - Name
 *	1 - Steam ID
 *	2 - Clan name
 */
char g_sClientData[MAXPLAYERS+1][3][MAX_NAME_LENGTH+1];

/**
 * Leaders' id, who invite player, and invitation's time
 */
int invitedBy[MAXPLAYERS+1][2];

/**
 * Players' id in DB
 */
int playerID[MAXPLAYERS+1];

/**
 * Mode of watching members in clan
 * Also contains id of player to kick or to select as a leader (it is after choosing 1 or 2 mode)
 *	0 - See stats
 *	1 - Kick player
 *	2 - Select as a leader
 * 	3 - Transfer coins
 *	4 - Change role
 *		id of clan/members
 */
#define CLAN_STYPE clan_SelectMode[client][0]		//Mode of watching members
#define CLAN_STARGET clan_SelectMode[client][1]		//Target selected
int clan_SelectMode[MAXPLAYERS+1][2];

bool renameClan[MAXPLAYERS+1]; // Флаг переименования клана
bool createClan[MAXPLAYERS+1]; // Флаг возможности создавать клан
bool creatingClan[MAXPLAYERS+1];	//Флаг, что игрок создает сейчас клан (1.7)
bool writeToClanChat[MAXPLAYERS+1];	//Флаг, что игрок будет писать в клановый чат (1.7)

/**
 * Admin modes of watching clans/members in clans. Contains type and ID
 *	Types [0]:
 *		0 - Select clan to set coins
 *		1 - Reset client
 *		2 - Reset clan
 *		3 - Delete client
 *		4 - Delete clan
 *		5 - Create clan
 *		6 - Change leader
 *		7 - Rename clan
 *		8 - Change slots
 *		9 - Change type
 *		10 - Change role
 *	ID [1] - contains clan's / player ID in database
 */
#define ADMIN_STYPE admin_SelectMode[client][0]			//Mode of admin watching
#define ADMIN_STARGET admin_SelectMode[client][1]		//Target selected
int admin_SelectMode[MAXPLAYERS+1][2];

//===================== CVARS =====================//
Handle 	g_hExpandingCost, 		//Price of expansion
		g_hMaxClanMembers, 		//Maximum number of players in any clan
		g_hExpandValue, 		//Number of slots clan gets buying the expansion
		g_hStartSlotsInClan, 	//Start number of slots for clans
		g_hLogs,				//Logs of players' actions
		g_hLogFlags,			//Log flags
		g_hLogExpireDays,		//How many days a recond can be in DB
		g_hSetClanTag,			//2 - set clan tag by force, 1 - set clan tag if player is in clan, 0 - set clan tag if player wants it (1.82)
		g_hLeaderChange,		//Flag: can leader set a new leader
		g_hCoinsTransfer,		//Flag: can clan transfer coins to other clan
		g_hLeaderLeave,			//Flag: can leader leave his/her clan
		g_hClanCreationCD,		//Time in minutes when player can create a new clan again (1.7)
		g_hRenameClanPrice,		//Clan rename price (1.7)
		g_hClanChatFilter;		//Clan chat filter (1.8): 1 (d) - dead can't write to alive, 2 (t) - people from different teams can't see each other's messages
		
int 	g_iExpandingCost, 		//Price of expansion
		g_iMaxClanMembers, 		//Maximum number of players in any clan
		g_iExpandValue, 		//Number of slots clan gets buying the expansion
		g_iStartSlotsInClan,	//Start number of slots for clans
		g_iLogs,				//Flag for logs: 2 - to DB, 1 - to file, 0 - not to log
		g_iLogFlags,			//Log flags
		g_iLogExpireDays,		//How many days a recond can be in DB
		g_iClanCreationCD,		//Time in minutes when player can create a new clan again (1.7)
		g_iRenameClanPrice,		//Clan rename price (1.7)
		g_iClanChatFilter,		//Clan chat filter (1.8)
		g_iSetClanTag;			//2 - set clan tag by force, 1 - set clan tag if player is in clan, 0 - set clan tag if player wants it (1.82)

bool	g_bLeaderChange,		//Flag: can leader set a new leader
		g_bCoinsTransfer,		//Flag: can clan transfer coins to other clan
		g_bLeaderLeave;			//Flag: can leader leave his/her clan
		
//===================== CVARS END =====================//
		
//Forwards below
Handle	g_hACMOpened, 		//AdminClanMenuOpened
		g_hACMSelected,		//AdminClanMenuSelected
		g_hCMOpened, 		//ClanMenuOpened
		g_hCMSelected,		//ClanMenuSelected
		g_hCSOpened, 		//ClanStatsOpened
		g_hPSOpened, 		//PlayerStatsOpened
		g_hClansLoaded,		//ClansLoaded
		g_hClanAdded,		//ClansAdded
		g_hClanDeleted,		//ClansDeleted
		g_hClientAdded,		//ClientAdded
		g_hClientDeleted,	//ClientDeleted
		g_hClanSelectedInList,	//Clans_OnClanSelectedInList	1.8v
		g_hClanMemberSelectedInList,	//Clans_OnClanMemberSelectedInList	1.8v NOT DONE
		g_hOnClanCoinsGive,		//Clans_OnClanCoinsGive	1.8v
		g_hOnClanClientLoaded;	//Clans_OnClientLoaded 1.83v

//=====================Permissions=====================//
Handle	g_hRInvitePerm,				//Invite players to clan
		g_hRGiveCoinsToClan,		//Give coins to other clan
		g_hRExpandClan,				//Expand clan
		g_hRKickPlayer,				//Kick player
		g_hRChangeType,				//Change clan's type
		g_hRChangeRole;				//Change role of player

int		g_iRInvitePerm,
		g_iRGiveCoinsToClan,
		g_iRExpandClan,
		g_iRKickPlayer,
		g_iRChangeType,
		g_iRChangeRole;
//=====================Permissions END=====================//

//===================== ClanChatColors =====================//
Handle 	g_hCCLeader,		//Color for leader in clan chat
		g_hCCColeader,		//Color for co-leader in clan chat
		g_hCCElder,			//Color for elder in clan chat
		g_hCCMember;		//Color for member in clan chat

char	g_cCCLeader[20],		//Color for leader in clan chat
		g_cCCColeader[20],		//Color for co-leader in clan chat
		g_cCCElder[20],			//Color for elder in clan chat
		g_cCCMember[20];		//Color for member in clan chat
//===================== ClanChatColors END =====================//

//===================== LOG FLAGS =====================//
#define LOG_KILLS 1
#define LOG_COINS 2
#define LOG_RENAMES 4
#define LOG_CLANACTION 8
#define LOG_CLIENTACTION 16
#define LOG_CHANGETYPE 32
#define LOG_CHANGEROLE 64
#define LOG_SLOTS 128
#define LOG_CLANCHAT 256
//===================== LOG FLAGS END =====================//

#include "clans/forwards.sp"
#include "clans/cookies.sp"
#include "clans/database.sp"
#include "clans/logging.sp"
#include "clans/cvars.sp"
#include "clans/functions.sp"
#include "clans/menus.sp"
#include "clans/clientCommands.sp"
#include "clans/adminCommands.sp"
#include "clans/natives.sp"

public Plugin myinfo = 
{ 
	name = "Clan system", 
	author = "Dream", 
	description = "Add clan system to the server", 
	version = PLUGIN_VERSION, 
}

public void OnPluginStart()
{
	RegClientCommands();
	RegAdminCommands();
	RegCVars();
	RegCookie();

	if(g_iLogs)
		PrepareDatabaseToLog();
	
	HookEvent("player_death", Death);
	HookEvent("player_spawn", Spawn);
	
	AddCommandListener(SayHook, "say");
	
	
	LoadTranslations("clans.phrases");
	LoadTranslations("clans_menus.phrases");
	LoadTranslations("clans_log.phrases");

	ConnectToDatabase();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		ClearPlayerMenuBuffer(i);	// v1.86
		ClearClientData(i);
		if(IsClientInGame(i))
			OnClientPostAdminCheck(i);
	}

	ClansLoaded();
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i))
			DB_SavePlayer(i);
	}
}

void ClansLoaded()
{
	g_bClansLoaded = true;
	F_OnClansLoaded();
}

public void OnClientPostAdminCheck(int client)
{
	renameClan[client] = false;			//Ставим флаг, что игрок не переименовывает клан
	createClan[client] = false;			//Игрок может создавать клан
	creatingClan[client] = false;
	ClearPlayerMenuBuffer(client);
	DB_LoadClient(client);				//Загрузка игрока с базы
	invitedBy[client][0] = -1;			//Айди того, кто пригласил в клан
	invitedBy[client][1] = -1;			//Время, когда пригласили в клан
	admin_SelectMode[client][0] = -1;
	admin_SelectMode[client][1] = -1;
	clan_SelectMode[client][0] = -1;
	clan_SelectMode[client][1] = -1;
	g_iClientDiffData[client][CD_DIFF_KILLS] = 0;	//v1.86
	g_iClientDiffData[client][CD_DIFF_DEATHS] = 0;
	if(!g_bCSS34)
		UpdatePlayerClanTag(client);
}

public void OnClientDisconnect(int client)
{
	DB_SavePlayer(client);	//v1.86
	//ClanClient = -1;
}

Action Death(Handle event, const char[] name, bool db)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	int victimInClanDB = GetClientIDinDB(victim);
	int attackerInClanDB = GetClientIDinDB(attacker);
	
	if (victim && attacker && (GetClientTeam(victim) != GetClientTeam(attacker)) && AreClientsInDifferentClans(victim, attacker))
	{
		KillFunc(attacker, victim, 1);
		if(CheckForLog(LOG_KILLS) && (victimInClanDB != -1 || attackerInClanDB != -1))
		{
			char log_buff[LOG_SIZE];
			FormatEx(log_buff, sizeof(log_buff), "%T", "L_Kill", LANG_SERVER);
			DB_LogAction(attacker, false, GetClientClanByID(attackerInClanDB), log_buff, victim, false, GetClientClanByID(victimInClanDB), LOG_KILLS);
		}
	}
	return Plugin_Continue;
}

Action Spawn(Handle event, const char[] name, bool db)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!g_bCSS34)
		UpdatePlayerClanTag(client);
	return Plugin_Handled;
}

Action SayHook(int client, const char[] command, int args)
{
	if(client && IsClientInGame(client))
	{
		if(writeToClanChat[client])	//1.7
		{
			char message[200];
			GetCmdArg(1, message, sizeof(message));
			FakeClientCommand(client, "sm_cchat %s", message);
			writeToClanChat[client] = false;
			return Plugin_Handled;
		}
		else if(ADMIN_STYPE >= 0 && ADMIN_STYPE != 7 && ADMIN_STYPE != 5)
		{
			char adminName[MAX_NAME_LENGTH+1];
			GetClientName(client, adminName, sizeof(adminName));
			switch(ADMIN_STYPE)
			{
				case 0:	//set coins to clan (admin_SelectMode[][1])
				{
					char str_coins[30],
						 print_buff[BUFF_SIZE],
						 clanName[MAX_CLAN_NAME+1];
					int coins = 0;
					int type = 2;	//0 - take, 1 - add, 2 - set
					int clanid = ADMIN_STARGET,
						clanCoins;
					GetClanName(clanid, clanName, sizeof(clanName));
					GetCmdArg(1, str_coins, sizeof(str_coins));
					TrimString(str_coins);
					if(!strcmp(str_coins, "отмена") || !strcmp(str_coins, "cancel"))
					{
						ADMIN_STYPE = -1;
						ADMIN_STARGET = -1;
						return Plugin_Handled;
					}
					if(str_coins[0] == '+')
						type = 1;
					else if(str_coins[0] == '-')
						type = 0;
					ReplaceString(str_coins, sizeof(str_coins), "+", "");
					coins = StringToInt(str_coins);
					if(type != 2)	//0 - take, 1 - add
					{
						clanCoins = GetClanCoins(clanid);
						if(clanCoins + coins < 0)
						{
							FormatEx(print_buff, sizeof(print_buff), "%T", "c_CoinsIncorrect", client);
							CPrintToChat(client, print_buff);
							ADMIN_STYPE = -1;
							ADMIN_STARGET = -1;
							return Plugin_Handled;
						}
						if(CheckForLog(LOG_COINS))
						{
							char log_buff[LOG_SIZE];
							FormatEx(log_buff, sizeof(log_buff), "%T", (type == 0 ? "L_TakeCoins" : "L_GiveCoins"), LANG_SERVER, (type == 0 ? -coins : coins), clanName);
							DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, ADMIN_STARGET, LOG_COINS);
						}
						DB_ChangeClanCoins(clanid, coins);
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], clanName))
							{
								FormatEx(print_buff, sizeof(print_buff), "%T", (type == 0 ? "c_AdminTookCoins" : "c_AdminGaveCoins"), i, adminName, (type == 0 ? -coins : coins) );
								CPrintToChat(i, print_buff);
							}
						}
						coins = clanCoins + coins;
					}
					else	//2 - set
					{
						if(coins < 0)
						{
							FormatEx(print_buff, sizeof(print_buff), "%T", "c_CoinsIncorrect", client);
							CPrintToChat(client, print_buff);
							ADMIN_STYPE = -1;
							ADMIN_STARGET = -1;
							return Plugin_Handled;
						}
						if(CheckForLog(LOG_COINS))
						{
							char log_buff[LOG_SIZE];
							FormatEx(log_buff, sizeof(log_buff), "%T", "L_SetCoins", LANG_SERVER, coins, clanName);
							DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, ADMIN_STARGET, LOG_COINS);
						}
						SetClanCoins(clanid, coins);
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], clanName))
							{
								FormatEx(print_buff, sizeof(print_buff), "%T", "c_AdminSetCoins", i, adminName, coins);
								CPrintToChat(i, print_buff);
							}
						}
					}
					FormatEx(print_buff, sizeof(print_buff), "%T", "c_CoinsNow", client, clanName, coins);
					CPrintToChat(client, print_buff);
				}
				case 1: //reset client (admin_SelectMode[][1])
				{
					char str_target[20],
						 targetName[MAX_NAME_LENGTH+1];
					int targetID = -1;
					GetCmdArg(1, str_target, sizeof(str_target));
					TrimString(str_target);
					targetID = StringToInt(str_target);
					if(targetID == ADMIN_STARGET)
					{
						GetClientNameByID(targetID, targetName, sizeof(targetName));
						if(CheckForLog(LOG_CLIENTACTION))
						{
							char log_buff[LOG_SIZE];
							FormatEx(log_buff, sizeof(log_buff), "%T", "L_ResetPlayer", LANG_SERVER, targetName);
							DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, targetID, true, GetClientClanByID(targetID), LOG_CLIENTACTION);
						}
						char print_buff[BUFF_SIZE];
						FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerReset", client, targetName);
						CPrintToChat(client, print_buff);
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && playerID[i] == targetID)
							{
								FormatEx(print_buff, sizeof(print_buff), "%T", "c_AdminResetPlayer", i, adminName);
								CPrintToChat(i, print_buff);
								i = MaxClients+1;
							}
						}
						ResetClient(targetID);
					}
				}
				case 2:	//reset clan
				{
					char str_clanid[20],
						 clanName[MAX_CLAN_NAME+1];
					int clanid = -1;
					GetCmdArg(1, str_clanid, sizeof(str_clanid));
					TrimString(str_clanid);
					clanid = StringToInt(str_clanid);
					if(clanid == ADMIN_STARGET)
					{
						GetClanName(clanid, clanName, sizeof(clanName));
						if(CheckForLog(LOG_CLANACTION))
						{
							char log_buff[LOG_SIZE];
							FormatEx(log_buff, sizeof(log_buff), "%T", "L_ResetClan", LANG_SERVER, clanName);
							DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_CLANACTION);
						}
						char print_buff[BUFF_SIZE];
						FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanReset", client, clanName);
						CPrintToChat(client, print_buff);
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], clanName))
							{
								FormatEx(print_buff, sizeof(print_buff), "%T", "c_AdminResetClan", i, adminName);
								CPrintToChat(i, print_buff);
							}
						}
						ResetClan(clanid);
					}
				}
				case 3: //delete client
				{
					char str_target[20],
						 targetName[MAX_NAME_LENGTH+1],
						 targetClanName[MAX_CLAN_NAME+1];
					int targetID = -1;
					GetCmdArg(1, str_target, sizeof(str_target));
					TrimString(str_target);
					targetID = StringToInt(str_target);
					if(targetID == ADMIN_STARGET)
					{
						GetClientNameByID(targetID, targetName, sizeof(targetName));
						char print_buff[BUFF_SIZE];
						FormatEx(print_buff, sizeof(print_buff), "%T", "c_PlayerDelete", client, targetName);
						CPrintToChat(client, print_buff);
						if(CheckForLog(LOG_CLIENTACTION))
						{
							int targetClanid = GetClientClanByID(targetID);
							GetClanName(targetClanid, targetClanName, sizeof(targetClanName));
							char log_buff[LOG_SIZE];
							FormatEx(log_buff, sizeof(log_buff), "%T", "L_DeletePlayer", LANG_SERVER, targetName, targetClanName);
							DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, targetID, true, targetClanid, LOG_CLIENTACTION);
						}
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && playerID[i] == targetID)
							{
								FormatEx(print_buff, sizeof(print_buff), "%T", "c_AdminDeletePlayer", i, adminName);
								CPrintToChat(i, print_buff);
								i = MaxClients+1;
							}
						}
						DeleteClientByID(targetID);
					}
				}
				case 4:	//delete clan
				{
					char str_clanid[20],
						 clanName[MAX_CLAN_NAME+1];
					int clanid = -1;
					GetCmdArg(1, str_clanid, sizeof(str_clanid));
					TrimString(str_clanid);
					clanid = StringToInt(str_clanid);
					if(clanid == ADMIN_STARGET)
					{
						GetClanName(clanid, clanName, sizeof(clanName));
						char print_buff[BUFF_SIZE];
						FormatEx(print_buff, sizeof(print_buff), "%T", "c_ClanDelete", client, clanName);
						CPrintToChat(client, print_buff);
						if(CheckForLog(LOG_CLANACTION))
						{
							char log_buff[LOG_SIZE];
							FormatEx(log_buff, sizeof(log_buff), "%T", "L_DeleteClan", LANG_SERVER, clanName);
							DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_CLANACTION);
						}
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], clanName))
							{
								FormatEx(print_buff, sizeof(print_buff), "%T", "c_AdminDeleteClan", i, adminName);
								CPrintToChat(i, print_buff);
							}
						}
						DeleteClan(clanid);
					}
				}
				case 8:	//set slots
				{
					char str_slots[30], 
						 print_buff[BUFF_SIZE],
						 clanName[MAX_CLAN_NAME+1];
					int slots = 0;
					int type = 2;	//0 - take, 1 - give, 2 - set
					int clanid = ADMIN_STARGET;
					GetCmdArg(1, str_slots, sizeof(str_slots));
					TrimString(str_slots);
					if(!strcmp(str_slots, "отмена") || !strcmp(str_slots, "cancel"))
					{
						ADMIN_STYPE = -1;
						ADMIN_STARGET = -1;
						return Plugin_Handled;
					}
					GetClanName(clanid, clanName, sizeof(clanName));
					if(str_slots[0] == '+')
						type = 1;
					else if(str_slots[0] == '-')
						type = 0;
					ReplaceString(str_slots, sizeof(str_slots), "-", "");
					slots = StringToInt(str_slots);
					if(type < 2)	//0 take, 1 - give
					{
						int clanSlots = GetClanMaxMembers(clanid);
						if(clanSlots + slots < 1)
						{
							FormatEx(print_buff, sizeof(print_buff), "%T", "c_SlotsIncorrect", client);
							CPrintToChat(client, print_buff);
							ADMIN_STYPE = -1;
							ADMIN_STARGET = -1;
							return Plugin_Handled;
						}
						if(CheckForLog(LOG_SLOTS))	//Логируем, если надо
						{
							char log_buff[LOG_SIZE];
							FormatEx(log_buff, sizeof(log_buff), "%T", (type == 0 ? "L_TakeSlots" : "L_GiveSlots"), LANG_SERVER, (type == 0 ? -slots : slots), clanName);
							DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_SLOTS);
						}
						SetClanMaxMembers(clanid, clanSlots + slots);	//Ставим слоты
						for(int i = 1; i <= MaxClients; i++)	//Оповещаем всех игроков клана, которые онлайн, об изменении
						{
							if(IsClientInGame(i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], clanName))
							{
								FormatEx(print_buff, sizeof(print_buff), "%T", (type == 0 ? "c_AdminTookSlots" : "c_AdminGaveSlots"), i, adminName, (type == 0 ? -slots : slots) );
								CPrintToChat(i, print_buff);
							}
						}
						slots = clanSlots + slots;
					}
					else	//2 - set
					{
						if(slots < 1)
						{
							FormatEx(print_buff, sizeof(print_buff), "%T", "c_SlotsIncorrect", client);
							CPrintToChat(client, print_buff);
							ADMIN_STYPE = -1;
							ADMIN_STARGET = -1;
							return Plugin_Handled;
						}
						if(CheckForLog(LOG_SLOTS))	//Логируем, если надо
						{
							char log_buff[LOG_SIZE];
							FormatEx(log_buff, sizeof(log_buff), "%T", "L_SetSlots", LANG_SERVER, slots, clanName);
							DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_SLOTS);
						}
						SetClanMaxMembers(clanid, slots);	//Ставим слоты
						for(int i = 1; i <= MaxClients; i++)	//Оповещаем всех игроков клана, которые онлайн, об изменении
						{
							if(IsClientInGame(i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], clanName))
							{
								FormatEx(print_buff, sizeof(print_buff), "%T", "c_AdminSetSlots", i, adminName, slots);
								CPrintToChat(i, print_buff);
							}
						}
					}
					FormatEx(print_buff, sizeof(print_buff), "%T", "c_SlotsNow", client, clanName, slots);	//Админу говорим, сколько теперь слотов
					CPrintToChat(client, print_buff);
				}
			}
			ADMIN_STYPE = -1;
			ADMIN_STARGET = -1;
			return Plugin_Handled;
		}
		else if(ADMIN_STYPE == 5 || creatingClan[client])	//clan create
		{
			char clanName[MAX_CLAN_NAME+1],  
				 buff[50];
			int clanid = -1;
			int target = ADMIN_STYPE == 5 ? ADMIN_STARGET : client;
			GetCmdArg(1, buff, sizeof(buff));
			TrimString(buff);
			if(!strcmp(buff, "отмена") || !strcmp(buff, "cancel"))
			{
				creatingClan[client] = false;
				ADMIN_STYPE = -1;
				ADMIN_STARGET = -1;
				return Plugin_Handled;
			}
			if(strlen(buff) < 1 || strlen(buff) > MAX_CLAN_NAME)
			{
				char print_buff[BUFF_SIZE];
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_WrongClanName", client, MAX_CLAN_NAME);
				CPrintToChat(client, print_buff);
				creatingClan[client] = false;
				ADMIN_STYPE = -1;
				ADMIN_STARGET = -1;
				return Plugin_Handled;
			}
			else
			{
				for(int i = 0; i < MAX_CLAN_NAME; i++)
					clanName[i] = buff[i];
				clanName[MAX_CLAN_NAME] = '\0';
			}
			
			if(CheckForLog(LOG_CLANACTION))
			{
				char log_buff[LOG_SIZE];
				FormatEx(log_buff, sizeof(log_buff), "%T", "L_CreateClan", LANG_SERVER, clanName);
				DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, clanid, LOG_CLANACTION);
			}

			if(playerID[target] != -1)
				DeleteClientByID(playerID[target]);

			CreateClan(target, clanName, client);
			creatingClan[client] = false;
			ADMIN_STYPE = -1;
			ADMIN_STARGET = -1;
			return Plugin_Handled;
		}
		else if(renameClan[client])
		{
			char clanName[MAX_CLAN_NAME+1],
				 clanPrevName[MAX_CLAN_NAME+1],
				 buff[50],
				 query[300];
			char print_buff[BUFF_SIZE];
			int clanid;
			bool takeCoins = ADMIN_STYPE != 7;
			if(ADMIN_STYPE == 7)
			{
				clanid = ADMIN_STARGET;
				ADMIN_STYPE = -1;
				ADMIN_STARGET = -1;
			}
			else
				clanid = GetClientClanByID(ClanClient);
			GetCmdArg(1, buff, sizeof(buff));
			TrimString(buff);
			if(!strcmp(buff, "отмена") || !strcmp(buff, "cancel"))
			{
				renameClan[client] = false;
				ADMIN_STYPE = -1;
				ADMIN_STARGET = -1;
				return Plugin_Handled;
			}
			if(strlen(buff) < 1 || strlen(buff) > MAX_CLAN_NAME)
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_WrongClanName", client, MAX_CLAN_NAME);
				CPrintToChat(client, print_buff);
				renameClan[client] = false;
				ADMIN_STYPE = -1;
				ADMIN_STARGET = -1;
				return Plugin_Handled;
			}
			else
			{
				for(int i = 0; i < MAX_CLAN_NAME; i++)
					clanName[i] = buff[i];
				clanName[MAX_CLAN_NAME] = '\0';
			}
			
			char clanNameEscaped[MAX_CLAN_NAME*2+1];
			g_hClansDB.Escape(clanName, clanNameEscaped, sizeof(clanNameEscaped));
			DataPack dp = CreateDataPack();
			GetClanName(clanid, clanPrevName, sizeof(clanPrevName));
			dp.WriteCell(client);
			dp.WriteCell(clanid);
			dp.WriteString(clanPrevName);
			dp.WriteString(clanName);
			dp.WriteCell(takeCoins);
			dp.Reset();
			FormatEx(query, sizeof(query), "SELECT 1 FROM `clans_table` WHERE `clan_name` = '%s'", clanNameEscaped);
			g_hClansDB.Query(DB_RenameClanCallback, query, dp);
			renameClan[client] = false;
			ADMIN_STYPE = -1;
			ADMIN_STARGET = -1;
			return Plugin_Handled;
		}
		else if(CLAN_STYPE == 3)	//Transfer coins
		{
			char str_coins[30], 
				 print_buff[BUFF_SIZE],
				 clanName[MAX_CLAN_NAME+1],
				 targetClanName[MAX_CLAN_NAME+1];
			int coins = 0,
				clientClan = GetClientClanByID(ClanClient);
			GetCmdArg(1, str_coins, sizeof(str_coins));
			TrimString(str_coins);
			if(!strcmp(str_coins, "отмена") || !strcmp(str_coins, "cancel"))
			{
				CLAN_STYPE = -1;
				CLAN_STARGET = -1;
				return Plugin_Handled;
			}
			coins = StringToInt(str_coins);
			int clientClanCoins = GetClanCoins(clientClan);
			if(coins <= 0 || clientClanCoins < coins)
			{
				FormatEx(print_buff, sizeof(print_buff), "%T", "c_TranferFailed", client);
				CPrintToChat(client, print_buff);
				CLAN_STYPE = -1;
				CLAN_STARGET = -1;
				return Plugin_Handled;
			}
			else
			{
				if(CheckForLog(LOG_CLANACTION))
				{
					char log_buff[LOG_SIZE];
					GetClanName(CLAN_STARGET, targetClanName, sizeof(targetClanName));
					FormatEx(log_buff, sizeof(log_buff), "%T", "L_TransferCoins", LANG_SERVER, coins, targetClanName);
					DB_LogAction(client, false, GetClientClanByID(ClanClient), log_buff, -1, true, CLAN_STARGET, LOG_CLANACTION);
				}
				int targetClanCoins = GetClanCoins(CLAN_STARGET);
				SetClanCoins(clientClan, clientClanCoins - coins);
				SetClanCoins(CLAN_STARGET, targetClanCoins + coins);
				GetClanName(clientClan, clanName, sizeof(clanName));
				for(int i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i) && !strcmp(g_sClientData[i][CLIENT_CLANNAME], targetClanName))
					{
						FormatEx(print_buff, sizeof(print_buff), "%T", "c_TranferFrom", i, clanName, coins);
						CPrintToChat(i, print_buff);
					}
				}
			}
			FormatEx(print_buff, sizeof(print_buff), "%T", "c_TranferSuccess", client);
			CPrintToChat(client, print_buff);
			CLAN_STYPE = -1;
			CLAN_STARGET = -1;
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}