select 
		r.session_id as spid,
		(
			select top 1 ('select db_name(' + rtrim(ltrim(cast(item as varchar))) + ')') 
				from dbo.fnsplit(wait_resource, ':') 
		) as dbcmd,
		'dbcc page(' + replace(r.wait_resource, ':', ', ') + ')' as pgcmd
	from sys.dm_exec_sessions s 
       join sys.dm_exec_requests r on r.session_id = s.session_id 
       cross apply sys.dm_exec_sql_text(r.sql_handle) as st
	where r.session_id != @@spid  and isnull(r.wait_resource, '') <> '' and r.wait_resource <> '0:0:0'
	order by r.cpu_time desc 

/*
dbcc traceon(3604)
dbcc page(6, 1, 45185306)
dbcc traceoff(3604)
*/

/*
	
use dataunify
go
select 
	o.name as tablename, 
	i.name as indexname,
	schema_name(o.schema_id) as schemaname
from sys.partitions p join sys.objects o on p.object_id = o.object_id
join sys.indexes i on p.object_id = i.object_id  and p.index_id = i.index_id
where p.hobt_id = 72057594048610304 --(partitionid)

select t.name as tablename, ind.name as indexname, ind.index_id as indexid, ic.index_column_id as columnid, col.name as colname
	from sys.indexes ind
		join sys.index_columns ic on ind.object_id = ic.object_id and ind.index_id = ic.index_id
		join sys.columns col on ic.object_id = col.object_id and ic.column_id = col.column_id
		join sys.tables t on ind.object_id = t.object_id 
	where ind.is_primary_key = 0  and ind.is_unique = 0 and ind.is_unique_constraint = 0 
		and t.is_ms_shipped = 0 and ind.name = 'ix_du_pessoa'
	order by  t.name, ind.name, ind.index_id, ic.index_column_id
*/