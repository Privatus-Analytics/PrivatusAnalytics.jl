using Documenter
using PrivatusAnalytics

# These docs use the package on themselves. The tag prints only when a site id is set
# (PRIVATUS_SITE_ID) and the build runs with PRIVATUS_ENV=production.
privatus = String(PrivatusAnalytics.tag())

makedocs(;
    sitename="PrivatusAnalytics.jl",
    modules=[PrivatusAnalytics],
    format=Documenter.HTML(;
        canonical="https://privatus-analytics.github.io/PrivatusAnalytics.jl",
        repolink="https://github.com/Privatus-Analytics/PrivatusAnalytics.jl",
        edit_link="main",
        assets=isempty(privatus) ? [] : [RawHTMLHeadContent(privatus)],
    ),
    pages=["Home" => "index.md", "Reference" => "reference.md"],
    remotes=nothing,
)
