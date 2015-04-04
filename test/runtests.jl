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
oc=OBDD("(c,b,a)-> (~(c|true) || !true) | (true&(b|a))")

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
