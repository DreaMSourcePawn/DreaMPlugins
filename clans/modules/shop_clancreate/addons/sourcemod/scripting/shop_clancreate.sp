#include <sourcemod>
#include <shop>
#include <clans>

int g_iPrice,
 	g_iSellPrice,
	g_iDuration;
	
ItemId g_itemid;

public Plugin myinfo = 
{ 
	name = "[SHOP] Clan create", 
	author = "Dream / SnC_P 1.11", 
	description = "Add buyable permission to create a clan", 
	version = "1.12", 
};

public OnPluginStart()
{
	ConVar hCvar;

	HookConVarChange((hCvar = CreateConVar("sm_shop_clancreate_price", "100", "Price of clan create permission.")), g_hPrice);
	g_iPrice = hCvar.IntValue;

	HookConVarChange((hCvar = CreateConVar("sm_shop_clancreate_sellprice", "80", "Sellprice of clan create permission.")), g_hSellPrice);
	g_iSellPrice = hCvar.IntValue;

	HookConVarChange((hCvar = CreateConVar("sm_shop_clancreate_permduration", "604800", "Duration")), g_hDuration);
	g_iDuration = hCvar.IntValue;

	AutoExecConfig(true, "shop_clancreate", "shop");

	if(Shop_IsStarted()) Shop_Started();
}



public int g_hPrice(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	g_iPrice = hCvar.IntValue;
	if(g_itemid != INVALID_ITEM) Shop_SetItemPrice(g_itemid, g_iPrice);
}

public int g_hSellPrice(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	g_iSellPrice = hCvar.IntValue;
	if(g_itemid != INVALID_ITEM) Shop_SetItemSellPrice(g_itemid, g_iSellPrice);
}

public int g_hDuration(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	g_iDuration = hCvar.IntValue;
	if(g_itemid != INVALID_ITEM) Shop_SetItemValue(g_itemid, g_iDuration);
}


public void Shop_Started()
{
	CategoryId CATEGORY = Shop_RegisterCategory("Clans", "Кланы", "");
	if(CATEGORY == INVALID_CATEGORY) SetFailState("Failed to register category");

	if(Shop_StartItem(CATEGORY, "clans"))
	{
		Shop_SetInfo("Право на создание клана", "", g_iPrice, g_iSellPrice, Item_Togglable, g_iDuration);
		Shop_SetCallbacks(OnItemRegistered, OnEquipItem);
		Shop_EndItem();
	}
	else
		SetFailState("Failed to register item");
}

public void OnPluginEnd() 
{
	Shop_UnregisterMe();
}

void OnItemRegistered(CategoryId category_id, const char[] category, const char[] item, ItemId item_id)
{
	g_itemid = item_id;
}

Action AddPermission(Handle timer, int client)
{
	Clans_SetCreatePerm(client, true);
}

public ShopAction OnEquipItem(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] sItem, bool isOn, bool elapsed)
{
	if (isOn || elapsed)
	{
		Clans_SetCreatePerm(client, false);
		return Shop_UseOff;
	}

	CreateTimer(1.0, AddPermission, client, TIMER_FLAG_NO_MAPCHANGE);
	return Shop_UseOn;
}