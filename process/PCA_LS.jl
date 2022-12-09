using MultivariateStats, Plots 
using DataFrames, CSV, MLUtils, TernaryPlots

plotlyjs()

frac_train = 0.1

function MainPCA_LS()

    df  = CSV.read("data/Landslides.csv", DataFrame)

    X_all  = Array(df[:,1:6])'
    y_all  = df[:,9].==1
    isplit = Int(floor(size(X_all,2)*frac_train))
    # Training set:
    Xtr        = Array(df[1:isplit,1:6])'    # 6×1000 Matrix{Float32}
    Xtr_labels = Vector(Array(df[1:isplit,9]).==1);  #   1000-element Vector{Bool}
    Xtr        = normalise(Xtr)
    # Testing set:
    Xte        = Array(df[isplit+1:end,1:6])'    # 6×1000 Matrix{Float32}
    Xte_labels = Array(df[isplit+1:end,9]).==1;  #   1000-element Vector{Bool}
    Xte        = normalise(Xte)


    M = fit(PCA, Xtr; maxoutdim=4)
    
    Yte = predict(M, Xte)

    Xr = reconstruct(M, Yte)


    Landslide_0 = Yte[:,Xte_labels.==0]
    Landslide_1 = Yte[:,Xte_labels.==1]


    # p = plot(size=(1200,1200), xlabel="PC1",ylabel="PC2",zlabel="PC3")
    # p = scatter!(Landslide_0[1,:],Landslide_0[2,:],Landslide_0[3,:],marker=:circle,linewidth=0, label="landslide")
    # p = scatter!(Landslide_1[1,:],Landslide_1[2,:],Landslide_1[3,:],marker=:circle,linewidth=0, label="no landslide")
    # display( p )

    Landslide_0[1,:] .-= minimum(Landslide_0[1,:])
    Landslide_0[1,:] ./= maximum(Landslide_0[1,:])
    Landslide_0[2,:] .-= minimum(Landslide_0[2,:])
    Landslide_0[2,:] ./= maximum(Landslide_0[2,:])
    Landslide_0[3,:] .-= minimum(Landslide_0[3,:])
    Landslide_0[3,:] ./= maximum(Landslide_0[3,:])

    Landslide_1[1,:] .-= minimum(Landslide_1[1,:])
    Landslide_1[1,:] ./= maximum(Landslide_1[1,:])
    Landslide_1[2,:] .-= minimum(Landslide_1[2,:])
    Landslide_1[2,:] ./= maximum(Landslide_1[2,:])
    Landslide_1[3,:] .-= minimum(Landslide_1[3,:])
    Landslide_1[3,:] ./= maximum(Landslide_1[3,:])

    compos = [Landslide_0[1,:] Landslide_0[2,:] Landslide_0[3,:]]
    LS0 = [zeros(eltype(compos), size(compos, 1)) zeros(eltype(compos), size(compos, 1))]

    for i in 1:size(compos,1)
        LS0[i,:] = collect(tern2cart(compos[i,:]))'
    end

    compos = [Landslide_1[1,:] Landslide_1[2,:] Landslide_1[3,:]]
    LS1 = [zeros(eltype(compos), size(compos, 1)) zeros(eltype(compos), size(compos, 1))]

    for i in 1:size(compos,1)
        LS1[i,:] = collect(tern2cart(compos[i,:]))'
    end

    ternary_axes(
    title="Principal component analysis",
    xguide="PC #1",
    yguide="PC #2",
    zguide="PC #3",)

    p = scatter!(LS0[:,1], LS0[:,2], legend=false, size=(1200,1000), label="no landslides")
    p = scatter!(LS1[:,1], LS1[:,2], legend=false, size=(1200,1000), label="landslides", alpha=0.5)
    display(plot(p))

    display(M)
end

MainPCA_LS()