use master 
go
begin
	
	-- esta query obt�m a soma total do volume de backups feitos por m�s!
	-- deve-se levantar o hist�rico a parte para identificar grandes diferen�as
	-- este m�s, foi necess�rio realizar backups a parte na base do Protheus, devido a migra��o
	-- e testes da migra��o, ocasionando uma soma maior

	set nocount on
	set quoted_identifier off

	declare @dbName sysname = 'SDBP12'
	declare @type varchar(1) = 'd' --d: full, l: log

	;with bkpSize as 
	(
		select top 100
				row_number() over(order by datepart(year, backup_start_date) asc, datepart(month, backup_start_date) asc) as rn,
				datepart(year, backup_start_date) as [year],
				datepart(month, backup_start_date) as [month],
				convert(decimal(10, 2), round(avg(backup_size / 1024. / 1024.), 4)) as bkp_size_mb,
				convert(decimal(10, 2), round(avg(compressed_backup_size / 1024. / 1024.), 4)) as compressed_bkp_size_mb,
				convert(decimal(10, 2), round(avg(backup_size / 1024. / 1024. / 1024.), 4)) as bkp_size_gb,
				convert(decimal(10, 2), round(avg(compressed_backup_size / 1024. / 1024. / 1024.), 4)) as compressed_bkp_size_gb
			from msdb.dbo.backupset
			where [database_name] = @dbName
				and lower([type]) = lower(@type)
				and backup_start_date between dateadd(mm, - 13, getdate()) and getdate()
			group by [database_name], datepart(year, backup_start_date), datepart(month, backup_start_date)
			order by [year], [month]
	)
	select
			bs1.[year],
			bs1.[month],
			bs1.bkp_size_gb,
			bs1.bkp_size_gb - bs3.bkp_size_gb as delta_normal,
			bs1.compressed_bkp_size_gb,
			bs1.compressed_bkp_size_gb - bs3.compressed_bkp_size_gb as delta_compressed
		from bkpSize bs1
			cross apply(
				select bs2.bkp_size_gb, bs2.compressed_bkp_size_gb
					from bkpSize bs2
					where bs2.rn = bs1.rn -1
			) as bs3
		order by bs1.[year] desc, bs1.[month] desc

end
