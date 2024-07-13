create table if not exists todos (
  id integer primary key autoincrement,
  title text not null,
  completed boolean
);