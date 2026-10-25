# Changelog

## 1.0.0 - 2026-10-25

- Initial release.
- `PrivatusAnalytics.tag()` prints the tracker script tag, with settings for site id, script
  host, modules, excluded paths, domains, single-page app mode, manual mode, extra attributes
  and a Content Security Policy nonce. Any setting can be changed for one call.
- On only in production by default: `ENV["GENIE_ENV"] == "prod"` or
  `ENV["PRIVATUS_ENV"] == "production"`, unless `enabled` is set.
- `event_attrs` and `event_data` for custom events on buttons, links and forms.
- `click_attr` and `click_data` for click map names.
- Page props: the `props` setting (a NamedTuple, a Dict, or a function that gets the request)
  and `tag(props = ...)`. They print the `privatusPageProps` script and `data-props`.
- `queue_stub` setting, so `privatus.track` calls made before the tracker loads are kept.
- `PrivatusAnalytics.inject(html)` adds the tag before `</head>`.
- Genie extension: `privatus_analytics_tag()`, `privatus_event_data`, `privatus_click_data`,
  and `auto_inject = true` to add the tag to every HTML page.
- HTTP.jl extension: `PrivatusAnalytics.middleware(handler)` adds the tag to HTML responses.
