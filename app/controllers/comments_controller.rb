# File: comments_controller.rb
# Purpose of class: Contains action methods for comments view.
# This software follows GPL license.
# TEM-DF Group.
# FGA-UnB Faculdade de Engenharias do Gama - Universidade de Brasília.
class CommentsController < ApplicationController
	
	# Method to report a comment
	def reports

		#Receives an object of class User of current session
		@user = User.find_by_id(session[:remember_token])

		# Checks wheter the User is admin
		if is_user_or_admin_logging?(@user)
			@reported_comments = Comment.all.where(report: true)
			CUSTOM_LOGGER.info("Showed all users")
		else
			redirect_to root_path
			CUSTOM_LOGGER.info("Failure to showed all users")
		end
	end

	# Method to deactivate a comment
	def deactivate
		#Receives an object of class User of current session
		@comment = Comment.find_by_id(params[:comment_id])
		report_or_deactive_comment(@comment, false)
	end

	# Method to reactivate a comment
	def reactivate
		#Receives an object of class User of current session
		@comment = Comment.find_by_id(params[:comment_id])
		if do_exist_comment?(@comment)
			@comment.update_attribute(:comment_status, true)
			CUSTOM_LOGGER.info("Comment reactivated #{@comment.to_yaml}")
		else
			CUSTOM_LOGGER.info("Failure to reactivate comment #{@comment.to_yaml}")
			missing_report
		end
		redirect_to reported_comments_path
	end

	# Method to remove the report in a comment
	def disable_report
		#Receives an object of class User of current session
		@comment = Comment.find_by_id(params[:comment_id])
		report_or_deactive_comment(@comment, true)
	end

	#REVIEW: it would be better to use assert?
	def missing_report
		flash.now.alert = "Erro, comentario nao encontrado."
		redirect_to reported_comments_path
	end

	private
	def is_user_or_admin_logging?(user)
		if @user && @user.username == "admin"
			true
		else
			false
		end
	end

	def do_exist_comment?(comment)
		if @comment
			true
		else
			false
		end
	end

	def report_or_deactive_comment(comment, is_report)
		if do_exist_comment?(@comment)
			if is_report = true
				@comment.update_attribute(:report, false)
				CUSTOM_LOGGER.info("Comment report disabled #{@comment.to_yaml}")
			else
				@comment.update_attribute(:comment_status, false)
				CUSTOM_LOGGER.info("Comment deactivated #{@comment.to_yaml}")
		else
			CUSTOM_LOGGER.info("Failure to disable report #{@comment.to_yaml}")
			missing_report
		end
		redirect_to reported_comments_path

	end
end

		@comment = Comment.find_by_id(params[:comment_id])
		if do_exist_comment?(@comment)
			@comment.update_attribute(:report, false)
			CUSTOM_LOGGER.info("Comment report disabled #{@comment.to_yaml}")
		else
			CUSTOM_LOGGER.info("Failure to disable report #{@comment.to_yaml}")
			missing_report
		end
		redirect_to reported_comments_path


			@comment = Comment.find_by_id(params[:comment_id])
		if do_exist_comment?(@comment)
			@comment.update_attribute(:comment_status, false)
			CUSTOM_LOGGER.info("Comment deactivated #{@comment.to_yaml}")
		else
			CUSTOM_LOGGER.info("Failure to deactivate comment #{@comment.to_yaml}")
			missing_report
		end
		redirect_to reported_comments_path