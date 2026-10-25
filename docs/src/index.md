# PrivatusAnalytics.jl

Adds the cookieless [Privatus Analytics](https://privatusanalytics.com) tracking script to
Julia web apps and sites: plain Julia, Genie, HTTP.jl, Franklin and Documenter.

The package only prints HTML: the browser script tag and a few data attributes. It never
sends events from your server and sets no cookies.

```julia
using PrivatusAnalytics
PrivatusAnalytics.configure!(site_id = "pa_YOURSITEID")

PrivatusAnalytics.tag()
# <script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID"></script>

event_attrs("Report exported"; format = "csv")
# data-privatus-event="Report exported" data-privatus-prop-format="csv"

click_attr("pricing.cta")
# data-privatus-click="pricing.cta"
```

The tag prints only in production: when `ENV["GENIE_ENV"] == "prod"`,
`ENV["PRIVATUS_ENV"] == "production"`, or when you set `enabled = true`.

The README on [GitHub](https://github.com/Privatus-Analytics/PrivatusAnalytics.jl) has the
full guide. The tracker itself is described in the
[Privatus Analytics docs](https://privatusanalytics.com/docs) and the
[script attributes reference](https://privatusanalytics.com/docs/tracker/attributes).
