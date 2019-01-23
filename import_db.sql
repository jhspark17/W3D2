PRAGMA foreign_keys = ON;
DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS questions_follows;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;


CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body TEXT, 
  author_id INTEGER NOT NULL, 

  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE questions_follows (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY(question_id) REFERENCES questions(id),
  FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  body TEXT,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,

  FOREIGN KEY(question_id) REFERENCES questions(id),
  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(parent_id) REFERENCES replies(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(question_id) REFERENCES questions(id)
);

INSERT INTO 
  users(fname,lname)
VALUES
  ("Bruce", "Wayne"),
  ("Burt", "Reynolds"),
  ("Stephen", "Curry");

INSERT INTO
  questions(title, body, author_id)
VALUES
  ("How to shave a mustache?", "Even Burt Reynolds shaves sometimes.", (SELECT id FROM users WHERE fname = "Burt")),
  ("Who am I?", "Am I the hero they deserve or need.", (SELECT id FROM users WHERE fname = "Bruce")),
  ("Do I deserve a Finals MVP?", "Or is Kevin Durant better than me.", (SELECT id FROM users WHERE fname = "Stephen"));

INSERT INTO
  replies(body, user_id, question_id)
VALUES
  ("Don't shave your glorious mustache.", (SELECT id FROM users WHERE fname = "Bruce" AND lname="Wayne"), (SELECT id from questions WHERE title LIKE "%mustache%") ),
  ("You are the hero Gotham needs.", (SELECT id FROM users WHERE fname = "Stephen" AND lname="Curry"), (SELECT id from questions WHERE title LIKE "Who am I%") ),
  ("Klay deserves the MVP.", (SELECT id FROM users WHERE fname = "Burt" AND lname="Reynolds"), (SELECT id from questions WHERE title LIKE "%Finals MVP%"));

  INSERT INTO 
   questions_follows(question_id,user_id)
  VALUES 
   (1,2),
   (1,3),
   (1,1),
   (2,1),
   (2,2),
   (3,1);

   INSERT INTO 
    question_likes(user_id,question_id)
   VALUES 
    (2,1),
    (2,3),
    (3,1),
    (1,3),
    (3,2),
    (1,1);