/*
====================================================================================
SGBD: PostgreSQL
CARTÃO: DB-651
DESCRIÇÃO: Retorna dicionário de dados apenas referente a constraints 
TIPO SCRIPT: DQL
====================================================================================
*/


SELECT 
	pcl.relname								"TABLE"
	,ccu.column_name 						"COLUMN"
	,pco.conname							"NAME"
	,(CASE (pco.contype)
		WHEN ('f') THEN 'FOREIGN KEY'
		WHEN ('c') THEN 'CHECK'
		WHEN ('u') THEN 'UNIQUE'
		WHEN ('p') THEN 'PRIMARY KEY'
		WHEN ('t') THEN 'TRIGGER'
		WHEN ('x') THEN 'EXCLUSION'
		ELSE '➖'
	END)									"TYPE"
	,(CASE
	  	WHEN (pco.contype != 'f') THEN '➖'
	  	ELSE (
			SELECT 
				sns.nspname||'.'||scl.relname||'.'||att.attname 
			FROM 
				pg_class scl 
				JOIN pg_attribute att ON att.attrelid = scl.oid
				JOIN pg_namespace sns ON scl.relnamespace = sns.oid 
			WHERE 
				scl.oid = pco.confrelid
				AND att.attnum = pco.confkey[1]
		)
	END)										"REFERENCES"
	,(CASE (pco.confupdtype)
			WHEN ('a') THEN 'NO ACTION'
			WHEN ('r') THEN 'RESTRICT'
			WHEN ('c') THEN 'CASCADE'
			WHEN ('n') THEN 'SET NULL'
			WHEN ('d') THEN 'SET DEFAULT'
			ELSE '➖'
	  END)									"ONUPDATE"
	,(CASE (pco.confdeltype)
		WHEN ('a') THEN 'NO ACTION'
		WHEN ('r') THEN 'RESTRICT'
		WHEN ('c') THEN 'CASCADE'
		WHEN ('n') THEN 'SET NULL'
		WHEN ('d') THEN 'SET DEFAULT'
		ELSE '➖'
	END)									"ONDELETE"
	,COALESCE(des.description, '➖')			"COMMENT"
FROM
	pg_class pcl  
	JOIN pg_constraint pco ON pco.conrelid = pcl.oid
	join pg_namespace pns on pns.oid = pco.connamespace
	JOIN information_schema.constraint_column_usage ccu ON 
		ccu.constraint_name = pco.conname
		AND ccu.table_schema = pns.nspname
	LEFT JOIN information_schema.check_constraints cck ON
		ccu.constraint_name = cck.constraint_name
	LEFT JOIN pg_description des ON 
			des.objoid = pco.oid
WHERE
	pcl.relnamespace = 2200
	and pcl.relkind = 'r'
ORDER BY
	pcl.relname
	,"TYPE"
	,ccu.column_name