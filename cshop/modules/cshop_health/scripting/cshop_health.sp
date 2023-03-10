#include <clans_shop>

ClanItemId g_itemId = INVALID_ITEM;

int g_iLevel[MAXPLAYERS+1];
bool g_bShopEnabled = false;

KeyValues g_kvSettings;
ArrayList g_alLevelsPrices = null;
ArrayList g_alHpToAdd = null;

public Plugin myinfo = 
{ 
	name = "[CSHOP] More hp", 
	author = "DreaM", 
	description = "Add more hp modifier to cshop", 
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
    if(g_alHpToAdd) delete g_alHpToAdd;
    if(g_alLevelsPrices) delete g_alLevelsPrices;

    g_kvSettings = new KeyValues("Settings");
    g_alHpToAdd = new ArrayList();
    g_alLevelsPrices = new ArrayList();
    if(!g_kvSettings.ImportFromFile("addons/sourcemod/configs/cshop/cshop_health.txt"))
        SetFailState("[CSHOP HP] No cfg file (addons/sourcemod/configs/cshop/cshop_health.txt)!");

    if(g_kvSettings.JumpToKey("Levels") && g_kvSettings.GotoFirstSubKey(false))
    {
        int iHpToAdd, iUpgradePrice;
        do
        {
            iUpgradePrice = g_kvSettings.GetNum("upgrade_price", -1);
            iHpToAdd = g_kvSettings.GetNum("add_hp", -1);
            if(iHpToAdd < 1)
                continue;
            
            g_alHpToAdd.Push(iHpToAdd);
            if(g_alHpToAdd.Length > 1)
                g_alLevelsPrices.Push(iUpgradePrice);
        } while(g_kvSettings.GotoNextKey(false));
    }

    bool bOnSpawn = g_kvSettings.GetNum("give_on_spawn", 0) == 1;

    if(bOnSpawn)
        HookEvent("player_spawn", OnSpawn);
    else
        HookEvent("round_start", OnRoundStart);

    if(g_alHpToAdd.Length < 1)
        SetFailState("[CSHOP HP] No level parameters in cfg file (addons/sourcemod/configs/cshop/cshop_health.txt)!");

    g_kvSettings.Rewind();
}

public void CShop_OnShopStatusChange(bool bActive)
{
    g_bShopEnabled = bActive;
}

public void CShop_OnShopLoaded()
{
    g_bShopEnabled = CShop_IsShopActive();
    if(g_alHpToAdd.Length)
        CShop_RegisterItem("hp_armor", "MoreHp", "MoreHpDesc", OnItemRegistered);
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

void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if(!g_bShopEnabled)
        return;

    int iHealth, iHpToAdd;
    for(int i = 1; i <= MaxClients; ++i)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && g_iLevel[i])
        {
            iHpToAdd = GetHpToAdd(i);
            if(iHpToAdd)
            {
                iHealth = GetEntProp(i, Prop_Send, "m_iHealth");
                SetEntProp(i, Prop_Send, "m_iHealth", iHealth+iHpToAdd);
            }
        }
    }
}

void OnSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    if(!g_bShopEnabled)
        return;

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(g_iLevel[client])
    {
        int iHpToAdd = GetHpToAdd(client);
        if(iHpToAdd)
        {
            int iHealth = GetEntProp(client, Prop_Send, "m_iHealth");
            SetEntProp(client, Prop_Send, "m_iHealth", iHealth+iHpToAdd);
        }
    }
}

/**
 * Получение числа HP, сколько выдавать игроку
 */
int GetHpToAdd(int iClient)
{
    if(g_iLevel[iClient] > g_alHpToAdd.Length)
        g_iLevel[iClient] = g_alHpToAdd.Length;

    int iLevelIndex = g_iLevel[iClient] - 1;
    return g_alHpToAdd.Get(iLevelIndex);
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
    if(itemId == g_itemId)
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