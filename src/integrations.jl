# Functions whose methods live in the package extensions. They load by themselves when you
# load the other package (Julia 1.9 or later).

"""
    middleware(handler; config = nothing, nonce = nothing)

HTTP.jl middleware that adds the tag just before `</head>` in HTML responses. Needs HTTP.jl:
run `using HTTP` first.

```julia
using HTTP, PrivatusAnalytics
HTTP.serve(PrivatusAnalytics.middleware(router), "0.0.0.0", 8080)
```

It skips responses that are not status 200 `text/html`, compressed responses (with a
`Content-Encoding` header), Ajax requests, pages without `</head>` and pages that already
have the tag. It sets `Content-Length` to the new size. `config` defaults to the global
settings at request time. `nonce` is a string, or a function that gets the request.
"""
function middleware end

"""
    inject_response(request, response; config = configuration(), nonce = nothing)

Adds the tag to one `HTTP.Response` when [`injectable`](@ref) allows it. Used by
[`middleware`](@ref) and by the Genie integration. Needs HTTP.jl.
"""
function inject_response end

"""
    privatus_analytics_tag(; kwargs...)

The script tag for a Genie view, as a Genie `ParsedHTMLString`. Needs Genie: run
`using Genie` first. It passes the current Genie request to a `props` or `nonce` function.
Takes the same keywords as [`tag`](@ref).

```html
<head>
  <title>My app</title>
  \$(privatus_analytics_tag())
</head>
```
"""
function privatus_analytics_tag end

"""
    privatus_event_data(name, props = nothing; more_props...) -> Vector{Pair{Symbol,String}}

The custom event attributes for Genie's HTML functions (`Html.button` and friends), with every
value already escaped, because Genie prints attribute values as they are. Needs Genie.

```html
<% Html.button("Export"; class = "btn", privatus_event_data("Report exported"; format = "csv")...) %>
```
"""
function privatus_event_data end

"""
    privatus_click_data(name) -> Vector{Pair{Symbol,String}}

The click map name for Genie's HTML functions, escaped. Empty when the name is not valid.
Needs Genie.

```html
<% Html.a("See plans"; href = "/pricing", privatus_click_data("pricing.cta")...) %>
```
"""
function privatus_click_data end

const EXTENSION_HINTS = Dict(
    :middleware => (:PrivatusAnalyticsHTTPExt, "HTTP.jl. Run `using HTTP` first"),
    :inject_response => (:PrivatusAnalyticsHTTPExt, "HTTP.jl. Run `using HTTP` first"),
    :privatus_analytics_tag => (:PrivatusAnalyticsGenieExt, "Genie. Run `using Genie` first"),
    :privatus_event_data => (:PrivatusAnalyticsGenieExt, "Genie. Run `using Genie` first"),
    :privatus_click_data => (:PrivatusAnalyticsGenieExt, "Genie. Run `using Genie` first"),
)

function extension_hint(io, exc, _argtypes, _kwargs)
    exc.f isa Function || return nothing
    hint = get(EXTENSION_HINTS, nameof(exc.f), nothing)
    hint === nothing && return nothing
    parentmodule(exc.f) === PrivatusAnalytics || return nothing
    Base.get_extension(@__MODULE__, first(hint)) === nothing || return nothing
    print(io, "\n`PrivatusAnalytics.$(nameof(exc.f))` needs $(last(hint)).")
    return nothing
end

function __init__()
    Base.Experimental.register_error_hint(extension_hint, MethodError)
    return nothing
end
