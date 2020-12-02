SELECT
        sdb.name
FROM
	sys.databases sdb
WHERE
	sdb.database_id > 5
ORDER BY
        sdb.name