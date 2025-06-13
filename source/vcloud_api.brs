' VCloud API helper functions
'
' Generates signed URL for GET requests using vCloud API authentication

function TrimSlashes(url as String) as String
    if Left(url,1) = "/" then url = Mid(url,2)
    if Right(url,1) = "/" then url = Left(url, Len(url)-1)
    return url
end function

function UriEncode(value as String) as String
    return EncodeUriComponent(value)
end function

function SortKeysAA(aa as Object) as Object
    keys = aa.keys()
    keys.sort()
    return keys
end function

function GenerateSignature(method as String, endpoint as String, params as Object, secret as String) as String
    endpoint = TrimSlashes(endpoint)
    str = secret + UCase(method) + endpoint
    sorted = SortKeysAA(params)
    for each key in sorted
        val = params[key]
        if Type(val) = "roArray" then
            val = val.join(",")
        end if
        if val = invalid then
            val = ""
        else
            val = val.ToStr()
        end if
        str = str + key + "=" + val
    end for
    digest = CreateObject("roEVPDigest")
    digest.Setup("sha256")
    digest.Update(str)
    ba = digest.Final()
    encoded = ba.ToBase64String()
    if Len(encoded) > 43 then
        encoded = Left(encoded,43)
    end if
    while Right(encoded,1) = "="
        encoded = Left(encoded, Len(encoded)-1)
    end while
    return UriEncode(encoded)
end function

function BuildSignedUrl(domain as String, endpoint as String, params as Object, apiKey as String, secret as String) as String
    params.api_key = apiKey
    sig = GenerateSignature("GET", endpoint, params, secret)
    params.signature = sig
    keys = SortKeysAA(params)
    query = ""
    first = true
    for each k in keys
        v = params[k]
        if Type(v) = "roArray" then
            v = v.join(",")
        end if
        part = k + "=" + UriEncode(v)
        if first then
            query = part
            first = false
        else
            query = query + "&" + part
        end if
    end for
    return "https://" + domain + "/" + TrimSlashes(endpoint) + "?" + query
end function
