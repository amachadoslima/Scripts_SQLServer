select distinct 
		b.logical_volume_name as logical_name,
		b.volume_mount_point as drive, 
		convert(decimal(10,2), b.total_bytes /1073741824.0) as total_gb, 
		(convert(decimal(10,2), b.total_bytes /1073741824.0)) - (convert(decimal(10,2), b.available_bytes/1073741824.0)) as used_gb,
		convert(decimal(10,2), b.available_bytes/1073741824.0) as free_gb
	from sys.master_files a
		cross apply sys.dm_os_volume_stats(a.database_id, a.file_id) b
	order by drive asc