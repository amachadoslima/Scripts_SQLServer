use master 
go
set nocount on
go

declare @irows int

declare @tbonline table
(	
	 database_id	int
	,[name]			char(30)
	,user_acess		tinyint
	,[state]		tinyint
	,state_desc		char(40)
	,recovery_model	tinyint
)

/************************************************************************************************
	VERIFICA SE TODOS OS DATABASES EST�O COM O STATUS ONLINE.									*
	ESTA OP��O DEVE ESTAR COMO ONLINE! QUANDO ESTA OP��O DIFERENTE DE ONLINE, SIGNIFICA QUE		*
	O DATABASE EST� OFFLINE E N�O EST� ACESS�VEL PARA A APLICA��O E OS USU�RIOS.				*
*************************************************************************************************/

insert into @tbonline 
	select	
			database_id,
			[name],
			user_access,
			[state],
			state_desc,
			recovery_model
		from sys.databases 
		where [state] <> 0

select @irows = @@rowcount

if (@irows = 0)
begin
	print 'Todos databases com Status ONLINE: OK!'
end
else begin
	print ''
	PRINT 'CRITICAL: ' + ltrim(rtrim(convert(char(2), @irows))) + ' com Status diferente de ONLINE!'
	select * from @tbonline
	print ''
end

set @irows = 0
delete from @tbonline

/************************************************************************************************
	VERIFICA SE TODOS OS DATABASES EST�O COM O USER_ACCESS COMO MULTI_USER.						*
	QUANDO ESTA OP��O EST� DIFERENTE DE MULTI_USER, SIGNIFICA QUE SOMENTE UM USU�RIO			*
	PODE SE CONECTAR NO DATABASE.																*
*************************************************************************************************/

insert into @tbonline 
	select
			database_id,
			[name],
			user_access,
			[state],
			state_desc,
			recovery_model
		from sys.databases 
		where user_access <> 0

select @irows = @@rowcount

if (@irows = 0)
begin
	print 'Todos databases com User_Access MULT_USER: OK!'
end
else begin
	print ''
	print 'CRITICAL: ' + ltrim(rtrim(convert(char(2), @irows)))  + ' com User_Access diferente de MULT_USER!'
	select * from @tbonline
	print ''
end

/************************************************************************************************
	VERIFICA SE TODOS OS DATABASES EST�O COM O IS_AUTO_CLOSE_ON DESABILITADO (OFF).				*
	ESTA OP��O DEVE ESTAR COMO OFF! QUANDO ESTA OP��O EST� HABILITADA (ON), SIGNIFICA QUE		*
	OS ARQUIVOS DE DADOS (.MDF E .LDF) PODEM SER COPIADOS, APAGADOS, ETC. SEM QUE OS PROCESSOS	*
	DO SQL SERVER ESTEJAM PARADOS.																*
*************************************************************************************************/

set @irows = 0
delete from @tbonline

insert into @tbonline 
	select
			database_id,
			[name],
			user_access,
			[state],
			state_desc,
			recovery_model
		from sys.databases 
		where is_auto_close_on <> 0

select @irows = @@rowcount

if (@irows = 0)
begin
	print 'Todos databases com Is_Auto_Close_On OFFLINE: OK!'
end
else begin
	print ''
	print 'CRITICAL: ' + ltrim(rtrim(convert(char(2), @irows)))  + ' com Is_Auto_Close_On diferente de OFFLINE!'
	select * from @tbonline
	print ''
end

/************************************************************************************************
	VERIFICA SE TODOS OS DATABASES EST�O COM O IS_AUTO_SHRINK_ON DESABILITADO (OFF).			*
	ESTA OP��O DEVE ESTAR COMO OFF! QUANDO ESTA OP��O EST� HABILITADA (ON), SIGNIFICA QUE		*
	ELE SEMPRE FAR� UM AUTO SHRINK PARA N�O DEIXAR OS ARQUIVOS DE LOG CRESCEREM RAPIDAMENTE		*
*************************************************************************************************/

set @irows = 0
delete from @tbonline

insert into @tbonline 
	select
			database_id,
			[name],
			user_access,
			[state],
			state_desc,
			recovery_model
		from sys.databases 
		where is_auto_shrink_on <> 0

select @irows = @@rowcount

if (@irows = 0)
begin
	print 'Todos databases com Is_Auto_Shrink_On OFFLINE: OK!'
end
else begin
	print ''
	print 'CRITICAL: ' + convert(char, ltrim(rtrim(@irows))) + ' com Is_Auto_Shrink_On diferente de OFFLINE!'
	select * from @tbonline
	print ''
end