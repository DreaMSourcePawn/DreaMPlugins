#define INVALID_CATEGORY -1

/** Список категорий */
ArrayList g_alCategories;

/** Отображение: имя категории -> id категории  */
StringMap g_smCategories;

/**
 * Инициализация категорий
 */
void InitCategories()
{
    g_alCategories = new ArrayList(sizeof(Category));
    g_smCategories = new StringMap();
}

/**
 * Регистрирует категорию по имени
 *
 * @param sName         название категории
 * 
 * @return              categoryId ид категории
 */
ClanCategoryId RegisterCategory(const char[] sName)
{
    ClanCategoryId categoryId;
    if(g_smCategories.GetValue(sName, categoryId))
        return categoryId;

    Category category;
    FormatEx(category.sName, sizeof(category.sName), "%s", sName);
    category.alItems = new ArrayList();
    categoryId = g_alCategories.PushArray(category);

    g_smCategories.SetValue(sName, categoryId);
    return categoryId;
}

/**
 * Добавляет предмет в категорию
 * 
 * @param id            id категории
 * @param itemId        id предмета
 */
void AddItemToCategory(ClanCategoryId id, ClanItemId itemId, bool bHidden)
{
    Category category;
    g_alCategories.GetArray(id, category, sizeof(category));
    ArrayList alCategoryItems = category.alItems;
    for(int i = 0; i < alCategoryItems.Length; ++i)
    {
        if(alCategoryItems.Get(i) == itemId)
            return;
    }

    alCategoryItems.Push(itemId);
    if(!bHidden)
    {
        category.iVisibleItems++;
        g_alCategories.SetArray(id, category, sizeof(category));
    }
}

/**
 * Удаление предмета из категории
 * 
 * @param id            ид категории
 * @param itemId        ид предмета
 * 
 * @noreturn
 */
void RemoveItemFromCategory(ClanCategoryId id, ClanItemId itemId)
{
    Category category;
    g_alCategories.GetArray(id, category, sizeof(category));
    ArrayList alCategoryItems = category.alItems;
    for(int i = 0; i < alCategoryItems.Length; ++i)
    {
        if(alCategoryItems.Get(i) == itemId)
        {
            alCategoryItems.Erase(i);
            return;
        }
    }
}

/**
 * Получение названия категории по ид
 * 
 * @param id              индекс категории
 * @param sBuffer         буфер, куда записывать название
 * @param iBufferSize     размер буфера
 * @noreturn
 */
/*void GetCategoryName(ClanCategoryId id, char[] sBuffer, int iBufferSize)
{
    Category category;
    if(!GetCategoryFromArray(id, category))
        return;
    
    FormatEx(sBuffer, iBufferSize, "%s", category.sName);
}*/

/**
 * Получение списка предметов категории
 * 
 * @param id        индекс категории
 * 
 * @return          ArrayList список предметов категории
 */
ArrayList GetCategoryItems(ClanCategoryId id)
{
    Category category;
    if(GetCategoryFromArray(id, category))
        return category.alItems;
    
    return null;
}

/**
 * Узнать, скрыта ли категория
 * 
 * @param id     индекс категории
 * @return       true, если да или категории нет, false иначе
 */
/*bool IsCategoryHidden(ClanCategoryId id)
{
    Category category;
    if(GetCategoryFromArray(id, category))
        return category.iVisibleItems == 0;
    
    return true;
}*/

/**
 * Получить категорию из списка по индексу
 * 
 * @param index         индекс категории
 * @param category      структура категории
 * 
 * @return              true в случае успеха, иначе - false
 */
bool GetCategoryFromArray(int index, Category category)
{
    if(index < 0 || index > g_alCategories.Length)
        return false;
    g_alCategories.GetArray(index, category, sizeof(category));
    return true;
}

/**
 * Получить категорию из списка по индексу
 * 
 * @param sName         имя категории
 * @param category      структура для хранения категории
 * 
 * @return              true в случае успеха, иначе - false
 */
bool GetCategoryFromArrayByName(const char[] sName, Category category)
{
    int index;
    if(!g_smCategories.GetValue(sName, index))
        return false;
    g_alCategories.GetArray(index, category, sizeof(category));
    return true;
}

/**
 * Обновить категорию из списка по индексу
 * 
 * @param index         индекс категории
 * @param category      обновленная структура категории
 * 
 * @return              true в случае успеха, иначе - false
 */
bool UpdateCategoryInArray(int index, Category category)
{
    if(index < 0 || index > g_alCategories.Length)
        return false;
    g_alCategories.SetArray(index, category, sizeof(category));
    return true;
}