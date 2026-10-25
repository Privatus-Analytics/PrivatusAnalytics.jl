module PrivatusAnalyticsGenieExt

# Genie support: a view helper that returns Genie's ParsedHTMLString, and a response hook
# that adds the tag to every HTML page when `auto_inject = true`.

using Genie: Genie
using PrivatusAnalytics: PrivatusAnalytics

const PA = PrivatusAnalytics

# The HTTP.Request Genie is handling right now, or nothing outside a request.
function current_request()
    try
        return Genie.Requests.request()
    catch
        return nothing
    end
end

function PA.privatus_analytics_tag(; request=current_request(), kwargs...)
    return Genie.Renderer.Html.ParsedHTMLString(String(PA.tag(; request=request, kwargs...)))
end

# Genie prints attribute values as they are, so escape them here.
function genie_attrs(attrs)
    return Pair{Symbol,String}[Symbol(name) => PA.escape_html(value) for (name, value) in attrs]
end

function PA.privatus_event_data(name, props=nothing; more_props...)
    return genie_attrs(PA.event_data(name, props; more_props...))
end

PA.privatus_click_data(name) = genie_attrs(PA.click_data(name))

# Runs after each Genie route. Off unless `auto_inject = true`.
function inject_hook(request, response, params)
    PA.configuration().auto_inject || return request, response, params
    return request, PA.inject_response(request, response), params
end

function __init__()
    hooks = Genie.Router.pre_response_hooks
    inject_hook in hooks || push!(hooks, inject_hook)
    return nothing
end

end
