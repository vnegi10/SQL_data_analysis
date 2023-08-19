SELECT year, title, id
FROM papers
WHERE EXISTS (SELECT author_id FROM paper_authors WHERE papers.id = paper_authors.paper_id AND 
author_id BETWEEN 1001 AND 5001)
LIMIT 10;

