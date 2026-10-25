"""
    PrivatusAnalytics

Adds the cookieless Privatus Analytics tracking script to Julia web apps and sites.

The package only prints HTML: the browser script tag and a few data attributes. It never
sends events from the server, sets no cookies and reads nothing about your visitors.

Start with [`configure!`](@ref) and [`tag`](@ref). See the README for Genie, HTTP.jl,
Franklin and Documenter.
"""
module PrivatusAnalytics

export event_attrs, event_data, click_attr, click_data
export privatus_analytics_tag, privatus_event_data, privatus_click_data

include("safe_html.jl")
include("configuration.jl")
include("attributes.jl")
include("page_props.jl")
include("tag.jl")
include("inject.jl")
include("integrations.jl")

end
