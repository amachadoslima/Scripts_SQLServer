USE [000_SIGERO_ADMIN]
GO

SET NOCOUNT ON

DECLARE @Pesquisa VARCHAR(500)
Set @Pesquisa = '418.67'
 
CREATE TABLE #Resultados
(
	ColumnName nvarchar(370), 
	ColumnValue nvarchar(3630)
)
 

DECLARE @TableName nvarchar(256)
DECLARE @ColumnName nvarchar(128)
DECLARE @Pesquisa2 nvarchar(110)

Set  @TableName = ''
Set @Pesquisa2 = QuoteName('%' + @Pesquisa + '%','''')
 
While(@TableName IS NOT NULL)
Begin

    Set @ColumnName = ''
    Set @TableName = 
    (
        SELECT Min(QuoteName(TABLE_SCHEMA) + '.' + QuoteName(TABLE_NAME))
			FROM INFORMATION_SCHEMA.TABLES
			WHERE TABLE_TYPE = 'BASE TABLE'
				AND QuoteName(TABLE_SCHEMA) + '.' + QuoteName(TABLE_NAME) > @TableName
				AND ObjectProperty(Object_ID(QuoteName(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)), 'IsMSShipped') = 0
    )
 
	While((@TableName IS NOT NULL) AND (@ColumnName IS NOT NULL))
	Begin

		Set @ColumnName =
        (
            SELECT Min(QuoteName(COLUMN_NAME))
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_SCHEMA = ParseName(@TableName, 2)
					AND TABLE_NAME = ParseName(@TableName, 1)
					--AND DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar') -- Strings
					--AND DATA_TYPE IN ('tinyint', 'smallint', 'int', 'bigint') -- Números Inteiros
					AND DATA_TYPE IN ('numeric', 'float', 'decimal', 'money') -- Números Quebrados
					--AND DATA_TYPE IN ('uniqueidentifier') -- IDS
					--AND DATA_TYPE IN ('datetime', 'data') -- Data, Data/Hora
					AND QuoteName(COLUMN_NAME) > @ColumnName
        )
 
        If(@ColumnName IS NOT NULL)
        Begin

            INSERT INTO #Resultados
				EXEC
				(
					'SELECT ''' + @TableName + '.' + @ColumnName + ''', LEFT(' + @ColumnName + ', 3630) FROM ' + @TableName + ' (NOLOCK) ' +
					' WHERE ' + @ColumnName + ' LIKE ' + @Pesquisa2
				)
        End
    End   
End
 
SELECT DISTINCT ColumnName, ColumnValue 
	FROM #Resultados
 
DROP TABLE #Resultados