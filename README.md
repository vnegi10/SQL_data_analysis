## SQL_data_analysis

This repository contains a sample SQLite database (NIPS - Neural Information Processing System
papers data) obtained from [Kaggle](https://www.kaggle.com/datasets/benhamner/nips-papers?select=database.sqlite).

Practice queries are present as sql filess. The `sqlite3` command-line tool can be used to
perform SQL queries.

## Installation

### Ubuntu
    $ sudo apt install sqlite3
    $ sqlite3 -version
    ## 3.37.2 2022-01-06 13:25:41 872ba256cbf61d9290b571c0e6d82a20c224ca3ad82971edc46b29818d5dalt1

## Examples
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