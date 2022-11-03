#if defined _clans_included
	#endinput
#endif
#define _clans_included

#include <clans/forwards>
#include <clans/clients>
#include <clans/clans>

#define MAX_CLAN_NAME 10
#define MAX_INVITATION_TIME 30							/*		Time in seconds to accept the invitation	*/

#define CLAN_INVALID_CLAN -1
#define CLAN_INVALID_CLIENT -1

#define PERM_INVITE 1
#define PERM_GIVECOINS 2
#define PERM_EXPAND 3
#define PERM_KICK 4
#define PERM_TYPE 5
#define PERM_ROLE 6

/*				CLIENT DATA DEFINES		INTEGER			*/

#define CLIENT_CLANID 0									/*		Client clan's id							*/
#define CLIENT_ROLE 1									/*		Client' role								*/
#define CLIENT_KILLS 2									/*		Client's kills in his clan					*/
#define CLIENT_DEATHS 3									/*		Client's deaths in his clan					*/
#define CLIENT_TIME 4									/*		Client's time of joining clan				*/

#define CLIENT_MEMBER 0									/*		Client is clan member						*/
#define CLIENT_ELDER 1									/*		Client is elder of a clan					*/
#define CLIENT_COLEADER 2								/*		Client is co-leader of a clan				*/
#define CLIENT_LEADER 4									/*		Client is leader of a clan					*/


/*				CLIENT DATA DEFINES		STRING			*/

#define CLIENT_NAME 0									/*		Client's name in database					*/
#define CLIENT_STEAMID 1								/*		Client's STEAM ID in database				*/
#define CLIENT_CLANNAME 2								/*		Client clan's name'							*/

/*				CLAN DATA DEFINES		INTEGER			*/

#define CLAN_MEMBERS 0									/*		Amount of members in clan					*/
#define CLAN_MAXMEMBERS 1								/*		Maximum amount of members in clan			*/
#define CLAN_KILLS 2									/*		Clan's kills								*/
#define CLAN_DEATHS 3									/*		Clan's deaths								*/
#define CLAN_TIME 4										/*		Clan's time of creating						*/
#define CLAN_COINS 5									/*		Clan's coins								*/
#define CLAN_TYPE 6										/*		Clan's type									*/

#define CLAN_CLOSED 0
#define CLAN_OPEN 1

/*				CLAN DATA DEFINES		STRING			*/

#define CLAN_NAME 0										/*		Clan's name									*/
#define CLAN_LEADERNAME 1								/*		Clan leader's name 							*/
#define CLAN_LEADERID 2									/*		Clan leader's STEAMID						*/
#define CLAN_DATE 3										/*		Clan's date of creating						*/

/*				CLAN TOP DEFINES		INTEGER			*/

#define TOP_KILLS 0										/*		Top by kills								*/
#define TOP_DEATHS 1									/*		Top by deaths								*/
#define TOP_EXISTTIME 2									/*		Top by exist time							*/
#define TOP_MEMBERS 3									/*		Top by number of members					*/
#define TOP_COINS 4										/*		Top by number of clan coins					*/

enum Clan_MenuType
{
	CM_Main,			//ThrowClanMenuToClient(int client)
	CM_Control,			//ThrowClanControlMenu(int client)
	CM_PlayerStats,		//ThrowPlayerStatsToClient(int client, int targetID)
	CM_ClanStats,		//ThrowClanStatsToClient(int client, int clanid)
	CM_ClanMembers,		//ThrowClanMembersToClient(int client, int clanid, int showFlags)
	CM_Top,				//ThrowTopsMenuToClient(int client)
	CM_ClansList,		//ThrowClansToClient(int client, bool showClientClan)
	CM_AllClanClients,	//ThrowClanClientsToClient(int client)
	CM_Admin,			//ThrowAdminMenu(int client)
	CM_ClanHelp,		//ThrowClanHelp(int client)
	CM_TagSettings		//ThrowClanTagSettings(int client)
};

enum Clans_ClientStatsType
{
    CCST_USETAG,            // Flag if client uses clan tag
    CCST_ID,                // Client's id in database
    CCST_ROLE,              // Client's role
    CCST_CLANID,            // Client clan's id
    CCST_KILLS,             // Client's kills in clan
    CCST_DEATHS,            // Client's deaths in clan
    CCST_PERMTOCREATE,      // Flag if client can create a clan
    CCST_TIMEINCLAN,        // Client's time in clan
    CCST_TIMETOCREATE       // Client's remaining time to create a new clan
};

enum Clan_RegStatus
{
	CR_Success,					//Successful registration
	CR_AlreadyExists,			//Registration of a plugin already exists
	CR_NoApprove,				//Forward Clans_ApproveHandle wasn't found
	CR_NoMenuOpenedForward		//Forward Clans_OnClanControlMenuOpened wasn't found
};

/**
 * Get clan's database
 *
 * @return clan's database handle
*/
native Database Clans_GetClanDatabase();

/**
 * Check if clan's database is mySQL database
 *
 * @return true if it is, false otherwise
*/
native bool Clans_IsMySQLDatabase();

/**
 * Check if clan system is loaded
 *
 * @return true - loaded, false otherwise
 */
native bool Clans_AreClansLoaded();

/**
 * Register a clan control option. If there is any of extra different from the core options
 * Clan control menu will be created and shown to client. Also it will be active in the main menu
 * CALL THIS NATIVE ONCE IN PLUGIN
 * ALSO DO NOT FORGET TO APPROVE YOUR REGISTRATION (see Clans_ApproveHandle in clans/forwards.inc)
 * MAKE SURE YOU HAVE Clans_OnClanControlMenuOpened and Clans_ApproveHandle FORWARDS (if you haven't your plugin won't be registered)
 *
 * @param int iRole - required role for the option (see CLIENT DATA DEFINES INTEGER)
 *
 * @return Clan_RegStatus (see above)
 */
native Clan_RegStatus Clans_RegClanControlOption(int iRole);

/**
 * Remove an extra clan control option.
 *
 * @param int iRole - required role for the option (see CLIENT DATA DEFINES INTEGER)
 *
 * @return true on success, false otherwise (your plugin hasn't registered options for this role)
 */
native bool Clans_RemoveClanControlOption(int iRole);