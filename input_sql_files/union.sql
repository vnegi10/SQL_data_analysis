SELECT id FROM papers
UNION
SELECT paper_id FROM paper_authors
LIMIT 10;

