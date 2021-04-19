select	
		t.[name] as table_name, 
		i.[rows] as records
	from sysobjects t, 
		 sysindexes i
	where lower(t.xtype) = 'u' and i.id = t.id and i.indid in (0,1)
	order by table_name asc