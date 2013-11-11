#define _httpInit
// Internal function - creates httpClient object type
// void _httpInit()
// Called by GM when extension loaded

global.__HttpClient = object_add();
object_set_persistent(global.__HttpClient, true);

#define httpParseUrl
// Parses a URL into its components
// real httpParseUrl(string url)

// Return value is a ds_map containing keys for the different URL parts: (or -1 on failure)
// "url" - the URL which was passed in
// "scheme" - the URL scheme (e.g. "http")
// "host" - the hostname (e.g. "example.com" or "127.0.0.1")
// "port" - the port (e.g. 8000) - this is a real, unlike the others
// "abs_path" - the absolute path (e.g. "/" or "/index.html")
// "query" - the query string (e.g. "a=b&c=3")
// Parts which are not included will not be in the map
// e.g. http://example.com will not have the "port", "path" or "query" keys

// This will *only* work properly for URLs of format:
// scheme ":" "//" host [ ":" port ] [ abs_path [ "?" query ]]"
// where [] denotes an optional component
// file: URLs will *not* work as they lack the authority (host:port) component
// It will not work correctly for IPv6 host values

var url;
url = argument0;

var map;
map = ds_map_create();
ds_map_add(map, 'url', url);

// before scheme
var colonPos;
// Find colon for end of scheme
colonPos = string_pos(':', url);
// No colon - bad URL
if (colonPos == 0)
    return -1;
ds_map_add(map, 'scheme', string_copy(url, 1, colonPos - 1));
url = string_copy(url, colonPos + 1, string_length(url) - colonPos);

// before double slash
// remove slashes (yes this will screw up file:// but who cares)
while (string_char_at(url, 1) == '/')
    url = string_copy(url, 2, string_length(url) - 1);

// before hostname
var slashPos, colonPos;
// Find slash for beginning of path
slashPos = string_pos('/', url);
// No slash ahead - http://host format with no ending slash
if (slashPos == 0)
{
    // Find : for beginning of port
    colonPos = string_pos(':', url);
}
else
{
    // Find : for beginning of port prior to /
    colonPos = string_pos(':', string_copy(url, 1, slashPos - 1));
}
// No colon - no port
if (colonPos == 0)
{
    // There was no slash
    if (slashPos == 0)
    {
        ds_map_add(map, 'host', url);
        return map;
    }
    // There was a slash
    else
    {
        ds_map_add(map, 'host', string_copy(url, 1, slashPos - 1));
        url = string_copy(url, slashPos, string_length(url) - slashPos + 1);
    }
}
// There's a colon - port specified
else
{
    // There was no slash
    if (slashPos == 0)
    {
        ds_map_add(map, 'host', string_copy(url, 1, colonPos - 1));
        ds_map_add(map, 'port', real(string_copy(url, colonPos + 1, string_length(url) - colonPos)));
        return map;
    }
    // There was a slash
    else
    {
        ds_map_add(map, 'host', string_copy(url, 1, colonPos - 1));
        url = string_copy(url, colonPos + 1, string_length(url) - colonPos);
        slashPos = string_pos('/', url);
        ds_map_add(map, 'port', real(string_copy(url, 1, slashPos - 1)));
        url = string_copy(url, slashPos, string_length(url) - slashPos + 1); 
    }
}

// before path
var queryPos;
queryPos = string_pos('?', url);
// There's no ? - no query
if (queryPos == 0)
{
    ds_map_add(map, 'abs_path', url);
    return map;
}
else
{
    ds_map_add(map, 'abs_path', string_copy(url, 1, queryPos - 1));
    ds_map_add(map, 'query', string_copy(url, queryPos + 1, string_length(url) - queryPos));
    return map;
}

// Return -1 upon unlikely error
ds_map_destroy(map);
return -1;

#define httpResolveUrl
// Takes a base URL and a URL reference and applies it to the base URL
// Returns resulting absolute URL
// string httpResolveUrl(string baseUrl, string refUrl)

// Return value is a string containing the new absolute URL, or "" on failure

// Works only for restricted URL syntax as understood by by httpResolveUrl
// The sole restriction of which is that only scheme://authority/path URLs work
// This notably excludes file: URLs which lack the authority component

// As described by RFC3986:
//      URI-reference = URI / relative-ref
//      relative-ref  = relative-part [ "?" query ] [ "#" fragment ]
//      relative-part = "//" authority path-abempty
//                    / path-absolute
//                    / path-noscheme
//                    / path-empty
// However httpResolveUrl does *not* deal with fragments

// Algorithm based on that of section 5.2.2 of RFC 3986

var baseUrl, refUrl;
baseUrl = argument0;
refUrl = argument1;

// Parse base URL
var urlParts;
urlParts = httpParseUrl(baseUrl);
if (urlParts == -1)
    return '';

// Try to parse reference URL
var refUrlParts, canParseRefUrl;
refUrlParts = httpParseUrl(refUrl);
canParseRefUrl = (refUrlParts != -1);
if (refUrlParts != -1)
    ds_map_destroy(refUrlParts);

var result;
result = '';

// Parsing of reference URL succeeded - it's absolute and we're done
if (canParseRefUrl)
{
    result = refUrl;
}
// Begins with '//' - scheme-relative URL
else if (string_copy(refUrl, 1, 2) == '//' and string_length(refUrl) > 2)
{
    result = ds_map_find_value(urlParts, 'scheme') + ':' + refUrl;
}
// Is or begins with '/' - absolute path relative URL
else if (((string_char_at(refUrl, 1) == '/' and string_length(refUrl) > 1) or refUrl == '/')
// Doesn't begin with ':' and is not blank - relative path relative URL
    or (string_char_at(refUrl, 1) != ':' and string_length(refUrl) > 0)) 
{
    // Find '?' for query
    var queryPos;
    queryPos = string_pos('?', refUrl);
    // No query
    if (queryPos == 0)
    {
        refUrl = httpResolvePath(ds_map_find_value(urlParts, 'abs_path'), refUrl);
        ds_map_replace(urlParts, 'abs_path', refUrl);
        if (ds_map_exists(urlParts, 'query'))
            ds_map_delete(urlParts, 'query');
    }
    // Query exists, split
    else
    {
        var path, query;
        path = string_copy(refUrl, 1, queryPos - 1);
        query = string_copy(refUrl, queryPos + 1, string_length(relUrl) - queryPos);
        path = httpResolvePath(ds_map_find_value(urlParts, 'abs_path'), path);
        ds_map_replace(urlParts, 'abs_path', path);
        if (ds_map_exists(urlParts, 'query'))
            ds_map_replace(urlParts, 'query', query);
        else
            ds_map_add(urlParts, 'query', query);
    }
    result = httpConstructUrl(urlParts);
}

ds_map_destroy(urlParts);
return result;

#define httpResolvePath
// Takes a base path and a path reference and applies it to the base path
// Returns resulting absolute path
// string httpResolvePath(string basePath, string refPath)

// Return value is a string containing the new absolute path

// Deals with UNIX-style / paths, not Windows-style \ paths
// Can be used to clean up .. and . in non-absolute paths too ('' as basePath)

var basePath, refPath;
basePath = argument0;
refPath = argument1;

// refPath begins with '/' (is absolute), we can ignore all of basePath
if (string_char_at(refPath, 1) == '/')
{
    basePath = refPath;
    refPath = '';
}

var parts, refParts;
parts = split(basePath, '/');
refParts = split(refPath, '/');

if (refPath != '')
{
    // Find last part of base path
    var lastPart;
    lastPart = ds_list_find_value(parts, ds_list_size(parts) - 1);

    // If it's not blank (points to a file), remove it
    if (lastPart != '')
    {
        ds_list_delete(parts, ds_list_size(parts) - 1);
    }
    
    // Concatenate refParts to end of parts
    var i;
    for (i = 0; i < ds_list_size(refParts); i += 1)
        ds_list_add(parts, ds_list_find_value(refParts, i));
}

// We now don't need refParts any more
ds_list_destroy(refParts);

// Deal with '..' and '.'
for (i = 0; i < ds_list_size(parts); i += 1)
{
    var part;
    part = ds_list_find_value(parts, i);

    if (part == '.')
    {
        if (i == 1 or i == ds_list_size(parts) - 1)
            ds_list_replace(parts, i, '');
        else
            ds_list_delete(parts, i);
        i -= 1;
        continue;
    }
    else if (part == '..')
    {
        if (i > 1)
        {
            ds_list_delete(parts, i - 1);
            ds_list_delete(part, i);
            i -= 2;
        }
        else
        {
            ds_list_replace(parts, i, '');
            i -= 1;
        }
        continue;
    }
    else if (part == '' and i != 0 and i != ds_list_size(parts) - 1)
    {
        ds_list_delete(parts, i);
        i -= 1;
        continue;
    }
}

// Reconstruct path from parts
var path;
path = '';
for (i = 0; i < ds_list_size(parts); i += 1)
{
    if (i != 0)
        path += '/';
    path += ds_list_find_value(parts, i);
}

ds_map_destroy(parts);
return path;

#define httpParseHex
// Takes a lowercase hexadecimal string and returns its integer value
// real httpParseHex(string hexString)

// Return value is the whole number value (or -1 if invalid)
// Only works for whole numbers (non-fractional numbers >= 0) and lowercase hex

var hexString;
hexString = argument0;

var result, hexValues;
result = 0;
hexValues = "0123456789abcdef";

var i;
for (i = 1; i <= string_length(hexString); i += 1) {
    result *= 16;
    var digit;
    digit = string_pos(string_char_at(hexString, i), hexValues) - 1;
    if (digit == -1)
        return -1;
    result += digit;
}

return result;

#define httpConstructUrl
// Constructs an URL from its components (as httpParseUrl would return)
// string httpConstructUrl(real parts)

// Return value is the string of the constructed URL
// Keys of parts map:
// "scheme" - the URL scheme (e.g. "http")
// "host" - the hostname (e.g. "example.com" or "127.0.0.1")
// "port" - the port (e.g. 8000) - this is a real, unlike the others
// "abs_path" - the absolute path (e.g. "/" or "/index.html")
// "query" - the query string (e.g. "a=b&c=3")
// Parts which are omitted will be omitted in the URL
// e.g. http://example.com lacks "port", "path" or "query" keys

// This will *only* work properly for URLs of format:
// scheme ":" "//" host [ ":" port ] [ abs_path [ "?" query ]]"
// where [] denotes an optional component
// file: URLs will *not* work as they lack the authority (host:port) component
// Should work correctly for IPv6 host values, but bare in mind parse_url won't

var parts;
parts = argument0;

var url;
url = '';

url += ds_map_find_value(parts, 'scheme');
url += '://';
url += ds_map_find_value(parts, 'host');
if (ds_map_exists(parts, 'port'))
    url += ':' + string(ds_map_find_value(parts, 'port'));
if (ds_map_exists(parts, 'abs_path'))
{
    url += ds_map_find_value(parts, 'abs_path');
    if (ds_map_exists(parts, 'query'))
        url += '?' + ds_map_find_value(parts, 'query');
}

return url;

#define httpGet
// Makes a GET HTTP request
// real httpGet(string url, real headers)

// url - URL to send GET request to
// headers - ds_map of extra headers to send, -1 if none

// Return value is an HttpClient instance that can be passed to httpRequestStatus etc.
// (errors on failure to parse URL)

var url, headers, client;

url = argument0;
headers = argument1;

client = instance_create(0, 0, global.__HttpClient);
_httpPrepareRequest(client, url, headers);
return client;

#define _httpPrepareRequest
// Internal function - prepares request
// void httpRequestGet(real client, string url, real headers)

// client - HttpClient object to prepare
// url - URL to send GET request to
// headers - ds_map of extra headers to send, -1 if none


var client, url, headers;
client = argument0;
url = argument1;
headers = argument2;

var parsed;
parsed = httpParseUrl(url);

if (parsed == -1)
    show_error("Error when making HTTP GET request - can't parse URL: " + url, true);

if (!ds_map_exists(parsed, 'port'))
    ds_map_add(parsed, 'port', 80);
if (!ds_map_exists(parsed, 'abs_path'))
    ds_map_add(parsed, 'abs_path', '/');

with (client)
{
    destroyed = false;
    CR = chr(13);
    LF = chr(10);
    CRLF = CR + LF;
    socket = tcp_connect(ds_map_find_value(parsed, 'host'), ds_map_find_value(parsed, 'port'));
    state = 0;
    errored = false;
    error = '';
    linebuf = '';
    line = 0;
    statusCode = -1;
    reasonPhrase = '';
    responseBody = buffer_create();
    responseBodySize = -1;
    responseBodyProgress = -1;
    responseHeaders = ds_map_create();
    requestUrl = url;
    requestHeaders = headers;

    //  Request       = Request-Line              ; Section 5.1
    //                  *(( general-header        ; Section 4.5
    //                   | request-header         ; Section 5.3
    //                   | entity-header ) CRLF)  ; Section 7.1
    //                  CRLF
    //                  [ message-body ]          ; Section 4.3

    // "The Request-Line begins with a method token, followed by the
    // Request-URI and the protocol version, and ending with CRLF. The
    // elements are separated by SP characters. No CR or LF is allowed
    // except in the final CRLF sequence."
    if (ds_map_exists(parsed, 'query'))
        write_string(socket, 'GET ' + ds_map_find_value(parsed, 'abs_path') + '?' + ds_map_find_value(parsed, 'query') + ' HTTP/1.1' + CRLF);
    else
        write_string(socket, 'GET ' + ds_map_find_value(parsed, 'abs_path') + ' HTTP/1.1' + CRLF);

    // "A client MUST include a Host header field in all HTTP/1.1 request
    // messages."
    // "A "host" without any trailing port information implies the default
    // port for the service requested (e.g., "80" for an HTTP URL)."
    if (ds_map_find_value(parsed, 'port') == 80)
        write_string(socket, 'Host: ' + ds_map_find_value(parsed, 'host') + CRLF);
    else
        write_string(socket, 'Host: ' + ds_map_find_value(parsed, 'host')
            + ':' + string(ds_map_find_value(parsed, 'port')) + CRLF);

    // "An HTTP/1.1 server MAY assume that a HTTP/1.1 client intends to
    // maintain a persistent connection unless a Connection header including
    // the connection-token "close" was sent in the request."
    write_string(socket, 'Connection: close' + CRLF);

    // "If no Accept-Encoding field is present in a request, the server MAY
    // assume that the client will accept any content coding."
    write_string(socket, 'Accept-Encoding:' + CRLF);
    
    // If headers specified
    if (headers != -1)
    {
        var key;
        // Iterate over headers map
        for (key = ds_map_find_first(headers); is_string(key); key = ds_map_find_next(headers, key))
        {
            write_string(socket, key + ': ' + ds_map_find_value(headers, key) + CRLF);
        }
    }
    
    // Send extra CRLF to terminate request
    write_string(socket, CRLF);
    
    socket_send(socket);

    ds_map_destroy(parsed);
}

#define _httpParseHeader
// Internal function - parses header
// real _httpParseHeader(string linebuf, real line)
// Returns false if it errored (caller should return and destroy)

var linebuf, line;
linebuf = argument0;
line = argument1;

// "HTTP/1.1 header field values can be folded onto multiple lines if the
// continuation line begins with a space or horizontal tab."
if ((string_char_at(linebuf, 1) == ' ' or ord(string_char_at(linebuf, 1)) == 9))
{
    if (line == 1)
    {
        errored = true;
        error = "First header line of response can't be a continuation, right?";
        return false;
    }
    headerValue = ds_map_find_value(responseHeaders, string_lower(headerName))
        + string_copy(linebuf, 2, string_length(linebuf) - 1);
}
// "Each header field consists
// of a name followed by a colon (":") and the field value. Field names
// are case-insensitive. The field value MAY be preceded by any amount
// of LWS, though a single SP is preferred."
else
{
    var colonPos;
    colonPos = string_pos(':', linebuf);
    if (colonPos == 0)
    {
        errored = true;
        error = "No colon in a header line of response";
        return false;
    }
    headerName = string_copy(linebuf, 1, colonPos - 1);
    headerValue = string_copy(linebuf, colonPos + 1, string_length(linebuf) - colonPos);
    // "The field-content does not include any leading or trailing LWS:
    // linear white space occurring before the first non-whitespace
    // character of the field-value or after the last non-whitespace
    // character of the field-value. Such leading or trailing LWS MAY be
    // removed without changing the semantics of the field value."
    while (string_char_at(headerValue, 1) == ' ' or ord(string_char_at(headerValue, 1)) == 9)
        headerValue = string_copy(headerValue, 2, string_length(headerValue) - 1);
}

ds_map_add(responseHeaders, string_lower(headerName), headerValue);

if (string_lower(headerName) == 'content-length')
{
    responseBodySize = real(headerValue);
    responseBodyProgress = 0;
}

return true;

#define _httpClientDestroy
// Clears up contents of an httpClient prior to destruction or after error

if (!destroyed) {
    socket_destroy(socket);
    buffer_destroy(responseBody);
    ds_map_destroy(responseHeaders);
}
destroyed = true;

#define httpRequestStep
// Steps the HTTP request (you need to call this each step or so)
// void httpRequestStep(real client)

// client - HttpClient object

var client;
client = argument0;

with (client)
{
    if (errored)
        exit;
    
    // Socket error
    if (socket_has_error(socket))
    {
        errored = true;
        error = "Socket error: " + socket_error(socket);
        return _httpClientDestroy();
    }
    
    var available;
    available = tcp_receive_available(socket);
    
    switch (state)
    {
    // Receiving lines
    case 0:
        var bytesRead, c;
        for (bytesRead = 1; bytesRead <= available; bytesRead += 1)
        {
            c = read_string(socket, 1);
            // Reached end of line
            // "HTTP/1.1 defines the sequence CR LF as the end-of-line marker for all
            // protocol elements except the entity-body (see appendix 19.3 for
            // tolerant applications)."
            if (c == LF and string_char_at(linebuf, string_length(linebuf)) == CR)
            {
                // Strip trailing CR
                linebuf = string_copy(linebuf, 1, string_length(linebuf) - 1);
                // First line - status code
                if (line == 0)
                {
                    // "The first line of a Response message is the Status-Line, consisting
                    // of the protocol version followed by a numeric status code and its
                    // associated textual phrase, with each element separated by SP
                    // characters. No CR or LF is allowed except in the final CRLF sequence."
                    var httpVer, spacePos;
                    spacePos = string_pos(' ', linebuf);
                    if (spacePos == 0)
                    {
                        errored = true;
                        error = "No space in first line of response";
                        return _httpClientDestroy();
                    }
                    httpVer = string_copy(linebuf, 1, spacePos);
                    linebuf = string_copy(linebuf, spacePos + 1, string_length(linebuf) - spacePos);
    
                    spacePos = string_pos(' ', linebuf);
                    if (spacePos == 0)
                    {
                        errored = true;
                        error = "No second space in first line of response";
                        return _httpClientDestroy();
                    }
                    statusCode = real(string_copy(linebuf, 1, spacePos));
                    reasonPhrase = string_copy(linebuf, spacePos + 1, string_length(linebuf) - spacePos);
                }
                // Other line
                else
                {
                    // Blank line, end of response headers
                    if (linebuf == '')
                    {
                        state = 1;
                        // write remainder
                        write_buffer_part(responseBody, socket, available - bytesRead);
                        responseBodyProgress = available - bytesRead;
                        break;
                    }
                    // Header
                    else
                    {
                        if (!_httpParseHeader(linebuf, line))
                            return _httpClientDestroy();
                    }
                }
    
                linebuf = '';
                line += 1;
            }
            else
                linebuf += c;
        }
        break;
    // Receiving response body
    case 1:
        write_buffer(responseBody, socket);
        responseBodyProgress += available;
        if (tcp_eof(socket))
        {
            if (ds_map_exists(responseHeaders, 'transfer-encoding'))
            {
                if (ds_map_find_value(responseHeaders, 'transfer-encoding') == 'chunked')
                {
                    // Chunked transfer, let's decode it
                    var actualResponseBody, actualResponseSize;
                    actualResponseBody = buffer_create();
                    actualResponseBodySize = 0;

                    // Parse chunks
                    // chunk          = chunk-size [ chunk-extension ] CRLF
                    //                  chunk-data CRLF
                    // chunk-size     = 1*HEX
                    while (buffer_bytes_left(responseBody))
                    {
                        var chunkSize, c;
                        chunkSize = '';
                        
                        // Read chunk size byte by byte 
                        while (buffer_bytes_left(responseBody))
                        {
                            c = read_string(responseBody, 1);
                            if (c == CR or c == ';')
                                break;
                            else
                                chunkSize += c;
                        }
                        
                        // We found a semicolon - beginning of chunk-extension
                        if (c == ';')
                        {
                            // skip all extension stuff
                            while (buffer_bytes_left(responseBody) && c != CR)
                            {
                                c = read_string(responseBody, 1);
                            }
                        }
                        // Reached end of header
                        if (c == CR)
                        {
                            c += read_string(responseBody, 1);
                            // Doesn't end in CRLF
                            if (c != CRLF)
                            {
                                errored = true;
                                error = 'header of chunk in chunked transfer did not end in CRLF';
                                buffer_destroy(actualResponseBody);
                                return _httpClientDestroy();
                            }
                            // chunk-size is empty - something's up!
                            if (chunkSize == '')
                            {
                                errored = true;
                                error = 'empty chunk-size in a chunked transfer';
                                buffer_destroy(actualResponseBody);
                                return _httpClientDestroy();
                            }
                            chunkSize = httpParseHex(chunkSize);
                            // Parsing of size failed - not hex?
                            if (chunkSize == -1)
                            {
                                errored = true;
                                error = 'chunk-size was not hexadecimal in a chunked transfer';
                                buffer_destroy(actualResponseBody);
                                return _httpClientDestroy();
                            }
                            // Is the chunk bigger than the remaining response?
                            if (chunkSize + 2 > buffer_bytes_left(responseBody))
                            {
                                errored = true;
                                error = 'chunk-size was greater than remaining data in a chunked transfer';
                                buffer_destroy(actualResponseBody);
                                return _httpClientDestroy();
                            }
                            // OK, everything's good, read the chunk
                            write_buffer_part(actualResponseBody, responseBody, chunkSize);
                            actualResponseBodySize += chunkSize;
                            // Check for CRLF
                            if (read_string(responseBody, 2) != CRLF)
                            {
                                errored = true;
                                error = 'chunk did not end in CRLF in a chunked transfer';
                                return _httpClientDestroy();
                            }
                        }
                        else
                        {
                            errored = true;
                            error = 'did not find CR after reading chunk header in a chunked transfer, Faucet HTTP bug?';
                            return _httpClientDestroy();
                        }
                        // if the chunk size is zero, then it was the last chunk
                        if (chunkSize == 0
                            // trailer headers will be present
                            and ds_map_exists(responseHeaders, 'trailer'))
                        {
                            // Parse header lines
                            var line;
                            line = 1;
                            while (buffer_bytes_left(responseBody))
                            {
                                var linebuf;
                                linebuf = '';
                                while (buffer_bytes_left(responseBody))
                                {
                                    c = read_string(responseBody, 1);
                                    if (c != CR)
                                        linebuf += c;
                                    else
                                        break;
                                }
                                c += read_string(responseBody, 1);
                                if (c != CRLF)
                                {
                                    errored = true;
                                    error = 'trailer header did not end in CRLF in a chunked transfer';
                                    return _httpClientDestroy();
                                }
                                if (!_httpParseHeader(linebuf, line))
                                    return _httpClientDestroy();
                                line += 1;
                            }
                        }
                    }
                    responseBodySize = actualResponseBodySize;
                    buffer_destroy(responseBody);
                    responseBody = actualResponseBody;
                }
                else
                {
                    errored = true;
                    error = 'Unsupported Transfer-Encoding: "' + ds_map_find_value(responseHaders, 'transfer-encoding') + '"';
                    return _httpClientDestroy();
                }
            }
            else if (responseBodySize != -1)
            {
                if (responseBodyProgress < responseBodySize)
                {
                    errored = true;
                    error = "Unexpected EOF, response body size is less than expected";
                    return _httpClientDestroy();
                }
            }
            // 301 Moved Permanently/302 Found/303 See Other/307 Moved Temporarily
            if (statusCode == 301 or statusCode == 302 or statusCode == 303 or statusCode == 307)
            {
                if (ds_map_exists(responseHeaders, 'location'))
                {
                    var location, resolved;
                    location = ds_map_find_value(responseHeaders, 'location');
                    resolved = httpResolveUrl(requestUrl, location);
                    // Resolving URL didn't fail and it's http://
                    if (resolved != '' and string_copy(resolved, 1, 7) == 'http://')
                    {
                        // Restart request
                        _httpClientDestroy();
                        _httpPrepareRequest(client, resolved, requestHeaders);
                    }
                    else
                    {
                        errored = true;
                        error = "301, 302, 303 or 307 response with invalid or unsupported Location URL ('" + location +  "') - can't redirect";
                        return _httpClientDestroy();
                    }
                    exit;
                }
                else
                {
                    errored = true;
                    error = "301, 302, 303 or 307 response without Location header - can't redirect";
                    return _httpClientDestroy();
                }
            }
            else
                state = 2;
        }
        break;
    // Done.
    case 2:
        break;
    }
}

#define httpRequestStatus
// Gets the current status of an HTTP request
// real httpRequestStatus(real client)

// client - HttpClient object

// Return value is either:
// 0 - In progress
// 1 - Done
// 2 - Errored

// The status being 1 and not 2 does not mean the request was successful
// So check the status code. If it is 2, it simply means there was a different error.

var client;
client = argument0;

if (client.errored)
    return 2;
else if (client.state == 2)
    return 1;
else
    return 0;

#define httpRequestError
// Gets the error message of an HTTP request
// string httpRequestError(real client)

// client - HttpClient object

// Return value is a string describing the error

// This is *not* the "error message" accompanying the status code.
// See httpRequestReasonPhrase for that

var client;
client = argument0;

return client.error;

#define httpRequestStatusCode
// Gets the status code returned by an HTTP request
// real httpRequestStatusCode(real client)

// client - HttpClient object

// Return value is either the status code of the request, or -1 if errored/not done yet

// "The Status-Code element is a 3-digit integer result code of the
// attempt to understand and satisfy the request. These codes are fully
// defined in section 10. The Reason-Phrase is intended to give a short
// textual description of the Status-Code. The Status-Code is intended
// for use by automata and the Reason-Phrase is intended for the human
// user. The client is not required to examine or display the Reason-
// Phrase."

var client;
client = argument0;

return client.statusCode;

#define httpRequestReasonPhrase
// Gets the reason phrase returned by an HTTP request
// string httpRequestSeasonPhrase(real client)

// client - HttpClient object

// Return value is either the reason phrase of the request, or "" if errored/not done yet

// "The Status-Code element is a 3-digit integer result code of the
// attempt to understand and satisfy the request. These codes are fully
// defined in section 10. The Reason-Phrase is intended to give a short
// textual description of the Status-Code. The Status-Code is intended
// for use by automata and the Reason-Phrase is intended for the human
// user. The client is not required to examine or display the Reason-
// Phrase."

var client;
client = argument0;

return client.reasonPhrase;

#define httpRequestResponseBody
// Gets the response body returned by an HTTP request as a buffer
// real httpRequestResponseBody(real client)

// client - HttpClient object

// Return value is a buffer if client hasn't errored and is finished

var client;
client = argument0;

return client.responseBody;

#define httpRequestResponseBodySize
// Gets the size of response body returned by an HTTP request
// real httpRequestResponseBodySize(real client)

// client - HttpClient object

// Return value is the size in bytes, or -1 if we don't know or don't know yet

// Call this each time you use the size - it may have changed in the case of redirect

var client;
client = argument0;

return client.responseBodySize;

#define httpRequestResponseBodyProgress
// Gets the size of response body returned by an HTTP request which is so far downloaded 
// real httpRequestResponseBodyProgress(real client)

// client - HttpClient object

// Return value is the size in bytes, or -1 if we haven't started yet or client has errored

var client;
client = argument0;

return client.responseBodyProgress;

#define httpRequestResponseHeaders
// Gets the response headers returned by an HTTP request as a ds_map
// real httpRequestResponseHeaders(real client)

// client - HttpClient object

// Return value is a ds_map if client hasn't errored and is finished

// All headers will have lowercase keys
// The ds_map is owned by the HttpClient, do not use ds_map_destroy() yourself
// Call when the request has finished - otherwise may be incomplete or missing

var client;
client = argument0;

return client.responseHeaders;

#define httpRequestDestroy
// Cleans up HttpClient
// void httpRequestResponseBody(real client)

// client - HttpClient object

var client;
client = argument0;

with (client)
{
    _httpClientDestroy();
    instance_destroy();
}

