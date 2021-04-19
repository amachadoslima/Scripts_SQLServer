USE master 
GO
if(object_id(N'tempdb..##tmpWhoIsActive') is not null)
	drop table ##tmpWhoIsActive 
GO

/*
	POR ALGUM MOTIVO, NO "N3 - OPEN ROAD", AO UTILIZAR O "get_additional_info" GERA
	UM EXCPETION DE NÍVEL CRÍTICO. ESTE EXCPETION ESTÁ RELACIONADO A MEMÓRIA... POR CONTA DISSO, POR HORA,
	ISSO ESTÁ DESABILITADO ATÉ QUE SEJA ENCONTRADO UMA SOLUÇÃO PARA ESTE PROBLEMA.
*/

set nocount on

declare @delayw char(8)
declare @maximosec int = (5 * 60)
declare @delay int = 1
declare @dteini datetime = getdate()
declare @qtd int = 0
declare @schematable varchar(max)

set @delayw = '00:00:' + replicate('0', 2 - len(@delay)) + rtrim(@delay)

declare @WhoIsActive table
( 
	[id] int identity(1,1),
	[dd hh:mm:ss.mss] varchar(8000) null,
	[session_id] varchar(100) null,
	[sql_text] xml null,
	[sql_command] xml null,
	[login_name] varchar(100) null,
	[wait_info] varchar(4000) null,
	[tran_log_writes] varchar(4000) null,
	[cpu] varchar(30) null,
	[tempdb_allocations] varchar(30) null,
	[tempdb_current] varchar(30) null,
	[blocked_session_count] varchar(100) null,
	[blocking_session_id] varchar(100) null,
	[reads] varchar(100) null,
	[writes] varchar(100) null,
	[physical_reads] varchar(100) null,
	[query_plan] xml null,
	[locks] xml null,
	[used_memory] varchar(100) null,
	[status] varchar(100) null,
	[tran_start_time] varchar(100) null,
	[open_tran_count] varchar(100) null,
	[percent_complete] varchar(100) null,
	[host_name] varchar(128) null,
	[database_name] varchar(128) null,
	[program_name] varchar(128) null,
	[start_time] varchar(100) null,
	[login_time] varchar(100) null,
	[request_id] varchar(100) null,
	[collection_time] varchar(100) null
)

-----------------------------------------------------------------------------------------------------------------------
-- Cria tabela temporária de acordo com o schema retornado pelo sp_WhoIsActive
-----------------------------------------------------------------------------------------------------------------------
exec sp_WhoIsActive
		@filter = '',
		@filter_type = 'session',
		@not_filter = '',
		@not_filter_type = 'session',
		@show_own_spid = 0,
		@show_system_spids = 0,
		@show_sleeping_spids = 0,
		@get_full_inner_text = 0,
		@get_plans = 1,
		@get_outer_command = 1,
		@get_transaction_info = 1,
		@get_task_info = 1,
		@get_locks = 1,
		@get_avg_time = 0,
		@get_additional_info = 0, --@get_additional_info = 1,
		@find_block_leaders = 1,
		@delta_interval = 0,
		@output_column_list = '[dd%][session_id][sql_text][sql_command][login_name][wait_info][tasks][tran_log%][cpu%][temp%][block%][reads%][writes%][context%][physical%][query_plan][locks][%]',
		@sort_order = '[start_time] asc',
		@format_output = 2,
		@destination_table = '##tmpWhoIsActive',
		@return_schema = 1,
		@schema = @schematable output,
		@help = 0;

if(@schematable is null)
	return

set @schematable = replace(@schematable, '<table_name>', '##tmpWhoIsActive')
exec (@schematable)


while(datediff(second, @dteini, getdate()) <= @maximosec)
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
		@show_sleeping_spids = 0,
		@get_full_inner_text = 0,
		@get_plans = 1,
		@get_outer_command = 1,
		@get_transaction_info = 1,
		@get_task_info = 1,
		@get_locks = 1,
		@get_avg_time = 0,
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

	select @qtd = count(*) from ##tmpWhoIsActive

	if(@qtd > 0)
	begin

		begin try
			insert into @WhoIsActive
				select --convert(varchar(23), getdate(), 121), 
					rtrim(ltrim([dd hh:mm:ss.mss])), rtrim(ltrim([session_id])), [sql_text], [sql_command], rtrim(ltrim([login_name])), 
					rtrim(ltrim([wait_info])), rtrim(ltrim([tran_log_writes])), rtrim(ltrim([cpu])), rtrim(ltrim([tempdb_allocations])), 
					rtrim(ltrim([tempdb_current])), rtrim(ltrim([blocking_session_id])), rtrim(ltrim([blocked_session_count])), rtrim(ltrim([reads])), 
					rtrim(ltrim([writes])), rtrim(ltrim([physical_reads])), [query_plan], [locks], rtrim(ltrim([used_memory])),
					rtrim(ltrim([status])), rtrim(ltrim(convert(varchar(23), [tran_start_time], 121))), rtrim(ltrim([open_tran_count])), 
					rtrim(ltrim([percent_complete])), rtrim(ltrim([host_name])), rtrim(ltrim([database_name])), rtrim(ltrim([program_name])), --[additional_info],
					rtrim(ltrim(convert(varchar(23), [start_time], 121))), 
					rtrim(ltrim(convert(varchar(23), [login_time], 121))), rtrim(ltrim([request_id])), 
					rtrim(ltrim(convert(varchar(23), [collection_time], 121)))
				from ##tmpWhoIsActive

			insert into @WhoIsActive
				values('------', '------', '------', '------', '------', '------', '------', '------', '------', '------', 
					'------', '------', '------', '------', '------', '------', '------', '------', '------', '------', 
					'------', '------', '------', '------', '------', '------', '------', '------', '------')
		end try
		begin catch
			select error_number() as err_num, error_message() as err_msg
			break
		end catch
	end

	waitfor delay @delayw

end

delete from @WhoIsActive where id = (select max(id) from @WhoIsActive where isnull([session_id], '------') = '------')
select * from @WhoIsActive order by id

GO
if(object_id(N'tempdb..##tmpWhoIsActive') is not null)
	drop table ##tmpWhoIsActive 
go