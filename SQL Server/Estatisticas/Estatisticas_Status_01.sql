use master 
go
select
		object_name([object_id]) as [object_name],
		[name] as [statistic_name],
		stats_date([object_id], stats_id) as [statistic_update_date],
		auto_created, 
		user_created,
		no_recompute,
		has_filter,
		filter_definition
		--is_temporary
	from sys.stats
	where isnull(stats_date([object_id], stats_id), '') <> ''
	order by [statistic_update_date] asc