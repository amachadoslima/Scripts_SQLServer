set nocount on

declare @openTranStatus table
(  
   activetransaction varchar(25),  
   details sql_variant   
   );  

insert into @openTranStatus   
   exec ('sp_MSforeachdb ''use [?] ; dbcc opentran with tableresults, no_infomsgs''');
   
select 
		db_name(c.database_id) as db, 
		a.*,
		b.login_name,
		b.login_time
	from @openTranStatus a
		left join sys.dm_exec_sessions b on a.details = b.session_id and a.activetransaction = 'oldact_spid'
		left join sys.dm_exec_requests c on b.session_id = c.session_id
	where a.activetransaction in ('oldact_spid','oldact_name','oldact_lsn','oldact_starttime')
		
set nocount off