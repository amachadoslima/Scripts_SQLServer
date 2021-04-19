SELECT schema_name(obj_table.schema_id)+'.'+obj_table.NAME      AS 'table', 
        columns.NAME        AS 'column',
        obj_Constraint.NAME AS 'constraint',
        obj_Constraint.type AS 'type'

    FROM   sys.objects obj_table 
        JOIN sys.objects obj_Constraint 
            ON obj_table.object_id = obj_Constraint.parent_object_id 
        JOIN sys.sysconstraints constraints 
             ON constraints.constid = obj_Constraint.object_id 
        JOIN sys.columns columns 
             ON columns.object_id = obj_table.object_id 
            AND columns.column_id = constraints.colid 
