#if defined _clans_shop_included
	#endinput
#endif
#define _clans_shop_included

#define MAX_ITEMS 1000

//Item info
#define ITEM_INFINITE -1	//Item has infinite duration
#define ITEM_NOTSELLABLE -1	//Item has no sell price
#define ITEM_NOTBUYABLE -1	//Item has no price
#define ITEM_NOTEXISTS -1	//Item doesn't exist in DB
#define INVALID_ITEM -1

//STATES
#define ITEM_NOTBOUGHT 0
#define ITEM_UNACTIVE 1
#define ITEM_ACTIVE 2
#define ITEM_ACTIVEALLTIME 3
#define ITEM_ONEUSE 4

//TYPES
#define TYPE_BUYONLY 1		//Item will be active for each player in clan for all item's duration
#define TYPE_TOGGLEABLE 2	//Player must activate it by himself/herself
#define TYPE_ONEUSE 3		//Leader can use item by the piece

/*							 			FORWARDS							 		*/
/**
 * Calls when client's items are loaded
 *
 * @param 		int client - client's index
 * @noreturn
*/
forward void CShop_OnPlayerLoaded(int client);

/**
 * Calls when client changes the state of an item
 *
 * @param 		int client - client's index
 * @param 		int item - item's index
 * @param 		int state - 0 - unactive, 1 - active
 * @noreturn
*/
forward void CShop_OnItemStateChanged(int client, int itemid, int state);

/**
 * Calls when clan leader uses an item
 *
 * @param 		int client - client's index
 * @param 		int item - item's index
 * @noreturn
*/
forward void CShop_OnItemUsed(int client, int itemid);

/*							 			NATIVES							 			*/

/**
 * Check if shop is loaded
 *
 * @return	true if shop is loaded, false otherwise
 */
native bool CShop_IsShopLoaded();

/**
 * Get status of clan shop
 *
 * @return	true if shop is enable, false otherwise
 */
native bool CShop_GetShopStatus();

/**
 * Set status of clan shop
 *
 * @param bool newStatus - true - activate the shop, false - deactivate
 * @noreturn
 */
native void CShop_SetShopStatus(bool newStatus);

/**
 * Register an item
 *
 * @param 	char[] category - category of item
 * @param 	char[] name - name of item
 * @param 	char[] desc - description of item
 * @param 	int price - price of item
 * @param 	int sellprice - sellprice of item
 * @param 	int duration - duration of item in seconds
 * @param 	int type - type of item
 * @return 	id of registered item, -1 if failed
 */
native int CShop_RegisterItem(char[] category, char[] name, char[] desc, int price, int sellprice, int duration, int type);

/**
 * Unregister an item
 * @param	int id - item's id to unregister
 * @return true if succeed, false otherwise
 */
native bool CShop_UnregisterItem(int id);

/**
 * Get item's state in player items
 *
 * @param	int client - client's index
 * @param	int itemid - item's index
 * @return	item's state: 2 - active, 1 - unactive, 0 - isn't bought
 */
native int CShop_PlayerGetItemState(int client, int itemid);

/**
 * Set item's state in player items
 *
 * @param	int itemid - item's index
 * @param	int client - client's index
 * @param	int state - 0 - unactive, 1 - active
 * @noreturn
 */
native void CShop_PlayerSetItemState(int client, int itemid, int state);

/**
 * Check if item is active in player items
 *
 * @param	int itemid - item's index
 * @param	int client - client's index
 * @return	true if active, false otherwise
 */
native bool CShop_IsItemActive(int itemid, int client);

/**
 * Check if clan has any items
 *
 * @param	int clanid - clan's index
 * @return	true if it has, false otherwise
 */
native bool CShop_HasClanAnyItems(int clanid);

/**
 * Set item price
 *
 * @param	int itemid - item's index
 * @param	int price - new price
 * @noreturn
 */
native void CShop_SetItemPrice(int itemid, int price);

/**
 * Set item sellprice
 *
 * @param	int itemid - item's index
 * @param	int sellprice - new sellprice
 * @noreturn
 */
native void CShop_SetItemSellPrice(int itemid, int sellprice);

/**
 * Set item duration
 *
 * @param	int itemid - item's index
 * @param	int duration - new duration in seconds
 * @noreturn
 */
native void CShop_SetItemDuration(int itemid, int duration);