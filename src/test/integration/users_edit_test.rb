require "test_helper"

class UsersEditTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
  end

  test "unsuccessful edit" do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_template 'users/edit'
    patch user_path(@user), params: { user: { name:  "",
                                              email: "foo@invalid",
                                              password:              "foo",
                                              password_confirmation: "bar" } }
    assert_select 'div.alert.alert-danger', 'The form contains 4 errors.'
    assert_template 'users/edit'
    assert_select "input[name=?][value=?]", "user[name]", ""
    assert_select "input[name=?][value=?]", "user[email]", "foo@invalid"
  end

  test "successful edit with friendly forwarding" do
    get edit_user_path(@user)
    log_in_as(@user)
    assert_redirected_to edit_user_url(@user)
    name  = "Foo Bar"
    email = "foo@bar.com"
    patch user_path(@user), params: { user: { name:  name,
                                              email: email,
                                              password:              "",
                                              password_confirmation: "" } }
    assert_not flash.empty?
    assert_redirected_to @user
    @user.reload
    assert_equal name,  @user.name
    assert_equal email, @user.email

    follow_redirect!
    assert_template 'users/show'
    assert_select "h1", text: @user.name
  end

  # フレンドリーフォワーディングは初回ログイン時のみ有効で、
  # 2回目以降のログインでは転送先がデフォルトのプロフィールになることを確認する。
  # （ログイン時に reset_session されるため session[:forwarding_url] は初回使用後に消え、
  #  次回ログインでは使われない）
  test "friendly forwarding redirects only on first login, then defaults to profile" do
    # 未ログインで編集ページへアクセス → ログイン画面へリダイレクト（このとき session[:forwarding_url] に edit の URL が保存される）
    get edit_user_path(@user)
    assert_redirected_to login_url
    follow_redirect!
    assert_template "sessions/new"

    # 1回目のログイン → 保存されていた URL（編集ページ）へ転送される
    log_in_as(@user)
    assert_redirected_to edit_user_url(@user)

    follow_redirect!
    assert_template "users/edit"

    # ログアウトしてから 2回目のログイン
    delete logout_path
    assert_redirected_to root_url
    log_in_as(@user)

    # 2回目は転送URLは使われず、デフォルトのプロフィール（show）へリダイレクトされる
    assert_redirected_to @user
  end
end
