# File: home_controller.rb 
# Purpose of class: This class is a controller and contains action methods for 
# home view.
# This software follows GPL license.
# TEM-DF Group
# FGA-UnB Faculdade de Engenharias do Gama - Universidade de Brasília
class HomeController < ApplicationController
	def about 
	end
	
	def index
		@reported_comment_size = Comment.all.where(report: true).size
		@deactivated_user_size = User.all.where(account_status: false).size
		@activaded_user_size = User.all.where(account_status: true).size-1
	end
end
