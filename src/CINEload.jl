module CINEload

using FixedPointNumbers:  N0f8, N4f12
using DataStructures: OrderedDict
using ProgressMeter: @showprogress
using Dates, TimeZones

export readcine, readframe, cineheader

include("readcine.jl")

end # module
