#define CSEASONS_NO_SEASON -1
#define CSEASONS_NO_WINNER -1

/**
 * Get current season id
 *
 * @noparam
 * @return current season's id, CSEASONS_NO_SEASON if no season has been started
 */
native bool CSeasons_IsCoreReady();

/**
 * Get current season id
 *
 * @noparam
 * @return current season's id, CSEASONS_NO_SEASON if no season has been started
 */
native int CSeasons_GetCurrentSeasonID();

/**
 * Get current season expiration time
 *
 * @noparam
 * @return current season's expiration time, CSEASONS_NO_SEASON if no season has been started
 */
native int CSeasons_GetCurrentSeasonExpirationTime();

/**
 * Throw rewards menu to client
 *
 * @param int iClient - client's index
 *
 * @return true on success, false otherwise (client's offline)
 */
native bool CSeasons_ThrowRewardsMenu(int iClient);

		/* 						FORWARDS 						*/
/**
 * Called when season core is loaded
 *
 * @noparam
 *
 * @noreturn
 */
forward void CSeasons_OnCoreReady();

/**
 * Called when season has just started (new or the season, which wasn't finished yet but loaded with the core)
 *
 * @param int iSeasonID - current season's id
 * @param int iExpireTime - when season expires
 *
 * @noreturn
 */
forward void CSeasons_OnSeasonStarted(int iSeasonID, int iExpireTime);

/**
 * Called when season has been just finished
 *
 * @param int iSeasonID - current season's id
 *
 * @noreturn
 */
forward void CSeasons_OnSeasonJustFinished(int iSeasonID);

/**
 * Called when season has been fully finished (1 minute after CSeasons_OnSeasonJustFinished called)
 *
 * @param int iSeasonID - current season's id
 * @param int iClanWinnerid - clan winner's id
 * @param const char[] sClanWinnerName - clan winner's name
 * @param int iScore - clan's score
 *
 * @noreturn
 */
forward void CSeasons_OnSeasonFinished(int iSeasonID, int iClanWinnerid, const char[] sClanWinnerName, int iScore);

/**
 * Called when player opens season info menu
 *
 * @param int iSeasonID - current season's id
 * @param int iClient - client's index
 * @param char[] sInfo - info to be shown to client
 * @param int iMaxLength - sInfo buffer length
 *
 * @noreturn
 */
forward void CSeasons_OnSeasonInfoOpened(int iSeasonID, int iClient, char[] sInfo, int iMaxLength);

/**
 * Called when player opens season rewards menu
 *
 * @param Menu mSeasonRewards - menu's handle
 * @param int iSeasonID - current season's id
 * @param int iClient - client's index
 *
 * @noreturn
 */
forward void CSeasons_OnSeasonRewardsOpened(Menu mSeasonRewards, int iSeasonID, int iClient);

/**
 * Called when player selects any option in the season rewards menu
 *
 * @param Menu mSeasonRewards - menu's handle
 * @param int iSeasonID - current season's id
 * @param int iClient - client's index
 * @param int iOption - selected option
 *
 * @noreturn
 */
forward void CSeasons_OnSeasonRewardsSelected(Menu mSeasonRewards, int iSeasonID, int iClient, int iOption);

/**
 * Called when player opens admin menu
 *
 * @param Menu mAdminMenu - menu's handle
 * @param int iSeasonID - current season's id
 * @param int iClient - client's index
 *
 * @noreturn
 */
forward void CSeasons_OnAdminMenuOpened(Menu mAdminMenu, int iSeasonID, int iClient);

/**
 * Called when player selects any option in the admin menu
 *
 * @param Menu mAdminMenu - menu's handle
 * @param int iSeasonID - current season's id
 * @param int iClient - client's index
 * @param int iOption - selected option
 *
 * @noreturn
 */
forward void CSeasons_OnAdminMenuSelected(Menu mAdminMenu, int iSeasonID, int iClient, int iOption);