#include <sourcemod>
#include <sdkhooks>
#include <clans>
#include <clans_shop>

#define ITEM_TYPE TYPE_BUYONLY

#pragma newdecls required

int taken_id = -1;
int dealt_id = -1;

int hasTaken[MAXPLAYERS+1];
int hasDealt[MAXPLAYERS+1];

Handle	g_hTaken, g_hDealt,	
		g_hTakenPrice, g_hTakenSellPrice, g_hTakenDuration,
		g_hDealtPrice, g_hDealtSellPrice, g_hDealtDuration;
float 	g_fTaken, g_fDealt;
int 	g_iTakenPrice, g_iTakenSellPrice, g_iTakenDuration, 
		g_iDealtPrice, g_iDealtSellPrice, g_iDealtDuration;

public Plugin myinfo = 
{ 
	name = "[CShop] Damage multipliers", 
	author = "Dream", 
	description = "Change taken/Dealt damage for clans", 
	version = "1.1", 
} 

public void OnPluginStart() 
{
	g_hTaken = CreateConVar("sm_cshop_damagetaken", "0.9", "Multiplier of damage taken by player");
	g_fTaken = GetConVarFloat(g_hTaken);
	HookConVarChange(g_hTaken, OnConVarChange);
	
	g_hDealt = CreateConVar("sm_cshop_damagedealt", "1.1", "Multiplier of damage dealt by player");
	g_fDealt = GetConVarFloat(g_hDealt);
	HookConVarChange(g_hDealt, OnConVarChange);
	
	g_hTakenPrice = CreateConVar("sm_cshop_takenprice", "50", "Price of damage taken multiplier");
	g_iTakenPrice = GetConVarInt(g_hTakenPrice);
	HookConVarChange(g_hTakenPrice, OnConVarChange);
	
	g_hTakenSellPrice = CreateConVar("sm_cshop_takensellprice", "25", "Sellprice of damage taken multiplier");
	g_iTakenSellPrice = GetConVarInt(g_hTakenSellPrice);
	HookConVarChange(g_hTakenSellPrice, OnConVarChange);
	
	g_hTakenDuration = CreateConVar("sm_cshop_takenduration", "604800", "Duration of damage taken multiplier in seconds");
	g_iTakenDuration = GetConVarInt(g_hTakenDuration);
	HookConVarChange(g_hTakenDuration, OnConVarChange);
	
	g_hDealtPrice = CreateConVar("sm_cshop_dealtprice", "50", "Price of damage dealt multiplier");
	g_iDealtPrice = GetConVarInt(g_hDealtPrice);
	HookConVarChange(g_hDealtPrice, OnConVarChange);
	
	g_hDealtSellPrice = CreateConVar("sm_cshop_dealtsellprice", "25", "Sellprice of damage dealt multiplier");
	g_iDealtSellPrice = GetConVarInt(g_hDealtSellPrice);
	HookConVarChange(g_hDealtSellPrice, OnConVarChange);
	
	g_hDealtDuration = CreateConVar("sm_cshop_dealtduration", "604800", "Duration of damage dealt multiplier in seconds");
	g_iDealtDuration = GetConVarInt(g_hDealtDuration);
	HookConVarChange(g_hDealtDuration, OnConVarChange);
	
	AutoExecConfig(true, "cshop_damage", "clans");
	
	if(CShop_IsShopLoaded())
		CShopLoaded();
}

public void OnPluginEnd()
{
	CShop_UnregisterItem(taken_id);
	CShop_UnregisterItem(dealt_id);
}

public void OnConVarChange(Handle hCvar, const char[] oldValue, const char[] newValue)
{
	if(hCvar == g_hTaken) 
		g_fTaken = StringToFloat(newValue);
	else if(hCvar == g_hDealt) 
		g_fDealt = StringToFloat(newValue);
	else if(hCvar == g_hTakenPrice) 
	{
		g_iTakenPrice = StringToInt(newValue);
		if(taken_id != INVALID_ITEM)	CShop_SetItemPrice(taken_id, g_iTakenPrice);
	}
	else if(hCvar == g_hTakenSellPrice) 
	{
		g_iTakenSellPrice = StringToInt(newValue);
		if(taken_id != INVALID_ITEM)	CShop_SetItemSellPrice(taken_id, g_iTakenSellPrice);
	}
	else if(hCvar == g_hTakenDuration) 
	{
		g_iTakenDuration = StringToInt(newValue);
		if(taken_id != INVALID_ITEM)	CShop_SetItemDuration(taken_id, g_iTakenDuration);
	}
	else if(hCvar == g_hDealtPrice) 
	{
		g_iDealtPrice = StringToInt(newValue);
		if(dealt_id != INVALID_ITEM)	CShop_SetItemPrice(dealt_id, g_iDealtPrice);
	}
	else if(hCvar == g_hDealtSellPrice) 
	{
		g_iDealtSellPrice = StringToInt(newValue);
		if(dealt_id != INVALID_ITEM)	CShop_SetItemSellPrice(dealt_id, g_iDealtSellPrice);
	}
	else if(hCvar == g_hDealtDuration) 
	{
		g_iDealtDuration = StringToInt(newValue);
		if(dealt_id != INVALID_ITEM)	CShop_SetItemDuration(dealt_id, g_iDealtDuration);
	}
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	hasTaken[client] = false;
	hasDealt[client] = false;
}

public void CShopLoaded()
{
	if(taken_id == -1)
		taken_id = CShop_RegisterItem("damage", "DamageTaken", "DamageTakenDesc", g_iTakenPrice, g_iTakenSellPrice, g_iTakenDuration, ITEM_TYPE);
	if(dealt_id == -1)
		dealt_id = CShop_RegisterItem("damage", "DamageDealt", "DamageDealtDesc", g_iDealtPrice, g_iDealtSellPrice, g_iDealtDuration, ITEM_TYPE);
}

public void CShop_OnPlayerLoaded(int client)
{
	if(CShop_IsItemActive(taken_id, client))
		hasTaken[client] = true;
	else
		hasTaken[client] = false;
	if(CShop_IsItemActive(dealt_id, client))
		hasDealt[client] = true;
	else
		hasDealt[client] = false;
}

public void CShop_OnItemStateChanged(int client, int itemid, int state)
{
	if(taken_id == itemid)
		hasTaken[client] = state == ITEM_ACTIVE ? true : false;
	else if(dealt_id == itemid)
		hasDealt[client] = state == ITEM_ACTIVE ? true : false;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(victim && attacker && attacker <= MAXPLAYERS && Clans_GetOnlineClientClan(victim) != Clans_GetOnlineClientClan(attacker))
	{
		if(hasDealt[attacker])
			damage = damage*g_fDealt;
		if(hasTaken[victim])
			damage = damage*g_fTaken;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}