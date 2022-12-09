using StatsBase, HypothesisTests
using DataFrames, CSV, MLUtils

plotlyjs()

frac_train = 0.1

function MainCovariance_LS()
    df  = CSV.read("data/Landslides.csv", DataFrame)
    # filter!(row -> row[:LS] == 0, df)
    X_all  = [Array(df[:,1:6]) Array(df[:,9])]
    # X_all  = normalise(X_all)
    covariance = cor(X_all)
    display(heatmap(covariance[1:end,1:end], c=:turbo))


    @show pvalue(CorrelationTest(X_all[:,1],X_all[:,7]))
    @show pvalue(CorrelationTest(X_all[:,6],X_all[:,7]))

    @show maximum((X_all[:,end]))
    @show minimum((X_all[:,end]))
    # @show df[:,9]

end
MainCovariance_LS()