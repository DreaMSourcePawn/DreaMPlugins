#include <sourcemod>
#include <shop>
#include <clans>

new Handle:g_hPrice, g_iPrice,
	Handle:g_hSellPrice, g_iSellPrice,
	ItemId:id;
	
bool used[MAXPLAYERS+1];

public Plugin:myinfo = 
{ 
	name = "[SHOP] Clan create", 
	author = "Dream", 
	description = "Add buyable permission to create a clan", 
	version = "1.0", 
} 

public OnPluginStart()
{
	g_hPrice = CreateConVar("sm_shop_clancreate_price", "100", "Price of clan create permission.");
	g_iPrice = GetConVarInt(g_hPrice);
	HookConVarChange(g_hPrice, OnConVarChange);
	
	g_hSellPrice = CreateConVar("sm_shop_clancreate_sellprice", "80", "Sellprice of clan create permission.");
	g_iSellPrice = GetConVarInt(g_hSellPrice);
	HookConVarChange(g_hSellPrice, OnConVarChange);

	AutoExecConfig(true, "shop_clancreate", "shop");

	if(Shop_IsStarted()) Shop_Started();
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if(hCvar == g_hPrice) 
	{
		g_iPrice = StringToInt(newValue);
		if(id != INVALID_ITEM) Shop_SetItemPrice(id, g_iPrice);
	}
	else if(hCvar == g_hSellPrice) 
	{
		g_iSellPrice = StringToInt(newValue);
		if(id != INVALID_ITEM) Shop_SetItemSellPrice(id, g_iSellPrice);
	}
}

public OnPluginEnd() 
{
	Shop_UnregisterMe();
}

public Shop_Started()
{
	new CategoryId:category_id = Shop_RegisterCategory("stuff", "Разное", "");
	
	if (Shop_StartItem(category_id, "clancreate"))
	{
		Shop_SetInfo("Разрешение на создание клана", "Дает Вам разрешение на создание клана до перезахода или смены карты", g_iPrice, g_iSellPrice, Item_Finite, 1);
		Shop_SetCallbacks(OnItemRegistered, OnPermissionUse);
		Shop_EndItem();
	}
}

public OnItemRegistered(CategoryId:category_id, const String:category[], const String:item[], ItemId:item_id)
{
	id = item_id;
}

public ShopAction:OnPermissionUse(client, CategoryId:category_id, const String:category[], ItemId:item_id, const String:item[])
{
	if(Clans_GetOnlineClientClan(client) == -1 && !used[client])
	{
		Clans_SetCreatePerm(client, true);
		used[client] = true;
		return Shop_UseOn;
	}
	return Shop_Raw;
}

public OnClientPostAdminCheck(client)
{
	CreateTimer(1.0, RemovePermission, client, TIMER_FLAG_NO_MAPCHANGE);
	used[client] = false;
}

public Action:RemovePermission(Handle:timer, int client)
{
	Clans_SetCreatePerm(client, false);
}

public Clans_OnClanAdded(int clanid, int client)
{
	if(used[client])
	{
		used[client] = false;
		Clans_SetCreatePerm(client, false);
	}
}