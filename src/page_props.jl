# Turns page props (plan, role and so on) into JSON that is safe inside a <script>.
# Keys follow the same rules as event props. Numbers, booleans and lists keep their JSON types.

const MAX_ITEMS = 30

"""
    page_props_json(props) -> Union{String,Nothing}

A JSON object string, or `nothing` when there are no props to send. `<`, `>`, `&`, U+2028
and U+2029 are written as `\\u003c` and so on, so the JSON is safe inside a `<script>`.
"""
function page_props_json(props)
    clean = Pair{String,Any}[]
    for (key, value) in normalize(props)
        value = json_value(value)
        value === nothing || push!(clean, key => value)
    end
    isempty(clean) && return nothing
    io = IOBuffer()
    print(io, '{')
    for (i, (key, value)) in enumerate(clean)
        i > 1 && print(io, ',')
        write_json(io, key)
        print(io, ':')
        write_json(io, value)
    end
    print(io, '}')
    return String(take!(io))
end

function json_value(value)
    if value isa Union{AbstractVector,Tuple}
        items = first([item for item in value if !isnil(item)], MAX_ITEMS)
        return Any[scalar for scalar in map(json_scalar, items) if scalar !== nothing]
    end
    return json_scalar(value)
end

json_scalar(value) = isnil(value) ? nothing : first(text(value), MAX_VALUE)
json_scalar(value::Bool) = value
json_scalar(value::Integer) = value
json_scalar(value::AbstractFloat) = isfinite(value) ? Float64(value) : nothing

write_json(io::IO, value::Bool) = print(io, value ? "true" : "false")
write_json(io::IO, value::Integer) = print(io, string(value))
write_json(io::IO, value::Float64) = print(io, repr(value))
function write_json(io::IO, values::AbstractVector)
    print(io, '[')
    for (i, value) in enumerate(values)
        i > 1 && print(io, ',')
        write_json(io, value)
    end
    return print(io, ']')
end

function write_json(io::IO, value::AbstractString)
    print(io, '"')
    for char in value
        if char == '"'
            print(io, "\\\"")
        elseif char == '\\'
            print(io, "\\\\")
        elseif char == '\n'
            print(io, "\\n")
        elseif char == '\r'
            print(io, "\\r")
        elseif char == '\t'
            print(io, "\\t")
        elseif char == '\b'
            print(io, "\\b")
        elseif char == '\f'
            print(io, "\\f")
        elseif char < ' ' || char in ('<', '>', '&', ' ', ' ')
            print(io, "\\u", string(UInt32(char); base=16, pad=4))
        else
            print(io, char)
        end
    end
    return print(io, '"')
end
