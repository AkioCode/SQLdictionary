WITH const_col as ( 
	SELECT 
		'"'||pcl.relname||'"'		as tabela
		,ccu.column_name as coluna
		,pco.contype	as tipo
		,cck.check_clause as ck_clause
	FROM
		pg_class pcl  
		JOIN pg_constraint pco ON pco.conrelid = pcl.oid
		join pg_namespace pns on pns.oid = pco.connamespace
		JOIN information_schema.constraint_column_usage ccu ON 
			ccu.constraint_name = pco.conname
			AND ccu.table_schema = pns.nspname
		LEFT JOIN information_schema.check_constraints cck ON
			ccu.constraint_name = cck.constraint_name
	WHERE
		pcl.relnamespace = 2200
		and pcl.relkind = 'r'
), const_group AS (
	SELECT 
		col.table_schema		"SCHEMA"
		,col.table_name 		"TABLE"
		,col.column_name 		"NAME"
		,col.character_maximum_length	"LENGTH"
		,col.data_type 			"TYPE"
		,col.is_nullable 		"NULL"
		,col.column_default 	"DEFAULT"
		,des.description		"COMMENT"
		,cco.ck_clause			"CHECK"
		,array_agg(cco.tipo) 	"CONSTRAINTS"
	FROM
		information_schema."columns" col
		LEFT JOIN pg_description des ON 
			(des.classoid = ('"'||col.table_name||'"')::regclass
			OR des.classoid = ('"'||col.table_schema||'"."'||col.table_name||'"')::regclass)
			AND des.objsubid = col.ordinal_position
		LEFT JOIN const_col cco ON
			cco.tabela = ('"'||col.table_name||'"') 
			AND cco.coluna = col.column_name
	WHERE 
		col.table_schema = 'public'
	GROUP BY
		col.column_name
		,col.character_maximum_length
		,col.table_name
		,col.table_schema
		,col.data_type
		,col.is_nullable
		,col.column_default
		,cco.ck_clause	
		,des.description
)
	SELECT 
		con."SCHEMA"
		,con."TABLE"
		,con."NAME"
		,(CASE 
		   		WHEN (con."LENGTH" IS NULL) THEN UPPER(con."TYPE")
				ELSE UPPER(con."TYPE") || ' (' || con."LENGTH" || ')'
		  END)	"TYPE"
		,(CASE 
		   		WHEN (con."NULL"='NO') THEN '✔'
				ELSE '❌'
		  END)	"NN"
		,(CASE 
		   		WHEN ('u'=ANY(con."CONSTRAINTS")
				OR 'p'=ANY(con."CONSTRAINTS")) THEN '✔'
				ELSE '❌'
		  END)	"UQ"
		,(CASE 
		   		WHEN ('p'=ANY(con."CONSTRAINTS")) THEN '✔'
				ELSE '❌'
		  END)	"PK"
		,(CASE 
		   		WHEN ('f'=ANY(con."CONSTRAINTS")) THEN '✔'
				ELSE '❌'
		  END)	"FK"
		,(CASE 
		   		WHEN (con."CHECK" IS NULL) THEN '➖'
				ELSE con."CHECK"
		  END)	"CK"
		,(CASE 
		   		WHEN (con."DEFAULT" IS NULL) THEN '➖'
				ELSE con."DEFAULT"
		  END)	"DF"
		,(CASE 
		   		WHEN (con."COMMENT" IS NULL) THEN '➖'
				ELSE con."COMMENT"
		  END)	"COMMENT"
	FROM 
		const_group con
ORDER BY 
	con."TABLE"
	,con."NAME"