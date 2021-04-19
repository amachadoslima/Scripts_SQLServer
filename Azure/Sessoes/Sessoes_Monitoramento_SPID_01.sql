set nocount on

declare @spid int = 154 
declare @db   int = 0

select @db = dbid from dbo.sysprocesses where spid = @spid;
dbcc inputbuffer(@spid) with no_infomsgs;
--dbcc outputbuffer(@spid) with no_infomsgs;
dbcc opentran(@db)  with no_infomsgs;	
exec sp_who2 @spid;
		
select * from dbo.sysprocesses where spid = @spid;
select b.login_name, b.host_name, a.reads, a.writes, f.transaction_status as [statustran], 
		db_name(e.dbid) as dbname,
		'['+object_schema_name(e.objectid, e.dbid) +'.'+object_name(e.objectid, e.dbid)+']' as object_name,
		f.transaction_begin_time as [initran], 
		(datediff(second, f.transaction_begin_time, getdate())) as [inisec],	
		e.text, d.query_plan,  database_transaction_log_record_count as qtd,
		case database_transaction_type
			when 1 then 'read/write' 
			when 2 then 'read-only' 
			when 3 then 'system' end as transtype,		
		case database_transaction_state
			when 1 then 'not been initialized' 
			when 3 then 'initialized without log records'
			when 4 then 'generated log records' 
			when 5 then 'begin tran' 
			when 10 then 'commit tran'
			when 11 then 'rollback tran' 
			when 12 then 'commit tran. the log record is being generated' end as transtate, *
	from sys.dm_exec_requests a
		join sys.dm_exec_sessions b on a.session_id = b.session_id
		left join sys.dm_tran_database_transactions c on a.transaction_id = c.transaction_id
		outer apply sys.dm_exec_query_plan (a.plan_handle) d
		outer apply sys.dm_exec_sql_text (a.sql_handle) e
		left join sys.dm_tran_active_transactions f on a.transaction_id = f.transaction_id
	where a.session_id = @spid;

set nocount off