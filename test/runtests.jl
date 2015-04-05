using BinaryDecisionDiagrams
using Base.Test

a=BDD("a",BDD(true),BDD(false))
b=BDD("a",BDD(false),BDD(true))
c=BDD("b",b,BDD(false))
d=BDD("c",BDD(true),a)
e=BDD("c",BDD(true),a)

@test string(a) == "~a"
@test string(b) == "a"
@test string(c) == "(~b & a)"
@test string(d) == "(~c | (c & ~a))"
@test BDD(false) == BDD(false)
@test BDD(true) == BDD(true)
@test e == d

ordering=["c","b","a"]

oa=OBDD(ordering,c)
ob=OBDD(ordering,d)
oc=OBDD("(c,b,a)-> (~(c|true) || !1) | (true&(b|a))")

BDDnodes=(()->Set(["$(node)" for node in union(ancestors(BDD(0)),ancestors(BDD(1)))]))

gc()
before_od=BDDnodes()

od=OBDD(["d","c","b","a"],BDD("d",c,d))
with_od=BDDnodes()

od=nothing
gc()
after_od=BDDnodes()

@test before_od == after_od
@test before_od != with_od
@test issubset(before_od,with_od)

@test oc == OBDD(ordering,"b|a")
@test OBDD(string(oa)) == oa
@test OBDD(string(oc)) == oc
@test OBDD(string(~oa)) == ~oa
@test OBDD(string(~ob)) == ~ob
@test OBDD(string(~oc)) == ~oc
@test OBDD(string(oa|ob)) == oa|ob
@test OBDD(string(oa|ob)) == OBDD(string(oa))|OBDD(string(ob))
@test (~~oa).root == oa.root
@test ~~oa == oa
@test oa&oa == oa
@test oa|oa == oa
@test ~oa&oa == OBDD(oa.ordering,BDD(false))
@test ~oa|oa == OBDD(oa.ordering,BDD(true))
@test oa&BDD(false) == BDD(false)&oa
@test oa&BDD(false) == OBDD(oa.ordering,BDD(false))
@test oa&BDD(true) == BDD(true)&oa
@test oa&BDD(true) == oa
@test oa|BDD(true) == OBDD(oa.ordering,BDD(true))
@test oa|BDD(false) == oa
@test oa|ob == ~(~oa & ~ob)
@test oa|ob == ob|oa
@test oa&ob == ~(~oa | ~ob)
@test oa&ob == ob&oa
@test restrict(oc,"b",1) == OBDD(oc.ordering,"true")
@test restrict(oc,"b",0) == OBDD(oc.ordering,"a")
