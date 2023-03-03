    // ============================ CLANS ============================ //

/**
 * Calls when clan has been deleted
 *
 * @param 		int iClanid - clan's index
 * 
 * @noreturn
*/
public void Clans_OnClanDeleted(int iClanid)
{
    DeleteClanItems(iClanid);
    RemoveClanItems(iClanid);
}

    // ============================ PLAYERS ============================ //

/**
 * Calls when client is loaded
 *
 * @param 		int iClient - client's index
 * @param 		int iClientID - client's id in database
 * @param 		int iClanid - client's clan id
 * @noreturn
*/
public void Clans_OnClientLoaded(int iClient, int iClientID, int iClanid)
{
    ClearPlayerItemInfo(iClient);
    if(iClanid != CLAN_INVALID_CLAN)
        DB_LoadPlayer(iClient, iClientID, iClanid);
}

/**
 * Calls when clan client has been deleted
 *
 * @param		int iClient - client's index (-1 if player is offline)
 * @param 		int iClientID - client's ID in clan database
 * @param 		int iClanid - clan's index, where clan client was
 * @noreturn
*/
public void Clans_OnClientDeleted(int iClient, int iClientID, int iClanid)
{
    DB_ClearPlayerItems(iClientID);
    if(iClient > 0)
    {
        ClearPlayerItemInfo(iClient);
    }
}

    // ============================ MENUS ============================ //

/**
 * Calls when client opens main clan menu
 *
 * @param clanMenu      clan menu handle
 * @param iClient       client's index
 * @noreturn
*/
public void Clans_OnClanMenuOpened(Handle clanMenu, int iClient)
{
    if(Clans_IsClientInClan(iClient))
    {
        char sBuff[300];
        FormatEx(sBuff, sizeof(sBuff), "%T", "m_ClanShop", iClient);
        InsertMenuItem(clanMenu, 5, "Shop", sBuff);
    }
}

/**
 * Calls when client selects menu item in main clan menu
 *
 * @param clanMenu      main clan menu handle
 * @param iClient       client's index
 * @param iOption       selected option
 * @noreturn
*/
public void Clans_OnClanMenuSelected(Handle clanMenu, int iClient, int iOption)
{
    char sBuff[10];
    GetMenuItem(clanMenu, iOption, sBuff, sizeof(sBuff));
    if(!strcmp(sBuff, "Shop"))
    {
        ThrowMainMenuToClient(iClient);
    }
}