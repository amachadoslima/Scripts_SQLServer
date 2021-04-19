select 
		id, 
		[status], 
		[path], 
		is_rowset, 
		event_count 
	from sys.traces
	where isnull([path], '') <> ''