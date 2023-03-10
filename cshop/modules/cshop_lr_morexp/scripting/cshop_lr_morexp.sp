#include <clans_shop>
#include <lvl_ranks>

ClanItemId g_itemId = INVALID_ITEM;

int g_iLevel[MAXPLAYERS+1];
bool g_bShopEnabled = false;

KeyValues g_kvSettings;
ArrayList g_alLevelsPrices = null;
ArrayList g_alLevelBoosts = null;

public Plugin myinfo = 
{ 
	name = "[CSHOP/LR] More XP for Levels Ranks", 
	author = "DreaM", 
	description = "Add more XP for kill for LR to cshop", 
	version = "1.01", 
} 

public void OnPluginStart()
{
    LoadConfig();

    if(CShop_IsShopLoaded())
        CShop_OnShopLoaded();

    LR_Hook(LR_OnPlayerKilledPre, AddPlayerExp);
}

public void OnPluginEnd()
{
    CShop_UnregisterMe();
}

void LoadConfig()
{
    if(g_kvSettings) delete g_kvSettings;
    if(g_alLevelBoosts) delete g_alLevelBoosts;
    if(g_alLevelsPrices) delete g_alLevelsPrices;

    g_kvSettings = new KeyValues("Settings");
    g_alLevelBoosts = new ArrayList();
    g_alLevelsPrices = new ArrayList();
    if(!g_kvSettings.ImportFromFile("addons/sourcemod/configs/cshop/lr_more_xp.txt"))
        SetFailState("[CSHOP LR MORE XP] No cfg file (addons/sourcemod/configs/cshop/lr_more_xp.txt)!");

    if(g_kvSettings.JumpToKey("Levels") && g_kvSettings.GotoFirstSubKey(false))
    {
        int iExpToAdd, iUpgradePrice;
        do
        {
            iUpgradePrice = g_kvSettings.GetNum("upgrade_price", -1);
            iExpToAdd = g_kvSettings.GetNum("exp_to_add", -1);
            if(iExpToAdd < 1)
                continue;
            
            g_alLevelBoosts.Push(iExpToAdd);
            if(g_alLevelBoosts.Length > 1)
                g_alLevelsPrices.Push(iUpgradePrice);
        } while(g_kvSettings.GotoNextKey(false));
    }

    if(g_alLevelBoosts.Length < 1)
        SetFailState("[CSHOP LR MORE XP] No level parameters in cfg file (addons/sourcemod/configs/cshop/lr_more_xp.txt)!");

    g_kvSettings.Rewind();
}

public void CShop_OnShopStatusChange(bool bActive)
{
    g_bShopEnabled = bActive;
}

public void CShop_OnShopLoaded()
{
    g_bShopEnabled = CShop_IsShopActive();
    if(g_alLevelBoosts.Length)
        CShop_RegisterItem("boosts", "LRXP", "LRXPDesc", OnItemRegistered);
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

void AddPlayerExp(Event hEvent, int& iExpCaused, int iClient, int iAttacker)
{
    if(!g_bShopEnabled)
        return;

    int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

    if(g_iLevel[attacker])
        iExpCaused += GetExpToAdd(attacker);
}

/**
 * Получение числа EXP, сколько выдавать игроку
 */
int GetExpToAdd(int iClient)
{
    if(g_iLevel[iClient] > g_alLevelBoosts.Length)
        return 0;

    int iLevelIndex = g_iLevel[iClient] - 1;
    return g_alLevelBoosts.Get(iLevelIndex);
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