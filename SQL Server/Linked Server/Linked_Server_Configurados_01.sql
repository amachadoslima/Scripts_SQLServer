select 
		s.[name],
		s.product,
		s.[provider],
		s.[data_source],
		[location],
		s.provider_string,
		s.[catalog],
		l.remote_name,
		s.modify_date
	from sys.servers s
		left join sys.linked_logins l on s.server_id = l.server_id 
		left join sys.server_principals sp on sp.principal_id = l.local_principal_id