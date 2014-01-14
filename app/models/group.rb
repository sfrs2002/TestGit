#encoding: utf-8
class Group
  include Mongoid::Document
  include Mongoid::Timestamps
  field :preview, type: Boolean,  default: true
  field :name, type: String, default: "未命名分组"
  has_many :questions

  def self.find_or_create_preview
    g = Group.where(preview: true).first
    g.nil? ? Group.create : g
  end

  def confirm(name)
    self.update_attributes(name: name, preview: false)
  end
end
