use Dersa_N3
go

set transaction isolation level read uncommitted;

select	
		l.resource_type as restype,
		l.resource_description as resdescr,
		l.request_mode as reqmode,
		l.request_type as reqtype,
		l.request_status as reqstatus,
		l.request_owner_type as reqownertype,
		t.[name] as transname,
		t.transaction_begin_time as transbegin,
		datediff(ss, t.transaction_begin_time, getdate()) as transdura,
		s.session_id as s_id,
		s.login_name as loginname,
		coalesce(o.[name], ob.[name]) as objectname,
		i.[name] as indexname,
		s.[host_name] as hostname,
		s.[program_name] as programname 
	from sys.dm_tran_locks as l 
		join sys.dm_exec_sessions as s on l.request_session_id = s.session_id 
		left join sys.dm_tran_active_transactions as t on l.request_owner_id = t.transaction_id and l.request_owner_type = 'transaction' 
		left join sys.objects as o on l.resource_associated_entity_id = o.[object_id]  and l.resource_type = 'object' 
		left join sys.partitions as p on l.resource_associated_entity_id = p.hobt_id  and l.resource_type in ('page', 'key', 'rid', 'hobt') 
		left join sys.objects as ob on p.[object_id] = ob.[object_id] 
		left join sys.indexes as i on p.[object_id] = i.[object_id] and p.index_id = i.index_id 
	where l.resource_database_id = db_id()
		and s.session_id <> @@spid
		and l.request_mode <> 's'
	order by l.resource_type, l.request_mode, l.request_type, l.request_status, objectname, s.login_name