go
with cte as(
	select 
		reason, 
		score, 
		dateadd(hour, -3, last_refresh) as last_refresh,
        query_id,
        regressed_plan_id,
        recommended_plan_id,
        current_state = json_value([state], '$.currentValue'),
        current_state_reason = json_value([state], '$.reason'),
        script = json_value(details, '$.implementationDetails.script'),
        estimated_gain = ((regressed_plan_execution_count + recommended_plan_execution_count) * (regressed_plancpu_time_average - recommended_plan_cpu_time_average) / 1000000),
        error_prone = iif(regressed_plan_error_count > recommended_plan_error_count, 'yes','no')
		from sys.dm_db_tuning_recommendations
			cross apply openjson(details, '$.planForceDetails') 
			with (query_id int '$.queryId',
				regressed_plan_id int '$.regressedPlanId',
				recommended_plan_id int '$.recommendedPlanId',
				regressed_plan_error_count int,    
				recommended_plan_error_count int,
				regressed_plan_execution_count int,
				regressed_plancpu_time_average float,
				recommended_plan_execution_count int,
				recommended_plan_cpu_time_average float
				)
)
select qsq.query_id, qsqt.query_sql_text, dtr.*, cast(rp.query_plan as xml) as regressedplan, cast(sp.query_plan as xml) as suggestedplan
	from cte as dtr
		join sys.query_store_plan as rp on rp.query_id = dtr.query_id and rp.plan_id = dtr.regressed_plan_id
		join sys.query_store_plan as sp on sp.query_id = dtr.query_id and sp.plan_id = dtr.recommended_plan_id
		join sys.query_store_query as qsq on qsq.query_id = rp.query_id
		join sys.query_store_query_text as qsqt on qsqt.query_text_id = qsq.query_text_id
	order by last_refresh desc