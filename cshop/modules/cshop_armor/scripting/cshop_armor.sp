#include <clans_shop>

ClanItemId g_itemId = INVALID_ITEM;

int g_iLevel[MAXPLAYERS+1];
bool g_bShopEnabled = false;

KeyValues g_kvSettings;
ArrayList alLevelsPrices = null;

public Plugin myinfo = 
{ 
	name = "[CSHOP] Armor", 
	author = "DreaM", 
	description = "Add armor to cshop", 
	version = "1.01", 
} 

public void OnPluginStart()
{
    LoadConfig();

    if(CShop_IsShopLoaded())
        CShop_OnShopLoaded();

    HookEvent("round_start", OnRoundStart);
}

public void OnPluginEnd()
{
    CShop_UnregisterMe();
}

void LoadConfig()
{
    if(g_kvSettings) delete g_kvSettings;
    if(alLevelsPrices) delete alLevelsPrices;

    g_kvSettings = new KeyValues("Settings");
    alLevelsPrices = new ArrayList();
    if(!g_kvSettings.ImportFromFile("addons/sourcemod/configs/cshop/armor.txt"))
        SetFailState("[CSHOP ARMOR] No cfg file (addons/sourcemod/configs/cshop/armor.txt)!");

    if(g_kvSettings.JumpToKey("Levels") && g_kvSettings.GotoFirstSubKey(false))
    {
        int iLevelPrice;
        do
        {
            iLevelPrice = g_kvSettings.GetNum(NULL_STRING);
            if(iLevelPrice)
                alLevelsPrices.Push(iLevelPrice);
        } while(g_kvSettings.GotoNextKey(false));
    }

    g_kvSettings.Rewind();
}

public void CShop_OnShopStatusChange(bool bActive)
{
    g_bShopEnabled = bActive;
}

public void CShop_OnShopLoaded()
{
    g_bShopEnabled = CShop_IsShopActive();
    if(g_kvSettings)
        CShop_RegisterItem("hp_armor", "Armor", "ArmorDesc", OnItemRegistered);
}

void OnItemRegistered(ClanItemId itemId, const char[] sName)
{
    g_itemId = itemId;

    CShop_SetIntItemInfo(itemId, CSHOP_ITEM_PRICE, g_kvSettings.GetNum("price"));
    CShop_SetIntItemInfo(itemId, CSHOP_ITEM_SELLPRICE, g_kvSettings.GetNum("sell_price"));
    CShop_SetIntItemInfo(itemId, CSHOP_ITEM_DURATION, g_kvSettings.GetNum("duration"));

    if(alLevelsPrices.Length > 0)
    {
        CShop_SetIntItemInfo(itemId, CSHOP_ITEM_MAX_LEVEL, alLevelsPrices.Length+1);
        CShop_SetItemLevelsPrices(itemId, alLevelsPrices);
    }
    else
    {
        CShop_SetIntItemInfo(itemId, CSHOP_ITEM_MAX_LEVEL, 1);
    }

    CShop_SetIntItemInfo(itemId, CSHOP_ITEM_TYPE, view_as<int>(CSHOP_TYPE_BUYONLY));
    CShop_SetIntItemInfo(itemId, CSHOP_ITEM_VISIBILITY, 1);
}

void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if(!g_bShopEnabled)
        return;

    int iArmor, iMaxArmor;
    for(int i = 1; i <= MaxClients; ++i)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && g_iLevel[i])
        {
            iArmor = GetEntProp(i, Prop_Send, "m_ArmorValue");
            iMaxArmor = GetMaxArmor(g_iLevel[i]);
            if(iArmor < iMaxArmor)
                SetEntProp(i, Prop_Send, "m_ArmorValue", iMaxArmor);
            
            if(g_iLevel[i] == 3)
                SetEntProp(i, Prop_Send, "m_bHasHelmet", 1);
        }
    }
}

int GetMaxArmor(int iLevel)
{
    if(iLevel > 2)
        --iLevel;
    
    return 50*iLevel;
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