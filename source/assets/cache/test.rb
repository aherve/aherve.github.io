class Comment
  include Mongoid::Document
  include Mongoid::Timestamps

  # the comment have a content
  field :content, type: String

  # stores the score for queries
  field :score, type: Integer

  # the comment belongs to a post
  belongs_to :post

  # the comment have upvoters
  has_and_belongs_to_many :upvoters  , class_name: "User", inverse_of: "liked_comments"

  # the comment have downvoters
  has_and_belongs_to_many :downvoters, class_name: "User", inverse_of: "disliked_comments"

  # score is computed, then stored at each save:
  before_save :set_score

  def set_score
    self.write_attributes(score: upvoter_ids.size - downvoter_ids.size)
  end

end

class Post
  include Mongoid::Document
  include Mongoid::Timestamps

  # the post belongs to its author
  belongs_to :author, class_name: "User", inverse_of: :posts

  # the post content
  field :content, type: String

  # the post has many comments
  has_many :comments

  # How many interesting comments does it have?
  def interesting_comments_count
    comments.gt(score: 0).count #gt = greater than
  end
end

class User
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :posts, class_name: "Post", inverse_of: :author

  # the post score is the sum of all posts scores
  def interesting_comments_count
    cache_timestamp = posts.max(:updated_at) # again, this is fast
    cache_key = "userInterestingCommentCount|#{id}|#{cache_timestamp}"

    Rails.cache.fetch(cache_key, expires_in: 2.days) do 
      posts.map(&:interesting_comments_count).reduce(:+) #map/reduce rules
    end
  end
end
