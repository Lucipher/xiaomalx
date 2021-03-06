class Answer < ActiveRecord::Base
  acts_as_nested_set :counter_cache => :children_count
  attr_protected :lft, :rgt
  belongs_to :question
  has_many :praises
end
