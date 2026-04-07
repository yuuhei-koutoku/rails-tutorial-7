class UserCsvImport
  include ActiveModel::Model

  attr_accessor :csv_file

  validates :csv_file, presence: true

  def self.normalize_field(row, key)
    # CSV の値は nil/空文字/空白のみが混ざるため、strip 済みの文字列に正規化する。
    row[key].to_s.strip
  end

  def self.build_new_user_from_csv_row(row)
    # 新規作成時は password を User に渡し、has_secure_password にハッシュ化を任せる。
    # name/email/password の検証は User に一本化する。
    password_plain = normalize_field(row, "password")
    User.new(
      name:                  normalize_field(row, "name"),
      email:                 normalize_field(row, "email"),
      password:              password_plain,
      password_confirmation: password_plain
    )
  end

  def self.attributes_for_csv_update(row)
    attrs = {
      name:  normalize_field(row, "name"),
      email: normalize_field(row, "email")
    }

    # 更新時は password が空なら変更しない（既存の password_digest を保持）。
    password_plain = normalize_field(row, "password")
    if password_plain.present?
      attrs[:password] = password_plain
      attrs[:password_confirmation] = password_plain
    end

    attrs
  end
end
