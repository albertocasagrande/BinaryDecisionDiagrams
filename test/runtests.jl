using BinaryDecisionDiagrams
using Test

a=BDD("a",BDD(true),BDD(false))
b=BDD("a",BDD(false),BDD(true))
c=BDD("b",b,BDD(false))
d=BDD("c",BDD(true),a)
e=BDD("c",BDD(true),a)
f=BDD("a",BDD(true),
          BDD("b",BDD("c",
                      BDD(false),
                      BDD(true)),
                  BDD(false)))

@testset "BDD tests" begin
  @test string(a) == "~a"
  @test string(b) == "a"
  @test string(c) == "(~b & a)"
  @test string(d) == "(~c | (c & ~a))"
  @test BDD(false) == BDD(false)
  @test BDD(true) == BDD(true)
  @test e == d
end

@testset "OBDD tests" begin
  ordering=["c","b","a"]

  oa=OBDD(ordering,c)
  ob=OBDD(ordering,d)
  oc=OBDD("(c,b,a)-> (~(c|true) || !1) | (true&(b|a))")

  otrue=OBDD(oa.ordering,BDD(true))
  ofalse=OBDD(oa.ordering,BDD(false))

  BDDnodes=(()->Set(["$(node)" for node in union(ancestors(BDD(0)),
                                                 ancestors(BDD(1)))]))

  GC.gc()
  before_od=BDDnodes()

  od=OBDD(["d","c","b","a"],BDD("d",c,d))
  with_od=BDDnodes()

  od=nothing
  GC.gc()
  after_od=BDDnodes()

  @test_broken before_od == after_od
  @test before_od != with_od
  @test issubset(before_od,with_od)

  @testset "Parsing" begin
    @test oc == OBDD(ordering,"b|a")
    @test OBDD(string(oa)) == oa
    @test OBDD(string(oc)) == oc
    @test OBDD(string(~oa)) == ~oa
    @test OBDD(string(~ob)) == ~ob
    @test OBDD(string(~oc)) == ~oc
    @test OBDD(string(oa|ob)) == oa|ob

    oe = OBDD(["c","a"], d)
    @test oe =="(~c || (c && ~a))"
    @test oe == "~c + (c*~a)"

    @test OBDD(["a","b","c"], f) == "a->(~b&c)"
    @test OBDD(string(oa|ob)) == OBDD(string(oa))|OBDD(string(ob))
  
    @test_throws Meta.ParseError OBDD(ordering,"(a,b)-(a&b)")
  end

  @testset "Bitwise operators" begin
    @test (~~oa).root == oa.root
    @test ~~oa == oa
    @test oa&oa == oa
    @test oa|oa == oa
    @test ~oa&oa == OBDD(oa.ordering,BDD(false))
    @test ~oa|oa == OBDD(oa.ordering,BDD(true))
    @test oa&BDD(false) == BDD(false)&oa
    @test oa&false == false&oa
    @test oa&0 == 0&oa
    @test oa&BDD(false) == ofalse
    @test oa&BDD(true) == BDD(true)&oa
    @test BDD(true)&oa == oa&BDD(true)
    @test true&oa == oa&true
    @test 1&oa == oa&1
    @test oa&true == oa
    @test oa|true == otrue
    @test oa|false == oa
    @test oa|ob == ~(~oa & ~ob)
    @test oa|ob == ob|oa
    @test oa&ob == ~(~oa | ~ob)
    @test oa&ob == ob&oa
    @test oa⊻ob == ob⊻oa
    @test otrue⊻otrue == ofalse
    @test ofalse⊻ofalse == ofalse
    @test otrue⊻ofalse == otrue
    @test ofalse⊻otrue == otrue
  end

  ab = SAT_assignments(ob)
  aa = SAT_assignments(oa)  
  @testset "SAT" begin
    @test Set(ab) == Set([Dict("c" => 0), Dict("a" => 0)])
    @test Set(aa) == Set([Dict("b" =>0,"a" => 1)])
  end

  @testset "Restrictions" begin
    @test restrict(oc,"b",1) == otrue
    @test restrict(oc,"b",0) == OBDD(oc.ordering,"a")
    
    for a in ab
      @test restrict(ob, a) == otrue
    end

    @test restrict(ob, aa[1]) == OBDD("(c,b,a)-> ~c")
  end 

  binaryexp="a|~c&b"
  O1=['c','a','b']
  O2=['a','b','c']

  oe=OBDD(O1,binaryexp)
  of=OBDD(O2,binaryexp)

  @testset "Variable orderings" begin
    @test_throws ArgumentError oe==of
    @test oe==changeordering(of,O1)

    set_dynamic_ordering()

    @test oe==of
    @test OBDD(["x"],"x")|(~oe&of)==(of&~oe)|OBDD(["x"],"x")

    set_static_ordering()

    @test_throws ArgumentError oe==of
  end
end
