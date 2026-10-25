@testset "inject" begin
    @testset "puts the tag before </head>" begin
        configure()
        @test PA.inject(PAGE) ==
            "<html><head><title>x</title>$TRACKER></script>\n</head><body>hi</body></html>"
        @test occursin(
            "$TRACKER></script>\n</head>", PA.inject(replace(PAGE, "</head>" => "</HEAD>"))
        )
    end

    @testset "leaves pages alone that have the tag, no head, or when the tag is off" begin
        configure()
        once = PA.inject(PAGE)
        @test PA.inject(once) == once
        @test PA.inject("<p>no head</p>") == "<p>no head</p>"
        configure(enabled=false)
        @test PA.inject(PAGE) == PAGE
    end

    @testset "takes per call options" begin
        configure()
        @test occursin("nonce=\"xyz\"", PA.inject(PAGE; nonce="xyz"))
    end

    @testset "injectable checks status, type, encoding and Ajax" begin
        @test PA.injectable(200, "text/html; charset=utf-8", "", "")
        @test PA.injectable(200, "TEXT/HTML", "", "")
        @test !PA.injectable(404, "text/html", "", "")
        @test !PA.injectable(200, "application/json", "", "")
        @test !PA.injectable(200, "text/html", "gzip", "")
        @test !PA.injectable(200, "text/html", "", "XMLHttpRequest")
    end
end
