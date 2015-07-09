# File: sessions_controller.rb
# Purpose of class: Create and destroy sessions when users perform,
# login or logout.
# This software follows GPL license.
# TEM-DF Group
# FGA-UnB Faculdade de Engenharias do Gama - Universidade de Brasília
class SessionsController < ApplicationController

  def new
    CUSTOM_LOGGER.info("Created new session")
  end

  # Create sessions when users perform login 
  def create
    user = User.authenticate(params[:username], params[:password])

    # Check the User existence and if your account is active
    is_user_is_active = user && user.account_status == true
    if is_user_is_active
      session[:remember_token] = user.id
      session[:user_id] = user.id
      redirect_to root_path, :notice => "Seja bem vindo!"
      CUSTOM_LOGGER.info("Created session user #{user.to_yaml}")
    else
      flash.now.alert = "Usuário ou senha inválidos!"
      render "new"
      CUSTOM_LOGGER.error("Failure to created session user")
    end
  end

  # Destroy sessions when users perform logout
  def destroy
    session[:remember_token] = nil
    session[:user_id] = nil
    redirect_to root_path, :notice => "Obrigado, volte sempre!"
    CUSTOM_LOGGER.info("Destroy user sessions")
  end
end
