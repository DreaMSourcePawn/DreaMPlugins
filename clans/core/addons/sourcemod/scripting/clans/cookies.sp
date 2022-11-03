#include <clientprefs>

//Cookie (1.7)
//Куки изменения клан тега на внутрисерверный
Handle g_hClanTagCookie = null;
//Куки, хранящий время последнего создания клана
Handle g_hLastClanCreation = null;

void RegCookie()
{
	g_hClanTagCookie = RegClientCookie("Change_Clan_Tag", "Flag if the server can change player's clan tag", CookieAccess_Private);
	
	g_hLastClanCreation = RegClientCookie("Last_Clan_Creation", "Time of the last creation of clan", CookieAccess_Private);
}

/**
 * Проверка, хочет ли игрок, чтобы его клан тег менялся на внутрисерверный
 *
 * @param int client - игрок для проверки
 *
 * @return true - хочет, false иначе
 */
bool WantToChangeTag(int client)
{
	if(client < 0 || client > MaxClients || !IsClientInGame(client))
		return false;
	char buffer[10];
	buffer[0] = 0;
	GetClientCookie(client, g_hClanTagCookie, buffer, sizeof(buffer));
	if(strcmp(buffer, "") == 0)
	{
		if(g_iSetClanTag == 2)	//Ставить насильно
			return true;
		else if(g_iSetClanTag == 1)	//Ставить, если игрок в клане
			return IsClientInClan(client);
		else
			return false;
	}
	return g_iSetClanTag == 2 || (g_iSetClanTag == 1 && IsClientInClan(client)) || (g_iSetClanTag == 0 && StringToInt(buffer) == 1);
}

/**
 * Получение значения куки установки клан тега на внутрисерверный
 *
 * @param int client - игрок, чье значение получаем
 *
 * @return значение куки игрока
 */
int GetClanTagCookie(int client)
{
	char buffer[5];
	buffer[0] = 0;
	GetClientCookie(client, g_hClanTagCookie, buffer, sizeof(buffer));
	if(strcmp(buffer, "") == 0)
		return 0;
	return StringToInt(buffer);
}

/**
 * Получение значения куки установки клан тега на внутрисерверный
 *
 * @param int client - игрок, чье значение получаем
 * @param int newValue - новое значение для записи
 *
 * @noreturn
 */
void SetClanTagCookie(int client, int newValue)
{
	if(IsClientInGame(client))
	{
		char buffer[5];
		FormatEx(buffer, sizeof(buffer), "%d", newValue);
		SetClientCookie(client, g_hClanTagCookie, buffer);
	}
}

/**
 * Получение времени, когда игрок в последнее время создавал клан
 *
 * @param int client - индекс игрока
 *
 * @return int время в секундах, когда последний раз создавался клан
 */
int GetLastClanCreationTime(int client)
{
	if(client < 0 || client > MaxClients || !IsClientInGame(client))
		return -1;
	char buffer[50];
	buffer[0] = 0;
	GetClientCookie(client, g_hLastClanCreation, buffer, sizeof(buffer));
	if(strcmp(buffer, "") == 0)
		return 0;
	return StringToInt(buffer);
}

/**
 * Обновление времени, когда игрок в последнее время создавал клан, на текущее
 *
 * @param int client - индекс игрока
 */
void UpdateLastClanCreationTime(int client)
{
	if(client < 0 || client > MaxClients || !IsClientInGame(client))
		return;
	char buffer[50];
	IntToString(GetTime(), buffer, sizeof(buffer));
	SetClientCookie(client, g_hLastClanCreation, buffer);
}