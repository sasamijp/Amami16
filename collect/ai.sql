
create table respond(
  link_id integer ,
  respond_sentence text ,
  primary key (link_id)
);

create table target(
  link_id integer ,
  target_sentence text ,
  primary key (link_id)
);

create table word(
  word_id integer ,
  word_target_id integer ,
  word_text text ,
  word_is_joshi integer ,
  word_is_connector integer ,
  primary key (word_id)
);


