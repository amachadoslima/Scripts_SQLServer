begin

	declare @range int
	declare @verbose bit

	set @range = 15
	set @verbose = 1

	set nocount on

	declare @topMissingIdxs table
	(
		id int identity,
		idx_advantage decimal(18,2),
		[db_schema_tbl] varchar(max),
		equality_columns varchar(max),
		inequality_columns varchar(max),
		user_seeks bigint,
		avg_total_user_cost decimal(18,2),
		avg_user_impact float,
		[tbl_name] varchar(max)	
	)
	
	declare @topQueries table
	(
		id int identity,
		missing_index_id int,
		[object_name] varchar(128),
		obj_type varchar(60),
		usecounts int,
		query_plan xml
	)
	
	declare @queriesMissingIdxs table 
	(
		[object_name] varchar(128),
		obj_type varchar(60),
		usecounts int,
		query_plan xml,
		query_plan_text varchar(max)
	)
	
	declare @xmlText varchar(max)
	declare @loopCounter int
	declare @equality varchar(180)
	declare @inequality varchar(180)
	declare @tableName varchar(128)
	declare @columnName varchar(80)
	declare @columnID bigint
	
	insert into @queriesMissingIdxs
		select
				object_name(objectid),
				cp.objtype,
				cp.usecounts,
				query_plan,
				cast(query_plan as varchar(max))
			from sys.dm_exec_cached_plans cp with(nolock)
				cross apply sys.dm_exec_query_plan(cp.plan_handle) qp
			where cast(query_plan as varchar(max)) like '%MissingIndex%'
				and dbid = db_id()
			option(recompile)
			
	insert into @topMissingIdxs
		select top (@range)
			convert(decimal(18, 2), user_seeks * avg_total_user_cost * (avg_user_impact * 0.01)) as idx_advantage,
			mid.[statement],
			mid.equality_columns,
			mid.inequality_columns,
			migs.user_seeks,
			convert(decimal(18,2), migs.avg_total_user_cost),
			migs.avg_user_impact,
			object_name(mid.[object_id])
		from sys.dm_db_missing_index_group_stats migs with(nolock)
			join sys.dm_db_missing_index_groups mig with(nolock) on migs.group_handle = mig.index_group_handle
			join sys.dm_db_missing_index_details mid with(nolock) on mig.index_handle = mid.index_handle
			join sys.partitions p with(nolock) on p.[object_id] = mid.[object_id]
		where mid.database_id = DB_ID()
			and p.index_id < 2 
		order by idx_advantage desc option(recompile)
	
	set @loopCounter = 0
	while(exists(select top 1 null from @topMissingIdxs where id > @loopCounter))
	begin

		select
				@loopCounter = id,
				@tableName = tbl_name,
				@equality = equality_columns,
				@inequality = inequality_columns
			from @topMissingIdxs
			where id = @loopCounter + 1

		set @xmlText = N'<MissingIndex Database="[' + DB_Name() + N']" Schema="[dbo]" Table="[' + @tableName + N']">'
		
		if(len(@equality) > 0)
		begin
			
			set @xmlText += N'<ColumnGroup Usage="EQUALITY">' 
			set @equality = replace(replace(replace(@equality, '[', ''), ']', ''), ' ', '')

			if charindex(',', @equality) = 0
				set @columnName = @equality
			else
                set @columnName = substring(@equality, 1, charindex(',', @equality) - 1)

			select @columnID = columnproperty(object_id(@tableName), @tableName, 'ColumnId')
			set @xmlText += N'<Column Name="[' + @columnName + N']" ColumnId="' + convert(varchar, @columnID) + N'"/>'

			while charindex(',', @equality) > 0
			begin

				set @equality = substring(@equality, charindex(',', @equality) + 1, len(@equality))

                if charindex(',', @equality) = 0
                begin
					set @columnName = @equality
				end
                else
					set @columnName = substring(@equality, 1, charindex(',', @equality) - 1)

				select @columnID = columnproperty(object_id(@tableName), @columnName, 'ColumnId')
                set @xmlText += N'<Column Name="[' + @columnName + N']" ColumnId="' + convert(varchar, @columnID) + N'"/>'
			end

			set @xmlText += N'</ColumnGroup>'
		end

		if(len(@inequality) > 0)
		begin

			set @xmlText += N'<ColumnGroup Usage="INEQUALITY">'
			set @inequality = replace(replace(replace(@inequality, '[', ''), ']', ''), ' ', '')

			if charindex(',', @inequality) = 0
				set @columnName = @inequality
			else
				set @columnName = substring(@inequality, 1, charindex(',', @inequality) - 1)

			select @columnID = columnproperty(object_id(@tableName), @columnName, 'ColumnId')
			set @xmlText += N'<Column Name="[' + @columnName + N']" ColumnId="' + convert(varchar, @columnID) + N'"/>'

			while(charindex(',', @inequality) > 0)
			begin

				set @inequality = substring(@inequality, charindex(',', @inequality) + 1, len(@inequality))

                if charindex(',', @inequality) = 0
					set @columnName = @inequality
				else
					set @columnName = substring(@inequality, 1, charindex(',', @inequality) - 1)

				select @columnID = columnproperty(object_id(@tableName), @columnName, 'ColumnId')
                set @xmlText += N'<Column Name="[' + @columnName + N']" ColumnId="' + convert(varchar, @columnID) + N'"/>'
				
			end

			set @xmlText += N'</ColumnGroup>'

		end

		if(@verbose = 1)
		begin
			print 'XML Text: '
			print '    ' + @xmlText
		end

        set @xmlText = replace(replace(@xmlText, '[', '#['), ']', '#]')

		insert into @topQueries 
			select
					@loopCounter,
					[object_name],
					obj_type,
					usecounts,
					query_plan
				from @queriesMissingIdxs
				where query_plan_text like N'%' + @xmlText + N'%' escape '#'

	end

	if(exists(select top 1 null from @topMissingIdxs))
	begin
		select *
			from @topMissingIdxs
			order by idx_advantage desc
	end

	if(exists(select top 1 null from @topQueries))
	begin
		select 
				missing_index_id, [object_name], obj_type, usecounts, query_plan 
			from @topQueries
			order by missing_index_id asc, usecounts desc    
	end

	set nocount off

end