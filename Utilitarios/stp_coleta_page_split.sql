USE [master]
GO
If(EXISTS(SELECT TOP 1 NULL FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'stp_coleta_page_split'))
	DROP PROCEDURE stp_coleta_page_split
GO
CREATE PROCEDURE stp_coleta_page_split
AS
BEGIN

	EXEC master..sp_MSforeachdb
		'
		USE [?];

		IF(DB_ID() < 5)
			RETURN;

		DECLARE @LastLSN VARCHAR(46)

		-- Seleciona o último LSN registrado no Log
		SELECT @LastLSN = LastLSN
			FROM master..tbMaxLSNLog
			WHERE DBName = DB_Name(DB_ID())

		INSERT INTO master..tbHistPageSplit(DBName, NomeTabela, NomeIndice, QtdPageSplit)
			SELECT 
					DB_Name(DB_ID()), SubString(Replace(AllocUnitName, ''dbo.'', ''''),1, CharIndex(''.'', Replace(AllocUnitName, ''dbo.'', '''')) -1), -- Tabela
					SubString(Replace(AllocUnitName, ''dbo.'', ''''), CharIndex(''.'', Replace(AllocUnitName, ''dbo.'', '''')) + 1,
					Len(Replace(AllocUnitName, ''dbo.'', '''')) - CharIndex(''.'', Replace(AllocUnitName, ''dbo.'','''')) + 1 ), -- Indice,
					COUNT([AllocUnitName]) [Splits] 
				FROM ::fn_dblog(NULL, NULL)
				WHERE Operation = N''LOP_DELETE_SPLIT''
					AND ParseName(AllocUnitName,3) <> ''sys''
					AND [Current LSN] > @LastLSN  -- Para não contabilizar duas vezes
				GROUP BY SubString(Replace(AllocUnitName, ''dbo.'', ''''),1, CharIndex(''.'', Replace(AllocUnitName, ''dbo.'', '''')) -1), -- Tabela
						 SubString(Replace(AllocUnitName, ''dbo.'', ''''), CharIndex(''.'', Replace(AllocUnitName, ''dbo.'', '''')) + 1,
						 Len(Replace(AllocUnitName, ''dbo.'', '''')) - CharIndex(''.'', Replace(AllocUnitName, ''dbo.'','''')) + 1 ) -- Indice

		If(@@ROWCOUNT > 0) -- Atualiza o LSN da database
		Begin

			SELECT @LastLSN = Max([Current LSN])
				FROM ::fn_dblog(NULL, NULL)
				WHERE Operation = N''LOP_DELETE_SPLIT''
					AND ParseName(AllocUnitName,3) <> ''sys''
					AND ([Current LSN] > @LastLSN OR @LastLSN IS NULL)

			UPDATE master..tbMaxLSNLog
				SET LastLSN = @LastLSN
				WHERE DBName = DB_Name(DB_ID())
		End
	'

END