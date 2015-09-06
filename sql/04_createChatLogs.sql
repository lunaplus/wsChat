create table chatLogs (
       id bigint auto_increment primary key,
       uid varchar(8),
       message text,
       sentDate datetime
);
