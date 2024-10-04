
	SELECT 
		 schemas.name AS [SchemaName]
		,objects.name AS [ObjectName]
		,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(objects.name, ' ', ''), ')', ''), '(', ''), '.', ''), ',', ''), '_', '') AS [CleanObjectName]
		,columns.name AS [ColumnName]
		,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(columns.name, ' ', ''), ')', ''), '(', ''), '.', ''), ',', ''), '_', '') AS [CleanColumnName]

		,ROW_NUMBER() OVER (
			PARTITION BY
				 schemas.name
				,objects.name
			ORDER BY
				columns.name
		) AS [RowOrder]

		,types.name AS [TypeName]

		-- https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql?view=sql-server-ver16
		,UPPER(
			CASE types.name
				WHEN 'uniqueidentifier' THEN types.name
				WHEN 'bit' THEN types.name
				WHEN 'int' THEN types.name
				WHEN 'bigint' THEN types.name

				WHEN 'nvarchar' THEN 
					CASE columns.max_length
						WHEN -1 THEN types.name + '(max)'
						ELSE types.name + '(' + CAST(columns.max_length / 2 AS NVARCHAR(20)) + ')'
						END
				WHEN 'varchar' THEN 
					CASE columns.max_length
						WHEN -1 THEN types.name + '(max)'
						ELSE types.name + '(' + CAST(columns.max_length AS NVARCHAR(20)) + ')'
						END
				
				WHEN 'datetimeoffset' THEN
					CASE columns.scale
						WHEN 3 THEN types.name
						ELSE types.name + '(' + CAST(columns.scale AS NVARCHAR(20)) + ')'
						END
				WHEN 'datetime' THEN
					CASE columns.scale
						WHEN 3 THEN types.name
						ELSE types.name + '(' + CAST(columns.scale AS NVARCHAR(20)) + ')'
						END
				WHEN 'datetime2' THEN
					CASE columns.scale
						WHEN 3 THEN types.name
						ELSE types.name + '(' + CAST(columns.scale AS NVARCHAR(20)) + ')'
						END
				
				WHEN 'decimal' THEN  types.name + '(' + CAST(columns.precision AS NVARCHAR(20)) + ', ' + CAST(columns.scale AS NVARCHAR(20)) + ')'
				WHEN 'numeric' THEN  types.name + '(' + CAST(columns.precision AS NVARCHAR(20)) + ', ' + CAST(columns.scale AS NVARCHAR(20)) + ')'

				END + 

			CASE columns.is_nullable 
				WHEN 1 THEN ' NULL' 
				ELSE ''
				END + 

			CASE columns.is_identity 
				WHEN 1 THEN ' IDENTITY' + (
					SELECT TOP 1 
						'(' + CAST(identity_columns.seed_value AS NVARCHAR(20)) + ', ' + CAST(identity_columns.increment_value AS NVARCHAR(20)) + ')' + 
						' /* ' + CASE WHEN identity_columns.last_value IS NULL THEN 'Seed' ELSE 'Last' END + ': ' + ISNULL(CAST(identity_columns.last_value AS NVARCHAR(20)), CAST(identity_columns.seed_value AS NVARCHAR(20))) + ' */'
					FROM sys.identity_columns
					WHERE 
							identity_columns.object_id = objects.object_id
						AND identity_columns.column_id = columns.column_id
				)				
				ELSE ''
				END +

			CASE 
				WHEN columns.collation_name IS NULL THEN ''
				ELSE ' COLLATE ' + columns.collation_name
				END

			) AS [SQL_TypeDescription]

			-- https://www.jhipster.tech/jdl/entities-fields#with-fields
			,CASE types.name
				WHEN 'uniqueidentifier' THEN 'UUID'
				WHEN 'bit' THEN 'Boolean'
				WHEN 'int' THEN 'Integer'
				WHEN 'bigint' THEN 'Long'

				WHEN 'nvarchar' THEN CASE columns.max_length WHEN -1 THEN 'TextBlob' ELSE 'String' END
				WHEN 'varchar' THEN CASE columns.max_length WHEN -1 THEN 'TextBlob' ELSE 'String' END
				
				WHEN 'datetimeoffset' THEN 'ZonedDateTime'
				WHEN 'datetime' THEN 'LocalDate'
				WHEN 'datetime2' THEN 'LocalDate'
				
				WHEN 'decimal' THEN 'Double'
				WHEN 'numeric' THEN 'Double'

				END AS [JDL_TypeDescription]
				
			,CASE types.name
				WHEN 'nvarchar' THEN columns.max_length
				WHEN 'varchar' THEN columns.max_length
				END AS [MaxStringLength]

	FROM sys.schemas AS [schemas]
	INNER JOIN sys.objects AS [objects]
		ON objects.schema_id = schemas.schema_id
			AND objects.type_desc = 'USER_TABLE'
	INNER JOIN sys.columns AS [columns]
		ON columns.object_id = objects.object_id --573
	INNER JOIN sys.types AS [types]
		ON types.system_type_id = columns.system_type_id
			AND types.user_type_id = columns.user_type_id
	FOR JSON AUTO
