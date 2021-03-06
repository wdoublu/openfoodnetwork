module AuthenticationWorkflow
  def login_to_admin_section
    admin_role = Spree::Role.find_or_create_by_name!('admin')
    admin_user = Spree::User.create!({
      :email => 'admin@ofn.org',
      :password => 'passw0rd',
      :password_confirmation => 'passw0rd',
      :remember_me => false,
      :persistence_token => 'pass',
      :login => 'admin@ofn.org'})

    admin_user.spree_roles << admin_role

    login_to_admin_as admin_user
  end

  def create_enterprise_user
    new_user = create(:user, email: 'enterprise@hub.com', password: 'blahblah', :password_confirmation => 'blahblah', )
    new_user.spree_roles = [] # for some reason unbeknown to me, this new user gets admin permissions by default.
    new_user.save
    new_user
  end

  def login_to_admin_as user
    visit spree.admin_path
    fill_in 'spree_user_email', :with => user.email
    fill_in 'spree_user_password', :with => user.password
    click_button 'Login'
  end

  def login_to_consumer_section
    # The first user is given the admin role by Spree, so create a dummy user if this is the first
    create(:user) if Spree::User.admin.empty?

    user_role = Spree::Role.find_or_create_by_name!('user')
    user = Spree::User.create!({
      :email => 'someone@ofn.org',
      :password => 'passw0rd',
      :password_confirmation => 'passw0rd',
      :remember_me => false,
      :persistence_token => 'pass',
      :login => 'someone@ofn.org'})

    user.spree_roles << user_role

    visit spree.login_path
    fill_in 'spree_user_email', :with => 'someone@ofn.org'
    fill_in 'spree_user_password', :with => 'passw0rd'
    click_button 'Login'
  end
end
