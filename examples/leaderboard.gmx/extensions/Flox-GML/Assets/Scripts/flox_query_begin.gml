/**
 * flox_query_begin(String entityType)
 * Begins a query for the given entity type.
 */

var entityType = string(argument0);
 
with flox_assert_initialized() {
    // If we aren't already building a query
    if not flox_assert(not map_exists(self._query),
        "Can not begin a new query, another query is already under construction") then exit;

    self._query = map_create("[Query] "+entityType);
    map_set(self._query,"type",entityType);
    map_set(self._query,"offset",0);
    var defaultLimit = 50;
    if os_type == os_windows then defaultLimit = 8;
    map_set(self._query,"limit",defaultLimit);
}