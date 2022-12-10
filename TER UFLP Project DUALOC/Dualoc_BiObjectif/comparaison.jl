include("Multi_CritereV2AvecArbreRaccourci.jl")
include("lowerBoundSet_UFLP_R .jl")
using Plots

s1 = main() # solution approchée
s2 = exemple2() # solution exacte

println(s1)
println(s2)

scatter(s1[1], s1[2], label="approché", markersize=5)
scatter!(s2[1], s2[2], label="exact", markershape=:diamond)
