SELECT papers.year, papers.title, paper_authors.author_id
FROM papers
INNER JOIN paper_authors ON papers.id = paper_authors.paper_id
WHERE author_id BETWEEN 1001 AND 5001
LIMIT 10;
