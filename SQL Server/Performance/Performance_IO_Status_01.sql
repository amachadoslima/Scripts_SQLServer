set nocount on
set transaction isolation level read uncommitted

select db_name(database_id) as [db_name],
		file_id,
		io_stall_read_ms,
		num_of_reads,
		cast(io_stall_read_ms / (1.0 + num_of_reads) as numeric(10, 1)) as [avg_read_stall_ms],
		io_stall_write_ms,
		num_of_writes,
		cast(io_stall_write_ms / (1.0 + num_of_writes) as numeric(10, 1)) as [avg_write_stall_ms],
		io_stall_read_ms + io_stall_write_ms as [io_stalls],
		num_of_reads + num_of_writes as [total_io],
		cast((io_stall_read_ms + io_stall_write_ms) / (1.0 + num_of_reads + num_of_writes) as numeric(10, 1)) as [avg_io_stall_ms]
	from sys.dm_io_virtual_file_stats(null, null)
	order by case when db_name(database_id) = db_name() then 0 else 1 end, (io_stall_read_ms + io_stall_write_ms) / (1.0 + num_of_reads + num_of_writes) desc