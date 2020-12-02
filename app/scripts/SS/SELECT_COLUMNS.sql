/*
====================================================================================
SGBD: PostgreSQL
CARTÃO: DB-651
DESCRIÇÃO: Retorna dicionário de dados apenas referente a colunas das tabelas, semelhante ao Pg_modeler
TIPO SCRIPT: DQL
====================================================================================
*/


WITH const_group AS
(
	SELECT 
		col.table_schema					as	[SCHEMA]
		,col.table_name 					as	[TABLE]
		,col.column_name 					as	[NAME]
		,col.character_maximum_length		as	[LENGTH]
		,col.NUMERIC_SCALE					as	[NUM_SCALE]
		,col.NUMERIC_PRECISION				as	[NUM_PRECISION]
		,col.data_type 						as	[TYPE]
		,col.is_nullable 					as	[NULL]
		,col.column_default 				as	[DEFAULT]
		,prop.[value]						as	[COMMENT]
		,ckc.CHECK_CLAUSE					as	[CHECK]
		,string_agg(tco.CONSTRAINT_TYPE,',') as	[CONSTRAINTS]
	FROM
		information_schema."columns" col
		JOIN sys.columns sc ON	
			sc.object_id = object_id(col.table_schema + '.' + col.table_name)
			AND sc.NAME = col.COLUMN_NAME
		LEFT JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu ON 
			ccu.TABLE_SCHEMA = col.TABLE_SCHEMA
			AND ccu.TABLE_NAME = col.TABLE_NAME
			AND ccu.COLUMN_NAME = col.COLUMN_NAME
		LEFT JOIN INFORMATION_SCHEMA.CHECK_CONSTRAINTS ckc ON
			ckc.CONSTRAINT_SCHEMA = ccu.CONSTRAINT_SCHEMA
			AND ckc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
		LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tco ON
			tco.TABLE_SCHEMA = ccu.TABLE_SCHEMA
			AND tco.TABLE_NAME = ccu.TABLE_NAME
			AND tco.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
		LEFT JOIN sys.extended_properties prop ON prop.major_id = sc.object_id
			AND prop.minor_id = sc.column_id
			AND prop.NAME = 'MS_Description'
	GROUP BY
			col.column_name
			,col.character_maximum_length
			,col.NUMERIC_PRECISION
			,col.NUMERIC_SCALE
			,col.table_name
			,col.table_schema
			,col.data_type
			,col.is_nullable
			,col.column_default
			,ckc.CHECK_CLAUSE
			,prop.[value]
)
	SELECT 
		con.[SCHEMA]
		,con.[TABLE]
		,con.[NAME]
		,con.[CONSTRAINTS]
		,(CASE 
		   		WHEN(con.TYPE = 'numeric' OR con.TYPE = 'decimal')
					THEN UPPER(con.TYPE) + ' (' + CAST(con.NUM_PRECISION AS NVARCHAR) + ','+ CAST(con.NUM_SCALE AS NVARCHAR)+ ')'
				WHEN(con.LENGTH IS NULL)
					THEN UPPER(con.TYPE)
				ELSE 
					UPPER(con.TYPE) + ' (' + CAST(con.LENGTH AS NVARCHAR) + ')'
		  END)	AS [TYPE]
		  ,(CASE 
		   		WHEN (con."NULL"='NO') THEN N'✔'
				ELSE N'❌'
		  END)	as	[NN]
		  ,(CASE 
		   		WHEN (CHARINDEX(N'PRIMARY KEY',con.CONSTRAINTS) > 0
				OR CHARINDEX(N'UNIQUE',con.CONSTRAINTS) > 0) THEN N'✔'
				ELSE N'❌'
		  END) 	as	[UQ]
		,(IIF(CHARINDEX(N'PRIMARY KEY',con.CONSTRAINTS) > 0 ,N'✔',N'❌'))	as	[PK]
		,(IIF(CHARINDEX(N'FOREIGN KEY',con.CONSTRAINTS) > 0 ,N'✔',N'❌'))	as	[FK]
		,(CASE 
		   		WHEN (con.[CHECK] IS NULL) THEN N'➖'
				ELSE con.[CHECK]
		  END)	as	[CK]
		,(CASE 
		   		WHEN (con.[DEFAULT] IS NULL) THEN N'➖'
				ELSE con.[DEFAULT]
		  END)	as	[DF]
		,(CASE 
		   		WHEN (con.[COMMENT] IS NULL) THEN N'➖'
				ELSE con.[COMMENT]
		  END)	as	[COMMENT]
	FROM 
		const_group con
ORDER BY 
	con.[TABLE]
	,con.[NAME]