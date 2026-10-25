module PrivatusAnalyticsHTTPExt

# HTTP.jl middleware that adds the tag to HTML responses. Works with HTTP.jl 1.x and 2.x.

using HTTP: HTTP
using PrivatusAnalytics: PrivatusAnalytics

const PA = PrivatusAnalytics

function header(message, name::AbstractString)
    for (key, value) in message.headers
        lowercase(key) == lowercase(name) && return String(value)
    end
    return ""
end

function body_text(body)
    body isa AbstractString && return String(body)
    # String(vector) takes the bytes away from the vector, so copy them first.
    body isa AbstractVector{UInt8} && return String(copy(body))
    return nothing # a streamed body: leave it alone
end

function PA.inject_response(
    request::HTTP.Request, response::HTTP.Response; config=PA.configuration(), nonce=nothing
)
    PA.injectable(
        response.status,
        header(response, "Content-Type"),
        header(response, "Content-Encoding"),
        header(request, "X-Requested-With"),
    ) || return response
    PA.render(config) || return response
    html = body_text(response.body)
    html === nothing && return response

    overrides = nonce === nothing ? (;) : (; nonce=nonce)
    injected = PA.inject(html, config; request=request, overrides...)
    ncodeunits(injected) == ncodeunits(html) && return response

    headers = Pair{String,String}[
        String(key) => String(value) for
        (key, value) in response.headers if lowercase(key) != "content-length"
    ]
    push!(headers, "Content-Length" => string(ncodeunits(injected)))
    return HTTP.Response(response.status, headers, injected; request=response.request)
end

function PA.middleware(handler; config=nothing, nonce=nothing)
    return function privatus_analytics_middleware(request::HTTP.Request)
        response = handler(request)
        response isa HTTP.Response || return response
        settings = config === nothing ? PA.configuration() : config
        return PA.inject_response(request, response; config=settings, nonce=nonce)
    end
end

end
