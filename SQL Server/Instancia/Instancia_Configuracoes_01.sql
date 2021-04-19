set nocount on;
set transaction isolation level read uncommitted;

use master;

declare @cfg table (nm nvarchar (70), [value] sql_variant);

insert @cfg select 'access check cache bucket count',     0					
insert @cfg select 'access check cache quota',            0					
insert @cfg select 'ad hoc distributed queries',          0					
insert @cfg select 'affinity i/o mask',                   0					
insert @cfg select 'affinity mask',                       0					
insert @cfg select 'affinity64 i/o mask',                 0					
insert @cfg select 'affinity64 mask',                     0					
insert @cfg select 'agent xps',                           0					
insert @cfg select 'allow updates',                       0					
insert @cfg select 'awe enabled',					      0
insert @cfg select 'backup checksum default',			  0		
insert @cfg select 'backup compression default',          0					
insert @cfg select 'blocked process threshold (s)',       0					
insert @cfg select 'c2 audit mode',                       0					
insert @cfg select 'clr enabled',                         0					
insert @cfg select 'common criteria compliance enabled',  0					
insert @cfg select 'contained database authentication',   0					
insert @cfg select 'cost threshold for parallelism',      5					
insert @cfg select 'cross db ownership chaining',         0					
insert @cfg select 'cursor threshold',                    -1					
insert @cfg select 'database mail xps',                   0					
insert @cfg select 'default full-text language',          1033					
insert @cfg select 'default language',                    0					
insert @cfg select 'default trace enabled',               1					
insert @cfg select 'disallow results from triggers',      0					
insert @cfg select 'ekm provider enabled',                0					
insert @cfg select 'filestream access level',             0					
insert @cfg select 'fill factor (%)',                     0					
insert @cfg select 'ft crawl bandwidth (max)',            100					
insert @cfg select 'ft crawl bandwidth (min)',            0					
insert @cfg select 'ft notify bandwidth (max)',           100					
insert @cfg select 'ft notify bandwidth (min)',           0					
insert @cfg select 'index create memory (kb)',            0					
insert @cfg select 'in-doubt xact resolution',            0					
insert @cfg select 'lightweight pooling',                 0					
insert @cfg select 'locks',                               0					
insert @cfg select 'max degree of parallelism',           0					
insert @cfg select 'max full-text crawl range',           4					
insert @cfg select 'max server memory (mb)',              2147483647					
insert @cfg select 'max text repl size (b)',              65536					
insert @cfg select 'max worker threads',                  0					
insert @cfg select 'media retention',                     0					
insert @cfg select 'min memory per query (kb)',           1024					
insert @cfg select 'min server memory (mb)',              0					
insert @cfg select 'nested triggers',                     1					
insert @cfg select 'network packet size (b)',             4096					
insert @cfg select 'ole automation procedures',           0					
insert @cfg select 'open objects',                        0					
insert @cfg select 'optimize for ad hoc workloads',       0					
insert @cfg select 'ph timeout (s)',                      60					
insert @cfg select 'precompute rank',                     0					
insert @cfg select 'priority boost',                      0					
insert @cfg select 'query governor cost limit',           0					
insert @cfg select 'query wait (s)',                      -1					
insert @cfg select 'recovery interval (min)',             0					
insert @cfg select 'remote access',                       1					
insert @cfg select 'remote admin connections',            0					
insert @cfg select 'remote login timeout (s)',            10					
insert @cfg select 'remote proc trans',                   0					
insert @cfg select 'remote query timeout (s)',            600					
insert @cfg select 'replication xps',                     0					
insert @cfg select 'scan for startup procs',              0					
insert @cfg select 'server trigger recursion',            1					
insert @cfg select 'set working set size',                0					
insert @cfg select 'show advanced options',               0					
insert @cfg select 'smo and dmo xps',                     1					
insert @cfg select 'sql mail xps',					      0
insert @cfg select 'transform noise words',               0					
insert @cfg select 'two digit year cutoff',               2049					
insert @cfg select 'user connections',                    0					
insert @cfg select 'user options',                        0		
insert @cfg select 'web assistant procedures',		      0		
insert @cfg select 'xp_cmdshell',                         0;			


with a as (	
	select 
			d.[name], 
			d.[value], 
			(select [value] from @cfg e where nm = d.[name]) as default_value
		from @cfg c 
			right join sys.configurations d on c.nm = case when d.[name] = 'blocked process threshold' then 'blocked process threshold (s)' else  d.[name] end and c.[value] = d.[value]
		where c.value is null
)
select 
		[name],
		default_value, 
		[value] as current_value
	from a
	order by name; 