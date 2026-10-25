@testset "attributes" begin
    @testset "an event becomes data attributes" begin
        @test event_data("Export CSV", (format="csv", source="toolbar")) == [
            "data-privatus-event" => "Export CSV",
            "data-privatus-prop-format" => "csv",
            "data-privatus-prop-source" => "toolbar",
        ]
        @test event_attrs("Export CSV"; format="csv", source="toolbar") ==
            "data-privatus-event=\"Export CSV\" data-privatus-prop-format=\"csv\" " *
              "data-privatus-prop-source=\"toolbar\""
    end

    @testset "keyword props are merged over the props argument" begin
        attrs = Dict(event_data("Saved", Dict(:a => "1", :b => "2"); b="3"))
        @test attrs["data-privatus-prop-a"] == "1"
        @test attrs["data-privatus-prop-b"] == "3"
    end

    @testset "a Dict is sorted by key, a NamedTuple keeps its order" begin
        @test first.(event_data("Saved", Dict("b" => 1, "a" => 2)))[2:end] ==
            ["data-privatus-prop-a", "data-privatus-prop-b"]
        @test first.(event_data("Saved", (b=1, a=2)))[2:end] ==
            ["data-privatus-prop-b", "data-privatus-prop-a"]
    end

    @testset "the event name is trimmed and cut to 120 characters" begin
        @test Dict(event_data("  Export CSV  "))["data-privatus-event"] == "Export CSV"
        @test Dict(event_data("a"^200))["data-privatus-event"] == "a"^120
        @test Dict(event_data("é"^200))["data-privatus-event"] == "é"^120
    end

    @testset "an empty event name gives nothing" begin
        @test isempty(event_data("   "; format="csv"))
        @test isempty(event_data(nothing))
        @test event_attrs("") == ""
        @test event_attrs("") isa PA.SafeHTML
    end

    @testset "prop keys are lowercased, cleaned and cut to 64 characters" begin
        attrs = Dict(event_data("Saved", Dict("Report Type" => "a", "x-y" => "b", "K"^80 => "c")))
        @test attrs["data-privatus-prop-report_type"] == "a"
        @test attrs["data-privatus-prop-x_y"] == "b"
        @test attrs["data-privatus-prop-$("k"^64)"] == "c"
    end

    @testset "values become strings and nothing values are dropped" begin
        attrs = Dict(
            event_data(
                "Saved";
                on=true,
                off=false,
                count=3,
                ratio=1.5,
                tags=["a", nothing, "b"],
                gone=nothing,
                unknown=missing,
                sym=:pro,
            ),
        )
        names = [
            "data-privatus-prop-$key" for key in ("on", "off", "count", "ratio", "tags", "sym")
        ]
        @test [attrs[name] for name in names] == ["true", "false", "3", "1.5", "a,b", "pro"]
        @test !haskey(attrs, "data-privatus-prop-gone")
        @test !haskey(attrs, "data-privatus-prop-unknown")
    end

    @testset "values are cut to 500 characters and at most 30 props are kept" begin
        props = ["p$i" => "v" for i in 1:40]
        @test length(event_data("Saved", props)) == 31
        @test length(Dict(event_data("Saved"; long="x"^900))["data-privatus-prop-long"]) == 500
    end

    @testset "html escapes every value" begin
        @test event_attrs("Say \"hi\" <now>"; note="a&b'c") ==
            "data-privatus-event=\"Say &quot;hi&quot; &lt;now&gt;\" " *
              "data-privatus-prop-note=\"a&amp;b&#39;c\""
    end

    @testset "a valid click name becomes a data attribute" begin
        @test click_data("pricing.cta") == ["data-privatus-click" => "pricing.cta"]
        @test click_data("a-b_c:d.1") == ["data-privatus-click" => "a-b_c:d.1"]
        @test click_attr("pricing.cta") == "data-privatus-click=\"pricing.cta\""
        @test PA.isvalid_click("x"^100)
    end

    @testset "an invalid click name gives nothing and warns outside production" begin
        for name in ("", "has space", "x"^101, "<b>", "ok\n", nothing)
            @test_logs (:warn, r"not valid") @test isempty(click_data(name))
        end
        @test_logs (:warn,) @test click_attr("bad name") == ""
        withenv("PRIVATUS_ENV" => "production") do
            @test_logs @test click_attr("bad name") == ""
        end
    end

    @testset "safe HTML works like a string and shows as HTML" begin
        html = event_attrs("Saved")
        @test html isa AbstractString
        @test "<b $html>" == "<b data-privatus-event=\"Saved\">"
        @test sprint(show, MIME("text/html"), html) == String(html)
        @test length(html) == length(String(html))
    end
end
