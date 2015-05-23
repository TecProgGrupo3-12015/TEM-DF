# File: medics_controller.rb 
# Purpose of class: This class is a controller and contains action methods for 
# medics view.
# This software follows GPL license.
# TEM-DF Group
# FGA-UnB Faculdade de Engenharias do Gama - Universidade de Brasília
class MedicsController < ApplicationController

	helper_method :array_speciality, :array_medics_quantity

	# Method to collect medics
	def results
		# Instance variable for medics object indetifies by params of search fields
		@medics = Medic.search(params[:list_specility], 
													 params[:list_work_unit_name])

		# Conditional for to return the medic object if the fields are filled     # correctly, else, show alert menssage and go to home. 
		#if @medics
  	#	@medics
  		CUSTOM_LOGGER.info("medics results loaded with success")
  	if  !@medics
  		flash.now.alert="Escolha um campo."
  		CUSTOM_LOGGER.error("empty fields on search medics results")
  		render "home/index"
  	end
	end

	# Method to collect a medic's information
	def profile

		# Find medic by id passed on params.
		@medic_by_id = Medic.find_by_id(params[:id]) 

		# Find work unit of medic.
		@work_unit_by_medic = WorkUnit.find_by_id(@medic_by_id.work_unit_id)

		# Average of this medic.
		@average = calculate_average(@medic_by_id)

		# Ratings of this medic
		@ratings = Rating.all.where(medic_id: @medic_by_id.id).size
	end
	
	# Method to show the work units X  quantity medics by region.
	def workunits_graph
		
		# These arrays has objects which build the graph medic work unitsX        # quantity medics by region.
		# Array that storages the quantity medic by unit
		@medics_size = []

		# Array that storages the units names.
		@unit_name = []

		@work_units = WorkUnit.all
		@work_units.each do |work_unit|
			medics_quantity_by_work_unit = Medic.all.where(work_unit_id: work_unit.id).size
			@medics_size.push(medics_quantity_by_work_unit)
			@unit_name.push(work_unit.name)
		end
	end

	# Method to fill array of medic's speciality 
	def array_speciality (id_work_unit)
		@medic = Medic.all.where(work_unit_id: id_work_unit)

		# Array which storages the medics specialities
		@speciality = []

		# Each block which verify the speciality array, unless the speciality would include on this, speciality will be included on this array.
		@medic.each do |medic|
			unless @speciality.include?(medic.speciality)
				@speciality.push(medic.speciality)
			end
		end	
		@speciality
	end

	# Method to fill array of speciality's quantity  
	def array_medics_quantity (id_work_unit, array_speciality)
		@medic = Medic.all.where(work_unit_id: id_work_unit)

		# Array which storages the medics quantity by speciality.
		@medics_size_speciality = []

		# Each block which storage quantity of medics by his speciality by        # work unit. 
		array_speciality.each do |speciality|
			quantity_medic_speciality = Medic.all.where(speciality: speciality,
																 work_unit_id: id_work_unit
																)
																.size

			# Include the quantity of medics by his speciality on speciality array.
			@medics_size_speciality.push(quantity_medic_speciality)
		end
		@medics_size_speciality
	end
	
	not_exists_user = @user == nil
	exists_user = @user

	# Method to rating a medic
	def rating
		medic_id = params[:medic_id]
		@user = User.find_by_id(session[:remember_token])
		@medic = Medic.find_by_id(medic_id)

		if !not_exists_user
			rating_status = ""
			@rating = Rating.find_by_user_id_and_medic_id(@user.id, @medic.id)
			CUSTOM_LOGGER.info("exist user in rating")
			# REVIEW: Verify this condidional with average action. Apply the default 
			# 	behavior. 
			if @rating
				update_rating(@rating , params[:grade])
				rating_status = 'Avaliação Alterada!'
				CUSTOM_LOGGER.info("Change rating for medic")
			else
				create_rating(@user, @medic)
				rating_status = 'Avaliação Realizada com sucesso!'
				CUSTOM_LOGGER.info("rating for medic created with success")
			end
			redirect_to action:"profile",id: medic_id, notice: rating_status
		else
			redirect_to login_path, :alert => "O Usuário necessita estar logado"
			CUSTOM_LOGGER.error("user not login for rating in medic")
		end
	end

	# Method to create a comment of a medic
	def create_comment
		@user = User.find_by_id(session[:remember_token])
		@medic = Medic.find_by_id(params[:medic_id])
		if exists_user
			@comment = Comment.new(content: params[:content], 
														 date: Time.current,
														 medic: @medic, 
														 user: @user, 
														 comment_status: true, 
											       report: false)
			@comment.save
			redirect_to profile_path(@medic)
			CUSTOM_LOGGER.info("user is logged for comment")
		else
			redirect_to login_path, :alert => "O Usuário necessita estar logado"
			CUSTOM_LOGGER.error("user not login for comment")
		end
	end

	#Method to create relevance of a comment
	def create_relevance

		# Users by id like session.		
		@user = User.find_by_id(session[:remember_token])

		# Comment by id passed by params.
		@comment = Comment.find_by_id(params[:comment_id])

		# Constants used on next conditional, this constants facilitates the
		# read code.
		exist_comment = @comment
		exist_relevance = @relevance

		# Conditional which verify case anybody user is logged, then redirect to  # login and show a alert. 
		# Else have an user and comment, then get some relevance.
		# Case have a relevance, then the relevance will be update with the values
		# setted by user, else, will be created.
		if exist_comment && !not_exists_user
				@relevance = Relevance.find_by_user_id_and_comment_id(@user.id, @comment.id)
				CUSTOM_LOGGER.info("exist user logged and comment on medic")
				if exist_relevance
					@relevance.update_attribute(:value, params[:value])
					CUSTOM_LOGGER.info("update the relevance")
				else
					@relevance = Relevance.create(value: params[:value], 
																				user: @user, 
																				comment: @comment)
					CUSTOM_LOGGER.info("relevance created")
				end

			# Redirect profile.	
			redirect_to action:"profile",id: params[:medic_id]
		end
		if not_exists_user
			redirect_to login_path, :alert => "O Usuário necessita estar logado"
			CUSTOM_LOGGER.error("user not loggin for create relevance on comment")
		else
			# Nothing to do
		end
	end

	# Methos to report a undue comment
	def to_report

		# Find comments by id passed by params.
		@comment = Comment.find_by_id(params[:comment_id])

		# Conditional which verify if the comment is reported, case not, his
		# attibute will be updated.
		if !@comment.report
			@comment.update_attribute(:report, true)
			CUSTOM_LOGGER.info("comment reported")
		end
		flash[:notice] = "Comentário reportado."
		redirect_to action:"profile",id: params[:medic_id]
	end

	# Method to list top 10 medics
	def ranking
		@medics = Medic.order(average: :desc).limit(10)
	end

  # REVIEW: This methods privates can be move to modules?
  private 
  # Method to create rating of a medic
	def create_rating(user, medic)
		@rating = Rating.new(grade: params[:grade], 
												 user: user, 
												 medic: medic, 
												 date: Time.current)
		@rating.save
	end

	NIL_GRADE = "0"

	# Method to change an existing rating
	def update_rating(rating, grade)
		not_exist_grade = grade != NIL_GRADE
		if !not_exist_grade
			# Nothing to do
			CUSTOM_LOGGER.info("exist grade for medic")
    else
    	rating.update_attribute(:grade , grade)
      rating.update_attribute(:date , Time.current) 
      CUSTOM_LOGGER.info("not exist grade") 
    end
	end

	NIL_RATING = 0

	# Method to caculate average of all rating of a medic
	def calculate_average(medic)
		@ratings = Rating.all.where(medic_id: medic.id)
		
		# REVIEW: Verify the default behavior with the rating action.
		not_exist_rating = @ratings.size == NIL_RATING

		if !not_exist_rating
			@ratings.each { |rating| sum_of_grades_rating += rating.grade}
			arithmetic_mean_averange = sum_of_grades_rating / (1.0 * @ratings.size)
			medic.update_attributes(:average => arithmetic_mean_averang)
			arithmetic_mean_averange
			CUSTOM_LOGGER.info("create average for medic")
		else
  		NIL_RATING
  		CUSTOM_LOGGER.info("not exist rating for medic")
		end
	end
end
