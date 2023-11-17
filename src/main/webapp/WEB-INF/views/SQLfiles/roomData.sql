show tables;


create table roomId(
	idx int not null auto_increment primary key,
	roomId text not null,
	userId_1 varchar(20) default 'no',
	userId_2 varchar(20) default 'no',
	createDay datetime default now()
);

select c.* from (select * from roomId order by createDay desc) as c;

select * from roomId
	where (userid_1 = 'no' OR userid_2 = 'no') AND !(userid_1 = 'no' AND userid_2 = 'no')
	order by createDay asc limit 0,1;

insert 
	
delete from roomId where userid_1 = 'no' AND userid_2 = 'no';


drop table roomid