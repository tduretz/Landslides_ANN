using Plots, Rasters, DataFrames, CSV, ProgressMeter, Printf, MAT
using BSON: @load
norm_cat = false

gr()

function PreProcess( DEM )
    h    = DEM.data[:,:,1]
    h   .= h[:,end:-1:1]
    h[h.==DEM.missingval] .= NaN
    return h
end

function ReadDEMProcess()
   
    # Load geotiffs
    DEM              = Raster("data/DEM.tif")
    dist_roads       = Raster("data/dist_roads.tif")
    plan_curvature   = Raster("data/plan_curvature.tif")
    profil_curvature = Raster("data/profil_curvature.tif")
    Slope            = Raster("data/Slope.tif")
    TWI              = Raster("data/TWI.tif")
    Geology          = Raster("data/Geology.tif")
    LandCover        = Raster("data/LandCover.tif")

    file = matopen("Vaud_extracted.mat")
    VD_coords = read(file, "coords")::Matrix{Float64} # note that this does NOT introduce a variable ``varname`` into scope
    close(file)

    file = matopen("Landslides_extracted.mat")
    LS_coords = read(file, "coords")::Matrix{Float64} # note that this does NOT introduce a variable ``varname`` into scope
    close(file)

    # Try to modify DEM without success
    # p=Plots.plot(size=(1400,1200), xtickfontsize=18, ytickfontsize=18, titlefontsize=18, labelfontsize=18)
    # p=Plots.plot!(VD_coords[:,1], VD_coords[:,2], color = :black, label=:none)
    # p=Plots.plot!(DEM, c=:terrain, title="DEM")
    # p=Plots.scatter!(LS_coords[:,1], LS_coords[:,2], markerstrokewidth=0., markercolor = :red, label="Landslides")
    # display(p)

    ############
    # Extract data from DEM
    x    = DEM.dims[1]
    y    = DEM.dims[2]
    y    = y[end:-1:1] 
    h    = PreProcess( DEM )

    # Interpolate landslide to a regular mesh
    LS_data = NaN*ones(Int64, size(h))
    dx, dy  = x[2]-x[1], y[2]-y[1]
    xmin    = x[1]
    ymin    = y[1]
    display((dx, dy))
    @showprogress for ii in eachindex(h)
        if h[ii]>0.
            LS_data[ii] = 0
        end
    end
    @showprogress for ii=1:length(LS_coords[:,1])
        ic = Int64(floor((LS_coords[ii,1]-xmin)/dx) )
        jc = Int64(floor((LS_coords[ii,2]-ymin)/dy) )
        LS_data[ic,jc] = 1
    end

    # p1 = Plots.plot(size=(1400,1400), xlabel="x [km]", ylabel="y [km]", xtickfontsize=18, ytickfontsize=18, titlefontsize=18, labelfontsize=18, aspect_ratio=1)
    # p1 = Plots.plot!(VD_coords[:,1]./1e3, VD_coords[:,2]./1e3, color = :black, label=:none)
    # p1 = heatmap!(x./1e3,y./1e3, h', clim=(450,3200), c=:terrain, aspect_ratio=1)
    # p1 = Plots.scatter!(LS_coords[:,1]./1e3, LS_coords[:,2]./1e3, markerstrokewidth=0., markercolor = :red, label="Landslides")
    # display( p1 )
    # png("Topography_Landslides")

    p2 = heatmap(x./1e3,y./1e3, LS_data', c=:turbo, aspect_ratio=1, clim=(0,1))
    display( p2 )

    file = matopen("observ.mat", "w")
    write(file, "LS_data", LS_data)
    close(file)

end

ReadDEMProcess()