#define TARGET_NONE -1

enum AdminAction
{
    AA_None = 0,
    AA_GiveItemToClan = 1,
    AA_TakeItemFromClan = 2,
    AA_SetItemLvlInClan = 4,
    AA_SetExpireTimeInClan = 8,
    AA_ChangeStock = 16,
    AA_Input = 32
}

enum struct AdminInfo
{
    AdminAction adminAction;        // Действие
    int iItemId;                    // item id
    int iClanId;                    // clan id
    char clanName[MAX_CLAN_NAME+1]; // название клана
}

AdminInfo adminInfo[MAXPLAYERS+1];

/** Хук чата */
void HookChat()
{
    AddCommandListener(SayHook, "say");
    for(int i = 1; i <= MaxClients; ++i)
    {
        adminInfo[i].adminAction = AA_None;
        adminInfo[i].iItemId = TARGET_NONE;
        adminInfo[i].iClanId = TARGET_NONE;
    }
}

/**
 * Установка админ информации игроку
 * 
 * @param iClient         Иднекс игрока
 * @param adminAction     Действие
 * @param iItemId         Ид предмета
 * @param iClanId         Ид клана
 * @param clanName        Название клана
 * @noreturn                
 */
void SetAdminInfo(int iClient, AdminAction adminAction, int iItemId, int iClanId, const char[] clanName = "")
{
    adminInfo[iClient].adminAction = adminAction;
    adminInfo[iClient].iItemId = iItemId;
    adminInfo[iClient].iClanId = iClanId;
    FormatEx(adminInfo[iClient].clanName, sizeof(adminInfo[].clanName), "%s", clanName);
}

/**
 * Очистка админ информации у игрока
 * 
 * @param iClient     Индекс игрока
 * @noreturn
 */
void ClearAdminInfo(int iClient)
{
    SetAdminInfo(iClient, AA_None, TARGET_NONE, TARGET_NONE);
}

/**
 * Получить текущее админ действие игрока
 * 
 * @param iClient     Индекс игрока
 * @return            AdminAction - админ действие
 */
AdminAction GetClientAdminAction(int iClient)
{
    return adminInfo[iClient].adminAction;
}

/**
 * Установить текущее админ действие игрока
 * 
 * @param iClient     Индекс игрока
 * @param aAction     Действие игрока
 * @noreturn
 */
void SetClientAdminAction(int iClient, AdminAction aAction)
{
    adminInfo[iClient].adminAction = aAction;
}

/**
 * Получить цель-предмет действия игрока
 * 
 * @param iClient     Индекс игрока
 * @return            id предмета
 */
ClanItemId GetAdminActionItemTarget(int iClient)
{
    return adminInfo[iClient].iItemId;
}

/**
 * Установить цель-предмет действия игрока
 * 
 * @param iClient     Индекс игрока
 * @param itemId      Ид предмета-цели
 * @noreturn
 */
void SetAdminActionItemTarget(int iClient, ClanItemId itemId)
{
    adminInfo[iClient].iItemId = itemId;
}

/**
 * Получить цель-клан действия игрока
 * 
 * @param iClient     Индекс игрока
 * @return            id клана
 */
int GetAdminActionClanTarget(int iClient)
{
    return adminInfo[iClient].iClanId;
}

/**
 * Установить цель-клан действия игрока
 * 
 * @param iClient     Индекс игрока
 * @param iClanId     Ид клана-цели
 * @noreturn
 */
void SetAdminActionClanTarget(int iClient, int iClanId)
{
    adminInfo[iClient].iClanId = iClanId;
}

/**
 * Получение название клана-цели
 * 
 * @param iClient         Индекс игрока
 * @param sBuffer         Буфер
 * @param iBufferSize     Размер буфера
 * @noreturn
 */
void GetAdminActionClanNameTarget(int iClient, char[] sBuffer, int iBufferSize)
{
    FormatEx(sBuffer, iBufferSize, "%s", adminInfo[iClient].clanName);
}

/**
 * Установка названия клана-цели
 * 
 * @param iClient         Индекс игрока
 * @param clanName        Название клана
 * @noreturn
 */
void SetAdminActionClanNameTarget(int iClient, const char[] clanName)
{
    FormatEx(adminInfo[iClient].clanName, sizeof(adminInfo[].clanName), "%s", clanName);
}

/**
 * Хук чата для админских действий
 * 
 * @param iClient      Индекс игрока
 * @param sCommand     Введенная команда
 * @param iArgs        Количество аргументов
 * @return             Plugin_Handled, если получено админ-действие, иначе - Plugin_Continue
 */
Action SayHook(int iClient, const char[] sCommand, int iArgs)
{
    if(iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient) && adminInfo[iClient].adminAction & AA_Input)
    {
        char sAction[256];
        GetCmdArg(1, sAction, sizeof(sAction));
        if(!strcmp(sAction, "cancel") || !strcmp(sAction, "отмена"))
        {
            ClearAdminInfo(iClient);
            return Plugin_Handled;
        }

        AdminAction aAction = adminInfo[iClient].adminAction & ~AA_Input;

        switch(aAction)
        {
            case AA_ChangeStock:    //Изменить запас предметов на складе
            {
                ClanItemId itemId = GetAdminActionItemTarget(iClient);

                int iAmountToAdd = StringToInt(sAction);
                if(iAmountToAdd == 0)
                {
                    ClearAdminInfo(iClient);
                    return Plugin_Handled;
                }
                if(AddItemMaxAmountById(itemId, iAmountToAdd))  // Возникла ошибка
                {
                    ColorPrintToChat(iClient, "%T", "c_Error", iClient);
                    if(ThrowCategoriesToClient(iClient))
                        SetAdminInfo(iClient, AA_ChangeStock, TARGET_NONE, TARGET_NONE);
                }
                else
                {
                    DB_ChangeItemMaxAmount(itemId, iAmountToAdd);
                    ColorPrintToChat(iClient, "%T", "c_ChangeStockSuccess", iClient);
                    if(ThrowCategoriesToClient(iClient))
                        SetAdminInfo(iClient, AA_ChangeStock, TARGET_NONE, TARGET_NONE);
                }
            }
            case AA_SetItemLvlInClan:
            {
                ClanItemId itemId = GetAdminActionItemTarget(iClient);
                int iClanId = GetAdminActionClanTarget(iClient);
                char clanName[MAX_CLAN_NAME+1];
                GetAdminActionClanNameTarget(iClient, clanName, sizeof(clanName));

                int iNewLevel = StringToInt(sAction);
                if(SetClanItemLevel(iClanId, itemId, iNewLevel))
                {
                    char originalItemName[256], itemName[256];
                    GetItemNameById(itemId, originalItemName, sizeof(originalItemName));
                    FormatEx(itemName, sizeof(itemName), "%s", originalItemName);
                    DisplayNameForMenu(iClient, itemName, sizeof(itemName));

                    ColorPrintToChat(iClient, "%T", "c_ItemLevelWasSuccessfullyChanged", iClient, itemName, clanName);

                    for(int i = 1; i <= MaxClients; ++i)
                    {
                        if(IsClientInGame(i) && Clans_GetClientData(i, CCST_CLANID) == iClanId)
                        {
                            FormatEx(itemName, sizeof(itemName), "%s", originalItemName);
                            DisplayNameForMenu(i, itemName, sizeof(itemName));
                            ColorPrintToChat(i, "%T %N", "c_ItemLevelWasChangedByAdmin", i, itemName, iNewLevel, iClient);
                        }
                    }
                }
                else
                {
                    ColorPrintToChat(iClient, "%T", "c_Error", iClient);
                }
                SetAdminInfo(iClient, AA_SetItemLvlInClan, TARGET_NONE, iClanId);
                ThrowClanItemsToClient(iClient, iClanId, clanName);
            }
            case AA_SetExpireTimeInClan:
            {
                ClanItemId itemId = GetAdminActionItemTarget(iClient);
                int iClanId = GetAdminActionClanTarget(iClient);
                char clanName[MAX_CLAN_NAME+1];
                GetAdminActionClanNameTarget(iClient, clanName, sizeof(clanName));

                int iNewDuration = StringToInt(sAction);
                if(iNewDuration == 0)
                {
                    ThrowConfirmTakeItem(iClient, itemId, iClanId, clanName);
                }
                else
                {
                    ThrowConfirmNewDurationForItem(iClient, itemId, clanName, iNewDuration);
                }

                SetClientAdminAction(iClient, AA_SetExpireTimeInClan);
            }
            default:
            {
                //SetAdminInfo(iClient, AA_None, TARGET_NONE);
                return Plugin_Continue;
            }
        }
        
        return Plugin_Handled;
    }

    return Plugin_Continue;
}