void RegClientCmds()
{
    RegConsoleCmd("cs_buy", BuyCmd);
}

Action BuyCmd(int iClient, int iArgs)
{
    if(iClient < 1 || iClient > MaxClients)
        return Plugin_Continue;

    if(!IsShopActive())
    {
        ColorPrintToChat(iClient, "%T", "c_ShopUnavailable", iClient);
        return Plugin_Handled;
    }
    
    ThrowMainMenuToClient(iClient);
    return Plugin_Handled;
}