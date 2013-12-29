class Group
  include Mongoid::Document
  include Mongoid::Timestamps
  field :preview, default: true
  has_many :questions

  def self.find_or_create_preview
    g = Group.where(preview: true).first
    g.nil? ? Group.create : g
  end

  def confirm
    self.update_attributes(preview: false)
  end
end
