include("setup.jl")

@testset "PrivatusAnalytics" begin
    withenv(
        "PRIVATUS_SITE_ID" => nothing,
        "PRIVATUS_SCRIPT_HOST" => nothing,
        "PRIVATUS_ENV" => nothing,
        "GENIE_ENV" => nothing,
    ) do
        include("configuration_tests.jl")
        include("attributes_tests.jl")
        include("page_props_tests.jl")
        include("tag_tests.jl")
        include("inject_tests.jl")
        include("http_tests.jl")
        include("genie_tests.jl")
    end
    include("aqua_tests.jl")
end
