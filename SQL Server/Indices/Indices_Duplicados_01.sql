;with idxduplicate as (
	select
			'['+s.[name]+'].['+o.[name]+']' as table_name,
			i.[name] as index_name,
			index_col(s.[name] + '.' + o.[name], i.index_id, 1) as col1,
			index_col(s.[name] + '.' + o.[name], i.index_id, 2) as col2,
			index_col(s.[name] + '.' + o.[name], i.index_id, 3) as col3,
			index_col(s.[name] + '.' + o.[name], i.index_id, 4) as col4,
			index_col(s.[name] + '.' + o.[name], i.index_id, 5) as col5,
			index_col(s.[name] + '.' + o.[name], i.index_id, 6) as col6,
			index_col(s.[name] + '.' + o.[name], i.index_id, 7) as col7,
			index_col(s.[name] + '.' + o.[name], i.index_id, 8) as col8,
			index_col(s.[name] + '.' + o.[name], i.index_id, 9) as col9,
			index_col(s.[name] + '.' + o.[name], i.index_id, 10) as col10,
			index_col(s.[name] + '.' + o.[name], i.index_id, 11) as col11,
			index_col(s.[name] + '.' + o.[name], i.index_id, 12) as col12,
			index_col(s.[name] + '.' + o.[name], i.index_id, 13) as col13,
			index_col(s.[name] + '.' + o.[name], i.index_id, 14) as col14,
			index_col(s.[name] + '.' + o.[name], i.index_id, 15) as col15,
			index_col(s.[name] + '.' + o.[name], i.index_id, 16) as col16
		from sys.indexes i
			join sys.objects o on i.[object_id] = o.[object_id] 
			join sys.schemas s on s.[schema_id] = o.[schema_id] 
		where index_id > 0
)
select    
		md1.table_name, md1.index_name,
		md2.index_name as overlappingindex,
		md1.col1, md1.col2, md1.col3, md1.col4,
		md1.col5, md1.col6, md1.col7, md1.col8,
		md1.col9, md1.col10, md1.col11, md1.col12,
		md1.col13, md1.col14, md1.col15, md1.col16
	from idxduplicate md1
		join idxduplicate md2 on md1.table_name = md2.table_name
		and md1.index_name <> md2.index_name
		and md1.col1 = md2.col1
		and (md1.col2 is null or md2.col2 is null or md1.col2 = md2.col2)
		and (md1.col3 is null or md2.col3 is null or md1.col3 = md2.col3)
		and (md1.col4 is null or md2.col4 is null or md1.col4 = md2.col4)
		and (md1.col5 is null or md2.col5 is null or md1.col5 = md2.col5)
		and (md1.col6 is null or md2.col6 is null or md1.col6 = md2.col6)
		and (md1.col7 is null or md2.col7 is null or md1.col7 = md2.col7)
		and (md1.col8 is null or md2.col8 is null or md1.col8 = md2.col8)
		and (md1.col9 is null or md2.col9 is null or md1.col9 = md2.col9)
		and (md1.col10 is null or md2.col10 is null or md1.col10 = md2.col10)
		and (md1.col11 is null or md2.col11 is null or md1.col11 = md2.col11)
		and (md1.col12 is null or md2.col12 is null or md1.col12 = md2.col12)
		and (md1.col13 is null or md2.col13 is null or md1.col13 = md2.col13)
		and (md1.col14 is null or md2.col14 is null or md1.col14 = md2.col14)
		and (md1.col15 is null or md2.col15 is null or md1.col15 = md2.col15)
		and (md1.col16 is null or md2.col16 is null or md1.col16 = md2.col16)
	order by md1.table_name, md1.index_name