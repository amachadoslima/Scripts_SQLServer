select 
		servicename, 
		startup_type_desc, 
		status_desc, 
		process_id, 
		last_startup_time, 
		service_account
	from sys.dm_server_services 
go
select 
		a.sqlserver_start_time as ini_instancia,
		a.cpu_count as cpu_logica,
		cast((a.physical_memory_in_bytes / 1024 / 1024 / 1024) as numeric(14,2)) as [memoria_win_gb],
		cast((b.available_physical_memory_kb /1024 / 1024 ) as numeric(14,2)) as memoria_disponivel_gb, 
		b.system_memory_state_desc as status_memoria,
		a.os_error_mode as erro_modo,
		case when a.os_priority_class = 32 then 'normal' when a.os_priority_class = 128 then 'alta' end as prioridade_processo,
		a.affinity_type_desc as afinidade_cpu,
		a.virtual_machine_type_desc as virtualizacao
	from sys.dm_os_sys_info a,
		 sys.dm_os_sys_memory b