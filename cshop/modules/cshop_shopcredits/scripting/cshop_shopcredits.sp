#include <shop>
#include <clans_shop>

#define PATH_TO_CFG "addons/sourcemod/configs/cshop/shopcredits.txt"

ClanItemId g_itemId = INVALID_ITEM;

enum struct LevelInfo
{
    int iAmountToGive;
	bool bDivide;	// Разделить среди всех участников
}

KeyValues g_kvSettings;
ArrayList g_alLevelsPrices = null;
ArrayList g_alLevelParams = null;

Database g_hClansDB = null;
int		 g_iServerId = -1;

public Plugin myinfo = 
{ 
	name = "[CSHOP/SHOP] Shop credits", 
	author = "DreaM", 
	description = "Add shop credits to cshop", 
	version = "1.0", 
} 

public void OnPluginStart()
{
	LoadConfig();

	if(SQL_CheckConfig("clans"))
		Database.Connect(OnDatabaseConnected, "clans");
	else
		SetFailState("[CSHOP SHOP CREDITS] No database configuration \"clans\" in databases.cfg!");
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
		SetFailState("[CSHOP SHOP CREDITS] No cfg file (%s)!", PATH_TO_CFG);

	g_iServerId = g_kvSettings.GetNum("server_id", -1);

	if(g_kvSettings.JumpToKey("Levels") && g_kvSettings.GotoFirstSubKey(false))
	{
		LevelInfo levelInfo;
		int iUpgradePrice;
		do
		{
			iUpgradePrice = g_kvSettings.GetNum("upgrade_price", ITEM_NOTBUYABLE);
			levelInfo.iAmountToGive = g_kvSettings.GetNum("amount", -1);
			if(levelInfo.iAmountToGive < 1)
				continue;
			levelInfo.bDivide = g_kvSettings.GetNum("divide", 0) == 1;

			g_alLevelParams.PushArray(levelInfo, sizeof(levelInfo));
			if(g_alLevelParams.Length > 1)
				g_alLevelsPrices.Push(iUpgradePrice);
		} while(g_kvSettings.GotoNextKey(false));
	}

	if(g_alLevelParams.Length < 1)
		SetFailState("[CSHOP SHOP CREDITS] No level parameters in cfg file (%s)!", PATH_TO_CFG);

	g_kvSettings.Rewind();
}

void OnDatabaseConnected(Database db, const char[] sError, any data)
{
	g_hClansDB = db;

	if(g_hClansDB == null)
		SetFailState("[CSHOP SHOP CREDITS] Unable to connect to database: %s", sError);

	g_hClansDB.Query(DB_CreateTableCallback, "CREATE TABLE IF NOT EXISTS players_shopcredits (auth CHAR(32), amount INT, server_id INT);");
}

void DB_CreateTableCallback(Database db, DBResultSet rSet, const char[] sError, int iData)
{
	if(sError[0])
		SetFailState("[CSHOP SHOP CREDITS] Unable to create table: %s", sError);
	else if(CShop_IsShopLoaded())
        CShop_OnShopLoaded();
}

public void CShop_OnShopLoaded()
{
    if(g_alLevelParams.Length && g_hClansDB != null)
        CShop_RegisterItem("shop", "ShopCredits", "ShopCreditsDesc", OnItemRegistered);
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

    CShop_SetIntItemInfo(itemId, CSHOP_ITEM_TYPE, view_as<int>(CSHOP_TYPE_ONEUSE));
    CShop_SetIntItemInfo(itemId, CSHOP_ITEM_VISIBILITY, 1);
}

/**
 * Получить кол-во кредитов, которые выдаются для указанного уровня
 * 
 * @param iLevel	уровень, для которого смотрим
 * @param &iAmountToGive	кол-во кредитов для этого уровня
 * 
 * @return			true - разделить на всех, иначе false
 */
bool GetInfoOfCredits(int iLevel, int& iAmountToGive)
{
	int iLevelIndex = iLevel - 1;
	LevelInfo levelInfo;
	g_alLevelParams.GetArray(iLevelIndex, levelInfo, sizeof(levelInfo));
	iAmountToGive = levelInfo.iAmountToGive;
	return levelInfo.bDivide;
}
                // ===================== ИГРОК ===================== //
public void Shop_OnAuthorized(int iClient)
{
    CheckPlayer(iClient);
}

/**
 * Проверить, есть ли кредиты для выдачи у игрока
 * 
 * @param iClient     Индекс игрока
 * @noreturn
 */
void CheckPlayer(int iClient)
{
	char sSteam2[32], sSteam3[32], query[256];
	GetClientAuthId(iClient, AuthId_Steam2, sSteam2, sizeof(sSteam3));
	GetClientAuthId(iClient, AuthId_Steam3, sSteam3, sizeof(sSteam3));
	FormatEx(query, sizeof(query), "SELECT SUM(amount) FROM players_shopcredits WHERE (auth = '%s' OR auth = '%s') AND server_id = %d", 
					sSteam2, sSteam3, g_iServerId);

	DataPack dp = new DataPack();
	dp.WriteCell(iClient);
	dp.WriteString(sSteam2);
	dp.Reset();
	g_hClansDB.Query(DB_CheckPlayerCallback, query, dp);
}

/**
 * Коллбэк получения числа кредитов, которые должны выдать игроку
 */
void DB_CheckPlayerCallback(Database db, DBResultSet rSet, const char[] sError, DataPack dp)
{
	int iClient = dp.ReadCell();
	if(sError[0])
	{
		LogError("[CSHOP SHOP CREDITS] Failed to get amount of credits for player %L: %s", iClient, sError);
	}
	else if(rSet.FetchRow() && IsClientInGame(iClient))
	{
		char sSteamFromDp[32], sPlayerSteam[32];
		dp.ReadString(sSteamFromDp, sizeof(sSteamFromDp));

		if(sSteamFromDp[0] == 'S')
			GetClientAuthId(iClient, AuthId_Steam2, sPlayerSteam, sizeof(sPlayerSteam));
		else
			GetClientAuthId(iClient, AuthId_Steam3, sPlayerSteam, sizeof(sPlayerSteam));

		// Вдруг наш запрос так долго ходил-бродил, что уже другой игрок под индексом этим
		if(!strcmp(sPlayerSteam, sSteamFromDp))
		{
			int iAmountToGive = rSet.FetchInt(0);
			if(!IsFakeClient(iClient))
				Shop_GiveClientCredits(iClient, iAmountToGive);
			char sSteam2[32], sSteam3[32], query[256];
			GetClientAuthId(iClient, AuthId_Steam2, sSteam2, sizeof(sSteam3));
			GetClientAuthId(iClient, AuthId_Steam3, sSteam3, sizeof(sSteam3));
			FormatEx(query, sizeof(query), "DELETE FROM players_shopcredits WHERE (auth = '%s' OR auth = '%s') AND server_id = %d", 
							sSteam2, sSteam3, g_iServerId);
			g_hClansDB.Query(DB_DeletePlayerCallback, query);
		}
	}
	delete dp;
}

void DB_DeletePlayerCallback(Database db, DBResultSet rSet, const char[] sError, int iData)
{
	if(sError[0])
		LogError("[CSHOP SHOP CREDITS] Failed to remove player: %s", sError);
}
                // ===================== КЛАН ===================== //
/**
 * Вызывается, когда клановый предмет используется
 * 
 * @param int iClanId - ид клана
 * @param ClanItemId itemId - ид предмета
 * @param int iLevel - уровень используемого предмета
 * 
 * @noreturn
 */
public void CShop_OnClanItemUsed(int iClanId, ClanItemId itemId, int iLevel)
{
	if(itemId == g_itemId)
	{
		int iAmountToGive;
		bool bDivide = GetInfoOfCredits(iLevel, iAmountToGive);
		
		if(bDivide)
			GiveClanDividedCredits(iClanId, iAmountToGive);
		else
			GiveClanCredits(iClanId, iAmountToGive);
	}
}

/**
 * Выдать клану кредиты, поделенные поровну среди всех
 * 
 * @param iClanId		Ид клана
 * @param iAmountToGive		Общее кол-во кредитов
 * 
 * @noreturn
 */
void GiveClanDividedCredits(int iClanId, int iAmountToGive)
{
	DataPack dp = new DataPack();
	dp.WriteCell(iClanId);
	dp.WriteCell(iAmountToGive);
	dp.Reset();
	char query[128];
	FormatEx(query, sizeof(query), "SELECT COUNT(*) FROM players_table WHERE player_clanid = %d", iClanId);
	g_hClansDB.Query(DB_GetAmountOfMembersCallback, query, dp);
}

/**
 * Коллбэк получения числа игроков в клане
 */
void DB_GetAmountOfMembersCallback(Database db, DBResultSet rSet, const char[] sError, DataPack dp)
{
	int iClanId = dp.ReadCell();
	int iAmountToGive = dp.ReadCell();
	if(sError[0])
	{
		LogError("[CSHOP SHOP CREDITS] Failed to get amount of members in clan with %d ID to give %d credits: %s", iClanId, iAmountToGive, sError);
	}
	else if(rSet.FetchRow())
	{
		int iMembers = rSet.FetchInt(0);
		iAmountToGive /= iMembers;
		GiveClanCredits(iClanId, iAmountToGive);
	}
	delete dp;
}

/**
 * Выдать кредиты клану
 * 
 * @param iClanId     Ид клана
 * @param iAmountToGive     Сколько выдать КАЖДОМУ игроку клана
 * @noreturn
 */
void GiveClanCredits(int iClanId, int iAmountToGive)
{
	DataPack dp = new DataPack();
	dp.WriteCell(iClanId);
	dp.WriteCell(iAmountToGive);
	dp.Reset();
	char query[128];
	FormatEx(query, sizeof(query), "SELECT player_steam FROM players_table WHERE player_clanid = %d", iClanId);
	g_hClansDB.Query(DB_GetPlayersSteamCallback, query, dp);
}

/**
 * Коллбэк для получения списка стимов игроков
 */
void DB_GetPlayersSteamCallback(Database db, DBResultSet rSet, const char[] sError, DataPack dp)
{
	int iClanId = dp.ReadCell();
	int iAmountToGive = dp.ReadCell();
	if(sError[0])
	{
		LogError("[CSHOP SHOP CREDITS] Failed to give %d credits to clan with %d ID: %s", iAmountToGive, iClanId, sError);
	}
	else if(rSet.FetchRow())
	{
		char sSteamId[32], query[128], onlinePlayerSteam[32];
		bool bGave;
		do
		{
			bGave = false;
			rSet.FetchString(0, sSteamId, sizeof(sSteamId));
			for(int i = 1; !bGave && i <= MaxClients; ++i)
			{
				if(!IsClientInGame(i))
					continue;

				if(sSteamId[0] == 'S')
					GetClientAuthId(i, AuthId_Steam2, onlinePlayerSteam, sizeof(onlinePlayerSteam));
				else
					GetClientAuthId(i, AuthId_Steam3, onlinePlayerSteam, sizeof(onlinePlayerSteam));

				if(!strcmp(sSteamId, onlinePlayerSteam))
				{
					if(!IsFakeClient(i))
						Shop_GiveClientCredits(i, iAmountToGive);
					bGave = true;
				}
			}
			if(!bGave)
			{
				FormatEx(query, sizeof(query), "INSERT INTO players_shopcredits VALUES ('%s', %d, %d)", sSteamId, iAmountToGive, g_iServerId);
				g_hClansDB.Query(DB_InsertPlayerCallback, query);
			}
		} while(rSet.FetchRow());
	}

	delete dp;
}

/**
 * Лог ошибки, если игрока не удалось записать в таблицу
 */
void DB_InsertPlayerCallback(Database db, DBResultSet rSet, const char[] sError, DataPack dp)
{
	if(sError[0])
		LogError("[CSHOP SHOP CREDITS] Failed to insert player to table: %s", sError);
}