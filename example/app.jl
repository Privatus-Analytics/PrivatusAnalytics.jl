# The example app for the Privatus Analytics conformance tests
# (https://github.com/Privatus-Analytics/conformance), made with HTTP.jl. The suite builds it
# with example/Dockerfile and checks every route in a real browser; its CONTRACT.md says what
# each route must print. The site id and script host come from PRIVATUS_SITE_ID and
# PRIVATUS_SCRIPT_HOST.
#
# Run it yourself: julia --project=example -e 'using Pkg; Pkg.instantiate()'
#                  julia --project=example example/app.jl
using HTTP
using PrivatusAnalytics

const PA = PrivatusAnalytics
const NONCE = "testnonce"
const NASTY = "</script><script>window.__pwned=1</script>  &<>\"'"
const PAGE_PROPS = (plan="pro", role="admin", beta=true, seats=3)

const AUTO_PAGE = """
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Auto inject</title>
</head>
<body><h1>Auto inject</h1><p>No tag in the template. The middleware adds it.</p></body>
</html>
"""

function layout(title, body; props=PAGE_PROPS)
    return """
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <title>$title</title>
    $(PA.tag(; props=props, queue_stub=true, nonce=NONCE))
    </head>
    <body>
    $body
    </body>
    </html>
    """
end

function off_page(queue_stub)
    html = PA.tag(; enabled=false, props=PAGE_PROPS, queue_stub=queue_stub, nonce=NONCE)
    return """
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <title>Off</title>
    <meta name="privatus-off-start">$(html)<meta name="privatus-off-end">
    </head>
    <body><h1>Off</h1></body>
    </html>
    """
end

page(html) = HTTP.Response(200, ["Content-Type" => "text/html; charset=utf-8"], html)

const EVENT_BODY = """
<h1>Events</h1>
<button type="button" $(event_attrs("Report exported", (format="csv", source="toolbar")))>Export report</button>
<p><a href="#pricing" $(click_attr("pricing.cta"))>Pricing</a></p>
<form action="/event" method="get" $(event_attrs("Signup form"))>
  <button type="submit">Sign up</button>
</form>"""

const NASTY_BODY = """
<h1>Nasty values</h1>
<button type="button" $(event_attrs("Nasty value", (nasty=NASTY,)))>Nasty</button>"""

function main()
    # Forced on, so the tag prints whatever the environment. The site id and script host come
    # from the environment.
    PA.configure!(; enabled=true)
    script_host = PA.script_host()

    router = HTTP.Router()
    HTTP.register!(router, "GET", "/", _ -> page(layout("Home", "<h1>Home</h1>")))
    HTTP.register!(router, "GET", "/event", _ -> page(layout("Events", EVENT_BODY)))
    HTTP.register!(
        router,
        "GET",
        "/nasty",
        _ -> page(layout("Nasty", NASTY_BODY; props=(; PAGE_PROPS..., nasty=NASTY))),
    )
    # Off with the queue stub on prints only the stub, so privatus.track calls still work.
    # Off without it prints nothing.
    HTTP.register!(router, "GET", "/off", _ -> page(off_page(true)))
    HTTP.register!(router, "GET", "/off-plain", _ -> page(off_page(false)))
    # Auto inject on this route only, so the other routes test the tag alone.
    HTTP.register!(router, "GET", "/auto", PA.middleware(_ -> page(AUTO_PAGE); nonce=NONCE))

    csp = "script-src 'nonce-$NONCE' $script_host"
    function app(request)
        response = router(request)
        HTTP.setheader(response, "Content-Security-Policy" => csp)
        return response
    end

    port = parse(Int, get(ENV, "PORT", "8080"))
    println("Example app on port $port")
    return HTTP.serve(app, "0.0.0.0", port)
end

main()
