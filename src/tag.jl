# Builds the script tag. Before the tracker tag it can also print the queue stub (queue_stub)
# and the page props script (props), each with the CSP nonce when there is one.

const PROPS_FUNCTION = "privatusPageProps"
const QUEUE_STUB =
    "window.privatus=window.privatus||{q:[]};['track','pageview','props','optOut','optIn','ready']" *
    ".forEach(function(m){window.privatus[m]=window.privatus[m]||function(){window.privatus.q.push(" *
    "[m,Array.prototype.slice.call(arguments)])}})"
const LIST_OPTIONS = (
    :modules => "data-modules", :excluded_paths => "data-exclude", :domains => "data-domains"
)

"""
    with_overrides(config; overrides...) -> Configuration

A copy of `config` with some settings changed. The original is left alone.
"""
function with_overrides(config::Configuration=configuration(); overrides...)
    updated = Configuration((getfield(config, name) for name in SETTINGS)...)
    for (name, value) in overrides
        set_setting!(updated, name, value)
    end
    return updated
end

"""
    render(config = configuration()) -> Bool

Whether the tag prints: there is a site id and the tag is enabled.
"""
render(config::Configuration=configuration()) = site_id(config) !== nothing && isenabled(config)

"""
    tag(config = configuration(); request = nothing, props = nothing, overrides...) -> SafeHTML

The Privatus Analytics script tag, as escaped HTML for the `<head>` of your page:

```julia
PrivatusAnalytics.tag()
# <script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID"></script>
```

Prints nothing without a site id, or when the tag is not enabled (see [`isenabled`](@ref)).

  - Any setting of [`Configuration`](@ref) can be changed for this call, for example
    `tag(modules = ["engage", "auto"], nonce = "abc")`.
  - `props` are merged over the configured props. A `nothing` value removes one.
  - `request` is passed to a `props` or `nonce` function.
"""
function tag(config::Configuration=configuration(); request=nothing, props=nothing, overrides...)
    config = isempty(overrides) ? config : with_overrides(config; overrides...)
    render(config) || return SafeHTML("")

    nonce = resolve_nonce(config.nonce, request)
    props_json = page_props_json(merged_props(config, request, props))
    html = String[]
    config.queue_stub && push!(html, inline_script(QUEUE_STUB, nonce))
    if props_json !== nothing
        push!(html, inline_script("window.$PROPS_FUNCTION=function(){return $props_json}", nonce))
    end
    attrs = script_attributes(config, nonce)
    props_json === nothing || push!(attrs, "data-props" => PROPS_FUNCTION)
    push!(html, script_tag(attrs))
    return SafeHTML(join(html, "\n"))
end

"""
    script_attributes(config = configuration(), nonce = nothing) -> Vector{Pair{String,Any}}

The tracker tag's attributes, in order. `true` means an attribute without a value (`defer`).
"""
function script_attributes(config::Configuration=configuration(), nonce=nothing)
    attrs = Pair{String,Any}[
        "defer" => true, "src" => "$(script_host(config))/js/pa.js", "data-site" => site_id(config)
    ]
    for (name, attribute) in LIST_OPTIONS
        values = list(getfield(config, name))
        # nothing keeps the tracker default. An empty modules list loads none.
        if values !== nothing && (name == :modules || !isempty(values))
            setpair!(attrs, attribute, join(values, ","))
        end
    end
    spa = text(config.spa)
    spa in SPA_MODES && spa != "auto" && setpair!(attrs, "data-spa", spa)
    config.manual && setpair!(attrs, "data-manual", "true")
    for (name, value) in prop_pairs(config.extra_attributes)
        isnil(value) || setpair!(attrs, name, value)
    end
    nonce === nothing || setpair!(attrs, "nonce", nonce)
    return attrs
end

# Configured props for this request with the per call props merged on top.
function merged_props(config::Configuration, request, props)
    merged = keyed(page_props(config, request))
    for (key, value) in keyed(props)
        setpair!(merged, key, value)
    end
    return merged
end

keyed(props) = Pair{String,Any}[normalize_key(key) => value for (key, value) in prop_pairs(props)]

function resolve_nonce(nonce, request)
    if nonce isa Function
        nonce = applicable(nonce, request) ? nonce(request) : nonce()
    end
    value = text(nonce)
    return isempty(value) ? nothing : value
end

function script_tag(attrs)
    parts = (value === true ? name : "$name=\"$(escape_html(value))\"" for (name, value) in attrs)
    return "<script $(join(parts, ' '))></script>"
end

function inline_script(code, nonce)
    opening = nonce === nothing ? "<script>" : "<script nonce=\"$(escape_html(nonce))\">"
    return "$opening$code</script>"
end

# nothing stays nothing. Anything else becomes a clean list of strings.
function list(value)
    isnil(value) && return nothing
    items = value isa Union{AbstractString,Symbol} ? [value] : collect(value)
    values = String[]
    for item in items, part in split(text(item), ',')
        part = strip(part)
        isempty(part) || push!(values, part)
    end
    return values
end
