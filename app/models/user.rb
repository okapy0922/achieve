class User < ActiveRecord::Base
  mount_uploader :avatar, AvatarUploader
  # 下記モジュールを組み込む:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable, :omniauthable

  has_many :blogs
  #ユーザーはたくさんのブログを持ちます。そしてユーザーが消えたらブログも消してねという意味。
  has_many :blogs, dependent: :destroy
  # CommentモデルのAssociationを設定
  has_many :comments, dependent: :destroy
  # Userテーブルが中間テーブルに対して複数のレコードを所持することを定義
  has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  #「foreign_key: "follower_id"」とforeign_keyを指定することで、
  # usersテーブルのidカラムと参照関係を持つカラムを「follower_id」カラムであると定義しています。(usersテーブルのidカラムと「follower_id」カラムが結びつく)
  has_many :reverse_relationships, foreign_key: "followed_id", class_name: "Relationship", dependent: :destroy
  #  has_many :reverse_relationshipsとすることで、reverse_relationshipsというアソシエーションを定義
  #  class_name: "Relationship"とすることで、Relationshipモデルに対して、アソシエーションを定義
  # 「dependent: :destroy」は、usersテーブルのレコードが削除される際に参照関係にある
  #  relationshipsテーブルのレコードも一緒に削除されるという定義
  has_many :followed_users, through: :relationships, source: :followed
  # 「自分と「自分”が”フォローしている人」の1対多の関係性を「followed_users」という名前で定義
  has_many :followers, through: :reverse_relationships, source: :follower
  # 「自分」と「フォロワー(自分をフォローしてるひと)」の関係性を「followers」という名前で定義
  has_many :tasks, dependent: :destroy
  # ユーザアカウントが削除されたらタスクも削除されるようにする設定
  has_many :submit_requests, dependent: :destroy
  # ユーザが削除されれば紐付くタスクも削除されるようにdependent: :destroyを設定
  has_many :received_requests, class_name: 'SubmitRequest', foreign_key: 'request_user_id'
  # class_name: 'SubmitRequest', foreign_key: 'request_user_id'でSubmitRequestモデルに対して、charge_idを外部キーにしてアソシエーションを定義

  def self.find_for_twitter_oauth(auth, signed_in_resource = nil)
   user = User.find_by(provider: auth.provider, uid: auth.uid)
     unless user
      user = User.new(
        name:     auth.info.nickname,
        image_url: auth.info.image,
        provider: auth.provider,
        uid:      auth.uid,
        email:    auth.info.email ||= "#{auth.uid}-#{auth.provider}@example.com",
        password: Devise.friendly_token[0, 20]
      )
      user.skip_confirmation!
      user.save
     end
    user
  end

  def self.create_unique_string
    SecureRandom.uuid
  end

  def update_with_password(params, *options)
    if provider.blank?
      super
    else
      params.delete :current_password
      update_without_password(params, *options)
    end
  end

  #指定のユーザをフォローするメソッド
  def follow!(other_user)
    relationships.create!(followed_id: other_user.id)
  end
  #フォローしているかどうかを確認するメソッド
  def following?(other_user)
    relationships.find_by(followed_id: other_user.id)
  end
  #指定のユーザをフォロー解除するメソッド
  def unfollow!(other_user)
    relationships.find_by(followed_id: other_user.id).destroy
  end
end