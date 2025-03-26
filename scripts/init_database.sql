USE master;
go

-- Drop and recreate the 'DataWareHouse' database
if exists (select 1 from sys.databases where name = 'DataWareHouse')
  begin 
    alter database DataWareHouse set SINGLE_USER with rollback immediate;
    drop database DataWareHouse;
  end;
go
  
-- Create the 'DataWareHouse' database 
create DATABASE DataWareHouse;
go
  
use DataWareHouse;
go

create schema bronze;
go
  
create schema silver;
go
  
create schema gold;
go
