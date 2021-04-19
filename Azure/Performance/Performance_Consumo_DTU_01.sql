select    
		avg(avg_cpu_percent) as 'average cpu utilization in percent',   
		max(avg_cpu_percent) as 'maximum cpu utilization in percent',   
		avg(avg_data_io_percent) as 'average data io in percent',   
		max(avg_data_io_percent) as 'maximum data io in percent',   
		avg(avg_log_write_percent) as 'average log write i/o throughput utilization in percent',   
		max(avg_log_write_percent) as 'maximum log write i/o throughput utilization in percent',   
		avg(avg_memory_usage_percent) as 'average memory usage in percent',   
		max(avg_memory_usage_percent) as 'maximum memory usage in percent'   
	from sys.dm_db_resource_stats;