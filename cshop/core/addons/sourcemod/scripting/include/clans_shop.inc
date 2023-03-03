#if defined _clans_shop_included
	#endinput
#endif
#define _clans_shop_included

//Item info
#define INVALID_ITEM -1
#define INVALID_ITEM_PARAM -2

#define ITEM_INFINITE -1		//Item has infinite duration
#define ITEM_NOTSELLABLE -1		//Item has no sell price
#define ITEM_NOTBUYABLE -1		//Item has no price

#define ClanItemId int

//STATES OF ITEMS
enum CShop_ItemState
{
	CSHOP_STATE_NOTBOUGHT = 0,
	CSHOP_STATE_UNACTIVE = 1,
	CSHOP_STATE_ACTIVE = 2
}

//TYPES OF ITEMS
enum CShop_ItemType
{
	CSHOP_TYPE_INVALID = 0,		// Тип не задан/предмета нет!
	CSHOP_TYPE_BUYONLY = 1,
	CSHOP_TYPE_TOGGLEABLE = 2,
	CSHOP_TYPE_ONEUSE = 3
}

//Core response on 'set' actions
enum CShop_Response
{
	CSHOP_SUCCESS = 0,			// Успех
	CSHOP_SAME_VALUE,			// Подано то же значение, что уже есть
	CSHOP_ITEM_NOT_EXISTS,		// Не найден предмет
	CSHOP_WRONG_PARAM,			// Подан неверный параметр
	CSHOP_CANT_BE_CHANGE		// Не может быть изменено (например, нельзя менять число используемых предметов)
}

#include <cshop/items>
#include <cshop/players>
#include <cshop/clans>

/**
 * Получение базы данных магазина
 */
native Database CShop_GetShopDatabase();

/**
 * Узнать, загружен ли магазин
 * 
 * @return true - активен, false - отключен
 */
native bool CShop_IsShopLoaded();

/**
 * Получение статуса магазина
 * 
 * @return true - активен, false - отключен
 */
native bool CShop_IsShopActive();

/**
 * Установка статуса магазина
 * 
 * @param bool bActive - статус магазин (включен/выключен)
 * 
 * @noreturn
 */
native void CShop_SetShopActive(bool bActive);

/**
 * Коллбэк регистрации предмета
 * 
 * @param ClanItemId itemId - ид предмета
 * @param const char[] sName - имя предмета
 * 
 * @noreturn
 */
typedef CShop_RegItemCallback = function void(ClanItemId itemId, const char[] sName);

/**
 * Регистрирует предмет
 *
 * @param const char[] sCategory - название категории
 * @param const char[] sName - название предмета
 * @param const char[] sDesc - описание предмета (если указанное описание найдено в файле перевода, то берется оттуда)
 * @param CShop_RegItemCallback callback - коллбэк, вызываемый после регистрации
 * 
 * @noreturn
 */
native void CShop_RegisterItem(const char[] sCategory, const char[] sName, const char[] sDesc, CShop_RegItemCallback callback);

/**
 * Снятие всех предметов с регистрации
 * @noreturn
 */
native void CShop_UnregisterMe();