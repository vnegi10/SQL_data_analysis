### A Pluto.jl notebook ###
# v0.19.26

using Markdown
using InteractiveUtils

# ╔═╡ 8adc3334-fcd1-11ed-2f59-9fa2b2d3093f
using SQLite, DataFrames, CSV, PlutoUI, HTTP

# ╔═╡ 2f5a11f0-32cf-4aef-aed2-daaf50318aa7
md"
## Analysis of NIPS SQLite database using sqlite3 and Julia 
"

# ╔═╡ 6bc5a433-f8a2-4145-acd9-4f4dfab3fa56
md"
## Load packages
"

# ╔═╡ de30a116-edc4-40e3-9591-2b7930904530
md"
## Read the database
"

# ╔═╡ 396409f8-b0b7-4730-9368-fa186eaaa7d8
md"
#### Try using Storj link
"

# ╔═╡ b64ce361-4f4c-4992-b1a7-f49e1460bf99
storj_url = "https://link.storjshare.io/s/juzz4fmc76kuym72xfjhoygxruxq/external/files/db/nips_papers.sqlite?download=1"

# ╔═╡ e5737f3c-dcc8-441d-a277-7ffc170b80fe
"""
    download_db(storj_url::String, fname::String)
"""
function download_db(storj_url::String, fname::String)

	to_dir = joinpath(@__DIR__, "input_sqlite_database")
	if ~isdir(to_dir)
		mkpath(to_dir)
	end
	
	file_path = joinpath(to_dir, fname)

	if ~isfile(file_path)
		# Run system command	
		run(`wget -O $file_path $storj_url`)
	else
		@info "Database file already exists, skipping download!"
	end

end

# ╔═╡ c70fb6c6-56cd-4f80-973c-fa630ca3be4a
download_db(storj_url, "storj_nips_papers.sqlite")

# ╔═╡ 7bfcd49e-38cb-4622-b9e9-cd1a5395049d
db = SQLite.DB("input_sqlite_database/storj_nips_papers.sqlite")

# ╔═╡ ddbb848a-1849-4670-8909-9a1496d9ee7d
md"
#### Check schema (tables and columns)
"

# ╔═╡ ac083d1e-ab05-4c05-bbb8-565043b5c7fb
SQLite.tables(db)

# ╔═╡ ca5ae6e6-5e83-4912-a774-7ac1d97767df
SQLite.columns(db, "papers")

# ╔═╡ 80124aef-07a4-4bba-9216-1815075734be
df_papers = DBInterface.execute(db, "SELECT id, year, title FROM papers") |> DataFrame

# ╔═╡ 8ab8e038-7f4a-490f-9461-bd8514420fa1
df_authors = DBInterface.execute(db, "SELECT id, name FROM authors") |> DataFrame

# ╔═╡ 3a332bd5-3a97-4e56-8019-1db081234726
authors_dict = Pair.(df_authors.id, df_authors.name) |> Dict

# ╔═╡ 5c0d688d-bc41-40f3-91f8-7e704ca82169
df_paper_authors = DBInterface.execute(db, "SELECT paper_id, author_id FROM paper_authors") |> DataFrame

# ╔═╡ ee7c1b4f-5a2d-420a-ac06-a89420463121
md"
## Analyze data
"

# ╔═╡ ee579482-6db0-46ca-af92-c55682de52d1
md"
#### Find all authors for a given year
"

# ╔═╡ 0e8b8ce1-7289-4f64-890b-b3d3195700e5
function get_authors_for_year(search_year::Int64, 
	                          df_papers::DataFrame = df_papers,
	                          df_paper_authors::DataFrame = df_paper_authors,
                              df_authors::DataFrame = df_authors)

	df_result = filter(row -> row.year == search_year, df_papers)
	author_ids = Vector{Int64}[]

	for p_id in df_result[!, :id]
		df_filter = filter(row -> row.paper_id == p_id, df_paper_authors)
		push!(author_ids, df_filter[!, :author_id])
	end

	author_names = Vector{String}[]

	for author_group in author_ids
		names_group = String[]
		
		for a_id in author_group
			df_filter = filter(row -> row.id == a_id, df_authors)
			# Each id maps to a unique author name
			push!(names_group, df_filter[!, :name][1])
		end
		push!(author_names, names_group)
	end

	insertcols!(df_result, 3, :authors => author_names)

	return df_result

end

# ╔═╡ e49c1a70-8d2e-457b-a72c-f03da4cdc62d
function get_authors_all_years(df_authors::DataFrame,
	                           df_papers::DataFrame = df_papers,
	                           df_paper_authors::DataFrame = df_paper_authors)

	df_result = deepcopy(df_papers)
	author_ids = Vector{Int64}[]

	for p_id in df_result[!, :id]
		df_filter = filter(row -> row.paper_id == p_id, df_paper_authors)
		push!(author_ids, df_filter[!, :author_id])
	end

	author_names = Vector{String}[]

	for author_group in author_ids
		names_group = String[]
		
		for a_id in author_group
			df_filter = filter(row -> row.id == a_id, df_authors)
			# Each id maps to a unique author name
			push!(names_group, df_filter[!, :name][1])
		end
		push!(author_names, names_group)
	end

	insertcols!(df_result, 3, :authors => author_names)

	return df_result

end

# ╔═╡ 6e0eee5f-08cd-446d-a227-11f7074d6503
function get_authors_all_years(authors_dict::Dict,
	                           df_papers::DataFrame = df_papers,
	                           df_paper_authors::DataFrame = df_paper_authors)

	df_result = deepcopy(df_papers)
	author_ids = Vector{Int64}[]

	for p_id in df_result[!, :id]
		df_filter = filter(row -> row.paper_id == p_id, df_paper_authors)
		push!(author_ids, df_filter[!, :author_id])
	end

	author_names = Vector{String}[]

	for author_group in author_ids
		names_group = String[]
		
		for a_id in author_group
			# Each id maps to a unique author name
			push!(names_group, authors_dict[a_id])
		end
		push!(author_names, names_group)
	end

	# Merge author names into one row
	authors = String[]
	for author in author_names
		push!(authors, join(author, ", "))
	end		

	insertcols!(df_result, 3, :authors => authors)

	return df_result

end

# ╔═╡ 7775b202-ece0-4019-8b7f-31b760250292
#filter(row -> row.year == 2012, df_papers)

# ╔═╡ 9b64889d-b9ab-4ae7-9f5f-d58e6039efac
#@time df_2012 = get_authors_for_year(2012)

# ╔═╡ 0f33b5b1-0fd6-48b8-a801-2f719a559059
#get_authors_all_years(df_authors)

# ╔═╡ 4e4bd98e-b773-4163-b752-48423bef1fdf
df_all_authors = get_authors_all_years(authors_dict)

# ╔═╡ c9a59c9d-5843-4ff0-8e70-a042d6f36801
md"
#### Count number of papers per year
"

# ╔═╡ e6cc3a26-6120-4856-a3cc-034b0f4bc602
function count_papers(year_start::Int64,
	                  year_end::Int64,
                      df_papers::DataFrame = df_papers)

	gdf_papers = groupby(df_papers, :year)
	df_count = combine(x -> length(x.title), gdf_papers)

	return filter(row -> year_start ≤ row.year ≤ year_end, df_count)

end

# ╔═╡ ee923163-93c4-4d46-806a-5db6f28a4c00
df_count = count_papers(1970, 2020)

# ╔═╡ 92461804-f7ae-4bab-9d7c-8b2d09690153
md"
## Save to database
"

# ╔═╡ c12d08b2-3aed-4104-9728-e3b213f6aac5
function save_to_db(df_input::DataFrame, 
	                db_name::String, 
	                table_name::String)

	db_save = SQLite.DB(db_name)

	SQLite.load!(df_input, 
	         db_save, 
	         table_name; 
             temp = false, 
             ifnotexists = false, 
             replace = false, 
             on_conflict = nothing, 
             analyze = false)	

end

# ╔═╡ b3e79263-808f-411c-aba8-fdee9a02c4ee
#save_to_db(df_count, "output/papers_from_julia.sqlite", "paper_count")

# ╔═╡ 3c3a6b0a-302c-448f-9a45-2e259ff83af2
md"
## Save to CSV
"

# ╔═╡ 677adb14-fd8c-4ad8-9473-654239758a67
#CSV.write("output/papers_from_julia.csv", df_all_authors)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
SQLite = "0aa819cd-b072-5ff4-a722-6bc24af294d9"

[compat]
CSV = "~0.10.10"
DataFrames = "~1.5.0"
HTTP = "~1.9.7"
PlutoUI = "~0.7.51"
SQLite = "~1.6.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.1"
manifest_format = "2.0"
project_hash = "baf4fe1b1175b891f7f1588e42708de0ad02214c"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitFlags]]
git-tree-sha1 = "43b1a4a8f797c1cddadf60499a8a077d4af2cd2d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.7"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "PrecompileTools", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "ed28c86cbde3dc3f53cf76643c2e9bc11d56acc7"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.10"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "9c209fb7536406834aa938fb149964b985de6c83"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.1"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "7a60c856b9fa189eb34f5f8a6f6b5529b7942957"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.6.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.2+0"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "96d823b94ba8d187a6d8f0826e731195a74b90e9"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.2.0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DBInterface]]
git-tree-sha1 = "9b0dc525a052b9269ccc5f7f04d5b3639c65bca5"
uuid = "a10d1c49-ce27-4219-8d33-6db1a4562965"
version = "2.5.0"

[[deps.DataAPI]]
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SentinelArrays", "SnoopPrecompile", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "aa51303df86f8626a962fccb878430cdb0a97eee"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.5.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "e90caa41f5a86296e014e148ee061bd6c3edec96"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.9"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "e27c4ebe80e8699540f2d6c805cc12203b614f12"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.20"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "2613d054b0e18a3dea99ca1594e9a3960e025da4"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.9.7"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "d75853a0bdbfb1ac815478bacd89cd27b550ace6"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.3"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "cedb76b37bc5a6c702ade66be44f831fa23c681e"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.0"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "Random", "Sockets"]
git-tree-sha1 = "03a9b9718f5682ecb107ac9f7308991db4ce395b"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.7"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "51901a49222b09e3743c65b8847687ae5fc78eb2"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.1"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "cae3153c7f6cf3f069a853883fd1919a6e5bab5b"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.9+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "d321bf2de576bf25ec4d3e4360faca399afca282"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "a5aef8d4a6e8d81f171b2bd4be5265b01384c74c"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.10"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "b478a748be27bd2f2c73a7690da219d0844db305"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.51"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "259e206946c293698122f63e2b513a7c99a244e8"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.1.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "7eb1686b4f04b82f96ed7a4ea5890a4f0c7a09f1"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "LaTeXStrings", "Markdown", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "213579618ec1f42dea7dd637a42785a608b1ea9c"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.2.4"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

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

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SQLite]]
deps = ["DBInterface", "Random", "SQLite_jll", "Serialization", "Tables", "WeakRefStrings"]
git-tree-sha1 = "eb9a473c9b191ced349d04efa612ec9f39c087ea"
uuid = "0aa819cd-b072-5ff4-a722-6bc24af294d9"
version = "1.6.0"

[[deps.SQLite_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "4619dd3363610d94fb42a95a6dc35b526a26d0ef"
uuid = "76ed43ae-9a5d-5a62-8c75-30186b810ce8"
version = "3.42.0+0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "77d3c4726515dca71f6d80fbb5e251088defe305"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.18"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.SnoopPrecompile]]
deps = ["Preferences"]
git-tree-sha1 = "e760a70afdcd461cf01a575947738d359234665c"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "a4ada03f999bd01b3a25dcaa30b2d929fe537e00"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.0"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StringManipulation]]
git-tree-sha1 = "46da2434b41f41ac3594ee9816ce5541c6096123"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "1544b926975372da01227b382066ab70e574a3ec"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "9a6ae7ed916312b41236fcef7e0af564ef934769"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.13"

[[deps.Tricks]]
git-tree-sha1 = "aadb748be58b492045b4f56166b5188aa63ce549"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.7"

[[deps.URIs]]
git-tree-sha1 = "074f993b0ca030848b897beff716d93aca60f06a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.2"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.WorkerUtilities]]
git-tree-sha1 = "cd1659ba0d57b71a464a29e64dbc67cfe83d54e7"
uuid = "76eceee3-57b5-4d4a-8e66-0e911cebbf60"
version = "1.6.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╟─2f5a11f0-32cf-4aef-aed2-daaf50318aa7
# ╟─6bc5a433-f8a2-4145-acd9-4f4dfab3fa56
# ╠═8adc3334-fcd1-11ed-2f59-9fa2b2d3093f
# ╟─de30a116-edc4-40e3-9591-2b7930904530
# ╟─396409f8-b0b7-4730-9368-fa186eaaa7d8
# ╠═b64ce361-4f4c-4992-b1a7-f49e1460bf99
# ╟─e5737f3c-dcc8-441d-a277-7ffc170b80fe
# ╠═c70fb6c6-56cd-4f80-973c-fa630ca3be4a
# ╠═7bfcd49e-38cb-4622-b9e9-cd1a5395049d
# ╟─ddbb848a-1849-4670-8909-9a1496d9ee7d
# ╠═ac083d1e-ab05-4c05-bbb8-565043b5c7fb
# ╠═ca5ae6e6-5e83-4912-a774-7ac1d97767df
# ╠═80124aef-07a4-4bba-9216-1815075734be
# ╠═8ab8e038-7f4a-490f-9461-bd8514420fa1
# ╠═3a332bd5-3a97-4e56-8019-1db081234726
# ╠═5c0d688d-bc41-40f3-91f8-7e704ca82169
# ╟─ee7c1b4f-5a2d-420a-ac06-a89420463121
# ╟─ee579482-6db0-46ca-af92-c55682de52d1
# ╟─0e8b8ce1-7289-4f64-890b-b3d3195700e5
# ╟─e49c1a70-8d2e-457b-a72c-f03da4cdc62d
# ╟─6e0eee5f-08cd-446d-a227-11f7074d6503
# ╠═7775b202-ece0-4019-8b7f-31b760250292
# ╠═9b64889d-b9ab-4ae7-9f5f-d58e6039efac
# ╠═0f33b5b1-0fd6-48b8-a801-2f719a559059
# ╠═4e4bd98e-b773-4163-b752-48423bef1fdf
# ╟─c9a59c9d-5843-4ff0-8e70-a042d6f36801
# ╟─e6cc3a26-6120-4856-a3cc-034b0f4bc602
# ╠═ee923163-93c4-4d46-806a-5db6f28a4c00
# ╟─92461804-f7ae-4bab-9d7c-8b2d09690153
# ╟─c12d08b2-3aed-4104-9728-e3b213f6aac5
# ╠═b3e79263-808f-411c-aba8-fdee9a02c4ee
# ╟─3c3a6b0a-302c-448f-9a45-2e259ff83af2
# ╠═677adb14-fd8c-4ad8-9473-654239758a67
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
