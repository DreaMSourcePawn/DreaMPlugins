#include <clans_shop>

ClanItemId g_itemId = INVALID_ITEM;

enum struct LevelInfo
{
    int iArmorToAdd;
    int iRequiredSeconds;
    int iMaxArmor;
}

int g_iLevel[MAXPLAYERS+1],        // 1 lvl: +2 AP/2s, 2: +5AP/2s, 3: +5AP/1s
    g_iSeconds[MAXPLAYERS+1];      // Сколько прошло секунд для игрока

bool g_bShopEnabled = false;

Handle  g_hTimer = INVALID_HANDLE;

KeyValues g_kvSettings;
ArrayList g_alLevelsPrices = null;
ArrayList g_alLevelParams = null;

public Plugin myinfo = 
{ 
	name = "[CSHOP] Armor regen", 
	author = "DreaM", 
	description = "Add armor regen to cshop", 
	version = "1.01", 
} 

public void OnPluginStart()
{
    LoadConfig();

    if(CShop_IsShopLoaded())
        CShop_OnShopLoaded();
}

public void OnPluginEnd()
{
    CShop_UnregisterMe();
}

void LoadConfig()
{
    if(g_kvSettings) delete g_kvSettings;
    if(g_alLevelParams) delete g_alLevelParams;
    if(g_alLevelsPrices) delete g_alLevelsPrices;

    g_kvSettings = new KeyValues("Settings");
    g_alLevelParams = new ArrayList(sizeof(LevelInfo));
    g_alLevelsPrices = new ArrayList();
    if(!g_kvSettings.ImportFromFile("addons/sourcemod/configs/cshop/armor_regen.txt"))
        SetFailState("[CSHOP REGEN ARMOR] No cfg file (addons/sourcemod/configs/cshop/armor_regen.txt)!");

    if(g_kvSettings.JumpToKey("Levels") && g_kvSettings.GotoFirstSubKey(false))
    {
        LevelInfo levelInfo;
        int iUpgradePrice;
        do
        {
            iUpgradePrice = g_kvSettings.GetNum("upgrade_price", -1);
            levelInfo.iArmorToAdd = g_kvSettings.GetNum("armor_to_add", -1);
            if(levelInfo.iArmorToAdd < 1)
                continue;

            levelInfo.iRequiredSeconds = g_kvSettings.GetNum("cd", -1);
            if(levelInfo.iRequiredSeconds < 1)
                continue;

            levelInfo.iMaxArmor = g_kvSettings.GetNum("max_armor", 100);

            g_alLevelParams.PushArray(levelInfo, sizeof(levelInfo));
            if(g_alLevelParams.Length > 1)
                g_alLevelsPrices.Push(iUpgradePrice);
        } while(g_kvSettings.GotoNextKey(false));
    }

    if(g_alLevelParams.Length < 1)
        SetFailState("[CSHOP REGEN ARMOR] No level parameters in cfg file (addons/sourcemod/configs/cshop/armor_regen.txt)!");

    g_kvSettings.Rewind();
}

public void CShop_OnShopStatusChange(bool bActive)
{
    g_bShopEnabled = bActive;
    if(g_bShopEnabled && g_hTimer == INVALID_HANDLE)
        g_hTimer = CreateTimer(1.0, GiveArmorTimer, 0, TIMER_REPEAT);
    else if(!g_bShopEnabled && g_hTimer != INVALID_HANDLE)
        KillTimer(g_hTimer);
}

public void CShop_OnShopLoaded()
{
    g_bShopEnabled = CShop_IsShopActive();
    if(g_bShopEnabled && g_hTimer == INVALID_HANDLE)
        g_hTimer = CreateTimer(1.0, GiveArmorTimer, 0, TIMER_REPEAT);

    if(g_alLevelParams.Length)
        CShop_RegisterItem("hp_armor", "ArmorRegen", "ArmorRegenDesc", OnItemRegistered);
}

void OnItemRegistered(ClanItemId itemId, const char[] sName)
{
    g_itemId = itemId;

    CShop_SetIntItemInfo(itemId, CSHOP_ITEM_PRICE, g_kvSettings.GetNum("price"));
    CShop_SetIntItemInfo(itemId, CSHOP_ITEM_SELLPRICE, g_kvSettings.GetNum("sell_price"));
    CShop_SetIntItemInfo(itemId, CSHOP_ITEM_DURATION, g_kvSettings.GetNum("duration"));

    if(g_alLevelsPrices.Length > 0)
    {
        CShop_SetIntItemInfo(itemId, CSHOP_ITEM_MAX_LEVEL, g_alLevelsPrices.Length+1);
        CShop_SetItemLevelsPrices(itemId, g_alLevelsPrices);
    }
    else
    {
        CShop_SetIntItemInfo(itemId, CSHOP_ITEM_MAX_LEVEL, 1);
    }

    CShop_SetIntItemInfo(itemId, CSHOP_ITEM_TYPE, view_as<int>(CSHOP_TYPE_BUYONLY));
    CShop_SetIntItemInfo(itemId, CSHOP_ITEM_VISIBILITY, 1);
}

Action GiveArmorTimer(Handle timer)
{
    int iArmor, iArmorToAdd, iMaxArmor, iSecondsNeed;
    for(int i = 1; i <= MaxClients; ++i)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && g_iLevel[i])
        {
            iSecondsNeed = GetArmorLevelData(i, iArmorToAdd, iMaxArmor);
            if(g_iSeconds[i] < iSecondsNeed)
            {
                g_iSeconds[i]++;
                continue;
            }

            iArmor = GetEntProp(i, Prop_Send, "m_ArmorValue");
            if(iArmor + iArmorToAdd < iMaxArmor)
                SetEntProp(i, Prop_Send, "m_ArmorValue", iArmor + iArmorToAdd);
            else if(iArmor < iMaxArmor)
                SetEntProp(i, Prop_Send, "m_ArmorValue", iMaxArmor);

            g_iSeconds[i] = 0;
        }
    }
}

/**
 * Получение данных о предмете для игрока
 * 
 * @param iClient         Индекс игрока
 * @param iArmorToAdd     Сколько брони выдавать
 * @param iMaxArmor       Какой лимит брони
 * @return                кол-во требуемых секунд для регена
 */
int GetArmorLevelData(int iClient, int& iArmorToAdd, int& iMaxArmor)
{
    if(g_iLevel[iClient] > g_alLevelParams.Length)
        g_iLevel[iClient] = g_alLevelParams.Length;
    
    int iLevelIndex = g_iLevel[iClient] - 1;
    LevelInfo levelInfo;
    g_alLevelParams.GetArray(iLevelIndex, levelInfo, sizeof(levelInfo));
    
    iArmorToAdd = levelInfo.iArmorToAdd;
    iMaxArmor = levelInfo.iMaxArmor;
    return levelInfo.iRequiredSeconds;
}
                // ===================== ИГРОК ===================== //
public void OnClientPostAdminCheck(int iClient)
{
    g_iLevel[iClient] = 0;
}

/**
 * Вызывается, когда игроку добавился (загрузился) какой-либо предмет
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета в базе
 * @param int iLevel - уровень предмета
 * @param CShop_ItemState state - состояние предмета
 * @param int iExpireTime - срок действия предмета
 * 
 * @noreturn
 */
public void CShop_OnItemAddedToClient(int iClient, ClanItemId itemId, int iLevel, CShop_ItemState state, int iExpireTime)
{
    if(g_itemId == itemId)
        g_iLevel[iClient] = iLevel;
}

/**
 * Вызывается, когда у игрока был отобран предмет
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - id предмета в базе
 * 
 * @noreturn
 */
public void CShop_OnItemRemovedFromClient(int iClient, ClanItemId itemId)
{
    if(g_itemId == itemId)
        g_iLevel[iClient] = 0;
}

/**
 * Вызывается, когда у предмета игрока меняется уровень
 * 
 * @param int iClient - индекс игрока
 * @param ClanItemId itemId - ид предмета
 * @param int iNewLevel - новый уровень предмета
 */
public void CShop_OnClientItemLevelChanged(int iClient, ClanItemId itemId, int iNewLevel)
{
    if(g_itemId == itemId)
        g_iLevel[iClient] = iNewLevel;
}