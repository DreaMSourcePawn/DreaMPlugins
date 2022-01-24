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