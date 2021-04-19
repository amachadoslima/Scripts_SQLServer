use master 
go
if(object_id(N'tempdb..##tmpWhoIsActive') is not null)
	drop table ##tmpWhoIsActive 
if(object_id(N'tempdb..##tmpWhoIsActiveF') is not null)
	drop table ##tmpWhoIsActiveF
go

set nocount on;
set ansi_warnings off;

begin

	--declare @tempsec int
	declare @perSec varchar(max)
	declare @delayW char(8)
	declare @maximoSec int = (3 * 60)
	declare @delay int = 1
	declare @dteIni datetime = getdate()
	declare @qtd int = 0
	declare @schemaTable varchar(max)
	declare @bar varchar(100)
	declare @bkpCnt bit = 0

	declare @sqlTemp varchar(max)
	declare @sqlInsert varchar(max) 
	declare @sqlLine varchar(max) 
	declare @columnName varchar(100)
	declare @columnType varchar(100)
	declare @qtdColumns int = 1

	declare @columns table
	(
		columnname	varchar(100),
		columntype	varchar(100)
	)

	set @delayW = '00:00:' + replicate('0', 2 - len(@delay)) + rtrim(@delay)

	-----------------------------------------------------------------------------------------------------------------------
	-- cria tabela temporária de acordo com o schema retornado pelo sp_whoisactive
	-----------------------------------------------------------------------------------------------------------------------
	exec sp_WhoIsActive
			@filter = '',
			@filter_type = 'session',
			@not_filter = '',
			@not_filter_type = 'session',
			@show_own_spid = 0,
			@show_system_spids = 0,
			@show_sleeping_spids = 1,
			@get_full_inner_text = 0,
			@get_plans = 1,
			@get_outer_command = 1,
			@get_transaction_info = 1,
			@get_task_info = 1,
			@get_locks = 1,
			@get_avg_time = 1,
			@get_additional_info = 0, --@get_additional_info = 1,
			@find_block_leaders = 1,
			@delta_interval = 0,
			@output_column_list = '[dd%][session_id][sql_text][sql_command][login_name][wait_info][tasks][tran_log%][cpu%][temp%][block%][reads%][writes%][context%][physical%][query_plan][locks][%]',
			@sort_order = '[start_time] asc',
			@format_output = 2,
			@destination_table = '',
			@return_schema = 1,
			@schema = @schemaTable output,
			@help = 0;

	if(@schemaTable is null)
		return

	set @schemaTable = replace(@schemaTable, '<table_name>', '##tmpWhoIsActive')
	exec (@schemaTable)

	----------------------------------------------------------------------------------------------------------------
	-- como todo processo é dinâmico, a tabela final também será realizada de forma dinâmica!
	-- neste trecho, é feito uma leitura de todas as colunas das tabelas, e aqui é montado os scripts de 
	-- inserção na tabela final, além dos "breaks lines"
	----------------------------------------------------------------------------------------------------------------

	declare curcolumns cursor for
		select c.[name], t.[name]
			from tempdb.sys.columns c
				join tempdb.sys.types t on c.user_type_id = t.user_type_id
			where object_id = object_id('tempdb..##tmpWhoIsActive')

	open curcolumns
	fetch next from curcolumns into @columnName, @columnType

	-- campo id auto númerico por comodidade...
	set @sqlTemp = 'create table ##tmpWhoIsActiveF
	(
		[id] int identity(1,1),'

	set @sqlInsert = 'insert into ##tmpWhoIsActiveF 
	select '

	while(@@fetch_status = 0)
	begin

		if(lower(@columnType) = 'xml')
		begin
			set @sqlInsert = @sqlInsert + '[' + @columnName + '],'
			set @sqlTemp = @sqlTemp + '
		[' + @columnName + '] xml, '
		end
		else 
		begin

			if(lower(@columnType) = 'datetime')
				set @sqlInsert = @sqlInsert + 'convert(varchar(23), [' + @columnName + '], 121),' 
			else
				set @sqlInsert = @sqlInsert + 'rtrim(ltrim([' + @columnName + '])),'

			set @sqlTemp = @sqlTemp + '
		[' + @columnName + '] varchar(max), '
		end

		set @qtdColumns = @qtdColumns + 1
		insert into @columns values(@columnName, @columnType)
		fetch next from curcolumns into @columnName, @columnType

	end

	close curcolumns
	deallocate curcolumns

	set @sqlTemp = substring(@sqlTemp, 0, len(@sqlTemp))
	set @sqlTemp = @sqlTemp +
	'
	);'

	set @sqlInsert = substring(@sqlInsert, 0, len(@sqlInsert))
	set @sqlInsert = @sqlInsert + '
		from ##tmpWhoIsActive;'

	set @sqlLine = 'insert into  ##tmpWhoIsActiveF
	values (' + replicate('''------'',', @qtdColumns - 1)
	set @sqlLine = substring(@sqlLine, 0, len(@sqlLine)) + ');'

	begin try
		exec (@sqlTemp)
	end try
	begin catch
		select error_number() as err_num, error_message() as err_msg
		return
	end catch

	while(datediff(second, @dteIni, getdate()) <= @maximoSec)
	begin
	
		delete from ##tmpWhoIsActive
		set @qtd = 0

		exec sp_WhoIsActive
			@filter = '',
			@filter_type = 'session',
			@not_filter = '',
			@not_filter_type = 'session',
			@show_own_spid = 0,
			@show_system_spids = 0,
			@show_sleeping_spids = 1,
			@get_full_inner_text = 0,
			@get_plans = 1,
			@get_outer_command = 1,
			@get_transaction_info = 1,
			@get_task_info = 1,
			@get_locks = 1,
			@get_avg_time = 1,
			@get_additional_info = 0, --@get_additional_info = 1,
			@find_block_leaders = 1,
			@delta_interval = 0,
			@output_column_list = '[dd%][session_id][sql_text][sql_command][login_name][wait_info][tasks][tran_log%][cpu%][temp%][block%][reads%][writes%][context%][physical%][query_plan][locks][%]',
			@sort_order = '[start_time] asc',
			@format_output = 2,
			@destination_table = '##tmpWhoIsActive',
			@return_schema = 0,
			@schema = null,
			@help = 0;

		if(@bkpCnt = 0)
		begin
			--delete from ##tmpWhoIsActive 
			--	where (cast(sql_text as varchar(max)) like '%BACKUP DATABASE%' or cast(sql_text as varchar(max)) like '%EXEC SP_BACKUP%' or isnull(cast(sql_text as varchar(max)), '') = '')
			delete from ##tmpWhoIsActive where cast(sql_text as varchar(max)) like '%BACKUP LOG%'
			delete from ##tmpWhoIsActive where cast(sql_text as varchar(max)) like '%EXEC SP_BACKUP%'
			delete from ##tmpWhoIsActive where cast(sql_text as varchar(max)) like '%BACKUP DATABASE%'
			delete from ##tmpWhoIsActive where cast(sql_text as varchar(max)) like '%RESTORE VERIFYONLY%'
			delete from ##tmpWhoIsActive where cast(sql_command as varchar(max)) like '%DBA.STP_MONITORING_DERSAN3%'
		end

		delete from ##tmpWhoIsActive where isnull(cast(sql_text as varchar(max)), '') = ''

		select @qtd = count(*) from ##tmpWhoIsActive

		if(@qtd > 0)
		begin
			begin try
				exec (@sqlInsert);
				exec (@sqlLine);
			end try
			begin catch
				select error_number() as err_num, error_message() as err_msg
				break
			end catch
		end

		--set @tempsec = (@maximoSec - datediff(second, @dteIni, getdate())) 
		--raiserror('>>>>>>>>>>> faltam %s segundos para finalizar...', 0, 1, @perSec) with nowait;

		set @perSec = cast(cast(cast(datediff(second, @dteIni, getdate()) as decimal(10, 2)) / cast(@maximoSec as decimal(10, 2)) * 100 as decimal(10,2)) as varchar)
		raiserror('%s%% percent completed...', 0, 1, @perSec) with nowait;

		declare @aux int = cast(substring(@perSec, 0, charindex('.', @perSec)) as int)
		if(@aux = 0)
			set @aux = 1
		else
			set @aux = @aux + 1

		set @bar = replicate('*', @aux)
		raiserror('%s', 0, 1, @bar) with nowait;

		waitfor delay @delayW

	end

	print ''
	print '------ TABELA INICIAL ------'
	print @schemaTable
	print '------ TABELA TEMPORARIA ------'
	print @sqlTemp
	print '------ INSERCAO FINAL ------'
	print @sqlInsert
	print '------ INSERCAO LINHAS ------'
	print @sqlLine

	delete from ##tmpWhoIsActiveF where id = (select max(id) from ##tmpWhoIsActiveF where isnull([session_id], '------') = '------')
	select * from ##tmpWhoIsActiveF order by id

end


go

if(object_id(N'tempdb..##tmpWhoIsActive') is not null)
	drop table ##tmpWhoIsActive 
if(object_id(N'tempdb..##tmpWhoIsActiveF') is not null)
	drop table ##tmpWhoIsActiveF