USE [master]
GO
BEGIN

	SET NOCOUNT ON

	If(OBJECT_ID(N'tbMaxLSNLog') IS NULL)
	Begin

		-- Cria tabela
		CREATE TABLE tbMaxLSNLog
		(
			DBName VARCHAR(50),
			LastLSN VARCHAR(46)
		)
	End

	-- Remove os dados caso o objeto já exista na base de dados
	DELETE FROM tbMaxLSNLog

	-- Realiza uma carga de inserções para os dados do Page Split em todas as bases de dados
	EXEC master..sp_MSforeachdb
	'
		USE [?]; 

		If(DB_ID() < 5)
			RETURN;

		INSERT INTO master..tbMaxLSNLog
			SELECT DB_Name(DB_ID()), Min([Current LSN])
				FROM ::fn_dblog(null, null)
				WHERE Operation = N''LOP_DELETE_SPLIT''
					AND ParseName(AllocUnitName,3) <> ''sys''
	'

	SELECT * FROM tbMaxLSNLog

END