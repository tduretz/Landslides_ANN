using Shapefile, GeoInterface, DataFrames, MAT

function ReadShapeFile()

    path = joinpath(dirname(pathof(Shapefile)),"..","test","shapelib_testcases","test.shp")
    path = string(@__DIR__,"/data/Shapefiles/Landslides.shp")
    # path = string(@__DIR__,"/data/Shapefiles/Vaud.shp")
    table = Shapefile.Table(path)

    # if you only want the geometries and not the metadata in the DBF file
    geoms = Shapefile.shapes(table)

    display(geoms[end])
    display(length(geoms))

    npoints = 0
    npol    = 0
    # loop through the table and count the points
    for t in table
        npol+=1
        arr = GeoInterface.coordinates(Shapefile.shape(t))[1][1]
        npoints += length(arr)
    end

    println(npol)
    println(npoints)
    x = zeros(npoints,2)
    npoints = 0
    # loop through the table and count the points
    for t in table
      
        arr = GeoInterface.coordinates(Shapefile.shape(t))[1][1]
        for ip=1:length(arr)
            npoints += 1
            x[npoints,1] =  GeoInterface.coordinates(Shapefile.shape(t))[1][1][ip][1]
            x[npoints,2] =  GeoInterface.coordinates(Shapefile.shape(t))[1][1][ip][2]
        end
    end
    # display(x)

    file = matopen("Landslides_Extracted.mat", "w")
    write(file, "coords", x)
    close(file)

end

ReadShapeFile()



