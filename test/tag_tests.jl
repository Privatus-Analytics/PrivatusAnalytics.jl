@testset "tag" begin
    @testset "prints the basic snippet" begin
        configure()
        @test PA.tag() == "$TRACKER></script>"
        @test PA.tag() isa PA.SafeHTML
    end

    @testset "prints nothing without a site id" begin
        configure(site_id=nothing)
        @test PA.tag() == ""
    end

    @testset "prints nothing when not enabled" begin
        configure(enabled=nothing)
        @test PA.tag() == ""
        withenv("GENIE_ENV" => "prod") do
            @test PA.tag() == "$TRACKER></script>"
        end
    end

    @testset "adds modules and exclusions" begin
        configure(modules=["engage", "auto"], excluded_paths=["/admin/*", "/preview/*"])
        tag = PA.tag()
        @test occursin("data-modules=\"engage,auto\"", tag)
        @test occursin("data-exclude=\"/admin/*,/preview/*\"", tag)
    end

    @testset "an empty modules list loads none" begin
        configure(modules=String[])
        @test occursin("data-modules=\"\"", PA.tag())
        configure(excluded_paths=String[])
        @test !occursin("data-exclude", PA.tag())
    end

    @testset "adds domains, spa mode and manual mode" begin
        configure(domains="example.com, www.example.com", spa="hash", manual=true)
        tag = PA.tag()
        @test occursin("data-domains=\"example.com,www.example.com\"", tag)
        @test occursin("data-spa=\"hash\"", tag)
        @test occursin("data-manual=\"true\"", tag)
        configure(spa=:off)
        @test occursin("data-spa=\"off\"", PA.tag())
    end

    @testset "ignores an unknown spa mode and the auto default" begin
        configure(spa="bogus")
        @test !occursin("data-spa", PA.tag())
        configure(spa="auto")
        @test !occursin("data-spa", PA.tag())
    end

    @testset "escapes attribute values" begin
        configure(excluded_paths=["/a\"b"])
        @test occursin("data-exclude=\"/a&quot;b\"", PA.tag())
    end

    @testset "per call options override the configuration" begin
        configure(modules=["engage"])
        @test occursin("data-modules=\"vitals\"", PA.tag(; modules=["vitals"]))
        @test PA.configuration().modules == ["engage"]
        @test PA.tag(; enabled=false) == ""
        @test occursin("data-site=\"pa_OTHER\"", PA.tag(; site_id="pa_OTHER"))
        @test occursin(
            "src=\"https://cdn.example.com/js/pa.js\"",
            PA.tag(; script_host="https://cdn.example.com/"),
        )
    end

    @testset "a separate configuration can be passed" begin
        configure()
        other = PA.Configuration(; site_id="pa_SECOND", enabled=true)
        @test occursin("data-site=\"pa_SECOND\"", PA.tag(other))
    end

    @testset "adds extra attributes and a nonce" begin
        configure(
            extra_attributes=Dict("data-mask" => "/orders/*->/orders/:id", "data-gone" => nothing)
        )
        tag = PA.tag(; nonce="abc123")
        @test occursin("data-mask=\"/orders/*-&gt;/orders/:id\"", tag)
        @test occursin("nonce=\"abc123\"", tag)
        @test !occursin("data-gone", tag)
    end

    @testset "the nonce can be a function of the request" begin
        configure(nonce=req -> "n-$req")
        @test occursin("nonce=\"n-7\"", PA.tag(; request=7))
    end

    @testset "page props print an inline script before the tag and data-props on it" begin
        configure()
        html = PA.tag(; props=(plan="pro", role="admin"))
        props_script = "<script>window.privatusPageProps=function(){return {\"plan\":\"pro\",\"role\":\"admin\"}}</script>"
        @test html == "$props_script\n$TRACKER data-props=\"privatusPageProps\"></script>"
    end

    @testset "the props script gets the nonce" begin
        configure()
        @test startswith(
            PA.tag(; props=(plan="pro",), nonce="abc"),
            "<script nonce=\"abc\">window.privatusPageProps=",
        )
    end

    @testset "empty props print no script and no data-props" begin
        configure()
        @test !occursin("privatusPageProps", PA.tag(; props=(plan=nothing,)))
    end

    @testset "configured props can be a NamedTuple or a Dict" begin
        configure(props=(plan="pro",))
        @test occursin("{\"plan\":\"pro\"}", PA.tag())
        configure(props=Dict(:plan => "pro"))
        @test occursin("{\"plan\":\"pro\"}", PA.tag())
    end

    @testset "configured props can be a function that gets the request" begin
        configure(props=request -> (plan=request[:plan],))
        @test occursin("{\"plan\":\"team\"}", PA.tag(; request=Dict(:plan => "team")))
    end

    @testset "per call props are merged over configured props and nothing removes one" begin
        configure(props=(plan="pro", role="admin"))
        @test occursin(
            "{\"plan\":\"pro\",\"tier\":\"gold\"}", PA.tag(; props=(role=nothing, tier="gold"))
        )
        @test occursin(
            "{\"plan\":\"team\",\"role\":\"admin\"}", PA.tag(; props=Dict("Plan" => "team"))
        )
    end

    @testset "the props function is not called when the tag is off" begin
        configure(enabled=false, props=_ -> error("should not run"))
        @test PA.tag() == ""
    end

    @testset "queue stub prints the official stub first" begin
        configure(queue_stub=true)
        parts = split(PA.tag(; nonce="abc", props=(plan="pro",)), "\n")
        @test parts[1] == "<script nonce=\"abc\">$(PA.QUEUE_STUB)</script>"
        @test occursin("privatusPageProps", parts[2])
        @test occursin("/js/pa.js", parts[3])
    end

    @testset "the queue stub is the official one" begin
        @test PA.QUEUE_STUB ==
            "window.privatus=window.privatus||{q:[]};['track','pageview','props','optOut','optIn','ready']" *
              ".forEach(function(m){window.privatus[m]=window.privatus[m]||function(){window.privatus.q.push(" *
              "[m,Array.prototype.slice.call(arguments)])}})"
    end

    @testset "queue stub can be switched on per call" begin
        configure()
        @test occursin("q:[]", PA.tag(; queue_stub=true))
        @test !occursin("q:[]", PA.tag())
    end

    @testset "event and click attributes print even when the tag is off" begin
        configure(enabled=false)
        @test event_attrs("Saved") == "data-privatus-event=\"Saved\""
        @test click_attr("a.b") == "data-privatus-click=\"a.b\""
    end
end
