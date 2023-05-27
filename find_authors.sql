SELECT papers.year, papers.title, paper_authors.author_id, authors.name
FROM papers
INNER JOIN paper_authors ON papers.id = paper_authors.paper_id
INNER JOIN authors ON authors.id = paper_authors.author_id
WHERE year = 2012 AND title LIKE '%Distributions%'
LIMIT 10;
