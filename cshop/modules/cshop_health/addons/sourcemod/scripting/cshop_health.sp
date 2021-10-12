#include <sourcemod>
#include <clans_shop>

#define ITEM_TYPE TYPE_BUYONLY

#pragma newdecls required

int id = -1;

Handle 	g_hAddHP, g_hAddHPPrice, g_hAddHPSellPrice, g_hAddHPDuration;
int		g_iAddHP, g_iAddHPPrice, g_iAddHPSellPrice, g_iAddHPDuration;

bool hasAddHP[MAXPLAYERS+1];

public Plugin myinfo = 
{ 
	name = "[CShop] Health", 
	author = "Dream", 
	description = "Additional health for clans", 
	version = "1.1", 
} 

public void OnPluginStart() 
{
	g_hAddHP = CreateConVar("sm_cshop_addhp", "10", "Number of additional HP.");
	g_iAddHP = GetConVarInt(g_hAddHP);
	HookConVarChange(g_hAddHP, OnConVarChange);
	
	g_hAddHPPrice = CreateConVar("sm_cshop_addhpprice", "50", "Price of additional HP");
	g_iAddHPPrice = GetConVarInt(g_hAddHPPrice);
	HookConVarChange(g_hAddHPPrice, OnConVarChange);
	
	g_hAddHPSellPrice = CreateConVar("sm_cshop_addhpsellprice", "25", "Sellprice of additional HP");
	g_iAddHPSellPrice = GetConVarInt(g_hAddHPSellPrice);
	HookConVarChange(g_hAddHPSellPrice, OnConVarChange);
	
	g_hAddHPDuration = CreateConVar("sm_cshop_addhpduration", "604800", "Duration of additional HP in seconds");
	g_iAddHPDuration = GetConVarInt(g_hAddHPDuration);
	HookConVarChange(g_hAddHPDuration, OnConVarChange);
	
	AutoExecConfig(true, "cshop_addhp", "clans");
	
	HookEvent("player_spawn", Spawn);
	
	if(CShop_IsShopLoaded())
		CShopLoaded();
}

public void OnPluginEnd()
{
	CShop_UnregisterItem(id);
}

public void OnConVarChange(Handle hCvar, const char[] oldValue, const char[] newValue)
{
	if(hCvar == g_hAddHP) 
		g_iAddHP = StringToInt(newValue);
	else if(hCvar == g_hAddHPPrice) 
	{
		g_iAddHPPrice = StringToInt(newValue);
		if(id != INVALID_ITEM)	CShop_SetItemPrice(id, g_iAddHPPrice);
	}
	else if(hCvar == g_hAddHPSellPrice) 
	{
		g_iAddHPSellPrice = StringToInt(newValue);
		if(id != INVALID_ITEM)	CShop_SetItemSellPrice(id, g_iAddHPSellPrice);
	}
	else if(hCvar == g_hAddHPDuration) 
	{
		g_iAddHPDuration = StringToInt(newValue);
		if(id != INVALID_ITEM)	CShop_SetItemDuration(id, g_iAddHPDuration);
	}
}

public void CShopLoaded()
{
	if(id == -1)
		id = CShop_RegisterItem("hp_armor", "Health", "HealthDesc", g_iAddHPPrice, g_iAddHPSellPrice, g_iAddHPDuration, ITEM_TYPE);
}

public void CShop_OnPlayerLoaded(int client)
{
	if(CShop_IsItemActive(id, client))
		hasAddHP[client] = true;
	else
		hasAddHP[client] = false;
}

public void CShop_OnItemStateChanged(int client, int itemid, int state)
{
	if(id == itemid)
	{
		hasAddHP[client] = state == ITEM_ACTIVE ? true : false;
	}
}

public Action Spawn(Handle event, const char[] name, bool db)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(hasAddHP[client])
	{
		int pHealth = GetEntProp(client, Prop_Send, "m_iHealth");
		SetEntProp(client, Prop_Send, "m_iHealth", pHealth+g_iAddHP);
	}
	return Plugin_Continue;
}