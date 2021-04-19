USE SIGERO_ADMIN_DIARIO
go
begin

	declare @pagina varchar(128) = '(1:50600:0)'
	declare @paginaid int = 50600

	select sys.fn_physlocformatter(%%physloc%% ) AS LOCAL_FISICO, * 
		from admin.usuario
		where sys.fn_physlocformatter(%%physloc%% ) = @pagina

	-- o id está no buffer...
	select * 
		from sys.dm_os_buffer_descriptors
		where page_id = @paginaid

end