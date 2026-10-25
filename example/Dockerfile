# The conformance example app (HTTP.jl). Build it with the package folder as the context:
#   docker build -f example/Dockerfile .
FROM julia:1.11
ENV JULIA_DEPOT_PATH=/depot JULIA_PROJECT=/pkg/example
WORKDIR /pkg
# The package from this repo's own source (the [sources] path in example/Project.toml), not
# from the General registry.
COPY Project.toml ./
COPY src/ src/
COPY ext/ ext/
COPY example/Project.toml example/
RUN julia -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
COPY example/ example/
ENV PORT=8080
EXPOSE 8080
CMD ["julia", "example/app.jl"]
