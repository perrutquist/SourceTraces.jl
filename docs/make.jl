using SourceTraces
using Documenter

DocMeta.setdocmeta!(SourceTraces, :DocTestSetup, :(using SourceTraces); recursive=true)

makedocs(;
    modules=[SourceTraces],
    authors="Per Rutquist",
    sitename="SourceTraces.jl",
    format=Documenter.HTML(;
        canonical="https://perrutquist.github.io/SourceTraces.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/perrutquist/SourceTraces.jl",
    devbranch="main",
)
