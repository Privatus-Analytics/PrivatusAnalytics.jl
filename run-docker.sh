#!/bin/sh
# Runs the tests (with Aqua), the JuliaFormatter check, a precompile of the package and a test
# against HTTP.jl 1.x, in the official Julia image. Usage: ./run-docker.sh
# DOCS=1 ./run-docker.sh also builds the Documenter docs.
# Packages are cached in the Docker volume privatus-julia-depot (docker volume rm it to start over).
set -e
docker run --rm -e DOCS="${DOCS:-0}" -v privatus-julia-depot:/root/.julia -v "$PWD":/pkg -w /pkg \
  julia:1.11 sh -c 'set -e
  echo "--- tests"
  julia --project=. -e "using Pkg; Pkg.test()"
  echo "--- tests with HTTP.jl 1.x"
  julia -e "using Pkg; Pkg.activate(temp=true); Pkg.develop(path=\".\"); Pkg.add(name=\"HTTP\", version=\"1\"); Pkg.add(\"Test\"); include(\"test/http1_compat.jl\")"
  echo "--- formatter"
  julia -e "using Pkg; Pkg.activate(temp=true); Pkg.add(\"JuliaFormatter\"); using JuliaFormatter; format(\".\"; overwrite=false) || (println(\"Run JuliaFormatter: format(\\\".\\\")\"); exit(1)); println(\"Formatting is clean.\")"
  echo "--- build"
  julia -e "using Pkg; Pkg.activate(temp=true); Pkg.develop(path=\".\"); Pkg.precompile(); using PrivatusAnalytics; println(\"PrivatusAnalytics \", pkgversion(PrivatusAnalytics), \" loads.\")"
  if [ "$DOCS" = "1" ]; then
    echo "--- docs"
    julia --project=docs -e "using Pkg; Pkg.develop(path=\".\"); Pkg.instantiate(); include(\"docs/make.jl\")"
  fi
'
