select
		reverse(substring(reverse([path]), charindex('\', reverse(path)), 256)) as default_trace_location,
		event_count, 
		start_time, 
		last_event_time
	from sys.traces
