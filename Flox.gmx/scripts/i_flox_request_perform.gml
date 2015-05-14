/**
 * i_flox_request_perform(Map request)
 * Performs a flox request and calls back with then the request
 * completes. Request map must include all details of the request including 'method', 'path', 'auth'
 * and the callbacks 'onComplete' and 'onError'
 * Method must be a valid http method, path is relative to the base path of the server
 * and data is an object containing all data required for the request.
 * Request info is a map containing any other data you wish to pass with the request,
 * when the request calls back these properties are accessible through the request object.
 * If you are making a GET request, data will be encoded into the url.
 * Note: Nested data structures in the data object are not currently supported
 * for GET requests. 
 */

var request = argument0;

var method = map_get(request,"method");
var path = map_get(request,"path");
var auth = map_get(request,"authentication");
var data = map_default(request,"data",noone);
var onComplete = map_get(request,"onComplete");
var onError = map_get(request,"onError");

var cachedResult = noone;
var requestId    = noone;

flox_log(fx_log_verbose,"Making Request","Method="+method,"Path="+path);

// If a fatal error has occurred, then fail the request
if self._fatalErrorOccurred {
    flox_log(fx_log_warn,"WARNING! Request will fail, a fatal error has already occurred and Flox has been shut down");
    return i_flox_response_fake_failure(request,"A fatal error occurred",http_status_unknown);
}
// If we are attempting to make a request while login is in process
else if not map_exists(auth) {
    flox_log(fx_log_warn,"WARNING! Request will fail, attempting request while login in process");
    return i_flox_response_fake_failure(request,"Cannot make request while login is in process",http_status_forbidden);
}

// If the method is get, encode a url
if method == http_method_get and map_exists(data) {
    path += "?" + i_flox_encode_map_for_uri(data);
    map_set(request,"path",path);
    flox_log(fx_log_silly,"Encoded data for url",path);
}
// Get the cached result from last time (if there is one)
if method == http_method_get and i_flox_cache_contains(path) {
    cachedResult = i_flox_cache_get(path,fx_null);
    flox_log(fx_log_silly,"Cache contains previous response",json_encode(cachedResult));
    // Do not use ds_map_add_map because otherwise the cached result will be removed
    if map_exists(cachedResult) then map_set(request,"cachedResult",cachedResult);
}

// Fail if we have indicated we want all requests to fail
if self.forceServiceFailure {
    flox_log(fx_log_warn,"WARNING! Request will fail, 'forceServiceFailure' is enabled");
    return i_flox_response_fake_failure(request,"Force service failure is enabled",http_status_unknown);
}

// Headers for the request
// Auth header
var floxSDK = map_create("request-headers-flox-sdk");
map_set(floxSDK,"type","gml");
map_set(floxSDK,"version",fx_sdk_version);
// Player Header
var floxPlayer = map_create("request-headers-flox-player");
map_copy(floxPlayer,auth);
// Flox header
var floxHeader = map_create("request-headers-flox");
map_set_map(floxHeader,"sdk",floxSDK);
map_set_map(floxHeader,"player",floxPlayer);
map_set(floxHeader,"gameKey",self.gameKey);
map_set(floxHeader,"bodyCompression","none"); // TODO add compression
var ctime = i_flox_get_current_time_utc();
map_set(floxHeader,"dispatchTime",flox_date_encode(ctime));
var headers = map_create("request-headers");
map_set(headers,"Content-Type","application/json");
map_set(headers,"X-Flox",json_encode(floxHeader));

// Get the meta-data associated with the cached result
if map_exists(cachedResult) {
    var eTag = i_flox_cache_metadata_get(path,"eTag",fx_null);
    map_set(headers,"If-None-Match",eTag);
}

// Create the full url
var protocol = "http";
if self.secure {
    if os_type == os_android and os_version < 10 {
        flox_log(fx_log_warn,"WARNING: Attempting to make a 'secure' request on Android version < 3.0, will fall back to http. "
            + "Read more about this issue here https://bitbucket.org/RaniSputnik/flox-gml/wiki/Attempting%20Secure%20Request%20on%20Android%20Version%20%3C%203.0");
    }
    else {
        protocol = "https";
    }
}
var basePath = self._serviceBasePath;
var fullURL = protocol + "://" + basePath + "games/" + string(self.gameID) + "/" + path;

// Perform the request
var body = '';
if map_exists(data) and method != http_method_get {
    body = json_encode(data);
}
flox_log(fx_log_silly,"Headers",json_encode(headers),"Body",body,"Full URL",fullURL);
requestId = http_request(fullURL,method,headers,body);

// Clean up the maps, nested maps not destroyed in HTML5
map_destroy(floxSDK);
map_destroy(floxPlayer);
map_destroy(floxHeader);
map_destroy(headers);
// Finally register the request in the requests being performed
map_set_map(self._serviceRequests,requestId,request);

// Return the request that was performed
return request;
