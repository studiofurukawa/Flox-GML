/**
 * flox_entity_create(String entityType) Entity
 * Creates a new Flox entity, note that this method DOESN'T hit the
 * server, you must create a flox entity and then save it for the data
 * to be stored on Flox.
 */

var entityType = argument0;
if not flox_assert(is_string(entityType),"Entity type must be a valid string '"+string(entityType)+"'") return noone;

// TODO check there are no invalid characters in the entityType

var entity = map_create("[Entity] "+entityType);
// Basic properties
map_set(entity,flox_type,entityType);
map_set(entity,flox_id,flox_create_uid());
map_set(entity,flox_public_access,flox_no_access);
var currentTime = i_flox_get_current_time_utc();
map_set(entity,flox_created_at,currentTime);
map_set(entity,flox_updated_at,currentTime);
// Get the owner of this entity (either the current player or noone)
var player = flox_player_get();
if flox_entity_exists(player) map_set(entity,flox_owner_id,map_get(player,"id"));
else map_set(entity,flox_owner_id,noone);

return entity;
