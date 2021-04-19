USE SDBP12
GO
select 
		object_name(p.[object_id]) as blocked_obj, *
	from sys.dm_exec_connections c 
		join sys.dm_exec_requests r on c.session_id = r.blocking_session_id
		join sys.dm_os_waiting_tasks t on r.blocking_session_id = t.session_id
		left join sys.partitions p on substring(resource_description, patindex('%associatedObjectId%', resource_description) + 19, len(resource_description)) = cast(p.partition_id as varchar)

/*
--OBJECT: 7:2066106401:3 
declare @object varchar(max) = 'OBJECT: 7:2066106401:3'
declare @dbid int
declare @fileno bigint
declare @pageno bigint

if(@object like 'OBJECT: %')
begin
	set @object = rtrim(ltrim(replace(@object, 'OBJECT: ', '')))
	set @dbid = substring(@object, 0, charindex(':', @object))
	set @object = replace(@object, (substring(@object, 0, charindex(':', @object) + 1)), '')
	set @fileno = substring(@object, 0, charindex(':', @object))
	set @object = replace(@object, (substring(@object, 0, charindex(':', @object) + 1)), '')
	set @pageno = @object
	
	dbcc page(7, 2066106401, 3) with tableresults 
end
*/