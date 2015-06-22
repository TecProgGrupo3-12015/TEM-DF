require "bcrypt"

# File: users_controller.rb
# Purpose of class: Contain action methods for users view.
# This software follows GPL license.
# TEM-DF Group.
# FGA-UnB Faculdade de Engenharias do Gama - Universidade de Brasília.
class UsersController < ApplicationController
  # Method to verify if the user is admin and set distinct values
  def index
    @user = User.find_by_id(session[:remember_token])

    show_all_users(@user)
  end

  # Method to create a user
  def create
    @user = User.new(user_params)
    @document = params[:user][:document]
    @account_status = @user.account_status
    @password = @user.password
    @password_confirmation = @user.password_confirmation

    # Common user create
    if @account_status == true && @password == @password_confirmation 
 			@account_status = false
      test(@user)
    else
    end

    # Medic user create
    if @account_status == false && @password == @password_confirmation 
	    test2(@user)
    else
    end  
    # Return error wheter passwords are different
    	flash.now.alert = "Senhas não conferem"
      render "new"
      CUSTOM_LOGGER.info("Failure to create user #{@user.to_yaml}")
  end

  # Auxiliar method to create a user
  def new
    @user = User.new
    CUSTOM_LOGGER.info("Start to create user #{@user.to_yaml}")
  end

  # Method to find a user by id and assist to update user's information
  def edit
    @user = User.find_by_id(session[:remember_token])
    CUSTOM_LOGGER.info("Start to edit user #{@user.to_yaml}")
  end

  # Method to find a user by id and assist to update user's password
  def edit_password
    @user = User.find_by_id(session[:remember_token]) 
    CUSTOM_LOGGER.info("Start to edit password #{@user.to_yaml}")
  end

  # Method to update user's information
  def update
    @user = User.find_by_id(session[:remember_token])
    @username = params[:user][:username]
    @email = params[:user][:email]
    @user_from_username = User.find_by_username(@username)
    @user_from_email = User.find_by_email(@email)

    if @user

    	# Commom user's update 
      if @user.username != "admin" 
        # Check if username is in use
        test3_update(@user)
       
      # Admin's update
      else 
        test4_update(@user)
      end
    else
      redirect_to root_path
      CUSTOM_LOGGER.info("Failure to update user #{@user.to_yaml}")
    end
  end

  # Method to update user's password
  def update_password
    @user_session = User.find_by_id(session[:remember_token])
    @user = User.authenticate(@user_session.username, params[:user][:password])
    @new_password = params[:user][:new_password]
		@password_confirmation = params[:user][:password_confirmation]
    # Check whether the user is logged
    if @user_session
      # Check whether the current password is correct
      if @user
      	# Check whether new password and confirmation password are the same
      	if @password_confirmation == @new_password && !@new_password.blank?
        	@user.update_attribute(:password, @new_password)
        	redirect_to root_path, notice: "Alteração feita com sucesso"
        	CUSTOM_LOGGER.info("Update user password #{@user.to_yaml}")
      	else
        	redirect_to edit_password_path, alert: "Confirmação não confere ou campo vazio"
        	CUSTOM_LOGGER.info("Failure to update password #{@user.to_yaml}")
      	end
      else
      	redirect_to edit_password_path, alert: "Senha errada"
      	CUSTOM_LOGGER.info("Failure to update password #{@user.to_yaml}")
      end
    else
      redirect_to edit_password_path
      CUSTOM_LOGGER.info("Failure to update password #{@user.to_yaml}")
    end
  end

  # Method to desactivate a user
  def deactivate
    @user = User.find_by_id(session[:remember_token])
     # User's deactivate
    if @user && @user.username != "admin"
      @user.update_attribute(:account_status, false)
      redirect_to logout_path
      CUSTOM_LOGGER.info("User deactivated #{@user.to_yaml}")
    # Admin's deactivate
    else
      @user = User.find_by_id(params[:id])
      if @user
        @user.update_attribute(:account_status, false)
        redirect_to(action: "index")
        CUSTOM_LOGGER.info("User deactivated #{@user.to_yaml}")
      else
        redirect_to root_path
        CUSTOM_LOGGER.info("Failure to deactivate user #{@user.to_yaml}")
      end
    end
  end

  # Method to reactivate a user
  def reactivate
    @user = User.find_by_id(params[:id])
    if @user
      @user.update_attribute(:account_status, true)
      redirect_to(action: "index")
      CUSTOM_LOGGER.info("User reactivated #{@user.to_yaml}")
    else
      redirect_to root_path
      CUSTOM_LOGGER.info("Failure to reactivate user #{@user.to_yaml}")
    end
  end

  # Method to verify the token from user and confirm account
  def confirmation_email
    @user = User.find_by_id_and_token_email(params[:id],params[:token_email])
    @message = ""
    # Check if the user and token email are equivalent
    if @user && @user.token_email
      @user.update_attribute(:account_status, true)
      @user.update_attribute(:token_email, nil)
      @message = "Cadastro Confirmado!"
      CUSTOM_LOGGER.info("User confirmed #{@user.to_yaml}")
    else
      @message = "Link inválido!"
      CUSTOM_LOGGER.info("Failure to confirm user #{@user.to_yaml}, invalid link")
    end
    redirect_to root_path, notice: @message
  end

  private
    #Method to set user's params
    def user_params
      params.require(:user).permit(:username, :email, :password, :password_confirmation, :account_status)
    end

    # Method to upload an archive 
    def upload(uploaded_io)
      if uploaded_io
        File.open(Rails.root.join('public', 'uploads', 'arquivo_medico'), 'wb') { |file| file.write(uploaded_io.read) }
        # Send file to temdf email
        TemdfMailer.request_account.deliver
        CUSTOM_LOGGER.info("Send email to #{@user.to_yaml}")
      else 
        # Nothing to do
      end
    end

    private

    def show_all_users(user)
      if @user && @user.username == "admin" 
        @users = User.all
        return true
        CUSTOM_LOGGER.info("Showed all users")
      else
        redirect_to root_path
        return false
        CUSTOM_LOGGER.info("Failure to showed all users")
      end
    end

    def test (user)
        if @user.save
        # Generate a random number for use it in update password
        random = Random.new
        @user.update_attribute(:token_email, random.seed)
        @user.update_attribute(:medic_type_status, false)
        TemdfMailer.confimation_email(@user.id, @user.token_email, @user.email).deliver
        render "new"
        flash[:notice] = "Por favor confirme seu cadastro pela mensagem enviada ao seu email!"
        CUSTOM_LOGGER.info("User saved #{@user.to_yaml} but not confirmed")
      else
        render "new"
        CUSTOM_LOGGER.info("Failure to create user #{@user.to_yaml}")
      end
    end

    def test2 (user)
      if @user.save 
        #Verify whether document is present
        if @document
          upload @document
          @user.update_attribute(:medic_type_status, true)
          flash[:notice] = "Nossa equipe vai avaliar seu cadastro. Por favor aguarde a nossa aprovação para acessar sua conta!"
          CUSTOM_LOGGER.info("User saved and document uploaded #{@user.to_yaml}")
        else
          flash.now.alert = "Você precisa anexar um documento!"
          render "new"
          CUSTOM_LOGGER.info("Failure to create user #{@user.to_yaml}")
        end
      else 
        render "new"
        CUSTOM_LOGGER.info("Failure to create user #{@user.to_yaml}")
      end
    end

    def test3_update(user)
       if @user_from_username && @user != @user_from_username
        flash[:alert] = "Nome já existente"
        render "edit"
        CUSTOM_LOGGER.info("Failure to update user #{@user.to_yaml}")
        # Check if the email is in use
      elsif @user_from_email && @user != @user_from_email
        flash[:alert] = "Email já existente"
        render "edit" 
        CUSTOM_LOGGER.info("Failure to update user #{@user.to_yaml}")
        # If not update attributes
      else 
        @user.update_attribute(:username , @username)
        @user.update_attribute(:email , @email)
        redirect_to root_path, notice: "Usuário alterado!"
        CUSTOM_LOGGER.info("Update user attributes #{@user.to_yaml}")
      end
    end

    def test4_update(user)
      if @user_from_email && @user != @user_from_email
        flash[:alert] = "Email já existente"
        render "edit" 
        CUSTOM_LOGGER.info("Failure to update user #{@user.to_yaml}")
      else 
        @user.update_attribute(:email , @email)
        redirect_to root_path, notice: 'Usuário alterado!'
        CUSTOM_LOGGER.info("Update user attributes #{@user.to_yaml}")
      end
    end
end