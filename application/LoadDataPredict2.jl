# Prediction without categorical arrays
using Plots, Rasters, Flux, DataFrames, CSV, ProgressMeter, Printf, MAT
using BSON: @load
with_cat_arr = false
show_fig = false
gr()

function PreProcess( DEM )
    h    = Float32.(DEM.data[:,:,1])
    h   .= h[:,end:-1:1]
    h[h.==DEM.missingval] .= NaN
    return h
end

function MainPrediction()
   
    # Load geotiffs
    DEM              = Raster("data/DEM.tif")
    dist_roads       = Raster("data/dist_roads.tif")
    plan_curvature   = Raster("data/plan_curvature.tif")
    profil_curvature = Raster("data/profil_curvature.tif")
    Slope            = Raster("data/Slope.tif")
    TWI              = Raster("data/TWI.tif")
    Geology          = Raster("data/Geology.tif")
    LandCover        = Raster("data/LandCover.tif")
    Landslides       = deepcopy(DEM)

    Geology[Geology.<0.] .= .0                # 0 37
    Geol_int = Int64.(floor.(Geology))  
    Land_int = Int64.(LandCover)              # 255

    @printf("Labels for Geology:\n")
    @show unique(Geol_int)
    @printf("Labels for LandCover:\n")
    @show unique(Land_int)

    # Load the predictive model
    ndata = 6
    if with_cat_arr
        @load "model_test_70pc_with_cat.bson" model
    else
        @load "model_test_70pc.bson" model
    end

    # Go through the DEM and compute how many activated cells
    n_cells = sum(DEM.>0. .&& Geol_int.!=0 .&& Geol_int.!=37 .&& Land_int.!=255)
    @printf("Found %04d activated cells\n", sum(DEM.>0.))
    @printf("Found %04d activated cells\n", n_cells)

    # Generate sparse map and extract data to table
    Dataset      = zeros(ndata, n_cells) 
    SparseMapVec = zeros(Int64, n_cells)
    Geol         = zeros(Int64, n_cells) 
    Land         = zeros(Int64, n_cells) 
    n_cells      = 0
    @showprogress for ii in eachindex(DEM)
        if (DEM[ii]>.0 && Geol_int[ii]!=0 && Geol_int[ii]!=37 && Land_int[ii]!=255)
            n_cells+=1
            SparseMapVec[n_cells] = ii
            X                     = [dist_roads[ii] DEM[ii] TWI[ii] plan_curvature[ii] profil_curvature[ii] Slope[ii] ]
            if with_cat_arr
                Geol[n_cells] = Geol_int[ii]
                Land[n_cells] = Land_int[ii]
            end
            Dataset[:,n_cells  ] .= X'
        end
    end

    # Make things hot!
    Land_hot = Flux.onehotbatch(Land, unique(Land))
    Geol_hot = Flux.onehotbatch(Geol, unique(Geol))

    # Normalise data set
    Dataset .= Flux.normalise(Dataset)
    if with_cat_arr
        Dataset = [Dataset Geol_hot Land_hot]
    end
    @show size(Dataset)

    # Apply prediction
    @printf("Start fit\n")
    ŷ = model(Dataset)
    Landslides[SparseMapVec] .= ŷ[1,:]

    @show minimum(ŷ[1,:])
    @show maximum(ŷ[1,:])

    # Display prediction
    if show_fig
        @printf("Start plot\n")
        p1 = Plots.plot(DEM, c=:terrain, title="DEM")
        p2 = Plots.plot(TWI, c=:turbo, title="TWI")
        p3 = Plots.plot(Slope, c=:turbo, title="Slopes")
        p4 = Plots.plot(Landslides, c=:turbo, title="Landslide prediction", clim=(0,1))
        display(plot(p1, p2, p3, p4, size=(1400,1400)))
    end

    predict = zeros(Float32,size(DEM,1), size(DEM,2))
    predict[SparseMapVec] .= ŷ[1,:]
 
    @printf("min LS_no_cat = %2.2e max= %2.2e\n", minimum(predict), maximum(predict))
    
    file = matopen("predict_no_cat.mat", "w")
    write(file, "LS", predict)
    close(file)
end

MainPrediction()