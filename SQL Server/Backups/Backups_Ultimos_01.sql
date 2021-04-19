use master 
go
set nocount on
set quoted_identifier off
go

declare @server varchar(40)

set @server = convert(varchar(35), serverproperty('machinename')) + '\' + @@servicename

begin try

	select 
			@server as servidor_instancia,
			isnull(a.[database_name], null) as [database_name],
			isnull(datediff(day, a.backup_finish_date, getdate()), 0) as full_dias,
			isnull(a.backup_finish_date, '1900-01-01')  as full_termino,
			convert(char,convert(numeric(12,2),(a.backup_size / 1024 / 1024))) as full_tamanho_mb,
			isnull(datediff(day, c.backup_finish_date, getdate()), 0) as diff_dias,
			isnull(c.backup_finish_date, '1900-01-01')  as diff_termino,
			case when c.backup_finish_date is null then '0'else isnull(datediff(day, a.backup_finish_date, c.backup_finish_date), 0) end as dias_full_diff,
			isnull(convert(char,convert(numeric(12,2),(c.backup_size / 1024 / 1024))), 0) as diff_tamanho_mb,
			isnull(datediff(minute, b.backup_finish_date, getdate()), 0) as tran_minutos,
			isnull(b.backup_finish_date, '1900-01-01') as tran_termino,
			isnull(convert(char,convert(numeric(12,2),(b.backup_size / 1024 / 1024))), 0) as tran_tamanho_mb
		from msdb.dbo.backupset as a
			left outer join msdb.dbo.backupset as b on b.[database_name] = a.[database_name] and b.[type] = 'l'
				and b.backup_finish_date =
				(
					(select	max(backup_finish_date) 
						from msdb.dbo.backupset x
						where x.[database_name] = a.[database_name] 
							and lower(x.[type]) = 'l')
				)
			left outer join msdb.dbo.backupset as c on c.[database_name] = a.[database_name] and lower(c.[type]) = 'i'
				and c.backup_finish_date =
				(
					(select max(backup_finish_date) 
						from msdb.dbo.backupset x 
						where x.[database_name] = a.[database_name] 
							and lower(x.[type]) = 'i')
				)
		where lower(a.[type]) = 'd' -- full backups only
			and a.backup_finish_date = 
			(
				select max(backup_finish_date) 
					from msdb.dbo.backupset x 
				where x.[database_name] = a.[database_name]  
					and lower(x.[type]) = 'd'
			)
				and	a.[database_name] in (select [name] from sys.databases where [state] <> 6) 
				and	lower(a.[database_name]) not in ('tempdb','pubs','northwind','model')
union all

	select
		 @server, [name], 0, '1900-01-01', '0', 0, 0, 0, '0', 0, 0, 0
			from master.dbo.sysdatabases as record
			where [name] not in(select distinct [database_name] from msdb.dbo.backupset)
				and lower([name]) not in('tempdb','pubs','northwind','model')
		order by 1, 2

end try
begin catch
	select error_number() as err_num, error_message() as err_msg
end catch
