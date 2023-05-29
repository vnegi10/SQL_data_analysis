## SQL_data_analysis

This repository contains a sample SQLite database (NIPS - Neural Information Processing System
papers data) obtained from [Kaggle](https://www.kaggle.com/datasets/benhamner/nips-papers?select=database.sqlite).

Practice queries are present as sql files. The `sqlite3`
[command-line](https://www.sqlite.org/cli.html) tool can be used to
perform SQL queries on the database.

Additionally, the same database can also be analyzed by converting relevant
tables to a Julia DataFrame. The relevant steps are discussed in this 
[blog post](https://vnegi.hashnode.dev/working-with-sqlite-database-in-julia).

## Installation

### SQLite command-line tool on Ubuntu
    $ sudo apt install sqlite3
    $ sqlite3 -version
    ## 3.37.2 2022-01-06 13:25:41 872ba256cbf61d9290b571c0e6d82a20c224ca3ad82971edc46b29818d5dalt1

### Pluto.jl in Julia
    using Pkg
    Pkg.add("Pluto")
    using Pluto
    Pluto.run()

### Git LFS
The database files (*.sqlite) are tracked using Large File Storage (LFS). If not already
configured, follow the instructions [here.](https://docs.github.com/en/repositories/working-with-files/managing-large-files/installing-git-large-file-storage)

Once everthing is set up, clone this repository and open **SQL_data_notebook.jl** in your 
Pluto browser window. That's it, you should be good to go!

## Examples for using sqlite3

Open a database and check the schema:
```
sqlite> .open nips_papers.sqlite
sqlite> .schema
CREATE TABLE papers (
    id INTEGER PRIMARY KEY,
    year INTEGER,
    title TEXT,
    event_type TEXT,
    pdf_name TEXT,
    abstract TEXT,
    paper_text TEXT);
CREATE TABLE authors (
    id INTEGER PRIMARY KEY,
    name TEXT);
CREATE TABLE paper_authors (
    id INTEGER PRIMARY KEY,
    paper_id INTEGER,
    author_id INTEGER);
CREATE INDEX paperauthors_paperid_idx ON paper_authors (paper_id);
CREATE INDEX paperauthors_authorid_idx ON paper_authors (author_id);
```

Select specific rows based on a condition:
```
sqlite> SELECT papers.year, papers.title
   ...> FROM papers
   ...> WHERE year = 2017
   ...> LIMIT 10;
2017|Wider and Deeper, Cheaper and Faster: Tensorized LSTMs for Sequence Learning
2017|Concentration of Multilinear Functions of the Ising Model with Applications to Network Data
2017|Deep Subspace Clustering Networks
2017|Attentional Pooling for Action Recognition
2017|On the Consistency of Quick Shift
2017|Breaking the Nonsmooth Barrier: A Scalable Parallel Method for Composite Optimization
2017|Dual-Agent GANs for Photorealistic and Identity Preserving Profile Face Synthesis
2017|Dilated Recurrent Neural Networks
2017|Hunt For The Unique, Stable, Sparse And Fast Feature Learning On Graphs
2017|Scalable Generalized Linear Bandits: Online Computation and Hashing

```

Change mode to table:
```
sqlite> .mode table
sqlite> .mode
current output mode: table
```

Perform JOINS while reading commands from a file:
```
> cat find_authors.sql
SELECT papers.year, papers.title, paper_authors.author_id, authors.name
FROM papers
INNER JOIN paper_authors ON papers.id = paper_authors.paper_id
INNER JOIN authors ON authors.id = paper_authors.author_id
WHERE year == 2012
LIMIT 10;

sqlite> .read find_authors.sql
+------+----------------------------------------------------------------------------------+-----------+--------------------+
| year |                                      title                                       | author_id |        name        |
+------+----------------------------------------------------------------------------------+-----------+--------------------+
| 2012 | Locally Uniform Comparison Image Descriptor                                      | 5507      | Andrew Ziegler     |
| 2012 | Locally Uniform Comparison Image Descriptor                                      | 5508      | Eric Christiansen  |
| 2012 | Locally Uniform Comparison Image Descriptor                                      | 5509      | David Kriegman     |
| 2012 | Locally Uniform Comparison Image Descriptor                                      | 2723      | Serge J. Belongie  |
| 2012 | Learning from Distributions via Support Measure Machines                         | 5654      | Krikamol Muandet   |
| 2012 | Learning from Distributions via Support Measure Machines                         | 1361      | Kenji Fukumizu     |
| 2012 | Learning from Distributions via Support Measure Machines                         | 5655      | Francesco Dinuzzo  |
| 2012 | Learning from Distributions via Support Measure Machines                         | 1472      | Bernhard Sch?lkopf |
| 2012 | Finding Exemplars from Pairwise Dissimilarities via Simultaneous Sparse Recovery | 4951      | Ehsan Elhamifar    |
| 2012 | Finding Exemplars from Pairwise Dissimilarities via Simultaneous Sparse Recovery | 3341      | Guillermo Sapiro   |
+------+----------------------------------------------------------------------------------+-----------+--------------------+
```