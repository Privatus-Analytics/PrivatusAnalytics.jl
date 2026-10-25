const DEFAULT_HOST = "https://privatusstats.com"
const MODULES = ("engage", "auto", "vitals", "clicks", "ask")
const SPA_MODES = ("auto", "history", "hash", "off")

"""
    Configuration(; kwargs...)

Settings for the tracking script. Every setting is optional except the site id.

  - `site_id`: the site id (starts with `pa_`). Falls back to `ENV["PRIVATUS_SITE_ID"]`.
  - `script_host`: origin that serves `/js/pa.js`. Falls back to `ENV["PRIVATUS_SCRIPT_HOST"]`,
    then `https://privatusstats.com`.
  - `modules`: tracker modules to load, for example `["engage", "auto"]`. `nothing` keeps the
    tracker default. `String[]` loads none.
  - `excluded_paths`: path globs the tracker never counts, for example `["/admin/*"]`.
  - `domains`: hostnames to count. `nothing` counts every host.
  - `spa`: one of `"auto"`, `"history"`, `"hash"`, `"off"`. `nothing` keeps the tracker default.
  - `manual`: `true` turns off the automatic pageview.
  - `enabled`: `true` or `false` forces the tag on or off. `nothing` turns it on only when
    `ENV["GENIE_ENV"] == "prod"` or `ENV["PRIVATUS_ENV"] == "production"`.
  - `auto_inject`: `true` adds the tag to every HTML page of a Genie app.
  - `extra_attributes`: other `data-*` attributes, for example
    `Dict("data-mask" => "/orders/*->/orders/:id")`.
  - `props`: page props sent with every pageview and event, for example `(plan = "pro",)`.
    A `NamedTuple`, `Dict` or list of pairs, or a function called on each request:
    `req -> (plan = plan_for(req),)`. Never put names, emails, user ids or anything else that
    points to one person here.
  - `queue_stub`: `true` prints the tracker's queue stub first, so `privatus.track` works
    before `pa.js` loads.
  - `nonce`: a Content Security Policy nonce for the script tags. A string, or a function
    called on each request.
"""
Base.@kwdef mutable struct Configuration
    site_id::Union{Nothing,AbstractString} = nothing
    script_host::Union{Nothing,AbstractString} = nothing
    modules::Any = nothing
    excluded_paths::Any = String[]
    domains::Any = nothing
    spa::Any = nothing
    manual::Bool = false
    enabled::Union{Nothing,Bool} = nothing
    auto_inject::Bool = false
    extra_attributes::Any = Pair{String,Any}[]
    props::Any = Pair{String,Any}[]
    queue_stub::Bool = false
    nonce::Any = nothing
end

const SETTINGS = fieldnames(Configuration)
const CONFIG = Ref(Configuration())

"""
    configuration() -> Configuration

The global settings used by [`tag`](@ref) and the integrations.
"""
configuration() = CONFIG[]

"""
    configure!(; kwargs...) -> Configuration

Changes the global settings. Takes the same keywords as [`Configuration`](@ref).

```julia
PrivatusAnalytics.configure!(site_id = "pa_YOURSITEID", modules = ["engage", "auto"])
```
"""
function configure!(; kwargs...)
    config = CONFIG[]
    for (name, value) in kwargs
        set_setting!(config, name, value)
    end
    return config
end

"""
    reset_configuration!() -> Configuration

Puts every setting back to its default. Handy in tests.
"""
reset_configuration!() = (CONFIG[] = Configuration())

function set_setting!(config::Configuration, name::Symbol, value)
    name in SETTINGS || throw(ArgumentError("unknown Privatus Analytics setting `$name`"))
    setfield!(config, name, convert(fieldtype(Configuration, name), value))
    return config
end

"""
    site_id(config = configuration()) -> Union{String,Nothing}

The configured site id, else `ENV["PRIVATUS_SITE_ID"]`, else `nothing`.
"""
function site_id(config::Configuration=configuration())
    value = strip(something(config.site_id, ""))
    isempty(value) && (value = strip(get(ENV, "PRIVATUS_SITE_ID", "")))
    return isempty(value) ? nothing : String(value)
end

"""
    script_host(config = configuration()) -> String

Where `/js/pa.js` is served, without a trailing slash.
"""
function script_host(config::Configuration=configuration())
    value = strip(something(config.script_host, ""))
    isempty(value) && (value = strip(get(ENV, "PRIVATUS_SCRIPT_HOST", "")))
    isempty(value) && (value = DEFAULT_HOST)
    return String(chopsuffix(value, "/"))
end

"""
    isenabled(config = configuration()) -> Bool

Whether the tag should print. `enabled` wins when it is `true` or `false`. Otherwise the tag
is on only when `ENV["GENIE_ENV"] == "prod"` or `ENV["PRIVATUS_ENV"] == "production"`.
"""
function isenabled(config::Configuration=configuration())
    config.enabled === nothing || return config.enabled
    return production_environment()
end

function production_environment()
    return get(ENV, "GENIE_ENV", "") == "prod" || get(ENV, "PRIVATUS_ENV", "") == "production"
end

"""
    page_props(config = configuration(), request = nothing)

The configured props for one request. Calls `props` when it is a function: with the request
when it takes one argument, or with no arguments.
"""
function page_props(config::Configuration=configuration(), request=nothing)
    value = config.props
    if value isa Function
        value = applicable(value, request) ? value(request) : value()
    end
    return value
end
