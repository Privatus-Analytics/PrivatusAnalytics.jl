const HEAD_CLOSE = r"</head>"i
const MARKER = "/js/pa.js"

"""
    inject(html, config = configuration(); request = nothing, overrides...) -> String

Puts the tag just before `</head>`. Leaves the page alone when it already has the tag, has no
`</head>`, or when the tag is off. Takes the same keywords as [`tag`](@ref).

Handy for static pages too, for example after a Franklin or Documenter build.
"""
function inject(
    html::AbstractString, config::Configuration=configuration(); request=nothing, overrides...
)
    html = String(html)
    (occursin(MARKER, html) || !occursin(HEAD_CLOSE, html)) && return html
    config = isempty(overrides) ? config : with_overrides(config; overrides...)
    # When the tag is off, add nothing (not even the queue stub).
    render(config) || return html
    snippet = tag(config; request)
    isempty(snippet) && return html
    return replace(html, HEAD_CLOSE => string(snippet, "\n</head>"); count=1)
end

"""
    injectable(status, content_type, content_encoding, requested_with) -> Bool

Whether a response may get the tag: status 200, `text/html`, no `Content-Encoding`, and not
an Ajax request (`X-Requested-With: XMLHttpRequest`). Missing headers are empty strings.
"""
function injectable(status, content_type, content_encoding, requested_with)
    status == 200 || return false
    startswith(lowercase(text(content_type)), "text/html") || return false
    isempty(strip(text(content_encoding))) || return false
    return lowercase(strip(text(requested_with))) != "xmlhttprequest"
end
