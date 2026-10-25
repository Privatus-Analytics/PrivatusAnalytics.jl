@testset "configuration" begin
    @testset "site id falls back to the environment" begin
        PA.reset_configuration!()
        @test PA.site_id() === nothing
        withenv("PRIVATUS_SITE_ID" => " pa_FROMENV ") do
            @test PA.site_id() == "pa_FROMENV"
        end
        PA.configure!(site_id="  pa_SET  ")
        @test PA.site_id() == "pa_SET"
    end

    @testset "script host has a default and loses a trailing slash" begin
        PA.reset_configuration!()
        @test PA.script_host() == "https://privatusstats.com"
        withenv("PRIVATUS_SCRIPT_HOST" => "https://stats.example.com/") do
            @test PA.script_host() == "https://stats.example.com"
        end
        PA.configure!(script_host="https://own.example.com/")
        @test PA.script_host() == "https://own.example.com"
    end

    @testset "enabled only in production unless forced" begin
        PA.reset_configuration!()
        @test !PA.isenabled()
        withenv("GENIE_ENV" => "prod") do
            @test PA.isenabled()
        end
        withenv("GENIE_ENV" => "dev") do
            @test !PA.isenabled()
        end
        withenv("PRIVATUS_ENV" => "production") do
            @test PA.isenabled()
        end
        withenv("PRIVATUS_ENV" => "staging") do
            @test !PA.isenabled()
        end
        PA.configure!(enabled=true)
        @test PA.isenabled()
        withenv("GENIE_ENV" => "prod") do
            PA.configure!(enabled=false)
            @test !PA.isenabled()
        end
    end

    @testset "unknown settings are refused" begin
        @test_throws ArgumentError PA.configure!(site=1)
        @test_throws ArgumentError PA.tag(colour="red")
    end

    @testset "props can be a function of the request, or take no arguments" begin
        PA.reset_configuration!()
        PA.configure!(props=req -> (plan=req,))
        @test PA.page_props(PA.configuration(), "team") == (plan="team",)
        PA.configure!(props=() -> (plan="solo",))
        @test PA.page_props(PA.configuration(), "ignored") == (plan="solo",)
    end
end
