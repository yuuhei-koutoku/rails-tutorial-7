require "csv"

class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy,
                                        :following, :followers, :import_csv]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: [:destroy, :import_csv]

  def index
    respond_to do |format|
      format.html do
        load_users_page
        @csv_import = UserCsvImport.new if current_user.admin?
      end
      format.csv do
        users = User.all
        csv_data = CSV.generate do |csv|
          csv << ['id', 'name', 'email', 'password']
          users.each do |user|
            csv << [user.id, user.name, user.email, '']
          end
        end
        send_data csv_data, filename: "users.csv"
      end
    end
  end

  def show
    @user = User.find(params[:id])
    @microposts = @user.microposts.paginate(page: params[:page])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      reset_session
      log_in @user
      flash[:success] = "Welcome to the Sample App!"
      redirect_to @user
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url, status: :see_other
  end

  def following
    @title = "Following"
    @user  = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])
    render 'show_follow'
  end

  def followers
    @title = "Followers"
    @user  = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow'
  end

  def import_csv
    # 管理者向け: CSV から User を一括作成/更新する。
    # 画面表示用のエラーは @csv_import.errors に集約し、失敗時は index を再描画する。
    @csv_import = UserCsvImport.new(csv_import_params)
    unless @csv_import.valid?
      load_users_page
      render :index, status: :unprocessable_entity
      return
    end

    # Excel 由来の CSV を想定して CP932 を UTF-8 に変換して読む。
    # headers: true でも最初の行を読み込むまでは headers が確定しないため、readline してから検証する。
    CSV.open(@csv_import.csv_file.path, 'r:cp932:utf-8', undef: :replace, headers: true) do |csv|
      first_row = csv.readline
      headers = csv.headers

      unless headers.is_a?(Array) && headers.size == 4
        @csv_import.errors.add(:base, "CSVの列数が不正です。")
        load_users_page
        render :index, status: :unprocessable_entity
        return
      end

      import_one_csv_row(first_row, 2) if first_row
      csv.each.with_index(3) do |row, line_no|
        import_one_csv_row(row, line_no)
      end
    end

    if @csv_import.errors.any?
      load_users_page
      render :index, status: :unprocessable_entity
    else
      flash[:success] = "ユーザーをCSVからインポートしました。"
      redirect_to users_url
    end
  end

  private
    def load_users_page
      @users = User.paginate(page: params[:page])
    end

    def import_one_csv_row(row, line_no)
      # id が空なら新規、値があれば該当 User を更新する。
      # name/email は strip 後に User のバリデーションに任せる。
      id_str = row["id"].to_s.strip

      if id_str.blank?
        user = UserCsvImport.build_new_user_from_csv_row(row)
        unless user.save
          @csv_import.errors.add(:base, "行 #{line_no}: #{user.errors.full_messages.to_sentence}")
        end
        return
      end

      user = User.find_by(id: id_str)
      unless user
        @csv_import.errors.add(:base, "行 #{line_no}: id #{id_str} のユーザーが見つかりません。")
        return
      end

      attrs = UserCsvImport.attributes_for_csv_update(row)
      unless user.update(attrs)
        @csv_import.errors.add(:base, "行 #{line_no}: #{user.errors.full_messages.to_sentence}")
      end
    end

    def csv_import_params
      params.fetch(:user_csv_import, {}).permit(:csv_file)
    end

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    # beforeフィルタ

    # 正しいユーザーかどうか確認
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url, status: :see_other) unless current_user?(@user)
    end

    # 管理者かどうか確認
    def admin_user
      redirect_to(root_url, status: :see_other) unless current_user.admin?
    end
end
