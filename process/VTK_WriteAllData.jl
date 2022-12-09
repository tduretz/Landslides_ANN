using WriteVTK, MAT, Printf

function WriteAllData()

    # LOAD ALL DATA FROM MAT FILES
    file = matopen("Raster_data.mat")
    x = read(file, "x")::Vector{Float64} 
    y = read(file, "y")::Vector{Float64} 
    DEM = read(file, "DEM")::Matrix{Float32}
    dist_roads = read(file, "dist_roads")::Matrix{Float32}
    plan_curvature = read(file, "plan_curvature")::Matrix{Float32}
    profil_curvature = read(file, "profil_curvature")::Matrix{Float32}
    Slope = read(file, "Slope")::Matrix{Float32}
    TWI = read(file, "TWI")::Matrix{Float32}
    Geology = read(file, "Geology")::Matrix{Float32}
    LandCover = read(file, "LandCover")::Matrix{Float32}
    close(file)

    file = matopen("predict_cat_mlj.mat")
    LS_cat = read(file, "LS")::Matrix{Float32}
    close(file)
    file = matopen("predict_no_cat.mat")
    LS_no_cat = read(file, "LS")::Matrix{Float32}
    close(file)

    file = matopen("observ.mat")
    LS_obs = read(file, "LS_data")::Matrix{Float64}
    close(file)

    @printf("min x = %2.2e max= %2.2e\n", minimum(x), maximum(x))
    @printf("min LS_no_cat = %2.2e max= %2.2e\n", minimum(LS_cat), maximum(LS_cat))

    z = zeros(1)
    A = zeros(size(DEM,1), size(DEM,2), 1)

    # WRITE ALL IN A VTK
    vtk_grid("AllDataVTK", x, y, z) do vtk
        vtk["DEM"] = DEM
        vtk["LS_obs"] = LS_obs
        vtk["LS_no_cat"] = LS_no_cat
        vtk["LS_cat"] = LS_cat
        vtk["dist_roads"] = dist_roads
        vtk["plan_curvature"] = plan_curvature
        vtk["profil_curvature"] = profil_curvature
        vtk["Slope"] = Slope
        vtk["TWI"] = TWI
        vtk["Geology"] = Geology
        vtk["LandCover"] = LandCover
    end

end

WriteAllData()