# Runs the HTTP.jl tests against HTTP.jl 1.x. Used by run-docker.sh in its own environment.
include("setup.jl")

using HTTP
@testset "HTTP.jl $(pkgversion(HTTP))" begin
    include("http_tests.jl")
end
