using HTTP
using Sockets

body_text(res) = res.body isa AbstractString ? String(res.body) : String(copy(res.body))
function header_value(res, name)
    for (key, value) in res.headers
        lowercase(key) == lowercase(name) && return value
    end
    return nothing
end
const HTML_TYPE = ["Content-Type" => "text/html; charset=utf-8"]
respond(body; status=200, headers=HTML_TYPE) = _ -> HTTP.Response(status, headers, body)

@testset "HTTP.jl middleware" begin
    request = HTTP.Request("GET", "/page")

    @testset "adds the tag and fixes Content-Length" begin
        configure()
        headers = vcat(HTML_TYPE, ["Content-Length" => string(ncodeunits(PAGE)), "X-Kept" => "1"])
        res = PA.middleware(respond(PAGE; headers=headers))(request)
        @test body_text(res) == PA.inject(PAGE)
        @test header_value(res, "Content-Length") == string(ncodeunits(PA.inject(PAGE)))
        @test count(pair -> lowercase(first(pair)) == "content-length", res.headers) == 1
        @test header_value(res, "X-Kept") == "1"
        @test res.status == 200
    end

    @testset "works with a byte body" begin
        configure()
        res = PA.middleware(respond(Vector{UInt8}(PAGE)))(request)
        @test occursin("/js/pa.js", body_text(res))
    end

    @testset "leaves other responses alone" begin
        configure()
        @test body_text(PA.middleware(respond(PAGE; status=404))(request)) == PAGE
        @test body_text(
            PA.middleware(respond(PAGE; headers=["Content-Type" => "application/json"]))(request)
        ) == PAGE
        gzip = vcat(HTML_TYPE, ["Content-Encoding" => "gzip"])
        @test body_text(PA.middleware(respond(PAGE; headers=gzip))(request)) == PAGE
        ajax = HTTP.Request("GET", "/page", ["X-Requested-With" => "XMLHttpRequest"])
        @test body_text(PA.middleware(respond(PAGE))(ajax)) == PAGE
        @test body_text(PA.middleware(respond("<p>no head</p>"))(request)) == "<p>no head</p>"
        tagged = PA.inject(PAGE)
        @test body_text(PA.middleware(respond(tagged))(request)) == tagged
        configure(enabled=false)
        @test body_text(PA.middleware(respond(PAGE))(request)) == PAGE
    end

    @testset "passes the request to props and takes a nonce" begin
        configure(props=req -> (section=req.target == "/page" ? "page" : "other",))
        res = PA.middleware(respond(PAGE); nonce=req -> "n-1")(request)
        @test occursin(
            "<script nonce=\"n-1\">window.privatusPageProps=function(){return {\"section\":\"page\"}}</script>",
            body_text(res),
        )
        @test occursin("data-props=\"privatusPageProps\"", body_text(res))
    end

    @testset "takes its own configuration" begin
        configure(enabled=false)
        own = PA.Configuration(; site_id="pa_OWN", enabled=true)
        @test occursin(
            "data-site=\"pa_OWN\"", body_text(PA.middleware(respond(PAGE); config=own)(request))
        )
    end

    @testset "reads settings at request time" begin
        configure(enabled=false)
        handler = PA.middleware(respond(PAGE))
        @test body_text(handler(request)) == PAGE
        configure()
        @test occursin("/js/pa.js", body_text(handler(request)))
    end

    @testset "a real server sends the tag with the right length" begin
        configure()
        port, socket = Sockets.listenany(ip"127.0.0.1", 18_000)
        close(socket)
        server = HTTP.serve!(PA.middleware(respond(PAGE)), "127.0.0.1", Int(port))
        try
            res = HTTP.get("http://127.0.0.1:$(Int(port))/")
            text = body_text(res)
            @test text == PA.inject(PAGE)
            @test header_value(res, "Content-Length") == string(ncodeunits(text))
        finally
            close(server)
        end
    end
end
