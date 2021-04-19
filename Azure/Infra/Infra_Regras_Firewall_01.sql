select 
		id,
		[name],
		start_ip_address,
		end_ip_address,
		dateadd(hour, -3, create_date) as create_date,
		dateadd(hour, -3, modify_date) as modify_date
	from sys.firewall_rules  
	order by id 