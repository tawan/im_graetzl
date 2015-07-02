class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  mount_uploader :avatar, AvatarUploader

  # associations
  has_one :address, as: :addressable, dependent: :destroy
  accepts_nested_attributes_for :address
  belongs_to :graetzl
  accepts_nested_attributes_for :graetzl
  has_many :going_tos
  has_many :meetings, through: :going_tos
  has_many :posts
  has_many :comments

  # attributes
  # virtual attribute to login with username or email
  attr_accessor :login
  GENDER_TYPES = { weiblich: 1, männlich: 2, anders: 3 }

  WEBSITE_NOTIFICATION_TYPES = {
    new_meeting_in_graetzl: {
      bitmask: 1,
      scope: ->(user) do
        s = PublicActivity::Activity.joins(sanitize_sql_array([
          "LEFT JOIN meetings ON meetings.id = activities.trackable_id
          AND activities.trackable_type = E'Meeting'
          AND meetings.graetzl_id = %s", user.graetzl_id ]))
      end
    },
    new_post_in_graetzl: {
      bitmask: 2,
      scope: ->(user) do
        s = PublicActivity::Activity.joins(sanitize_sql_array(["
        JOIN posts ON posts.id = activities.trackable_id
        AND activities.trackable_type = E'Post'
        AND posts.graetzl_id = %s", user.graetzl_id ]))
      end
    },
    meeting_changed: { bitmask: 4 },
    meeting_canceled: { bitmask: 8 },
    organizer_comments_meeting: { bitmask: 16 },
    user_comments_meeting: { bitmask: 32 },
    new_participant_of_my_meeting: { bitmask: 64 },
    user_comments_my_meeting: { bitmask: 128 },
    participant_cancels: { bitmask: 256 },
    private_message_received: { bitmask: 512 },
    graetzl_newsletter: { bitmask: 1024 }
  }

  def self.website_notifications_enabled(type)
    bit_mask = WEBSITE_NOTIFICATION_TYPES[type][:bitmask]
    where(["(website_notifications & :bit_mask) > 0", { bit_mask: bit_mask } ])
  end

  def notification_activities(type = nil)
    unless type.nil?
      WEBSITE_NOTIFICATION_TYPES[type][:scope].call(self)
    else
      enabled_types = [ ]
      WEBSITE_NOTIFICATION_TYPES.keys.each do |type|
        enabled_types << type if receives_website_notification_of?(type)
      end

      return [ ] if enabled_types.empty?

      enabled_types.inject(PublicActivity::Activity.where("1 = 1")) do |r, type|
        r = r.merge(WEBSITE_NOTIFICATION_TYPES[type][:scope].call(self))
        r
      end
    end
  end

  # validations
  validates :graetzl, presence: true
  validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 50 }
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :terms_and_conditions, acceptance: true
  validates_integrity_of :avatar
  validates_processing_of :avatar

  # class methods
  # overwrite devise authentication method to allow username OR email
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).
        where(["lower(username) = :value OR lower(email) = :value", { value: login.downcase }]).
        first
    else
      where(conditions.to_h).first
    end
  end

  # instance methods
  def autosave_associated_records_for_graetzl
    if new_graetzl = Graetzl.find_by_name(graetzl.name)
      self.graetzl = new_graetzl
    else
      self.graetzl = Graetzl.first
    end
  end

  def going_to?(meeting)
    meetings.include?(meeting)
  end

  def initiated?(meeting)
    going_to = going_tos.find_by_meeting_id(meeting)
    going_to && going_to.role == GoingTo::ROLES[:initiator]
  end

  def go_to(meeting, role=GoingTo::ROLES[:attendee])
    going_tos.create(meeting_id: meeting.id, role: role)
  end

  def receives_website_notification_of?(type)
    website_notifications & WEBSITE_NOTIFICATION_TYPES[type][:bitmask] > 0
  end

  def enable_website_notifications_for(type)
    new_setting = website_notifications | WEBSITE_NOTIFICATION_TYPES[type][:bitmask] 
    update_attribute(:website_notifications, new_setting)
  end

  def disable_website_notifications_for(type)
    mask = WEBSITE_NOTIFICATION_TYPES.values.inject(0) do |sum, val|
      sum = sum | val[:bitmask]
      sum
    end
    new_setting = (mask ^ WEBSITE_NOTIFICATION_TYPES[type][:bitmask]) & website_notifications 
    update_attribute(:website_notifications, new_setting)
  end
end
