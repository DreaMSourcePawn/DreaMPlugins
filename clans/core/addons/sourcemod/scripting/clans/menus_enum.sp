#define	IsMBufferEmpty(%1) g_asClientLastMenu[%1].Empty
#define NO_BUFF_DATA 0
#define MDINT(%1) (view_as<int>(%1))

// List of functions
enum MD_Funcs
{
    MD_ThrowClanMenuToClient = 0,
    MD_ThrowPlayerStatsToClient,
    MD_ThrowClanStatsToClient,
    MD_ThrowClanMembersToClient,
    MD_ThrowTopsMenuToClient,
    MD_ThrowTopClanInCategoryToClient,
    MD_ThrowClansToClient,
    MD_ThrowClanClientsToClient,
    MD_ThrowInviteList,
    MD_ThrowClanControlMenu,
    MD_ThrowSetTypeMenu,
    MD_ThrowChangeRoleMenu,
    MD_ThrowAdminMenu,
    MD_ThrowClanHelp,
    MD_ThrowClanTagSettings
};