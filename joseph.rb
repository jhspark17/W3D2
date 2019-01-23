require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('aram.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_accessor :id, :fname, :lname
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM users")
    data.map { |datum| User.new(datum) }
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def self.find_by_id(id)
     user = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    User.new(user[0])
  end

  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
    SELECT
      *
    FROM
      users
    WHERE
      fname = ? AND lname = ?
  SQL
  User.new(user[0])
  end

  def authored_questions
      ques = QuestionsDatabase.instance.execute(<<-SQL, self.id)
    SELECT
      *
    FROM
      questions
    WHERE
      author_id = ?
  SQL
   ques.map {|ques| Question.new(ques)}
  end

  def authored_replies
    QuestionsDatabase.instance.execute(<<-SQL, self.id)
    SELECT
      *
    FROM
      replies
    WHERE
      user_id = ?
  SQL
  end

  def followed_questions 
    QuestionFollow.followed_questions_for_user_id(self.id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(self.id)
  end
  
  def average_karma
    user_questions  = self.authored_questions
    total_likes = user_questions.map  do |ques|
      ques.num_likes
    end.sum
    total_likes / user_questions.count
  end

  def save
   raise "Already in a database" unless User.find_by_id(self.id).id.nil?
  QuestionsDatabase.instance.execute(<<-SQL)
  INSERT INTO
    users("fname", "lname")
  VALUES
    (self.fname, self.lname)
  SQL
  end

  def update 
    raise "not in a database" if User.find_by_id(self.id).id.nil?
    QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname, self.id)
    UPDATE
    users
    SET
    fname = ?, lname = ?
    WHERE
    id = ?
  SQL
  end
end

class Question
  attr_accessor :id, :title, :body, :author_id
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map { |datum| Question.new(datum)}
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def self.find_by_id(id)
     question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    Question.new(question[0])
  end

  def self.find_by_keyword(title)
    arg = "%#{title}%"
    question = QuestionsDatabase.instance.execute(<<-SQL, arg)
    SELECT
      *
    FROM
      questions
    WHERE
      title LIKE ?
    SQL
  Question.new(question[0])
  end

  def author
    #User.find_by_id(self.author_id)
    QuestionsDatabase.instance.execute(<<-SQL, self.author_id)
    SELECT
      fname, lname
    FROM
      users
    
      WHERE 
       users.id = ?
    SQL
  end

  def replies 
     Reply.find_by_question_id(self.id)
  end

  def followers 
    QuestionFollow.followers_for_question_id(self.id)
  end
  
  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)  
  end

  def likes 
    QuestionLike.likers_for_question_id(self.id)
  end
  
  def num_likes
    QuestionLike.num_likes_for_question_id(self.id)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end
end

class QuestionFollow
  attr_accessor :id, :question_id, :user_id
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions_follows")
    data.map { |datum| QuestionFollow.new(datum) }
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end

  def self.find_by_id(id)
     question_follow = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions_follows
      WHERE
        id = ?
    SQL
    QuestionFollow.new(question_follow[0])
  end

   def self.followers_for_question_id(question_id)
    user = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        users
      JOIN questions_follows ON user_id = users.id
      JOIN questions ON question_id = questions.id
      WHERE
        question_id = ?
    SQL
    user.map {|user| User.new(user)}
   end 

   def self.followed_questions_for_user_id(user_id)
    ques = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        questions
      JOIN questions_follows ON question_id = questions.id 
      JOIN users ON user_id = users.id
      WHERE
      user_id = ?
    SQL
    ques.map {|ques| Question.new(ques)}
   end 

   def self.most_followed_questions(n)
      questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        title, COUNT(fname)
      FROM
        users
      JOIN questions_follows ON user_id = users.id
      JOIN questions ON question_id = questions.id
      GROUP BY
        title
      ORDER BY 
        COUNT(fname) DESC
      LIMIT ?
    SQL
    questions.map {|questions| Question.new(questions)}
   end
end

class Reply
  attr_accessor :id, :body, :user_id, :question_id, :parent_id
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    data.map { |datum| QuestionFollow.new(datum) }
  end

  def initialize(options)
    @id = options['id']
    @body = options['body']
    @user_id = options['user_id']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
  end

  def self.find_by_id(id)
     reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
     Reply.new(reply[0])
  end

  def self.find_by_question_id(question_id)
     reply = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
     reply.map {|rep| Reply.new(rep)}
  end

  def author 
    User.find_by_id(self.user_id)
  end

  def question 
    Question.find_by_id(self.question_id)
  end

  def parent_reply 
    Reply.find_by_id(self.parent_id)
  end

  def child_replies 
    QuestionsDatabase.instance.execute(<<-SQL, self.id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL
  end
end

class QuestionLike
  attr_accessor :id, :user_id, :question_id
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
    data.map { |datum| QuestionFollow.new(datum) }
  end

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.find_by_id(id)
     like = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        id = ?
    SQL
    QuestionLike.new(like[0])
  end

  def self.likers_for_question_id(question_id)
    user_ids = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        user_id
      FROM
        question_likes
      WHERE
        question_id = ?
    SQL
    user_ids.map {|user| User.find_by_id(user["user_id"]) }
  end

  def self.num_likes_for_question_id(question_id)
     res = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        question_id, COUNT(user_id)
      FROM
        question_likes
      WHERE
        question_id = ?
    SQL
    res[0]['COUNT(user_id)']
  end

  def self.liked_questions_for_user_id(user_id)
     ques_ids = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        question_id
      FROM
        question_likes
      WHERE
        user_id = ?
    SQL
    ques_ids.map {|ques| Question.find_by_id(ques["question_id"]) }
  end

  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        title, COUNT(questions.id)
      FROM
        question_likes
      JOIN questions ON question_id = questions.id
      GROUP BY
        title
      ORDER BY 
        COUNT(questions.id) DESC
      LIMIT ?
    SQL
    questions.map {|questions| Question.new(questions)}
  end
end
