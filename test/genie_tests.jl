using Genie
using Genie.Renderer.Html: Html, @yield

@testset "Genie" begin
    view(name) = Genie.Renderer.Path(joinpath(@__DIR__, "views", name))

    @testset "the view helper returns Genie HTML" begin
        configure()
        tag = privatus_analytics_tag()
        @test tag isa Genie.Renderer.Html.ParsedHTMLString
        @test String(tag) == "$TRACKER></script>"
        @test occursin("data-modules=\"auto\"", privatus_analytics_tag(; modules=["auto"]))
    end

    @testset "attributes for Genie's HTML functions are escaped" begin
        @test privatus_event_data("Report exported"; note="a\"b") == [
            Symbol("data-privatus-event") => "Report exported",
            Symbol("data-privatus-prop-note") => "a&quot;b",
        ]
        @test privatus_click_data("pricing.cta") == [Symbol("data-privatus-click") => "pricing.cta"]
        @test_logs (:warn,) @test isempty(privatus_click_data("bad name"))
        button = Html.button("Export"; privatus_event_data("Report exported"; format="csv")...)
        @test occursin(
            "<button data-privatus-event=\"Report exported\" data-privatus-prop-format=\"csv\">Export</button>",
            button,
        )
    end

    @testset "a layout keeps the tag in the head" begin
        configure()
        res = Genie.Renderer.Html.html(
            view("page.jl.html"); layout=view("layout.jl.html"), context=@__MODULE__
        )
        page = body_text(res)
        head = page[1:findfirst("</head>", page)[1]]
        @test occursin("$TRACKER></script>", head)
        @test occursin(
            "data-privatus-event=\"Report exported\" data-privatus-prop-format=\"csv\"", page
        )
        @test occursin("data-privatus-click=\"pricing.cta\"", page)
    end

    @testset "auto inject adds the tag to Genie responses" begin
        ext = Base.get_extension(PrivatusAnalytics, :PrivatusAnalyticsGenieExt)
        @test ext.inject_hook in Genie.Router.pre_response_hooks
        Genie.Router.route("/privatus-page") do
            Genie.Renderer.Html.html(PAGE)
        end
        get_page() = body_text(
            Genie.Router.route_request(HTTP.Request("GET", "/privatus-page"), HTTP.Response())
        )

        configure(props=req -> (path=req.target,))
        @test !occursin("/js/pa.js", get_page())
        configure(auto_inject=true, props=req -> (path=req.target,))
        page = get_page()
        @test occursin("$TRACKER data-props=\"privatusPageProps\"></script>\n</head>", page)
        @test occursin("{\"path\":\"/privatus-page\"}", page)
        configure(auto_inject=true, enabled=false)
        @test !occursin("/js/pa.js", get_page())
    end
end
