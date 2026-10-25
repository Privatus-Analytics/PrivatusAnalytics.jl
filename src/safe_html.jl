"""
    SafeHTML(html)

A string of HTML that is already escaped and safe to print as is.

It works anywhere a `String` works (string interpolation, `print`, `*`, HTTP bodies), and it
shows as real HTML in tools that understand the `text/html` MIME type, like Pluto, Jupyter and
Documenter `@example` blocks.
"""
struct SafeHTML <: AbstractString
    html::String
end

SafeHTML(html::SafeHTML) = html

Base.String(s::SafeHTML) = s.html
Base.string(s::SafeHTML) = s.html
Base.ncodeunits(s::SafeHTML) = ncodeunits(s.html)
Base.codeunit(s::SafeHTML) = codeunit(s.html)
Base.codeunit(s::SafeHTML, i::Integer) = codeunit(s.html, i)
Base.isvalid(s::SafeHTML, i::Integer) = isvalid(s.html, i)
Base.iterate(s::SafeHTML) = iterate(s.html)
Base.iterate(s::SafeHTML, i::Integer) = iterate(s.html, i)
Base.print(io::IO, s::SafeHTML) = print(io, s.html)
Base.show(io::IO, ::MIME"text/html", s::SafeHTML) = print(io, s.html)

const HTML_ESCAPES = (
    '&' => "&amp;", '<' => "&lt;", '>' => "&gt;", '"' => "&quot;", '\'' => "&#39;"
)

"""
    escape_html(value) -> String

Escapes `& < > " '` so a value is safe inside an HTML attribute or element.
"""
escape_html(value) = replace(string(value), HTML_ESCAPES...)
