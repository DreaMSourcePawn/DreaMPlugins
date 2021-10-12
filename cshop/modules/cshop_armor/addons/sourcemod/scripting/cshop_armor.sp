#include <sourcemod>
#include <clans_shop>

#define ITEM_TYPE TYPE_BUYONLY

#pragma newdecls required

int id = -1;

int hasArmor[MAXPLAYERS+1];

Handle 	g_hArmor, g_hHelmet, g_hArmorPrice, g_hArmorSellPrice, g_hArmorDuration;
int 	g_iArmor, g_iHelmet, g_iArmorPrice, g_iArmorSellPrice, g_iArmorDuration;

public Plugin myinfo = 
{ 
	name = "[CShop] Armor", 
	author = "Dream", 
	description = "Additional Armor for clans", 
	version = "1.1", 
} 

public void OnPluginStart() 
{
	g_hArmor = CreateConVar("sm_cshop_armor", "100", "Number of armor to set.");
	g_iArmor = GetConVarInt(g_hArmor);
	HookConVarChange(g_hArmor, OnConVarChange);
	
	g_hHelmet = CreateConVar("sm_cshop_helmet", "1", "Flag if helmet should be given. 1 - true, 0 - false");
	g_iHelmet = GetConVarInt(g_hHelmet);
	HookConVarChange(g_hHelmet, OnConVarChange);
	
	g_hArmorPrice = CreateConVar("sm_cshop_armorprice", "5", "Price of armor");
	g_iArmorPrice = GetConVarInt(g_hArmorPrice);
	HookConVarChange(g_hArmorPrice, OnConVarChange);
	
	g_hArmorSellPrice = CreateConVar("sm_cshop_armorsellprice", "25", "Sellprice of armor");
	g_iArmorSellPrice = GetConVarInt(g_hArmorSellPrice);
	HookConVarChange(g_hArmorSellPrice, OnConVarChange);
	
	g_hArmorDuration = CreateConVar("sm_cshop_armorduration", "604800", "Duration of armor HP in seconds");
	g_iArmorDuration = GetConVarInt(g_hArmorDuration);
	HookConVarChange(g_hArmorDuration, OnConVarChange);
	
	AutoExecConfig(true, "cshop_armor", "clans");
	
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
	if(hCvar == g_hArmor) 
		g_iArmor = StringToInt(newValue);
	else if(hCvar == g_hHelmet) 
		g_iHelmet = StringToInt(newValue);
	else if(hCvar == g_hArmorPrice) 
	{
		g_iArmorPrice = StringToInt(newValue);
		if(id != INVALID_ITEM)	CShop_SetItemPrice(id, g_iArmorPrice);
	}
	else if(hCvar == g_hArmorSellPrice) 
	{
		g_iArmorSellPrice = StringToInt(newValue);
		if(id != INVALID_ITEM)	CShop_SetItemSellPrice(id, g_iArmorSellPrice);
	}
	else if(hCvar == g_hArmorDuration) 
	{
		g_iArmorDuration = StringToInt(newValue);
		if(id != INVALID_ITEM)	CShop_SetItemDuration(id, g_iArmorDuration);
	}
}

public void CShopLoaded()
{
	if(id == -1)
		id = CShop_RegisterItem("hp_armor", "Armor", "ArmorDesc", g_iArmorPrice, g_iArmorSellPrice, g_iArmorDuration, ITEM_TYPE);
}

public void CShop_OnPlayerLoaded(int client)
{
	if(CShop_IsItemActive(id, client))
		hasArmor[client] = true;
	else
		hasArmor[client] = false;
}

public void CShop_OnItemStateChanged(int client, int itemid, int state)
{
	if(id == itemid)
	{
		hasArmor[client] = state == ITEM_ACTIVE ? true : false;
	}
}

public Action Spawn(Handle event, const char[] name, bool db)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(hasArmor[client])
	{
		SetEntProp(client, Prop_Send, "m_ArmorValue", g_iArmor);
		if(g_iHelmet == 1)
			SetEntProp(client, Prop_Send, "m_bHasHelmet", g_iHelmet);
	}
	return Plugin_Continue;
}