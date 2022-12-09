using Plots, Rasters, DataFrames, CSV, ProgressMeter, Printf, MAT
using BSON: @load
norm_cat = false

function PreProcess( DEM )
    h    = Float32.(DEM.data[:,:,1])::Matrix{Float32}
    h   .= h[:,end:-1:1]
    println(typeof(h))
    println(DEM.missingval)
    h[h.==DEM.missingval] .= NaN
    return h
end

# gr()

function ReadDEM()
   
    # Load geotiffs
    DEM              = Raster("data/DEM.tif")
    dist_roads       = Raster("data/dist_roads.tif")
    plan_curvature   = Raster("data/plan_curvature.tif")
    profil_curvature = Raster("data/profil_curvature.tif")
    Slope            = Raster("data/Slope.tif")
    TWI              = Raster("data/TWI.tif")
    Geology          = Raster("data/Geology.tif")
    LandCover        = Raster("data/LandCover.tif")

    x    = Array(DEM.dims[1])
    y    = Array( DEM.dims[2])
    y    = y[end:-1:1] 
    _DEM              = PreProcess(DEM)
    _dist_roads       = PreProcess(dist_roads)
    _plan_curvature   = PreProcess(plan_curvature)
    _profil_curvature = PreProcess(profil_curvature)
    _Slope            = PreProcess(Slope)
    _TWI              = PreProcess(TWI)
    _Geology          = PreProcess(Geology)
    _LandCover        = PreProcess(LandCover)

    file = matopen("Raster_data.mat", "w")
    write(file, "x", x)
    write(file, "y", y)
    write(file, "DEM", _DEM)
    write(file, "dist_roads", _dist_roads)
    write(file, "plan_curvature", _plan_curvature)
    write(file, "profil_curvature", _profil_curvature)
    write(file, "Slope", _Slope)
    write(file, "TWI", _TWI)
    write(file, "Geology", _Geology)
    write(file, "LandCover", _LandCover)
    close(file)

    # Try to modify DEM without success
    # # p1=Plots.plot!(dist_roads, c=:turbo, title="dist_roads")
    # p2=Plots.plot!(DEM, c=:terrain)
    # # p3=Plots.plot!(plan_curvature, c=:turbo, title="plan_curvature")
    # # p4=Plots.plot!(profil_curvature, c=:turbo, title="profil_curvature")
    # display( p2 )


    # # Extract data from DEM
    # x    = DEM.dims[1]
    # y    = DEM.dims[2]
    # y    = y[end:-1:1] 
    # h    = PreProcess( DEM )

    # p= Plots.heatmap!(x./1e3,y./1e3, h', clim=(450,3200), c=:terrain, aspect_ratio=1)
    # display( Plots.plot(p) ) 

    # png("Raster_pt_1")

    # # Try to modify DEM without success
    # p1=Plots.plot!(Slope, c=:turbo, title="Slope")
    # p2=Plots.plot!(TWI, c=:turbo, title="TWI")
    # p3=Plots.plot!(Geology, c=:turbo, title="Geology")
    # p4=Plots.plot!(LandCover, c=:turbo, title="LandCover")
    # display( Plots.plot(p1,p2,p3,p4) )

    @printf("Start plot\n")
    p1 = Plots.plot(dist_roads, c=:turbo, title="dist_roads")
    p2 = Plots.plot(DEM, c=:terrain, title="DEM")
    p3 = Plots.plot(plan_curvature, c=:turbo, title="plan_curvature", clim=(-5,5))
    p4 = Plots.plot(profil_curvature, c=:turbo, title="profil_curvature", clim=(-5,5))
    display( Plots.plot(p1,p2,p3,p4, size=(1400,1400)) )
    png("Raster_pt_1")

    p1 = Plots.plot(Slope, c=:turbo, title="Slope")
    p2 = Plots.plot(TWI, c=:turbo, title="TWI")
    p3 = Plots.plot(Geology, c=:turbo, title="Geology")
    p4 = Plots.plot(LandCover, c=:turbo, title="LandCover")
    display( plot(p1, p2, p3, p4, size=(1400,1400)) )

    png("Raster_pt_2")

end

ReadDEM()