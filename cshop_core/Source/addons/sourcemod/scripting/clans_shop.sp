#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clans>
#include <clans_shop>
#include <morecolors>

#pragma newdecls required

#define CLANKEY_SIZE 70
#define BUFF_SIZE 100
#define CLAN_CATEGORY 80
#define UPDATE_TIME 1
#define UPDATE_TIMEF 1.0

#define PLUGIN_VERSION "1.1"

//Database Handle
Handle g_hClanShopDB = null;

int maxItemIndex = -1;

bool g_bShopEnabled = true;
bool g_bShopLoaded = false;

//key - item/clan_item id
KeyValues g_kvItems;
KeyValues g_kvClans;
KeyValues g_kvCategories;
KeyValues g_kvPlayerItems[MAXPLAYERS+1];

/*
	Item in clan info:
		0 - Item id
		1 - Item state in client's clan:
			0 - item isn't bought
			1 - item is bought and unactive
			2 - item is bought and active
			3 - item is bought and ready to be used
		
*/
int itemInClanInfo[MAXPLAYERS+1][2];

/*
	Admin action flag:
		0 - Looking inventory
		1 - Give item
		2 - Take item
		3 - Reset clan
			X - clan id
	default: [-1][-1]
*/
int admin_SelectMode[MAXPLAYERS+1][2];

//Flag of return from item desc menu. True - open inventory, false - buy menu
bool openInventory[MAXPLAYERS+1];

Handle	g_hPlayerLoaded,			//CShop_OnPlayerLoaded forward
		g_hItemStateChanged,		//CShop_OnItemStateChanged forward
		g_hItemUsed;				//CShop_OnItemUsed forward

Handle g_tUpdateItems = null;

bool mySQL = true;

public Plugin myinfo = 
{ 
	name = "[Clans] Shop", 
	author = "Dream", 
	description = "Add shop for clans", 
	version = PLUGIN_VERSION, 
} 

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("CShop_IsShopLoaded", Native_IsShopLoaded);
	CreateNative("CShop_GetShopStatus", Native_GetShopStatus);
	CreateNative("CShop_SetShopStatus", Native_SetShopStatus);
	CreateNative("CShop_RegisterItem", Native_RegisterItem);
	CreateNative("CShop_UnregisterItem", Native_UnregisterItem);
	CreateNative("CShop_PlayerGetItemState", Native_PlayerGetItemState);
	CreateNative("CShop_PlayerSetItemState", Native_PlayerSetItemState);
	CreateNative("CShop_IsItemActive", Native_IsItemActive);
	CreateNative("CShop_HasClanAnyItems", Native_HasClanAnyItems);
	CreateNative("CShop_SetItemPrice", Native_SetItemPrice);
	CreateNative("CShop_SetItemSellPrice", Native_SetItemSellPrice);
	CreateNative("CShop_SetItemDuration", Native_SetItemDuration);

	//Forwards
	g_hPlayerLoaded = CreateGlobalForward("CShop_OnPlayerLoaded", ET_Ignore, Param_Cell);
	g_hItemStateChanged = CreateGlobalForward("CShop_OnItemStateChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hItemUsed = CreateGlobalForward("CShop_OnItemUsed", ET_Ignore, Param_Cell, Param_Cell);
	return APLRes_Success; 
}

public void OnPluginStart()
{
	RegAdminCmd("sm_acshop", Command_AdminMenu, ADMFLAG_ROOT);
	RegAdminCmd("sm_dumpshop", Command_DumpShop, ADMFLAG_ROOT);

	RegConsoleCmd("sm_cshop", Command_ClanShop);
	//RegConsoleCmd("sm_ctest", Command_Test);
	
	g_kvItems = CreateKeyValues("Shop_Items");
	g_kvClans = CreateKeyValues("Shop_Clans");
	g_kvCategories = CreateKeyValues("Shop_Categories");
	for(int i = 1; i < MAXPLAYERS+1; i++)
		g_kvPlayerItems[i] = CreateKeyValues("Player_Items");

	if (!SQL_CheckConfig("clans_shop"))
	{
		mySQL = false;
		//SetFailState("\"clans\" не найдена в databases.cfg");
	}
	
	char DB_Error[256];
	DB_Error[0] = '\0';
	if(mySQL)
		g_hClanShopDB = SQL_Connect("clans_shop", true, DB_Error, sizeof(DB_Error));
	else
		g_hClanShopDB = SQLite_UseDatabase("clans_shop", DB_Error, sizeof(DB_Error));
	if(g_hClanShopDB == INVALID_HANDLE)
	{
		SetFailState("[CShop] Unable to connect to database (%s)", DB_Error);
		return;
	}
	
	SQL_LockDatabase(g_hClanShopDB);
	
	SQL_FastQuery(g_hClanShopDB, "CREATE TABLE IF NOT EXISTS `shop_clans` (`clan_id` INTEGER, `item_id` INTEGER, `item_duration` INTEGER,\
									`purchase_date` TEXT)");

	SQL_FastQuery(g_hClanShopDB, "CREATE TABLE IF NOT EXISTS `shop_players` (`player_id` INTEGER, `clan_id` INTEGER, `item_id` INTEGER, `item_state` INTEGER)");
	
	SQL_FastQuery(g_hClanShopDB, "CREATE TABLE IF NOT EXISTS `shop_items` (`item_id` INTEGER AUTO_INCREMENT, `item_category` TEXT,\
									`item_name` TEXT, `item_desc` TEXT, `item_price` INTEGER default '-1', `item_sellprice` INTEGER default '-1',\
									`item_duration` INTEGER default '-1', `item_type` INTEGER default '1')");
	
	SQL_UnlockDatabase(g_hClanShopDB);
	
	LoadTranslations("clan_shop_general.phrases");
	LoadTranslations("clan_shop_categories.phrases");
	LoadTranslations("clan_shop_items.phrases");
	
	ShopLoaded();
}

public void OnPluginEnd()
{
	Shop_SaveClans();
	Shop_SaveItems();
}

void ShopLoaded()
{
	char query[100];
	Format(query, sizeof(query), "SELECT * FROM `shop_items` ORDER BY `item_id` DESC");
	DBResultSet hQuery = SQL_Query(g_hClanShopDB, query, sizeof(query));
	if(hQuery == null)
	{
		char error[255];
		SQL_GetError(g_hClanShopDB, error, sizeof(error));
		LogError("[CLAN SHOP] Unable to load items from database. Error: %s", error);
	}
	else
	{
		if(SQL_FetchRow(hQuery))
			maxItemIndex = SQL_FetchInt(hQuery, 0);
		CloseHandle(hQuery);
	}
	
	g_bShopLoaded = true;

	CreateTimer(2.0, StartShopLoad, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action StartShopLoad(Handle timer)
{
	Handle plugin;
	Handle thisplugin = GetMyHandle();
	Handle plugIter = GetPluginIterator();
	while (MorePlugins(plugIter))
	{
		plugin = ReadPlugin(plugIter);
		if (plugin != thisplugin && GetPluginStatus(plugin) == Plugin_Running)
		{
			Function func = GetFunctionByName(plugin, "CShopLoaded");
			if (func != INVALID_FUNCTION)
			{
				Call_StartFunction(plugin, func);
				Call_Finish();
			}
		}
	}
	delete plugIter;
	delete plugin;
	delete thisplugin;
	if(g_bShopEnabled && g_tUpdateItems == null)
		g_tUpdateItems = CreateTimer(UPDATE_TIMEF, UpdateItems, _, TIMER_REPEAT);
}

public Action UpdateItems(Handle timer)
{
	UpdateItemsInClans();
}

public void OnClientPostAdminCheck(int client)
{
	Shop_LoadPlayer(client);
	openInventory[client] = false;
	admin_SelectMode[client][0] = -1;
	admin_SelectMode[client][1] = -1;
	itemInClanInfo[client][0] = -1;
	itemInClanInfo[client][1] = -1;
}

public void OnMapEnd()
{
	if(g_bShopEnabled)
	{
		Shop_SaveClans();
		Shop_SaveItems();
	}
}

public void Clans_OnClanDeleted(int clanid)
{
	DeleteClan(clanid);
}

public void Clans_OnClientAdded(int client, int clientID, int clanid)
{
	
}

public void Clans_OnClientDeleted(int clientID, int clanid)
{
	Shop_DeletePlayer(clientID);
	bool stop = false;
	for(int i = 1; !stop && i < MAXPLAYERS+1; i++)
	{
		if(Clans_GetClientID(i) == clientID)
		{
			delete g_kvPlayerItems[i];
			g_kvPlayerItems[i] = CreateKeyValues("Player_Items");
			stop = true;
		}
	}
}
//=============================== COMMANDS FOR CLANS FOR USERS ===============================//
public Action Command_ClanShop(int client, int args)
{
	AdminId adminid = GetUserAdmin(client);
	if(!g_bShopEnabled && !GetAdminFlag(adminid, Admin_Root))
	{
		char buff[BUFF_SIZE];
		FormatEx(buff, sizeof(buff), "%T", "ShopUnable", client);
		CPrintToChat(client, buff);
		return Plugin_Continue;
	}
	int clanid = Clans_GetOnlineClientClan(client);
	if(clanid == -1 && !GetAdminFlag(adminid, Admin_Root))
	{
		char buff[BUFF_SIZE];
		FormatEx(buff, sizeof(buff), "%T", "NotInClan", client);
		CPrintToChat(client, buff);
		return Plugin_Continue;
	}
	ThrowClanShopMainMenu(client);
	return Plugin_Continue;
}

/*public Action Command_Test(int client, int args)
{
	char output[1024];
	g_kvPlayerItems[client].ExportToString(output, sizeof(output));
	PrintToServer(output);
	g_kvClans.ExportToString(output, sizeof(output));
	PrintToServer(output);
}*/
//=============================== COMMANDS FOR CLANS FOR ADMINS ===============================//
public Action Command_AdminMenu(int client, int args)
{
	ThrowAdminMenu(client);
}

public Action Command_DumpShop(int client, int args)	//Will be removed later. It's useful while testing the clan shop
{
	File file;
	file = OpenFile("cfg/clans/cshop_dump.txt", "w", false, NULL_STRING);
	if(file != null)
	{
		g_kvCategories.Rewind();
		g_kvCategories.ExportToFile("cfg/clans/categories_dump.txt");
		g_kvClans.Rewind();
		g_kvClans.ExportToFile("cfg/clans/clans_dump.txt");
		g_kvItems.Rewind();
		g_kvItems.ExportToFile("cfg/clans/items_dump.txt");
	}
	delete file;
	return Plugin_Stop;
}
//=============================== ACTIONS IN CLAN BASE MENUS ===============================//
//Calls when client open main clan menu (!myclan)
public void Clans_OnClanMenuOpened(Handle clanMenu, int client)
{
	char buff[BUFF_SIZE];
	FormatEx(buff, sizeof(buff), "%T", "ClanShop", client);
	if(Clans_IsClanLeader(Clans_GetClientID(client)))
		InsertMenuItem(clanMenu, 5, "ClanShop", buff, 0);
	else
		InsertMenuItem(clanMenu, 4, "ClanShop", buff, 0);
}

//Calls when client selected missing menu item in base clan menu. 
public void Clans_OnClanMenuSelected(Handle clanMenu, int client, int option)
{
	char selectedItem[50];
	int buff;
	GetMenuItem(clanMenu, option, selectedItem, sizeof(selectedItem), buff, "", 0);
	if(!strcmp(selectedItem, "ClanShop"))
	{
		AdminId adminid = GetUserAdmin(client);
		if(!g_bShopEnabled && !GetAdminFlag(adminid, Admin_Root))
		{
			char c_buff[50];
			FormatEx(c_buff, sizeof(c_buff), "%T", "ShopUnable", client);
			CPrintToChat(client, c_buff);
		}
		else
			ThrowClanShopMainMenu(client);
	}
}
//=============================== MENUS ===============================//
//Clan shop main menu
public int CShop_MainClanShopSelectMenu(Handle clanShopMainMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char selectedItem[50];
		int buff;
		GetMenuItem(clanShopMainMenu, option, selectedItem, sizeof(selectedItem), buff, "", 0);
		if(!strcmp(selectedItem, "Buy"))
		{
			openInventory[client] = false;
			ThrowClanCategoryMenu(client);
		}
		else if(!strcmp(selectedItem, "Inventory"))
		{
			openInventory[client] = true;
			ThrowClanInventoryCategoryMenu(client, Clans_GetOnlineClientClan(client));
		}
		else if(!strcmp(selectedItem, "Admin"))
		{
			ThrowAdminMenu(client);
		}
	}
	else if (action == MenuAction_End && action == MenuAction_Cancel)
	{
		openInventory[client] = false;
		CloseHandle(clanShopMainMenu);
	}
}

//List of items in clan shop in X category
public int CShop_BuyClanShopSelectMenu(Handle clanShopBuyMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char selectedItem[50];
		int buff;
		GetMenuItem(clanShopBuyMenu, option, selectedItem, sizeof(selectedItem), buff, "", 0);
		if(admin_SelectMode[client][0] == -1)
		{
			itemInClanInfo[client][0] = StringToInt(selectedItem);
			ThrowItemMenu(client, itemInClanInfo[client][0]);
		}
		else if(admin_SelectMode[client][0] == 1)
		{
			char category[CLAN_CATEGORY], c_buff[2*BUFF_SIZE], item_name[CLANKEY_SIZE];
			int itemid = StringToInt(selectedItem);
			int state, type;
			type = GetItemType(itemid);
			if(type == TYPE_BUYONLY)
				state = ITEM_ACTIVEALLTIME;
			else if(type == TYPE_TOGGLEABLE)
				state = ITEM_UNACTIVE;
			else
				state = ITEM_ONEUSE;
			GetItemCategory(itemid, category, sizeof(category));
			AddNewItemToClan(admin_SelectMode[client][1], itemid, state);
			GetItemName(itemid, item_name, sizeof(item_name));
			Format(item_name, sizeof(item_name), "%T", item_name, client);
			FormatEx(c_buff, sizeof(c_buff), "%T", "GiveItemSuccess", client, item_name);
			CPrintToChat(client, c_buff);
			ThrowClanShopBuyMenu(client, category);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(clanShopBuyMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		ThrowClanCategoryMenu(client);
	}
}

//Item description panel
public int CShop_ItemDescSelectPanel(Handle itemDescPanel, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		int clanid, state;
		if(admin_SelectMode[client][0] == 0)
			clanid = admin_SelectMode[client][1];
		else
			clanid = Clans_GetOnlineClientClan(client);
		bool leader = Clans_IsClanLeader(Clans_GetClientID(client)) || admin_SelectMode[client][0] == 0;
		char category[CLAN_CATEGORY];
		GetItemCategory(itemInClanInfo[client][0], category, sizeof(category));
		bool test = HasClanItem(clanid, itemInClanInfo[client][0]);
		PrintToServer("Adm %d | leader %d | clanid %d | option %d | hasItem %d", admin_SelectMode[client][0], leader, clanid, option, test);
		//if(HasClanItem(clanid, itemInClanInfo[client][0]))	//If clan has this item
		if(test)	//If clan has this item
		{
			if(admin_SelectMode[client][0] == 0)
				state = ITEM_UNACTIVE;
			else
				state = GetItemState(client, itemInClanInfo[client][0]);
			if(leader)
			{
				if(option == 1)		//Sell
				{
					int coins, sellPrice;
					sellPrice = GetItemSellPrice(itemInClanInfo[client][0]);
					if(sellPrice == ITEM_NOTSELLABLE)
					{
						char buff[BUFF_SIZE];
						FormatEx(buff, sizeof(buff), "%T", "ItemNotForSell", client);
						CPrintToChat(client, buff);
					}
					else
					{
						if(RemoveItemInClan(clanid, itemInClanInfo[client][0]))
						{
							coins = Clans_GetClanCoins(clanid);
							Clans_SetClanCoins(clanid, coins+sellPrice);
							/*if(admin_SelectMode[client][0] != 0)
								DeletePlayerItem(client, itemInClanInfo[client][0]);*/
						}
						else
						{
							char buff[BUFF_SIZE];
							FormatEx(buff, sizeof(buff), "%T", "SellingFailed", client);
							CPrintToChat(client, buff);
						}
					}
					ThrowItemMenu(client, itemInClanInfo[client][0]);
				}
				else if(option == 2 && admin_SelectMode[client][0] != 0)	//Activate/Deactivate or use
				{
					if(state == ITEM_ACTIVEALLTIME)
					{
						itemInClanInfo[client][0] = -1;
						itemInClanInfo[client][1] = -1;
						if(openInventory[client])
							ThrowClanShopInventoryMenu(client, category);
						else
							ThrowClanShopBuyMenu(client, category);
					}
					else if(state == ITEM_ONEUSE)
					{
						RemoveItemInClan(clanid, itemInClanInfo[client][0]);
						Call_StartForward(g_hItemUsed);	//CShop_OnItemUsed forward
						Call_PushCell(client);
						Call_PushCell(itemInClanInfo[client][0]);
						Call_Finish();
						ThrowItemMenu(client, itemInClanInfo[client][0]);
					}
					else
					{
						if(state == ITEM_UNACTIVE)	
							state = ITEM_ACTIVE;
						else
							state = ITEM_UNACTIVE;
						SetItemState(client, itemInClanInfo[client][0], state);
						ThrowItemMenu(client, itemInClanInfo[client][0]);
					}
				}
				else	//Close
				{
					itemInClanInfo[client][0] = -1;
					itemInClanInfo[client][1] = -1;
					if(openInventory[client])
						ThrowClanShopInventoryMenu(client, category);
					else
						ThrowClanShopBuyMenu(client, category);
				}
			}
			else
			{
				if(option == 1)	//Activate/Deactivate
				{
					if(state == ITEM_ACTIVEALLTIME)
					{
						itemInClanInfo[client][0] = -1;
						itemInClanInfo[client][1] = -1;
						if(openInventory[client])
							ThrowClanShopInventoryMenu(client, category);
						else
							ThrowClanShopBuyMenu(client, category);
					}
					else
					{
						if(state == ITEM_UNACTIVE)	
							state = ITEM_ACTIVE;
						else
							state = ITEM_UNACTIVE;
						SetItemState(client, itemInClanInfo[client][0], state);
						ThrowItemMenu(client, itemInClanInfo[client][0]);
					}
				}
				else	//Close
				{
					itemInClanInfo[client][0] = -1;
					itemInClanInfo[client][1] = -1;
					if(openInventory[client])
						ThrowClanShopInventoryMenu(client, category);
					else
						ThrowClanShopBuyMenu(client, category);
				}
			}
		}
		else
		{
			if(leader)
			{
				if(option == 1)		//Buy
				{
					int coins, price, type;
					price = GetItemPrice(itemInClanInfo[client][0]);
					type = GetItemType(itemInClanInfo[client][0])
					if(type == TYPE_TOGGLEABLE)
						state = ITEM_UNACTIVE;
					if(type == TYPE_BUYONLY)
						state = ITEM_ACTIVEALLTIME;
					else if(type == TYPE_ONEUSE)
						state = ITEM_ONEUSE;
					if(price == ITEM_NOTBUYABLE)
					{
						char buff[BUFF_SIZE];
						FormatEx(buff, sizeof(buff), "%T", "ItemNotForPurchase", client);
						CPrintToChat(client, buff);
					}
					else
					{
						coins = Clans_GetClanCoins(clanid);
						if(coins < price)
						{
							char buff[BUFF_SIZE];
							FormatEx(buff, sizeof(buff), "%T", "NotEnoughCoins", client);
							CPrintToChat(client, buff);
						}
						else
						{
							/*if(admin_SelectMode[client][0] != 0)
								AddPlayerItem(client, itemInClanInfo[client][0], state);*/
							AddNewItemToClan(clanid, itemInClanInfo[client][0], state);
							Clans_SetClanCoins(clanid, coins-price);
						}
					}
					ThrowItemMenu(client, itemInClanInfo[client][0]);
				}
				else	//Close
				{
					itemInClanInfo[client][0] = -1;
					itemInClanInfo[client][1] = -1;
					if(openInventory[client])
						ThrowClanShopInventoryMenu(client, category);
					else
						ThrowClanShopBuyMenu(client, category);
				}
			}
			else
			{
				itemInClanInfo[client][0] = -1;
				itemInClanInfo[client][1] = -1;
				if(openInventory[client])
					ThrowClanShopInventoryMenu(client, category);
				else
					ThrowClanShopBuyMenu(client, category);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(itemDescPanel);
	}
}

//Items of clan inventory in some category
public int CShop_ClanShopInventorySelectMenu(Handle clanShopInventoryMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char selectedItem[50];
		int buff;
		GetMenuItem(clanShopInventoryMenu, option, selectedItem, sizeof(selectedItem), buff, "", 0);
		itemInClanInfo[client][0] = StringToInt(selectedItem);
		if(admin_SelectMode[client][0] == 2)
		{
			char category[CLANKEY_SIZE];
			GetItemCategory(itemInClanInfo[client][0], category, sizeof(category));
			RemoveItemInClan(admin_SelectMode[client][1], itemInClanInfo[client][0]);
			int hasClanItems = HasClanAnyItemsInCategory(admin_SelectMode[client][1], category);
			if(hasClanItems == 2)
				ThrowClanShopInventoryMenu(client, category);
			else if(hasClanItems == 1)
				ThrowClanInventoryCategoryMenu(client, admin_SelectMode[client][1]);
			else
				ThrowAdminMenu(client);
		}
		else
			ThrowItemMenu(client, itemInClanInfo[client][0]);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(clanShopInventoryMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		int clanid;
		if(admin_SelectMode[client][0] != -1)
			clanid = admin_SelectMode[client][1];
		else
			clanid = Clans_GetOnlineClientClan(client);
		ThrowClanInventoryCategoryMenu(client, clanid);
	}
}

//List of categories
public int CShop_CategoryClanShopSelectMenu(Handle clanShopCategoryMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char selectedItem[50];
		int buff;
		GetMenuItem(clanShopCategoryMenu, option, selectedItem, sizeof(selectedItem), buff, "", 0);
		ThrowClanShopBuyMenu(client, selectedItem);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(clanShopCategoryMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		if(admin_SelectMode[client][0] == 1)
			ThrowAdminMenu(client);
		else
			ThrowClanShopMainMenu(client);
	}
}

//List of categories for inventory
public int CShop_InventoryCategoryClanShopSelectMenu(Handle clanShopInventoryCategoryMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char selectedItem[50];
		int buff;
		GetMenuItem(clanShopInventoryCategoryMenu, option, selectedItem, sizeof(selectedItem), buff, "", 0);
		ThrowClanShopInventoryMenu(client, selectedItem);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(clanShopInventoryCategoryMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		if(admin_SelectMode[client][0] != -1)
			ThrowAdminMenu(client);
		else
			ThrowClanShopMainMenu(client);
	}
}

//Admin Menu
public int CShop_AdminMenuSelect(Handle adminMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char selectedItem[50];
		int i_buff;
		GetMenuItem(adminMenu, option, selectedItem, sizeof(selectedItem), i_buff, "", 0);
		if(!strcmp(selectedItem, "SeeInventory"))
		{
			admin_SelectMode[client][0] = 0;
			admin_SelectMode[client][1] = -1;
			itemInClanInfo[client][1] = 1;
		}
		else if(!strcmp(selectedItem, "GiveItem"))
		{
			admin_SelectMode[client][0] = 1;
			admin_SelectMode[client][1] = -1;
		}
		else if(!strcmp(selectedItem, "TakeItem"))
		{
			admin_SelectMode[client][0] = 2;
			admin_SelectMode[client][1] = -1;
		}
		else if(!strcmp(selectedItem, "ResetClan"))
		{
			admin_SelectMode[client][0] = 3;
			admin_SelectMode[client][1] = -1;
		}
		if(admin_SelectMode[client][0] != 1)
		{
			char c_name[MAX_NAME_LENGTH+1], c_clanid[CLANKEY_SIZE], buff[BUFF_SIZE];
			Handle adminClansMenu = CreateMenu(CShop_AdminClansMenuSelect);
			bool show = false;
			FormatEx(buff, sizeof(buff), "%T", "Clans", client);
			SetMenuTitle(adminClansMenu, buff);
			g_kvClans.Rewind();
			if(g_kvClans.GotoFirstSubKey(true))
			{
				do
				{
					g_kvClans.GetSectionName(c_clanid, sizeof(c_clanid));
					Clans_GetClanName(StringToInt(c_clanid), c_name, sizeof(c_name));
					AddMenuItem(adminClansMenu, c_clanid, c_name);
					show = true;
				} while(g_kvClans.GotoNextKey());
				g_kvClans.Rewind();
			}
			if(show)
			{
				SetMenuExitBackButton(adminClansMenu, true);
				DisplayMenu(adminClansMenu, client, 0);
			}
			else
			{
				delete adminClansMenu;
				FormatEx(buff, sizeof(buff), "%T", "NoClans", client);
				CPrintToChat(client, buff);
				ThrowAdminMenu(client);
			}
		}
		else
			ThrowAllClans(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(adminMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		ThrowClanShopMainMenu(client);
	}
}

//List of clans
public int CShop_AdminClansMenuSelect(Handle adminClansMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		int i_buff;
		char c_clanid[CLANKEY_SIZE];
		GetMenuItem(adminClansMenu, option, c_clanid, sizeof(c_clanid), i_buff, "", 0);
		admin_SelectMode[client][1] = StringToInt(c_clanid);
		if(admin_SelectMode[client][0] == 0)	//SeeInventory
		{
			openInventory[client] = true;
			ThrowClanInventoryCategoryMenu(client, admin_SelectMode[client][1]);
		}
		else if(admin_SelectMode[client][0] == 2)	//Take Item
		{
			ThrowClanInventoryCategoryMenu(client, admin_SelectMode[client][1]);
		}
		else if(admin_SelectMode[client][0] == 3)	//Reset Clan
		{
			char buff[BUFF_SIZE], c_name[MAX_NAME_LENGTH+1];
			Handle adminConfirm = CreateMenu(CShop_AdminConfirmSelectMenu);
			FormatEx(buff, sizeof(buff), "%T", "Confirmation", client);
			SetMenuTitle(adminConfirm, buff);
			Clans_GetClanName(admin_SelectMode[client][1], c_name, sizeof(c_name));
			FormatEx(buff, sizeof(buff), "%T", "ResetClanConfirmation", client, c_name);
			AddMenuItem(adminConfirm, "ResetClanConfirmation", buff);
			SetMenuExitButton(adminConfirm, true);
			DisplayMenu(adminConfirm, client, 0);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(adminClansMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		admin_SelectMode[client][0] = -1;
		admin_SelectMode[client][1] = -1;
		itemInClanInfo[client][1] = -1;
		openInventory[client] = false;
		ThrowAdminMenu(client);
	}
}

//Confirmation menu
public int CShop_AdminConfirmSelectMenu(Handle adminConfirm, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char buff[BUFF_SIZE], c_name[MAX_NAME_LENGTH+1];
		Clans_GetClanName(admin_SelectMode[client][1], c_name, sizeof(c_name));
		DeleteClan(admin_SelectMode[client][1]);
		admin_SelectMode[client][0] = -1;
		admin_SelectMode[client][1] = -1;
		itemInClanInfo[client][1] = -1;
		FormatEx(buff, sizeof(buff), "%T", "ResetSuccess", client, c_name);
		CPrintToChat(client, buff);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(adminConfirm);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		ThrowAdminMenu(client);
	}
}

//List of all clans (using in giving items)
public int CShop_ClansSelectMenu(Handle clansMenu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		int i_buff;
		char c_clanid[CLANKEY_SIZE];
		GetMenuItem(clansMenu, option, c_clanid, sizeof(c_clanid), i_buff, "", 0);
		admin_SelectMode[client][1] = StringToInt(c_clanid);
		ThrowClanCategoryMenu(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(clansMenu);
	}
	else if(option == MenuCancel_ExitBack && action == MenuAction_Cancel)
	{
		ThrowAdminMenu(client);
	}
}
//=============================== FUNCTIONS ===============================//
//ITEMS
/**
 * Get item's duration
 *
 * @param int itemid - item's id
 * @return item duration or -2 if item doesn't exists
 */
int GetItemDuration(int itemid)
{
	char key[CLANKEY_SIZE];
	int duration = ITEM_NOTEXISTS;
	Format(key, sizeof(key), "%d", itemid);
	g_kvItems.Rewind();
	if(g_kvItems.JumpToKey(key, false))
		duration = g_kvItems.GetNum("item_duration", 0);
	g_kvItems.Rewind();
	return duration;
}

/**
 * Set item's duration
 *
 * @param int itemid - item's id
 * @param int newDuration - new duration of item
 */
void SetItemDuration(int itemid, int newDuration)
{
	char query[200];
	Format(query, sizeof(query), "UPDATE `shop_items` SET `item_duration` = '%d' WHERE `item_id` = '%d'", newDuration, itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 1);
	Format(query, sizeof(query), "SELECT * FROM `shop_items` WHERE `item_id` = '%d'", itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LoadItemCallback, query, 0);
}

/**
 * Get item's price
 *
 * @param int itemid - item's id
 * @return item price or -2 if item doesn't exists
 */
int GetItemPrice(int itemid)
{
	char key[CLANKEY_SIZE];
	int price = ITEM_NOTEXISTS;
	Format(key, sizeof(key), "%d", itemid);
	g_kvItems.Rewind();
	if(g_kvItems.JumpToKey(key, false))
		price = g_kvItems.GetNum("item_price", 0);
	g_kvItems.Rewind();
	return price;
}

/**
 * Set item's price
 *
 * @param int itemid - item's id
 * @param int newPrice - new price of item
 */
void SetItemPrice(int itemid, int newPrice)
{
	char query[200];
	Format(query, sizeof(query), "UPDATE `shop_items` SET `item_price` = '%d' WHERE `item_id` = '%d'", newPrice, itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 1);
	Format(query, sizeof(query), "SELECT * FROM `shop_items` WHERE `item_id` = '%d'", itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LoadItemCallback, query, 0);
}

/**
 * Get item's sell price
 *
 * @param int itemid - item's id
 * @return item sell price or -2 if item doesn't exists
 */
int GetItemSellPrice(int itemid)
{
	char key[CLANKEY_SIZE];
	int sellprice = ITEM_NOTEXISTS;
	Format(key, sizeof(key), "%d", itemid);
	g_kvItems.Rewind();
	if(g_kvItems.JumpToKey(key, false))
		sellprice = g_kvItems.GetNum("item_sellprice", 0);
	g_kvItems.Rewind();
	return sellprice;
}

/**
 * Set item's sell price
 *
 * @param int itemid - item's id
 * @param int newSellPrice - new sell price of item
 */
void SetItemSellPrice(int itemid, int newSellPrice)
{
	char query[200];
	Format(query, sizeof(query), "UPDATE `shop_items` SET `item_sellprice` = '%d' WHERE `item_id` = '%d'", newSellPrice, itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 1);
	Format(query, sizeof(query), "SELECT * FROM `shop_items` WHERE `item_id` = '%d'", itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LoadItemCallback, query, 0);
	
}

/**
 * Get item's name
 *
 * @param int itemid - item's id
 * @param char[] buff - variable to contain the name
 * @param int maxlength - max length of buff
 */
void GetItemName(int itemid, char[] buff, int maxlength)
{
	char key[CLANKEY_SIZE];
	Format(key, sizeof(key), "%d", itemid);
	g_kvItems.Rewind();
	if(g_kvItems.JumpToKey(key, false))
		g_kvItems.GetString("item_name", buff, maxlength);
	g_kvItems.Rewind();
}

/**
 * Set item's name
 *
 * @param int itemid - item's id
 * @param char[] newName - new name of item
 */
void SetItemName(int itemid, char[] newName)
{
	char key[CLANKEY_SIZE];
	Format(key, sizeof(key), "%d", itemid);
	g_kvItems.Rewind();
	if(g_kvItems.JumpToKey(key, false))
		g_kvItems.SetString("item_name", newName);
	g_kvItems.Rewind();
}

/**
 * Get item's description
 *
 * @param int itemid - item's id
 * @param char[] buff - variable to contain the description
 * @param int maxlength - max length of buff
 */
void GetItemDescription(int itemid, char[] buff, int maxlength)
{
	char key[CLANKEY_SIZE];
	Format(key, sizeof(key), "%d", itemid);
	g_kvItems.Rewind();
	if(g_kvItems.JumpToKey(key, false))
		g_kvItems.GetString("item_desc", buff, maxlength);
	g_kvItems.Rewind();
}

/**
 * Set item's description
 *
 * @param int itemid - item's id
 * @param char[] newDesc - new item description
 */
void SetItemDescription(int itemid, char[] newDesc)
{
	char key[CLANKEY_SIZE];
	Format(key, sizeof(key), "%d", itemid);
	g_kvItems.Rewind();
	if(g_kvItems.JumpToKey(key, false))
		g_kvItems.SetString("item_desc", newDesc);
	g_kvItems.Rewind();
}

/**
 * Get item's category
 *
 * @param int itemid - item's id
 * @param char[] buff - variable to contain the category
 * @param int maxlength - max length of buff
 */
void GetItemCategory(int itemid, char[] buff, int maxlength)
{
	char key[CLANKEY_SIZE];
	Format(key, sizeof(key), "%d", itemid);
	g_kvItems.Rewind();
	if(g_kvItems.JumpToKey(key, false))
		g_kvItems.GetString("item_category", buff, maxlength);
	g_kvItems.Rewind();
}

/**
 * Get item's category in player items
 *
 * @param int client - client's id
 * @param int itemid - item's id
 * @param char[] buff - variable to contain the category
 * @param int maxlength - max length of buff
 */
void GetItemCategoryFromPlayer(int client, int itemid, char[] buff, int maxlength)
{
	char key[CLANKEY_SIZE];
	Format(key, sizeof(key), "%d", itemid);
	g_kvPlayerItems[client].Rewind();
	if(g_kvPlayerItems[client].JumpToKey(key, false))
		g_kvPlayerItems[client].GetString("item_category", buff, maxlength);
	g_kvPlayerItems[client].Rewind();
}

/**
 * Set item's category
 *
 * @param int itemid - item's id
 * @param char[] newDesc - new item category
 */
void SetItemCategory(int itemid, char[] newCategory)
{
	char key[CLANKEY_SIZE];
	Format(key, sizeof(key), "%d", itemid);
	g_kvItems.Rewind();
	if(g_kvItems.JumpToKey(key, false))
		g_kvItems.SetString("item_category", newCategory);
	g_kvItems.Rewind();
}

/**
 * Get item's type
 *
 * @param int itemid - item's id
 * @return 1 - BuyOnly, 2 - Toggleable, 3 - oneuse, -1 - doesn't exist
 */
int GetItemType(int itemid)
{
	char key[CLANKEY_SIZE];
	int type = ITEM_NOTEXISTS;
	Format(key, sizeof(key), "%d", itemid);
	g_kvItems.Rewind();
	if(g_kvItems.JumpToKey(key, false))
		type = g_kvItems.GetNum("item_type", -1);
	g_kvItems.Rewind();
	return type;
}

/**
 * Set item's type
 *
 * @param int itemid - item's id
 * @param int newType - new type of item
 */
void SetItemType(int itemid, int newType)
{
	char query[200], c_itemid[CLANKEY_SIZE];
	int state;
	if(newType == TYPE_BUYONLY)
		state = 1;
	else if(newType == TYPE_BUYONLY)
		state = 2;
	else
		state = 3;
	Format(query, sizeof(query), "UPDATE `shop_items` SET `item_type` = '%d' WHERE `item_id` = '%d'", newType, itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 1);
	Format(query, sizeof(query), "SELECT * FROM `shop_items` WHERE `item_id` = '%d'", itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LoadItemCallback, query, 0);
	Format(query, sizeof(query), "UPDATE `shop_players` SET `item_state` = '%d' WHERE `item_id` = '%d'", newType, itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 1);
	for(int i = 1; i < MAXPLAYERS+1; i++)
	{
		SetItemState(i, itemid, state);
	}
}

/**
 * Register a new item
 *
 * @param char[] category - category of item
 * @param char[] name - name of item
 * @param char[] desc - description of item
 * @param int price - price of item
 * @param int sellprice - sellprice of item
 * @param int duration - duration of item
 * @param int type - type of item
 * @return int id - id of registered item, -1 if failed
 */
int RegisterItem(char[] category, char[] name, char[] desc, int price, int sellprice, int duration, int type)
{
	int id = -1;
	char itemInfo[CLANKEY_SIZE], query[300];
	Format(query, sizeof(query), "SELECT * FROM `shop_items` WHERE `item_name` = '%s' AND `item_category` = '%s'", name, category);
	DBResultSet hQuery = SQL_Query(g_hClanShopDB, query, sizeof(query));
	if(hQuery == INVALID_HANDLE)
	{
		char error[256];
		SQL_GetError(g_hClanShopDB, error, sizeof(error));
		LogError("[CLAN SHOP] Unable to load item %s from database. Error: %s", name, error);
		return -1;
	}
	else
	{
		if(SQL_FetchRow(hQuery))
			id = SQL_FetchInt(hQuery, 0);
	}
	if(id == -1)
	{
		id = ++maxItemIndex;
		IntToString(id, itemInfo, sizeof(itemInfo));
		g_kvCategories.Rewind();
		g_kvItems.Rewind();
		if(g_kvItems.JumpToKey(itemInfo, true))
		{
			g_kvItems.SetString("item_category", category);
			if(g_kvCategories.JumpToKey(category, true))
			{
				int count = g_kvCategories.GetNum("1", -1);
				if(count != -1)
					g_kvCategories.SetNum("1", count + 1);
				else
					g_kvCategories.SetNum("1", 1);
			}
			g_kvItems.SetString("item_name", name);
			g_kvItems.SetString("item_desc", desc);
			g_kvItems.SetNum("item_price", price);
			g_kvItems.SetNum("item_sellprice", sellprice);
			g_kvItems.SetNum("item_duration", duration);
			g_kvItems.SetNum("item_type", type);
		}
		g_kvItems.Rewind();
		g_kvCategories.Rewind();
		Shop_SaveItem(id);
	}
	else
	{
		Format(query, sizeof(query), "UPDATE `shop_items` SET `item_price` = '%d', `item_sellprice` = '%d', `item_duration` = '%d', `item_type` = '%d' WHERE `item_id` = '%d'", 
		price, sellprice, duration, type, id);
		SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 1);
		Format(query, sizeof(query), "SELECT * FROM `shop_items` WHERE `item_id` = '%d'", id);
		SQL_TQuery(g_hClanShopDB, SQL_LoadItemCallback, query, 0);
		Format(query, sizeof(query), "SELECT * FROM `shop_clans` WHERE `item_id` = '%d'", id);
		SQL_TQuery(g_hClanShopDB, SQL_LoadClanItemCallback, query, 0);
	}
	CloseHandle(hQuery);
	return id;
}

/**
 * Unregister an item
 *
 * @param int itemid - id of item
 */
bool UnregisterItem(int itemid)
{
	char c_itemid[CLANKEY_SIZE], c_clanid[CLANKEY_SIZE], query[200], category[CLAN_CATEGORY];
	int duration;
	bool f = true;
	IntToString(itemid, c_itemid, sizeof(c_itemid));
	g_kvClans.Rewind();
	if(g_kvClans.GotoFirstSubKey(true))
	{
		do
		{
			if(g_kvClans.JumpToKey(c_itemid, false))
			{
				duration = g_kvClans.GetNum("item_duration", 0);
				g_kvClans.GoBack();
				g_kvClans.GetSectionName(c_clanid, sizeof(c_clanid));
				if(!g_kvClans.DeleteKey(c_itemid))
					f = false;
				Format(query, sizeof(query), "UPDATE `shop_clans` SET `item_duration` = '%d' WHERE `clan_id` = '%d'\
												AND `item_id` = '%d'",
												duration, StringToInt(c_clanid), itemid);
				SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 5);
			}
		} while(g_kvClans.GotoNextKey());
		g_kvClans.Rewind();
	}
	g_kvItems.Rewind();
	if(g_kvItems.GotoFirstSubKey(true))
	{
		bool stop = false;
		char cur_itemid[CLANKEY_SIZE];
		do
		{
			g_kvItems.GetSectionName(cur_itemid, sizeof(cur_itemid));
			if(!strcmp(cur_itemid, c_itemid))
			{
				stop = true;
				g_kvItems.GetString("item_category", category, sizeof(category));
				if(!g_kvItems.DeleteThis())
					f = false;
			}
		} while(!stop && g_kvItems.GotoNextKey())
	}
	g_kvItems.Rewind();
	g_kvCategories.Rewind();
	if(g_kvCategories.JumpToKey(category, false))
	{
		int count = g_kvCategories.GetNum("1");
		if(count == 1)
			g_kvCategories.DeleteThis();
		else
			g_kvCategories.SetNum("1", --count);
	}
	g_kvCategories.Rewind();
	return f;
}

/**
 * Get the state of any item in players items
 *
 * @param int client - client's id
 * @param int itemid - item's id
 * @return item state: 0 - not bought, 1 - unactive, 2 - active.
 */
int GetItemState(int client, int itemid)
{
	if(itemid == -1 || client < 1 || client > MAXPLAYERS)
		return 0;
	char key[CLANKEY_SIZE];
	int state = 0;
	Format(key, sizeof(key), "%d", itemid);
	g_kvPlayerItems[client].Rewind();
	if(g_kvPlayerItems[client].JumpToKey(key, false))
	{
		state = g_kvPlayerItems[client].GetNum("item_state", 0);
	}
	g_kvPlayerItems[client].Rewind();
	return state;
}

/**
 * Set the state of any item in players items
 *
 * @param int client - client's id
 * @param int itemid - item's id
 * @param int state - item's new state
 * @return true if succeed, false otherwise
 */
bool SetItemState(int client, int itemid, int state)
{
	char key[CLANKEY_SIZE];
	int curState;
	Format(key, sizeof(key), "%d", itemid);
	g_kvPlayerItems[client].Rewind();
	if(g_kvPlayerItems[client].JumpToKey(key, false))
	{
		curState = g_kvPlayerItems[client].GetNum("item_state");
		if(state != curState)
		{
			g_kvPlayerItems[client].SetNum("item_state", state);
			Call_StartForward(g_hItemStateChanged);	//CShop_OnItemStateChanged forward
			Call_PushCell(client);
			Call_PushCell(itemid);
			Call_PushCell(state);
			Call_Finish();
			Shop_UpdatePlayerItem(client, itemid);
		}
		g_kvPlayerItems[client].Rewind();
	}
	else
		return false;
	return true;
}

/**
 * Check if player has an item
 *
 * @param int client - client's index
 * @param int itemid - item's id
 * @return true if player has the item, false otherwise
 */
bool HasPlayerItem(int client, int itemid)
{
	char key[CLANKEY_SIZE];
	bool clanHasItem = false;
	Format(key, sizeof(key), "%d", itemid);
	g_kvPlayerItems[client].Rewind();
	clanHasItem = g_kvPlayerItems[client].JumpToKey(key, false);
	g_kvPlayerItems[client].Rewind();
	return clanHasItem;
}

/**
 * Add new item to player
 *
 * @param int client - client's index
 * @param int itemid - item's id
 * @param char[] category - item's category
 * @param int state - item's state
 * @return true if succeed, false otherwise
 */
bool AddPlayerItem(int client, int itemid, int state)
{
	if(client < 1 || client > MaxClients)
		return false;
	char c_itemid[CLANKEY_SIZE];
	IntToString(itemid, c_itemid, sizeof(c_itemid));
	g_kvPlayerItems[client].Rewind();
	if(g_kvPlayerItems[client].JumpToKey(c_itemid, true))
	{
		g_kvPlayerItems[client].SetNum("item_state", state);
		g_kvPlayerItems[client].Rewind();
	}
	else
		return false;
	return true;
}

/**
 * Delete an item from player
 *
 * @param int client - client's index
 * @param int itemid - item's id
 * @return true if succeed, false otherwise
 */
bool DeletePlayerItem(int client, int itemid)
{
	if(client < 1 || client > MaxClients)
		return false;
	char c_itemid[CLANKEY_SIZE];
	IntToString(itemid, c_itemid, sizeof(c_itemid));
	g_kvPlayerItems[client].Rewind();
	if(g_kvPlayerItems[client].JumpToKey(c_itemid, false))
	{
		g_kvPlayerItems[client].DeleteThis();
		g_kvPlayerItems[client].Rewind();
	}
	else
		return false;
	return true;
}
//CLANS
/**
 * Check if clan has an item
 *
 * @param int clanid - clan's id
 * @param int itemid - item's id
 * @return true if clan has the item, false otherwise
 */
bool HasClanItem(int clanid, int itemid)
{
	char key[CLANKEY_SIZE];
	bool clanHasItem = false;
	Format(key, sizeof(key), "%d", clanid);
	g_kvClans.Rewind();
	clanHasItem = g_kvClans.JumpToKey(key, false);
	if(clanHasItem)
	{
		Format(key, sizeof(key), "%d", itemid);
		clanHasItem = g_kvClans.JumpToKey(key, false);
	}
	g_kvClans.Rewind();
	return clanHasItem;
}

/**
 * Check if clan has any items
 *
 * @param int clanid - clan's id
 * @return true if clan has any items, false otherwise
 */
bool HasClanAnyItems(int clanid)
{
	char c_clanid[CLANKEY_SIZE];
	bool clanHasItems = false;
	Format(c_clanid, sizeof(c_clanid), "%d", clanid);
	g_kvClans.Rewind();
	clanHasItems = g_kvClans.JumpToKey(c_clanid, false);
	g_kvClans.Rewind();
	return clanHasItems;
}

/**
 * Check if clan has any items in some category
 *
 * @param int clanid - clan's id
 * @param char[] category - category to search in
 * @return 2 - clan has items in given category, 1 - clan has items in other category, 0 - clan has no items
 */
int HasClanAnyItemsInCategory(int clanid, char[] category)
{
	char c_clanid[CLANKEY_SIZE], item_category[CLAN_CATEGORY], buff[CLANKEY_SIZE];
	int clanHasItems = 0;
	Format(c_clanid, sizeof(c_clanid), "%d", clanid);
	g_kvClans.Rewind();
	if(g_kvClans.JumpToKey(c_clanid, false))
	{
		if(g_kvClans.GotoFirstSubKey(false))
		{
			do
			{
				g_kvClans.GetSectionName(buff, sizeof(buff));
				GetItemCategory(StringToInt(buff), item_category, sizeof(item_category));
				if(!strcmp(item_category, category))
					clanHasItems = 2;
				else
					clanHasItems = 1;
			} while(clanHasItems != 2 && g_kvClans.GotoNextKey());
		}
	}
	g_kvClans.Rewind();
	return clanHasItems;
}

/**
 * Add new item to clan
 *
 * @param int clanid - clan's id
 * @param int itemid - item's id
 * @param int state - default state for the item
 */
void AddNewItemToClan(int clanid, int itemid, int state)
{
	AddNewItemToClanPlayers(clanid, itemid, state);
	char key[CLANKEY_SIZE], c_itemid[CLANKEY_SIZE];
	Format(c_itemid, sizeof(c_itemid), "%d", itemid);
	g_kvItems.Rewind();
	if(g_kvItems.JumpToKey(c_itemid, false))
	{
		g_kvItems.Rewind();
		Format(key, sizeof(key), "%d", clanid);
		g_kvClans.Rewind();
		if(g_kvClans.JumpToKey(key, true))
		{
			if(g_kvClans.JumpToKey(c_itemid, true))
			{
				char date[11];
				FormatTime(date, 10, "%D");
				date[10] = '\0';
				g_kvClans.SetNum("item_duration", GetItemDuration(itemid));
				g_kvClans.SetString("purchase_date", date);
				Shop_DeleteClanItem(clanid, itemid);
				Shop_SaveClanItem(clanid, itemid);
				g_kvClans.Rewind();
				for(int i = 0; i < MAX_PLAYERSINCLANES; i++)
				{
					if(Clans_GetClientClan(i) == clanid)
						Shop_SavePlayerItem(i, itemid);
				}
			}
		}
	}
}

void AddNewItemToClanPlayers(int clanid, int itemid, int state)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_kvPlayerItems[i].Rewind();
		if(g_kvPlayerItems[i].GetNum("clanid") == clanid)
		{
			AddPlayerItem(i, itemid, state);
			g_kvPlayerItems[i].Rewind();
		}
	}
}

/**
 * Add item to clan
 *
 * @param int clanid - clan's id
 * @param int itemid - item's id
 * @param int duration - item's duration
 * @param char[] date - purchase date
 */
void AddItemToClan(int clanid, int itemid, int duration, char[] date)
{
	char key[CLANKEY_SIZE], c_itemid[CLANKEY_SIZE];
	Format(c_itemid, sizeof(c_itemid), "%d", itemid);
	g_kvItems.Rewind();
	if(g_kvItems.JumpToKey(c_itemid, false))
	{
		g_kvItems.Rewind();
		Format(key, sizeof(key), "%d", clanid);
		g_kvClans.Rewind();
		if(g_kvClans.JumpToKey(key, true))
		{
			if(g_kvClans.JumpToKey(c_itemid, true))
			{
				g_kvClans.SetNum("item_duration", duration);
				g_kvClans.SetString("purchase_date", date);
			}
		}
		g_kvClans.Rewind();
	}
}

/**
 * Remove item in clan
 *
 * @param int clanid - clan's id
 * @param int itemid - item's id
 * @return true if succeed, false otherwise
 */
bool RemoveItemInClan(int clanid, int itemid)
{
	RemoveItemFromClanPlayers(clanid, itemid);
	char c_itemid[CLANKEY_SIZE], c_clanid[CLANKEY_SIZE];
	bool itemRemoved = false;
	int anyNodes = 0;
	Format(c_clanid, sizeof(c_clanid), "%d", clanid);
	g_kvClans.Rewind();
	if(!g_kvClans.JumpToKey(c_clanid, false))
		return false;
	Format(c_itemid, sizeof(c_itemid), "%d", itemid);
	if(g_kvClans.JumpToKey(c_itemid, false))
	{
		anyNodes = g_kvClans.DeleteThis();
		itemRemoved = true;
	}
	if(anyNodes == -1)
	{
		g_kvClans.Rewind();
		if(g_kvClans.JumpToKey(c_clanid, false))
		{
			if(!g_kvClans.GotoFirstSubKey(false))
				g_kvClans.DeleteThis();
		}
	}
	g_kvClans.Rewind();
	if(itemRemoved)
	{
		Shop_DeleteClanItem(clanid, itemid);
		for(int i = 0; i < MAX_PLAYERSINCLANES; i++)
		{
			if(Clans_GetClientClan(i) == clanid)
				Shop_DeletePlayerItem(i, itemid);
		}
	}
	return itemRemoved;
}

void RemoveItemFromClanPlayers(int clanid, int itemid)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_kvPlayerItems[i].Rewind();
		if(g_kvPlayerItems[i].GetNum("clanid") == clanid)
		{
			DeletePlayerItem(i, itemid);
			g_kvPlayerItems[i].Rewind();
		}
	}
}

/**
 * Get the duration left of any item in clan
 *
 * @param int clanid - clan's id
 * @param int itemid - item's id
 * @return item duration left
 */
int GetItemDurationInClan(int clanid, int itemid)
{
	char key[CLANKEY_SIZE];
	int duration = 0;
	Format(key, sizeof(key), "%d", clanid);
	g_kvClans.Rewind();
	if(g_kvClans.JumpToKey(key, false))
	{
		Format(key, sizeof(key), "%d", itemid);
		if(g_kvClans.JumpToKey(key, false))
			duration = g_kvClans.GetNum("item_duration", 0);
	}
	g_kvClans.Rewind();
	return duration;
}

/**
 * Get the date of purchase of item
 *
 * @param int clanid - clan's id
 * @param int itemid - item's id
 * @param char[] buff - variable to contain the date
 * @param int maxlength - length of buff
 */
void GetItemPurchaseDate(int clanid, int itemid, char[] buff, int maxlength)
{
	char key[CLANKEY_SIZE];
	Format(key, sizeof(key), "%d", clanid);
	g_kvClans.Rewind();
	if(g_kvClans.JumpToKey(key, false))
	{
		Format(key, sizeof(key), "%d", itemid);
		if(g_kvClans.JumpToKey(key, false))
			g_kvClans.GetString("purchase_date", buff, maxlength);
	}
	g_kvClans.Rewind();
}

/**
 * Update items duration in clans
 */
void UpdateItemsInClans()
{
	g_kvClans.Rewind();
	int NextState = 2; //0 - stop, 1 - stay, 2 - go to next
	char str_clanid[CLANKEY_SIZE], str_itemid[CLANKEY_SIZE];
	int newDuration;
	g_kvClans.Rewind();
	if(g_kvClans.GotoFirstSubKey())
	{
		g_kvClans.GetSectionName(str_clanid, sizeof(str_clanid));
		do
		{
			g_kvClans.SavePosition();
			g_kvClans.GotoFirstSubKey();
			do
			{
				NextState = 2;
				g_kvClans.GetSectionName(str_itemid, sizeof(str_itemid));
				newDuration = g_kvClans.GetNum("item_duration");
				if(newDuration != ITEM_INFINITE)
				{
					newDuration -= UPDATE_TIME;
					if(newDuration > 0)
						g_kvClans.SetNum("item_duration", newDuration);
					else
					{
						if(g_kvClans.DeleteThis() == 1)
							NextState = 1;
						Shop_DeleteClanItem(StringToInt(str_clanid), StringToInt(str_itemid));
					}
				}
				if(NextState == 2)
					NextState = g_kvClans.GotoNextKey() == true ? 2 : 0;
			} while(NextState != 0);
			g_kvClans.GoBack();
		} while(g_kvClans.GotoNextKey());
	}
	g_kvClans.Rewind();
}

/**
 * Delete all items in clan
 * @param int clanid - id of clan
 *
 */
void DeleteClan(int clanid)
{
	char c_clanid[CLANKEY_SIZE], cur_clanid[CLANKEY_SIZE];
	IntToString(clanid, c_clanid, sizeof(c_clanid));
	g_kvClans.Rewind();
	if(g_kvClans.GotoFirstSubKey(true))
	{
		bool stop = false;
		do
		{
			g_kvClans.GetSectionName(cur_clanid, sizeof(cur_clanid));
			if(!strcmp(cur_clanid, c_clanid))
			{
				stop = true;
				g_kvClans.DeleteThis();
				Shop_DeleteClan(clanid);
			}
		} while(!stop && g_kvClans.GotoNextKey());
		g_kvClans.Rewind();
	}
}
//THE REST
/**
 * Converting seconds to time
 *
 * @param int seconds
 * @param char[] buffer - time, format: MONTHS:DAYS:HOURS:MINUTES:SECONDS
 * @param int maxlength - size of buffer
 * @param int client - who will see the time
 */
void SecondsToTime(int seconds, char[] buffer, int maxlength, int client)
{
	int months, days, hours, minutes;
	months = seconds/2678400;
	seconds -= 2678400*months;
	days = seconds/86400;
	seconds -= 86400*days;
	hours = seconds/3600;
	seconds -= 3600*hours;
	minutes = seconds/60;
	seconds -= 60*minutes;
	FormatEx(buffer, maxlength, "%T", "Time", client, months, days, hours, minutes, seconds);
}

/**
 * Copying a keyValues
 *
 * @param KeyValues origin - origin KeyValues
 * @return KeyValues result - copy of origin KeyValues
 */
KeyValues CopyKV(KeyValues origin)
{
	origin.Rewind();
	KeyValues result = CreateKeyValues("copy");
	if(!result.Import(origin))
		SetFailState("Unable to copy keyValues");
	return result;
}

/**
 * Get a player's clan id
 *
 * @param int client - client's index
 * @return KeyValues result - copy of origin KeyValues
 */
int GetPlayerClan(int client)
{
	int clanid;
	g_kvPlayerItems[client].GetNum("clanid", -1);
	return clanid;
}
//=============================== THROW MENU FUNCTIONS ===============================//
/**
 * Throws main clan shop menu
 *
 * @param int client - client's id
 * @return true if succeed, false otherwise
 */
bool ThrowClanShopMainMenu(int client)
{
	if(client < 1 || !IsClientInGame(client))
		return false;
	admin_SelectMode[client][0] = -1;
	admin_SelectMode[client][1] = -1;
	openInventory[client] = false;
	Handle clanShopMainMenu = CreateMenu(CShop_MainClanShopSelectMenu);
	char buff[BUFF_SIZE];
	FormatEx(buff, sizeof(buff), "%T", "ClanShop", client);
	SetMenuTitle(clanShopMainMenu, buff);
	FormatEx(buff, sizeof(buff), "%T", "Buy", client);
	AddMenuItem(clanShopMainMenu, "Buy", buff);
	FormatEx(buff, sizeof(buff), "%T", "Inventory", client);
	AddMenuItem(clanShopMainMenu, "Inventory", buff);
	if(GetAdminFlag(GetUserAdmin(client), Admin_Root, Access_Real))
	{
		FormatEx(buff, sizeof(buff), "%T", "AdminMenu", client);
		AddMenuItem(clanShopMainMenu, "Admin", buff);
	}
	SetMenuExitButton(clanShopMainMenu, true);
	DisplayMenu(clanShopMainMenu, client, 0);
	return true;
}

/**
 * Throws a list of categories
 *
 * @param int client - client's id
 * @return true if succeed, false otherwise
 */
bool ThrowClanCategoryMenu(int client)
{
	if(client < 1 || !IsClientInGame(client))
		return false;
	char buff[BUFF_SIZE];
	if(maxItemIndex == -1)
	{
		FormatEx(buff, sizeof(buff), "%T", "NoItems", client);
		CPrintToChat(client, buff);
		ThrowClanShopMainMenu(client);
		return false;
	}
	char category[50];
	Handle clanShopCategoryMenu = CreateMenu(CShop_CategoryClanShopSelectMenu);
	FormatEx(buff, sizeof(buff), "%T", "ClanShop", client);
	SetMenuTitle(clanShopCategoryMenu, buff);
	g_kvCategories.Rewind();
	if(g_kvCategories.GotoFirstSubKey())
	{
		do
		{
			g_kvCategories.GetSectionName(category, sizeof(category));
			FormatEx(buff, sizeof(buff), "%T", category, client);
			AddMenuItem(clanShopCategoryMenu, category, buff);
		} while(g_kvCategories.GotoNextKey());
		SetMenuExitBackButton(clanShopCategoryMenu, true);
		DisplayMenu(clanShopCategoryMenu, client, 0);
		g_kvCategories.Rewind();
	}
	else
		return false;
	return true;
}

/**
 * Throws a list of categories for inventory
 *
 * @param int client - client's id
 * @return true if succeed, false otherwise
 */
bool ThrowClanInventoryCategoryMenu(int client, int clanid)
{
	if(client < 1 || !IsClientInGame(client) || !Clans_IsClanValid(clanid))
		return false;
	char buff[BUFF_SIZE];
	bool hasItems = false;
	if(maxItemIndex == -1)
	{
		FormatEx(buff, sizeof(buff), "%T", "NoItems", client);
		CPrintToChat(client, buff);
		return false;
	}
	char category[50], c_clanid[CLANKEY_SIZE], c_itemid[CLANKEY_SIZE];
	Handle clanShopInventoryCategoryMenu = CreateMenu(CShop_InventoryCategoryClanShopSelectMenu);
	FormatEx(buff, sizeof(buff), "%T", "ClanShop", client);
	SetMenuTitle(clanShopInventoryCategoryMenu, buff);
	KeyValues invCategories = CreateKeyValues("Categories");
	IntToString(clanid, c_clanid, sizeof(c_clanid));
	g_kvClans.Rewind();
	if(g_kvClans.JumpToKey(c_clanid, false))
	{
		if(g_kvClans.GotoFirstSubKey())
		{
			do
			{
				g_kvClans.GetSectionName(c_itemid, sizeof(c_itemid));
				GetItemCategory(StringToInt(c_itemid), category, sizeof(category));
				if(invCategories.JumpToKey(category, true))
				{
					hasItems = true;
					invCategories.Rewind();
				}
			} while(g_kvClans.GotoNextKey());
		}
	}
	if(invCategories.GotoFirstSubKey())
	{
		do
		{
			invCategories.GetSectionName(category, sizeof(category));
			FormatEx(buff, sizeof(buff), "%T", category, client);
			AddMenuItem(clanShopInventoryCategoryMenu, category, buff);
		} while(invCategories.GotoNextKey());
		SetMenuExitBackButton(clanShopInventoryCategoryMenu, true);
		DisplayMenu(clanShopInventoryCategoryMenu, client, 0);
	}
	delete invCategories;
	if(!hasItems)
	{
		FormatEx(buff, sizeof(buff), "%T", "NoItemsInClan", client);
		CPrintToChat(client, buff);
		ThrowClanShopMainMenu(client);
	}
	else
		return false;
	return true;
}

/**
 * Throws a list of items in clan shop in X category
 *
 * @param int client - client's id
 * @param char category[] - name of category
 * @return true if succeed, false otherwise
 */
bool ThrowClanShopBuyMenu(int client, char[] category)
{
	if(client < 1 || !IsClientInGame(client))
		return false;
	char buff[255], itemid[CLANKEY_SIZE];
	if(maxItemIndex == -1)
	{
		FormatEx(buff, sizeof(buff), "%T", "NoItems", client);
		CPrintToChat(client, buff);
		return false;
	}
	Handle clanShopBuyMenu = CreateMenu(CShop_BuyClanShopSelectMenu);
	FormatEx(buff, sizeof(buff), "%T", "ClanShop", client);
	SetMenuTitle(clanShopBuyMenu, buff);
	KeyValues shopItems = CopyKV(g_kvItems);
	shopItems.Rewind();
	if(shopItems.GotoFirstSubKey())
	{
		do
		{
			shopItems.GetString("item_category", buff, sizeof(buff));
			if(!strcmp(buff, category))
			{
				shopItems.GetSectionName(itemid, sizeof(itemid));
				shopItems.GetString("item_name", buff, sizeof(buff));
				char itemName[BUFF_SIZE];
				FormatEx(itemName, sizeof(itemName), "%T", buff, client);
				AddMenuItem(clanShopBuyMenu, itemid, itemName);
			}
		} while(shopItems.GotoNextKey());
		delete shopItems;
		SetMenuExitBackButton(clanShopBuyMenu, true);
		DisplayMenu(clanShopBuyMenu, client, 0);
		return true;
	}
	delete shopItems;
	return false;
}

/**
 * Throws an inventory of client's clan in some category
 *
 * @param int client - client's id
 * @param char category[] - category to show
 * @return true if succeed, false otherwise
 */
bool ThrowClanShopInventoryMenu(int client, char[] category)
{
	if(client < 1 || !IsClientInGame(client))
		return false;
	char clanid[CLANKEY_SIZE], itemid[CLANKEY_SIZE], itemInfo[CLANKEY_SIZE], buff[BUFF_SIZE];
	bool hasItems;
	if(maxItemIndex == -1)
	{
		FormatEx(buff, sizeof(buff), "%T", "NoItems", client);
		CPrintToChat(client, buff);
		return false;
	}
	if(admin_SelectMode[client][0] == -1)
		IntToString(Clans_GetOnlineClientClan(client), clanid, sizeof(clanid));
	else
		IntToString(admin_SelectMode[client][1], clanid, sizeof(clanid));
	Handle clanShopInventoryMenu = CreateMenu(CShop_ClanShopInventorySelectMenu);
	FormatEx(buff, sizeof(buff), "%T", "Inventory", client);
	SetMenuTitle(clanShopInventoryMenu, buff);
	KeyValues clanItems = CopyKV(g_kvClans);
	clanItems.Rewind();
	if(clanItems.JumpToKey(clanid, false))
	{
		clanItems.GotoFirstSubKey();
		do
		{
			clanItems.GetSectionName(itemid, sizeof(itemid));
			GetItemCategory(StringToInt(itemid), itemInfo, sizeof(itemInfo));
			if(!strcmp(itemInfo, category))
			{
				GetItemName(StringToInt(itemid), itemInfo, sizeof(itemInfo));
				FormatEx(buff, sizeof(buff), "%T", itemInfo, client);
				AddMenuItem(clanShopInventoryMenu, itemid, buff);
				hasItems = true;
			}
		} while(clanItems.GotoNextKey());
	}
	delete clanItems;
	if(hasItems)
	{
		SetMenuExitBackButton(clanShopInventoryMenu, true);
		DisplayMenu(clanShopInventoryMenu, client, 0);
	}
	else
	{
		delete clanShopInventoryMenu;
		ThrowClanInventoryCategoryMenu(client, StringToInt(clanid));
	}
	return true;
}

/**
 * Throws an item description menu to client
 *
 * @param int client - client's id
 * @param int itemid - item's id
 * @return true if succeed, false otherwise
 */
bool ThrowItemMenu(int client, int itemid)
{
	if(client < 1 || !IsClientInGame(client))
		return false;
	char key[CLANKEY_SIZE], itemInfo[255], time[60], buff[BUFF_SIZE];
	IntToString(itemid, key, sizeof(key));
	g_kvItems.Rewind();
	if(g_kvItems.JumpToKey(key, false))
	{
		int clanid;
		if(admin_SelectMode[client][0] == -1)
			clanid = Clans_GetOnlineClientClan(client);
		else
			clanid = admin_SelectMode[client][1];
		bool hasItem = HasPlayerItem(client, itemid);
		Handle itemDescPanel = CreatePanel();
		FormatEx(buff, sizeof(buff), "%T", "ClanShop", client);
		SetPanelTitle(itemDescPanel, buff);
		g_kvItems.GetString("item_name", itemInfo, sizeof(itemInfo));
		FormatEx(buff, sizeof(buff), "%T", itemInfo, client);
		DrawPanelText(itemDescPanel, buff);
		g_kvItems.GetString("item_desc", itemInfo, sizeof(itemInfo));
		FormatEx(buff, sizeof(buff), "%T", itemInfo, client);
		DrawPanelText(itemDescPanel, buff);
		g_kvItems.GetString("item_price", itemInfo, sizeof(itemInfo));
		if(!strcmp(itemInfo, "-1"))
			FormatEx(buff, sizeof(buff), "%T", "m_ItemNotForPurchase", client);
		else
			FormatEx(buff, sizeof(buff), "%T", "ItemPrice", client, StringToInt(itemInfo));
		DrawPanelText(itemDescPanel, buff);
		g_kvItems.GetString("item_sellprice", itemInfo, sizeof(itemInfo));
		if(!strcmp(itemInfo, "-1"))
			FormatEx(buff, sizeof(buff), "%T", "m_ItemNotForSell", client);
		else
			FormatEx(buff, sizeof(buff), "%T", "ItemSellPrice", client, StringToInt(itemInfo));
		DrawPanelText(itemDescPanel, buff);
		g_kvItems.GetString("item_duration", itemInfo, sizeof(itemInfo));
		if(!strcmp(itemInfo, "-1"))
			FormatEx(buff, sizeof(buff), "%T", "Forever", client);
		else
		{
			if(hasItem)
			{
				int duration = GetItemDurationInClan(clanid, itemid);
				SecondsToTime(duration, time, sizeof(time), client);
				FormatEx(buff, sizeof(buff), "%T", "Left", client);
				Format(buff, sizeof(buff), "%s %s\n \n", buff, time);
			}
			else
			{
				SecondsToTime(StringToInt(itemInfo), time, sizeof(time), client);
				FormatEx(buff, sizeof(buff), "%T", "Duration", client);
				Format(buff, sizeof(buff), "%s: %s\n \n", buff, time);
			}
		}
		DrawPanelText(itemDescPanel, buff);
		
		bool hasClanItem = HasClanItem(clanid, itemid);
		if(admin_SelectMode[client][0] == 0)
			itemInClanInfo[client][1] = hasClanItem == true ? ITEM_UNACTIVE : ITEM_NOTBOUGHT;
		else
		{
			if(hasClanItem)
				itemInClanInfo[client][1] = GetItemState(client, itemInClanInfo[client][0]);
			else
				itemInClanInfo[client][1] = ITEM_NOTBOUGHT;
		}
		if(admin_SelectMode[client][0] == 0 || Clans_IsClanLeader(Clans_GetClientID(client)))
		{
			if(itemInClanInfo[client][1] == ITEM_NOTBOUGHT)
			{
				FormatEx(buff, sizeof(buff), "%T", "Buy", client);
				DrawPanelItem(itemDescPanel, buff);
			}
			else
			{
				FormatEx(buff, sizeof(buff), "%T", "Sell", client);
				DrawPanelItem(itemDescPanel, buff);
			}
		}
		if(itemInClanInfo[client][1] == ITEM_UNACTIVE && admin_SelectMode[client][0] != 0)
		{
			FormatEx(buff, sizeof(buff), "%T", "Activate", client);
			DrawPanelItem(itemDescPanel, buff);
		}
		else if(itemInClanInfo[client][1] == ITEM_ACTIVE)
		{
			FormatEx(buff, sizeof(buff), "%T", "Deactivate", client);
			DrawPanelItem(itemDescPanel, buff);
		}
		else if(itemInClanInfo[client][1] == ITEM_ONEUSE && (Clans_IsClanLeader(Clans_GetClientID(client)) || admin_SelectMode[client][0] == 0) )
		{
			FormatEx(buff, sizeof(buff), "%T", "Use", client);
			DrawPanelItem(itemDescPanel, buff);
		}
		FormatEx(buff, sizeof(buff), "%T", "Close", client);
		DrawPanelItem(itemDescPanel, buff);
		SendPanelToClient(itemDescPanel, client, CShop_ItemDescSelectPanel, 0);
	}
	else
		return false;
	g_kvItems.Rewind();
	return true;
}

/**
 * Throws admin menu to client
 *
 * @param int client - client's id
 * @return true if succeed, false otherwise
 */
bool ThrowAdminMenu(int client)
{
	if(client < 1 || !IsClientInGame(client))
		return false;
	char buff[BUFF_SIZE];
	Handle adminMenu = CreateMenu(CShop_AdminMenuSelect);
	FormatEx(buff, sizeof(buff), "%T", "AdminMenu", client);
	SetMenuTitle(adminMenu, buff);
	FormatEx(buff, sizeof(buff), "%T", "SeeInventory", client);
	AddMenuItem(adminMenu, "SeeInventory", buff);
	FormatEx(buff, sizeof(buff), "%T", "GiveItem", client);
	AddMenuItem(adminMenu, "GiveItem", buff);
	FormatEx(buff, sizeof(buff), "%T", "TakeItem", client);
	AddMenuItem(adminMenu, "TakeItem", buff);
	FormatEx(buff, sizeof(buff), "%T", "ResetClan", client);
	AddMenuItem(adminMenu, "ResetClan", buff);
	SetMenuExitBackButton(adminMenu, true);
	DisplayMenu(adminMenu, client, 0);
	return true;
}

/**
 * Throws list of all created clans
 *
 * @param int client - client's id
 * @return true if succeed, false otherwise
 */
bool ThrowAllClans(int client)
{
	if(client < 1 || !IsClientInGame(client))
		return false;
	Handle clansMenu = CreateMenu(CShop_ClansSelectMenu);
	char str_clanid[20], c_name[MAX_NAME_LENGTH+1];
	SetMenuTitle(clansMenu, "Кланы");
	for(int i = 0; i < MAX_CLANS; i++)
	{
		if(Clans_IsClanValid(i))
		{
			Clans_GetClanName(i, c_name, sizeof(c_name));
			IntToString(i, str_clanid, sizeof(str_clanid));
			AddMenuItem(clansMenu, str_clanid, c_name);
		}
	}
	SetMenuExitBackButton(clansMenu, true);
	DisplayMenu(clansMenu, client, 0);
	return true;
}

/**
 * Throws type select menu to client
 *
 * @param int client - client's id
 * @return true if succeed, false otherwise
 */
bool ThrowSetClanTypeMenu(int client)
{
	if(client < 1 || !IsClientInGame(client) || client > MaxClients)
		return false;
	Handle clansMenu = CreateMenu(CShop_ClansSelectMenu);
	char str_clanid[20], c_name[MAX_NAME_LENGTH+1];
	SetMenuTitle(clansMenu, "Кланы");
	for(int i = 0; i < MAX_CLANS; i++)
	{
		if(Clans_IsClanValid(i))
		{
			Clans_GetClanName(i, c_name, sizeof(c_name));
			IntToString(i, str_clanid, sizeof(str_clanid));
			AddMenuItem(clansMenu, str_clanid, c_name);
		}
	}
	SetMenuExitBackButton(clansMenu, true);
	DisplayMenu(clansMenu, client, 0);
	return true;
}
//=============================== SQL Funtions ===============================//
void Shop_SaveItems()
{
	KeyValues kvSave = CopyKV(g_kvItems);
	char item[CLANKEY_SIZE];
	if(kvSave.GotoFirstSubKey())
	{
		do
		{
			kvSave.GetSectionName(item, sizeof(item));
			Shop_UpdateItem(StringToInt(item));
		} while(kvSave.GotoNextKey());
	}
	delete kvSave;
}

void Shop_SaveItem(int itemid)
{
	char query[200], name[100], desc[100], category[100];
	int duration = GetItemDuration(itemid);
	int price = GetItemPrice(itemid);
	int sellprice = GetItemSellPrice(itemid);
	int type = GetItemType(itemid);
	GetItemName(itemid, name, sizeof(name));
	GetItemDescription(itemid, desc, sizeof(desc));
	GetItemCategory(itemid, category, sizeof(category));
	
	Format(query, sizeof(query), "INSERT INTO `shop_items` VALUES ('%d', '%s', '%s', '%s', '%d', '%d', '%d', '%d')",
	itemid, category, name, desc, price, sellprice, duration, type);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 0);
}

void Shop_UpdateItem(int itemid)
{
	char query[350], name[100], desc[100], category[100];
	int duration = GetItemDuration(itemid);
	int price = GetItemPrice(itemid);
	int sellprice = GetItemSellPrice(itemid);
	int type = GetItemType(itemid);
	GetItemName(itemid, name, sizeof(name));
	GetItemDescription(itemid, desc, sizeof(desc));
	GetItemCategory(itemid, category, sizeof(category));
	Format(query, sizeof(query), "UPDATE `shop_items` SET `item_category` = '%s', `item_name` = '%s', `item_desc` = '%s', \
		`item_price` = '%d', `item_sellprice` = '%d', `item_duration` = '%d', `item_type` = '%d' WHERE `item_id` = '%d'",
	category, name, desc, price, sellprice, duration, type, itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 1);
}

void Shop_DeleteItem(int itemid)
{
	char query[100];
	Format(query, sizeof(query), "DELETE FROM `shop_items` WHERE `item_id` = '%d'", itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 2);
	Format(query, sizeof(query), "DELETE FROM `shop_clans` WHERE `item_id` = '%d'", itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 3);
}

void Shop_SaveClans()
{
	KeyValues kvSave = CopyKV(g_kvClans);
	char item[CLANKEY_SIZE], c_clanid[CLANKEY_SIZE];
	if(kvSave.GotoFirstSubKey())
	{
		do
		{
			kvSave.SavePosition();
			kvSave.GetSectionName(c_clanid, sizeof(c_clanid));
			if(kvSave.GotoFirstSubKey())
			{
				do
				{
					kvSave.GetSectionName(item, sizeof(item));
					Shop_UpdateClanItem(StringToInt(c_clanid), StringToInt(item));
				} while(kvSave.GotoNextKey());
				kvSave.GoBack();
			}
		} while(kvSave.GotoNextKey());
		kvSave.Rewind();
	}
	delete kvSave;
}

void Shop_SaveClanItem(int clanid, int itemid)
{
	char query[150], date[11];
	int duration;
	duration = GetItemDurationInClan(clanid, itemid);
	GetItemPurchaseDate(clanid, itemid, date, sizeof(date));
	date[10] = '\0';
	Format(query, sizeof(query), "INSERT INTO `shop_clans` VALUES ('%d', '%d', '%d', '%s')",
	clanid, itemid, duration, date);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 4);
}

void Shop_UpdateClanItem(int clanid, int itemid)
{
	char query[200], date[11];
	int duration;
	duration = GetItemDurationInClan(clanid, itemid);
	GetItemPurchaseDate(clanid, itemid, date, sizeof(date));
	date[10] = '\0';
	
	Format(query, sizeof(query), "UPDATE `shop_clans` SET `item_duration` = '%d' WHERE `clan_id` = '%d'\
		AND `item_id` = '%d'",
	duration, clanid, itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 5);
}

void Shop_DeleteClanItem(int clanid, int itemid)
{
	char query[150];
	Format(query, sizeof(query), "DELETE FROM `shop_clans` WHERE `clan_id` = '%d' AND `item_id` = '%d'", clanid, itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 3);
	Format(query, sizeof(query), "DELETE FROM `shop_players` WHERE `clan_id` = '%d' AND `item_id` = '%d'", clanid, itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 9);
}

void Shop_DeleteClan(int clanid)
{
	char query[100];
	Format(query, sizeof(query), "DELETE FROM `shop_clans` WHERE `clan_id` = '%d'", clanid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 6);
	Format(query, sizeof(query), "DELETE FROM `shop_players` WHERE `clan_id` = '%d'", clanid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 10);
}

void Shop_SavePlayerItem(int clientID, int itemid)
{
	char query[120];
	int clanid, type, state;
	clanid = Clans_GetClientClan(clientID);
	type = GetItemType(itemid);
	if(type == TYPE_BUYONLY)
		state = ITEM_ACTIVEALLTIME;
	else if(type == TYPE_TOGGLEABLE)
		state = ITEM_UNACTIVE;
	else if(type == TYPE_ONEUSE)
		state = ITEM_ONEUSE;
	Format(query, sizeof(query), "INSERT INTO `shop_players` VALUES ('%d', '%d', '%d', '%d')",
	clientID, clanid, itemid, state);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 8);
}

void Shop_UpdatePlayerItem(int client, int itemid)
{
	char query[200];
	int state;
	state = GetItemState(client, itemid);
	Format(query, sizeof(query), "UPDATE `shop_players` SET `item_state` = '%d' WHERE `player_id` = '%d'\
		AND `item_id` = '%d'",
	state, Clans_GetClientID(client), itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 8);
}

void Shop_DeletePlayerItem(int clientID, int itemid)
{
	char query[150];
	Format(query, sizeof(query), "DELETE FROM `shop_players` WHERE `player_id` = '%d' AND `item_id` = '%d'",
	clientID, itemid);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 9);
}

void Shop_LoadPlayer(int client)
{
	char query[200];
	FormatEx(query, sizeof(query), "SELECT * FROM `shop_players` WHERE `player_id` = '%d'", Clans_GetClientID(client));
	SQL_TQuery(g_hClanShopDB, SQL_LoadPlayerCallback, query, client);
}

void Shop_DeletePlayer(int clientID)
{
	char query[100];
	Format(query, sizeof(query), "DELETE FROM `shop_players` WHERE `player_id` = '%d'", clientID);
	SQL_TQuery(g_hClanShopDB, SQL_LogError, query, 9);
}
//=============================== SQL Callbacks ===============================//
public void SQL_LoadItemCallback(Handle owner, Handle hndl, const char[] error, any anyvar) 
{
	if(hndl == INVALID_HANDLE) LogError("[CLANS] Query Fail load client: %s", error);
	else
	{
		int itemid;
		char key[CLANKEY_SIZE], buff[255];
		g_kvItems.Rewind();
		if(SQL_FetchRow(hndl))
		{
			itemid = SQL_FetchInt(hndl, 0);
			IntToString(itemid, key, sizeof(key));
			if(g_kvItems.JumpToKey(key, true))
			{
				SQL_FetchString(hndl, 1, buff, sizeof(buff));
				g_kvItems.SetString("item_category", buff);
				if(g_kvCategories.JumpToKey(buff,true))
				{
					int count = g_kvCategories.GetNum("1", -1);
					if(count != -1)
						g_kvCategories.SetNum("1", count + 1);
					else
						g_kvCategories.SetNum("1", 1);
					g_kvCategories.Rewind();
				}
				SQL_FetchString(hndl, 2, buff, sizeof(buff));
				g_kvItems.SetString("item_name", buff);
				SQL_FetchString(hndl, 3, buff, sizeof(buff));
				g_kvItems.SetString("item_desc", buff);
				g_kvItems.SetNum("item_price", SQL_FetchInt(hndl, 4));
				g_kvItems.SetNum("item_sellprice", SQL_FetchInt(hndl, 5));
				g_kvItems.SetNum("item_duration", SQL_FetchInt(hndl, 6));
				g_kvItems.SetNum("item_type", SQL_FetchInt(hndl, 7));
				g_kvItems.Rewind();
			}
			if(itemid > maxItemIndex)
				maxItemIndex = itemid;
		}
	}
}

public void SQL_LoadClanItemCallback(Handle owner, Handle hndl, const char[] error, any anyvar) 
{
	if(hndl == INVALID_HANDLE) LogError("[CLANS] Query Fail load client: %s", error);
	else
	{
		int clanid, itemid, duration;
		char date[11];
		while(SQL_FetchRow(hndl))
		{
			clanid = SQL_FetchInt(hndl, 0);
			itemid = SQL_FetchInt(hndl, 1);
			duration = SQL_FetchInt(hndl, 2);
			SQL_FetchString(hndl, 3, date, sizeof(date));
			AddItemToClan(clanid, itemid, duration, date);
		}
	}
}

public void SQL_LoadPlayerCallback(Handle owner, Handle hndl, const char[] error, int client) 
{
	if(hndl == INVALID_HANDLE) LogError("[CLANS] Query Fail load client: %s", error);
	else
	{
		int clanid, state, itemid;
		char c_itemid[CLANKEY_SIZE];
		if(g_kvPlayerItems[client] != null)
			delete g_kvPlayerItems[client];
		g_kvPlayerItems[client] = CreateKeyValues("Player_Items");
		while(SQL_FetchRow(hndl))
		{
			clanid = SQL_FetchInt(hndl, 1);
			itemid = SQL_FetchInt(hndl, 2);
			state = SQL_FetchInt(hndl, 3);
			g_kvPlayerItems[client].SetNum("clanid", clanid);
			IntToString(itemid, c_itemid, sizeof(c_itemid));
			if(g_kvPlayerItems[client].JumpToKey(c_itemid, true))
			{
				g_kvPlayerItems[client].SetNum("item_state", state);
				g_kvPlayerItems[client].Rewind();
			}
		}
		Call_StartForward(g_hPlayerLoaded);	//CShop_OnPlayerLoaded forward
		Call_PushCell(client);
		Call_Finish();
	}
}

public void SQL_LogError(Handle owner, Handle hndl, const char[] error, int errorid)
{
	if(error[0] != 0)
	{
		char err[40];
		switch(errorid)
		{
			case 0: err = "Save item";
			case 1: err = "Update item";
			case 2: err = "Delete item from items table";
			case 3: err = "Delete item from clans table";
			case 4: err = "Save clan item";
			case 5: err = "Update clan item";
			case 6: err = "Delete clan";
			case 7: err = "Save player item";
			case 8: err = "Update player item";
			case 9: err = "Delete player item";
			case 10: err = "Delete player";
		}
		LogError("[CLANS] Query failed: %s (%d): %s", err, errorid, error);
	}
}
//=============================== NATIVES ===============================//
public any Native_IsShopLoaded(Handle plugin, int numParams)
{
	return g_bShopLoaded;
}

public any Native_GetShopStatus(Handle plugin, int numParams)
{
	return g_bShopEnabled;
}

public int Native_SetShopStatus(Handle plugin, int numParams)
{
	g_bShopEnabled = GetNativeCell(1);
	if(g_bShopEnabled && g_tUpdateItems == INVALID_HANDLE)
		g_tUpdateItems = CreateTimer(UPDATE_TIMEF, UpdateItems, _, TIMER_REPEAT);
	else if(!g_bShopEnabled && g_tUpdateItems != INVALID_HANDLE)
	{
		KillTimer(g_tUpdateItems);
		g_tUpdateItems = INVALID_HANDLE;
		Shop_SaveClans();
		Shop_SaveItems();
	}
	return 0;
}

public int Native_RegisterItem(Handle plugin, int numParams)
{
	if(numParams != 7)
		return -1;
	char category[CLAN_CATEGORY], name[100], desc[255];
	int price, sellprice, duration, type;
	GetNativeString(1, category, sizeof(category));
	GetNativeString(2, name, sizeof(name));
	GetNativeString(3, desc, sizeof(desc));
	price = GetNativeCell(4);
	sellprice = GetNativeCell(5);
	duration = GetNativeCell(6);
	type = GetNativeCell(7);
	return RegisterItem(category, name, desc, price, sellprice, duration, type);
}

public any Native_UnregisterItem(Handle plugin, int numParams)
{
	if(numParams != 1)
		return false;
	int itemid = GetNativeCell(1);
	return UnregisterItem(itemid);
}

public int Native_PlayerGetItemState(Handle plugin, int numParams)
{
	if(!g_bShopEnabled)
		return 0;
	int client = GetNativeCell(1);
	int itemid = GetNativeCell(2);
	return GetItemState(client, itemid);
}

public any Native_PlayerSetItemState(Handle plugin, int numParams)
{
	if(!g_bShopEnabled)
		return 0;
	int client = GetNativeCell(1);
	int itemid = GetNativeCell(2);
	int state = GetNativeCell(3);
	return SetItemState(client, itemid, state);
}

public any Native_IsItemActive(Handle plugin, int numParams)
{
	int itemid = GetNativeCell(1);
	int client = GetNativeCell(2);
	int state = GetItemState(client, itemid);
	return g_bShopEnabled && (state == 2 || state == 3);
}

public any Native_HasClanAnyItems(Handle plugin, int numParams)
{
	int clanid = GetNativeCell(1);
	return HasClanAnyItems(clanid);
}

public int Native_SetItemPrice(Handle plugin, int numParams)
{
	int itemid = GetNativeCell(1);
	int price = GetNativeCell(2);
	SetItemPrice(itemid, price);
	return 0;
}

public int Native_SetItemSellPrice(Handle plugin, int numParams)
{
	int itemid = GetNativeCell(1);
	int sellprice = GetNativeCell(2);
	SetItemSellPrice(itemid, sellprice);
	return 0;
}

public int Native_SetItemDuration(Handle plugin, int numParams)
{
	int itemid = GetNativeCell(1);
	int duration = GetNativeCell(2);
	SetItemDuration(itemid, duration);
	return 0;
}