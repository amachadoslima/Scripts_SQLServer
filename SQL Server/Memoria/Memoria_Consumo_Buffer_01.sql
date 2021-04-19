select 
		cast((physical_memory_in_use_kb / 1024. / 1024.) as decimal(10,2)) as mem_sqlserver_gb
	from sys.dm_os_process_memory