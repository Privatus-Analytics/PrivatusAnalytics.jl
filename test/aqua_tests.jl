using Aqua

@testset "Aqua quality checks" begin
    # The package starts no tasks. The persistent tasks check is off because it stops on
    # HttpCommon, an old Genie dependency without a Project.toml.
    Aqua.test_all(PrivatusAnalytics; persistent_tasks=false)
end
