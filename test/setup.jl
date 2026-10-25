using PrivatusAnalytics
using Test

const PA = PrivatusAnalytics
const TRACKER = "<script defer src=\"https://privatusstats.com/js/pa.js\" data-site=\"pa_TEST123456\""
const PAGE = "<html><head><title>x</title></head><body>hi</body></html>"

# Clean settings for each test, with the tag forced on unless a test says otherwise.
function configure(; kwargs...)
    PA.reset_configuration!()
    return PA.configure!(; site_id="pa_TEST123456", enabled=true, kwargs...)
end
