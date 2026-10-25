# Builds the data attributes the tracker reads for custom events and click maps.

const MAX_NAME = 120
const MAX_KEY = 64
const MAX_PROPS = 30
const MAX_VALUE = 500
const CLICK_NAME = r"\A[A-Za-z0-9_.:-]{1,100}\z"

const Attrs = Vector{Pair{String,String}}

# `nothing` and `missing` count as "no value", like nil in the Ruby gem.
isnil(value) = value === nothing || value === missing

text(value) = isnil(value) ? "" : scrub(string(value))

# Swaps bytes that are not valid UTF-8 for U+FFFD, so escaping and cutting are safe.
scrub(s::AbstractString) = isvalid(s) ? String(s) : map(c -> isvalid(c) ? c : '�', String(s))

"""
    normalize_key(key) -> String

Lowercases a prop key, swaps anything outside `a-z 0-9 _` for `_` and cuts it to 64
characters. `"Report Type"` becomes `"report_type"`.
"""
normalize_key(key) = first(replace(lowercase(text(key)), r"[^a-z0-9_]" => "_"), MAX_KEY)

# Props as an ordered list of `String => value` pairs. A NamedTuple, keyword arguments or a
# list of pairs keep their order. A plain `Dict` has no order, so it is sorted by key.
function prop_pairs(props)
    isnil(props) && return Pair{String,Any}[]
    items = props isa Union{AbstractDict,NamedTuple,Base.Iterators.Pairs} ? pairs(props) : props
    list = Pair{String,Any}[text(key) => value for (key, value) in items]
    props isa Dict && sort!(list; by=first)
    return list
end

# Sets `key => value` in an ordered pair list, keeping the first position of a key.
function setpair!(list::Vector{<:Pair}, key, value)
    index = findfirst(pair -> first(pair) == key, list)
    index === nothing ? push!(list, key => value) : (list[index] = key => value)
    return list
end

"""
    normalize(props) -> Vector{Pair{String,Any}}

Cleans every key with [`normalize_key`](@ref), drops `nothing` values and empty keys, and
keeps the first 30 props.
"""
function normalize(props)
    clean = Pair{String,Any}[]
    for (key, value) in prop_pairs(props)
        key = normalize_key(key)
        isempty(key) || isnil(value) || setpair!(clean, key, value)
    end
    return first(clean, MAX_PROPS)
end

function string_value(value)
    joined = if value isa Union{AbstractVector,Tuple}
        join((text(item) for item in value if !isnil(item)), ",")
    else
        text(value)
    end
    return first(joined, MAX_VALUE)
end

merge_props(props, kwargs) = isempty(kwargs) ? props : vcat(prop_pairs(props), prop_pairs(kwargs))

"""
    event_data(name, props = nothing; more_props...) -> Vector{Pair{String,String}}

The custom event attributes as `attribute name => value` pairs, with values not yet escaped.
Use it with HTML builders that escape values for you. Returns an empty list for an empty name.

```julia
event_data("Report exported"; format = "csv")
# ["data-privatus-event" => "Report exported", "data-privatus-prop-format" => "csv"]
```
"""
function event_data(name, props=nothing; more_props...)
    name = strip(first(strip(text(name)), MAX_NAME))
    isempty(name) && return Attrs()
    attrs = Attrs(["data-privatus-event" => String(name)])
    for (key, value) in normalize(merge_props(props, more_props))
        push!(attrs, "data-privatus-prop-$key" => string_value(value))
    end
    return attrs
end

"""
    event_attrs(name, props = nothing; more_props...) -> SafeHTML

Data attributes for a custom event, as escaped HTML to put inside a tag:

```julia
"<button \$(event_attrs("Report exported"; format = "csv"))>Export</button>"
```

On a `<form>` the event is sent when the form is submitted. Prints nothing for an empty name.
The attributes print even when the tag is off, so your pages look the same everywhere.
"""
function event_attrs(name, props=nothing; more_props...)
    return SafeHTML(to_html(event_data(name, props; more_props...)))
end

"""
    isvalid_click(name) -> Bool

Whether a click map name is valid: letters, digits, `_ . : -` and at most 100 characters.
"""
isvalid_click(name) = !isnil(name) && occursin(CLICK_NAME, string(name))

"""
    click_data(name) -> Vector{Pair{String,String}}

The click map name as `"data-privatus-click" => name`, or an empty list when the name is not
valid. Outside production it logs a warning for a name that is not valid.
"""
function click_data(name)
    isvalid_click(name) && return Attrs(["data-privatus-click" => string(name)])
    production_environment() ||
        @warn "[privatus-analytics] click map name $(repr(name)) is not valid. Use letters, " *
            "digits and _ . : - only, at most 100 characters. Nothing was printed."
    return Attrs()
end

"""
    click_attr(name) -> SafeHTML

The click map name attribute as escaped HTML: `data-privatus-click="pricing.cta"`.
Prints nothing when the name is not valid.
"""
click_attr(name) = SafeHTML(to_html(click_data(name)))

"""
    to_html(attrs) -> String

Turns `name => value` pairs into HTML attributes, with every value escaped.
"""
to_html(attrs) = join(("$name=\"$(escape_html(value))\"" for (name, value) in attrs), " ")
