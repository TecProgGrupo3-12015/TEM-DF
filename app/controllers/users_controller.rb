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
    # Check the user type 
    @document = params[:user][:document]
    if @user.account_status == false && !@document
      flash.now.alert = "Você precisa anexar um documento!"
      render "new"
      CUSTOM_LOGGER.info("Failure to create user #{@user.to_yaml}")
    # Check whether the password and password_confirmation are the same
    elsif @user.password == @user.password_confirmation 
      @user.account_status = false
      if @user.save
        upload @document
        CUSTOM_LOGGER.info("User saved and document uploaded #{@user.to_yaml}")
        # Check whether the user is common 
        if @user_params_document == nil
          # Generate a random number for use it in update password
          random = Random.new
          @user.update_attribute(:token_email, random.seed)
          @user.update_attribute(:medic_type_status, false)
          TemdfMailer.confimation_email(@user.id, @user.token_email, @user.email).deliver
          flash[:notice] = "Por favor confirme seu cadastro pela mensagem enviada ao seu email!"
          CUSTOM_LOGGER.info("User saved #{@user.to_yaml} but not confirmed")
        # Or a medic user
        else
          @user.update_attribute(:medic_type_status, true)
          flash[:notice] = "Nossa equipe vai avaliar seu cadastro. Por favor aguarde a nossa aprovação para acessar sua conta!"
          CUSTOM_LOGGER.info("User saved #{@user.to_yaml} but not confirmed")
        end
        redirect_to root_path
      else
        render "new"
        CUSTOM_LOGGER.info("Failure to create user #{@user.to_yaml}")
      end
    else
      render "new"
      CUSTOM_LOGGER.info("Failure to create user #{@user.to_yaml}")
    end
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
    if @user
    	# Admin's update
      if @user.username == "admin" 
        @email = params[:user][:email]
        @user_from_email = User.find_by_email(@email)
        if @user_from_email && @user != @user_from_email
          flash[:alert] = "Email já existente"
          render "edit" 
          CUSTOM_LOGGER.info("Failure to update user #{@user.to_yaml}")
        else 
          @user.update_attribute(:email , @email)
          redirect_to root_path, notice: 'Usuário alterado!'
          CUSTOM_LOGGER.info("Update user attributes #{@user.to_yaml}")
        end
      # Commom user's update 
      else 
        @username = params[:user][:username]
        @email = params[:user][:email]
        @user_from_username = User.find_by_username(@username)
        @user_from_email = User.find_by_email(@email)
        # Check if username is in use
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
    else
      redirect_to root_path
      CUSTOM_LOGGER.info("Failure to update user #{@user.to_yaml}")
    end
  end

  # Method to update user's password
  def update_password
    @user_session = User.find_by_id(session[:remember_token])
    # Check whether the user is logged
    if @user_session
        @user = User.authenticate(@user_session.username, params[:user][:password])
        # Check whether the current password is correct
        if @user
        	@new_password = params[:user][:new_password]
        	@password_confirmation = params[:user][:password_confirmation]
        	# Check whether new password and confirmation password are the same
        	if @password_confirmation == @new_password && !@new_password.blank?
          	@user.update_attribute(:password, @new_password)
          	redirect_to root_path, notice: "Alteração feita com sucesso"
          	CUSTOM_LOGGER.info("Update user password #{@user.to_yaml}")
        	else
          	redirect_to edit_password_path, alert: "Confirmação nao confere ou campo vazio"
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
    # Admin's deactivate
    if @user && @user.username != "admin"
      @user.update_attribute(:account_status, false)
      redirect_to logout_path
      CUSTOM_LOGGER.info("User deactivated #{@user.to_yaml}")
    # User's deactivate
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
end