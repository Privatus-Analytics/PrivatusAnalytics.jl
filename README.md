# Privatus Analytics for Julia

**Simple, private website analytics for your Julia web app or site.** No
cookies, honest numbers, and a dashboard you understand in seconds.

## Why Privatus Analytics

**Google Analytics is slow, confusing and hungry for data.** It sends what your
visitors do to Google. In many countries it means showing a cookie pop-up (the
box that asks visitors to accept cookies), and many people click "reject", so
you never see them. Bots pad the numbers that are left.

**Privatus Analytics fixes that.** It counts visits to your Julia app or site
without cookies and never stores IP addresses. Bots are filtered out before they
are counted. Your data is never sold or shared.

What you get:

- **A dashboard you understand in seconds.** Visitors, top pages and where
  people came from, all on one screen.
- **No cookie pop-up needed for our analytics.** We set no cookies and store no
  personal data. Laws differ by country, so check your own legal advice.
- **Honest numbers.** Known bots and fake traffic are left out on every plan.
- **A fast site.** The tracking script is about 3 KB, tiny next to most tracking
  tags.
- **Data you own.** We never sell it or show you ads, and you can pull it out
  any time through the API.

**Start free.** The Free plan has 10,000 events a month and 3 sites, with no
card. Every new account also gets 14 days of Pro free, with no card. [Create
your account](https://privatusanalytics.com).

## What this package does

- Adds the Privatus Analytics tracking script in plain Julia, in
  [Genie](https://genieframework.com) apps, with
  [HTTP.jl](https://github.com/JuliaWeb/HTTP.jl) servers, and in sites built
  with Franklin.jl or Documenter.jl.
- Only prints the browser script. It never sends events from your server and
  sets no cookies.

You need a Privatus Analytics account to see reports, and there is a free plan.
Sign up at https://privatusanalytics.com.

## Requirements

* Julia 1.9 or later.
* No other packages. The Genie and HTTP.jl parts switch on by themselves when
  you load Genie 5 or 6, or HTTP.jl 1 or 2 (Julia calls these "package
  extensions").
* A Privatus Analytics site id (it starts with `pa_`). You find it under
  Site settings, Tracking.

## Install

```julia
using Pkg
Pkg.add("PrivatusAnalytics")
```

or type `] add PrivatusAnalytics` in the Julia REPL. For the full setup guide
and every tracker option, see the [Privatus Analytics
docs](https://privatusanalytics.com/docs).

Set your site id with an environment variable:

```sh
PRIVATUS_SITE_ID=pa_YOURSITEID
```

or in your code, once at startup:

```julia
using PrivatusAnalytics
PrivatusAnalytics.configure!(site_id = "pa_YOURSITEID")
```

## Add the tag

`PrivatusAnalytics.tag()` returns the tag. Put it in the `<head>` of your
pages:

```julia
page = """
<head>
  <title>My app</title>
  $(PrivatusAnalytics.tag())
</head>
"""
```

In production it prints:

```html
<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID"></script>
```

The tag prints nothing when there is no site id, and nothing outside
production (see below). With `queue_stub = true` it then prints only the queue
stub (see [Track from your own JavaScript](#track-from-your-own-javascript)).
The result is a `SafeHTML` string: it works anywhere a
string works, and tools like Pluto, Jupyter and Documenter show it as HTML.

### Genie

Load the package next to Genie, for example in
`config/initializers/privatus.jl`:

```julia
using PrivatusAnalytics
PrivatusAnalytics.configure!(site_id = "pa_YOURSITEID")
```

Then put the helper in the `<head>` of your layout, for example
`app/layouts/app.jl.html`:

```html
<head>
  <title>My app</title>
  <% privatus_analytics_tag() %>
</head>
```

Use `<% ... %>` here, not `$(...)`. Genie reads the layout as HTML, and text
written with `$(...)` inside `<head>` gets moved into the `<body>`.

`privatus_analytics_tag` returns Genie's own HTML string type, and it passes
the current Genie request to your `props` function (see Page props).

### HTTP.jl

Call `tag` in your handler. Pass the request if your props need it:

```julia
using HTTP, PrivatusAnalytics

function home(req)
    html = "<html><head><title>Home</title>$(PrivatusAnalytics.tag(request = req))</head><body>Hi</body></html>"
    return HTTP.Response(200, ["Content-Type" => "text/html; charset=utf-8"], html)
end
```

### Or let the package add it

If you would rather not touch your layouts, let the package add the tag for
you. In a Genie app, switch on `auto_inject`:

```julia
PrivatusAnalytics.configure!(site_id = "pa_YOURSITEID", auto_inject = true)
```

With HTTP.jl, wrap your handler or router in the middleware:

```julia
using HTTP, PrivatusAnalytics

router = HTTP.Router()
HTTP.register!(router, "GET", "/", home)
HTTP.serve(PrivatusAnalytics.middleware(router), "0.0.0.0", 8080)
```

Both add the tag just before `</head>` in uncompressed `text/html` responses
with status 200, and set `Content-Length` to the new size. They skip Ajax
requests (with the `X-Requested-With: XMLHttpRequest` header), pages without a
`<head>`, and pages that already have the tag. Responses that have a
`Content-Encoding` header (compressed responses) are left alone, so compress
after the middleware, or use the helper instead. The middleware works with
request handlers, not stream handlers.

The middleware reads the settings on each request. You can also give it its
own settings and a Content Security Policy nonce (a string, or a function that
gets the request):

```julia
PrivatusAnalytics.middleware(router; nonce = req -> nonce_for(req))
```

## Static sites: Franklin and Documenter

For a static site, the tag is written when you build the site, so set
`PRIVATUS_ENV=production` in the build that you publish (for example in your
GitHub Actions deploy job). Local builds then stay out of your reports.

### Franklin.jl

Add an HTML function to `utils.jl`:

```julia
using PrivatusAnalytics
PrivatusAnalytics.configure!(site_id = "pa_YOURSITEID", props = (section = "blog",))

hfun_privatus() = String(PrivatusAnalytics.tag())
hfun_privatus_click(params) = String(click_attr(params[1]))
```

Then call it in the head of `_layout/head.html`:

```html
<head>
  <title>{{fill title}}</title>
  {{privatus}}
</head>
```

and name the parts you care about for click maps in your layout files, like
`<a href="/pricing/" {{privatus_click nav.pricing}}>Pricing</a>`.

### Documenter.jl

Documenter 1.13 and later can put raw HTML in the head with
`RawHTMLHeadContent`. In `docs/make.jl`:

```julia
using Documenter, PrivatusAnalytics

privatus = String(PrivatusAnalytics.tag(site_id = "pa_YOURSITEID"))

makedocs(
    sitename = "MyPackage.jl",
    format = Documenter.HTML(assets = isempty(privatus) ? [] : [RawHTMLHeadContent(privatus)]),
)
```

If your Documenter version has no `RawHTMLHeadContent`, add the tracker as a
script asset instead. This way has no page props:

```julia
PrivatusAnalytics.configure!(site_id = "pa_YOURSITEID")
tracker = asset("https://privatusstats.com/js/pa.js"; class = :js,
                attributes = Dict(:defer => "", Symbol("data-site") => "pa_YOURSITEID"))
assets = PrivatusAnalytics.render() ? [tracker] : []
```

`PrivatusAnalytics.render()` is `true` when there is a site id and the tag is
on.

Static pages from any other tool can go through `PrivatusAnalytics.inject(html)`,
which adds the tag before `</head>`.

## Configuration

Every setting is optional except the site id.

```julia
PrivatusAnalytics.configure!(
    site_id = "pa_YOURSITEID",                 # or ENV["PRIVATUS_SITE_ID"]
    script_host = "https://privatusstats.com", # or ENV["PRIVATUS_SCRIPT_HOST"]
    modules = ["engage", "auto", "vitals", "clicks", "ask"],
    excluded_paths = ["/admin/*", "/preview/*"],
    domains = ["example.com", "www.example.com"],
    spa = "auto",          # auto, history, hash or off
    manual = false,        # true turns off the automatic pageview
    enabled = nothing,     # true or false forces the tag on or off
    auto_inject = false,   # Genie only
    extra_attributes = Dict("data-mask" => "/orders/*->/orders/:id"),
    props = req -> (plan = plan_for(req),),
    queue_stub = false,
    nonce = nothing,
)
```

| Setting | Default | What it does |
|---|---|---|
| `site_id` | `ENV["PRIVATUS_SITE_ID"]` | The `data-site` attribute. Nothing prints without it |
| `script_host` | `https://privatusstats.com` | Where `/js/pa.js` is served. Change it only if you host your own copy |
| `modules` | tracker default (`engage`) | The `data-modules` attribute. Setting it replaces the default, so keep `engage` for time on page and scroll depth. `String[]` loads none |
| `excluded_paths` | none | The `data-exclude` attribute. Path globs the tracker never counts |
| `domains` | all hosts | The `data-domains` attribute. Count only these hostnames |
| `spa` | `auto` | The `data-spa` attribute (for single-page apps) |
| `manual` | `false` | The `data-manual` attribute |
| `enabled` | `nothing` | `true` or `false` forces the tag on or off. `nothing` means on only when `ENV["GENIE_ENV"] == "prod"` or `ENV["PRIVATUS_ENV"] == "production"` |
| `auto_inject` | `false` | Adds the tag to every HTML page of a Genie app. With HTTP.jl, use `middleware` |
| `extra_attributes` | none | Any other `data-*` attribute |
| `props` | none | Page props sent with every pageview and event. A NamedTuple, a Dict, or a function that gets the request. See below |
| `queue_stub` | `false` | Prints a small script first, so `privatus.track` calls made before the tracker loads are kept and sent later |
| `nonce` | `nothing` | A Content Security Policy (CSP) nonce for the script tags. A string, or a function that gets the request |

Each tracker attribute is explained in the [script attributes
reference](https://privatusanalytics.com/docs/tracker/attributes), and the
modules in [Modules](https://privatusanalytics.com/docs/tracker/modules).

You can also change any setting for one call:

```julia
PrivatusAnalytics.tag(modules = ["engage", "auto"], excluded_paths = ["/preview/*"])
```

### Development and test

Requests are only counted in production by default, so your own clicking
around never reaches your reports. Genie sets `GENIE_ENV=prod` in production.
Elsewhere, set `PRIVATUS_ENV=production`. To see the tag while you build, set
`enabled = true`. The tracker also ignores `localhost` unless you pass
`data-allow-local` or `data-debug` (see [Debug
mode](https://privatusanalytics.com/docs/tracker/debug)):

```julia
PrivatusAnalytics.configure!(enabled = true, extra_attributes = Dict("data-debug" => "true"))
```

### Leaving people out

Use `data-exclude` through `excluded_paths` for admin areas. To leave out
signed-in staff, print the tag only for other people:

```html
<% is_staff() ? "" : privatus_analytics_tag() %>
```

## Product analytics: see which features people use

Privatus Analytics can show which buttons, forms and features people really use. You
add a few attributes to your HTML. The tracker reads them in the browser and
sends the events. Your server still sends nothing.

### Name events well

Use a short "Noun verb" name, like `Report exported` or `Invite sent`. Put the
details in props, not in the name. So write `Report exported` with
`format = "csv"`, not `Report exported as CSV`. Then all exports add up in one
place, and you can split them by format.

### Events on buttons, links and forms

`event_attrs` prints the attributes inside a tag you write yourself:

```julia
"<button $(event_attrs("Report exported"; format = "csv", source = "toolbar"))>Export</button>"
```

It prints:

```html
<button data-privatus-event="Report exported" data-privatus-prop-format="csv" data-privatus-prop-source="toolbar">Export</button>
```

Props can be keywords, a NamedTuple or a Dict. A NamedTuple and keywords keep
their order. A Dict has no order, so its keys are sorted.

`event_data` returns the same attributes as a list of `name => value` pairs,
with the values not escaped yet, for HTML builders that escape for you.

In Genie views, use `privatus_event_data` with Genie's HTML functions. Genie
prints attribute values as they are, so this one escapes them for you:

```html
<% Html.button("Export"; class = "btn", privatus_event_data("Report exported"; format = "csv")...) %>
```

On a form, the event is sent when the form is submitted:

```julia
"<form action=\"/newsletter\" method=\"post\" $(event_attrs("Newsletter joined"; list = "weekly"))>"
```

The rules:

* The name is trimmed and cut to 120 characters. An empty name prints nothing.
* Prop keys are made lowercase. Anything that is not a letter, a digit or `_`
  becomes `_`, so `"Report Type"` becomes `report_type`. Keys are cut to 64
  characters.
* At most 30 props. Values become text: `true`, `false`, numbers as written,
  lists joined with commas. `nothing` and `missing` values are left out.
  Values are cut to 500 characters.
* Everything is escaped for HTML.
* The attributes print everywhere, even when the tag is off. They do nothing
  without the tracker, so your pages look the same in development and
  production.

### Click maps

A click map shows where people click on a page. Give the important parts a
name so they stay easy to find, even when the page changes:

```julia
"<a href=\"/pricing\" $(click_attr("pricing.cta"))>See plans</a>"
```

```html
<% Html.a("See plans"; href = "/pricing", privatus_click_data("pricing.cta")...) %>
```

A name may use letters, digits and `_ . : -`, up to 100 characters. Anything
else prints nothing, and outside production the package logs a warning.

### Page props: plan, role and other groups

Page props are sent with every pageview and event on the page. Use them to
split your reports by plan, role, app version, feature flag or account tier.

Set them for every page with a function. It runs on each request and gets the
request (an `HTTP.Request` in Genie and HTTP.jl):

```julia
PrivatusAnalytics.configure!(props = req -> (plan = plan_for(req), role = role_for(req), app_version = "2.4"))
```

A function with no arguments works too, and so does a plain NamedTuple or
Dict. You can also set or change props for one page. They are merged over the
configured ones, and `nothing` removes one:

```julia
PrivatusAnalytics.tag(props = (section = "billing", role = nothing))
```

The tag then prints a small script before the tracker, with your Content
Security Policy nonce when you have one, and points the tracker at it:

```html
<script nonce="...">window.privatusPageProps=function(){return {"plan":"pro","role":"admin"}}</script>
<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID" data-props="privatusPageProps"></script>
```

Keys follow the same rules as event props. Numbers and true or false stay as
they are, and lists stay lists (up to 30 items). The props are escaped so they
are safe inside a script. The middleware and Genie's `auto_inject` use the
same setting.

**Never put names, emails, user ids or anything that points to one person in
props.** Privatus Analytics counts visitors without any id. Put groups (like the plan or
the role), not people. The server also removes emails and long ids it finds.

### Track from your own JavaScript

For things that are not a click or a submit, call the tracker from your
JavaScript, as the [JavaScript API
docs](https://privatusanalytics.com/docs/tracker/javascript-api) explain:

```js
privatus.track("Feature used", { feature: "export" })
```

If your code may run before the tracker has loaded, switch on the queue stub.
It prints a tiny script before the tracker that keeps your calls in a list and
sends them once the tracker is ready:

```julia
PrivatusAnalytics.configure!(queue_stub = true)
```

or for one page: `PrivatusAnalytics.tag(queue_stub = true)`. The stub prints
even when the tag is off (in development, or with no site id). Then the tag
prints only the stub, with no tracker, so your `privatus.track(...)` calls
never fail. They wait in the list and are never sent.

### See the results

* [Funnels](https://privatusanalytics.com/docs/features/funnels): how many
  people go from one step to the next.
* [Click maps](https://privatusanalytics.com/docs/features/click-maps): where
  people click.
* [Goals](https://privatusanalytics.com/docs/features/goals): turn an event
  into a goal to count conversions.
* [Events](https://privatusanalytics.com/docs/events): every custom event and
  its props.

## Privacy

The script sets no cookies and stores nothing in the browser. The event, click
and props helpers only print HTML attributes and a small script. Keep people
out of your props and event props: no names, emails or user ids. See the
[privacy documentation](https://privatusanalytics.com/docs/privacy) for what is
collected.

If you have a privacy policy, it should say which tools handle your visitors' data. You can paste this:

> This website uses [Privatus Analytics](https://privatusanalytics.com/privacy-analytics) to count visits. It
> does not use cookies and does not follow you from one website to another. Your IP address is used for a moment
> to count visits and is never stored.

Change it to fit your site. The [privacy policy generator](https://privatusanalytics.com/tools/privacy-policy-generator)
makes a longer version with your site's name in it.

## Development

The checks run in Docker so your local Julia does not matter:

```sh
./run-docker.sh
```

It runs the test suite (with the Aqua.jl quality checks, and against Genie and
HTTP.jl), the HTTP.jl tests again with HTTP.jl 1.x, the JuliaFormatter check,
and a precompile of the package. `DOCS=1 ./run-docker.sh` also builds the
Documenter docs in `docs/`.

## Contributing

Bug reports and pull requests are welcome at
https://github.com/Privatus-Analytics/PrivatusAnalytics.jl.

## License

MIT. See [LICENSE](LICENSE). Privatus Analytics is a product of Two Phase LLC,
Wyoming, USA.
