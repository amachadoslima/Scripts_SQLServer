select 
	 serverproperty('buildclrversion') as build_clr_version	--version of the microsoft.net framework common language runtime (clr) that was used while building the instance of sql server.
	,serverproperty('collation') as collation	--name of the default collation for the server.
	,serverproperty('collationid') as collation_id	--id of the sql server collation.
	,serverproperty('comparisonstyle') as comparison_style	--windows comparison style of the collation.
	,serverproperty('computernamephysicalnetbios') as computer_name_physical_netbios	--netbios name of the local computer on which the instance of sql server is currently running.
	,serverproperty('edition') as edition		--installed product edition of the instance of sql server. use the value of this property to determine the features and the limits, such as compute capacity limits by edition of sql server. 64-bit versions of the database engine append (64-bit) to the version.
	,serverproperty('editionid') as edition_id	--editionid represents the installed product edition of the instance of sql server. use the value of this property to determine features and limits, such as compute capacity limits by edition of sql server.
	,serverproperty('engineedition') as engine_edition	--database engine edition of the instance of sql server installed on the server.
	,serverproperty('hadrmanagerstatus') as hadr_manager_status		--applies to: sql server 2012 through sql server 2016. indicates whether the alwayson availability groups manager has started.
	,serverproperty('instancedefaultdatapath') as instance_default_data_path	--applies to: sql server 2012 through current version in updates beginning in late 2015.name of the default path to the instance data files.
	,serverproperty('instancedefaultlogpath') as instance_default_log_path		--applies to: sql server 2012 through current version in updates beginning in late 2015.name of the default path to the instance data files.
	,serverproperty('instancename') as instance_name	--name of the instance to which the user is connected.
	,serverproperty('isadvancedanalyticsinstalled') as is_advanced_analytics_installed	--returns 1 if the advanced analytics feature was installed during setup; 0 if advanced analytics was not installed.
	,serverproperty('isclustered') as is_clustered	--server instance is configured in a failover cluster.
	,serverproperty('isfulltextinstalled') as is_fulltext_installed	--the full-text and semantic indexing components are installed on the current instance of sql server.
	,serverproperty('ishadrenabled') as is_hadr_enabled 	--applies to: sql server 2012 through sql server 2016.alwayson availability groups is enabled on this server instance.
	,serverproperty('isintegratedsecurityonly') as is_integrated_security_only	--server is in integrated security mode.
	,serverproperty('islocaldb') as is_local_db 	--applies to: sql server 2012 through sql server 2016.server is an instance of sql server express localdb.
	,serverproperty('ispolybaseinstalled') as is_poly_base_installed	--applies to: sql server 2016.returns whether the server instance has the polybase feature installed.
	,serverproperty('issingleuser') as is_single_user 	--server is in single-user mode.
	,serverproperty('isxtpsupported') as is_xtp_supported 	--applies to: sql server (sql server 2014 through sql server 2016), sql database.server supports in-memory oltp.
	,serverproperty('lcid') as lcid	--windows locale identifier (lcid) of the collation.
	,serverproperty('licensetype') as license_type 	--unused. license information is not preserved or maintained by the sql server product. always returns disabled.
	,serverproperty('machinename') as machine_name 	--windows computer name on which the server instance is running.
	,serverproperty('numlicenses') as num_licenses 	--unused. license information is not preserved or maintained by the sql server product. always returns null.
	,serverproperty('processid') as process_id 	--process id of the sql server service. processid is useful in identifying which sqlservr.exe belongs to this instance.
	,serverproperty('productbuild') as product_build 	--applies to: sql server 2014 beginning october, 2015. the build number.
	,serverproperty('productbuildtype') as product_build_type	--applies to: sql server 2012 through current version in updates beginning in late 2015. the build type.
	,serverproperty('productlevel') as product_level 	--level of the version of the instance of sql server.
	,serverproperty('productmajorversion') as product_major_version	--applies to: sql server 2012 through current version in updates beginning in late 2015. the major version.
	,serverproperty('productminorversion') as product_minor_version	--applies to: sql server 2012 through current version in updates beginning in late 2015. the minor version.
	,serverproperty('productupdatelevel') as product_update_level	--applies to: sql server 2012 through current version in updates beginning in late 2015.
	,serverproperty('productupdatereference') as product_update_reference 	--applies to: sql server 2012 through current version in updates beginning in late 2015.
	,serverproperty('productversion') as product_version 	--version of the instance of sql server, in the form of'major.minor.build.revision'.
	,serverproperty('resourcelastupdatedatetime') as resource_last_update_datetime	--returns the date and time that the resource database was last updated.
	,serverproperty('resourceversion') as resource_version 	--returns the version resource database.
	,serverproperty('servername') as server_name 	--both the windows server and instance information associated with a specified instance of sql server.
	,serverproperty('sqlcharset') as sql_char_set 	--the sql character set id from the collation id.
	,serverproperty('sqlcharsetname') as sql_char_set_name 	--the sql character set name from the collation.
	,serverproperty('sqlsortorder') as sql_sort_order 	--the sql sort order id from the collation
	,serverproperty('sqlsortordername') as sql_sort_order_name	--the sql sort order name from the collation.
	,serverproperty('filestreamsharename') as file_streams_hare_name	--the name of the share used by filestream.
	,serverproperty('filestreamconfiguredlevel') as file_stream_configured_level	--the configured level of filestream access. for more information, see filestream access level.
	,serverproperty('filestreameffectivelevel') as file_stream_effective_level	--the effective level of filestream access. this value can be different than the filestreamconfiguredlevel if the level has changed and either an instance restart or a computer restart is pending. for more information, see filestream access level.
go