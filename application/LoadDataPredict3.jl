# Prediction with categorical arrays: categories dealt using MLJ
using Plots, Rasters, Flux, DataFrames, CSV, ProgressMeter, Printf
using BSON: @load
import MLJ
norm_cat = false

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

    Geology[Geology.<0.] .= .0                      # 0 37
    Geol_int = Int64.(floor.(Geology))  
    Land_int = Int64.(LandCover)                   # 255

    @show unique(Geol_int)
    @show unique(Land_int)

    # Load the predictive model
    if norm_cat
        @load "model_test_70pc_with_cat_norm.bson" model
    else
        @load "model_test_70pc_with_cat_no_norm.bson" model
    end
 
    # Go through the DEM and compute how many activated cells
    n_cells = sum(DEM.>0. .&& Geol_int.!=0 .&& Geol_int.!=37 .&& Land_int.!=255)
    @printf("Found %04d activated cells\n", sum(DEM.>0.))
    @printf("Found %04d activated cells\n", n_cells)

    # Generate sparse map and extract data to table
    ndata = 8
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
            Dataset[1:6,n_cells  ] .= X'
            Dataset[7,n_cells  ]  = Geol_int[ii]
            Dataset[8,n_cells  ]  = Land_int[ii]           
        end
    end

    # Normalise data set
    if norm_cat 
        Dataset  .= Flux.normalise(Dataset)
    else
        Dataset[1:6,:] .= Flux.normalise(Dataset[1:6,:])
    end
    DF = DataFrame(Dataset', :auto)

    MLJ.coerce!(DF, :x7 =>  MLJ.OrderedFactor, :x8 =>  MLJ.OrderedFactor)
    hot  = MLJ.OneHotEncoder()
    mach =  MLJ.machine(hot, DF)
    mach = MLJ.fit!( MLJ.machine(hot, DF))
    DF2  = MLJ.transform(mach, DF)
    MLJ.coerce!(DF2, :LS => MLJ.OrderedFactor{2})
    display(DF2)
    
    # Apply prediction
    Dataset = Array(DF2)'
    ŷ = model(Dataset)
    Landslides[SparseMapVec] .= ŷ[1,:]

    @show minimum(ŷ[1,:])
    @show maximum(ŷ[1,:])

    # Display prediction
    p1 = Plots.plot(DEM, c=:terrain, title="DEM")
    p2 = Plots.plot(TWI, c=:turbo, title="TWI")
    p3 = Plots.plot(Slope, c=:turbo, title="Slopes")
    p4 = Plots.plot(Landslides, c=:turbo, title="Landslide prediction", clim=(0.,1.))
    display(plot(p1, p2, p3, p4, size=(1400,1400)))

    predict = PreProcess( Landslides )
    predict[predict.>1.0] .= 1.0
    file = matopen("predict_cat_mlj.mat", "w")
    write(file, "LS", predict)
    close(file)

end

MainPrediction()