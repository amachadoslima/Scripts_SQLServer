select 
		@@servername as server_name,
		db_name(database_id) as [database_name],
		mirroring_state_desc,
		mirroring_role_desc,
		mirroring_safety_level_desc
	from sys.database_mirroring
	where mirroring_role is not null