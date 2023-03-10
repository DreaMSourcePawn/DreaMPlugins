#include <clans_shop>

ClanItemId g_itemId = INVALID_ITEM;

enum struct LevelInfo
{
    int iHpToAdd;
    int iRequiredSeconds;
    int iMaxHp;
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
	name = "[CSHOP] HP regen", 
	author = "DreaM", 
	description = "Add HP regen to cshop", 
	version = "1.01", 
} 

public void OnPluginStart()
{
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

    if(!g_kvSettings.ImportFromFile("addons/sourcemod/configs/cshop/hp_regen.txt"))
        SetFailState("[CSHOP REGEN HP] No cfg file (addons/sourcemod/configs/cshop/hp_regen.txt)!");

    LevelInfo levelInfo;
    if(g_kvSettings.JumpToKey("Levels") && g_kvSettings.GotoFirstSubKey())
    {
        int iUpgradePrice;
        do
        {
            iUpgradePrice = g_kvSettings.GetNum("upgrade_price", -1);
            levelInfo.iHpToAdd = g_kvSettings.GetNum("hp_to_add", -1);
            if(levelInfo.iHpToAdd < 1)
                continue;

            levelInfo.iRequiredSeconds = g_kvSettings.GetNum("cd", -1);
            if(levelInfo.iRequiredSeconds < 1)
                continue;

            levelInfo.iMaxHp = g_kvSettings.GetNum("max_hp", 100);

            g_alLevelParams.PushArray(levelInfo, sizeof(levelInfo));
            if(g_alLevelParams.Length > 1)
                g_alLevelsPrices.Push(iUpgradePrice);
        } while(g_kvSettings.GotoNextKey());
    }

    if(g_alLevelParams.Length < 1)
        SetFailState("[CSHOP REGEN HP] No level parameters in cfg file (addons/sourcemod/configs/cshop/hp_regen.txt)!");

    g_kvSettings.Rewind();

    CShop_RegisterItem("hp_armor", "HpRegen", "HpRegenDesc", OnItemRegistered);
}

public void CShop_OnShopStatusChange(bool bActive)
{
    g_bShopEnabled = bActive;
    if(g_bShopEnabled && g_hTimer == INVALID_HANDLE)
        g_hTimer = CreateTimer(1.0, GiveHPTimer, 0, TIMER_REPEAT);
    else if(!g_bShopEnabled && g_hTimer != INVALID_HANDLE)
        KillTimer(g_hTimer);
}

public void CShop_OnShopLoaded()
{
    g_bShopEnabled = CShop_IsShopActive();
    LoadConfig();
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

    if(g_bShopEnabled && g_hTimer == INVALID_HANDLE)
        g_hTimer = CreateTimer(1.0, GiveHPTimer, 0, TIMER_REPEAT);
}

Action GiveHPTimer(Handle timer)
{
    int iHealth, iHpToAdd, iMaxHp, iSecondsNeed;
    for(int i = 1; i <= MaxClients; ++i)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && g_iLevel[i])
        {
            iSecondsNeed = GetHpLevelData(i, iHpToAdd, iMaxHp)
            if(g_iSeconds[i] < iSecondsNeed)
            {
                g_iSeconds[i]++;
                continue;
            }

            iHealth = GetEntProp(i, Prop_Send, "m_iHealth");
            if(iHealth + iHpToAdd < iMaxHp)
                SetEntProp(i, Prop_Send, "m_iHealth", iHealth+iHpToAdd);
            else if(iHealth < iMaxHp)
                SetEntProp(i, Prop_Send, "m_iHealth", iMaxHp);

            g_iSeconds[i] = 0;
        }
    }
}

/**
 * Получение данных о предмете для игрока
 * 
 * @param iClient         Индекс игрока
 * @param iHpToAdd        Сколько ХП выдавать
 * @param iMaxHp          Какой лимит ХП
 * @return                кол-во требуемых секунд для регена
 */
int GetHpLevelData(int iClient, int& iHpToAdd, int& iMaxHp)
{
    if(g_iLevel[iClient] > g_alLevelParams.Length)
        g_iLevel[iClient] = g_alLevelParams.Length;
    
    int iLevelIndex = g_iLevel[iClient] - 1;
    LevelInfo levelInfo;
    g_alLevelParams.GetArray(iLevelIndex, levelInfo, sizeof(levelInfo));
    
    iHpToAdd = levelInfo.iHpToAdd;
    iMaxHp = levelInfo.iMaxHp;
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