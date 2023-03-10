#include <sdkhooks>
#include <clans_shop>

#define PATH_TO_CFG "addons/sourcemod/configs/cshop/damage_multipliers.txt"

ClanItemId g_itemId = INVALID_ITEM;

enum struct LevelInfo
{
	int iUpgradePrice;
    float fGiveDamageMult;
    float fTakenDamageMult;
}

int g_iLevel[MAXPLAYERS+1];
bool g_bShopEnabled = false;

KeyValues g_kvSettings;
ArrayList g_alLevelsPrices = null;
ArrayList g_alLevelParams = null;

public Plugin myinfo = 
{ 
	name = "[CSHOP] Damage multipliers", 
	author = "DreaM", 
	description = "Add damage multipliers to cshop", 
	version = "1.0", 
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

	if(!g_kvSettings.ImportFromFile(PATH_TO_CFG))
		SetFailState("[CSHOP DMG MULT] No cfg file (%s)!", PATH_TO_CFG);

	if(g_kvSettings.JumpToKey("Levels") && g_kvSettings.GotoFirstSubKey(false))
	{
		LevelInfo levelInfo;
		do
		{
			levelInfo.iUpgradePrice = g_kvSettings.GetNum("upgrade_price", ITEM_NOTBUYABLE);
			levelInfo.fGiveDamageMult = g_kvSettings.GetFloat("give_mult", 1.0);
			levelInfo.fTakenDamageMult = g_kvSettings.GetFloat("take_mult", 1.0);

			g_alLevelParams.PushArray(levelInfo, sizeof(levelInfo));
			if(g_alLevelParams.Length > 1)
				g_alLevelsPrices.Push(levelInfo.iUpgradePrice);
		} while(g_kvSettings.GotoNextKey(false));
	}

	if(g_alLevelParams.Length < 1)
		SetFailState("[CSHOP DMG MULT] No level parameters in cfg file (%s)!", PATH_TO_CFG);

	g_kvSettings.Rewind();
}

public void CShop_OnShopStatusChange(bool bActive)
{
    g_bShopEnabled = bActive;
}

public void CShop_OnShopLoaded()
{
    g_bShopEnabled = CShop_IsShopActive();
    if(g_alLevelParams.Length)
        CShop_RegisterItem("boosts", "DmgMult", "DmgMultDesc", OnItemRegistered);
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

    CShop_SetIntItemInfo(itemId, CSHOP_ITEM_TYPE, view_as<int>(CSHOP_TYPE_TOGGLEABLE));
    CShop_SetIntItemInfo(itemId, CSHOP_ITEM_VISIBILITY, 1);
}

float GetGiveDamageMultiplier(int iClient)
{
	if(g_iLevel[iClient] > g_alLevelParams.Length)
		g_iLevel[iClient] = g_alLevelParams.Length;

	int iLevelIndex = g_iLevel[iClient] - 1;
	LevelInfo levelInfo;
	g_alLevelParams.GetArray(iLevelIndex, levelInfo, sizeof(levelInfo));
	return levelInfo.fGiveDamageMult;
}

float GetTakenDamageMultiplier(int iClient)
{
	if(g_iLevel[iClient] > g_alLevelParams.Length)
		g_iLevel[iClient] = g_alLevelParams.Length;

	int iLevelIndex = g_iLevel[iClient] - 1;
	LevelInfo levelInfo;
	g_alLevelParams.GetArray(iLevelIndex, levelInfo, sizeof(levelInfo));
	return levelInfo.fTakenDamageMult;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(g_bShopEnabled && victim && attacker && attacker <= MAXPLAYERS && (g_iLevel[attacker] || g_iLevel[victim]) )
	{
		float fDamageMult = 1.0;
		if(g_iLevel[attacker])
		{
			fDamageMult = GetGiveDamageMultiplier(attacker);
		}

		if(g_iLevel[victim])
		{
			fDamageMult *= GetTakenDamageMultiplier(victim);
		}

		damage = damage*fDamageMult;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
                // ===================== ИГРОК ===================== //
public void OnClientPostAdminCheck(int iClient)
{
	g_iLevel[iClient] = 0;
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
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