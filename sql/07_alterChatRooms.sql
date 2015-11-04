alter table chatRooms add column (
      isRevoked bit(1) not null default b'0'
);
