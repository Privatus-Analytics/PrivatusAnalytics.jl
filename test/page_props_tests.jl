@testset "page props" begin
    json = PA.page_props_json

    @testset "props become a JSON object" begin
        @test json((plan="pro", role="admin")) == "{\"plan\":\"pro\",\"role\":\"admin\"}"
    end

    @testset "empty props give nothing" begin
        @test json(Dict()) === nothing
        @test json(nothing) === nothing
        @test json((gone=nothing,)) === nothing
    end

    @testset "numbers, booleans and lists keep their JSON types" begin
        @test json((seats=5, ratio=1.5, beta=true, old=false, flags=["a", nothing, "b", 3])) ==
            "{\"seats\":5,\"ratio\":1.5,\"beta\":true,\"old\":false,\"flags\":[\"a\",\"b\",3]}"
        @test json((big=1e20, small=2.5f0, nan=NaN, inf=Inf)) == "{\"big\":1.0e20,\"small\":2.5}"
        @test json((t=(1, "x"),)) == "{\"t\":[1,\"x\"]}"
    end

    @testset "keys are cleaned like event props" begin
        @test json(Dict("App Version" => "2.1")) == "{\"app_version\":\"2.1\"}"
    end

    @testset "limits props, list items and value length" begin
        many = ["p$i" => i for i in 1:40]
        @test count(==(':'), json(many)) == 30
        @test count(==(','), json((list=string.(1:50),))) == 29
        @test json((long="x"^900,)) == "{\"long\":\"$("x"^500)\"}"
    end

    @testset "the JSON is safe inside a script tag" begin
        out = json((note="</script><b>&\u2028\u2029",))
        @test out == "{\"note\":\"\\u003c/script\\u003e\\u003cb\\u003e\\u0026\\u2028\\u2029\"}"
        @test !any(in(('<', '>', '&', '\u2028', '\u2029')), out)
    end

    @testset "quotes, backslashes and control characters are escaped" begin
        @test json((s="a\"b\\c\nd\te\u01",)) == "{\"s\":\"a\\\"b\\\\c\\nd\\te\\u0001\"}"
        @test json((s="ü😀",)) == "{\"s\":\"ü😀\"}"
    end
end
