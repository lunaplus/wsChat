create table cgiUsers (
       UID varchar(8) primary key,
       Name varchar(20),
       Password text,
       Expired bool,
       isAdmin bool,
       LastLogin datetime,
       LastModified datetime
);
