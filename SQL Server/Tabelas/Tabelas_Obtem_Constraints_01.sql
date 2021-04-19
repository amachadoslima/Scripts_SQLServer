DECLARE @Constraint TABLE (
        [Database] [nvarchar](128) NULL,
        [Schema Name] [nvarchar](64) NULL,
        [Table Name] [sysname] NOT NULL,
        [Column Name] [nvarchar](128) NULL,
        [Data Type] [nvarchar](64) NULL,
        [Constraint Name] [sysname] NOT NULL,
        [Constraint Type] [varchar](7) NOT NULL,
        [definition] [varchar](512) NULL,
        [Create Date] [datetime] NULL
    )

    insert into @Constraint
    exec sp_MSforeachdb 'use [?]
	if(db_id() <=4)
	return
    select db_name() [Database],schema_name(t.schema_id) [Schema Name],t.name [Table Name],ac.name [Column Name],dt.name [Data Type],dc.name [Constraint Name],''Default'' [Constraint Type],dc.definition,dc.create_date [Create Date]
    from
                sys.tables t
    inner join  sys.all_columns ac
    on          t.object_id=ac.object_id
    inner join  sys.types dt
    on          ac.user_type_id=dt.user_type_id
    inner join  sys.default_constraints dc
    on          t.object_id=dc.parent_object_id and ac.column_id=dc.parent_column_id
    where t.type=''U''
    union all
    select db_name() [Database],schema_name(t.schema_id) [Schema Name],t.name [Table Name],ac.name [Column Name],dt.name [Data Type],cc.name [Constraint Name],''Default'' [Constraint Type],cc.definition,cc.create_date [Create Date]
    from
                sys.tables t
    inner join  sys.all_columns ac
    on          t.object_id=ac.object_id
    inner join  sys.types dt
    on          ac.user_type_id=dt.user_type_id
    inner join  sys.check_constraints cc
    on          t.object_id=cc.parent_object_id and ac.column_id=cc.parent_column_id
    where t.type=''U'''

    select * from @Constraint