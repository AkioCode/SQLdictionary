SELECT
    datname
FROM
    pg_database
WHERE
    datistemplate = false
    AND datallowconn = true
ORDER BY 
    datname