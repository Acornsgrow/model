require 'sequel/extensions/pg_array'

class User
  include Lotus::Entity
  attributes :name, :age, :created_at, :updated_at
end

class Article
  include Lotus::Entity
  include Lotus::Entity::DirtyTracking
  attributes :user_id, :unmapped_attribute, :title, :comments_count, :tags
end

class Repository
  include Lotus::Entity
  attributes :id, :name
end

class CustomUserRepository
  include Lotus::Repository
end

class UserRepository
  include Lotus::Repository
end

class UnmappedRepository
  include Lotus::Repository
end

class ArticleRepository
  include Lotus::Repository

  def self.rank
    query do
      desc(:comments_count)
    end
  end

  def self.by_user(user)
    query do
      where(user_id: user.id)
    end
  end

  def self.not_by_user(user)
    exclude by_user(user)
  end

  def self.rank_by_user(user)
    rank.by_user(user)
  end

  def self.aggregate
    execute("select * from articles")
  end
end

[SQLITE_CONNECTION_STRING, POSTGRES_CONNECTION_STRING].each do |conn_string|
  DB = Sequel.connect(conn_string)

  DB.create_table :users do
    primary_key :id
    String  :name
    Integer :age
    DateTime :created_at
    DateTime :updated_at
  end

  DB.create_table :articles do
    primary_key :_id
    Integer :user_id
    String  :s_title
    String  :comments_count # Not an error: we're testing String => Integer coercion
    String  :umapped_column

    if conn_string.match(/\Apostgres/)
      column :tags, 'text[]'
    else
      column :tags, String
    end
  end

  DB.create_table :devices do
    primary_key :id
  end
end

class PGArray
  def self.call(value)
    ::Sequel.pg_array(value) rescue nil
  end
end

#FIXME this should be passed by the framework internals.
MAPPER = Lotus::Model::Mapper.new do
  collection :users do
    entity User

    attribute :id,         Integer
    attribute :name,       String
    attribute :age,        Integer
    attribute :created_at, DateTime
    attribute :updated_at, DateTime
  end

  collection :articles do
    entity Article

    attribute :id,             Integer, as: :_id
    attribute :user_id,        Integer
    attribute :title,          String,  as: 's_title'
    attribute :comments_count, Integer
    attribute :tags,           Array, coercer: PGArray

    identity :_id
  end

end

MAPPER.load!
