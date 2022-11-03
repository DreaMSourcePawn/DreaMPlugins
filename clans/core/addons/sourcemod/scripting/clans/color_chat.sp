void ColorPrintToChat(int iClient, const char[] message, any ...)
{
    char sBuff[2048];
    VFormat(sBuff, sizeof(sBuff), message, 3);

    if(g_bCSGO)
        CGOPrintToChat(iClient, sBuff);
    else if(g_bCSS)
        CPrintToChat(iClient, sBuff);
    else
        C34PrintToChat(iClient, sBuff);
}