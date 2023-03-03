#include <sourcemod>
#include <clans>
#include <clans_shop>

#define PLUGIN_LOG_NAME "[CSHOP] "
#define ClanCategoryId int

public Plugin myinfo = 
{ 
	name = "[CLANS SHOP] Core", 
	author = "DreaM", 
	description = "Add clan shop", 
	version = "1.0R2", 
}

enum struct Category
{
    char sName[256];
    int iVisibleItems;
    ArrayList alItems;      // Содержит id'ы ClanItem
}

enum struct ClanItem
{
    ClanItemId id;
    ClanCategoryId categoryId;
    char sName[256];
    char sDesc[256];
    int iPrice;
    int iSellPrice;
    int iDuration;
    int iAmount;            // Текущее число используемых предметов
    int iMaxAmount;
    int iMaxLevel;
    ArrayList alLevelsPrices;
    CShop_ItemType type;
    bool bHidden;
    Handle hPluginOwner;    // Кто зарегистрировал предмет
}

enum struct PlayerItem
{
    ClanItemId itemId;
    ClanCategoryId categoryId;  // Чтобы не лезть в item
    int iLevel;                 // Идет с клана
    CShop_ItemState state;
    int iExpireTime;            // Идет с клана
}

EngineVersion engineVersion;

#define g_bCSGO (engineVersion == Engine_CSGO)
#define g_bCSS (engineVersion == Engine_CSS)
#define g_bCSS34 (engineVersion == Engine_SourceSDK2006)

bool    g_bIsShopEnabled;

#include "cshop/color_chat.sp"
#include "cshop/cvars.sp"
#include "cshop/forwards.sp"
#include "cshop/database.sp"
#include "cshop/helpful.sp"
#include "cshop/categories.sp"
#include "cshop/items.sp"
#include "cshop/player.sp"
#include "cshop/clans.sp"
#include "cshop/expireHandler.sp"   //BETA4
#include "cshop/actions.sp"
#include "cshop/register.sp"
#include "cshop/adminActions.sp"
#include "cshop/menus.sp"
#include "cshop/core_forwards.sp"   //BETA4
#include "cshop/clientCommands.sp"
#include "cshop/adminCommands.sp"
#include "cshop/natives.sp"

public void OnPluginStart()
{
    engineVersion = GetEngineVersion();

    if(Clans_AreClansLoaded())
        Clans_OnClansLoaded();

    InitConVars();
    ConnectToDatabase();
    InitCategories();
    InitItems();
    InitPlayerItems();

    CreateForwards();

    RegClientCmds();
    RegAdminCmds();

    HookChat();                 //BETA2
    InitExpiringItemsArray();    //BETA4

    SetShopStatus(true);

    LoadTranslations("cshop_general.phrases");
    LoadTranslations("cshop_items.phrases");
}

public void OnMapStart()
{
    if(g_Database != null)
    {
        DB_RemoveExpiredRecords();
    }
}