select	
		db_name(sd.[database_id]) as [database_name],
		sd.mirroring_state,
		sd.mirroring_state_desc,
		sd.mirroring_partner_name,
		sd.mirroring_role_desc,
		sd.mirroring_safety_level_desc,
		sd.mirroring_witness_name,
		sd.mirroring_connection_timeout as timeout_sec
    from sys.database_mirroring as sd
    where mirroring_guid is not null
    order by [database_name];