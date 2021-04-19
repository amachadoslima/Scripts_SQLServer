declare @top int
set @top = 10


declare @results	table
(
	database_id			int,
	objectname			sysname null,
	indexname			sysname null,
	cache_kb			bigint,
	free_bytes			bigint,
	size_kb				bigint null,
	[filegroup]			sysname null,
	indid				int null,
	dirty_kb			bigint null,
	[schema_name]		sysname	null,
	[user_name]			sysname	null
)


declare	@databases table
(	
	database_id			int,
	[name]				sysname null,
	id					int identity
)


insert into @databases (database_id, [name])
	select	database_id, [name]
		from sys.databases
		where user_access <> 1		-- not single user
			and	[state] = 0               -- online
			and	has_dbaccess([name]) <> 0	-- have access.


declare	@nbuffersize bigint

select	@nbuffersize = count(*)
	from sys.dm_os_buffer_descriptors with (readpast)

declare @sql nvarchar(max)
declare @n int
declare @db int

set	@n = 1
set	@db = 0


while(1=1)
begin

	set @db = null

	select @db = database_id 
		from @databases 
		where id = @n

	set @n = @n + 1

	if @db is null
		break

	if @db = 0x7fff	-- skip this one.
		continue


	set @sql = 'use ' + quotename(db_name(@db))	+	
	'select db_id() database_id,	
		isnull(o.[name],''<in-memory-resource>'') as [object_name],
		isnull(i.[name],'''') as index_name,
		cast(8 * sum(cast(b.cache_pages as bigint)) as bigint) as cache_kb,
		sum(cast(b.free_bytes as bigint)) as free_bytes,
		cast(8 * sum(cast(a.total_pages as bigint)) as bigint) as used_kb,
		(select top 1 [name] from sys.filegroups fg with (readpast) where fg.data_space_id = a.data_space_id) as [filegroup],
		min(i.index_id)	as indid,
		cast(8 * sum(cast(b.dirty_pages as bigint)) as bigint) as dirty_kb,
		min(s.[name])	as [schema_name],
		min(u.[name]) as [user_name]
	from(
			select	a.database_id, allocation_unit_id, count(*) cache_pages, sum(cast(free_space_in_bytes as bigint)) free_bytes, sum(case when is_modified=1 then 1 else 0 end) dirty_pages
				from sys.dm_os_buffer_descriptors a with (readpast) 
				where a.database_id = db_id()
				group by a.database_id,allocation_unit_id
		)	b
		left outer join	sys.allocation_units a with (readpast) on b.allocation_unit_id = a.allocation_unit_id
		left outer join	sys.partitions p with (readpast) on	(a.container_id = p.hobt_id and a.[type] in (1,3)) or	(a.container_id = p.[partition_id] and a.[type] = 2)
		left outer join sys.objects	o with (readpast) on p.object_id = o.object_id 
		left outer join sys.indexes	i with (readpast) on p.object_id = i.object_id  and p.index_id = i.index_id
		left outer join sys.schemas	s with (readpast) on o.schema_id = s.schema_id
		left outer join	sys.database_principals u with (readpast) on s.principal_id = u.principal_id
	where database_id = db_id()
		and a.data_space_id is not null
	group by a.data_space_id, isnull(o.name,''<in-memory-resource>''), isnull(i.name,'''')
	option (keepfixed plan)'


	insert into @results(database_id, objectname, indexname, cache_kb, free_bytes, size_kb,	[filegroup], indid,	dirty_kb, [schema_name], [user_name])
		exec(@sql)

end


insert into @results (database_id, [schema_name], [user_name], cache_kb, free_bytes, dirty_kb)
	select	
			a.database_id, 
			'system', 
			'system',	
			(8 * count(*)) as cache_pages, 
			sum(free_space_in_bytes) free_bytes,	
			(sum(case when is_modified=1 then 1 else 0 end) * 8) as dirty_pages
		from sys.dm_os_buffer_descriptors a with (readpast)
		where a.database_id = 0x7fff
		group by a.database_id
		option (keepfixed plan)

set rowcount @top
set nocount off

select	
		[db_name], 
		tb_owner,
		tb_name,
		ix_name,	
		size_in_cache_kb,	
		case when percentage_of_cache > 100 then 100 when percentage_of_cache < 0 then 0 else percentage_of_cache end percentage_of_cache, 
		object_size_kb,	
		case when percentage_of_object > 100 then 100 when percentage_of_object < 0 then 0 else percentage_of_object end percentage_of_object,	
		[file_group], 
		indid, 
		dirty_kb,	
		case when percentage_object_dirty > 100 then 100 when percentage_object_dirty < 0 then 0 else percentage_object_dirty end percentage_object_dirty, 
		allocate_cache_unused_kb
	from(
		select	
				case when database_id = 0x7fff then 'mssqlsystemresource' else db_name(database_id) end	[db_name],	
				isnull([user_name],'system') as tb_owner, 
				objectname as tb_name, 
				indexname as ix_name, 
				cache_kb as size_in_cache_kb, 
				case when @nbuffersize = 0 then 0.0 else 100 * (cache_kb / 8.) / @nbuffersize end as percentage_of_cache, 
				size_kb as object_size_kb,
				case when size_kb = 0 then 0.0 else ((cache_kb * 1.) * 100.0) / size_kb end	percentage_of_object,	
				[filegroup] as [file_group], 
				indid, 
				dirty_kb as dirty_kb, 
				case when size_kb = 0 then 0.0 else (dirty_kb * 100.0 / size_kb) end as percentage_object_dirty,
				(free_bytes/1024.) as allocate_cache_unused_kb
		from @results
	)	x
	order by percentage_of_cache desc


set rowcount 0