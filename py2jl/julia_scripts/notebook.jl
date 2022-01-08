### A Pluto.jl notebook ###
# v0.17.5

using Markdown
using InteractiveUtils

# ╔═╡ 92ea08b0-7034-11ec-2f22-816edf235c84
using PythonCall, CondaPkg, NearestNeighbors, BenchmarkTools, PlutoUI

# ╔═╡ ea71d315-5dde-4bef-afc5-5b621f8a1d5d
using NamedArrays

# ╔═╡ 1bd43a33-6c2f-4b45-a1e8-d30513fc63ba
md"""
# Pythons and trees 🐍

We're going to show a new way to call Python from the Julia side. This should work without needing to do *anything* separately on your own system. Let's start by loading up some packages we would like to use in this notebook, including `PythonCall.jl` for handling the Julia/Python interop, and `CondaPkg` for handling the package management.

$(TableOfContents())
"""

# ╔═╡ 1d8d6419-4bc1-423f-a4a1-66a10505bce7
md"""
We also installed a benchmarking package `BenchmarkTools.jl` for making *sick* benchmarking graphics and `PlutoUI.jl` for creating a nifty table of contents.
"""

# ╔═╡ a3470f22-d4dc-4932-985c-4db8787e7408
md"""
## Some test data

🔹 We'll be using these for the rest of the notebook:
"""

# ╔═╡ 6c3d09a8-f6b4-4e18-a509-085f48a46fcc
const data = rand(3, 1_000)

# ╔═╡ 7e41fbbf-d9c2-434b-89ce-0b395f654158
const query = [0.5, 0.5, 0.5]

# ╔═╡ fbca44ec-98a1-47b8-a368-ce5d3bb94d54
md"""
## Calling Python

🔹 Let's start by installing `scipy` and loading it into the notebook:
"""

# ╔═╡ de1ef776-5c1e-4321-a24b-22834c23a31c
CondaPkg.add("scipy"), CondaPkg.resolve();

# ╔═╡ aeb83261-1055-4ae5-85ad-e4eb0623def9
md"""
🔹 Done. We can now do stuff like this:
"""

# ╔═╡ 0b075caa-54cf-45fa-b048-9fb87d6893de
@py import scipy.spatial as sp

# ╔═╡ ab2093a8-79e8-4416-9451-0c22786bfae5
# Define a 🌳 search
knn_py(data, query; k=3) = sp.KDTree(data).query(query, k=k)

# ╔═╡ c0131885-2302-413c-96bf-ef878155f36c
t_py = @benchmark knn_py($(data'), $query)

# ╔═╡ 53320eac-f2ab-4620-8b16-1d0dbf9f84e1
md"""
!!! note "Why all the $"
	They just helps us get [more accurate benchmarks](https://stackoverflow.com/a/57314853/16402912). Julia's compiler is very smart... maybe too smart
"""

# ╔═╡ f026d776-7ab8-49f1-9722-afc44f903ab6
md"""
🔹 This is ok, but we could do even better if we can precompute the tree first:
"""

# ╔═╡ aac55d6e-3f94-4c44-b2cd-f5e83866388b
knn_py_precomputed(tree, query; k=3) = tree.query(query, k=k)

# ╔═╡ 1bffa349-63d4-4a5d-8306-0870ddd283a1
tree_py = sp.KDTree(data')

# ╔═╡ b97f360c-480e-4ee0-aed2-9a1c4f8faa24
t_py_precomputed = @benchmark knn_py_precomputed($tree_py, $query)

# ╔═╡ 7a1fd302-9c3a-453b-adf9-e4f561c4031e
x_faster(a, b) = round(median(a.times) / median(b.times), digits=2)

# ╔═╡ 68dc277c-907d-4d4b-9eb1-44a4d1788baf
md"""
🔹 This is about **$(x_faster(t_py, t_py_precomputed)) x** faster now, but it's still slower than the best native Python solution we have in the other notebook. Let's try it in Julia.
"""

# ╔═╡ db2f9891-cb13-4739-bbf8-8b92b60ae81f
md"""
## Native Julia

🔹 First we'll start with the native Julia version of the non-precomputed function above:
"""

# ╔═╡ 7b27714f-f59e-4f4e-87ea-3040eea74d01
knn_jl(data, query; k=3) = knn(KDTree(data), query, k, true)

# ╔═╡ deb43ecf-0540-4af8-9c4f-feb0c671c47d
t_jl = @benchmark knn_jl($data, $query)

# ╔═╡ 1dee6ecd-4aa7-40d2-92a6-d4cf85ac1d66
md"""
🔹 This is already **$(x_faster(t_py, t_jl))x** faster than the first Python version (`t_py`). It's also faster than its native Python equivalent! To wrap up the comparisons, let's check out the precomputed version:
"""

# ╔═╡ 00a66ccc-82e3-4865-83fa-585c2fb62f1b
tree_jl = KDTree(data)

# ╔═╡ 362c2be6-9dbd-4465-805f-8194d3afded2
knn_precomputed_jl(tree, data, query; k=3) = knn(tree, query, k, true)

# ╔═╡ 3e3d634a-fcd4-42f8-9aa0-4c1b07e27fa2
t_jl_precomputed = @benchmark knn_precomputed_jl($tree_jl, $data, $query)

# ╔═╡ a2ed5cd3-67ca-4321-9360-bff45afaa26a
md"""
🔹 This is $(x_faster(t_py, t_jl_precomputed))x faster than the original Python version 🔥
"""

# ╔═╡ ef51513a-9e37-47ec-9476-6b0722aeb4c3
md"""
## Summary

Below is a quick summary of the speed-ups for each case:
"""

# ╔═╡ 64787d25-bf8d-4d0d-af35-b480845fb633
md"""
!!! tip
	Updating the initial input for the `data` and `query` will automatically re-run the benchmarks and update this table accordingly!
"""

# ╔═╡ 032247e6-484c-47cc-af44-ec33291b90d9
labels = ["t_py", "t_py_precomp", "t_jl", "t_jl_precomp"]

# ╔═╡ cdb4c600-d6b3-4984-b344-9dc6c328d5b0
times = (t_py, t_jl, t_py_precomputed, t_jl_precomputed);

# ╔═╡ ef420307-fb1f-48fc-bc9d-66217f001d60
times_report = map(Iterators.product(times, times)) do t
	x_faster(t[2], t[1])
end;

# ╔═╡ 65c4aed6-fcf2-4d46-923e-296a9b85df33
@with_terminal println(NamedArray(times_report, (labels, labels), ("this", "vs.")))

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
CondaPkg = "992eb4ea-22a4-4c89-a5bb-47a3300528ab"
NamedArrays = "86f7a689-2022-50b4-a561-43c23ac3c673"
NearestNeighbors = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
PythonCall = "6099a3de-0909-46bc-b1f4-468b9a2dfc0d"

[compat]
BenchmarkTools = "~1.2.2"
CondaPkg = "~0.2.3"
NamedArrays = "~0.9.6"
NearestNeighbors = "~0.4.9"
PlutoUI = "~0.7.29"
PythonCall = "~0.5.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.1"
manifest_format = "2.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "940001114a0147b6e4d10624276d56d531dd9b49"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.2.2"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CodecBzip2]]
deps = ["Bzip2_jll", "Libdl", "TranscodingStreams"]
git-tree-sha1 = "2e62a725210ce3c3c2e1a3080190e7ca491f18d7"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.7.2"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[deps.Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "44c37b4636bc54afac5c574d2d02b625349d6582"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.41.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.CondaPkg]]
deps = ["MicroMamba", "Pkg", "TOML"]
git-tree-sha1 = "62b9ee4b58ad286452699d5cca555dfb03fd182f"
uuid = "992eb4ea-22a4-4c89-a5bb-47a3300528ab"
version = "0.2.3"

[[deps.DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3daef5523dd2e769dad2365274f760ff5f282c7d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.11"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "3258d0659f812acde79e8a74b11f17ac06d0ca04"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.7"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
git-tree-sha1 = "2b078b5a615c6c0396c77810d92ee8c6f470d238"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.3"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.MicroMamba]]
deps = ["CodecBzip2", "Downloads", "Tar"]
git-tree-sha1 = "9fe99eb772fd0865f8735849518387d7c808ed0c"
uuid = "0b3b1443-0f03-428d-bdfb-f27f9c1191ea"
version = "0.1.1"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.NamedArrays]]
deps = ["Combinatorics", "DataStructures", "DelimitedFiles", "InvertedIndices", "LinearAlgebra", "Random", "Requires", "SparseArrays", "Statistics"]
git-tree-sha1 = "2fd5787125d1a93fbe30961bd841707b8a80d75b"
uuid = "86f7a689-2022-50b4-a561-43c23ac3c673"
version = "0.9.6"

[[deps.NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "16baacfdc8758bc374882566c9187e785e85c2f0"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.9"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "d7fa6237da8004be601e19bd6666083056649918"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.1.3"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "7711172ace7c40dc8449b7aed9d2d6f1cf56a5bd"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.29"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "2cf929d64681236a2e074ffafb8d568733d2e6af"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.PythonCall]]
deps = ["CondaPkg", "Dates", "Libdl", "MacroTools", "Markdown", "Pkg", "Requires", "Serialization", "Tables", "UnsafePointers"]
git-tree-sha1 = "4069e80d13c3b33a2b5680a1464baf264c36e5a0"
uuid = "6099a3de-0909-46bc-b1f4-468b9a2dfc0d"
version = "0.5.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "8f82019e525f4d5c669692772a6f4b0a58b06a6a"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.2.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "88a559da57529581472320892576a486fa2377b9"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.3.1"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
git-tree-sha1 = "d88665adc9bcf45903013af0982e2fd05ae3d0a6"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.2.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "bb1064c9a84c52e277f1096cf41434b675cd368b"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.6.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnsafePointers]]
git-tree-sha1 = "c81331b3b2e60a982be57c046ec91f599ede674a"
uuid = "e17b2a0c-0bdf-430a-bd0c-3a23cae4ff39"
version = "1.0.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─1bd43a33-6c2f-4b45-a1e8-d30513fc63ba
# ╠═92ea08b0-7034-11ec-2f22-816edf235c84
# ╟─1d8d6419-4bc1-423f-a4a1-66a10505bce7
# ╟─a3470f22-d4dc-4932-985c-4db8787e7408
# ╠═6c3d09a8-f6b4-4e18-a509-085f48a46fcc
# ╠═7e41fbbf-d9c2-434b-89ce-0b395f654158
# ╟─fbca44ec-98a1-47b8-a368-ce5d3bb94d54
# ╠═de1ef776-5c1e-4321-a24b-22834c23a31c
# ╟─aeb83261-1055-4ae5-85ad-e4eb0623def9
# ╠═0b075caa-54cf-45fa-b048-9fb87d6893de
# ╠═ab2093a8-79e8-4416-9451-0c22786bfae5
# ╠═c0131885-2302-413c-96bf-ef878155f36c
# ╟─53320eac-f2ab-4620-8b16-1d0dbf9f84e1
# ╟─f026d776-7ab8-49f1-9722-afc44f903ab6
# ╠═aac55d6e-3f94-4c44-b2cd-f5e83866388b
# ╠═1bffa349-63d4-4a5d-8306-0870ddd283a1
# ╠═b97f360c-480e-4ee0-aed2-9a1c4f8faa24
# ╠═7a1fd302-9c3a-453b-adf9-e4f561c4031e
# ╟─68dc277c-907d-4d4b-9eb1-44a4d1788baf
# ╟─db2f9891-cb13-4739-bbf8-8b92b60ae81f
# ╠═7b27714f-f59e-4f4e-87ea-3040eea74d01
# ╠═deb43ecf-0540-4af8-9c4f-feb0c671c47d
# ╟─1dee6ecd-4aa7-40d2-92a6-d4cf85ac1d66
# ╠═00a66ccc-82e3-4865-83fa-585c2fb62f1b
# ╠═362c2be6-9dbd-4465-805f-8194d3afded2
# ╠═3e3d634a-fcd4-42f8-9aa0-4c1b07e27fa2
# ╟─a2ed5cd3-67ca-4321-9360-bff45afaa26a
# ╟─ef51513a-9e37-47ec-9476-6b0722aeb4c3
# ╟─65c4aed6-fcf2-4d46-923e-296a9b85df33
# ╟─64787d25-bf8d-4d0d-af35-b480845fb633
# ╟─032247e6-484c-47cc-af44-ec33291b90d9
# ╟─cdb4c600-d6b3-4984-b344-9dc6c328d5b0
# ╟─ef420307-fb1f-48fc-bc9d-66217f001d60
# ╟─ea71d315-5dde-4bef-afc5-5b621f8a1d5d
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
