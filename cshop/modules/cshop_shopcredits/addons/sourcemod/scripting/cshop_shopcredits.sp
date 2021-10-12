#include <sourcemod>
#include <shop>
#include <clans>
#include <clans_shop>

#define ITEM_TYPE TYPE_ONEUSE
#define ITEM_CATEGORY "shopcredits"
#define ITEM_DESC "shopcreditsDesc"

   //Список выдаваемых кредитов вида: "id предмета" "число выдаваемых кредитов"
StringMap g_smCreditList = null;

    //База данных
Handle g_hClansDB = null;

public Plugin myinfo = 
{ 
	name = "[CSHOP] Buy shop credits", 
	author = "Dream", 
	description = "Add opportunity to buy shop credits for a clan", 
	version = "1.0", 
} 

public void OnPluginStart()
{
    char DB_Error[256], query[150];
    g_hClansDB = SQL_Connect("clans", true, DB_Error, sizeof(DB_Error));
    if(g_hClansDB == null)
	{
		SetFailState("[CLANSCREDITS] Unable to connect to database (%s)", DB_Error);
		return;
	}

    Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `players_shopcredits` (`auth` TEXT, `amount` INTEGER) CHARACTER SET utf8 COLLATE utf8_general_ci;");
    SQL_TQuery(g_hClansDB, SQL_LogError, query, 0);
	
    if(CShop_IsShopLoaded())
		CShopLoaded();
}

public void OnPluginEnd()
{
    int     id;
    char    id_char[70];
    StringMapSnapshot snapShot = g_smCreditList.Snapshot();
    for(int i = 0; i < snapShot.Length; i++)
    {
        snapShot.GetKey(i, id_char, sizeof(id_char));
        id = StringToInt(id_char);
        CShop_UnregisterItem(id);
    }
    delete g_smCreditList;
}

public void OnClientPostAdminCheck(int client)
{
    CheckPlayer(client);
}

//=========================== CLAN SHOP forwards ===========================//
public void CShopLoaded()
{
    int price,          //Цена покупки кредитов
        sellprice,      //Цена продажи кредитов
        amount,         //Число выдаваемых кредитов
        id;             //Выданный айди для кредитов

    char    sectionName[70],    //Название предмета в шоп
            id_toChar[70];

    g_smCreditList = CreateTrie();
    KeyValues kv_creditList = CreateKeyValues("shop_credits_buff");
    kv_creditList.ImportFromFile("cfg/clans/cshop_shopcredits_list.txt");

    if(kv_creditList.GotoFirstSubKey())
    {
        do
        {
            kv_creditList.GetSectionName(sectionName, sizeof(sectionName));
            price = kv_creditList.GetNum("price", -1);
            sellprice = kv_creditList.GetNum("sellprice", -1);
            amount = kv_creditList.GetNum("amount", -1);
            id = CShop_RegisterItem(ITEM_CATEGORY, sectionName, ITEM_DESC, price, sellprice, ITEM_INFINITE, ITEM_TYPE);
            IntToString(id, id_toChar, sizeof(id_toChar));
            g_smCreditList.SetValue(id_toChar, amount);
        } while(kv_creditList.GotoNextKey());
    }
    delete kv_creditList;
}

public void CShop_OnItemUsed(int client, int itemid)
{
    int clientClan,             //Клан игрока
        amount;                 //Число кредитов для выдачи
    char itemid_toChar[70];
    IntToString(itemid, itemid_toChar, sizeof(itemid_toChar));
    if(g_smCreditList.GetValue(itemid_toChar, amount))
    {
        clientClan = Clans_GetOnlineClientClan(client);
        SQL_OnShopCreditsUse(clientClan, amount);
        CreateTimer(3.0, Timer_CheckPlayers, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}

//=========================== FUNCTIONS ===========================//
void SQL_OnShopCreditsUse(int clanid, int amount)
{
    char query[110];
    Format(query, sizeof(query), "SELECT * FROM `players_table` WHERE `player_clanid` = '%d'", clanid);
    SQL_TQuery(g_hClansDB, SQL_GetClanPlayersCallback, query, amount);
}

Action Timer_CheckPlayers(Handle timer)
{
    for(int i = 1; i <= MaxClients; i++)
        CheckPlayer(i);
}

void CheckPlayer(int client)
{
    if(IsClientInGame(client) && !IsFakeClient(client))
    {
		char auth[33], query[200];
		GetClientAuthId(client, AuthId_Steam3, auth, sizeof(auth));
		Format(query, sizeof(query), "SELECT `amount` FROM `players_shopcredits` WHERE `auth` = '%s'", auth);
		DataPack dp = CreateDataPack();
		dp.WriteCell(client);
		dp.WriteString(auth);
		dp.Reset();
		SQL_TQuery(g_hClansDB, SQL_PlayerFoundCallBack, query, dp);
    }
}

//=========================== SQL CallBacks ===========================//
void SQL_GetClanPlayersCallback(Handle owner, Handle hndl, const char[] error, int amount)
{
	if(hndl == INVALID_HANDLE) LogError("[CLANSCREDITS] Query Fail load clients: %s", error);
	else
	{
        char auth[33], query[150];
        while(SQL_FetchRow(hndl))
        {
            SQL_FetchString(hndl, 2, auth, sizeof(auth));
            FormatEx(query, sizeof(query), "INSERT INTO `players_shopcredits` VALUES ('%s', '%d')", auth, amount);
            SQL_TQuery(g_hClansDB, SQL_LogError, query, 0);
        }
	}
}

void SQL_LogError(Handle owner, Handle hndl, const char[] error, int anyvar)
{
	if(error[0] != 0)
	{
        LogError("[CLANSCREDITS] Query failed: %s", error);
	}
}

void SQL_PlayerFoundCallBack(Handle owner, Handle hndl, const char[] error, DataPack dp)
{
	if(hndl == INVALID_HANDLE) LogError("[CLANSCREDITS] Query Fail find player: %s", error);
	else if(SQL_FetchRow(hndl))
	{
		char query[130], auth[33];
		int amount = 0;
		int client = dp.ReadCell();
		dp.ReadString(auth, sizeof(auth));
		do
		{
			amount += SQL_FetchInt(hndl, 0);
		} while(SQL_FetchRow(hndl));
		Shop_GiveClientCredits(client, amount);
		FormatEx(query, sizeof(query), "DELETE FROM `players_shopcredits` WHERE `auth` = '%s'", auth);
		SQL_TQuery(g_hClansDB, SQL_LogError, query, 0);
    }
	delete dp;
}