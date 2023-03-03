/**
 * Проверка, что у игрока есть нужный админский флаг
 * TODO: Сделать тут кастомный флажок, а не z
 *
 * @param int iClient - индекс игрока
 *
 * @return true, если нет, false - иначе
 */
bool HasPlayerAdminFlag(int iClient)
{
    AdminId admID = GetUserAdmin(iClient);
    return admID != INVALID_ADMIN_ID && admID.HasFlag(Admin_Root, Access_Effective);    //Access_Real
}

/**
 * Проверка, что магазин доступен
 */
bool IsShopActive()
{
    return g_Database != null && g_dbClans != null && g_bIsShopEnabled;
}

/**
 * Установка статуса магазина
 * 
 * @param bool bActive - статус магазин (включен/выключен)
 * 
 * @noreturn
 */
void SetShopStatus(bool bActive)
{
    g_bIsShopEnabled = bActive;
    F_OnShopStatusChange(bActive);
}

/**
 * Изменение названия, если оно найдено в файле перевода
 * 
 * @param int iClient - индекс игрока, кому показывать
 * @param char[] sName - буфер-название объекта
 * @param int iNameMaxLength - максимальная длина буфера
 * @param bool bHidden - флажок скрытия объекта
 */
void DisplayNameForMenu(int iClient, char[] sName, int iNameMaxLength, bool bHidden = false)
{
    if(TranslationPhraseExists(sName))
    {
        Format(sName, iNameMaxLength, "%T", sName, iClient);
        if(bHidden)
            Format(sName, iNameMaxLength, "[H] %s", sName);
    }
    else if(bHidden)
    {
        Format(sName, iNameMaxLength, "[H] %s", sName);
    }
}

/**
 * Converting seconds to time. Buffer's first char will be zeroed
 *
 * @param int iSeconds
 * @param char[] sBuffer - time, format: MONTHS:DAYS:HOURS:MINUTES:SECONDS
 * @param int iBufferSize - size of buffer
 * @param int iClient - who will see the time
 */
void SecondsToTime(int iSeconds, char[] sBuffer, int iBufferSize, int iClient)
{
	if(iSeconds < 0)
	{
		FormatEx(sBuffer, iBufferSize, "%T", "Forever", iClient);
		return;
	}

	sBuffer[0] = 0;
	char sBuff[128];
	int months, days, hours, minutes;
	months = iSeconds/2678400;
	iSeconds -= 2678400*months;
	days = iSeconds/86400;
	iSeconds -= 86400*days;
	hours = iSeconds/3600;
	iSeconds -= 3600*hours;
	minutes = iSeconds/60;
	iSeconds -= 60*minutes;
	if(months > 0)
	{
		FormatEx(sBuff, sizeof(sBuff), "%T", "Months", iClient, months);
		FormatEx(sBuffer, iBufferSize, "%s%s", (sBuffer[0] == 0 ? "" : " "), sBuff);
	}
	if(days > 0)
	{
		FormatEx(sBuff, sizeof(sBuff), "%T", "Days", iClient, days);
		Format(sBuffer, iBufferSize, "%s%s%s", sBuffer, (sBuffer[0] == 0 ? "" : " "), sBuff);
	}
	if(hours > 0)
	{
		FormatEx(sBuff, sizeof(sBuff), "%T", "Hours", iClient, hours);
		Format(sBuffer, iBufferSize, "%s%s%s", sBuffer, (sBuffer[0] == 0 ? "" : " "), sBuff);
	}
	if(minutes > 0)
	{
		FormatEx(sBuff, sizeof(sBuff), "%T", "Minutes", iClient, minutes);
		Format(sBuffer, iBufferSize, "%s%s%s", sBuffer, (sBuffer[0] == 0 ? "" : " "), sBuff);
	}
	if(iSeconds > 0)
	{
		FormatEx(sBuff, sizeof(sBuff), "%T", "Seconds", iClient, iSeconds);
		Format(sBuffer, iBufferSize, "%s%s%s", sBuffer, (sBuffer[0] == 0 ? "" : " "), sBuff);
	}
}