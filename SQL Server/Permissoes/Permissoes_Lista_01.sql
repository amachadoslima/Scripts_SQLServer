-- logins e regras (nível servidor)
select	
		sp.[name] as login_name,
		sp.[type_desc] as [login_type],
		sp.default_database_name as default_dbname,
		slog.sysadmin,
		slog.securityadmin,
		slog.serveradmin, 
		slog.setupadmin,
		slog.processadmin,
		slog.diskadmin,
		slog.dbcreator,
		slog.bulkadmin
	from sys.server_principals sp  
		join master..syslogins slog on sp.[sid] = slog.[sid]
	where sp.[type]  <> 'r' 
		and sp.[name] not like '##%'
	order by sp.[sid] asc

-- logins e regras (nível database)
declare @sql varchar(4000) 
declare @dbuser table 
(
	[db_name] sysname, 
	[user_name] sysname, 
	associated_dbrole nvarchar(256)
) 

set @sql ='
select ''?'' as dbname, dp.name as username, user_name(drm.role_principal_id) as associateddbrole 
	from [?].sys.database_principals dp
		left outer join [?].sys.database_role_members drm on dp.principal_id=drm.member_principal_id 
	where dp.sid not in (0x01) 
		and dp.sid is not null 
		and dp.type not in (''c'') 
		and dp.is_fixed_role <> 1 
		and dp.name not like ''##%'' 
		and ''[?]'' not in (''master'',''msdb'',''model'',''tempdb'') 
	order by dbname'

insert @dbuser
	exec sp_msforeachdb @sql

select * 
	from @dbuser 
	order by [db_name]