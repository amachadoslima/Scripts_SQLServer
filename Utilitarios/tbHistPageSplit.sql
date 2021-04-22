USE [master]
GO
BEGIN

	SET NOCOUNT ON

	If(Object_ID(N'tbHistPageSplit') IS NULL)
	Begin

		-- Cria tabela
		CREATE TABLE tbHistPageSplit
		(
			ID INT IDENTITY(1,1),
			DBName VARCHAR(40),
			NomeTabela VARCHAR(100),
			NomeIndice VARCHAR(300),
			DataHora DATETIME DEFAULT(getdate()),
			QtdPageSplit INT,
			CONSTRAINT PK_tbHistPageSplit PRIMARY KEY(ID)
		)

	End

	-- Remove os dados caso o objeto já exista na base de dados
	DELETE FROM tbHistPageSplit

END