/**
 * flox_create_uid([Optional] Number length)
 * Generates a UID (unique identifier) that can be used for Entity IDs. 
 * Per default, the UID is 16 characters long. 
 * Note: do not use this function for security-critical hashing.
 */

var length = 16;
if argument_count > 0 length = argument[0];

var now = date_second_span(25569,date_current_datetime());
var b64 = "";
var chars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
var nChars = string_length(chars)-1;
repeat length { 
    var r = (irandom(nChars) + now) % nChars;
    b64 += string_char_at(chars,1+r); 
}
return b64;