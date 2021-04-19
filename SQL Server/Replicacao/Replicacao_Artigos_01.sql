select 
		st.[name] as published_object, st.[schema_id], st.is_published , st.is_merge_published, is_schema_published  
	from sys.tables st 
	where st.is_published = 1 
		or st.is_merge_published = 1 
		or st.is_schema_published = 1  
union  
	select 
			sp.[name], sp.[schema_id], 0, 0, sp.is_schema_published  
		from sys.procedures sp 
		where sp.is_schema_published = 1  
union  
	select 
			sv.[name], sv.[schema_id], 0, 0, sv.is_schema_published  
		from sys.views sv 
		where sv.is_schema_published = 1;