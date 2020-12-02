WITH ccons AS (
SELECT 
	ccu.TABLE_NAME							as [TABLE]
	,ccu.column_name 						as [COLUMN]
	,tco.CONSTRAINT_NAME					as [NAME]
	,tco.CONSTRAINT_TYPE					as [TYPE]
	,(CASE tco.CONSTRAINT_TYPE
	  	WHEN N'FOREIGN KEY' THEN 
		(
			SELECT
				STRING_AGG(OBJECT_NAME(sfc.referenced_object_id)+'.'+
				COL_NAME(sfc.referenced_object_id,sfc.referenced_column_id),',')
			FROM
				sys.foreign_keys sfk
				JOIN sys.foreign_key_columns sfc ON
					sfk.object_id = sfc.constraint_object_id
				JOIN sys.tables stb ON
					sfc.referenced_object_id = stb.object_id
			WHERE
				OBJECT_NAME(sfc.constraint_object_id) = tco.CONSTRAINT_NAME
		)
	  	ELSE N'➖'
	END)									as	[REFERENCES]
	,(CASE tco.CONSTRAINT_TYPE
	  	WHEN N'FOREIGN KEY' THEN	rco.UPDATE_RULE
		ELSE N'➖'
	END)								as		[ONUPDATE]
	,(CASE tco.CONSTRAINT_TYPE
	  	WHEN N'FOREIGN KEY' THEN	rco.DELETE_RULE
		ELSE N'➖'
	END)									as	[ONDELETE]
	,ISNULL(prop.[value],N'➖')				as	[COMMENT]
FROM
	INFORMATION_SCHEMA.TABLE_CONSTRAINTS tco
	LEFT JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rco ON
		rco.CONSTRAINT_SCHEMA = tco.CONSTRAINT_SCHEMA
		AND	 rco.CONSTRAINT_NAME = tco.CONSTRAINT_NAME
	JOIN information_schema.constraint_column_usage ccu ON 
		ccu.constraint_name = tco.CONSTRAINT_NAME
		AND ccu.table_schema = tco.TABLE_SCHEMA
		AND ccu.TABLE_NAME = tco.TABLE_NAME
	LEFT JOIN information_schema.check_constraints cck ON
		ccu.constraint_name = cck.constraint_name
	LEFT JOIN sys.extended_properties prop ON 
			prop.class = 1
			AND prop.major_id = OBJECT_ID(tco.CONSTRAINT_SCHEMA+'.'+tco.CONSTRAINT_NAME)
			AND prop.NAME = N'MS_Description'
)
	SELECT 
		cns.[TABLE]
		,STRING_AGG(cns.[COLUMN],',') as [COLUMN]
		,cns.[NAME]
		,cns.[TYPE]
		,cns.[REFERENCES]
		,cns.[ONUPDATE]
		,cns.[ONDELETE]
		,cns.[COMMENT]
	FROM
		ccons cns
GROUP BY
	cns.[TABLE]
	,cns.[NAME]
	,cns.[TYPE]
	,cns.[REFERENCES]
	,cns.[ONUPDATE]
	,cns.[ONDELETE]
	,cns.[COMMENT]
ORDER BY
	cns.[NAME]